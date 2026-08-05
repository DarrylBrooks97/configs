# Personal Design System Guidelines

Rules for crafting quality software. Always apply these principles.

> Canonical visual reference: `docs/design-system.html` — the complete token sheet (light + dark), type/space/radius/duration scales, iconography, identity, voice, component vocabulary, and validated chart palettes. Agents building UI should read it before inventing styles; it also tracks known drift between this canon and shipped code.

## Core Design Philosophy

### 1. Prioritize the User Experience Over Visual Flair
Design Engineers at Vercel focus on **performance, accessibility, and page speed** before flashy animations. As Rauno Freiberg notes, "primitives such as performance and accessibility are not as glamorous...but is having a slow website with immaculate attention to visual craft desirable?" The answer is no—balance craft with substance. [Source](https://raunofreiberg.com/craft/vercel)

### 2. Build Reusable, Generic Components
Don't build for linear impact—aim for **multiplicative reuse**. John Pham from Vercel emphasizes: "Even when building what seems like a one-off animation...think about how we can reuse this in the future." Spend time upfront making components generic enough to work across different contexts rather than reworking them later. [Source](https://www.youtube.com/watch?v=U9X2tgPYcNk)

### 3. Animation Should Serve Purpose, Not Distract
Emil Kowalski's philosophy centers on **purposeful animation**:
- Use animations to indicate state changes and guide user attention
- Never animate keyboard-initiated actions (repeated hundreds of times daily)
- Keep animations under 300ms for snappy feel; use `ease-out` for responsiveness
- Respect `prefers-reduced-motion` for accessibility
- Animate with `transform` and `opacity` for 60fps performance [Source](https://emilkowal.ski/ui/great-animations)
- When visually presenting newly loaded items, use the standard blur reveal unless an existing local motion pattern already covers it: start at `opacity: 0`, a small vertical offset, and `filter: blur(6px-8px)`, then settle to `opacity: 1`, no offset, and `filter: blur(0px)` in about 180-240ms. Disable the offset/blur for reduced motion.

### 4. Develop Taste Through Iteration
Emil describes taste as the "magical ingredient"—knowing **why** an animation feels right or wrong. This comes from constant practice, reviewing your work with fresh eyes, and ensuring the easing, duration, and feel match the overall product identity. Sonner succeeds because "the whole experience of using it is cohesive." [Source](https://animations.dev)

## Craft & Collaboration

### 5. Blur the Line Between Design and Engineering
Derek Briggs advocates for **dedicated UI Engineers** on design teams—not product engineering. This enables pixel-perfect execution and creates a feedback loop where designers and engineers level each other up. The key insight: "The users never see the Figma files. Your design quality matters in the product, not the handoff document." [^1]

### 6. Sweat the Small Details
At Clerk, Derek focuses on subtle refinements that most engineers don't notice:
- Using shadows as borders instead of hard lines
- Applying subtle gradients
- Precise alignment techniques
- These micro-decisions compound into a polished, trustworthy interface [^1]

### 7. Design in Code, Not Just Figma
Vercel's Design Engineers often prototype directly in code for animations, keyboard controls, and touch interactions—these are "better implemented in code to save the time and effort of reimplementing them from a different medium." Skip traditional handoffs; iterate in the final medium. [Source](https://vercel.com/blog/design-engineering-at-vercel)

## System & Process

### 8. Create Constraint-Based Systems
Vercel's Geist design system establishes clear rules through:
- Consistent grid systems (360px columns with readable line-length)
- Deliberate use of intersection points and visual hierarchy
- Typography and iconography designed at specific sizes (16×16px icons, 1.5pt stroke)
- CSS variables for spacing, padding, and breakpoints that adapt across viewports [Source](https://glenn.me/vercel)

### 9. Progressive Enhancement
Build experiences that work without JavaScript first. Vercel's hero sections are composed of layered CSS, SVG, and only progressively enhanced with shaders. This ensures fast initial paint and graceful degradation. [Source](https://raunofreiberg.com/craft/vercel)

### 10. Quality Creates Business Value
Derek Briggs on the business case: "When you look at a product that the team cares about what it looks like...it helps with adoption." High craft signals trustworthiness and attracts both users and talent—creating a flywheel where great designers want to work at companies known for quality. [^1]

[^1]: https://www.youtube.com/watch?v=z4hP80tzBL4

## References
- [Crafting with Vercel](https://raunofreiberg.com/craft/vercel)
- [Making software](https://www.makingsoftware.com/)
- [Great Animations](https://emilkowal.ski/ui/great-animations)
- [Design Engineering at Vercel](https://vercel.com/blog/design-engineering-at-vercel)
