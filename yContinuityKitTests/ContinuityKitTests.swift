import XCTest
@testable import ContinuityKit

final class ContinuityKitTests: XCTestCase {
    private var temporaryURLs: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryURLs {
            try? FileManager.default.removeItem(at: url)
        }
        temporaryURLs.removeAll()
    }

    func testCreateAndOpenProjectPackage() throws {
        let projectURL = makeProjectURL()
        let store = try ContinuityStore.createProject(at: projectURL, name: "Research Notes", description: "Fixture", appContext: "tests")

        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("manifest.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("continuity.sqlite").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("sources/originals").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("sources/extracted").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("attachments").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("exports").path))

        let reopened = try ContinuityStore.open(projectURL: projectURL)
        XCTAssertEqual(reopened.project.id, store.project.id)
        XCTAssertEqual(reopened.project.name, "Research Notes")
    }

    func testObjectEventLinkAndTimelineQueries() throws {
        let store = try makeStore()
        let person = ContinuityObject(projectID: store.project.id, name: "Smedley Butler", objectType: "person")
        let committee = ContinuityObject(projectID: store.project.id, name: "McCormack-Dickstein Committee", objectType: "entity")
        try store.createObject(person)
        try store.createObject(committee)

        var testimony = ContinuityEvent(
            projectID: store.project.id,
            title: "Butler testifies before committee",
            time: ContinuityTimeValue(kind: .date, precision: .day, label: "November 20, 1934", sortKey: 19341120)
        )
        let before = ContinuityEvent(projectID: store.project.id, title: "Before", time: ContinuityTimeValue(kind: .date, sortKey: 19341119))
        let after = ContinuityEvent(projectID: store.project.id, title: "After", time: ContinuityTimeValue(kind: .date, sortKey: 19341121))
        try store.createEvent(before)
        try store.createEvent(testimony)
        try store.createEvent(after)

        testimony.summary = "Public testimony"
        try store.updateEvent(testimony)

        let events = try store.events(matching: ContinuityTimelineQuery(startSortKey: 19341120, endSortKey: 19341120))
        XCTAssertEqual(events.map(\.id), [testimony.id])
        XCTAssertEqual(events.first?.summary, "Public testimony")

        let link = ContinuityLink(
            projectID: store.project.id,
            from: ContinuityRef(kind: .object, id: person.id),
            relationshipType: "participated_in",
            to: ContinuityRef(kind: .event, id: testimony.id),
            summary: "Testimony"
        )
        try store.createLink(link)

        XCTAssertEqual(try store.links(from: ContinuityRef(kind: .object, id: person.id)).first?.id, link.id)
        XCTAssertEqual(try store.links(to: ContinuityRef(kind: .event, id: testimony.id)).first?.id, link.id)

        try store.archiveObject(id: committee.id)
        XCTAssertNil(try store.object(id: committee.id))
        XCTAssertNotNil(try store.object(id: committee.id, includeArchived: true))
    }

    func testProposalAcceptCreatesRecordsTransactionally() throws {
        let store = try makeStore()
        let person = ContinuityObject(projectID: store.project.id, name: "Smedley Butler", objectType: "person")
        let event = ContinuityEvent(
            projectID: store.project.id,
            title: "Butler testifies before committee",
            time: ContinuityTimeValue(kind: .date, precision: .day, sortKey: 19341120)
        )
        let link = ContinuityLink(
            projectID: store.project.id,
            from: ContinuityRef(kind: .object, id: person.id),
            relationshipType: "participated_in",
            to: ContinuityRef(kind: .event, id: event.id)
        )

        let proposal = try store.submitProposal(
            summary: "Add testimony fixture",
            operations: [
                try .createObject(person),
                try .createEvent(event),
                try .createLink(link)
            ],
            confidence: 0.8,
            createdBy: "test"
        )
        try store.acceptProposal(id: proposal.id)

        XCTAssertEqual(try store.proposal(id: proposal.id)?.status, .accepted)
        XCTAssertEqual(try store.object(id: person.id)?.name, "Smedley Butler")
        XCTAssertEqual(try store.link(id: link.id)?.relationshipType, "participated_in")
    }

    func testProposalAcceptanceRollsBackOnInvalidLink() throws {
        let store = try makeStore()
        let person = ContinuityObject(projectID: store.project.id, name: "Smedley Butler", objectType: "person")
        let link = ContinuityLink(
            projectID: store.project.id,
            from: ContinuityRef(kind: .object, id: person.id),
            relationshipType: "participated_in",
            to: ContinuityRef(kind: .event, id: UUID())
        )
        let proposal = try store.submitProposal(
            summary: "Invalid link",
            operations: [
                try .createObject(person),
                try .createLink(link)
            ],
            confidence: 0.7,
            createdBy: "test"
        )

        XCTAssertThrowsError(try store.acceptProposal(id: proposal.id))
        XCTAssertNil(try store.object(id: person.id))
        XCTAssertEqual(try store.proposal(id: proposal.id)?.status, .pending)
    }

    func testRejectProposalDoesNotApplyRecords() throws {
        let store = try makeStore()
        let object = ContinuityObject(projectID: store.project.id, name: "Unreviewed", objectType: "note")
        let proposal = try store.submitProposal(
            summary: "Add unreviewed object",
            operations: [try .createObject(object)],
            confidence: 0.5,
            createdBy: "test"
        )

        try store.rejectProposal(id: proposal.id)

        XCTAssertEqual(try store.proposal(id: proposal.id)?.status, .rejected)
        XCTAssertNil(try store.object(id: object.id))
    }

    private func makeStore() throws -> ContinuityStore {
        try ContinuityStore.createProject(at: makeProjectURL(), name: "Fixture")
    }

    private func makeProjectURL() -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        temporaryURLs.append(root)
        return root.appendingPathComponent("Fixture.continuity", isDirectory: true)
    }
}
