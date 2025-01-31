;; Define constants for error handling
(define-constant err-not-owner (err u100))
(define-constant err-already-listed (err u101))
(define-constant err-not-listed (err u102))
(define-constant err-wrong-price (err u103))

;; Define data variables
(define-data-var next-listing-id uint u0)

;; Define data maps
(define-map textbooks
    { listing-id: uint }
    {
        owner: principal,
        title: (string-ascii 100),
        isbn: (string-ascii 13),
        price: uint,
        is-available: bool
    }
)

;; Create a new textbook listing
(define-public (list-textbook (title (string-ascii 100)) (isbn (string-ascii 13)) (price uint))
    (let
        ((listing-id (var-get next-listing-id)))
        (map-insert textbooks
            { listing-id: listing-id }
            {
                owner: tx-sender,
                title: title,
                isbn: isbn,
                price: price,
                is-available: true
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

(define-read-only (get-current-listing-id)
    (ok (var-get next-listing-id))
)
