# Implementation Notes

## Suggested file structure

```text
ContinuityKit/
  Package.swift
  Sources/
    ContinuityKit/
      ContinuityKit.swift
      Models/
      Time/
      Store/
      Persistence/
      Proposals/
      Query/
  Tests/
    ContinuityKitTests/
```

Keep one Swift module for now.  Use folders for organization, not separate package targets.

## GRDB mapping

Use GRDB record types or persistence adapters as appropriate.  The public models should remain clean Codable Swift structs.

It is acceptable to add private database row structs if they simplify JSON field handling.

## JSON fields

Use `JSONEncoder` and `JSONDecoder` helpers for:

- aliases
- metadata
- source IDs
- linked refs
- time values
- proposal payloads

## Timestamps

Use UTC ISO 8601 strings in SQLite.

## UUIDs

Store UUIDs as uppercase strings.

## Archive behavior

Archive is soft delete.  Set `archivedAt`.  Do not delete rows.

Default fetch methods should exclude archived records unless `includeArchived` is true.

## Proposal acceptance

Proposal acceptance should run in a GRDB transaction.

Pseudo-flow:

```swift
try dbWriter.write { db in
    let proposal = try fetchProposal(db, id)
    guard proposal.status == .pending else { throw ... }
    let operations = try fetchOperations(db, proposalID: id)
    try validateOperations(operations, db: db)
    for operation in operations {
        try apply(operation, db: db)
    }
    try markProposalAccepted(id, db: db)
}
```

## Proposal validation in Milestone 2

Only validate structural issues needed for safe application.

Examples:

- Proposal has operations.
- Confidence is between 0.0 and 1.0.
- Operation payload decodes correctly.
- Update and archive targets exist.
- Create targets do not already exist.
- Links reference existing records or records created earlier in the same proposal.

Do not add conflict checker behavior yet.
