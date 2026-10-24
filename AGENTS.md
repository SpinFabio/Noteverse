# Collaboration rules

## Repository structure

- Noteverse is a monorepo containing the backend, frontend, documentation, and
  root-level development orchestration.
- Consider repository-wide effects while keeping component-specific work within
  the relevant component directory.
- Run backend tools from `backend/` and Flutter/Dart tools from `frontend/`.
- Present user-facing commands as executable from the repository root. When a
  command must run in a component directory, show how to enter that directory
  and return to the root afterward.
- Prefer root Makefile targets for workflows involving multiple components.

## Workflow

- Start with an iterative discussion of the idea and its requirements.
- Before implementing, propose a concrete implementation plan and wait for the
  user's explicit approval. Do not interpret silence as approval.
- Requests to discuss, investigate, or plan are not authorization to implement.
- Implement one approved step at a time and only within the approved scope. Do
  not add features, dependencies, infrastructure, refactors, or other changes on
  your own initiative.
- Do not create, modify, or run tests during the implementation phase. Treat
  testing as a separate phase requiring explicit approval.
- After implementation, let the user review the result and address feedback
  iteratively before proceeding.
- Create a commit only after the user has validated the implementation and
  explicitly requested the commit.
- Track the agreed project direction in `documentation/todo-list.md`. Its
  milestones are ordered, high-level outcomes; its backlog contains specific
  activities discovered during development but not yet assigned to a milestone.
  Discuss additions and milestone changes before recording them.

## Communication

- Be precise and concise unless the user explicitly requests brainstorming or a
  broader exploration.
- Express doubts, advice, risks, and proposals openly instead of silently making
  decisions.
- If anything is unclear, state the uncertainty and discuss it before
  implementing the affected behavior.
- If instructions, documentation, or code conflict, explain the conflict and
  resolve it with the user. Do not choose a resolution silently.
- When a conflict is first identified, report it explicitly in the conversation
  before recording it with a project tag.
- Assume commands given to the user are run from the project root. If a command
  must run in a component directory, show the command to enter that directory
  and the command to return to the project root. State the shell when the syntax
  is shell-specific. Prefer root Makefile targets when an appropriate target
  already exists.
- When discussing Dart or Flutter, do not assume prior familiarity. Explain the
  relevant framework concepts and idiomatic approach, distinguish deterministic
  corrections from design decisions, and discuss meaningful tradeoffs before
  making non-trivial choices.

## Documentation

- Write all project documentation in English.
- Use the root README to present the project, state its current maturity, and
  link to the files in `documentation/`.
- Keep functional requirements and user flows focused on observable product
  behavior. Do not document endpoint edge cases or implementation choices there.
- Keep installation prerequisites, configuration, and startup instructions in
  `documentation/getting-started.md`.
- Document implementation details, technical edge cases, and design choices next
  to the relevant code. Use FastAPI and Pydantic's generated documentation
  capabilities where applicable.
- In Python, use Pydantic field descriptions where applicable. In Flutter/Dart,
  use documentation comments (`///`) for relevant classes, properties, and
  methods. Discuss broader Dart documentation conventions before introducing
  them.

## Project tags

Use these exact, searchable tags in relevant code or documentation after the
subject has been discussed:

- `[[TODO]]`: a concrete, agreed task that has not been completed.
- `[[TBD]]`: a decision that still needs to be made.
- `[[CONFLICT]]`: an unresolved inconsistency, problem, or risk, including one
  intentionally postponed for later resolution.

Add a short explanation on the same line or immediately after each tag. Remove
the tag when its subject has been resolved.

## Development environment

- Use the root Makefile as the entry point for common development actions. Keep
  its help text simple and in English.
- In development, run Neo4j in Docker and the backend and frontend as local
  processes. Do not introduce PostgreSQL unless a concrete need is discussed and
  approved.
- Keep container service commands (`services-up`, `services-down`) separate from
  local development commands (`be-up`, `fe-up`). Use `dev-all-up` to start both
  container services and local development processes; stopping that launcher
  must leave the containers running.
- Treat running frontend and backend images together in Docker Compose as a
  separate workflow requiring its own approved plan.

## Tests

- Keep backend tests in `backend/tests/` and frontend tests in `frontend/test/`
  (Flutter convention). Do not create a root-level test directory.
- Keep checks requiring a live stack separate from the default local test run.
