#!/usr/bin/env bash
# AI-based code review for pushes, run by .github/workflows/ai-review.yml on the
# Linux self-hosted runner. Resolves the pushed range, temporarily appends review
# guidance to AGENTS.md, asks the AI reviewer to review the diff, and writes
# advisory outputs. Always exits 0; the review is a backstop and must never fail
# the workflow.
#
# Inputs (env):
#   REVIEW_BEFORE    github.event.before
#   REVIEW_SHA       github.sha
#   DEFAULT_BRANCH   github.event.repository.default_branch
#   AI_GATEWAY_API_KEY  optional; when set, the reviewer uses the Vercel AI
#                       Gateway (the recommended credential source for
#                       scripts/CI). When empty it is unset so it falls back to
#                       credentials saved on the runner machine.
#   REVIEW_BIN       optional; path to the reviewer binary
#                    (default: ~/.local/bin/fx, then `fx` on PATH).
#
# Outputs (GITHUB_OUTPUT):
#   has_issues, review_output_path, transcript_path, last_message_path, range_label
set -u

log() { printf '[review] %s\n' "$*"; }

write_output() {
    local name="$1" value="$2"
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
        printf '%s=%s\n' "$name" "$value" >>"$GITHUB_OUTPUT"
    fi
}

append_summary() {
    if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
        printf '%s\n' "$*" >>"$GITHUB_STEP_SUMMARY"
    fi
}

function test_zero_sha() {
    [ -n "${1:-}" ] && [[ "$1" =~ ^0+$ ]]
}

function test_git_commit() {
    [ -n "${1:-}" ] && git cat-file -e "$1^{commit}" 2>/dev/null
}

function resolve_head_sha() {
    local candidate="${1:-}"
    if [ -n "$candidate" ] && ! test_zero_sha "$candidate" && test_git_commit "$candidate"; then
        printf '%s\n' "$candidate"
        return 0
    fi
    local head
    head="$(git rev-parse HEAD 2>/dev/null || true)"
    if [ -z "$head" ]; then
        log "Unable to resolve HEAD for review."
        return 1
    fi
    printf '%s\n' "$head"
}

function resolve_base_sha() {
    local before="${1:-}" default_branch="${2:-}"

    if [ -n "$before" ] && ! test_zero_sha "$before" && test_git_commit "$before"; then
        printf '%s\n' "$before"
        return 0
    fi

    [ -n "$default_branch" ] || default_branch="master"
    local remote_default="origin/$default_branch"
    if ! test_git_commit "$remote_default"; then
        log "Fetching origin/$default_branch to resolve a base commit."
        # Bound the fetch: a stalled network would otherwise hang until the
        # job-level timeout, which continue-on-error cannot suppress.
        timeout 300 git fetch --no-tags origin "+refs/heads/$default_branch:refs/remotes/origin/$default_branch" >/dev/null 2>&1 || \
            log "Unable to fetch origin/$default_branch; falling back to local history."
    fi

    if test_git_commit "$remote_default"; then
        local merge_base
        merge_base="$(git merge-base HEAD "$remote_default" 2>/dev/null || true)"
        if [ -n "$merge_base" ]; then
            printf '%s\n' "$merge_base"
            return 0
        fi
    fi

    if test_git_commit "HEAD~1"; then
        git rev-parse HEAD~1
        return 0
    fi

    return 1
}

# Decide whether a review contains findings. Verdict line first, then heuristic
# issue patterns, then heuristic clean patterns; defaults to false
# (advisory-only reviews never block).
function test_review_has_issues() {
    local text="$1"
    [ -n "$(printf '%s' "$text" | tr -d '[:space:]')" ] || return 1

    local verdict
    verdict="$(printf '%s\n' "$text" | grep -Eim1 '^[[:space:]]*AI_REVIEW_HAS_ISSUES[[:space:]]*:[[:space:]]*(true|false)[[:space:]]*$' | awk -F: '{print $2}' | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
    if [ -n "$verdict" ]; then
        [ "$verdict" = "true" ] && return 0 || return 1
    fi

    local issue_patterns=(
        '^[[:space:]]*-[[:space:]]*\[(P[0-9]|S[0-9]|critical|high|medium|low|bug|security|performance|correctness)\]'
        '^[[:space:]]*\[(P[0-9]|S[0-9]|critical|high|medium|low|bug|security|performance|correctness)\]'
        '^[[:space:]]*(critical|high|medium|low|warning|error|bug|security|correctness|performance)[[:space:]]*:'
        '^[[:space:]]*(finding|issue)[[:space:]]+[0-9]+[[:space:]]*:'
    )
    local pattern
    for pattern in "${issue_patterns[@]}"; do
        if printf '%s\n' "$text" | grep -Eqim1 "$pattern"; then
            return 0
        fi
    done

    local clean_patterns=(
        '^[[:space:]]*(no findings|no issues found|no issues detected|no actionable issues|no actionable findings|nothing to report|looks good to me|lgtm)\.?+[[:space:]]*$'
        '^[[:space:]]*findings[[:space:]]*:[[:space:]]*(none|no(ne)? issues)\.?+[[:space:]]*$'
        '^[[:space:]]*there are no (findings|issues|actionable issues|actionable findings)\.?+[[:space:]]*$'
        '^[[:space:]]*i found no (findings|issues|actionable issues|actionable findings)\.?+[[:space:]]*$'
        'i did not (identify|find) (a|an|any)?[[:space:]]*(discrete|concrete|actionable|introduced|new|clear)?[[:space:]]*(bug|issue|regression|finding|findings|bugs|issues|regressions)'
        '(the patch|this patch|the change|this change|the changes|this update)[[:space:]].*(no|not any|without)[[:space:]]+((evident|obvious|functional|actionable)[[:space:]]+)*(regressions?|issues?|findings?|bugs?)'
    )
    for pattern in "${clean_patterns[@]}"; do
        if printf '%s\n' "$text" | grep -Eqim1 "$pattern"; then
            return 1
        fi
    done

    return 1
}

# Truncate to 12000 characters, keeping head and tail, mirroring Limit-ReviewLength.
function limit_review_length() {
    local text="$1" max=12000 tail_len=4000
    local length=${#text}
    if [ "$length" -le "$max" ]; then
        printf '%s\n' "$text"
        return 0
    fi
    local head_len=$((max - tail_len))
    {
        printf '%s' "${text:0:head_len}" | sed -e 's/[[:space:]]*$//'
        printf '\n\n... review output truncated; see review-transcript.txt for the full raw transcript ...\n\n'
        printf '%s' "${text:length - tail_len:tail_len}" | sed -e 's/^[[:space:]]*//'
    }
}

# Resolve paths and inputs.
output_root="${RUNNER_TEMP:-$(pwd)}"
review_output_path="$output_root/review-output.md"
transcript_output_path="$output_root/review-transcript.txt"
last_message_output_path="$output_root/review-last-message.md"
json_output_path="$output_root/review-response.json"

: "${REVIEW_BEFORE:-}"
: "${REVIEW_SHA:-}"
default_branch="${DEFAULT_BRANCH:-}"

# Unset an empty gateway key so the reviewer falls back to credentials saved on
# the machine (VERCEL_OIDC_TOKEN -> AI_GATEWAY_API_KEY -> login -> saved API key).
[ -n "${AI_GATEWAY_API_KEY:-}" ] || unset AI_GATEWAY_API_KEY || true
export FX_AUTO_UPGRADE="${FX_AUTO_UPGRADE:-0}" # deterministic CI runs: no background self-update

review_bin="${REVIEW_BIN:-}"
if [ -z "$review_bin" ] && [ -x "$HOME/.local/bin/fx" ]; then
    review_bin="$HOME/.local/bin/fx"
fi
if [ -z "$review_bin" ]; then
    review_bin="$(command -v fx 2>/dev/null || true)"
fi
if [ -z "$review_bin" ]; then
    log "Reviewer binary not found; skipping review."
    write_output "has_issues" "false"
    write_output "review_output_path" "$review_output_path"
    write_output "transcript_path" "$transcript_output_path"
    write_output "last_message_path" "$last_message_output_path"
    write_output "range_label" ""
    exit 0
fi

# Skip when the push deleted a ref.
if test_zero_sha "$REVIEW_SHA"; then
    log "Push deleted a ref; skipping review."
    write_output "has_issues" "false"
    write_output "review_output_path" "$review_output_path"
    write_output "transcript_path" "$transcript_output_path"
    write_output "last_message_path" "$last_message_output_path"
    write_output "range_label" ""
    exit 0
fi

head_sha="$(resolve_head_sha "$REVIEW_SHA")" || head_sha=""
if [ -z "$head_sha" ]; then
    write_output "has_issues" "false"
    write_output "review_output_path" "$review_output_path"
    write_output "transcript_path" "$transcript_output_path"
    write_output "last_message_path" "$last_message_output_path"
    write_output "range_label" ""
    exit 0
fi
short_head="${head_sha:0:12}"

base_sha="$(resolve_base_sha "$REVIEW_BEFORE" "$default_branch" 2>/dev/null)" || base_sha=""
single_commit_mode=0
if [ -z "$base_sha" ]; then
    single_commit_mode=1
    log "No base commit found; reviewing HEAD commit only."
    range_label="$short_head"
else
    log "Using $base_sha as review base."
    range_label="$base_sha..$head_sha"
fi

# Temporarily append review guidance to AGENTS.md (the reviewer reads project
# instructions from it); restore the original file afterwards.
agents_path="AGENTS.md"
agents_backup="$output_root/review-agents-backup.md"
had_agents=0
[ -f "$agents_path" ] && had_agents=1
cleanup() {
    if [ "$had_agents" -eq 1 ]; then
        cp -f "$agents_backup" "$agents_path" 2>/dev/null || true
    elif [ -f "$agents_path" ]; then
        rm -f "$agents_path" 2>/dev/null || true
    fi
    if [ -n "${base_branch:-}" ]; then
        git branch -D "$base_branch" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

if [ "$had_agents" -eq 1 ]; then
    log "AGENTS.md exists; appending temporary review guidance and restoring it after review."
    cp -f "$agents_path" "$agents_backup"
fi
cat >>"$agents_path" <<'GUIDANCE'

# Automated AI Review Guidance

- Do not run nested AI or reviewer CLI commands during automated review.
- In particular, do not run `fx`, `fx ask`, or commands that invoke another model/API client.
- Use ordinary read-only repository inspection commands such as `git diff`, `git show`, `rg`, and `cat` when needed.
- Do not modify any files.
- End your final response with exactly one machine-readable verdict line: `AI_REVIEW_HAS_ISSUES: true` or `AI_REVIEW_HAS_ISSUES: false`.
- Use `AI_REVIEW_HAS_ISSUES: true` only when the review contains concrete, actionable findings with file/line evidence. Use `false` for clean reviews, uncertainty, summaries, and non-actionable observations.
GUIDANCE

base_branch=""
if [ "$single_commit_mode" -eq 1 ]; then
    range_instructions="Review the repository changes introduced by commit $head_sha.

- Run \`git show $head_sha\` to see the change, and inspect surrounding code with read-only commands (git log, git show, ls, cat, grep) as needed.
- Do not modify any files."
else
    base_branch="review-base-$short_head"
    git branch --force "$base_branch" "$base_sha" >/dev/null 2>&1 || {
        log "Unable to create temporary review base branch '$base_branch'."
        base_branch=""
        write_output "has_issues" "false"
        write_output "review_output_path" "$review_output_path"
        write_output "transcript_path" "$transcript_output_path"
        write_output "last_message_path" "$last_message_output_path"
        write_output "range_label" "$range_label"
        exit 0
    }
    range_instructions="Review the repository changes in the git range $range_label.

- Run \`git diff $base_sha $head_sha\` to see the changes, and inspect surrounding code with read-only commands (git log, git show, ls, cat, grep) as needed.
- Do not modify any files."
fi

# Review standards, inlined. The point is to suppress noise in an advisory
# review, not to enumerate every possible rule.
review_standards=$(cat <<'STANDARDS'
You are acting as a reviewer for a proposed code change made by another engineer.

The criteria below are defaults, not the final word. More specific guidance you encounter (in a developer message, a user message, a project file such as AGENTS.md, or elsewhere in this system message) overrides these general instructions.

Decide whether an issue is worth flagging using these criteria:
1. It meaningfully impacts accuracy, performance, security, or maintainability.
2. It is discrete and actionable, not a general codebase issue or a bundle of issues.
3. Fixing it does not demand more rigor than the surrounding code follows.
4. It was introduced in the reviewed range (do not flag pre-existing bugs).
5. The author would likely fix it if made aware.
6. It does not rely on unstated assumptions about the codebase or the author's intent.
7. Speculation is not enough: identify the specific parts provably affected.
8. It is clearly not an intentional choice by the author.

Report every qualifying finding, not just the first. If none qualifies, prefer no findings. Review the diff independently and deduplicate findings by changed location and defect/remedy. Do not omit ordinary findings or invent findings solely because a rubric exists.

Output the report as Markdown (not inline PR comments), one section per finding:

### [P1] <short imperative title, 80 chars or fewer>

<body: brief Markdown explaining why it is a problem; cite files/lines/functions; name the scenarios or inputs that trigger it, and note when its severity depends on them>

Tag each title with a priority: [P0] blocking (only for universal issues that do not depend on assumptions about inputs), [P1] urgent, [P2] normal, [P3] nice-to-have. If there are no findings, state exactly: `No findings.`

Convey severity accurately without overstating it. Write each finding so the author can grasp it immediately without close reading. Keep the tone matter-of-fact: neither accusatory nor excessively positive; it should read as a helpful AI assistant suggestion, not a human reviewer. Avoid filler praise and unhelpful phrasing such as `Great job ...` or `Thanks for ...`. Ignore style, formatting, typos, documentation, and other nits when forming the verdict. Do not generate a PR fix.
STANDARDS
)

prompt=$(cat <<PROMPT
$range_instructions

$review_standards

End your final response with exactly one machine-readable verdict line: \`AI_REVIEW_HAS_ISSUES: true\` or \`AI_REVIEW_HAS_ISSUES: false\`.
Use \`true\` only when the review contains concrete, actionable findings with file/line evidence. Use \`false\` for clean reviews, uncertainty, summaries, and non-actionable observations.
PROMPT
)

# Reasoning effort override for models that support it (REVIEW_EFFORT:
# low|medium|high|...; empty = the model's default). Also settable persistently
# on the machine via `fx config set effort <level>`.
effort_args=()
if [ -n "${REVIEW_EFFORT:-}" ]; then
    effort_args=(--effort "$REVIEW_EFFORT")
fi

# Enforce the review deadline here: a runner-imposed timeout is a hard
# cancellation that continue-on-error cannot suppress, so wrap the reviewer in
# `timeout` and always exit 0. --kill-after upgrades TERM to SIGKILL 60s later
# so the step ends even if it ignores SIGTERM: the step is guaranteed to finish
# within the deadline + 60s.
review_timeout_seconds="${REVIEW_TIMEOUT_SECONDS:-3300}"
log "Running review for $range_label (deadline: ${review_timeout_seconds}s)."
timeout --kill-after=60 "$review_timeout_seconds" "$review_bin" ask --json --no-save --auto \
    ${effort_args[@]+"${effort_args[@]}"} --timeout 300 "$prompt" \
    >"$json_output_path" 2>"$transcript_output_path"
review_exit_code=$?
log "Reviewer finished with exit code $review_exit_code; any failure is advisory and ignored."

# Extract the review text from the structured output. Handle every mid-flight
# failure (provider outage, deadline SIGTERM/SIGKILL, partial/invalid JSON)
# with a concise advisory line instead of dumping raw JSON into the report.
# Every path below keeps the review advisory: the script always exits 0.
review_text=""
review_error=""
if jq -es . "$json_output_path" >/dev/null 2>&1; then
    review_text="$(jq -er '.final_output // .output // empty' "$json_output_path" 2>/dev/null || true)"
    review_error="$(jq -er '.error // empty' "$json_output_path" 2>/dev/null || true)"
fi

if [ -z "$review_text" ]; then
    if [ -n "$review_error" ]; then
        review_text="Reviewer produced no output (error: $review_error). See review-transcript.txt for details."
    elif [ "$review_exit_code" -eq 124 ] || [ "$review_exit_code" -eq 137 ]; then
        review_text="Review was terminated at the ${review_timeout_seconds}s deadline before producing output. See review-transcript.txt for partial progress."
    elif [ -s "$json_output_path" ]; then
        # stdout was produced but is not valid JSON (unexpected CLI output);
        # keep it verbatim for debugging rather than discarding it.
        review_text="$(cat "$json_output_path" 2>/dev/null || true)"
    fi
fi
[ -n "$review_text" ] || review_text="Reviewer produced no output."

printf '%s\n' "$review_text" >"$last_message_output_path"

if test_review_has_issues "$review_text"; then
    has_issues=true
else
    has_issues=false
fi
review_text="$(limit_review_length "$review_text")"

summary="# AI Code Review

- Range: \`$range_label\`
- Mode: advisory
- Reviewer exit code: \`$review_exit_code\`
- Issues found: \`$has_issues\`

## Review

$review_text"

{
    printf '%s\n' "$summary"
} >"$review_output_path"
append_summary "$summary"

write_output "has_issues" "$has_issues"
write_output "review_output_path" "$review_output_path"
write_output "transcript_path" "$transcript_output_path"
write_output "last_message_path" "$last_message_output_path"
write_output "range_label" "$range_label"

log "Review written to $review_output_path."
exit 0
