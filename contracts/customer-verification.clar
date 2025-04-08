;; Customer Verification Contract
;; This contract validates policyholder information

;; Define data variables
(define-data-var admin principal tx-sender)
(define-map customers
  { customer-id: (string-utf8 36) }
  {
    principal: principal,
    name: (string-utf8 100),
    email: (string-utf8 100),
    verified: bool,
    verification-date: uint
  }
)

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ALREADY_VERIFIED u2)
(define-constant ERR_CUSTOMER_NOT_FOUND u3)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Add a new customer
(define-public (add-customer (customer-id (string-utf8 36)) (name (string-utf8 100)) (email (string-utf8 100)))
  (let ((customer-principal tx-sender))
    (ok (map-insert customers
      { customer-id: customer-id }
      {
        principal: customer-principal,
        name: name,
        email: email,
        verified: false,
        verification-date: u0
      }
    ))
  )
)

;; Verify a customer (admin only)
(define-public (verify-customer (customer-id (string-utf8 36)))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (match (map-get? customers { customer-id: customer-id })
      customer
        (if (get verified customer)
          (err ERR_ALREADY_VERIFIED)
          (ok (map-set customers
            { customer-id: customer-id }
            {
              principal: (get principal customer),
              name: (get name customer),
              email: (get email customer),
              verified: true,
              verification-date: block-height
            }
          ))
        )
      (err ERR_CUSTOMER_NOT_FOUND)
    )
  )
)

;; Get customer information
(define-read-only (get-customer (customer-id (string-utf8 36)))
  (map-get? customers { customer-id: customer-id })
)

;; Check if a customer is verified
(define-read-only (is-customer-verified (customer-id (string-utf8 36)))
  (match (map-get? customers { customer-id: customer-id })
    customer (get verified customer)
    false
  )
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR_UNAUTHORIZED))
    (ok (var-set admin new-admin))
  )
)
