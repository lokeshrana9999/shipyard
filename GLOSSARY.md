# Shipyard

Agent Skills that take a code change through a delivery pipeline. These terms are the ones the skills, docs, and settings files share.

## Language

**Stage**:
One step of the delivery pipeline (explain, plan, test design, implement, verify live, review, describe, demo), run by one skill or by the agent's normal session.
_Avoid_: step, phase

**Handoff**:
The line that ends a stage skill by naming the stage that comes next, or one stage per outcome; it names stages, it never starts them.
_Avoid_: routing, next step

**User-started skill**:
A skill the agent never starts on its own; only the user starts it, with its command in Claude Code or by asking for it by name in other agents.
_Avoid_: user-invoked, user-only, manual skill

**Settings file**:
A project's `.claude/shipyard/<skill>.md`, whose values win over a skill's defaults.
_Avoid_: overlay, config

**House default**:
A default value or rule the maintainers chose by judgment, with no source or measurement behind it.
_Avoid_: guess, arbitrary default, unsourced default

**Adapter**:
The tool-specific part of the migration skill: which tool a project uses, how it is detected, and the commands that create, apply, and check migrations. Shipped per tool, overridden by the settings file.
_Avoid_: driver, provider, backend

**Role**:
A named job an agent does in a run (`implement`, `verify`, `live-run`, and the rest of the 13 in `docs/models.md`); the unit a model is configured per.
_Avoid_: agent type, persona

**Model layer**:
One of the places a role's model is read from, in order: the project's `.claude/shipyard/models.md`, the user's `~/.claude/shipyard/models.md`, the default.
_Avoid_: model config level, tier

**Seat**:
One agent continued by message across several tasks of a run, so the files it read stay in its context; replaced, not resumed, once its cache has expired.
_Avoid_: persistent agent, worker, task agent

**Development database**:
A database whose data can be lost without harming anyone. Defined by that role, not by where it is hosted.
_Avoid_: local database, dev DB

**Risky change**:
A schema change whose generated migration can lose data or lock a busy table. The migration skill lists them in one table and stops for every one.
_Avoid_: dangerous change, destructive change

**Gate**:
A point in a skill where the agent stops, shows what it is about to do, and waits for the user to choose.
_Avoid_: checkpoint, approval step
