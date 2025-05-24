;; Service Provider Verification Contract
;; Validates and manages transportation operators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_PROVIDER_EXISTS (err u101))
(define-constant ERR_PROVIDER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Provider status types
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Data structures
(define-map providers
  { provider-id: uint }
  {
    name: (string-ascii 100),
    operator-type: (string-ascii 50),
    license-number: (string-ascii 50),
    status: uint,
    verification-date: uint,
    rating: uint
  }
)

(define-map provider-addresses
  { address: principal }
  { provider-id: uint }
)

(define-data-var next-provider-id uint u1)

;; Register a new service provider
(define-public (register-provider
  (name (string-ascii 100))
  (operator-type (string-ascii 50))
  (license-number (string-ascii 50)))
  (let ((provider-id (var-get next-provider-id)))
    (asserts! (is-none (map-get? provider-addresses { address: tx-sender })) ERR_PROVIDER_EXISTS)
    (map-set providers
      { provider-id: provider-id }
      {
        name: name,
        operator-type: operator-type,
        license-number: license-number,
        status: STATUS_PENDING,
        verification-date: u0,
        rating: u0
      }
    )
    (map-set provider-addresses { address: tx-sender } { provider-id: provider-id })
    (var-set next-provider-id (+ provider-id u1))
    (ok provider-id)
  )
)

;; Verify a service provider (admin only)
(define-public (verify-provider (provider-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data {
            status: STATUS_VERIFIED,
            verification-date: block-height
          })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

;; Update provider rating
(define-public (update-rating (provider-id uint) (new-rating uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-rating u100) ERR_INVALID_STATUS)
    (match (map-get? providers { provider-id: provider-id })
      provider-data
      (begin
        (map-set providers
          { provider-id: provider-id }
          (merge provider-data { rating: new-rating })
        )
        (ok true)
      )
      ERR_PROVIDER_NOT_FOUND
    )
  )
)

;; Get provider information
(define-read-only (get-provider (provider-id uint))
  (map-get? providers { provider-id: provider-id })
)

;; Check if provider is verified
(define-read-only (is-provider-verified (provider-id uint))
  (match (map-get? providers { provider-id: provider-id })
    provider-data
    (is-eq (get status provider-data) STATUS_VERIFIED)
    false
  )
)

;; Get provider ID by address
(define-read-only (get-provider-by-address (address principal))
  (map-get? provider-addresses { address: address })
)
