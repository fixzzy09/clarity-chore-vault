# ChoreVault
A family chore management system with reward tracking built on Stacks blockchain.

## Features
- Create and manage chores with associated rewards
- Track chore completion status
- Manage family member accounts
- Automated reward distribution system
- Parent approval workflow
- View chore history and reward balances

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute test suite

## Usage Examples
```clarity
;; Add a new chore (parent only)
(contract-call? .chore-vault add-chore "Clean room" u50 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Mark chore as complete (child)
(contract-call? .chore-vault complete-chore u1)

;; Approve chore completion (parent only)
(contract-call? .chore-vault approve-chore u1)

;; Check reward balance
(contract-call? .chore-vault get-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
