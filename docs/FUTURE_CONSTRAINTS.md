# Future Constraints

The Milestone 1 and Milestone 2 implementation must preserve these constraints.

## Simplicity

ContinuityGraph uses small primitives and rich relationships.

Do not add specialized top-level models for government, campaign finance, characters, factions, vendors, laws, rooms, routes, or artifacts.  Use `ContinuityObject`, `ContinuityEvent`, `ContinuityLink`, and `ContinuityClaim`.

## Domain neutrality

ContinuityKit must remain reusable by Continuity Studio, CivicTrace, SourceTrace, and future apps.

Do not hard-code fiction, civic, or provenance concepts into the engine.

## LLM separation

ContinuityKit must not depend on yLLMKit or any LLM provider.

LLM-generated output should enter the engine later as proposals.

## Proposal trust boundary

Generated, imported, bulk, and uncertain changes should use proposals.

Proposal acceptance must be transactional.

## Source separation

ContinuityKit may store source metadata in Milestone 1 and 2.  Actual source file copy and checksum handling waits for Milestone 4.

Do not parse PDFs, ebooks, audio, video, images, or web pages in ContinuityKit.

## Relationship direction

Canonical relationship direction matters.

Preferred future directions:

- Claim -> about -> Event/Object/Claim
- Source -> supports -> Claim
- Source -> records -> Event
- Object -> believes -> Claim
- Item object -> possessed_by -> Person or entity object
- Location object -> governed_by -> Entity or person object
- Event -> occurred_at -> Location object

UI can show inverse labels later.

## Registry discipline

Registries should be lightweight and advisory.  They should guide labels, validation hints, and conflict warnings.  They should not block unusual modeling unless a true database integrity problem exists.

## Time model

Do not replace `ContinuityTimeValue` with plain `Date`.

The engine must support approximate, relative, text-only, unknown, and range-based time.

## Storage

Use GRDB and explicit migrations.

Do not use SwiftData as the source of truth.

Do not expose raw SQLite details as the main public API.

## Export/import future

Keep IDs as UUID strings and records as Codable so export/import can later use JSON packages.

Do not make assumptions that prevent record ID remapping during import.

## Audit future

Do not make changes in ways that make it impossible to add audit entries later.

Centralize write paths in `ContinuityStore` as much as practical.
