;; Tenant Improvement Manager Contract
;; Manages construction budgets, contractor payments, and improvement cost reconciliation

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-allowance (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-invalid-status (err u106))
(define-constant err-already-approved (err u107))
(define-constant err-not-approved (err u108))

;; Data Variables
(define-data-var project-nonce uint u0)
(define-data-var invoice-nonce uint u0)

;; Data Maps
(define-map improvement-projects
    uint
    {
        tenant: principal,
        property-manager: principal,
        total-allowance: uint,
        spent-amount: uint,
        status: (string-ascii 20),
        created-at: uint
    }
)

(define-map contractor-invoices
    uint
    {
        project-id: uint,
        contractor: principal,
        amount: uint,
        description: (string-utf8 500),
        category: (string-ascii 50),
        status: (string-ascii 20),
        tenant-approved: bool,
        manager-approved: bool,
        submitted-at: uint
    }
)

(define-map project-budgets
    { project-id: uint, category: (string-ascii 50) }
    {
        allocated-amount: uint,
        spent-amount: uint
    }
)

(define-map payments
    uint
    {
        invoice-id: uint,
        amount: uint,
        paid-to: principal,
        paid-at: uint,
        payment-method: (string-ascii 30)
    }
)

(define-map improvement-documentation
    { project-id: uint, doc-id: uint }
    {
        description: (string-utf8 500),
        completed-at: uint,
        final-cost: uint,
        documented-by: principal
    }
)

;; Authorization Functions
(define-private (is-project-manager (project-id uint))
    (let ((project (unwrap! (map-get? improvement-projects project-id) false)))
        (is-eq tx-sender (get property-manager project))
    )
)

(define-private (is-project-tenant (project-id uint))
    (let ((project (unwrap! (map-get? improvement-projects project-id) false)))
        (is-eq tx-sender (get tenant project))
    )
)

;; Read-only Functions
(define-read-only (get-project-details (project-id uint))
    (ok (unwrap! (map-get? improvement-projects project-id) err-not-found))
)

(define-read-only (get-invoice-details (invoice-id uint))
    (ok (unwrap! (map-get? contractor-invoices invoice-id) err-not-found))
)

(define-read-only (get-remaining-allowance (project-id uint))
    (let ((project (unwrap! (map-get? improvement-projects project-id) err-not-found)))
        (ok (- (get total-allowance project) (get spent-amount project)))
    )
)

(define-read-only (get-budget-for-category (project-id uint) (category (string-ascii 50)))
    (ok (unwrap! (map-get? project-budgets { project-id: project-id, category: category }) err-not-found))
)

(define-read-only (get-payment-details (payment-id uint))
    (ok (unwrap! (map-get? payments payment-id) err-not-found))
)

(define-read-only (calculate-budget-utilization (project-id uint))
    (let ((project (unwrap! (map-get? improvement-projects project-id) err-not-found)))
        (let ((total (get total-allowance project))
              (spent (get spent-amount project)))
            (ok (if (> total u0)
                (* (/ (* spent u10000) total) u100)
                u0
            ))
        )
    )
)

;; Public Functions
(define-public (create-improvement-project (tenant principal) (total-allowance uint))
    (let ((project-id (+ (var-get project-nonce) u1)))
        (asserts! (> total-allowance u0) err-invalid-amount)
        (map-set improvement-projects project-id {
            tenant: tenant,
            property-manager: tx-sender,
            total-allowance: total-allowance,
            spent-amount: u0,
            status: "active",
            created-at: block-height
        })
        (var-set project-nonce project-id)
        (ok project-id)
    )
)

(define-public (allocate-budget-category (project-id uint) (category (string-ascii 50)) (amount uint))
    (begin
        (asserts! (is-project-manager project-id) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        (match (map-get? project-budgets { project-id: project-id, category: category })
            existing-budget err-already-exists
            (ok (map-set project-budgets 
                { project-id: project-id, category: category }
                { allocated-amount: amount, spent-amount: u0 }
            ))
        )
    )
)

(define-public (submit-contractor-invoice 
    (project-id uint) 
    (amount uint) 
    (description (string-utf8 500)) 
    (category (string-ascii 50)))
    (let ((invoice-id (+ (var-get invoice-nonce) u1))
          (project (unwrap! (map-get? improvement-projects project-id) err-not-found)))
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (is-eq (get status project) "active") err-invalid-status)
        (map-set contractor-invoices invoice-id {
            project-id: project-id,
            contractor: tx-sender,
            amount: amount,
            description: description,
            category: category,
            status: "pending",
            tenant-approved: false,
            manager-approved: false,
            submitted-at: block-height
        })
        (var-set invoice-nonce invoice-id)
        (ok invoice-id)
    )
)

(define-public (approve-invoice-by-tenant (invoice-id uint))
    (let ((invoice (unwrap! (map-get? contractor-invoices invoice-id) err-not-found)))
        (asserts! (is-project-tenant (get project-id invoice)) err-unauthorized)
        (asserts! (is-eq (get status invoice) "pending") err-invalid-status)
        (asserts! (not (get tenant-approved invoice)) err-already-approved)
        (map-set contractor-invoices invoice-id (merge invoice { tenant-approved: true }))
        (ok true)
    )
)

(define-public (approve-invoice-by-manager (invoice-id uint))
    (let ((invoice (unwrap! (map-get? contractor-invoices invoice-id) err-not-found)))
        (asserts! (is-project-manager (get project-id invoice)) err-unauthorized)
        (asserts! (is-eq (get status invoice) "pending") err-invalid-status)
        (asserts! (not (get manager-approved invoice)) err-already-approved)
        (map-set contractor-invoices invoice-id (merge invoice { manager-approved: true }))
        (ok true)
    )
)

(define-public (process-payment (invoice-id uint))
    (let ((invoice (unwrap! (map-get? contractor-invoices invoice-id) err-not-found))
          (project (unwrap! (map-get? improvement-projects (get project-id invoice)) err-not-found)))
        (asserts! (is-project-manager (get project-id invoice)) err-unauthorized)
        (asserts! (get tenant-approved invoice) err-not-approved)
        (asserts! (get manager-approved invoice) err-not-approved)
        (asserts! (is-eq (get status invoice) "pending") err-invalid-status)
        (asserts! (>= (- (get total-allowance project) (get spent-amount project)) (get amount invoice)) 
            err-insufficient-allowance)
        
        ;; Update project spent amount
        (map-set improvement-projects (get project-id invoice)
            (merge project { spent-amount: (+ (get spent-amount project) (get amount invoice)) })
        )
        
        ;; Update budget category spent amount
        (match (map-get? project-budgets { project-id: (get project-id invoice), category: (get category invoice) })
            budget (map-set project-budgets 
                { project-id: (get project-id invoice), category: (get category invoice) }
                (merge budget { spent-amount: (+ (get spent-amount budget) (get amount invoice)) })
            )
            true
        )
        
        ;; Update invoice status
        (map-set contractor-invoices invoice-id (merge invoice { status: "paid" }))
        
        ;; Record payment
        (map-set payments invoice-id {
            invoice-id: invoice-id,
            amount: (get amount invoice),
            paid-to: (get contractor invoice),
            paid-at: block-height,
            payment-method: "allowance"
        })
        
        (ok true)
    )
)

(define-public (document-improvement 
    (project-id uint) 
    (doc-id uint)
    (description (string-utf8 500)) 
    (final-cost uint))
    (begin
        (asserts! (or (is-project-manager project-id) (is-project-tenant project-id)) err-unauthorized)
        (asserts! (> final-cost u0) err-invalid-amount)
        (map-set improvement-documentation
            { project-id: project-id, doc-id: doc-id }
            {
                description: description,
                completed-at: block-height,
                final-cost: final-cost,
                documented-by: tx-sender
            }
        )
        (ok true)
    )
)

(define-public (close-project (project-id uint))
    (let ((project (unwrap! (map-get? improvement-projects project-id) err-not-found)))
        (asserts! (is-project-manager project-id) err-unauthorized)
        (asserts! (is-eq (get status project) "active") err-invalid-status)
        (map-set improvement-projects project-id (merge project { status: "closed" }))
        (ok true)
    )
)

(define-public (reconcile-project-costs (project-id uint))
    (let ((project (unwrap! (map-get? improvement-projects project-id) err-not-found)))
        (asserts! (is-project-manager project-id) err-unauthorized)
        (ok {
            total-allowance: (get total-allowance project),
            total-spent: (get spent-amount project),
            remaining: (- (get total-allowance project) (get spent-amount project)),
            utilization-rate: (if (> (get total-allowance project) u0)
                (/ (* (get spent-amount project) u100) (get total-allowance project))
                u0
            )
        })
    )
)
