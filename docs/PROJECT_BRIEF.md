# Project Brief

ContinuityGraph is a timeline-aware knowledge graph engine.  ContinuityKit is the Swift package that implements the engine.

ContinuityGraph is intended to power multiple apps:

- Continuity Studio, for worldbuilding and research
- CivicTrace, for civic and government data analysis
- SourceTrace, for provenance and evidence tracking

The engine must remain domain-neutral.  It should not know about fiction, city councils, campaign finance, public records, or provenance-specific workflows.  It should store durable graph primitives that those apps can use.

## Core idea

Everything important exists in context and changes over time.

The engine tracks:

- Objects, such as people, entities, locations, items, documents, laws, concepts, and routes
- Events, meaning things that happen on the timeline
- Links, meaning time-aware relationships between records
- Claims, meaning assertions, interpretations, allegations, beliefs, rumors, canon facts, or disputed statements
- Sources, meaning files, references, documents, transcripts, PDFs, media, or manual citations
- Notes, meaning unstructured user text
- Proposals, meaning reviewable batches of proposed changes

## Core philosophy

- Keep the engine simple.
- Use a small number of flexible primitives.
- Make relationships time-aware.
- Treat claims as first-class records so competing interpretations can coexist.
- Keep LLM provider logic outside the engine.
- Let LLMs, importers, and apps propose changes.  Let the engine validate and commit them.
- Preserve future compatibility with source archives, conflict checking, domain registries, import batches, export/import, and audit history.

## Implementation target for this package

Implement Milestone 1 and Milestone 2 only.

Milestone 1 proves the core graph can be stored and queried.

Milestone 2 adds reviewable proposals and transactional proposal acceptance.
