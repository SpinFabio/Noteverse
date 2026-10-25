# To-do list

Use this file to track the agreed direction of the project:

- **Milestones** are the ordered, high-level outcomes leading toward the MVP.
- **Backlog** contains specific activities discovered during development but not
  yet assigned to a milestone.

Discuss new entries and milestone changes before recording them here.

## Milestones

- [ ] Complete and validate the project setup.
- [ ] Build a functional frontend grid using mock data.
- [ ] Use the frontend prototype to define the backend interfaces.
- [ ] Implement the first backend endpoints.
- [ ] Add integration tests.
- [ ] Iterate on features until an agreed MVP is reached.

## Backlog

- [ ] Separate static checks from test execution in Make targets.
- [ ] Define and implement switchable main graph modes. Navigation allows
      panning only; exploration also opens a note-content preview on node click;
      edit allows panning, opens a modal note preview on double-click, and
      supports selecting and repositioning one or more nodes on the hex grid.
- [ ] Define node-selection interactions before implementing them, including
      whole-graph and subgraph selection. [[TBD]] Decide whether a selection
      must be connected; the meaning of a selection "without holes" remains
      undefined.
- [ ] Finalize the name and role of the layout editor (working name: Graph
      Layout Editor), distinguishing it from the main graph's grid-based edit
      mode. Use it for ZIP ingestion and rearranging existing nodes.
- [ ] Define and implement ZIP ingestion: read Markdown notes and standard
      Markdown links, arrange the imported graph in the layout editor, snap it
      to the hex grid, and confirm its insertion into the project. Define
      cancellation behavior before implementing the flow.
- [ ] Allow force-directed layout to target all project nodes or a selected
      subgraph. Define treatment of edges to unselected nodes, placement of the
      result, and collisions with occupied cells before implementing reinsertion.
- [ ] Persist applied graph coordinates through the backend and Markdown files.
- [ ] Define how newly imported graphs are positioned relative to existing
      canvas content.
- [ ] Support multiple saved views of the same graph.
- [ ] Optimize force-directed layout for large graphs after profiling it.
- [ ] Define how a graph project combines multiple imported Markdown archives.
      [[TBD]] Decide whether notes are shared across projects or copied, and how
      note identity, source paths, and project-specific positions are represented.
- [ ] Define and implement project-local links and persistent links. Local links
      affect only their graph project; persistent directed links add a standard
      Markdown reference at the end of the source note. Define cross-archive
      link resolution before implementing file updates.
