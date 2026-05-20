# Architecture

ContinuityKit is a Swift package that implements the ContinuityGraph engine.

## Responsibility split

### ContinuityKit owns

- Project package creation
- SQLite storage through GRDB
- Core records
- Time representation
- Links and claims
- Proposal storage and acceptance
- Basic query methods
- Stable migrations

### Apps own

- UI
- Domain-specific terminology
- App-specific workflows
- LLM chat interface
- Prompting
- Source parsing
- Importers
- Document review screens

### LLM layer owns

- Natural language conversation
- Extraction from text
- Summarization
- Structured proposal generation
- Model selection
- yLLMKit integration

ContinuityKit must not depend on yLLMKit.

## Project package

A project is stored as a folder package:

```text
ProjectName.continuity/
  manifest.json
  continuity.sqlite
  sources/
    originals/
    extracted/
  attachments/
  exports/
```

Milestone 1 creates the package structure and database.  Milestone 4 will implement real source file importing.

## Storage

Use GRDB and SQLite.

- Store UUID values as uppercase UUID strings.
- Store dates as ISO 8601 strings.
- Store complex fields as JSON text in v1.
- Duplicate `time.sortKey` into indexed columns where needed for timeline queries.
- Use explicit database migrations.

## Relationship model

`ContinuityLink` connects any two supported record references.

Examples:

```text
Object -> participated_in -> Event
Claim -> about -> Event
Object -> believes -> Claim
Source -> supports -> Claim
Source -> records -> Event
Event -> caused -> Event
```

Canonical relationship direction matters.  Future registries will define canonical direction and inverse display labels.

## Proposal model

A proposal is a reviewable batch of operations.

Acceptance is atomic.  If any operation fails, none of the operations should remain committed.

Proposal operations store payloads as JSON for Milestone 2.  This is intentional.  It keeps the proposal system flexible while the model is still evolving.
