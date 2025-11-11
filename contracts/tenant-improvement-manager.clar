;; Tenant Improvement Manager Smart Contract
;; Track construction budgets, approve contractor invoices, coordinate payments, reconcile allowances, and document improvements

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-lease-not-found (err u102))
(define-constant err-budget-not-found (err u103))
(define-constant err-invoice-not-found (err u104))
(define-constant err-insufficient-allowance (err u105))
(define-constant err-already-approved (err u106))
(define-constant err-not-approved (err u107))
(define-constant err-already-paid (err u108))
(define-constant err-invalid-amount (err u109))

;; Data Variables
(define-data-var property-manager-name (string-ascii 100) "")
(define-data-var system-initialized bool false)
(define-data-var total-leases uint u0)
(define-data-var total-budgets uint u0)
(define-data-var total-invoices uint u0)
(define-data-var total-improvements uint u0)

;; Data Maps
(define-map property-managers principal bool)
(define-map landlords principal bool)
(define-map tenants principal bool)

(define-map leases
    { lease-id: uint }
    {
        property-address: (string-ascii 200),
        landlord: principal,
        tenant: principal,
        lease-start-date: uint,
        improvement-deadline: uint,
        total-allowance: uint,
        allowance-used: uint,
        allowance-remaining: uint,
        lease-status: (string-ascii 20),
        created-at: uint
    }
)

(define-map lease-by-tenant principal uint)

(define-map improvement-budgets
    { budget-id: uint }
    {
        lease-id: uint,
        budget-category: (string-ascii 50),
        budgeted-amount: uint,
        actual-spent: uint,
        variance: int,
        budget-status: (string-ascii 20),
        created-by: principal,
        created-at: uint
    }
)

(define-map contractor-invoices
    { invoice-id: uint }
    {
        lease-id: uint,
        budget-id: uint,
        contractor-name: (string-ascii 100),
        contractor-address: principal,
        invoice-amount: uint,
        work-description: (string-ascii 200),
        invoice-date: uint,
        tenant-approved: bool,
        landlord-approved: bool,
        payment-processed: bool,
        payment-date: uint,
        submitted-by: principal
    }
)

(define-map improvements
    { improvement-id: uint }
    {
        lease-id: uint,
        improvement-type: (string-ascii 50),
        description: (string-ascii 200),
        contractor: (string-ascii 100),
        start-date: uint,
        completion-date: uint,
        final-cost: uint,
        status: (string-ascii 20),
        certificate-issued: bool
    }
)

(define-map payment-history
    { payment-id: uint }
    {
        invoice-id: uint,
        lease-id: uint,
        amount: uint,
        paid-to: principal,
        paid-date: uint,
        paid-by: principal
    }
)

;; Private Functions
(define-private (is-property-manager (user principal))
    (default-to false (map-get? property-managers user))
)

(define-private (is-landlord (user principal))
    (default-to false (map-get? landlords user))
)

(define-private (is-tenant (user principal))
    (default-to false (map-get? tenants user))
)

(define-private (calculate-variance (budgeted uint) (actual uint))
    (if (>= budgeted actual)
        (to-int (- budgeted actual))
        (to-int (- u0 (- actual budgeted)))
    )
)

;; Public Functions - Administrative
(define-public (initialize (manager-name (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (var-get system-initialized)) err-already-approved)
        (var-set property-manager-name manager-name)
        (var-set system-initialized true)
        (map-set property-managers contract-owner true)
        (ok true)
    )
)

(define-public (register-property-manager (manager-address principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set property-managers manager-address true))
    )
)

(define-public (register-landlord (landlord-address principal))
    (begin
        (asserts! (is-property-manager tx-sender) err-not-authorized)
        (ok (map-set landlords landlord-address true))
    )
)

(define-public (register-tenant (tenant-address principal))
    (begin
        (asserts! (is-property-manager tx-sender) err-not-authorized)
        (ok (map-set tenants tenant-address true))
    )
)

;; Public Functions - Lease Management
(define-public (create-lease 
    (property-address (string-ascii 200))
    (landlord-address principal)
    (tenant-address principal)
    (lease-start-date uint)
    (improvement-deadline uint)
    (total-allowance uint)
)
    (let
        (
            (new-lease-id (+ (var-get total-leases) u1))
        )
        (asserts! (is-property-manager tx-sender) err-not-authorized)
        (asserts! (> total-allowance u0) err-invalid-amount)
        
        (map-set leases
            { lease-id: new-lease-id }
            {
                property-address: property-address,
                landlord: landlord-address,
                tenant: tenant-address,
                lease-start-date: lease-start-date,
                improvement-deadline: improvement-deadline,
                total-allowance: total-allowance,
                allowance-used: u0,
                allowance-remaining: total-allowance,
                lease-status: "active",
                created-at: block-height
            }
        )
        (map-set lease-by-tenant tenant-address new-lease-id)
        (map-set landlords landlord-address true)
        (map-set tenants tenant-address true)
        (var-set total-leases new-lease-id)
        (ok new-lease-id)
    )
)

(define-public (update-lease-status (lease-id uint) (new-status (string-ascii 20)))
    (let
        (
            (lease-data (unwrap! (map-get? leases { lease-id: lease-id }) err-lease-not-found))
        )
        (asserts! (is-property-manager tx-sender) err-not-authorized)
        
        (ok (map-set leases
            { lease-id: lease-id }
            (merge lease-data { lease-status: new-status })
        ))
    )
)

;; Public Functions - Budget Management
(define-public (create-improvement-budget 
    (lease-id uint)
    (budget-category (string-ascii 50))
    (budgeted-amount uint)
)
    (let
        (
            (new-budget-id (+ (var-get total-budgets) u1))
            (lease-data (unwrap! (map-get? leases { lease-id: lease-id }) err-lease-not-found))
        )
        (asserts! (or (is-property-manager tx-sender) (is-eq tx-sender (get tenant lease-data))) err-not-authorized)
        (asserts! (> budgeted-amount u0) err-invalid-amount)
        
        (map-set improvement-budgets
            { budget-id: new-budget-id }
            {
                lease-id: lease-id,
                budget-category: budget-category,
                budgeted-amount: budgeted-amount,
                actual-spent: u0,
                variance: (to-int budgeted-amount),
                budget-status: "active",
                created-by: tx-sender,
                created-at: block-height
            }
        )
        (var-set total-budgets new-budget-id)
        (ok new-budget-id)
    )
)

(define-public (update-budget-spending (budget-id uint) (additional-spent uint))
    (let
        (
            (budget-data (unwrap! (map-get? improvement-budgets { budget-id: budget-id }) err-budget-not-found))
            (new-actual-spent (+ (get actual-spent budget-data) additional-spent))
        )
        (asserts! (is-property-manager tx-sender) err-not-authorized)
        
        (ok (map-set improvement-budgets
            { budget-id: budget-id }
            (merge budget-data {
                actual-spent: new-actual-spent,
                variance: (calculate-variance (get budgeted-amount budget-data) new-actual-spent)
            })
        ))
    )
)

;; Public Functions - Invoice Management
(define-public (submit-contractor-invoice
    (lease-id uint)
    (budget-id uint)
    (contractor-name (string-ascii 100))
    (contractor-address principal)
    (invoice-amount uint)
    (work-description (string-ascii 200))
)
    (let
        (
            (new-invoice-id (+ (var-get total-invoices) u1))
            (lease-data (unwrap! (map-get? leases { lease-id: lease-id }) err-lease-not-found))
            (budget-data (unwrap! (map-get? improvement-budgets { budget-id: budget-id }) err-budget-not-found))
        )
        (asserts! (or (is-property-manager tx-sender) (is-eq tx-sender (get tenant lease-data))) err-not-authorized)
        (asserts! (> invoice-amount u0) err-invalid-amount)
        (asserts! (<= invoice-amount (get allowance-remaining lease-data)) err-insufficient-allowance)
        
        (map-set contractor-invoices
            { invoice-id: new-invoice-id }
            {
                lease-id: lease-id,
                budget-id: budget-id,
                contractor-name: contractor-name,
                contractor-address: contractor-address,
                invoice-amount: invoice-amount,
                work-description: work-description,
                invoice-date: block-height,
                tenant-approved: false,
                landlord-approved: false,
                payment-processed: false,
                payment-date: u0,
                submitted-by: tx-sender
            }
        )
        (var-set total-invoices new-invoice-id)
        (ok new-invoice-id)
    )
)

(define-public (approve-invoice-by-tenant (invoice-id uint))
    (let
        (
            (invoice-data (unwrap! (map-get? contractor-invoices { invoice-id: invoice-id }) err-invoice-not-found))
            (lease-data (unwrap! (map-get? leases { lease-id: (get lease-id invoice-data) }) err-lease-not-found))
        )
        (asserts! (is-eq tx-sender (get tenant lease-data)) err-not-authorized)
        (asserts! (not (get tenant-approved invoice-data)) err-already-approved)
        
        (ok (map-set contractor-invoices
            { invoice-id: invoice-id }
            (merge invoice-data { tenant-approved: true })
        ))
    )
)

(define-public (approve-invoice-by-landlord (invoice-id uint))
    (let
        (
            (invoice-data (unwrap! (map-get? contractor-invoices { invoice-id: invoice-id }) err-invoice-not-found))
            (lease-data (unwrap! (map-get? leases { lease-id: (get lease-id invoice-data) }) err-lease-not-found))
        )
        (asserts! (is-eq tx-sender (get landlord lease-data)) err-not-authorized)
        (asserts! (not (get landlord-approved invoice-data)) err-already-approved)
        
        (ok (map-set contractor-invoices
            { invoice-id: invoice-id }
            (merge invoice-data { landlord-approved: true })
        ))
    )
)

(define-public (process-payment (invoice-id uint))
    (let
        (
            (invoice-data (unwrap! (map-get? contractor-invoices { invoice-id: invoice-id }) err-invoice-not-found))
            (lease-data (unwrap! (map-get? leases { lease-id: (get lease-id invoice-data) }) err-lease-not-found))
            (payment-id (+ (var-get total-invoices) (var-get total-leases)))
        )
        (asserts! (is-property-manager tx-sender) err-not-authorized)
        (asserts! (get tenant-approved invoice-data) err-not-approved)
        (asserts! (get landlord-approved invoice-data) err-not-approved)
        (asserts! (not (get payment-processed invoice-data)) err-already-paid)
        
        (map-set contractor-invoices
            { invoice-id: invoice-id }
            (merge invoice-data {
                payment-processed: true,
                payment-date: block-height
            })
        )
        
        (map-set payment-history
            { payment-id: payment-id }
            {
                invoice-id: invoice-id,
                lease-id: (get lease-id invoice-data),
                amount: (get invoice-amount invoice-data),
                paid-to: (get contractor-address invoice-data),
                paid-date: block-height,
                paid-by: tx-sender
            }
        )
        
        (map-set leases
            { lease-id: (get lease-id invoice-data) }
            (merge lease-data {
                allowance-used: (+ (get allowance-used lease-data) (get invoice-amount invoice-data)),
                allowance-remaining: (- (get allowance-remaining lease-data) (get invoice-amount invoice-data))
            })
        )
        
        (try! (update-budget-spending (get budget-id invoice-data) (get invoice-amount invoice-data)))
        (ok true)
    )
)

;; Public Functions - Improvement Documentation
(define-public (record-improvement
    (lease-id uint)
    (improvement-type (string-ascii 50))
    (description (string-ascii 200))
    (contractor (string-ascii 100))
    (start-date uint)
    (final-cost uint)
)
    (let
        (
            (new-improvement-id (+ (var-get total-improvements) u1))
            (lease-data (unwrap! (map-get? leases { lease-id: lease-id }) err-lease-not-found))
        )
        (asserts! (or (is-property-manager tx-sender) (is-eq tx-sender (get tenant lease-data))) err-not-authorized)
        
        (map-set improvements
            { improvement-id: new-improvement-id }
            {
                lease-id: lease-id,
                improvement-type: improvement-type,
                description: description,
                contractor: contractor,
                start-date: start-date,
                completion-date: u0,
                final-cost: final-cost,
                status: "in-progress",
                certificate-issued: false
            }
        )
        (var-set total-improvements new-improvement-id)
        (ok new-improvement-id)
    )
)

(define-public (complete-improvement (improvement-id uint))
    (let
        (
            (improvement-data (unwrap! (map-get? improvements { improvement-id: improvement-id }) err-budget-not-found))
        )
        (asserts! (is-property-manager tx-sender) err-not-authorized)
        
        (ok (map-set improvements
            { improvement-id: improvement-id }
            (merge improvement-data {
                completion-date: block-height,
                status: "completed",
                certificate-issued: true
            })
        ))
    )
)

;; Read-Only Functions
(define-read-only (get-lease-info (lease-id uint))
    (ok (map-get? leases { lease-id: lease-id }))
)

(define-read-only (get-allowance-balance (lease-id uint))
    (ok (get allowance-remaining (unwrap! (map-get? leases { lease-id: lease-id }) err-lease-not-found)))
)

(define-read-only (get-budget-info (budget-id uint))
    (ok (map-get? improvement-budgets { budget-id: budget-id }))
)

(define-read-only (get-budget-utilization (budget-id uint))
    (let
        (
            (budget-data (unwrap! (map-get? improvement-budgets { budget-id: budget-id }) err-budget-not-found))
        )
        (ok (/ (* (get actual-spent budget-data) u100) (get budgeted-amount budget-data)))
    )
)

(define-read-only (get-invoice-info (invoice-id uint))
    (ok (map-get? contractor-invoices { invoice-id: invoice-id }))
)

(define-read-only (get-invoice-status (invoice-id uint))
    (let
        (
            (invoice-data (unwrap! (map-get? contractor-invoices { invoice-id: invoice-id }) err-invoice-not-found))
        )
        (ok {
            tenant-approved: (get tenant-approved invoice-data),
            landlord-approved: (get landlord-approved invoice-data),
            payment-processed: (get payment-processed invoice-data)
        })
    )
)

(define-read-only (get-improvement-info (improvement-id uint))
    (ok (map-get? improvements { improvement-id: improvement-id }))
)

(define-read-only (get-system-statistics)
    (ok {
        total-leases: (var-get total-leases),
        total-budgets: (var-get total-budgets),
        total-invoices: (var-get total-invoices),
        total-improvements: (var-get total-improvements)
    })
)

(define-read-only (is-system-initialized)
    (ok (var-get system-initialized))
)
