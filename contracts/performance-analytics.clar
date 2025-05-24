;; Performance Analytics Contract
;; Tracks multimodal efficiency and system performance metrics

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_INVALID_METRIC (err u501))
(define-constant ERR_DATA_NOT_FOUND (err u502))

;; Metric types
(define-constant METRIC_ON_TIME_PERFORMANCE u0)
(define-constant METRIC_TRANSFER_EFFICIENCY u1)
(define-constant METRIC_USER_SATISFACTION u2)
(define-constant METRIC_COST_EFFICIENCY u3)
(define-constant METRIC_CARBON_FOOTPRINT u4)

;; Data structures
(define-map provider-metrics
  { provider-id: uint, metric-type: uint, period: uint }
  {
    value: uint,
    sample-size: uint,
    last-updated: uint,
    trend: int
  }
)

(define-map system-metrics
  { metric-type: uint, period: uint }
  {
    total-journeys: uint,
    successful-journeys: uint,
    average-rating: uint,
    total-revenue: uint,
    carbon-saved: uint,
    last-calculated: uint
  }
)

(define-map journey-performance
  { journey-id: uint }
  {
    planned-duration: uint,
    actual-duration: uint,
    delays: uint,
    transfers-completed: uint,
    user-rating: uint,
    cost-efficiency: uint,
    carbon-footprint: uint
  }
)

(define-map daily-analytics
  { date: uint }
  {
    total-users: uint,
    total-journeys: uint,
    revenue: uint,
    average-satisfaction: uint,
    system-uptime: uint
  }
)

;; Record journey performance
(define-public (record-journey-performance
  (journey-id uint)
  (planned-duration uint)
  (actual-duration uint)
  (delays uint)
  (transfers-completed uint)
  (user-rating uint)
  (cost-efficiency uint)
  (carbon-footprint uint))
  (begin
    (map-set journey-performance
      { journey-id: journey-id }
      {
        planned-duration: planned-duration,
        actual-duration: actual-duration,
        delays: delays,
        transfers-completed: transfers-completed,
        user-rating: user-rating,
        cost-efficiency: cost-efficiency,
        carbon-footprint: carbon-footprint
      }
    )
    (ok true)
  )
)

;; Update provider metrics
(define-public (update-provider-metric
  (provider-id uint)
  (metric-type uint)
  (period uint)
  (value uint)
  (sample-size uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (let ((current-metric (map-get? provider-metrics { provider-id: provider-id, metric-type: metric-type, period: period })))
      (match current-metric
        existing-data
        (let ((trend (calculate-trend value (get value existing-data))))
          (map-set provider-metrics
            { provider-id: provider-id, metric-type: metric-type, period: period }
            {
              value: value,
              sample-size: sample-size,
              last-updated: block-height,
              trend: trend
            }
          )
        )
        (map-set provider-metrics
          { provider-id: provider-id, metric-type: metric-type, period: period }
          {
            value: value,
            sample-size: sample-size,
            last-updated: block-height,
            trend: 0
          }
        )
      )
      (ok true)
    )
  )
)

;; Update system-wide metrics
(define-public (update-system-metrics
  (metric-type uint)
  (period uint)
  (total-journeys uint)
  (successful-journeys uint)
  (average-rating uint)
  (total-revenue uint)
  (carbon-saved uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set system-metrics
      { metric-type: metric-type, period: period }
      {
        total-journeys: total-journeys,
        successful-journeys: successful-journeys,
        average-rating: average-rating,
        total-revenue: total-revenue,
        carbon-saved: carbon-saved,
        last-calculated: block-height
      }
    )
    (ok true)
  )
)

;; Calculate trend (simplified)
(define-private (calculate-trend (new-value uint) (old-value uint))
  (if (> new-value old-value)
    1
    (if (< new-value old-value)
      -1
      0
    )
  )
)

;; Get provider performance metrics
(define-read-only (get-provider-metrics (provider-id uint) (metric-type uint) (period uint))
  (map-get? provider-metrics { provider-id: provider-id, metric-type: metric-type, period: period })
)

;; Get system metrics
(define-read-only (get-system-metrics (metric-type uint) (period uint))
  (map-get? system-metrics { metric-type: metric-type, period: period })
)

;; Get journey performance
(define-read-only (get-journey-performance (journey-id uint))
  (map-get? journey-performance { journey-id: journey-id })
)

;; Calculate on-time performance rate
(define-read-only (calculate-on-time-rate (provider-id uint) (period uint))
  (match (map-get? provider-metrics { provider-id: provider-id, metric-type: METRIC_ON_TIME_PERFORMANCE, period: period })
    metric-data
    (some (get value metric-data))
    none
  )
)

;; Calculate system efficiency score
(define-read-only (calculate-efficiency-score (period uint))
  (match (map-get? system-metrics { metric-type: METRIC_TRANSFER_EFFICIENCY, period: period })
    metric-data
    (let (
      (success-rate (/ (* (get successful-journeys metric-data) u100) (get total-journeys metric-data)))
      (satisfaction (get average-rating metric-data))
    )
      (some (/ (+ success-rate satisfaction) u2))
    )
    none
  )
)

;; Get carbon footprint reduction
(define-read-only (get-carbon-reduction (period uint))
  (match (map-get? system-metrics { metric-type: METRIC_CARBON_FOOTPRINT, period: period })
    metric-data
    (some (get carbon-saved metric-data))
    none
  )
)

;; Record daily analytics
(define-public (record-daily-analytics
  (date uint)
  (total-users uint)
  (total-journeys uint)
  (revenue uint)
  (average-satisfaction uint)
  (system-uptime uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set daily-analytics
      { date: date }
      {
        total-users: total-users,
        total-journeys: total-journeys,
        revenue: revenue,
        average-satisfaction: average-satisfaction,
        system-uptime: system-uptime
      }
    )
    (ok true)
  )
)
