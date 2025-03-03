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

;; [Previous data vars and maps remain unchanged]

(define-public (create-ticket (ticket-id uint) (event-id uint) (seat (string-ascii 10)) (section (string-ascii 10)) (price uint) (recipient principal))
    (let ((event (unwrap! (map-get? events event-id) err-event-not-found))
          (current-time (unwrap! (get-block-info? time (- block-height u1)) err-past-event)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> price u0) err-invalid-price)
        (asserts! (not (is-eq recipient contract-owner)) err-zero-address)
        (asserts! (> (get date event) current-time) err-past-event)
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

(define-public (request-refund (ticket-id uint))
    (let ((ticket (unwrap! (map-get? tickets ticket-id) err-ticket-not-found))
          (event (unwrap! (map-get? events (get event-id ticket)) err-event-not-found))
          (refund-amount (get price ticket))
          (current-owner (get owner ticket)))
        (asserts! (is-eq tx-sender current-owner) err-unauthorized)
        (asserts! (not (get is-used ticket)) err-already-used)
        (asserts! (get refundable event) err-unauthorized)
        (asserts! (< block-height (- (get date event) (var-get refund-window))) err-refund-window-expired)
        (asserts! (>= (as-contract (stx-get-balance tx-sender)) refund-amount) err-insufficient-funds)
        
        ;; Atomic operations: Update ticket state first
        (map-set tickets ticket-id
            {owner: contract-owner,
             price: u0,
             is-used: true,
             for-sale: false,
             event-id: (get event-id ticket)})
        
        ;; Process refund
        (as-contract 
            (match (stx-transfer? refund-amount tx-sender current-owner)
                success (ok true)
                error err-insufficient-funds))))

;; [Remaining functions unchanged]
