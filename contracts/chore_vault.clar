;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-completed (err u102))
(define-constant err-not-assigned (err u103))
(define-constant err-past-deadline (err u104))
(define-constant err-contract-paused (err u105))
(define-constant err-invalid-reward (err u106))
(define-constant max-reward u1000)

;; Define reward token
(define-fungible-token chore-rewards)

;; Contract status
(define-data-var contract-paused bool false)

;; Data structures
(define-map chores
  { chore-id: uint }
  {
    name: (string-ascii 64),
    reward: uint,
    assigned-to: principal,
    completed: bool,
    approved: bool,
    deadline: uint,
    created-at: uint
  }
)

(define-data-var chore-id-nonce uint u0)

;; Events
(define-public (print-chore-event (event-type (string-ascii 12)) (chore-id uint))
  (ok (print { event-type: event-type, chore-id: chore-id, caller: tx-sender })))

;; Contract management
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused true)
    (ok true)))

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused false)
    (ok true)))

;; Administrative functions
(define-public (add-chore (name (string-ascii 64)) (reward uint) (assigned-to principal) (deadline uint))
  (let ((new-id (+ (var-get chore-id-nonce) u1)))
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= reward max-reward) err-invalid-reward)
    (begin
      (var-set chore-id-nonce new-id)
      (map-set chores
        { chore-id: new-id }
        {
          name: name,
          reward: reward,
          assigned-to: assigned-to,
          completed: false,
          approved: false,
          deadline: deadline,
          created-at: block-height
        }
      )
      (try! (print-chore-event "chore-added" new-id))
      (ok new-id))))

(define-public (delete-chore (chore-id uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (map-delete chores {chore-id: chore-id})
    (try! (print-chore-event "chore-deleted" chore-id))
    (ok true)))

;; User functions
(define-public (complete-chore (chore-id uint))
  (let ((chore (unwrap! (map-get? chores {chore-id: chore-id}) err-not-found)))
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-eq (get assigned-to chore) tx-sender) err-not-assigned)
    (asserts! (not (get completed chore)) err-already-completed)
    (asserts! (<= block-height (get deadline chore)) err-past-deadline)
    (begin
      (map-set chores
        {chore-id: chore-id}
        (merge chore {completed: true})
      )
      (try! (print-chore-event "completed" chore-id))
      (ok true))))

(define-public (approve-chore (chore-id uint))
  (let ((chore (unwrap! (map-get? chores {chore-id: chore-id}) err-not-found)))
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (begin
      (try! (ft-mint? chore-rewards (get reward chore) (get assigned-to chore)))
      (map-set chores
        {chore-id: chore-id}
        (merge chore {approved: true})
      )
      (try! (print-chore-event "approved" chore-id))
      (ok true))))

;; Batch operations
(define-public (approve-multiple-chores (chore-ids (list 10 uint)))
  (fold approve-chore chore-ids (ok true)))

;; Read-only functions
(define-read-only (get-chore (chore-id uint))
  (ok (map-get? chores {chore-id: chore-id})))

(define-read-only (get-balance (user principal))
  (ok (ft-get-balance chore-rewards user)))

(define-read-only (is-paused)
  (ok (var-get contract-paused)))
