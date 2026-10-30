---
name: boui-adminlte-migration-conventions
version: 1.0.0
description: Conventions for migrating legacy AdminLTE admin screens into BOUI/Uxmal. Use when a developer needs practical guidance to reinterpret AdminLTE pages using Uxmal Design System 2026, BOUI components, Laravel page structure, and clear backoffice UX patterns without requiring pixel-perfect validation or specialized tooling.
---

# BOUI AdminLTE Migration Conventions

Use this skill when migrating an old AdminLTE admin screen into a BOUI/Uxmal admin module.

The goal is not to copy the old page. The goal is to preserve what the user can do, while rebuilding the interface with BOUI components and Uxmal admin conventions.

## Main Principle

Migrate the workflow, not the markup.

AdminLTE is the legacy reference for business behavior: what data is shown, what actions exist, which filters matter, what forms are required, and which states the user needs.

Uxmal/BOUI is the new reference for layout, hierarchy, components, spacing, actions, and interaction patterns.

## How to Read the Legacy Screen

Before coding, understand the AdminLTE screen in plain terms:

- What is the main user task?
- Is this a listing, detail, create/edit form, configuration screen, history screen, or modal flow?
- What actions can the user perform?
- Which fields, filters, statuses, and table columns are actually important?
- Which actions are destructive or require confirmation?
- Which empty, loading, error, disabled, or success states matter?
- Which parts are just old AdminLTE decoration and can be dropped?

Do not preserve a legacy layout just because it exists. Preserve it only when it helps the user complete the task.

## Uxmal Layout Conventions

Use the BOUI/Uxmal admin structure as the target:

- standard admin shell with sidebar and topbar when the page is a full module
- white page surface by default
- title block separated from the main content block
- main content inside a clear bordered container
- Light border treatment and 16px radius for the main BOUI containers
- dense, scannable layouts for backoffice use
- no marketing-style hero sections, big decorative cards, or dashboard-like compositions unless the task is truly a dashboard

The title block should contain:

- page title
- short subtitle when helpful
- optional status badge
- optional history button

The title block should not contain operational CTAs like create, save, export, delete, edit, or cancel. Put those actions in the content/action area.

## Component Conventions

Prefer BOUI components and factories:

- `UI::card()` for grouped content
- `UI::gridJS()` for tables and listings
- `UI::modal()` for modal flows
- `Form::` components for inputs
- `Html::button()` for buttons
- `Html::a()` for links
- `Html::div()`, `Html::tag()`, and related helpers for layout and text

Important BOUI details:

- Buttons use `Html::button()`. There is no `UI::button()`.
- Cards use `->header()`, `->body()`, and `->footer()`.
- Use `UI::gridJS()` with camelCase.
- Use `UI::` and `Html::` factories instead of raw HTML strings.
- Treat `src/Components/UI.php` as the practical component catalog when in doubt.

## Table Conventions

For migrated listings:

- use a searchable, paginated BOUI table pattern
- keep search and filters together near the upper-left of the listing block
- put row actions at the far right
- use icon-only row actions
- avoid putting long text buttons inside rows
- show status with badges or clear visual labels
- include empty states when the table can have no results

Do not recreate AdminLTE DataTables initialization code as the final approach. Reinterpret it as a BOUI/GridJS table.

## Button and Action Conventions

Keep the action hierarchy simple:

- one primary CTA per block
- secondary actions should be neutral
- destructive actions should look dangerous and require confirmation
- avoid multiple competing primary buttons
- avoid action clutter in headers

Examples:

- `Crear`, `Guardar`, or `Aplicar` can be primary.
- `Cancelar`, `Limpiar`, `Exportar`, or `Volver` are usually secondary.
- `Eliminar`, `Desactivar`, or irreversible changes are danger actions.

## Forms and Modals

For migrated forms:

- group related fields into clear sections
- keep labels direct and predictable
- keep helper text short
- show validation states where the user needs them
- place form actions consistently at the bottom or in the expected action area

For modals:

- use modals for focused decisions or small subflows
- align modal actions to the right
- center content only when the modal is purely informational
- destructive modals must clearly explain the consequence

<!-- ## JavaScript Conventions

Use BOUI events instead of old jQuery-driven behavior:

- use `boui.on()` to listen for events
- use `boui.dispatch()` to communicate between components
- use `boui.get()` to access BOUI components
- use `boui.cbq()` for command/query calls when needed
- use `boui.toast()` for user feedback
- use `boui.alert()` for confirmations

Avoid using `document.querySelector` or jQuery selectors to operate on BOUI-rendered components. The `boui` object is the preferred interface.

Do not use Livewire for migrated interactions unless the project explicitly requires it. -->

## Icon Conventions

- Use Material Design Icons for buttons, table actions, and functional controls.
- Reserve Bootstrap Icons for sidebar and navigation usage.
- In tables, actions should usually be icons with clear hover titles or accessible labels.

## What to Leave Behind from AdminLTE

Do not carry these over as final code:

- AdminLTE skin classes
- `.box`, `.panel`, `.widget`, and similar layout wrappers
- copied inline styles
- jQuery click handlers tied to legacy selectors
- DataTables setup scripts
- visual clutter that exists only because of the old template
- dashboard cards when the actual task is a CRUD listing

If something from AdminLTE is only decorative, drop it. If it supports the workflow, rebuild it using BOUI/Uxmal conventions.

## Reasonable Migration Output

When a migration is done, the result should be easy to explain:

- what legacy screen was migrated
- what BOUI screen pattern was chosen
- which legacy actions were preserved
- which AdminLTE pieces were intentionally replaced by BOUI/Uxmal patterns
- any uncertainty or missing component that should be reviewed

The final page should feel like a BOUI/Uxmal admin screen, not like AdminLTE with different colors.

