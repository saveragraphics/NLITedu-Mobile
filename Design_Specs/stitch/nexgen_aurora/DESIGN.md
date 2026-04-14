# Design System Specification: Editorial EdTech Excellence

## 1. Overview & Creative North Star

### Creative North Star: "The Digital Curator"
This design system moves away from the clinical, "boxed-in" feel of traditional Learning Management Systems (LMS). Instead, it adopts the persona of a **Digital Curator**: an authoritative yet innovative environment that treats educational content like high-end editorial features. 

The aesthetic is defined by **Tonal Depth** and **Asymmetric Balance**. We break the "template" look by utilizing significant white space, overlapping glass elements, and a radical departure from traditional borders. The system feels innovative through its use of vibrant violet gradients and accessible through its meticulous typographic hierarchy. It is not just a tool for learning; it is a premium space for intellectual growth.

---

## 2. Colors & Surface Philosophy

The palette transitions from deep, authoritative purples (`primary: #4800b2`) to vibrant, energetic violets (`secondary_container: #bc87fe`). This creates a spectrum that feels both institutional and technologically advanced.

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders to define sections or modules. Boundaries must be established through:
*   **Background Shifts:** Using `surface-container-low` (#f1f3ff) for a sidebar against a `surface` (#faf8ff) main content area.
*   **Tonal Transitions:** Defining the edge of a workspace by a shift from `surface` to `surface-container` (#eaedfc).

### Surface Hierarchy & Nesting
Treat the UI as physical layers of fine paper and frosted glass. Depth is built by nesting containers:
1.  **Base:** `surface` (#faf8ff)
2.  **Sectioning:** `surface-container-low` (#f1f3ff)
3.  **Actionable Cards:** `surface-container-lowest` (#ffffff) to provide a "pop" of clarity.
4.  **Information Callouts:** `surface-container-high` (#e5e7f6) to draw immediate attention.

### The "Glass & Gradient" Rule
To inject "soul" into the professional interface:
*   **Glassmorphism:** For floating headers or navigation overlays, use `surface` at 80% opacity with a `backdrop-blur: 20px`.
*   **Signature Gradients:** Hero sections and primary call-to-actions should utilize a subtle linear gradient from `primary` (#4800b2) to `primary_container` (#6200ee) at a 135-degree angle.

---

## 3. Typography

The typographic system utilizes a dual-sans-serif approach to balance authority with modern innovation.

*   **Display & Headline (Plus Jakarta Sans):** These are your "Editorial Voice." Large scales (`display-lg: 3.5rem`) and generous tracking create an open, high-end feel. Use these for course titles and major milestones.
*   **Title, Body, & Label (Inter):** This is your "Functional Voice." Inter provides world-class legibility for dense educational content. 
*   **Hierarchy as Identity:** By pairing the geometric flair of Plus Jakarta Sans with the utilitarian precision of Inter, the system conveys that it is both a place of inspiration (Headlines) and a place of work (Body).

---

## 4. Elevation & Depth

We eschew traditional drop shadows in favor of **Ambient Tonal Layering**.

*   **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` background. The subtle shift in hex code creates a "soft lift" that is easier on the eyes than a shadow.
*   **Ambient Shadows:** Where a floating effect is required (e.g., a Modal or a Profile Dropdown), use a large, diffused shadow:
    *   `box-shadow: 0 20px 40px rgba(23, 27, 38, 0.06);` (Using a 6% opacity tint of `on_surface`).
*   **The "Ghost Border" Fallback:** If a divider is functionally required for accessibility, use `outline_variant` (#cbc3d9) at **15% opacity**. Never use a 100% opaque border.
*   **Interaction Depth:** On hover, a card should not just gain a shadow; it should transition from `surface-container-lowest` to a subtle gradient or a slightly higher surface tier.

---

## 5. Components

### Buttons
*   **Primary:** Solid `primary` (#4800b2) with `on_primary` (#ffffff) text. Use `xl` (1.5rem) roundedness. Apply a subtle inner-glow gradient to the top edge for a premium feel.
*   **Secondary:** `surface_container_highest` (#dfe2f1) background with `primary` text. No border.
*   **Tertiary:** No background. Bold `primary` text with an underline that appears only on hover.

### Cards & Learning Modules
*   **Constraint:** Forbid all divider lines within cards.
*   **Layout:** Use the Spacing Scale (8px increments) to separate headlines from body text. Use `surface-container-low` backgrounds for "Tags" or "Metadata" areas within the card to create internal structure.

### Input Fields
*   **State:** Default state uses `surface-container-highest` as a subtle fill rather than an outline.
*   **Active:** Transitions to a "Ghost Border" of `primary` at 40% opacity with a 2px soft outer glow.
*   **Typography:** Labels must use `label-md` in `on_surface_variant` (#494456) for a sophisticated, understated look.

### Specialized EdTech Components
*   **Progress Orbs:** Instead of flat bars, use a semi-transparent `secondary_container` track with a `primary` glowing progress indicator.
*   **Course Navigation:** A vertical, "No-Line" sidebar using `surface-container-low` with active states indicated by a `primary` "ink bar" (4px wide, rounded) on the leading edge.

---

## 6. Do's and Don'ts

### Do
*   **Do** use asymmetrical layouts (e.g., a wide left column for content and a narrow, floating glass-morphic right column for tools).
*   **Do** prioritize vertical whitespace. If you think there is enough space, add 16px more.
*   **Do** use the `secondary` (#7743b5) color for "Moment of Delight" interactions, like completing a lesson.

### Don't
*   **Don't** use black (#000000) for text. Always use `on_surface` (#171b26) to maintain tonal harmony with the violet palette.
*   **Don't** use standard "Material Design" shadows. Keep elevations flat or ultra-diffused.
*   **Don't** use "Alert Red" for everything. Use `error` (#ba1a1a) sparingly, preferring `on_surface_variant` for neutral states to keep the UI calm.