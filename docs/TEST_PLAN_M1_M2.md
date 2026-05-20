# Test Plan for Milestones 1 and 2

Use XCTest.

Tests should use temporary directories and delete them after test completion.

## Milestone 1 tests

### Project creation

- Create a project package.
- Verify `.continuity` directory exists.
- Verify `manifest.json` exists.
- Verify `continuity.sqlite` exists.
- Verify expected source, attachment, and export directories exist.

### Project open

- Create project.
- Close store.
- Open project again.
- Fetch project row.

### Object CRUD

- Create object.
- Fetch object by ID.
- Fetch objects by type.
- Update summary.
- Archive object.
- Verify default fetch excludes archived.

### Event CRUD and timeline query

- Create three events with sort keys.
- Query a middle range.
- Verify only matching events are returned in order.

### Claim CRUD

- Create claim.
- Fetch claim by ID.
- Fetch claims by status.
- Update status.
- Archive claim.

### Source CRUD

- Create source record.
- Fetch source.
- Update citation.
- Archive source.

### Note CRUD

- Create note with linked refs.
- Fetch note.
- Update body.
- Archive note.

### Link CRUD

- Create object and event.
- Create link object -> participated_in -> event.
- Fetch links from object.
- Fetch links to event.
- Update link summary.
- Archive link.

### Business Plot graph fixture

- Create Smedley Butler object.
- Create McCormack-Dickstein Committee object.
- Create testimony event.
- Create coup claim.
- Create Butler participated_in event link.
- Create claim about event link.
- Create committee investigated claim link.
- Verify links can be traversed from Butler and from event.

## Milestone 2 tests

### Submit proposal stores proposal and operations

- Submit proposal with three operations.
- Fetch pending proposals.
- Fetch operations for proposal.
- Verify sort order and payload JSON.

### Reject proposal does not apply records

- Submit proposal to create object.
- Reject proposal.
- Verify proposal status is rejected.
- Verify object does not exist.

### Accept proposal creates records

- Submit proposal creating object, event, claim, and links.
- Accept proposal.
- Verify proposal status is accepted.
- Verify records exist.
- Verify links resolve.

### Accept proposal is atomic

- Submit proposal with one valid object create and one invalid link to a missing object.
- Accept proposal should fail.
- Verify object was not created.
- Verify proposal remains pending unless implementation explicitly marks failed.

### Proposal can link to record created earlier in same proposal

- Proposal creates object A.
- Proposal creates event B.
- Proposal creates link A -> participated_in -> B.
- Accept proposal.
- Verify all records exist and link resolves.

### Update operation replaces existing record

- Create object directly.
- Submit proposal to update object summary.
- Accept proposal.
- Fetch object.
- Verify summary changed.

### Archive operation sets archivedAt

- Create object directly.
- Submit archive proposal.
- Accept proposal.
- Fetch object including archived.
- Verify archivedAt is not nil.
- Default object query should exclude archived records.

### Proposal status safety

- Accept already accepted proposal should throw.
- Reject already accepted proposal should throw.
- Accept rejected proposal should throw.

### Confidence validation

- Submit proposal with confidence below 0.0 should throw.
- Submit proposal with confidence above 1.0 should throw.
