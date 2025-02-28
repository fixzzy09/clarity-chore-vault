;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-completed (err u102))
(define-constant err-not-assigned (err u103))

;; Define reward token
(define-fungible-token chore-rewards)

;; Data structures
(define-map chores
  { chore-id: uint }
  {
    name: (string-ascii 64),
    reward: uint,
    assigned-to: principal,
    completed: bool,
    approved: bool
  }
)

(define-data-var chore-id-nonce uint u0)

;; Administrative functions
(define-public (add-chore (name (string-ascii 64)) (reward uint) (assigned-to principal))
  (let ((new-id (+ (var-get chore-id-nonce) u1)))
    (if (is-eq tx-sender contract-owner)
      (begin
        (var-set chore-id-nonce new-id)
        (map-set chores
          { chore-id: new-id }
          {
            name: name,
            reward: reward,
            assigned-to: assigned-to,
            completed: false,
            approved: false
          }
        )
        (ok new-id))
      err-owner-only)))

;; User functions
(define-public (complete-chore (chore-id uint))
  (let ((chore (unwrap! (map-get? chores {chore-id: chore-id}) err-not-found)))
    (if (is-eq (get assigned-to chore) tx-sender)
      (if (get completed chore)
        err-already-completed
        (begin
          (map-set chores
            {chore-id: chore-id}
            (merge chore {completed: true})
          )
          (ok true)))
      err-not-assigned)))

(define-public (approve-chore (chore-id uint))
  (let ((chore (unwrap! (map-get? chores {chore-id: chore-id}) err-not-found)))
    (if (is-eq tx-sender contract-owner)
      (begin
        (try! (ft-mint? chore-rewards (get reward chore) (get assigned-to chore)))
        (map-set chores
          {chore-id: chore-id}
          (merge chore {approved: true})
        )
        (ok true))
      err-owner-only)))

;; Read-only functions
(define-read-only (get-chore (chore-id uint))
  (ok (map-get? chores {chore-id: chore-id})))

(define-read-only (get-balance (user principal))
  (ok (ft-get-balance chore-rewards user)))
