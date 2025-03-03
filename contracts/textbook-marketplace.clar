;; Define constants for error handling
(define-constant err-not-owner (err u100))
(define-constant err-already-listed (err u101))
(define-constant err-not-listed (err u102))
(define-constant err-wrong-price (err u103))
(define-constant err-not-available (err u104))
(define-constant err-invalid-rating (err u105))
(define-constant err-rental-expired (err u106))
(define-constant err-invalid-rental-price (err u107))
(define-constant err-invalid-purchase-price (err u108))
(define-constant err-invalid-rental-duration (err u109))

;; Define events
(define-data-var next-listing-id uint u0)
(define-data-var next-review-id uint u0)

;; Define maps
(define-map textbooks
    { listing-id: uint }
    {
        owner: principal,
        title: (string-ascii 100),
        isbn: (string-ascii 13),
        price: uint,
        rental-price: uint,
        is-available: bool,
        is-rental: bool,
        rental-duration: uint,
        rental-start: (optional uint),
        renter: (optional principal)
    }
)

(define-map reviews
    { review-id: uint }
    {
        reviewer: principal,
        listing-id: uint,
        rating: uint,
        comment: (string-ascii 200)
    }
)

;; Enhanced event printing
(define-public (print-listing-event 
    (event-type (string-ascii 20)) 
    (listing-id uint)
    (price uint)
    (details (optional (string-ascii 50)))
)
    (print {
        event-type: event-type,
        listing-id: listing-id,
        price: price,
        details: details,
        sender: tx-sender
    })
    (ok true)
)

;; Create a new textbook listing
(define-public (list-textbook (title (string-ascii 100)) (isbn (string-ascii 13)) (price uint) (rental-price uint) (rental-duration uint))
    (let
        ((listing-id (var-get next-listing-id)))
        ;; Enhanced input validation
        (asserts! (> price u0) (err err-invalid-purchase-price))
        (asserts! (> rental-price u0) (err err-invalid-rental-price))
        (asserts! (>= price rental-price) (err err-invalid-rental-price))
        (asserts! (> rental-duration u0) (err err-invalid-rental-duration))
        
        (map-insert textbooks
            { listing-id: listing-id }
            {
                owner: tx-sender,
                title: title,
                isbn: isbn,
                price: price,
                rental-price: rental-price,
                is-available: true,
                is-rental: false,
                rental-duration: rental-duration,
                rental-start: none,
                renter: none
            }
        )
        (var-set next-listing-id (+ listing-id u1))
        (try! (print-listing-event "listed" listing-id price none))
        (ok listing-id)
    )
)

;; [Previous functions unchanged...]

;; Return a rented textbook - Fixed logic
(define-public (return-textbook (listing-id uint))
    (let (
        (listing (unwrap! (map-get? textbooks { listing-id: listing-id }) (err err-not-listed)))
        (renter (get renter listing))
        (rental-start (get rental-start listing))
        (rental-duration (get rental-duration listing))
    )
        (asserts! (is-eq (some tx-sender) renter) (err err-not-owner))
        ;; Fixed rental duration check
        (asserts! (<= (- block-height (unwrap! rental-start (err err-not-listed))) rental-duration) 
            (err err-rental-expired))
        
        (map-set textbooks
            { listing-id: listing-id }
            (merge listing {
                is-available: true,
                is-rental: false,
                rental-start: none,
                renter: none
            })
        )
        (try! (print-listing-event "returned" listing-id u0 none))
        (ok true)
    )
)

;; [Remaining functions unchanged...]
