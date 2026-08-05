# Article-Derived Interface Details

Source: Jakub Krehel, "Details That Make Interfaces Feel Better"
URL: https://jakub.kr/writing/details-that-make-interfaces-feel-better

Use this reference when you need concrete defaults or want to check whether a polish pass is grounded in specific interaction details instead of vague taste.

## Text and Numbers

### Balance short text blocks

- Prefer `text-wrap: balance` for short headings, cards, and compact marketing copy.
- Use `text-wrap: pretty` only if you need a similar result and are comfortable with the heavier algorithm.
- Skip both on long-form body copy unless the layout actually benefits.

```css
.balanced {
	text-wrap: balance;
}
```

### Make text crisper when it helps

- On macOS, `-webkit-font-smoothing: antialiased` can make light text feel cleaner and less heavy.
- Apply this at the layout or root level only after checking the actual font rendering.

```css
html {
	-webkit-font-smoothing: antialiased;
}
```

Tailwind: `antialiased`

### Stabilize live-updating numerals

- Use `font-variant-numeric: tabular-nums` for counters, charts, timers, tables, prices, and metrics.
- Some fonts noticeably change the numeral design with tabular figures. Check the font before rolling it out broadly.

```css
.stable-numbers {
	font-variant-numeric: tabular-nums;
}
```

Tailwind: `tabular-nums`

## Shape and Depth

### Keep nested radii concentric

- Use the rule: `outer radius = inner radius + padding`.
- Apply it to cards inside panels, inputs inside containers, button groups, and any nested rounded surfaces.
- Mismatched radii make components feel subtly sloppy even when the layout is correct.

Example:

- inner radius: `12px`
- padding around inner element: `8px`
- outer radius: `20px`

### Prefer soft shadow borders when appropriate

- Replace low-contrast borders with a shadow stack when you want gentle separation that still works on varied backgrounds.
- Darken the same stack slightly on hover instead of switching to a different visual language.
- If the element needs to animate between resting and hover states, include `box-shadow` in the transition.

```css
.surface-shadow {
	box-shadow:
		0 0 0 1px rgba(0, 0, 0, 0.06),
		0 1px 2px -1px rgba(0, 0, 0, 0.06),
		0 2px 4px 0 rgba(0, 0, 0, 0.04);
	transition: box-shadow 160ms ease;
}

.surface-shadow:hover {
	box-shadow:
		0 0 0 1px rgba(0, 0, 0, 0.08),
		0 1px 2px -1px rgba(0, 0, 0, 0.08),
		0 2px 4px 0 rgba(0, 0, 0, 0.06);
}
```

### Outline images lightly

- Add a `1px` outline with about `10%` opacity so image edges stay legible against busy or similar-toned backgrounds.
- Switch the outline color for dark mode instead of using one fixed border color.

```css
.image-outline {
	outline: 1px solid rgba(0, 0, 0, 0.1);
	outline-offset: -1px;
}

.dark .image-outline {
	outline-color: rgba(255, 255, 255, 0.1);
}
```

## Motion and Interaction

### Animate contextual icon swaps

- When an icon appears only in response to state, combine `opacity`, slight `scale`, and light `blur`.
- This works well for copy buttons, disclosure toggles, favorite states, and inline action confirmations.
- Use springs or short transitions. Avoid bouncy novelty unless the product language already supports it.

Practical pattern:

- enter: `opacity: 0 -> 1`
- scale: `0.85 -> 1`
- blur: `4px -> 0`

### Make interactions interruptible

- Use transitions or retargetable spring/state animations for hover, open, rotate, and toggle interactions.
- Reserve keyframes for staged sequences that play once and do not need to respond to changed user intent.

Rule of thumb:

- user-controlled interaction: transition or spring
- one-way reveal sequence: keyframes are fine

### Split and stagger entering elements

- Animate smaller units instead of one large wrapper.
- Good default: stagger sections by about `100ms`.
- For split titles or word-by-word entrances, about `80ms` per word is a reasonable starting point.
- Common enter properties: `opacity`, `translateY`, and light `blur`.

```css
@keyframes enter {
	from {
		transform: translateY(8px);
		filter: blur(5px);
		opacity: 0;
	}
}

.animate-enter {
	animation: enter 800ms cubic-bezier(0.25, 0.46, 0.45, 0.94) both;
	animation-delay: calc(var(--delay, 0ms) * var(--stagger, 0));
}
```

### Make exits softer than entrances

- Keep some directional motion so the state change stays legible.
- Reduce the exit travel distance compared with the enter motion.
- A small fixed offset like `-12px` is often enough when a full container-height exit feels too loud.

## Optical Alignment

### Align by eye, not just by math

- Icon-and-text buttons often need slightly asymmetric padding so the content feels centered.
- Some icons visually lean left, right, high, or low even when their viewBox is mathematically centered.
- Adjust the SVG itself for reusable fixes. Use local margin or padding only for one-off cases.

Check these cases first:

- play icons
- stars
- arrows in buttons
- mixed icon sizes in segmented controls

## Review Checklist

- Does any short headline break awkwardly?
- Do changing numbers shift width or cause layout jitter?
- Do nested rounded surfaces use concentric radii?
- Are borders doing work that a soft shadow should do better?
- Do images need an outline to stay readable on their background?
- Do icon swaps pop abruptly instead of transitioning into place?
- Can the user reverse an interaction before the animation finishes?
- Are enter animations split into meaningful pieces rather than one big slab?
- Are exits softer and shorter than entrances?
- Do icon-and-text controls look centered by eye, not only by measurement?
