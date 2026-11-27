# Hexora Flutter repository instructions

These instructions apply to the entire Flutter repository. Preserve narrower `AGENTS.md` instructions if they are added later.

## Changelog and product announcements

Whenever implementing a feature, improvement, or bug fix:

- Determine whether the change has a meaningful impact on an end user.
- Update the `Unreleased` section of `CHANGELOG.md` for meaningful changes.
- Classify each entry as `Feature`, `Improvement`, or `Bug Fix`.
- Describe the user benefit rather than internal implementation details.
- Prepare bilingual English and Spanish release notes for significant user facing changes.
- Store pending release notes as drafts in `release-notes/`.
- Give each draft a stable `announcement_key`. Before creating a draft, search both the current changelog and `release-notes/` for that key or the same user benefit. Update the existing draft instead of duplicating it.
- If a task changes both Hexora repositories, keep one release note draft in the repository that owns the primary user facing behavior. Reference its `announcement_key` from the other repository's changelog when useful.
- Do not create public announcement drafts for internal refactoring, development only changes, dependency maintenance, or minor styling changes.
- Do not publish announcements or write them to the production database without the user's explicit approval.
- Do not mark a draft approved, verified, released, or ready to import unless that state is supported by the work completed in the task.
- Never present unfinished, unverified, or unreleased functionality to customers as available.
- Include pending release note paths in the final task summary.

Preserve all existing changelog entries and repository instructions.

## Release note draft states

- `draft`: prepared for internal review.
- `approved`: explicitly approved by the user.
- `published`: imported and published through the Hexora announcement administration flow.

New drafts must start as `draft`. Verification and release readiness are separate fields and must remain accurate.
