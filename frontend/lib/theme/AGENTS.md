# Frontend theme rules

- Noteverse is dark-mode-first. Do not add a light theme until its behavior and
  palette have been discussed and approved.
- Use Material `ColorScheme` roles for standard UI semantics: `primary`,
  `secondary`, `tertiary`, `surface`, `error`, and their matching `on` roles.
  Material 3 `tertiary` is the application accent role.
- Use `NoteverseColors`, a `ThemeExtension`, for application-specific roles such
  as graph background, grid lines, graph origin, node, edge, and selection
  colors.
- Keep raw reusable color values in this directory. Widgets must resolve colors
  through `Theme.of(context)`; painters must receive resolved colors from their
  owning widget.
- Use light gray `0xFFE0E0E0`, not pure white, for the main foreground. Define
  lower-emphasis foreground roles separately instead of scattering opacity or
  gray literals through widgets.
- Use `0xFF303030` as the default graph background. A user-selected background
  is a persisted runtime override; restoring defaults must return to the theme
  token.
- Add a semantic token instead of reusing an unrelated role solely because its
  current color happens to match. Discuss new roles and palette changes before
  introducing them.
- Preserve readable contrast between every surface and its corresponding
  foreground role.
- Keep floating menus solid and visually elevated above the canvas. Do not add
  backdrop blur unless its performance impact has been discussed and approved.
- Use circular shapes for icon-only controls and fully rounded pill shapes for
  text buttons. Define these defaults in the application theme instead of
  styling each button independently.
- Interpret a requested lighter or darker "shade" as movement between discrete
  palette steps, such as neutral 800 to neutral 900, not as a color gradient.
  Keep those scale values centralized in `NoteversePalette`.
