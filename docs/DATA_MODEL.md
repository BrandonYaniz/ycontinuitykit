# Data Model

Use full `Continuity*` type names.

## ContinuityProject

```swift
public struct ContinuityProject: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var description: String?
    public var appContext: String?
    public var schemaVersion: Int
    public var createdAt: Date
    public var updatedAt: Date
}
```

`appContext` is a string, not an enum.  Future apps may define their own contexts.

## ContinuityRecordKind

```swift
public enum ContinuityRecordKind: String, Codable, Hashable {
    case object
    case event
    case claim
    case source
    case note
}
```

## ContinuityRef

```swift
public struct ContinuityRef: Codable, Hashable {
    public var kind: ContinuityRecordKind
    public var id: UUID
}
```

## ContinuityRecord protocol

```swift
public protocol ContinuityRecord: Identifiable, Codable, Hashable where ID == UUID {
    var id: UUID { get }
    var projectID: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var archivedAt: Date? { get }
}
```

## ContinuityObject

```swift
public struct ContinuityObject: ContinuityRecord {
    public var id: UUID
    public var projectID: UUID
    public var name: String
    public var objectType: String
    public var summary: String?
    public var aliases: [String]
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?
}
```

An object is any tracked thing, such as a person, entity, location, item, law, route, room, artifact, document, vendor, committee, or concept.

## ContinuityTimeValue

```swift
public enum ContinuityTimeKind: String, Codable, Hashable {
    case unknown
    case instant
    case date
    case range
    case approximate
    case relative
    case text
}

public enum ContinuityTimePrecision: String, Codable, Hashable {
    case exact
    case day
    case month
    case year
    case decade
    case century
    case approximate
    case unknown
}

public struct ContinuityTimeValue: Codable, Hashable {
    public var kind: ContinuityTimeKind
    public var start: Date?
    public var end: Date?
    public var precision: ContinuityTimePrecision
    public var label: String?
    public var sortKey: Double?
}
```

Do not use plain `Date` as the only timeline model.  The engine must support uncertain, approximate, relative, and text-based time.

## ContinuityEvent

```swift
public struct ContinuityEvent: ContinuityRecord {
    public var id: UUID
    public var projectID: UUID
    public var title: String
    public var summary: String?
    public var time: ContinuityTimeValue
    public var timeConfidence: Double
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?
}
```

Participants and locations should be modeled as links, not fields on the event.

## ContinuityLink

```swift
public struct ContinuityLink: ContinuityRecord {
    public var id: UUID
    public var projectID: UUID
    public var from: ContinuityRef
    public var relationshipType: String
    public var to: ContinuityRef
    public var time: ContinuityTimeValue?
    public var timeConfidence: Double?
    public var confidence: Double
    public var summary: String?
    public var sourceIDs: [UUID]
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?
}
```

Links are time-aware relationships.

## ContinuityClaimStatus

```swift
public enum ContinuityClaimStatus: String, Codable, Hashable {
    case unknown
    case accepted
    case supported
    case disputed
    case contradicted
    case rejected
    case superseded
}
```

## ContinuityClaim

```swift
public struct ContinuityClaim: ContinuityRecord {
    public var id: UUID
    public var projectID: UUID
    public var statement: String
    public var claimType: String
    public var status: ContinuityClaimStatus
    public var confidence: Double
    public var sourceIDs: [UUID]
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?
}
```

A claim is a statement, assertion, interpretation, allegation, rumor, belief, canon fact, or disputed idea.

## ContinuitySourceType

```swift
public enum ContinuitySourceType: String, Codable, Hashable {
    case note
    case pdf
    case ebook
    case image
    case video
    case audio
    case webpage
    case transcript
    case spreadsheet
    case document
    case manualReference
    case other
}
```

## ContinuitySource

```swift
public struct ContinuitySource: ContinuityRecord {
    public var id: UUID
    public var projectID: UUID
    public var title: String
    public var sourceType: ContinuitySourceType
    public var originalFilename: String?
    public var storedPath: String?
    public var checksum: String?
    public var origin: String?
    public var citation: String?
    public var extractedTextPath: String?
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?
}
```

Milestone 1 stores source records only.  Milestone 4 will copy files and compute checksums.

## ContinuityNote

```swift
public struct ContinuityNote: ContinuityRecord {
    public var id: UUID
    public var projectID: UUID
    public var title: String?
    public var body: String
    public var linkedRefs: [ContinuityRef]
    public var sourceIDs: [UUID]
    public var metadata: [String: String]
    public var createdAt: Date
    public var updatedAt: Date
    public var archivedAt: Date?
}
```

## ContinuityProposalStatus

```swift
public enum ContinuityProposalStatus: String, Codable, Hashable {
    case pending
    case accepted
    case rejected
    case failed
}
```

## ContinuityProposal

```swift
public struct ContinuityProposal: Identifiable, Codable, Hashable {
    public var id: UUID
    public var projectID: UUID
    public var summary: String
    public var detail: String?
    public var status: ContinuityProposalStatus
    public var sourceIDs: [UUID]
    public var confidence: Double
    public var createdBy: String
    public var createdAt: Date
    public var updatedAt: Date
    public var reviewedAt: Date?
}
```

## ContinuityProposalOperationKind

```swift
public enum ContinuityProposalOperationKind: String, Codable, Hashable {
    case createObject
    case updateObject
    case archiveObject
    case createEvent
    case updateEvent
    case archiveEvent
    case createClaim
    case updateClaim
    case archiveClaim
    case createSource
    case updateSource
    case archiveSource
    case createNote
    case updateNote
    case archiveNote
    case createLink
    case updateLink
    case archiveLink
}
```

## ContinuityProposalOperation

```swift
public struct ContinuityProposalOperation: Identifiable, Codable, Hashable {
    public var id: UUID
    public var projectID: UUID
    public var proposalID: UUID
    public var sortOrder: Int
    public var kind: ContinuityProposalOperationKind
    public var targetRef: ContinuityRef?
    public var summary: String?
    public var payloadJSON: String
    public var createdAt: Date
}
```

## ContinuityProposalOperationDraft

```swift
public struct ContinuityProposalOperationDraft: Codable, Hashable {
    public var kind: ContinuityProposalOperationKind
    public var targetRef: ContinuityRef?
    public var summary: String?
    public var payloadJSON: String
}
```

Use drafts when submitting proposals so callers do not need to provide operation IDs, project IDs, proposal IDs, timestamps, or sort order.
