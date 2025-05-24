;; Ticketing Integration Contract
;; Manages unified payment system for multimodal transportation

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INSUFFICIENT_BALANCE (err u301))
(define-constant ERR_TICKET_NOT_FOUND (err u302))
(define-constant ERR_TICKET_EXPIRED (err u303))
(define-constant ERR_INVALID_AMOUNT (err u304))

;; Ticket status types
(define-constant TICKET_ACTIVE u0)
(define-constant TICKET_USED u1)
(define-constant TICKET_EXPIRED u2)
(define-constant TICKET_REFUNDED u3)

;; Data structures
(define-map user-balances
  { user: principal }
  { balance: uint }
)

(define-map tickets
  { ticket-id: uint }
  {
    user: principal,
    journey-id: uint,
    provider-id: uint,
    amount: uint,
    valid-from: uint,
    valid-until: uint,
    status: uint,
    created-at: uint
  }
)

(define-map journey-tickets
  { journey-id: uint, segment-index: uint }
  { ticket-id: uint }
)

(define-data-var next-ticket-id uint u1)

;; Add funds to user balance
(define-public (add-funds (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (let ((current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender })))))
      (map-set user-balances
        { user: tx-sender }
        { balance: (+ current-balance amount) }
      )
      (ok true)
    )
  )
)

;; Purchase a ticket
(define-public (purchase-ticket
  (journey-id uint)
  (provider-id uint)
  (amount uint)
  (valid-from uint)
  (valid-until uint))
  (let (
    (ticket-id (var-get next-ticket-id))
    (current-balance (default-to u0 (get balance (map-get? user-balances { user: tx-sender }))))
  )
    (asserts! (>= current-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)

    ;; Deduct amount from user balance
    (map-set user-balances
      { user: tx-sender }
      { balance: (- current-balance amount) }
    )

    ;; Create ticket
    (map-set tickets
      { ticket-id: ticket-id }
      {
        user: tx-sender,
        journey-id: journey-id,
        provider-id: provider-id,
        amount: amount,
        valid-from: valid-from,
        valid-until: valid-until,
        status: TICKET_ACTIVE,
        created-at: block-height
      }
    )

    (var-set next-ticket-id (+ ticket-id u1))
    (ok ticket-id)
  )
)

;; Use a ticket
(define-public (use-ticket (ticket-id uint))
  (match (map-get? tickets { ticket-id: ticket-id })
    ticket-data
    (begin
      (asserts! (is-eq (get user ticket-data) tx-sender) ERR_UNAUTHORIZED)
      (asserts! (is-eq (get status ticket-data) TICKET_ACTIVE) ERR_TICKET_EXPIRED)
      (asserts! (>= block-height (get valid-from ticket-data)) ERR_TICKET_EXPIRED)
      (asserts! (<= block-height (get valid-until ticket-data)) ERR_TICKET_EXPIRED)

      (map-set tickets
        { ticket-id: ticket-id }
        (merge ticket-data { status: TICKET_USED })
      )
      (ok true)
    )
    ERR_TICKET_NOT_FOUND
  )
)

;; Refund a ticket (admin only)
(define-public (refund-ticket (ticket-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? tickets { ticket-id: ticket-id })
      ticket-data
      (let (
        (user (get user ticket-data))
        (amount (get amount ticket-data))
        (current-balance (default-to u0 (get balance (map-get? user-balances { user: user }))))
      )
        (map-set user-balances
          { user: user }
          { balance: (+ current-balance amount) }
        )
        (map-set tickets
          { ticket-id: ticket-id }
          (merge ticket-data { status: TICKET_REFUNDED })
        )
        (ok true)
      )
      ERR_TICKET_NOT_FOUND
    )
  )
)

;; Get user balance
(define-read-only (get-balance (user principal))
  (default-to u0 (get balance (map-get? user-balances { user: user })))
)

;; Get ticket information
(define-read-only (get-ticket (ticket-id uint))
  (map-get? tickets { ticket-id: ticket-id })
)

;; Check if ticket is valid
(define-read-only (is-ticket-valid (ticket-id uint))
  (match (map-get? tickets { ticket-id: ticket-id })
    ticket-data
    (and
      (is-eq (get status ticket-data) TICKET_ACTIVE)
      (>= block-height (get valid-from ticket-data))
      (<= block-height (get valid-until ticket-data))
    )
    false
  )
)

;; Calculate total spent by user
(define-read-only (get-user-total-spent (user principal))
  ;; This would require iteration in a real implementation
  ;; For now, return a placeholder
  u0
)
