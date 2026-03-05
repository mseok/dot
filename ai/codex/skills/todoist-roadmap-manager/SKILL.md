---
name: todoist-roadmap-manager
description: Manage Todoist roadmap execution for research programs. Use when tasks must be structured into multiple projects, labels standardized, milestone names normalized, due dates synchronized idempotently, or accidentally completed tasks restored.
---

# Todoist Roadmap Manager

## Parse Inputs

Parse user roadmap entries into normalized records with:
- `project_name`
- `task_name`
- `due_date` (`YYYY-MM-DD`)
- `labels[]`
- `priority` (`1-4`)
- `description` (optional)

Require explicit calendar dates for due dates when possible. If the user gives a relative expression (for example, "end of April"), confirm or apply a stated default and report the concrete date used.

## Normalize Names

Normalize project, label, and task names as follows:
- Preserve project names exactly as provided by the user.
- Normalize labels to lowercase kebab-case.
- Default milestone tasks to `[Milestone] <name>` unless the user provides an exact task title to keep.

## Sync Idempotently

Execute idempotent sync in this order:
1. List existing projects, labels, and tasks in target projects.
2. Upsert projects by exact name match.
3. Upsert labels by exact label string.
4. For each normalized task record, match by `project_id + content`.
5. Update matching tasks (`due_date`, `labels`, `priority`, `description`).
6. Create tasks only when no match exists.

Never delete, close, or move tasks unless the user explicitly asks.

## Recover Accidental Completion

Recover accidentally completed tasks with:
1. Query completed tasks in the target project and recent window.
2. Select only tasks that match the user recovery intent.
3. Reopen selected tasks.
4. Re-query active tasks and report restored IDs.

Prefer a bounded window first (for example, the last 30-90 days), then widen only if needed.

## Use Todoist Tools in Sequence

Use tools in this sequence:
1. Discover state: `get_projects_list`, `get_labels_list`, `get_tasks_list`.
2. Create missing entities: `create_projects`, `create_labels`.
3. Sync tasks: `create_tasks` or `update_tasks`.
4. Recover by completion status: `get_completed_tasks` then `reopen_tasks`.
5. Verify: `get_tasks_list` with project filters and optional text search.

## Return Change Log

Return a concise report with:
- Projects created or reused
- Labels created or reused
- Tasks created, updated, or reopened with IDs
- Explicit exclusions (for example, "NeurIPS not modified")

## Match Trigger Phrases

Trigger this skill when requests include patterns such as:
- "Reflect these milestones in Todoist with proper tags."
- "Create separate projects and sync roadmap deadlines."
- "I completed tasks by mistake, restore them."
