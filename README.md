# ContinuityKit

ContinuityKit is a Swift library for building timeline-aware knowledge graph storage. It provides the core persistence layer for ContinuityGraph: durable records, time-aware relationships, claims, sources, notes, and reviewable batches of proposed changes.

The package is intentionally domain-neutral. Apps bring their own vocabulary and workflows; ContinuityKit stores the graph primitives that those apps need to reason about people, places, documents, events, assertions, and relationships over time.

## Current Scope

The first implementation pass focuses on two pieces:

1. Core graph storage for projects, objects, events, links, claims, sources, and notes.
2. A proposal workflow for generated, imported, bulk, or uncertain changes.

Proposal acceptance is transactional: a proposal applies completely or not at all. Direct user edits can write records through store APIs, while generated or uncertain changes should go through proposals first.

Out of scope for this pass: UI, LLM provider integration, source archive copying, conflict checking, import batches, export/import packages, audit history, semantic search, PDF parsing, OCR, audio/video parsing, and app-specific domain registries.

## Project Packages

ContinuityKit projects are stored as folder packages with a `.continuity` extension:

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

The initial storage layer creates the package structure and SQLite database. Later milestones can add source archive management, checksums, imports, exports, and audit history without changing the basic package shape.

## Development Notes

The implementation targets:

- Swift 6.0
- macOS 14.0 or newer
- Swift Package Manager
- GRDB for SQLite persistence
- XCTest for test coverage

Design notes, schema details, public API expectations, and the test plan live in `docs/`.
