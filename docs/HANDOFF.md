# OmniMAM Spec Handoff

## Current goal and status

- Goal: publish the Task Center download-order and no-legacy-data correction as `spec-v1.23.7`.
- Status: in progress. The scoped v1.23.7 correction is implemented and validated; content/release commits and remote publication remain.

## Work completed in this session

- Re-read the Spec S1/S2 workflow rules and confirmed the approved v1.23.6 scope.
- Resumed from the existing checkpoint and verified local `master`, cached `origin/master`, and annotated `spec-v1.23.5` all point to `476d976`.
- Loaded the required Spec S1/S2 workflow rules before content changes.
- Verified through HTTPS `git ls-remote` that remote `master` and peeled `spec-v1.23.5` both point to `476d976`; no push was necessary.
- Added `US-TASK-027`, `BR-TASK-158..163`, `TaskBusinessResourceSummary`, `TaskLogContext`, optional task resource projections, four `atomic_tasks` snapshot columns, the partial composite index, and WorkflowRuntime log envelope v2 compatibility/security/download rules.
- Updated `CHANGELOG.md`; no errors, permissions, events, Domain Context, new tables, or Attempt persistence were changed.
- Created content commit `8924ab681d1c5b3de693d8b315ed80df241d390c` and added the `spec-v1.23.6` release record pointing to it.
- Created release commit `47eef7b4273bbf3c910ed95a880e04b503b40ac6`, annotated tag `spec-v1.23.6`, pushed both, and verified remote `master` plus the peeled tag at that commit.
- During downstream Server inspection, confirmed the existing download order is `occurred_at`, `level`, `source`, `message`; v1.23.6 module contract incorrectly states `occurred_at`, `source`, `level`, `message`.
- User approved an immutable v1.23.7 correction and overrode the prior legacy-data compatibility requirement: deployment will clear old Task Center/WorkflowRuntime data and logs will be v2-only.
- Updated S1 with `BR-TASK-164`/`AC-TASK-027-06`, made logs v2-only, corrected the download order, and documented the empty-data deployment gate in the module contract and changelog.

## Current in-progress work

- Create the v1.23.7 content commit, then add its release record and create the release commit/tag without rewriting v1.23.6.

## Files added, modified, renamed, or removed

- Modified: `docs/HANDOFF.md`.
- Content committed: `00_product/domains/task-center/product-spec.md`, `01_contracts/domains/task-center/openapi.yaml`, `01_contracts/domains/task-center/schema.sql`, `01_contracts/domains/task-center/module-contract.md`, and `CHANGELOG.md`.
- Committed for the release: `RELEASE.md`.
- Modified as the live post-release checkpoint: `docs/HANDOFF.md`.

## Key architectural or design decisions

- Add one optional immutable `primary_resource` snapshot for the top-level navigable business resource.
- Extend the existing WorkflowRuntime log contract to envelope v2 only; clear old persisted data instead of decoding v1/plain text.
- Do not add a log table, Attempt diff API, new error code, permission, event, or Domain Context change.

## API, schema, dependency, or configuration changes

- Added `TaskBusinessResourceSummary`, optional `primary_resource` on task response schemas, structured `TaskAttemptLog` fields, four `atomic_tasks` columns, and a partial composite index.
- No dependency or runtime configuration changes.

## Verification performed and remaining checks

- Verified the local and remote release/tag state. SSH reads failed twice, while the HTTPS read returned matching refs.
- Parsed Task Center OpenAPI successfully and resolved all 80 local refs; verified the new S1 anchors and passed `git diff --check`.
- Verified remote `refs/heads/master=47eef7b4273bbf3c910ed95a880e04b503b40ac6`, tag object `6991ad0b08b3a9daffd0ba166bf83f7816446a05`, and peeled `refs/tags/spec-v1.23.6^{}=47eef7b4273bbf3c910ed95a880e04b503b40ac6`.
- Re-parsed Task Center OpenAPI and resolved all 80 local refs; verified S1/no-legacy-data anchors and passed `git diff --check`.
- Remaining: content/release commits, tag, push, and remote verification for v1.23.7.

## Outstanding tasks

- Publish `spec-v1.23.7`, then update downstream pins before formal implementation.

## Known issues and risks

- Downstream Server/Web implementation must not pin v1.23.6 until its release tag is remotely verified.
- GitHub SSH connectivity failed during two early reads but succeeded for push and final ref verification.
- Server code at `backend/internal/apiserver/service/v1/taskcenter/task_logs.go` writes timestamp, level, source, message; v1.23.7 preserves that order.

## Exact recommended next step

Create the scoped v1.23.7 content commit, then add a release record pointing to it before creating the release commit/tag.

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
