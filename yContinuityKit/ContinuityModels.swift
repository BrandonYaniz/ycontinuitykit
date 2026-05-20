import Foundation

public struct ContinuityProject: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var description: String?
    public var appContext: String?
    public var schemaVersion: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), name: String, description: String? = nil, appContext: String? = nil, schemaVersion: Int = 1, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.appContext = appContext
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum ContinuityRecordKind: String, Codable, Hashable, Sendable {
    case object
    case event
    case claim
    case source
    case note
}

public struct ContinuityRef: Codable, Hashable, Sendable {
    public var kind: ContinuityRecordKind
    public var id: UUID

    public init(kind: ContinuityRecordKind, id: UUID) {
        self.kind = kind
        self.id = id
    }
}

public protocol ContinuityRecord: Identifiable, Codable, Hashable, Sendable where ID == UUID {
    var id: UUID { get }
    var projectID: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var archivedAt: Date? { get }
}

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

    public init(id: UUID = UUID(), projectID: UUID, name: String, objectType: String, summary: String? = nil, aliases: [String] = [], metadata: [String: String] = [:], createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.projectID = projectID
        self.name = name
        self.objectType = objectType
        self.summary = summary
        self.aliases = aliases
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

public enum ContinuityTimeKind: String, Codable, Hashable, Sendable {
    case unknown
    case instant
    case date
    case range
    case approximate
    case relative
    case text
}

public enum ContinuityTimePrecision: String, Codable, Hashable, Sendable {
    case exact
    case day
    case month
    case year
    case decade
    case century
    case approximate
    case unknown
}

public struct ContinuityTimeValue: Codable, Hashable, Sendable {
    public var kind: ContinuityTimeKind
    public var start: Date?
    public var end: Date?
    public var precision: ContinuityTimePrecision
    public var label: String?
    public var sortKey: Double?

    public init(kind: ContinuityTimeKind, start: Date? = nil, end: Date? = nil, precision: ContinuityTimePrecision = .unknown, label: String? = nil, sortKey: Double? = nil) {
        self.kind = kind
        self.start = start
        self.end = end
        self.precision = precision
        self.label = label
        self.sortKey = sortKey
    }
}

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

    public init(id: UUID = UUID(), projectID: UUID, title: String, summary: String? = nil, time: ContinuityTimeValue, timeConfidence: Double = 1.0, metadata: [String: String] = [:], createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.projectID = projectID
        self.title = title
        self.summary = summary
        self.time = time
        self.timeConfidence = timeConfidence
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

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

    public init(id: UUID = UUID(), projectID: UUID, from: ContinuityRef, relationshipType: String, to: ContinuityRef, time: ContinuityTimeValue? = nil, timeConfidence: Double? = nil, confidence: Double = 1.0, summary: String? = nil, sourceIDs: [UUID] = [], metadata: [String: String] = [:], createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.projectID = projectID
        self.from = from
        self.relationshipType = relationshipType
        self.to = to
        self.time = time
        self.timeConfidence = timeConfidence
        self.confidence = confidence
        self.summary = summary
        self.sourceIDs = sourceIDs
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

public enum ContinuityClaimStatus: String, Codable, Hashable, Sendable {
    case unknown
    case accepted
    case supported
    case disputed
    case contradicted
    case rejected
    case superseded
}

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

    public init(id: UUID = UUID(), projectID: UUID, statement: String, claimType: String, status: ContinuityClaimStatus = .unknown, confidence: Double = 1.0, sourceIDs: [UUID] = [], metadata: [String: String] = [:], createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.projectID = projectID
        self.statement = statement
        self.claimType = claimType
        self.status = status
        self.confidence = confidence
        self.sourceIDs = sourceIDs
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

public enum ContinuitySourceType: String, Codable, Hashable, Sendable {
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

    public init(id: UUID = UUID(), projectID: UUID, title: String, sourceType: ContinuitySourceType, originalFilename: String? = nil, storedPath: String? = nil, checksum: String? = nil, origin: String? = nil, citation: String? = nil, extractedTextPath: String? = nil, metadata: [String: String] = [:], createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.projectID = projectID
        self.title = title
        self.sourceType = sourceType
        self.originalFilename = originalFilename
        self.storedPath = storedPath
        self.checksum = checksum
        self.origin = origin
        self.citation = citation
        self.extractedTextPath = extractedTextPath
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

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

    public init(id: UUID = UUID(), projectID: UUID, title: String? = nil, body: String, linkedRefs: [ContinuityRef] = [], sourceIDs: [UUID] = [], metadata: [String: String] = [:], createdAt: Date = Date(), updatedAt: Date = Date(), archivedAt: Date? = nil) {
        self.id = id
        self.projectID = projectID
        self.title = title
        self.body = body
        self.linkedRefs = linkedRefs
        self.sourceIDs = sourceIDs
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}

public enum ContinuityProposalStatus: String, Codable, Hashable, Sendable {
    case pending
    case accepted
    case rejected
    case failed
}

public struct ContinuityProposal: Identifiable, Codable, Hashable, Sendable {
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

    public init(id: UUID = UUID(), projectID: UUID, summary: String, detail: String? = nil, status: ContinuityProposalStatus = .pending, sourceIDs: [UUID] = [], confidence: Double, createdBy: String, createdAt: Date = Date(), updatedAt: Date = Date(), reviewedAt: Date? = nil) {
        self.id = id
        self.projectID = projectID
        self.summary = summary
        self.detail = detail
        self.status = status
        self.sourceIDs = sourceIDs
        self.confidence = confidence
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reviewedAt = reviewedAt
    }
}

public enum ContinuityProposalOperationKind: String, Codable, Hashable, Sendable {
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

public struct ContinuityProposalOperation: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var projectID: UUID
    public var proposalID: UUID
    public var sortOrder: Int
    public var kind: ContinuityProposalOperationKind
    public var targetRef: ContinuityRef?
    public var summary: String?
    public var payloadJSON: String
    public var createdAt: Date

    public init(id: UUID = UUID(), projectID: UUID, proposalID: UUID, sortOrder: Int, kind: ContinuityProposalOperationKind, targetRef: ContinuityRef? = nil, summary: String? = nil, payloadJSON: String, createdAt: Date = Date()) {
        self.id = id
        self.projectID = projectID
        self.proposalID = proposalID
        self.sortOrder = sortOrder
        self.kind = kind
        self.targetRef = targetRef
        self.summary = summary
        self.payloadJSON = payloadJSON
        self.createdAt = createdAt
    }
}

public struct ContinuityProposalOperationDraft: Codable, Hashable, Sendable {
    public var kind: ContinuityProposalOperationKind
    public var targetRef: ContinuityRef?
    public var summary: String?
    public var payloadJSON: String

    public init(kind: ContinuityProposalOperationKind, targetRef: ContinuityRef? = nil, summary: String? = nil, payloadJSON: String) {
        self.kind = kind
        self.targetRef = targetRef
        self.summary = summary
        self.payloadJSON = payloadJSON
    }
}

public struct ContinuityTimelineQuery: Codable, Hashable, Sendable {
    public var startSortKey: Double?
    public var endSortKey: Double?
    public var includeArchived: Bool
    public var limit: Int?
    public var offset: Int?

    public init(startSortKey: Double? = nil, endSortKey: Double? = nil, includeArchived: Bool = false, limit: Int? = nil, offset: Int? = nil) {
        self.startSortKey = startSortKey
        self.endSortKey = endSortKey
        self.includeArchived = includeArchived
        self.limit = limit
        self.offset = offset
    }
}

public enum ContinuityStoreError: Error, Equatable, Sendable {
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

public extension ContinuityProposalOperationDraft {
    static func createObject(_ object: ContinuityObject, summary: String? = nil) throws -> Self {
        try Self(kind: .createObject, targetRef: ContinuityRef(kind: .object, id: object.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(object))
    }

    static func updateObject(_ object: ContinuityObject, summary: String? = nil) throws -> Self {
        try Self(kind: .updateObject, targetRef: ContinuityRef(kind: .object, id: object.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(object))
    }

    static func archiveObject(id: UUID, summary: String? = nil) -> Self {
        Self(kind: .archiveObject, targetRef: ContinuityRef(kind: .object, id: id), summary: summary, payloadJSON: "{}")
    }

    static func createEvent(_ event: ContinuityEvent, summary: String? = nil) throws -> Self {
        try Self(kind: .createEvent, targetRef: ContinuityRef(kind: .event, id: event.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(event))
    }

    static func updateEvent(_ event: ContinuityEvent, summary: String? = nil) throws -> Self {
        try Self(kind: .updateEvent, targetRef: ContinuityRef(kind: .event, id: event.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(event))
    }

    static func archiveEvent(id: UUID, summary: String? = nil) -> Self {
        Self(kind: .archiveEvent, targetRef: ContinuityRef(kind: .event, id: id), summary: summary, payloadJSON: "{}")
    }

    static func createClaim(_ claim: ContinuityClaim, summary: String? = nil) throws -> Self {
        try Self(kind: .createClaim, targetRef: ContinuityRef(kind: .claim, id: claim.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(claim))
    }

    static func updateClaim(_ claim: ContinuityClaim, summary: String? = nil) throws -> Self {
        try Self(kind: .updateClaim, targetRef: ContinuityRef(kind: .claim, id: claim.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(claim))
    }

    static func archiveClaim(id: UUID, summary: String? = nil) -> Self {
        Self(kind: .archiveClaim, targetRef: ContinuityRef(kind: .claim, id: id), summary: summary, payloadJSON: "{}")
    }

    static func createSource(_ source: ContinuitySource, summary: String? = nil) throws -> Self {
        try Self(kind: .createSource, targetRef: ContinuityRef(kind: .source, id: source.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(source))
    }

    static func updateSource(_ source: ContinuitySource, summary: String? = nil) throws -> Self {
        try Self(kind: .updateSource, targetRef: ContinuityRef(kind: .source, id: source.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(source))
    }

    static func archiveSource(id: UUID, summary: String? = nil) -> Self {
        Self(kind: .archiveSource, targetRef: ContinuityRef(kind: .source, id: id), summary: summary, payloadJSON: "{}")
    }

    static func createNote(_ note: ContinuityNote, summary: String? = nil) throws -> Self {
        try Self(kind: .createNote, targetRef: ContinuityRef(kind: .note, id: note.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(note))
    }

    static func updateNote(_ note: ContinuityNote, summary: String? = nil) throws -> Self {
        try Self(kind: .updateNote, targetRef: ContinuityRef(kind: .note, id: note.id), summary: summary, payloadJSON: ContinuityJSON.encodeString(note))
    }

    static func archiveNote(id: UUID, summary: String? = nil) -> Self {
        Self(kind: .archiveNote, targetRef: ContinuityRef(kind: .note, id: id), summary: summary, payloadJSON: "{}")
    }

    static func createLink(_ link: ContinuityLink, summary: String? = nil) throws -> Self {
        try Self(kind: .createLink, targetRef: nil, summary: summary, payloadJSON: ContinuityJSON.encodeString(link))
    }

    static func updateLink(_ link: ContinuityLink, summary: String? = nil) throws -> Self {
        try Self(kind: .updateLink, targetRef: nil, summary: summary, payloadJSON: ContinuityJSON.encodeString(link))
    }

    static func archiveLink(id: UUID, summary: String? = nil) -> Self {
        Self(kind: .archiveLink, targetRef: nil, summary: summary, payloadJSON: #"{"id":"\#(id.uuidString.uppercased())"}"#)
    }
}

enum ContinuityJSON {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func encodeString<T: Encodable>(_ value: T) throws -> String {
        let data = try encoder.encode(value)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ContinuityStoreError.invalidPayload("Unable to encode JSON as UTF-8.")
        }
        return string
    }

    static func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw ContinuityStoreError.invalidPayload("Unable to decode JSON as UTF-8.")
        }
        return try decoder.decode(type, from: data)
    }
}
