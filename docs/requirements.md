# Functional requirements — Graph Knowledge App

Version: 0.1 — Initial draft  
Status: Planning

## Purpose

Manage interconnected Markdown pages that users can explore and arrange spatially
in a persistent knowledge graph. This document describes intended behavior;
it does not indicate that these features have been implemented.

## RF-01 — Markdown pages

- Create, read, edit, and delete Markdown pages.
- Keep a unique, stable identity for each page.
- Associate each page with a file using a path relative to the document root.
- Support links between pages using Markdown syntax: `[text](path)`.
- Update relationships when a page is created, edited, moved, or deleted.

## RF-02 — Knowledge graph

- Represent each page as a node and each page link as a directed edge.
- Find directly and indirectly connected pages.
- Find paths between pages and retrieve subgraphs.
- Filter nodes by their properties.
- Reflect page changes in the graph without disrupting navigation.

## RF-03 — Spatial organization

- Give each node a persistent position on a virtually infinite hexagonal grid.
- Allow users to drag and reposition nodes, zoom, and pan.
- Restore saved positions across sessions.
- Allow at most one node per cell in each view.
- Handle moves into occupied cells; the conflict behavior remains to be agreed.

## RF-04 — Spatial searches

- Retrieve nodes within a selected area or coordinate range.
- Find nodes within a specified hexagonal distance.
- Search rings and regions of the grid.
- Display the subgraph relevant to the visible area.

## RF-05 — Automatic layouts

- Support manual arrangement, radial layouts around a selected node, and
  force-directed layouts similar to Obsidian's graph view.
- Place automatically arranged nodes on the hexagonal grid.
- Let users preview a layout and confirm before saving it.
- Never overwrite manual positions with an automatic layout without confirmation.

## RF-06 — Multiple views

- Create different spatial views of the same logical graph.
- Keep positions independent between views.
- Switch views without changing page relationships.
- Restore views across sessions.

## RF-07 — Position saving and recovery

- Reflect dragging immediately, without waiting for a remote save.
- Save pending position changes automatically after a short pause and periodically
  while changes remain pending.
- Save the latest position of each changed node.
- Preserve unsaved changes when the network is unavailable and retry saving.
- Protect saved positions from concurrent or out-of-order updates.

## RF-08 — Persistence

- Preserve pages, relationships, and positions between sessions.
- Keep page contents and graph relationships consistent.
- Restore the saved spatial state when a view is opened.
- Do not automatically recalculate a layout when opening a view.

## User experience constraints

- Graph interactions must remain responsive during saving or network delays.
- Support progressive exploration of large graphs.
- Prioritize a simple experience for one or two users per instance.
- Support self-hosting without mandatory proprietary cloud services.

## Open behavior questions

These questions require discussion before implementing the affected behavior:

- What happens when a user moves a node into an occupied cell?
- Should users also be able to position nodes freely outside the grid?
- How are broken links and links affected by page moves or renames presented?
- How should changes made to page files outside the application appear?
- How should conflicting edits be resolved and presented to the user?
- What graph size should the initial experience support?
- Where should newly created nodes appear in a view?

## Initial MVP scope

- Create, read, edit, and delete Markdown pages.
- Derive relationships from page links and preserve the graph.
- Display interactive nodes and edges.
- Arrange nodes by dragging them on a hexagonal grid.
- Save and restore positions.
- Support basic graph and spatial searches.
- Save position changes automatically without interrupting interaction.

## Deferred scope

- Force-directed layouts.
- Advanced radial layouts.
- Multiple views.
- Real-time collaboration.
- Advanced optimization for very large graphs.
