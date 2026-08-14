# OmniMAM Spec Handoff

## Current goal and status

- Goal: publish the Task Center business-resource association and structured diagnostic contract as `spec-v1.23.6`.
- Status: in progress. The approved v1.23.6 content commit is `8924ab681d1c5b3de693d8b315ed80df241d390c`; the release record is prepared and awaits its release commit/tag/push.

## Work completed in this session

- Re-read the Spec S1/S2 workflow rules and confirmed the approved v1.23.6 scope.
- Resumed from the existing checkpoint and verified local `master`, cached `origin/master`, and annotated `spec-v1.23.5` all point to `476d976`.
- Loaded the required Spec S1/S2 workflow rules before content changes.
- Verified through HTTPS `git ls-remote` that remote `master` and peeled `spec-v1.23.5` both point to `476d976`; no push was necessary.
- Added `US-TASK-027`, `BR-TASK-158..163`, `TaskBusinessResourceSummary`, `TaskLogContext`, optional task resource projections, four `atomic_tasks` snapshot columns, the partial composite index, and WorkflowRuntime log envelope v2 compatibility/security/download rules.
- Updated `CHANGELOG.md`; no errors, permissions, events, Domain Context, new tables, or Attempt persistence were changed.
- Created content commit `8924ab681d1c5b3de693d8b315ed80df241d390c` and added the `spec-v1.23.6` release record pointing to it.

## Current in-progress work

- Validate the release diff, create the release commit and annotated `spec-v1.23.6` tag, then push and verify both remote refs.

## Files added, modified, renamed, or removed

- Modified: `docs/HANDOFF.md`.
- Content committed: `00_product/domains/task-center/product-spec.md`, `01_contracts/domains/task-center/openapi.yaml`, `01_contracts/domains/task-center/schema.sql`, `01_contracts/domains/task-center/module-contract.md`, and `CHANGELOG.md`.
- Modified for the release commit: `RELEASE.md` and `docs/HANDOFF.md`.

## Key architectural or design decisions

- Add one optional immutable `primary_resource` snapshot for the top-level navigable business resource.
- Extend the existing WorkflowRuntime log contract to envelope v2 while retaining v1 and plain-text compatibility.
- Do not add a log table, Attempt diff API, new error code, permission, event, or Domain Context change.

## API, schema, dependency, or configuration changes

- Added `TaskBusinessResourceSummary`, optional `primary_resource` on task response schemas, structured `TaskAttemptLog` fields, four `atomic_tasks` columns, and a partial composite index.
- No dependency or runtime configuration changes.

## Verification performed and remaining checks

- Verified the local and remote release/tag state. SSH reads failed twice, while the HTTPS read returned matching refs.
- Parsed Task Center OpenAPI successfully and resolved all 80 local refs; verified the new S1 anchors and passed `git diff --check`.
- Remaining: release commit, annotated tag creation, push, and remote commit verification for v1.23.6.

## Outstanding tasks

- Create the release commit and annotated tag, push, and verify the remote refs.

## Known issues and risks

- Downstream Server/Web implementation must not pin v1.23.6 until its release tag is remotely verified.
- GitHub SSH connectivity is currently intermittent; use HTTPS read-only verification if SSH ref checks fail again.

## Exact recommended next step

Run `git diff --check`, commit `RELEASE.md` and `docs/HANDOFF.md`, create annotated tag `spec-v1.23.6`, then push `master` and the tag.

Next Prompt:

Read docs/HANDOFF.md, verify the current implementation, and continue with the next outstanding task. Do not repeat completed work.
