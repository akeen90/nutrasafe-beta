## Guidance
- Use **Builder** when adding new features, redesigns or cross‑cutting changes that affect multiple screens, data models, or flows.
- Use **Coder** when applying targeted code changes with already‑defined requirements (bug fixes, small UI tweaks, local refactors).

## Builder Outputs (before coding)
- Problem statement, goals, and scope
- UX flows/wireframes and component list
- Data model/API changes and migration plan
- Acceptance criteria, telemetry and error states
- Risks, rollback, and release plan

## Coder Outputs (implementation)
- Code changes across affected modules following app conventions
- Unit/UI tests and build verification
- Instrumentation and feature flags if needed
- Lightweight docs in code (names/structure) and changelog notes

## Recommended Workflow
1. Kick off with Builder for the feature: define scope, UX, data contracts, acceptance criteria.
2. Review/adjust plan; freeze specs.
3. Hand off to Coder: implement, test, and verify on devices.
4. Ship behind a flag if risky; monitor telemetry.

## Decision Checklist
- Touches more than one layer (UI + models + persistence)? → Builder first.
- Needs new interactions/controls/components? → Builder first.
- Simple, isolated tweak with clear spec (e.g., spacing, text, minor logic)? → Coder.

If you confirm, I’ll start in Builder to capture the feature spec and acceptance criteria, then proceed with Coder to implement. 