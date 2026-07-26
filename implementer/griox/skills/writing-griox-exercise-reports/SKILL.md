---
name: writing-griox-exercise-reports
description: Use when writing or updating Vietnamese exercise reports under implementer/griox/basic after screenshots change and the report must mirror the source lab README in basic/.
---

# Writing Griox Exercise Reports

## Overview

Write the report from repo evidence, not memory. The workflow is: detect changed screenshot folders from `git diff` and `git status`, map each folder number to the source lab in `basic/`, assign screenshots to lab steps, then write a polished Vietnamese `README.md` in the style of `implementer/griox/basic/01/README.md`.

## When to Use

- New or updated screenshots appear under `implementer/griox/basic/<NN>/screenshots/`
- A report in `implementer/griox/basic/<NN>/README.md` needs to be created or refreshed
- The report must follow the lab flow from `basic/<NN>-*/README.md`

Do not use this for code changes unrelated to exercise-report writing.

## Required Workflow

1. First command: run `git diff --name-only`.
2. Second command: run `git status --short`.
3. Build the active screenshot set from both outputs:
   - tracked screenshot changes from `git diff --name-only`
   - untracked or modified screenshot files/folders from `git status --short`
4. From that combined set, isolate only paths matching `implementer/griox/basic/*/screenshots/*`.
5. If no screenshot path appears in either `git diff` or `git status`, stop. Do not guess the target folder from `ls`, `find`, or existing files.
6. Group changed screenshots by exercise folder `<NN>`. Process each folder independently.
7. Map `<NN>` to the source lab by finding `basic/<NN>-*/README.md`.
8. Read three inputs before drafting:
   - the source lab README
   - the target report README, if it already exists
   - `implementer/griox/basic/01/README.md` as the style reference
9. Build a step-to-evidence table with:
   - source step
   - expected proof
   - matched screenshot filenames
10. Match screenshots to steps using this priority:
   - visible terminal/browser content inside the image
   - filename keywords
   - source README step order
11. If a screenshot is ambiguous, place it by the most specific Kubernetes artifact visible. Use filename only as supporting evidence.
12. If a required step has no proof, do not invent certainty. Either keep the prose factual and limited, or call out that the screenshot set does not show that step clearly.
13. Write or update `implementer/griox/basic/<NN>/README.md`.

Never skip steps 1 and 2. The active screenshot folders are decided by the union of `git diff --name-only` and `git status --short`. `ls` and `find` may help later, but they are not allowed to choose the target folder by themselves.

## Report Contract

The report must:

- Be written in Vietnamese and xưng là `em`
- Start with a short intro linking back to the source lab README
- Follow the source lab order, not screenshot filename order
- Use numbered sections for the main flow
- Put `Ảnh bằng chứng:` immediately before the relevant screenshot links
- Omit `Lệnh sử dụng:` blocks unless explicitly required
- End with `Tổng kết`

When the lab has a bonus section, keep it as a separate final section.

## Matching Heuristics

- `config-*` screenshots usually belong to environment setup before the exercise flow
- `create-*`, `namespace-*`, `apply-*`, `describe-*`, `scale-*`, `delete-*`, `bonus-*` are strong filename hints
- For two-image evidence, prefer one image for the action and one for the result
- The same screenshot should not be used twice unless one image genuinely proves two inseparable facts

## Verification Checklist

- [ ] The workflow started from `git diff --name-only` and `git status --short`, not from a guessed folder
- [ ] Every changed screenshot under the target folder is used or intentionally excluded with a reason
- [ ] Section order matches `basic/<NN>-*/README.md`
- [ ] Screenshot paths are relative and valid
- [ ] Tone matches `implementer/griox/basic/01/README.md`
- [ ] The report does not claim steps that the screenshots do not support

## Common Mistakes

| Mistake | Fix |
|---|---|
| Drafting from filenames only | Read the source README and inspect the screenshot meaning first |
| Ignoring untracked screenshot files | Read `git status --short` in addition to `git diff --name-only` |
| Jumping straight into a guessed folder | Prove the target folder first with `git diff --name-only` and `git status --short` |
| Writing sections in screenshot order | Reorder sections to match the lab flow |
| Rewriting commands into a different environment | Describe commands the way the screenshots actually prove them |
| Mixing `mình` and `em` | Use `em` consistently |

## Red Flags

- Starting from folder guessing instead of repo change signals
- Reading only `git diff` and forgetting untracked screenshot files in `git status`
- Choosing the exercise folder because it already exists
- Inferring the target from `ls`, `find`, or README links before checking the diff

If any red flag appears, restart the workflow from `git diff --name-only` and `git status --short`.
