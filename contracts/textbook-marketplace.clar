;; Define constants for error handling
(define-constant err-not-owner (err u100))
(define-constant err-already-listed (err u101))
(define-constant err-not-listed (err u102))
(define-constant err-wrong-price (err u103))
(define-constant err-not-available (err u104))
(define-constant err-invalid-rating (err u105))

;; Define data variables
(define-data-var next-listing-id uint u0)
(define-data-var next-review-id uint u0)

;; Define data maps
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

;; Create a new textbook listing
(define-public (list-textbook (title (string-ascii 100)) (isbn (string-ascii 13)) (price uint) (rental-price uint) (rental-duration uint))
    (let
        ((listing-id (var-get next-listing-id)))
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
                renter: none
            }
        )
        (var-set next-listing-id (+ listing-id u1))
        (ok listing-id)
    )
)

;; Purchase a textbook
(define-public (purchase-textbook (listing-id uint))
    (let (
        (listing (unwrap! (map-get? textbooks { listing-id: listing-id }) (err err-not-listed)))
        (price (get price listing))
        (seller (get owner listing))
        (is-available (get is-available listing))
    )
        (asserts! is-available (err err-not-available))
        (try! (stx-transfer? price tx-sender seller))
        (map-set textbooks
            { listing-id: listing-id }
            (merge listing { is-available: false })
        )
        (ok true)
    )
)

;; Rent a textbook
(define-public (rent-textbook (listing-id uint))
    (let (
        (listing (unwrap! (map-get? textbooks { listing-id: listing-id }) (err err-not-listed)))
        (rental-price (get rental-price listing))
        (owner (get owner listing))
        (is-available (get is-available listing))
    )
        (asserts! is-available (err err-not-available))
        (try! (stx-transfer? rental-price tx-sender owner))
        (map-set textbooks
            { listing-id: listing-id }
            (merge listing { 
                is-available: false,
                is-rental: true,
                renter: (some tx-sender)
            })
        )
        (ok true)
    )
)

;; Return a rented textbook
(define-public (return-textbook (listing-id uint))
    (let (
        (listing (unwrap! (map-get? textbooks { listing-id: listing-id }) (err err-not-listed)))
        (renter (get renter listing))
    )
        (asserts! (is-eq (some tx-sender) renter) (err err-not-owner))
        (map-set textbooks
            { listing-id: listing-id }
            (merge listing {
                is-available: true,
                is-rental: false,
                renter: none
            })
        )
        (ok true)
    )
)

;; Add a review
(define-public (add-review (listing-id uint) (rating uint) (comment (string-ascii 200)))
    (let (
        (review-id (var-get next-review-id))
    )
        (asserts! (<= rating u5) (err err-invalid-rating))
        (map-insert reviews
            { review-id: review-id }
            {
                reviewer: tx-sender,
                listing-id: listing-id,
                rating: rating,
                comment: comment
            }
        )
        (var-set next-review-id (+ review-id u1))
        (ok review-id)
    )
)

;; Remove a textbook listing
(define-public (remove-listing (listing-id uint))
    (let (
        (listing (unwrap! (map-get? textbooks { listing-id: listing-id }) (err err-not-listed)))
    )
        (asserts! (is-eq tx-sender (get owner listing)) (err err-not-owner))
        (map-delete textbooks { listing-id: listing-id })
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-listing (listing-id uint))
    (map-get? textbooks { listing-id: listing-id })
)

(define-read-only (get-review (review-id uint))
    (map-get? reviews { review-id: review-id })
)

(define-read-only (get-current-listing-id)
    (ok (var-get next-listing-id))
)

(define-read-only (get-current-review-id)
    (ok (var-get next-review-id))
)
