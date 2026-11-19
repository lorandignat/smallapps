# DESIGN — {{TITLE}}

Owner: `ba` (written with the developer). Living document: the shape of the app,
not a specification of behaviour — behaviour lives in `product/SPEC.md`.

Update when a decision would be expensive to reverse. Keep it to one page; if it
grows, split off a diagram file.

## Shape

The few components that matter and how they talk to each other.

```
(component) ──> (component) ──> (storage)
```

## Data model

Entities, their fields, and what owns them. Note anything persisted and where.

## Boundaries

- What is local vs remote.
- Where the app talks to the outside world, and what happens when it cannot.
- What is deliberately not abstracted yet.

## UX principles

Three rules that settle arguments. e.g. "one primary action per screen",
"nothing destructive without an undo".

## Known trade-offs

Decision, alternative rejected, and what would make us revisit it. Link
`DEC-###` entries.
