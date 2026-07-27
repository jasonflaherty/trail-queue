# Trail Queue Design System Specification

This document defines the layout rules, design tokens, accessibility standards, and usability heuristics for building the **Trail Queue** mobile application. AI code generators (Cursor, v0, Claude) MUST follow the rules in this document when generating UI code.

---

## 1. Design Principles & Usability (Jakob Nielsen's Heuristics)

Every screen and component generated must strictly align with Nielsen’s core usability heuristics, adapted for outdoor trail environments:

1. **Visibility of System Status (#1):** 
   - Always display explicit state feedback (e.g., streaming sync indicators, offline status badges, or loading skeletons).
   - Use clear visual confirmation when an issue report is submitted or saved locally.
2. **Match Between System and the Real World (#2):**
   - Use natural language and real-world terminology familiar to trail volunteers (e.g., *Blowdown*, *Washout*, *Drainage*, *Crosscut*).
   - Map controls must align with real-world spatial orientations and standard GPS gestures.
3. **User Control and Freedom (#3):**
   - Include clear "Cancel", "Close", or "Back" actions on all modals, bottom sheets, and multi-step forms.
   - Provide "Undo" or easy edit mechanisms when removing photos or deleting queued issue reports.
4. **Consistency and Standards (#4):**
   - Standardize icon metaphors across light and dark modes (e.g., green checkmarks for completion, red badges for high priority).
   - Keep global navigation actions (Home, Map, My Queue, Profile) fixed in a bottom tab bar.
5. **Error Prevention (#5):**
   - Use structured inputs like `ToggleTileGrid` for issue types instead of freeform text to prevent ambiguous submissions.
   - Confirm before discarding unsubmitted trail reports containing uploaded photos or GPS data.
6. **Recognition Rather Than Recall (#6):**
   - Show visual thumbnails alongside text titles in issue lists.
   - Display key metadata (time estimates, required volunteers, distance) directly on cards so users don't need to open every detail view.
7. **Flexibility and Efficiency of Use (#7):**
   - Provide one-tap quick actions (e.g., "Report an Issue" direct CTA on the home screen, "Use My Location" in form pickers).
   - Support both map-based spatial browsing and list-based filtering.
8. **Aesthetic and Minimalist Design (#8):**
   - Maintain high contrast and whitespace to prevent screen clutter.
   - Display secondary information in collapsible sheets or metadata badges rather than crowding the main card layout.
9. **Help Users Recognize, Diagnose, and Recover from Errors (#9):**
   - Provide actionable error messages (e.g., "GPS signal weak—tap to manually drop a pin" instead of generic error codes).
10. **Help and Documentation (#10):**
    - Include short contextual prompts in input fields (e.g., "Describe the issue..." or brief volunteer requirements).

---

## 2. Accessibility Standards (WCAG 2.1 AA Compliance)

Because this app is used outdoors under varying light conditions, accessibility guidelines must be strictly enforced in code generation.

### Visual & Color Contrast
* **Contrast Ratios:**
  * **Normal Text (< 18pt):** Minimum contrast ratio of **4.5:1** against the background.
  * **Large Text (≥ 18pt or 14pt bold) & UI Controls:** Minimum contrast ratio of **3.0:1**.
* **Color Independence:** Color MUST NOT be the sole indicator of status or priority. Always pair color with an icon and explicit text label (e.g., a Red Badge + Exclamation/High Icon + "High Priority" text).

### Touch Targets & Spatial Layout
* **Minimum Touch Target:** All interactive controls, grid tiles, map markers, and close buttons must be at least **48 × 48 dp/px**.
* **Spacing:** Maintain a minimum **8px gap** between adjacent touch targets to prevent accidental taps while walking or wearing gloves.

### Screen Readers & Semantics (VoiceOver / TalkBack)
* **Accessibility Labels:** All icon-only buttons (`Back`, `Filter`, `Share`, `Close`, `Notifications`) MUST include explicit `aria-label` or `accessibilityLabel` props.
* **Component Roles:** Ensure interactive elements use correct semantic roles (`button`, `checkbox`, `tab`, `heading`).
* **Grouped Metadata:** Group related card elements (Title, Distance, Priority) into single accessible focus blocks so screen readers read cards coherently rather than as fragmented items.

---

## 3. Design Tokens

### Color Palette

Use semantic color tokens exclusively. **Do not hardcode hex values inside UI components.**

| Token | Light Mode Value | Dark Mode Value | Contrast Standard | Usage |
| :--- | :--- | :--- | :--- | :--- |
| `--color-primary` | `#2D593E` | `#58976C` | Pass (AA) | Main identity, active states, primary CTA background |
| `--color-primary-on` | `#FFFFFF` | `#FFFFFF` | Pass (AAA) | Text/icons on primary elements |
| `--color-surface` | `#FFFFFF` | `#1A1D1E` | Pass (AAA) | Card backgrounds, inputs, sheet surfaces |
| `--color-surface-variant` | `#F0F2F1` | `#222628` | Pass (AA) | Header cards, secondary button backgrounds |
| `--color-text-base` | `#000000` | `#E0E3E1` | Pass (AAA) | Primary headers, title text |
| `--color-text-subtle` | `#595F5D` | `#8C9290` | Pass (AA) | Secondary labels, timestamps, distances |
| `--color-priority-high` | `#D93644` | `#EE6773` | Pass (AA) | High priority badges & icons |
| `--color-priority-high-bg` | `#F9E0E3` | `#4B1C22` | Pass (AA) | High priority container background |
| `--color-priority-med` | `#E69200` | `#FFC14D` | Pass (AA) | Medium priority status |
| `--color-priority-low` | `#218A32` | `#57CB72` | Pass (AA) | Low priority status |

### Typography & Spacing

* **Primary Font Family:** System Sans-Serif / Inter
* **Dynamic Type:** Text sizes must scale dynamically based on device system font scale settings. Do not clip text in fixed-height containers.
* **Base Radius:**
  * Cards & Sheets: `16px`
  * Buttons & Inputs: `8px`
  * Badges & Chips: `100px` (Full pill shape)
* **Spacing Scale:** `4px` base grid (`4px`, `8px`, `12px`, `16px`, `24px`, `32px`)

---

## 4. UI Component Specs & Rules

### Badges (`PriorityBadge`, `MetadataBadge`)
* **Priority Badge:** Uses `--color-priority-[level]` text/icon paired with `--color-priority-[level]-bg` background. Always includes both text and icon.
* **Metadata Badge:** Pill-shaped badge with `--color-surface-variant` background and `--color-text-subtle` text. Displays icon + text (e.g., `⏱ 2-4 hrs` or `👥 2-4 volunteers`).

### Cards (`IssueCard`)
* **Shape:** `16px` corner radius.
* **Layout:** Horizontal layout with an 80x80px thumbnail on the left, followed by the issue title, trail name, distance, and badge chips at the bottom.
* **Touch Target:** The entire card area is interactive and must be focusable by screen readers as a unified list item.

### Inputs (`ToggleTileGrid`)
* **Grid:** 4-column layout for issue categories (Blowdown, Erosion, Washout, Bridge, etc.).
* **Target Size:** Minimum 48x48px per tile.
* **Active State:** Solid border with `--color-primary` and subtle tinted background. Focus indicators must be explicitly visible for keyboard/accessibility navigation.

---

## 5. Prompting Instructions for AI Code Generators

* **Framework:** Mobile framework components (Flutter / React Native / Tailwind CSS).
* Always apply `SafeArea` / system status bar margins when constructing full-screen views.
* Always build UI components dark-mode capable using the theme tokens defined in Section 3.
* **Accessibility Checklist for AI Code:**
  - Add explicit semantic roles (`button`, `heading`, `image`) to generated layout nodes.
  - Ensure all decorative images have null alt labels or hidden screen reader traits, while content images (issue photos) have descriptive alt text.
  - Never generate color-only indicators; always pair colors with text/icons.
---

## 6. Implementation Map (Flutter monorepo)

The reference file structure in the spec is React/TSX. Trail Queue is Flutter; the
design system lives in `packages/ui`:

| Spec artifact | Flutter implementation |
| :--- | :--- |
| `tokens.json` | `packages/ui/tokens.json` (source of truth) → `packages/ui/lib/src/colors.dart` (`TqTokens` ThemeExtension) |
| `theme/colors.ts`, `theme/typography.ts` | `packages/ui/lib/src/theme.dart` (`TrailQueueTheme.light` / `.dark`) |
| `badges/PriorityBadge.tsx` | `packages/ui/lib/src/widgets/priority_badge.dart` (`PriorityBadge`, `StatusChip`) |
| `badges/MetadataBadge.tsx` | `packages/ui/lib/src/widgets/effort_chip.dart` (`EffortChip`) |
| `buttons/PrimaryButton.tsx`, `SecondaryButton.tsx` | `packages/ui/lib/src/widgets/primary_button.dart`, `outline_button.dart` |
| `cards/IssueCard.tsx` | `packages/ui/lib/src/widgets/issue_card.dart` |
| `inputs/ToggleTileGrid.tsx` | `packages/ui/lib/src/widgets/issue_type_grid.dart` (`IssueTypeGrid`) |
| `inputs/LocationPicker.tsx` | "Use My Location" flow in `apps/client/lib/screens/report_issue_screen.dart` |
