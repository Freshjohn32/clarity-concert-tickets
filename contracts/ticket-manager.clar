;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-ticket-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-used (err u103))
(define-constant err-not-for-sale (err u104))
(define-constant err-invalid-price (err u105))
(define-constant err-event-not-found (err u106))
(define-constant err-past-event (err u107))
(define-constant err-refund-window-expired (err u108))

;; Data vars
(define-data-var venue-name (string-ascii 256) "")
(define-data-var max-price uint u0)
(define-data-var refund-window uint u172800) ;; 48 hours in seconds

;; Data maps
(define-map tickets 
    uint 
    {owner: principal, 
     price: uint,
     is-used: bool,
     for-sale: bool,
     event-id: uint})

(define-map ticket-metadata 
    uint 
    {seat: (string-ascii 10),  
     section: (string-ascii 10)})

(define-map events
    uint
    {name: (string-ascii 256),
     date: uint,
     refundable: bool})

;; Create new event - only owner
(define-public (create-event (event-id uint) (event-name (string-ascii 256)) (event-date uint) (allow-refunds bool))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set events event-id
                {name: event-name,
                 date: event-date,
                 refundable: allow-refunds})
            (ok true))
        err-owner-only))

;; Create new ticket - only owner
(define-public (create-ticket (ticket-id uint) (event-id uint) (seat (string-ascii 10)) (section (string-ascii 10)) (price uint) (recipient principal))
    (let ((event (unwrap! (map-get? events event-id) err-event-not-found)))
        (if (is-eq tx-sender contract-owner)
            (begin
                (map-set tickets ticket-id 
                    {owner: recipient,
                     price: price,
                     is-used: false,
                     for-sale: false,
                     event-id: event-id})
                (map-set ticket-metadata ticket-id
                    {seat: seat,
                     section: section})
                (ok true))
            err-owner-only)))

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
                     for-sale: false,
                     event-id: (get event-id ticket)})
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
                     for-sale: false,
                     event-id: (get event-id ticket)})
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
                     for-sale: true,
                     event-id: (get event-id ticket)})
                (ok true))
            err-invalid-price)))

;; Request refund
(define-public (request-refund (ticket-id uint))
    (let ((ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found))
          (event (unwrap! (map-get? events (get event-id ticket)) err-event-not-found)))
        (if (and
            (is-eq tx-sender (get owner ticket))
            (not (get is-used ticket))
            (get refundable event)
            (< block-height (- (get date event) (var-get refund-window))))
            (begin
                (map-set tickets ticket-id
                    {owner: contract-owner,
                     price: u0,
                     is-used: true,
                     for-sale: false,
                     event-id: (get event-id ticket)})
                (as-contract (stx-transfer? (get price ticket) tx-sender (get owner ticket)))
                (ok true))
            err-refund-window-expired)))

;; Read-only functions
(define-read-only (get-ticket-info (ticket-id uint))
    (map-get? tickets ticket-id))

(define-read-only (get-ticket-details (ticket-id uint))
    (map-get? ticket-metadata ticket-id))

(define-read-only (get-event-info (event-id uint))
    (map-get? events event-id))
