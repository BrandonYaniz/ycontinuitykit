import Foundation
import GRDB

public final class ContinuityStore {
    public let projectURL: URL
    public let project: ContinuityProject

    private let dbQueue: DatabaseQueue

    private init(projectURL: URL, project: ContinuityProject, dbQueue: DatabaseQueue) {
        self.projectURL = projectURL
        self.project = project
        self.dbQueue = dbQueue
    }

    public static func createProject(at projectURL: URL, name: String, description: String? = nil, appContext: String? = nil) throws -> ContinuityStore {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: projectURL.appendingPathComponent("sources/originals"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: projectURL.appendingPathComponent("sources/extracted"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: projectURL.appendingPathComponent("attachments"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: projectURL.appendingPathComponent("exports"), withIntermediateDirectories: true)

        let now = Date()
        let project = ContinuityProject(name: name, description: description, appContext: appContext, createdAt: now, updatedAt: now)
        let manifest = ContinuityManifest(projectID: project.id, name: name, description: description, appContext: appContext, schemaVersion: 1, createdAt: now, updatedAt: now)
        let manifestData = try ContinuityJSON.encoder.encode(manifest)
        try manifestData.write(to: projectURL.appendingPathComponent("manifest.json"), options: .atomic)

        let dbQueue = try openDatabase(at: projectURL.appendingPathComponent("continuity.sqlite"))
        try migrator.migrate(dbQueue)
        try dbQueue.write { db in
            try insertProject(project, db: db)
        }
        return ContinuityStore(projectURL: projectURL, project: project, dbQueue: dbQueue)
    }

    public static func open(projectURL: URL) throws -> ContinuityStore {
        let dbURL = projectURL.appendingPathComponent("continuity.sqlite")
        guard FileManager.default.fileExists(atPath: dbURL.path) else {
            throw ContinuityStoreError.projectNotOpen
        }
        let dbQueue = try openDatabase(at: dbURL)
        try migrator.migrate(dbQueue)
        let project = try dbQueue.read { db in
            try ContinuityProject.fetchOne(db, sql: "SELECT * FROM projects LIMIT 1")
        }
        guard let project else {
            throw ContinuityStoreError.projectNotOpen
        }
        return ContinuityStore(projectURL: projectURL, project: project, dbQueue: dbQueue)
    }

    public func createObject(_ object: ContinuityObject) throws {
        try dbQueue.write { db in
            try Self.validateProject(object.projectID, expected: project.id)
            try Self.insertObject(object, db: db)
        }
    }

    public func updateObject(_ object: ContinuityObject) throws {
        try dbQueue.write { db in
            try Self.validateProject(object.projectID, expected: project.id)
            try Self.ensureRecordExists(ContinuityRef(kind: .object, id: object.id), db: db)
            try Self.updateObject(object, db: db)
        }
    }

    public func archiveObject(id: UUID) throws {
        try dbQueue.write { db in
            try Self.archiveObject(id: id, db: db)
        }
    }

    public func object(id: UUID, includeArchived: Bool = false) throws -> ContinuityObject? {
        try dbQueue.read { db in
            try Self.fetchObject(id: id, includeArchived: includeArchived, db: db)
        }
    }

    public func objects(type: String? = nil, includeArchived: Bool = false) throws -> [ContinuityObject] {
        try dbQueue.read { db in
            var sql = "SELECT * FROM objects WHERE project_id = ?"
            var arguments: StatementArguments = [project.id.dbString]
            if let type {
                sql += " AND object_type = ?"
                arguments += [type]
            }
            if !includeArchived {
                sql += " AND archived_at IS NULL"
            }
            sql += " ORDER BY name COLLATE NOCASE, created_at"
            return try ContinuityObject.fetchAll(db, sql: sql, arguments: arguments)
        }
    }

    public func createEvent(_ event: ContinuityEvent) throws {
        try dbQueue.write { db in
            try Self.validateProject(event.projectID, expected: project.id)
            try Self.insertEvent(event, db: db)
        }
    }

    public func updateEvent(_ event: ContinuityEvent) throws {
        try dbQueue.write { db in
            try Self.validateProject(event.projectID, expected: project.id)
            try Self.ensureRecordExists(ContinuityRef(kind: .event, id: event.id), db: db)
            try Self.updateEvent(event, db: db)
        }
    }

    public func archiveEvent(id: UUID) throws {
        try dbQueue.write { db in
            try Self.archiveEvent(id: id, db: db)
        }
    }

    public func event(id: UUID, includeArchived: Bool = false) throws -> ContinuityEvent? {
        try dbQueue.read { db in
            try Self.fetchEvent(id: id, includeArchived: includeArchived, db: db)
        }
    }

    public func events(matching query: ContinuityTimelineQuery) throws -> [ContinuityEvent] {
        try dbQueue.read { db in
            var sql = "SELECT * FROM events WHERE project_id = ?"
            var arguments: StatementArguments = [project.id.dbString]
            if let startSortKey = query.startSortKey {
                sql += " AND time_sort_key >= ?"
                arguments += [startSortKey]
            }
            if let endSortKey = query.endSortKey {
                sql += " AND time_sort_key <= ?"
                arguments += [endSortKey]
            }
            if !query.includeArchived {
                sql += " AND archived_at IS NULL"
            }
            sql += " ORDER BY time_sort_key IS NULL, time_sort_key, created_at"
            if let limit = query.limit {
                sql += " LIMIT ?"
                arguments += [limit]
            }
            if let offset = query.offset {
                if query.limit == nil {
                    sql += " LIMIT -1"
                }
                sql += " OFFSET ?"
                arguments += [offset]
            }
            return try ContinuityEvent.fetchAll(db, sql: sql, arguments: arguments)
        }
    }

    public func createClaim(_ claim: ContinuityClaim) throws {
        try dbQueue.write { db in
            try Self.validateProject(claim.projectID, expected: project.id)
            try Self.insertClaim(claim, db: db)
        }
    }

    public func updateClaim(_ claim: ContinuityClaim) throws {
        try dbQueue.write { db in
            try Self.validateProject(claim.projectID, expected: project.id)
            try Self.ensureRecordExists(ContinuityRef(kind: .claim, id: claim.id), db: db)
            try Self.updateClaim(claim, db: db)
        }
    }

    public func archiveClaim(id: UUID) throws {
        try dbQueue.write { db in
            try Self.archiveClaim(id: id, db: db)
        }
    }

    public func claim(id: UUID, includeArchived: Bool = false) throws -> ContinuityClaim? {
        try dbQueue.read { db in
            try Self.fetchClaim(id: id, includeArchived: includeArchived, db: db)
        }
    }

    public func claims(status: ContinuityClaimStatus? = nil, includeArchived: Bool = false) throws -> [ContinuityClaim] {
        try dbQueue.read { db in
            var sql = "SELECT * FROM claims WHERE project_id = ?"
            var arguments: StatementArguments = [project.id.dbString]
            if let status {
                sql += " AND status = ?"
                arguments += [status.rawValue]
            }
            if !includeArchived {
                sql += " AND archived_at IS NULL"
            }
            sql += " ORDER BY created_at"
            return try ContinuityClaim.fetchAll(db, sql: sql, arguments: arguments)
        }
    }

    public func createSource(_ source: ContinuitySource) throws {
        try dbQueue.write { db in
            try Self.validateProject(source.projectID, expected: project.id)
            try Self.insertSource(source, db: db)
        }
    }

    public func updateSource(_ source: ContinuitySource) throws {
        try dbQueue.write { db in
            try Self.validateProject(source.projectID, expected: project.id)
            try Self.ensureRecordExists(ContinuityRef(kind: .source, id: source.id), db: db)
            try Self.updateSource(source, db: db)
        }
    }

    public func archiveSource(id: UUID) throws {
        try dbQueue.write { db in
            try Self.archiveSource(id: id, db: db)
        }
    }

    public func source(id: UUID, includeArchived: Bool = false) throws -> ContinuitySource? {
        try dbQueue.read { db in
            try Self.fetchSource(id: id, includeArchived: includeArchived, db: db)
        }
    }

    public func createNote(_ note: ContinuityNote) throws {
        try dbQueue.write { db in
            try Self.validateProject(note.projectID, expected: project.id)
            try Self.insertNote(note, db: db)
        }
    }

    public func updateNote(_ note: ContinuityNote) throws {
        try dbQueue.write { db in
            try Self.validateProject(note.projectID, expected: project.id)
            try Self.ensureRecordExists(ContinuityRef(kind: .note, id: note.id), db: db)
            try Self.updateNote(note, db: db)
        }
    }

    public func archiveNote(id: UUID) throws {
        try dbQueue.write { db in
            try Self.archiveNote(id: id, db: db)
        }
    }

    public func note(id: UUID, includeArchived: Bool = false) throws -> ContinuityNote? {
        try dbQueue.read { db in
            try Self.fetchNote(id: id, includeArchived: includeArchived, db: db)
        }
    }

    public func createLink(_ link: ContinuityLink) throws {
        try dbQueue.write { db in
            try Self.validateProject(link.projectID, expected: project.id)
            try Self.validateLinkRefs(link, db: db)
            try Self.insertLink(link, db: db)
        }
    }

    public func updateLink(_ link: ContinuityLink) throws {
        try dbQueue.write { db in
            try Self.validateProject(link.projectID, expected: project.id)
            try Self.ensureLinkExists(id: link.id, db: db)
            try Self.validateLinkRefs(link, db: db)
            try Self.updateLink(link, db: db)
        }
    }

    public func archiveLink(id: UUID) throws {
        try dbQueue.write { db in
            try Self.archiveLink(id: id, db: db)
        }
    }

    public func link(id: UUID, includeArchived: Bool = false) throws -> ContinuityLink? {
        try dbQueue.read { db in
            try Self.fetchLink(id: id, includeArchived: includeArchived, db: db)
        }
    }

    public func links(from ref: ContinuityRef, relationshipType: String? = nil, includeArchived: Bool = false) throws -> [ContinuityLink] {
        try dbQueue.read { db in
            var sql = "SELECT * FROM links WHERE project_id = ? AND from_kind = ? AND from_id = ?"
            var arguments: StatementArguments = [project.id.dbString, ref.kind.rawValue, ref.id.dbString]
            if let relationshipType {
                sql += " AND relationship_type = ?"
                arguments += [relationshipType]
            }
            if !includeArchived {
                sql += " AND archived_at IS NULL"
            }
            sql += " ORDER BY created_at"
            return try ContinuityLink.fetchAll(db, sql: sql, arguments: arguments)
        }
    }

    public func links(to ref: ContinuityRef, relationshipType: String? = nil, includeArchived: Bool = false) throws -> [ContinuityLink] {
        try dbQueue.read { db in
            var sql = "SELECT * FROM links WHERE project_id = ? AND to_kind = ? AND to_id = ?"
            var arguments: StatementArguments = [project.id.dbString, ref.kind.rawValue, ref.id.dbString]
            if let relationshipType {
                sql += " AND relationship_type = ?"
                arguments += [relationshipType]
            }
            if !includeArchived {
                sql += " AND archived_at IS NULL"
            }
            sql += " ORDER BY created_at"
            return try ContinuityLink.fetchAll(db, sql: sql, arguments: arguments)
        }
    }

    public func submitProposal(summary: String, detail: String? = nil, operations: [ContinuityProposalOperationDraft], sourceIDs: [UUID] = [], confidence: Double, createdBy: String) throws -> ContinuityProposal {
        guard (0.0...1.0).contains(confidence) else {
            throw ContinuityStoreError.confidenceOutOfRange(confidence)
        }
        guard !operations.isEmpty else {
            throw ContinuityStoreError.invalidProposal("A proposal must contain at least one operation.")
        }

        let now = Date()
        let proposal = ContinuityProposal(projectID: project.id, summary: summary, detail: detail, status: .pending, sourceIDs: sourceIDs, confidence: confidence, createdBy: createdBy, createdAt: now, updatedAt: now)
        try dbQueue.write { db in
            try Self.insertProposal(proposal, db: db)
            for (index, draft) in operations.enumerated() {
                let operation = ContinuityProposalOperation(projectID: project.id, proposalID: proposal.id, sortOrder: index, kind: draft.kind, targetRef: draft.targetRef, summary: draft.summary, payloadJSON: draft.payloadJSON, createdAt: now)
                try Self.insertProposalOperation(operation, db: db)
            }
        }
        return proposal
    }

    public func proposals(status: ContinuityProposalStatus? = nil) throws -> [ContinuityProposal] {
        try dbQueue.read { db in
            var sql = "SELECT * FROM proposals WHERE project_id = ?"
            var arguments: StatementArguments = [project.id.dbString]
            if let status {
                sql += " AND status = ?"
                arguments += [status.rawValue]
            }
            sql += " ORDER BY created_at"
            return try ContinuityProposal.fetchAll(db, sql: sql, arguments: arguments)
        }
    }

    public func proposal(id: UUID) throws -> ContinuityProposal? {
        try dbQueue.read { db in
            try ContinuityProposal.fetchOne(db, sql: "SELECT * FROM proposals WHERE project_id = ? AND id = ?", arguments: [project.id.dbString, id.dbString])
        }
    }

    public func proposalOperations(proposalID: UUID) throws -> [ContinuityProposalOperation] {
        try dbQueue.read { db in
            try ContinuityProposalOperation.fetchAll(db, sql: "SELECT * FROM proposal_operations WHERE project_id = ? AND proposal_id = ? ORDER BY sort_order", arguments: [project.id.dbString, proposalID.dbString])
        }
    }

    public func rejectProposal(id: UUID) throws {
        try dbQueue.write { db in
            guard let proposal = try ContinuityProposal.fetchOne(db, sql: "SELECT * FROM proposals WHERE project_id = ? AND id = ?", arguments: [project.id.dbString, id.dbString]) else {
                throw ContinuityStoreError.invalidProposal("Proposal not found.")
            }
            guard proposal.status == .pending else {
                throw ContinuityStoreError.invalidProposalStatus(proposal.status.rawValue)
            }
            let now = Date()
            try db.execute(sql: "UPDATE proposals SET status = ?, updated_at = ?, reviewed_at = ? WHERE id = ?", arguments: [ContinuityProposalStatus.rejected.rawValue, now.dbString, now.dbString, id.dbString])
        }
    }

    public func acceptProposal(id: UUID) throws {
        try dbQueue.write { db in
            guard let proposal = try ContinuityProposal.fetchOne(db, sql: "SELECT * FROM proposals WHERE project_id = ? AND id = ?", arguments: [project.id.dbString, id.dbString]) else {
                throw ContinuityStoreError.invalidProposal("Proposal not found.")
            }
            guard proposal.status == .pending else {
                throw ContinuityStoreError.invalidProposalStatus(proposal.status.rawValue)
            }

            let operations = try ContinuityProposalOperation.fetchAll(db, sql: "SELECT * FROM proposal_operations WHERE project_id = ? AND proposal_id = ? ORDER BY sort_order", arguments: [project.id.dbString, id.dbString])
            for operation in operations {
                try Self.apply(operation, projectID: project.id, db: db)
            }

            let now = Date()
            try db.execute(sql: "UPDATE proposals SET status = ?, updated_at = ?, reviewed_at = ? WHERE id = ?", arguments: [ContinuityProposalStatus.accepted.rawValue, now.dbString, now.dbString, id.dbString])
        }
    }
}

private struct ContinuityManifest: Codable {
    var projectID: UUID
    var name: String
    var description: String?
    var appContext: String?
    var schemaVersion: Int
    var createdAt: Date
    var updatedAt: Date
}

private extension ContinuityStore {
    static func openDatabase(at url: URL) throws -> DatabaseQueue {
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            try db.execute(sql: "PRAGMA foreign_keys = ON")
        }
        return try DatabaseQueue(path: url.path, configuration: configuration)
    }

    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.execute(sql: """
            CREATE TABLE projects (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                description TEXT,
                app_context TEXT,
                schema_version INTEGER NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );
            CREATE TABLE objects (
                id TEXT PRIMARY KEY NOT NULL,
                project_id TEXT NOT NULL,
                name TEXT NOT NULL,
                object_type TEXT NOT NULL,
                summary TEXT,
                aliases_json TEXT NOT NULL,
                metadata_json TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT,
                FOREIGN KEY(project_id) REFERENCES projects(id)
            );
            CREATE INDEX idx_objects_project_type ON objects(project_id, object_type);
            CREATE INDEX idx_objects_project_name ON objects(project_id, name);
            CREATE INDEX idx_objects_project_archived ON objects(project_id, archived_at);
            CREATE TABLE events (
                id TEXT PRIMARY KEY NOT NULL,
                project_id TEXT NOT NULL,
                title TEXT NOT NULL,
                summary TEXT,
                time_json TEXT NOT NULL,
                time_sort_key REAL,
                time_confidence REAL NOT NULL,
                metadata_json TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT,
                FOREIGN KEY(project_id) REFERENCES projects(id)
            );
            CREATE INDEX idx_events_project_sort_key ON events(project_id, time_sort_key);
            CREATE INDEX idx_events_project_title ON events(project_id, title);
            CREATE INDEX idx_events_project_archived ON events(project_id, archived_at);
            CREATE TABLE claims (
                id TEXT PRIMARY KEY NOT NULL,
                project_id TEXT NOT NULL,
                statement TEXT NOT NULL,
                claim_type TEXT NOT NULL,
                status TEXT NOT NULL,
                confidence REAL NOT NULL,
                source_ids_json TEXT NOT NULL,
                metadata_json TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT,
                FOREIGN KEY(project_id) REFERENCES projects(id)
            );
            CREATE INDEX idx_claims_project_status ON claims(project_id, status);
            CREATE INDEX idx_claims_project_type ON claims(project_id, claim_type);
            CREATE INDEX idx_claims_project_archived ON claims(project_id, archived_at);
            CREATE TABLE sources (
                id TEXT PRIMARY KEY NOT NULL,
                project_id TEXT NOT NULL,
                title TEXT NOT NULL,
                source_type TEXT NOT NULL,
                original_filename TEXT,
                stored_path TEXT,
                checksum TEXT,
                origin TEXT,
                citation TEXT,
                extracted_text_path TEXT,
                metadata_json TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT,
                FOREIGN KEY(project_id) REFERENCES projects(id)
            );
            CREATE INDEX idx_sources_project_type ON sources(project_id, source_type);
            CREATE INDEX idx_sources_project_checksum ON sources(project_id, checksum);
            CREATE INDEX idx_sources_project_archived ON sources(project_id, archived_at);
            CREATE TABLE notes (
                id TEXT PRIMARY KEY NOT NULL,
                project_id TEXT NOT NULL,
                title TEXT,
                body TEXT NOT NULL,
                linked_refs_json TEXT NOT NULL,
                source_ids_json TEXT NOT NULL,
                metadata_json TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT,
                FOREIGN KEY(project_id) REFERENCES projects(id)
            );
            CREATE INDEX idx_notes_project_archived ON notes(project_id, archived_at);
            CREATE TABLE links (
                id TEXT PRIMARY KEY NOT NULL,
                project_id TEXT NOT NULL,
                from_kind TEXT NOT NULL,
                from_id TEXT NOT NULL,
                relationship_type TEXT NOT NULL,
                to_kind TEXT NOT NULL,
                to_id TEXT NOT NULL,
                time_json TEXT,
                time_sort_key REAL,
                time_confidence REAL,
                confidence REAL NOT NULL,
                summary TEXT,
                source_ids_json TEXT NOT NULL,
                metadata_json TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                archived_at TEXT,
                FOREIGN KEY(project_id) REFERENCES projects(id)
            );
            CREATE INDEX idx_links_from ON links(project_id, from_kind, from_id);
            CREATE INDEX idx_links_to ON links(project_id, to_kind, to_id);
            CREATE INDEX idx_links_relationship ON links(project_id, relationship_type);
            CREATE INDEX idx_links_project_sort_key ON links(project_id, time_sort_key);
            CREATE INDEX idx_links_project_archived ON links(project_id, archived_at);
            CREATE TABLE proposals (
                id TEXT PRIMARY KEY NOT NULL,
                project_id TEXT NOT NULL,
                summary TEXT NOT NULL,
                detail TEXT,
                status TEXT NOT NULL,
                source_ids_json TEXT NOT NULL,
                confidence REAL NOT NULL,
                created_by TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                reviewed_at TEXT,
                FOREIGN KEY(project_id) REFERENCES projects(id)
            );
            CREATE INDEX idx_proposals_project_status ON proposals(project_id, status);
            CREATE INDEX idx_proposals_project_created ON proposals(project_id, created_at);
            CREATE TABLE proposal_operations (
                id TEXT PRIMARY KEY NOT NULL,
                project_id TEXT NOT NULL,
                proposal_id TEXT NOT NULL,
                sort_order INTEGER NOT NULL,
                kind TEXT NOT NULL,
                target_kind TEXT,
                target_id TEXT,
                summary TEXT,
                payload_json TEXT NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY(project_id) REFERENCES projects(id),
                FOREIGN KEY(proposal_id) REFERENCES proposals(id)
            );
            CREATE INDEX idx_proposal_operations_proposal ON proposal_operations(project_id, proposal_id, sort_order);
            CREATE INDEX idx_proposal_operations_kind ON proposal_operations(project_id, kind);
            """)
        }
        return migrator
    }

    static func validateProject(_ value: UUID, expected: UUID) throws {
        if value != expected {
            throw ContinuityStoreError.invalidReference(ContinuityRef(kind: .object, id: value))
        }
    }

    static func insertProject(_ project: ContinuityProject, db: Database) throws {
        try db.execute(
            sql: "INSERT INTO projects (id, name, description, app_context, schema_version, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            arguments: [project.id.dbString, project.name, project.description, project.appContext, project.schemaVersion, project.createdAt.dbString, project.updatedAt.dbString]
        )
    }

    static func insertObject(_ object: ContinuityObject, db: Database) throws {
        try db.execute(sql: "INSERT INTO objects (id, project_id, name, object_type, summary, aliases_json, metadata_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: object.arguments)
    }

    static func updateObject(_ object: ContinuityObject, db: Database) throws {
        try db.execute(sql: "UPDATE objects SET project_id = ?, name = ?, object_type = ?, summary = ?, aliases_json = ?, metadata_json = ?, created_at = ?, updated_at = ?, archived_at = ? WHERE id = ?", arguments: object.updateArguments)
    }

    static func archiveObject(id: UUID, db: Database) throws {
        try ensureRecordExists(ContinuityRef(kind: .object, id: id), db: db)
        try db.execute(sql: "UPDATE objects SET archived_at = ?, updated_at = ? WHERE id = ?", arguments: [Date().dbString, Date().dbString, id.dbString])
    }

    static func fetchObject(id: UUID, includeArchived: Bool, db: Database) throws -> ContinuityObject? {
        var sql = "SELECT * FROM objects WHERE id = ?"
        if !includeArchived {
            sql += " AND archived_at IS NULL"
        }
        return try ContinuityObject.fetchOne(db, sql: sql, arguments: [id.dbString])
    }

    static func insertEvent(_ event: ContinuityEvent, db: Database) throws {
        try db.execute(sql: "INSERT INTO events (id, project_id, title, summary, time_json, time_sort_key, time_confidence, metadata_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: event.arguments)
    }

    static func updateEvent(_ event: ContinuityEvent, db: Database) throws {
        try db.execute(sql: "UPDATE events SET project_id = ?, title = ?, summary = ?, time_json = ?, time_sort_key = ?, time_confidence = ?, metadata_json = ?, created_at = ?, updated_at = ?, archived_at = ? WHERE id = ?", arguments: event.updateArguments)
    }

    static func archiveEvent(id: UUID, db: Database) throws {
        try ensureRecordExists(ContinuityRef(kind: .event, id: id), db: db)
        let now = Date().dbString
        try db.execute(sql: "UPDATE events SET archived_at = ?, updated_at = ? WHERE id = ?", arguments: [now, now, id.dbString])
    }

    static func fetchEvent(id: UUID, includeArchived: Bool, db: Database) throws -> ContinuityEvent? {
        var sql = "SELECT * FROM events WHERE id = ?"
        if !includeArchived {
            sql += " AND archived_at IS NULL"
        }
        return try ContinuityEvent.fetchOne(db, sql: sql, arguments: [id.dbString])
    }

    static func insertClaim(_ claim: ContinuityClaim, db: Database) throws {
        try db.execute(sql: "INSERT INTO claims (id, project_id, statement, claim_type, status, confidence, source_ids_json, metadata_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: claim.arguments)
    }

    static func updateClaim(_ claim: ContinuityClaim, db: Database) throws {
        try db.execute(sql: "UPDATE claims SET project_id = ?, statement = ?, claim_type = ?, status = ?, confidence = ?, source_ids_json = ?, metadata_json = ?, created_at = ?, updated_at = ?, archived_at = ? WHERE id = ?", arguments: claim.updateArguments)
    }

    static func archiveClaim(id: UUID, db: Database) throws {
        try ensureRecordExists(ContinuityRef(kind: .claim, id: id), db: db)
        let now = Date().dbString
        try db.execute(sql: "UPDATE claims SET archived_at = ?, updated_at = ? WHERE id = ?", arguments: [now, now, id.dbString])
    }

    static func fetchClaim(id: UUID, includeArchived: Bool, db: Database) throws -> ContinuityClaim? {
        var sql = "SELECT * FROM claims WHERE id = ?"
        if !includeArchived {
            sql += " AND archived_at IS NULL"
        }
        return try ContinuityClaim.fetchOne(db, sql: sql, arguments: [id.dbString])
    }

    static func insertSource(_ source: ContinuitySource, db: Database) throws {
        try db.execute(sql: "INSERT INTO sources (id, project_id, title, source_type, original_filename, stored_path, checksum, origin, citation, extracted_text_path, metadata_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: source.arguments)
    }

    static func updateSource(_ source: ContinuitySource, db: Database) throws {
        try db.execute(sql: "UPDATE sources SET project_id = ?, title = ?, source_type = ?, original_filename = ?, stored_path = ?, checksum = ?, origin = ?, citation = ?, extracted_text_path = ?, metadata_json = ?, created_at = ?, updated_at = ?, archived_at = ? WHERE id = ?", arguments: source.updateArguments)
    }

    static func archiveSource(id: UUID, db: Database) throws {
        try ensureRecordExists(ContinuityRef(kind: .source, id: id), db: db)
        let now = Date().dbString
        try db.execute(sql: "UPDATE sources SET archived_at = ?, updated_at = ? WHERE id = ?", arguments: [now, now, id.dbString])
    }

    static func fetchSource(id: UUID, includeArchived: Bool, db: Database) throws -> ContinuitySource? {
        var sql = "SELECT * FROM sources WHERE id = ?"
        if !includeArchived {
            sql += " AND archived_at IS NULL"
        }
        return try ContinuitySource.fetchOne(db, sql: sql, arguments: [id.dbString])
    }

    static func insertNote(_ note: ContinuityNote, db: Database) throws {
        try db.execute(sql: "INSERT INTO notes (id, project_id, title, body, linked_refs_json, source_ids_json, metadata_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: note.arguments)
    }

    static func updateNote(_ note: ContinuityNote, db: Database) throws {
        try db.execute(sql: "UPDATE notes SET project_id = ?, title = ?, body = ?, linked_refs_json = ?, source_ids_json = ?, metadata_json = ?, created_at = ?, updated_at = ?, archived_at = ? WHERE id = ?", arguments: note.updateArguments)
    }

    static func archiveNote(id: UUID, db: Database) throws {
        try ensureRecordExists(ContinuityRef(kind: .note, id: id), db: db)
        let now = Date().dbString
        try db.execute(sql: "UPDATE notes SET archived_at = ?, updated_at = ? WHERE id = ?", arguments: [now, now, id.dbString])
    }

    static func fetchNote(id: UUID, includeArchived: Bool, db: Database) throws -> ContinuityNote? {
        var sql = "SELECT * FROM notes WHERE id = ?"
        if !includeArchived {
            sql += " AND archived_at IS NULL"
        }
        return try ContinuityNote.fetchOne(db, sql: sql, arguments: [id.dbString])
    }

    static func insertLink(_ link: ContinuityLink, db: Database) throws {
        try db.execute(sql: "INSERT INTO links (id, project_id, from_kind, from_id, relationship_type, to_kind, to_id, time_json, time_sort_key, time_confidence, confidence, summary, source_ids_json, metadata_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: link.arguments)
    }

    static func updateLink(_ link: ContinuityLink, db: Database) throws {
        try db.execute(sql: "UPDATE links SET project_id = ?, from_kind = ?, from_id = ?, relationship_type = ?, to_kind = ?, to_id = ?, time_json = ?, time_sort_key = ?, time_confidence = ?, confidence = ?, summary = ?, source_ids_json = ?, metadata_json = ?, created_at = ?, updated_at = ?, archived_at = ? WHERE id = ?", arguments: link.updateArguments)
    }

    static func archiveLink(id: UUID, db: Database) throws {
        try ensureLinkExists(id: id, db: db)
        let now = Date().dbString
        try db.execute(sql: "UPDATE links SET archived_at = ?, updated_at = ? WHERE id = ?", arguments: [now, now, id.dbString])
    }

    static func fetchLink(id: UUID, includeArchived: Bool, db: Database) throws -> ContinuityLink? {
        var sql = "SELECT * FROM links WHERE id = ?"
        if !includeArchived {
            sql += " AND archived_at IS NULL"
        }
        return try ContinuityLink.fetchOne(db, sql: sql, arguments: [id.dbString])
    }

    static func insertProposal(_ proposal: ContinuityProposal, db: Database) throws {
        try db.execute(sql: "INSERT INTO proposals (id, project_id, summary, detail, status, source_ids_json, confidence, created_by, created_at, updated_at, reviewed_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: proposal.arguments)
    }

    static func insertProposalOperation(_ operation: ContinuityProposalOperation, db: Database) throws {
        try db.execute(sql: "INSERT INTO proposal_operations (id, project_id, proposal_id, sort_order, kind, target_kind, target_id, summary, payload_json, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", arguments: operation.arguments)
    }

    static func apply(_ operation: ContinuityProposalOperation, projectID: UUID, db: Database) throws {
        switch operation.kind {
        case .createObject:
            var object = try decodePayload(ContinuityObject.self, operation)
            object.projectID = projectID
            try insertObject(object, db: db)
        case .updateObject:
            var object = try decodePayload(ContinuityObject.self, operation)
            object.projectID = projectID
            try ensureRecordExists(ContinuityRef(kind: .object, id: object.id), db: db)
            try updateObject(object, db: db)
        case .archiveObject:
            try archiveObject(id: requiredTarget(operation, kind: .object).id, db: db)
        case .createEvent:
            var event = try decodePayload(ContinuityEvent.self, operation)
            event.projectID = projectID
            try insertEvent(event, db: db)
        case .updateEvent:
            var event = try decodePayload(ContinuityEvent.self, operation)
            event.projectID = projectID
            try ensureRecordExists(ContinuityRef(kind: .event, id: event.id), db: db)
            try updateEvent(event, db: db)
        case .archiveEvent:
            try archiveEvent(id: requiredTarget(operation, kind: .event).id, db: db)
        case .createClaim:
            var claim = try decodePayload(ContinuityClaim.self, operation)
            claim.projectID = projectID
            try insertClaim(claim, db: db)
        case .updateClaim:
            var claim = try decodePayload(ContinuityClaim.self, operation)
            claim.projectID = projectID
            try ensureRecordExists(ContinuityRef(kind: .claim, id: claim.id), db: db)
            try updateClaim(claim, db: db)
        case .archiveClaim:
            try archiveClaim(id: requiredTarget(operation, kind: .claim).id, db: db)
        case .createSource:
            var source = try decodePayload(ContinuitySource.self, operation)
            source.projectID = projectID
            try insertSource(source, db: db)
        case .updateSource:
            var source = try decodePayload(ContinuitySource.self, operation)
            source.projectID = projectID
            try ensureRecordExists(ContinuityRef(kind: .source, id: source.id), db: db)
            try updateSource(source, db: db)
        case .archiveSource:
            try archiveSource(id: requiredTarget(operation, kind: .source).id, db: db)
        case .createNote:
            var note = try decodePayload(ContinuityNote.self, operation)
            note.projectID = projectID
            try validateNoteRefs(note, db: db)
            try insertNote(note, db: db)
        case .updateNote:
            var note = try decodePayload(ContinuityNote.self, operation)
            note.projectID = projectID
            try ensureRecordExists(ContinuityRef(kind: .note, id: note.id), db: db)
            try validateNoteRefs(note, db: db)
            try updateNote(note, db: db)
        case .archiveNote:
            try archiveNote(id: requiredTarget(operation, kind: .note).id, db: db)
        case .createLink:
            var link = try decodePayload(ContinuityLink.self, operation)
            link.projectID = projectID
            try validateLinkRefs(link, db: db)
            try insertLink(link, db: db)
        case .updateLink:
            var link = try decodePayload(ContinuityLink.self, operation)
            link.projectID = projectID
            try ensureLinkExists(id: link.id, db: db)
            try validateLinkRefs(link, db: db)
            try updateLink(link, db: db)
        case .archiveLink:
            let id = try decodeArchiveLinkID(operation)
            try archiveLink(id: id, db: db)
        }
    }

    static func decodePayload<T: Decodable>(_ type: T.Type, _ operation: ContinuityProposalOperation) throws -> T {
        do {
            return try ContinuityJSON.decode(type, from: operation.payloadJSON)
        } catch {
            throw ContinuityStoreError.invalidPayload("Invalid payload for \(operation.kind.rawValue).")
        }
    }

    static func decodeArchiveLinkID(_ operation: ContinuityProposalOperation) throws -> UUID {
        struct Payload: Decodable { var id: UUID }
        return try decodePayload(Payload.self, operation).id
    }

    static func requiredTarget(_ operation: ContinuityProposalOperation, kind: ContinuityRecordKind) throws -> ContinuityRef {
        guard let targetRef = operation.targetRef, targetRef.kind == kind else {
            throw ContinuityStoreError.invalidProposal("Missing target reference for \(operation.kind.rawValue).")
        }
        return targetRef
    }

    static func validateLinkRefs(_ link: ContinuityLink, db: Database) throws {
        try ensureRecordExists(link.from, db: db)
        try ensureRecordExists(link.to, db: db)
    }

    static func validateNoteRefs(_ note: ContinuityNote, db: Database) throws {
        for ref in note.linkedRefs {
            try ensureRecordExists(ref, db: db)
        }
    }

    static func ensureRecordExists(_ ref: ContinuityRef, db: Database) throws {
        let table = ref.kind.tableName
        let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table) WHERE id = ?", arguments: [ref.id.dbString]) ?? 0
        if count == 0 {
            throw ContinuityStoreError.invalidReference(ref)
        }
    }

    static func ensureLinkExists(id: UUID, db: Database) throws {
        let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM links WHERE id = ?", arguments: [id.dbString]) ?? 0
        if count == 0 {
            throw ContinuityStoreError.recordNotFound(ContinuityRef(kind: .object, id: id))
        }
    }
}

private extension ContinuityRecordKind {
    var tableName: String {
        switch self {
        case .object: "objects"
        case .event: "events"
        case .claim: "claims"
        case .source: "sources"
        case .note: "notes"
        }
    }
}

private extension UUID {
    var dbString: String { uuidString.uppercased() }
}

private extension Date {
    var dbString: String { ISO8601DateFormatter.continuityFormatter().string(from: self) }
}

private extension ISO8601DateFormatter {
    static func continuityFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

private extension String {
    var dbDate: Date {
        ISO8601DateFormatter.continuityFormatter().date(from: self) ?? Date(timeIntervalSince1970: 0)
    }

    var dbUUID: UUID {
        UUID(uuidString: self) ?? UUID()
    }
}

private extension Optional where Wrapped == String {
    var dbDate: Date? {
        guard let self else { return nil }
        return self.dbDate
    }
}

extension ContinuityProject: FetchableRecord {
    public init(row: Row) throws {
        self.init(
            id: (row["id"] as String).dbUUID,
            name: row["name"],
            description: row["description"],
            appContext: row["app_context"],
            schemaVersion: row["schema_version"],
            createdAt: (row["created_at"] as String).dbDate,
            updatedAt: (row["updated_at"] as String).dbDate
        )
    }
}

extension ContinuityObject: FetchableRecord {
    public init(row: Row) throws {
        self.init(
            id: (row["id"] as String).dbUUID,
            projectID: (row["project_id"] as String).dbUUID,
            name: row["name"],
            objectType: row["object_type"],
            summary: row["summary"],
            aliases: try ContinuityJSON.decode([String].self, from: row["aliases_json"]),
            metadata: try ContinuityJSON.decode([String: String].self, from: row["metadata_json"]),
            createdAt: (row["created_at"] as String).dbDate,
            updatedAt: (row["updated_at"] as String).dbDate,
            archivedAt: (row["archived_at"] as String?).dbDate
        )
    }

    var arguments: StatementArguments {
        get throws {
            [id.dbString, projectID.dbString, name, objectType, summary, try ContinuityJSON.encodeString(aliases), try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString]
        }
    }

    var updateArguments: StatementArguments {
        get throws {
            [projectID.dbString, name, objectType, summary, try ContinuityJSON.encodeString(aliases), try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString, id.dbString]
        }
    }
}

extension ContinuityEvent: FetchableRecord {
    public init(row: Row) throws {
        self.init(
            id: (row["id"] as String).dbUUID,
            projectID: (row["project_id"] as String).dbUUID,
            title: row["title"],
            summary: row["summary"],
            time: try ContinuityJSON.decode(ContinuityTimeValue.self, from: row["time_json"]),
            timeConfidence: row["time_confidence"],
            metadata: try ContinuityJSON.decode([String: String].self, from: row["metadata_json"]),
            createdAt: (row["created_at"] as String).dbDate,
            updatedAt: (row["updated_at"] as String).dbDate,
            archivedAt: (row["archived_at"] as String?).dbDate
        )
    }

    var arguments: StatementArguments {
        get throws {
            [id.dbString, projectID.dbString, title, summary, try ContinuityJSON.encodeString(time), time.sortKey, timeConfidence, try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString]
        }
    }

    var updateArguments: StatementArguments {
        get throws {
            [projectID.dbString, title, summary, try ContinuityJSON.encodeString(time), time.sortKey, timeConfidence, try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString, id.dbString]
        }
    }
}

extension ContinuityClaim: FetchableRecord {
    public init(row: Row) throws {
        self.init(
            id: (row["id"] as String).dbUUID,
            projectID: (row["project_id"] as String).dbUUID,
            statement: row["statement"],
            claimType: row["claim_type"],
            status: ContinuityClaimStatus(rawValue: row["status"]) ?? .unknown,
            confidence: row["confidence"],
            sourceIDs: try ContinuityJSON.decode([UUID].self, from: row["source_ids_json"]),
            metadata: try ContinuityJSON.decode([String: String].self, from: row["metadata_json"]),
            createdAt: (row["created_at"] as String).dbDate,
            updatedAt: (row["updated_at"] as String).dbDate,
            archivedAt: (row["archived_at"] as String?).dbDate
        )
    }

    var arguments: StatementArguments {
        get throws {
            [id.dbString, projectID.dbString, statement, claimType, status.rawValue, confidence, try ContinuityJSON.encodeString(sourceIDs), try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString]
        }
    }

    var updateArguments: StatementArguments {
        get throws {
            [projectID.dbString, statement, claimType, status.rawValue, confidence, try ContinuityJSON.encodeString(sourceIDs), try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString, id.dbString]
        }
    }
}

extension ContinuitySource: FetchableRecord {
    public init(row: Row) throws {
        self.init(
            id: (row["id"] as String).dbUUID,
            projectID: (row["project_id"] as String).dbUUID,
            title: row["title"],
            sourceType: ContinuitySourceType(rawValue: row["source_type"]) ?? .other,
            originalFilename: row["original_filename"],
            storedPath: row["stored_path"],
            checksum: row["checksum"],
            origin: row["origin"],
            citation: row["citation"],
            extractedTextPath: row["extracted_text_path"],
            metadata: try ContinuityJSON.decode([String: String].self, from: row["metadata_json"]),
            createdAt: (row["created_at"] as String).dbDate,
            updatedAt: (row["updated_at"] as String).dbDate,
            archivedAt: (row["archived_at"] as String?).dbDate
        )
    }

    var arguments: StatementArguments {
        get throws {
            [id.dbString, projectID.dbString, title, sourceType.rawValue, originalFilename, storedPath, checksum, origin, citation, extractedTextPath, try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString]
        }
    }

    var updateArguments: StatementArguments {
        get throws {
            [projectID.dbString, title, sourceType.rawValue, originalFilename, storedPath, checksum, origin, citation, extractedTextPath, try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString, id.dbString]
        }
    }
}

extension ContinuityNote: FetchableRecord {
    public init(row: Row) throws {
        self.init(
            id: (row["id"] as String).dbUUID,
            projectID: (row["project_id"] as String).dbUUID,
            title: row["title"],
            body: row["body"],
            linkedRefs: try ContinuityJSON.decode([ContinuityRef].self, from: row["linked_refs_json"]),
            sourceIDs: try ContinuityJSON.decode([UUID].self, from: row["source_ids_json"]),
            metadata: try ContinuityJSON.decode([String: String].self, from: row["metadata_json"]),
            createdAt: (row["created_at"] as String).dbDate,
            updatedAt: (row["updated_at"] as String).dbDate,
            archivedAt: (row["archived_at"] as String?).dbDate
        )
    }

    var arguments: StatementArguments {
        get throws {
            [id.dbString, projectID.dbString, title, body, try ContinuityJSON.encodeString(linkedRefs), try ContinuityJSON.encodeString(sourceIDs), try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString]
        }
    }

    var updateArguments: StatementArguments {
        get throws {
            [projectID.dbString, title, body, try ContinuityJSON.encodeString(linkedRefs), try ContinuityJSON.encodeString(sourceIDs), try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString, id.dbString]
        }
    }
}

extension ContinuityLink: FetchableRecord {
    public init(row: Row) throws {
        let timeJSON: String? = row["time_json"]
        self.init(
            id: (row["id"] as String).dbUUID,
            projectID: (row["project_id"] as String).dbUUID,
            from: ContinuityRef(kind: ContinuityRecordKind(rawValue: row["from_kind"]) ?? .object, id: (row["from_id"] as String).dbUUID),
            relationshipType: row["relationship_type"],
            to: ContinuityRef(kind: ContinuityRecordKind(rawValue: row["to_kind"]) ?? .object, id: (row["to_id"] as String).dbUUID),
            time: try timeJSON.map { try ContinuityJSON.decode(ContinuityTimeValue.self, from: $0) },
            timeConfidence: row["time_confidence"],
            confidence: row["confidence"],
            summary: row["summary"],
            sourceIDs: try ContinuityJSON.decode([UUID].self, from: row["source_ids_json"]),
            metadata: try ContinuityJSON.decode([String: String].self, from: row["metadata_json"]),
            createdAt: (row["created_at"] as String).dbDate,
            updatedAt: (row["updated_at"] as String).dbDate,
            archivedAt: (row["archived_at"] as String?).dbDate
        )
    }

    var arguments: StatementArguments {
        get throws {
            [id.dbString, projectID.dbString, from.kind.rawValue, from.id.dbString, relationshipType, to.kind.rawValue, to.id.dbString, try time.map { try ContinuityJSON.encodeString($0) }, time?.sortKey, timeConfidence, confidence, summary, try ContinuityJSON.encodeString(sourceIDs), try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString]
        }
    }

    var updateArguments: StatementArguments {
        get throws {
            [projectID.dbString, from.kind.rawValue, from.id.dbString, relationshipType, to.kind.rawValue, to.id.dbString, try time.map { try ContinuityJSON.encodeString($0) }, time?.sortKey, timeConfidence, confidence, summary, try ContinuityJSON.encodeString(sourceIDs), try ContinuityJSON.encodeString(metadata), createdAt.dbString, updatedAt.dbString, archivedAt?.dbString, id.dbString]
        }
    }
}

extension ContinuityProposal: FetchableRecord {
    public init(row: Row) throws {
        self.init(
            id: (row["id"] as String).dbUUID,
            projectID: (row["project_id"] as String).dbUUID,
            summary: row["summary"],
            detail: row["detail"],
            status: ContinuityProposalStatus(rawValue: row["status"]) ?? .failed,
            sourceIDs: try ContinuityJSON.decode([UUID].self, from: row["source_ids_json"]),
            confidence: row["confidence"],
            createdBy: row["created_by"],
            createdAt: (row["created_at"] as String).dbDate,
            updatedAt: (row["updated_at"] as String).dbDate,
            reviewedAt: (row["reviewed_at"] as String?).dbDate
        )
    }

    var arguments: StatementArguments {
        get throws {
            [id.dbString, projectID.dbString, summary, detail, status.rawValue, try ContinuityJSON.encodeString(sourceIDs), confidence, createdBy, createdAt.dbString, updatedAt.dbString, reviewedAt?.dbString]
        }
    }
}

extension ContinuityProposalOperation: FetchableRecord {
    public init(row: Row) throws {
        let targetKind: String? = row["target_kind"]
        let targetID: String? = row["target_id"]
        let targetRef = targetKind.flatMap { kind in
            targetID.flatMap { id in
                ContinuityRecordKind(rawValue: kind).map { ContinuityRef(kind: $0, id: id.dbUUID) }
            }
        }
        self.init(
            id: (row["id"] as String).dbUUID,
            projectID: (row["project_id"] as String).dbUUID,
            proposalID: (row["proposal_id"] as String).dbUUID,
            sortOrder: row["sort_order"],
            kind: ContinuityProposalOperationKind(rawValue: row["kind"]) ?? .createObject,
            targetRef: targetRef,
            summary: row["summary"],
            payloadJSON: row["payload_json"],
            createdAt: (row["created_at"] as String).dbDate
        )
    }

    var arguments: StatementArguments {
        [id.dbString, projectID.dbString, proposalID.dbString, sortOrder, kind.rawValue, targetRef?.kind.rawValue, targetRef?.id.dbString, summary, payloadJSON, createdAt.dbString]
    }
}
