;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-ticket-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-used (err u103))
(define-constant err-not-for-sale (err u104))
(define-constant err-invalid-price (err u105))

;; Data vars
(define-data-var venue-name (string-ascii 256) "")
(define-data-var event-date (uint) u0)
(define-data-var max-price uint u0)

;; Data maps
(define-map tickets 
    uint 
    {owner: principal, 
     price: uint,
     is-used: bool,
     for-sale: bool})

(define-map ticket-metadata 
    uint 
    {seat: (string-ascii 10),  
     section: (string-ascii 10)})

;; Create new ticket - only owner
(define-public (create-ticket (ticket-id uint) (seat (string-ascii 10)) (section (string-ascii 10)) (price uint) (recipient principal))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set tickets ticket-id 
                {owner: recipient,
                 price: price,
                 is-used: false,
                 for-sale: false})
            (map-set ticket-metadata ticket-id
                {seat: seat,
                 section: section})
            (ok true))
        err-owner-only))

;; Transfer ticket
(define-public (transfer-ticket (ticket-id uint) (recipient principal))
    (let ((ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found)))
        (if (and 
            (is-eq tx-sender (get owner ticket))
            (not (get is-used ticket)))
            (begin
                (map-set tickets ticket-id 
                    {owner: recipient,
                     price: (get price ticket),
                     is-used: false,
                     for-sale: false})
                (ok true))
            err-unauthorized)))

;; Use ticket
(define-public (use-ticket (ticket-id uint))
    (let ((ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found)))
        (if (and
            (is-eq tx-sender (get owner ticket))
            (not (get is-used ticket)))
            (begin 
                (map-set tickets ticket-id
                    {owner: (get owner ticket),
                     price: (get price ticket),
                     is-used: true,
                     for-sale: false})
                (ok true))
            err-unauthorized)))

;; List ticket for sale
(define-public (list-for-sale (ticket-id uint) (sale-price uint))
    (let ((ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found)))
        (if (and
            (is-eq tx-sender (get owner ticket))
            (not (get is-used ticket))
            (<= sale-price (var-get max-price)))
            (begin
                (map-set tickets ticket-id
                    {owner: (get owner ticket),
                     price: sale-price,
                     is-used: false,
                     for-sale: true})
                (ok true))
            err-invalid-price)))

;; Read-only functions
(define-read-only (get-ticket-info (ticket-id uint))
    (map-get? tickets ticket-id))

(define-read-only (get-ticket-details (ticket-id uint))
    (map-get? ticket-metadata ticket-id))
