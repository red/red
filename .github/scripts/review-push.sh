#!/usr/bin/env bash
# AI-based code review for pushes, run by .github/workflows/ai-review.yml on the
# Linux self-hosted runner. Resolves the pushed range, temporarily appends review
# guidance to AGENTS.md, runs `codex exec review` on the diff, and writes advisory
# outputs. Always exits 0; the review is a backstop and must never fail the
# workflow. Authentication uses the codex login on the runner machine (CODEX_HOME).
#
# Inputs (env):
#   REVIEW_BEFORE    github.event.before
#   REVIEW_SHA       github.sha
#   DEFAULT_BRANCH   github.event.repository.default_branch
#   REVIEW_BIN       optional; path to the codex binary (default: `codex` on PATH).
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

    # Strong signals: an actual finding entry — a prioritised list item, a
    # bracketed tag, or a numbered "Finding 1:" block. Codex renders findings in
    # these shapes, so they are trusted ahead of any clean prose: a scoped
    # sentence such as "the patch does not introduce regressions in fast-forward
    # pushes" must not swallow a real finding.
    local issue_patterns=(
        '^[[:space:]]*-[[:space:]]*\[(P[0-9]|S[0-9]|critical|high|medium|low|bug|security|performance|correctness)\]'
        '^[[:space:]]*\[(P[0-9]|S[0-9]|critical|high|medium|low|bug|security|performance|correctness)\]'
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
        '(the patch|this patch|the change|this change|the changes|this update|the updated iteration)[[:space:]].*does not introduce (any|an|a)[[:space:]]+((evident|obvious|functional|actionable|correctness)[[:space:]]+)*(regressions?|issues?|bugs?)'
    )
    for pattern in "${clean_patterns[@]}"; do
        if printf '%s\n' "$text" | grep -Eqim1 "$pattern"; then
            return 1
        fi
    done

    # A specific clean shape: a fix now matches its target, has no downstream
    # references, and introduces no regressions.
    if printf '%s\n' "$text" | grep -Eiq 'now matches|matches' && \
       printf '%s\n' "$text" | grep -Eiq 'no downstream references' && \
       printf '%s\n' "$text" | grep -Eiq 'does not introduce (any|an|a)[[:space:]]+((evident|obvious|functional|actionable|correctness)[[:space:]]+)*(regressions?|issues?|bugs?)'; then
        return 1
    fi

    # Weak signal, checked last: a bare `Correctness:` / `Security:` prose
    # heading. Codex writes section headings in this shape even for a clean
    # review, so it only counts when no clean statement above ruled it out.
    local weak_issue_patterns=(
        '^[[:space:]]*(critical|high|medium|low|warning|error|bug|security|correctness|performance)[[:space:]]*:'
    )
    for pattern in "${weak_issue_patterns[@]}"; do
        if printf '%s\n' "$text" | grep -Eqim1 "$pattern"; then
            return 0
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

: "${REVIEW_BEFORE:-}"
: "${REVIEW_SHA:-}"
default_branch="${DEFAULT_BRANCH:-}"

review_bin="${REVIEW_BIN:-}"
if [ -z "$review_bin" ]; then
    review_bin="$(command -v codex 2>/dev/null || true)"
fi
if [ -z "$review_bin" ]; then
    log "codex binary not found; skipping review."
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
- In particular, do not run `codex`, `codex exec`, or commands that invoke another model/API client.
- Use ordinary read-only repository inspection commands such as `git diff`, `git show`, `rg`, and `cat` when needed.
- Do not modify any files.
- End your final response with exactly one machine-readable verdict line: `AI_REVIEW_HAS_ISSUES: true` or `AI_REVIEW_HAS_ISSUES: false`.
- Use `AI_REVIEW_HAS_ISSUES: true` only when the review contains concrete, actionable findings with file/line evidence. Use `false` for clean reviews, uncertainty, summaries, and non-actionable observations.
GUIDANCE

# A force-push leaves the previous tip unreachable from the new one, so codex's
# --base mode falls back to the merge base and can hide content the force-push
# discarded (the report would still be labelled before..after). codex rejects
# --base together with a custom prompt, so this path passes the prompt only.
force_push=0
if [ "$single_commit_mode" -eq 0 ] && test_git_commit "$base_sha" && \
   ! git merge-base --is-ancestor "$base_sha" "$head_sha" 2>/dev/null; then
    force_push=1
    log "Force-push detected: $base_sha is not an ancestor of $head_sha."
fi

base_branch=""
if [ "$single_commit_mode" -eq 1 ]; then
    : # Reviewing HEAD commit only; codex --commit handles the range.
elif [ "$force_push" -eq 1 ]; then
    : # No base branch: the review prompt carries the explicit before..after range.
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
fi

# Reasoning effort override (REVIEW_EFFORT: low|medium|high|...; empty = the
# model's default), passed to codex as a config override.
effort_args=()
if [ -n "${REVIEW_EFFORT:-}" ]; then
    effort_args=(-c "model_reasoning_effort=$REVIEW_EFFORT")
fi

# codex review takes exactly one target: --commit <sha>, --base <branch>, or a
# custom prompt. --base and the positional prompt are mutually exclusive.
range_args=()
review_prompt_args=()
if [ "$single_commit_mode" -eq 1 ]; then
    range_args=(--commit "$head_sha")
elif [ "$force_push" -eq 1 ]; then
    review_prompt_args=("Review exactly the changes introduced by this push. Run: git diff $base_sha $head_sha and base the review on that diff. The push rewrote history (the previous tip is not an ancestor of HEAD), so a merge-base diff would hide changes that the force-push discarded.")
else
    range_args=(--base "$base_branch")
fi

# Drop any previous report: a reused output directory (local runs without
# RUNNER_TEMP) would otherwise let a failed or timed-out run publish stale
# findings under the current commit.
rm -f "$last_message_output_path" 2>/dev/null || true

# Enforce the review deadline here: a runner-imposed timeout is a hard
# cancellation that continue-on-error cannot suppress, so wrap the reviewer in
# `timeout` and always exit 0. --kill-after upgrades TERM to SIGKILL 60s later
# so the step ends even if it ignores SIGTERM: the step is guaranteed to finish
# within the deadline + 60s. --ephemeral keeps sessions out of CODEX_HOME, so
# repeated reviews do not accumulate state on the self-hosted runner.
review_timeout_seconds="${REVIEW_TIMEOUT_SECONDS:-3300}"
log "Running codex review for $range_label (deadline: ${review_timeout_seconds}s)."
timeout --kill-after=60 "$review_timeout_seconds" "$review_bin" exec review \
    --ephemeral \
    ${effort_args[@]+"${effort_args[@]}"} ${range_args[@]+"${range_args[@]}"} \
    -o "$last_message_output_path" \
    ${review_prompt_args[@]+"${review_prompt_args[@]}"} \
    >"$transcript_output_path" 2>&1
review_exit_code=$?
log "codex finished with exit code $review_exit_code; any failure is advisory and ignored."

# Read the review from the file codex wrote with -o. Handle mid-flight failures
# (provider outage, deadline SIGTERM/SIGKILL) with a concise advisory line
# instead of dumping the raw transcript into the report. Every path below keeps
# the review advisory: the script always exits 0.
review_text=""
if [ -f "$last_message_output_path" ]; then
    review_text="$(cat "$last_message_output_path" 2>/dev/null || true)"
fi

if [ -z "$review_text" ]; then
    if [ "$review_exit_code" -eq 124 ] || [ "$review_exit_code" -eq 137 ]; then
        review_text="Review was terminated at the ${review_timeout_seconds}s deadline before producing output. See review-transcript.txt for partial progress."
    elif [ -s "$transcript_output_path" ]; then
        # codex ran but wrote no final message; keep a short note and preserve
        # the transcript for debugging.
        review_text="codex produced no final review message. See review-transcript.txt for details."
    fi
fi
[ -n "$review_text" ] || review_text="Reviewer produced no output."

# Leave last_message_output_path as codex wrote it; this script only reads it.
# The report below carries any fallback text, so the artifact stays faithful
# to the tool's raw final message.

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
