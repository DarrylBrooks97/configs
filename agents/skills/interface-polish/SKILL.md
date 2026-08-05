---
name: interface-polish
description: Personal product UI polish. Use when refining an existing interface, reviewing spacing/typography/motion/accessibility, or making a product UI feel more cohesive without changing product behavior.
---

# Interface Polish

Polish should make the product clearer, faster-feeling, and more trustworthy. Do not replace the product's visual language with a new aesthetic direction.

## First Principles

- Read `references/design-system.md` before broad visual changes.
- Prioritize accessibility, performance, and page speed over visual flair.
- Reuse existing product primitives and tokens before adding new variants.
- Keep components generic enough to reuse when the pattern is not screen-specific.
- Respect dense, empty, loading, error, and long-content states.

## High-Leverage Details

Check these in order:

1. **Hierarchy:** headings, labels, metadata, and actions have obvious priority.
2. **Spacing:** related items are grouped; unrelated sections breathe.
3. **Typography:** numbers, dates, and identifiers align and scan well.
4. **Borders and shadows:** subtle separation; avoid heavy outlines unless the local pattern uses them.
5. **Icon alignment:** icons sit optically centered with text and hit targets remain accessible.
6. **Motion:** state changes are purposeful, short, transform/opacity-based, and disabled or simplified for reduced motion.
7. **Responsive states:** no clipped text, unusable controls, or awkward empty space at common widths.

## Motion Defaults

- Prefer `ease-out` and durations under 300ms.
- Do not animate keyboard-initiated actions that users repeat often.
- For newly loaded items, use the standard blur reveal: opacity from 0 to 1, small vertical offset, `filter: blur(6px-8px)` to `blur(0)`, about 180-240ms; remove offset/blur for reduced motion.

## Deliverable

When changing code, include the focused check used for the affected surface, refresh `bun.lock` if package metadata changed, and finish with:

```bash
bun install   # when dependencies/package metadata changed
bun fmt && bun check
```
