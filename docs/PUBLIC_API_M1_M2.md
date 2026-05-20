# Public API for Milestones 1 and 2

The main public entry point is `ContinuityStore`.

## ContinuityStore creation

```swift
public final class ContinuityStore {
    public static func createProject(
        at projectURL: URL,
        name: String,
        description: String?,
        appContext: String?
    ) throws -> ContinuityStore

    public static func open(projectURL: URL) throws -> ContinuityStore
}
```

`createProject` should create the `.continuity` package folder, create `manifest.json`, initialize `continuity.sqlite`, run migrations, and insert the project row.

`open` should open an existing project package and run any pending migrations.

## Basic record APIs

Use simple CRUD-style methods for Milestone 1.

```swift
public func createObject(_ object: ContinuityObject) throws
public func updateObject(_ object: ContinuityObject) throws
public func archiveObject(id: UUID) throws
public func object(id: UUID, includeArchived: Bool = false) throws -> ContinuityObject?
public func objects(type: String? = nil, includeArchived: Bool = false) throws -> [ContinuityObject]
```

```swift
public func createEvent(_ event: ContinuityEvent) throws
public func updateEvent(_ event: ContinuityEvent) throws
public func archiveEvent(id: UUID) throws
public func event(id: UUID, includeArchived: Bool = false) throws -> ContinuityEvent?
public func events(matching query: ContinuityTimelineQuery) throws -> [ContinuityEvent]
```

```swift
public func createClaim(_ claim: ContinuityClaim) throws
public func updateClaim(_ claim: ContinuityClaim) throws
public func archiveClaim(id: UUID) throws
public func claim(id: UUID, includeArchived: Bool = false) throws -> ContinuityClaim?
public func claims(status: ContinuityClaimStatus? = nil, includeArchived: Bool = false) throws -> [ContinuityClaim]
```

```swift
public func createSource(_ source: ContinuitySource) throws
public func updateSource(_ source: ContinuitySource) throws
public func archiveSource(id: UUID) throws
public func source(id: UUID, includeArchived: Bool = false) throws -> ContinuitySource?
```

```swift
public func createNote(_ note: ContinuityNote) throws
public func updateNote(_ note: ContinuityNote) throws
public func archiveNote(id: UUID) throws
public func note(id: UUID, includeArchived: Bool = false) throws -> ContinuityNote?
```

```swift
public func createLink(_ link: ContinuityLink) throws
public func updateLink(_ link: ContinuityLink) throws
public func archiveLink(id: UUID) throws
public func link(id: UUID, includeArchived: Bool = false) throws -> ContinuityLink?
public func links(from ref: ContinuityRef, relationshipType: String? = nil, includeArchived: Bool = false) throws -> [ContinuityLink]
public func links(to ref: ContinuityRef, relationshipType: String? = nil, includeArchived: Bool = false) throws -> [ContinuityLink]
```

## Timeline query

```swift
public struct ContinuityTimelineQuery: Codable, Hashable {
    public var startSortKey: Double?
    public var endSortKey: Double?
    public var includeArchived: Bool
    public var limit: Int?
    public var offset: Int?
}
```

## Proposal APIs

```swift
public func submitProposal(
    summary: String,
    detail: String?,
    operations: [ContinuityProposalOperationDraft],
    sourceIDs: [UUID],
    confidence: Double,
    createdBy: String
) throws -> ContinuityProposal
```

```swift
public func proposals(status: ContinuityProposalStatus? = nil) throws -> [ContinuityProposal]
public func proposal(id: UUID) throws -> ContinuityProposal?
public func proposalOperations(proposalID: UUID) throws -> [ContinuityProposalOperation]
public func rejectProposal(id: UUID) throws
public func acceptProposal(id: UUID) throws
```

## Proposal operation helpers

Add helpers if practical:

```swift
public extension ContinuityProposalOperationDraft {
    static func createObject(_ object: ContinuityObject, summary: String? = nil) throws -> Self
    static func createEvent(_ event: ContinuityEvent, summary: String? = nil) throws -> Self
    static func createClaim(_ claim: ContinuityClaim, summary: String? = nil) throws -> Self
    static func createSource(_ source: ContinuitySource, summary: String? = nil) throws -> Self
    static func createNote(_ note: ContinuityNote, summary: String? = nil) throws -> Self
    static func createLink(_ link: ContinuityLink, summary: String? = nil) throws -> Self
}
```

## Error model

Add a focused error enum:

```swift
public enum ContinuityStoreError: Error, Equatable {
    case projectNotOpen
    case recordNotFound(ContinuityRef)
    case recordAlreadyExists(ContinuityRef)
    case invalidReference(ContinuityRef)
    case invalidProposal(String)
    case invalidProposalStatus(String)
    case invalidPayload(String)
    case unsupportedOperation(String)
    case confidenceOutOfRange(Double)
}
```
