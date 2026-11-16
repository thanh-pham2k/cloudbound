# Cloudbound — Agent Execution Workflow

This is the standing workflow for future asset and integration tasks. It authorizes delegation within the user's active task scope; it does not start new work by itself. Explicit user instructions and repository asset/testing rules still apply.

## Roles

| Role | Responsibility | Required handoff |
|---|---|---|
| Orchestrator | Inspect current state, choose the next task, own asset direction, define batches, coordinate agents, review results and accept changes | Concrete brief, resource contract, file ownership, acceptance checks and checkpoint |
| Luna High Priority | Generate or repair real asset batches from the Orchestrator's references and brief, using the repository pipeline | Output paths, provenance, validation results, previews and unresolved quality issues |
| Hydrogen High | Implement gameplay code and integrate accepted assets while preserving existing behavior and balance unless instructed otherwise | Changed-file summary, resource mappings, executed checks, failures and remaining work |

Luna means the available `gpt-6-luna` model with reasoning `high` and service tier `priority` where supported. Hydrogen is the user's requested coding-agent designation; its model mapping must be established from actual tool availability or user configuration. Do not pretend that an unavailable model exists or silently select a replacement. Model selection and service tier are separate settings; do not claim a tier was set if the tool cannot set or confirm it.

With the current collaboration tool, a full-history fork inherits the parent's model and reasoning and cannot accept overrides. To select Luna explicitly, spawn with `fork_turns: "none"`, `model: "gpt-6-luna"`, `reasoning_effort: "high"` and provide a self-contained brief plus repository/checkpoint paths. Apply the same rule to Hydrogen once its actual model mapping is known. Use a full-history fork only when inherited configuration is appropriate. The spawn API has no service-tier parameter; report that limitation instead of claiming an explicit priority setting.

## Actions for each task

1. **Inspect and resume.** Read `AGENTS.md`, this workflow, relevant toolkit skills, the current task specification and its latest checkpoint. Inspect branch, Git status, tracked diff and untracked files. Preserve existing work and validated assets. Use current files and executed results as authoritative evidence.
2. **Define a bounded brief.** Assign a task/batch ID and record scope, references, expected outputs, acceptance criteria and owned files. Define animation names, frame counts, dimensions, pivot, loop/FPS settings, target paths and intended visual scale before delegation. Identify dependencies and existing READY assets to preserve.
3. **Delegate assets to Luna.** Supply the brief, references, toolkit requirements and exact output locations. Luna creates or repairs the batch and reports actual outputs and validation failures. Do not replace required AI-generated art with placeholders unless the active task permits it; report capability blockers honestly.
4. **Delegate code to Hydrogen.** Spawn with the agreed model configuration and an explicit brief; pass context according to the tool constraints above. Hydrogen may prepare code in parallel with Luna once the resource contract is fixed. Integrate actual assets after structural validation; label motion or visual review still pending. Never treat pending assets as READY. If Hydrogen's mapping is unavailable, report the missing mapping and continue independent authorized work; do not dispatch a substitute under its name.
5. **Control concurrent edits.** Default to at most one active asset batch and one active integration task. Give agents separate file ownership. Orchestrator owns shared checkpoint files. Coordinate ownership changes before edits; use isolated worktrees where necessary. Do not let agents overwrite each other's changes or validated assets.
6. **Review the handoff.** After Hydrogen finishes, Orchestrator inspects the actual diff and output files, confirms the resource contract and checks for unintended behavior/balance changes. An agent's completion message alone is not acceptance evidence.
7. **Validate.** Run `python3 scripts/tools/validate_assets.py`, Godot import and the relevant asset/resource audit when applicable, plus `git diff --check`. Record exact commands, exit codes, warnings and failures. Do not run simulated gameplay smoke tests, combat/AI playtests or multi-step runtime loops. The user tests gameplay directly in Godot. Structural PASS does not establish visual, motion or gameplay quality.
8. **Save state.** Update the task checkpoint and QA report after every Hydrogen handoff, including failed or partial handoffs. Save state before starting the next task. Record the next actionable step and any dependency on user playtesting.
9. **Continue or hand off.** Start the next independent task when authorized and safe. If required input or evidence is missing, preserve the incomplete status and describe what is needed. Do not claim completion until all original acceptance criteria have matching evidence.

Default flow:

```text
Orchestrator: brief + resource contract
    -> Luna: asset batch + QA
    -> Hydrogen: code + asset integration
    -> Orchestrator: review + validation + save state
    -> Next task / user gameplay verification
```

Hydrogen's code preparation may overlap Luna's asset generation; final integration and acceptance depend on actual validated outputs.

## Durable checkpoint contract

For the existing animation goal, use `docs/assets/animation_pack_qa/HANDOFF.md`, `PROGRESS.md` and `QA_REPORT.md`. For a new task, name its checkpoint location in the brief. Do not overwrite historical Gate A manifests as though they describe newly generated batches.

Each checkpoint must include the following information, either directly or through explicit links to the associated progress and QA reports. For a multi-file checkpoint, the files collectively form the saved state; do not duplicate command logs in every file. Older checkpoints may omit new fields: record them at the next real task handoff from current evidence, without inventing historical assignments or results.

- Task/batch ID, original objective, current branch and base commit; identify uncommitted work.
- Agent assignments, actual model configuration where known, and file ownership.
- Asset references/source paths, generated outputs, profiles and SpriteFrames mappings.
- Separate status for structural checks, visual/motion review and gameplay evidence. Use `STRUCTURAL_PASS`, `REVIEW_REQUIRED`, `NEEDS_REPAIR` or `FAILED` as appropriate; reserve READY for assets with the required approval evidence.
- Completed implementation, changed files and confirmed defects fixed.
- Commands actually executed, exit codes, evidence paths and outstanding warnings/failures. Mark unexecuted checks explicitly.
- Remaining work, blockers, pending user playtest cases and a concrete next action with its prerequisites.

On resume, inspect this saved state against the current worktree before issuing new agent actions. Forked conversation context is helpful but is not durable state.

Saving state means writing repository documentation. It does not imply permission to commit or push; do those only when authorized by the user for the relevant work.

## Workflow verification — 2026-11-16

- Verified the `AGENTS.md` workflow link and existence of the referenced checkpoint files, toolkit instructions and repository validation scripts.
- Successfully spawned a read-only probe using `gpt-6-luna`, reasoning `high`, `fork_turns: "none"`. The probe read the instructions and correctly reported task boundaries, required handoff fields, missing Hydrogen mapping and the need for user gameplay evidence. This proves delegation and instruction comprehension, not asset-generation quality.
- Corrected the original full-history fork wording to match the tool's model-override constraints. No service-tier parameter was set or verified.
- Clarified that linked checkpoint files collectively supply the required state, and older checkpoints must not be retroactively filled with invented evidence.
- Hydrogen dispatch and a complete asset-to-integration batch remain untested because the Hydrogen model mapping has not been supplied. No gameplay simulation or new asset generation was performed for this probe.
