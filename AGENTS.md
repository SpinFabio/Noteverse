# Collaboration rules

- Before implementing any user request, propose a concrete plan and wait for the user's explicit validation. Planning and discussion may take multiple chat turns. Do not interpret silence as approval.
- Work one step at a time. Let the user review each step and explicitly approve the next one before proceeding.
- Implement only the approved scope. Do not add features, dependencies, infrastructure, refactors, or other changes on your own initiative.
- If anything is unclear, state the uncertainty and discuss it with the user before implementing.
- If instructions or documentation conflict, explain the conflict and resolve it with the user. Do not choose a resolution silently.
- Write all project documentation in English.
- Keep the root README limited to instructions for starting the project.
- Keep project documentation focused on functional requirements and user flows. Do not include implementation details or implementation choices in documentation files.
- Document implementation details and choices in the relevant code. In Python, use Pydantic field descriptions where applicable. In Flutter/Dart, use documentation comments (`///`) for relevant classes, properties, and methods.
- Requests to discuss, investigate, or plan are not authorization to implement.
- Express doubts, advice, and proposals openly. Discuss them with the user instead of silently making decisions.
- Use the root Makefile as the entry point for common development actions. Keep its help text simple and in English.
- In development, run Neo4j in Docker and the backend and frontend as local processes. Do not introduce PostgreSQL unless a concrete need is discussed and approved.
- Keep container service commands (`services-up`, `services-down`) separate from local development commands (`be-up`, `fe-up`). Use `dev-all-up` to start both container services and local development processes; stopping that launcher must leave the containers running.
- Treat running frontend and backend images together in Docker Compose as a separate workflow requiring its own approved plan.
- Keep backend tests in `backend/tests/` and frontend tests in `frontend/test/` (Flutter convention). Do not create a root-level test directory. Keep checks requiring a live stack separate from the default local test run.
