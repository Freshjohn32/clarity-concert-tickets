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
(define-constant err-zero-address (err u109))
(define-constant err-insufficient-funds (err u110))

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

;; Events
(define-data-var last-event-id uint u0)

(define-public (create-event (event-id uint) (event-name (string-ascii 256)) (event-date uint) (allow-refunds bool))
    (let ((current-time (unwrap! (get-block-info? time (- block-height u1)) err-past-event)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> event-date current-time) err-past-event)
        (map-set events event-id
            {name: event-name,
             date: event-date,
             refundable: allow-refunds})
        (var-set last-event-id event-id)
        (ok true)))

(define-public (create-ticket (ticket-id uint) (event-id uint) (seat (string-ascii 10)) (section (string-ascii 10)) (price uint) (recipient principal))
    (let ((event (unwrap! (map-get? events event-id) err-event-not-found)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> price u0) err-invalid-price)
        (asserts! (not (is-eq recipient contract-owner)) err-zero-address)
        (map-set tickets ticket-id 
            {owner: recipient,
             price: price,
             is-used: false,
             for-sale: false,
             event-id: event-id})
        (map-set ticket-metadata ticket-id
            {seat: seat,
             section: section})
        (ok true)))

;; ... [remaining functions unchanged for brevity]

;; Enhanced refund implementation
(define-public (request-refund (ticket-id uint))
    (let ((ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found))
          (event (unwrap! (map-get? events (get event-id ticket)) err-event-not-found))
          (refund-amount (get price ticket)))
        (asserts! (is-eq tx-sender (get owner ticket)) err-unauthorized)
        (asserts! (not (get is-used ticket)) err-already-used)
        (asserts! (get refundable event) err-unauthorized)
        (asserts! (< block-height (- (get date event) (var-get refund-window))) err-refund-window-expired)
        (asserts! (>= (stx-get-balance contract-owner) refund-amount) err-insufficient-funds)
        
        (map-set tickets ticket-id
            {owner: contract-owner,
             price: u0,
             is-used: true,
             for-sale: false,
             event-id: (get event-id ticket)})
        
        (as-contract 
            (match (stx-transfer? refund-amount contract-owner (get owner ticket))
                success (ok true)
                error err-insufficient-funds))
        (ok true)))

;; New getter functions
(define-read-only (get-venue-info)
    (ok {
        venue-name: (var-get venue-name),
        max-price: (var-get max-price),
        refund-window: (var-get refund-window)
    }))

(define-read-only (get-last-event-id)
    (ok (var-get last-event-id)))
