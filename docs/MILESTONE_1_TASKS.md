# Milestone 1 Tasks: Core Graph Storage

## Goal

ContinuityKit can create a project package, initialize a GRDB-backed SQLite database, create core records, link them together, and query them back.

## Required tasks

1. Create Swift package named `ContinuityKit`.
2. Add GRDB dependency.
3. Create package folder layout under `Sources/ContinuityKit`.
4. Implement core model structs.
5. Implement `ContinuityTimeValue` and supporting enums.
6. Implement `ContinuityRef` and `ContinuityRecordKind`.
7. Implement JSON encoding and decoding helpers.
8. Implement `ContinuityStore`.
9. Implement project package creation.
10. Implement `manifest.json` creation.
11. Implement GRDB database setup.
12. Implement migration v1.
13. Implement create, update, archive, and fetch for objects.
14. Implement create, update, archive, and fetch for events.
15. Implement create, update, archive, and fetch for claims.
16. Implement create, update, archive, and fetch for sources.
17. Implement create, update, archive, and fetch for notes.
18. Implement create, update, archive, and fetch for links.
19. Implement `links(from:)` and `links(to:)` queries.
20. Implement `events(matching:)` timeline query.
21. Add unit tests.

## Business Plot fixture

Use this fixture in tests:

- Object: Smedley Butler, type person
- Object: McCormack-Dickstein Committee, type entity
- Event: Butler testifies before committee, date November 20, 1934
- Claim: Butler was approached about leading veterans in a coup
- Link: Smedley Butler participated_in testimony event
- Link: Claim about testimony event
- Link: Committee investigated claim

## Acceptance criteria

- Project package is created with expected folders.
- SQLite database is created and migrated.
- Core records can be created and fetched.
- Archived records are excluded from default fetches.
- Events can be queried by sort key range.
- Links can connect objects, events, claims, sources, and notes.
- Link queries by from/to ref work.
- Unit tests pass.
