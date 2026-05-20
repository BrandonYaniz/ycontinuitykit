# Milestone 2 Tasks: Proposal Workflow

## Goal

ContinuityKit supports reviewable proposed changes that can be accepted or rejected.  Proposal acceptance must be transactional.

## Required tasks

1. Implement `ContinuityProposalStatus`.
2. Implement `ContinuityProposal`.
3. Implement `ContinuityProposalOperationKind`.
4. Implement `ContinuityProposalOperation`.
5. Implement `ContinuityProposalOperationDraft`.
6. Add proposals and proposal_operations tables to migration v1.
7. Implement `submitProposal`.
8. Implement `proposals(status:)`.
9. Implement `proposal(id:)`.
10. Implement `proposalOperations(proposalID:)`.
11. Implement `rejectProposal`.
12. Implement `acceptProposal`.
13. Implement operation payload decoding.
14. Implement create operations for all core record types.
15. Implement update operations as full replacement for all core record types.
16. Implement archive operations as soft archive for all core record types.
17. Validate that proposal confidence is between 0.0 and 1.0.
18. Validate that proposal has at least one operation.
19. Validate that only pending proposals can be accepted or rejected.
20. Apply proposal operations inside one GRDB transaction.
21. Allow links to reference records created earlier in the same proposal.
22. Add tests for proposal storage, rejection, acceptance, and atomic failure.

## Operation rules

Create operations use payload JSON containing the full record.

Update operations use payload JSON containing the full updated record.

Archive operations use `targetRef`.  Payload JSON can be `{}`.

For create operations, the payload record ID is authoritative.  This allows later operations in the same proposal to link to records created earlier in the same proposal.

## Transaction rule

A proposal must either fully apply or not apply at all.

If one operation fails, no operations from that proposal should be committed.

## Acceptance criteria

- Proposals can be submitted and stored as pending.
- Proposal operations are stored in stable sort order.
- Rejected proposals do not mutate graph records.
- Accepted proposals apply all operations transactionally.
- Create, update, and archive operations work for all core record types.
- Links can reference records created earlier in the same proposal.
- Invalid proposals fail safely.
- Unit tests prove atomic behavior.
