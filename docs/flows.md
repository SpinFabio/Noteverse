# User flows

These flows describe the intended requirements, not the current implementation.
They do not resolve the open behavior questions in [requirements.md](requirements.md).

## Create and link pages

1. The user creates a Markdown page and enters its content.
2. The user saves the page.
3. The page becomes available as a node in the knowledge graph.
4. Links to other pages appear as directed relationships.

The initial placement of a new node remains to be agreed.

## Edit a page

1. The user opens an existing page.
2. The user edits its content or links and saves it.
3. The graph reflects the updated relationships while retaining the page's identity.

## Move or delete a page

1. The user moves or deletes a page.
2. Relationships reflect that change.

The treatment of links affected by a move, rename, or deletion remains to be agreed.

## Explore the graph

1. The user opens the graph and sees its saved arrangement.
2. The user pans or zooms to explore an area.
3. The application displays the relevant nodes and relationships.
4. The user can search for connected pages, paths, or nodes within an area.

## Reposition a node

1. The user drags a node to a hexagonal cell.
2. The node moves immediately on screen.
3. The application saves the latest position automatically.
4. Opening the view again restores the saved position.

The behavior when the destination cell is occupied remains to be agreed.

## Recover from a connection failure

1. The user changes node positions while saving is unavailable.
2. Pending changes are retained locally.
3. The application retries saving when connectivity becomes available.
4. The latest positions are preserved without older updates overwriting them.

Conflict resolution between concurrent changes remains to be agreed.

## Preview an automatic layout — deferred

1. The user selects a layout and, when required, a central node.
2. The application previews the proposed arrangement.
3. The user confirms before it replaces saved positions.

## Switch views — deferred

1. The user creates or selects another spatial view.
2. The application displays that view's saved positions.
3. Page relationships remain the same across views.
