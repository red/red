# Issue #5644: Recovering CSV Loading Plan

## Goals

- Keep plain `load-csv` strict.
- Prevent silent partial loads.
- Add an explicit recovery mode for CSV import tools.
- Report every recovery decision with enough source position data to fix the original CSV.
- Leave room for real-world CSV profiles without making the default loader vague or unsafe.

## Proposed API

```red
errors: copy []
rows: load-csv/recover data errors
```

Plain `load-csv data` remains strict:

- malformed syntax throws
- non-aligned rows throw
- no partial result is returned silently

`load-csv/recover data errors`:

- returns successfully parsed rows
- skips or repairs row-level problems where recovery is safe
- appends diagnostic objects to `errors`

Future optional extension:

```red
rows: load-csv/recover/options data errors [
    bare-quotes:       yes
    trim-after-quote:  yes
    pad-short-rows:    yes
    truncate-long-rows no
]
```

## Diagnostic Shape

```red
make object! [
    type: 'unterminated-quote
    line: 245
    column: 13
    action: 'skipped
    source: {"a"x,b,c}
]
```

`action` values:

- `skipped`
- `repaired`
- `padded`
- `truncated`

## Recommended Architecture

Use a small streaming CSV scanner/state machine instead of trying to make the existing whole-file `parse` rule recoverable.

Scanner states:

- `start-field`
- `unquoted-field`
- `quoted-field`
- `quote-closed`
- `after-delimiter`
- `record-end`

Track:

- current line
- current column
- current offset
- record start position
- field start position
- quote start position
- expected field count
- current row
- current field

Strict mode and recover mode should share this scanner. Only the error handler changes:

- strict mode throws immediately
- recover mode appends a diagnostic object and then repairs, skips, or resynchronizes

## Recovery Policy

Phase 1 should be conservative:

- Syntax errors: skip the offending row and report `action: 'skipped`.
- Unterminated quote at EOF: repair only if the row width is plausible; otherwise skip.
- Unterminated quote before more data: skip; do not guess where the row should end.
- Unexpected non-whitespace after a closing quote: skip.
- Whitespace after a closing quote before delimiter/newline: repair by trimming and report `action: 'repaired`.
- Short non-aligned row: pad missing fields with `""` when expected width is known and report `action: 'padded`.
- Long non-aligned row: truncate only when expected width is known and truncation is enabled; otherwise skip.
- Ambiguous quote structure: skip; do not guess.

Expected width should come from:

1. header row, if `/header`
2. `/flat` size, if applicable
3. the first successfully parsed row otherwise

## Resynchronization

When a row cannot be repaired:

- append a diagnostic object
- skip to the next likely physical line boundary
- try parsing from there
- if that line is invalid too, repeat

The scanner must not treat newlines inside valid quoted fields as record boundaries.

## Phased Implementation

### Phase 1

- Add `/recover errors`.
- Replace or wrap the current `load-csv` parser with a record-oriented scanner.
- Keep strict behavior for plain `load-csv`.
- Add conservative row skip/pad/repair behavior.
- Append diagnostic objects using the agreed shape.

### Phase 2

Add configurable recovery options or profiles for common wild CSV sources.

Possible profiles:

- `rfc4180`
- `excel`
- `loose`
- `tsv`

Possible options:

- `bare-quotes`
- `trim-after-quote`
- `pad-short-rows`
- `truncate-long-rows`
- `skip-empty-bad-rows`

## Alternatives Considered

### Whole-File Parse With Post-Check

Pros:

- Smallest patch
- Fixes silent partial output

Cons:

- Does not support recovery after the first malformed row
- Poor error position data
- Hard to resynchronize

### Physical Row Split Plus Existing Parser

Pros:

- Easier than a scanner
- Can skip simple malformed rows

Cons:

- Breaks quoted multiline fields
- Poor for unterminated quote recovery
- Not robust enough for wild CSV formats

### Scanner With Conservative Recovery

Pros:

- Accurate line/column/source reporting
- Handles quoted newlines correctly
- Supports strict and recover modes with one parser core
- Safe default recovery behavior

Cons:

- Larger implementation
- Requires a broader test matrix

### Profile-Driven Scanner

Pros:

- Best fit for real-world CSV managers
- Allows users to choose risk level
- Keeps plain `load-csv` strict and predictable

Cons:

- More API surface
- Profiles/options need clear documentation
- More tests needed

## Tests

- Plain `load-csv` malformed input throws.
- Plain `load-csv` non-aligned input throws.
- `load-csv/recover` malformed input returns surrounding valid rows and appends one diagnostic object.
- `load-csv/recover` short non-aligned row pads missing fields and reports `action: 'padded`.
- `load-csv/recover` ambiguous quote error skips the row and reports `action: 'skipped`.
- `load-csv/recover` handles quoted multiline fields without splitting them incorrectly.
- `load-csv/recover` can report multiple bad rows in one input.
- Existing `/header`, `/as-columns`, `/as-records`, `/flat`, `/trim`, `/quote`, and `/with` behavior remains unchanged in strict mode.
