
;; STX-Validata
;; Decentralized Peer-Review Publishing System
;; Author: Claude
;; Description: A smart contract that manages peer reviews for research papers and rewards reviewers

;; Constants for error handling
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PAPER-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-REVIEWED (err u102))
(define-constant ERR-INVALID-SCORE (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-NOT-REVIEWER (err u105))
(define-constant ERR-PAPER-EXISTS (err u106))
(define-constant ERR-EMPTY-HASH (err u107))
(define-constant ERR-INVALID-ID (err u108))
(define-constant ERR-EMPTY-REASON (err u109))
(define-constant ERR-SELF-CHALLENGE (err u110))
(define-constant ERR-EMPTY-STATUS (err u111))
(define-constant ERR-INVALID-STATUS (err u112))
(define-constant ERR-ALREADY-REGISTERED (err u113))

;; Data Variables
(define-data-var min-stake uint u100) ;; Minimum STX required to stake as reviewer
(define-data-var review-reward uint u50) ;; STX reward per review
(define-data-var contract-owner principal tx-sender)

;; Data Maps
(define-map Papers 
    { paper-id: uint }
    {
        author: principal,
        ipfs-hash: (string-ascii 64),
        status: (string-ascii 20),
        review-count: uint,
        total-score: uint,
        timestamp: uint
    }
)

(define-map Reviews
    { paper-id: uint, reviewer: principal }
    {
        score: uint,
        comment-hash: (string-ascii 64),
        timestamp: uint,
        status: (string-ascii 20)
    }
)

(define-map Reviewers
    { reviewer: principal }
    {
        stake: uint,
        review-count: uint,
        reputation: uint,
        status: (string-ascii 20)
    }
)

;; Authorization check
(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner))
)

;; Submit new paper
(define-public (submit-paper (ipfs-hash (string-ascii 64)) (paper-id uint))
    (let
        (
            (paper-data {
                author: tx-sender,
                ipfs-hash: ipfs-hash,
                status: "pending",
                review-count: u0,
                total-score: u0,
                timestamp: stacks-block-height
            })
        )
        ;; Additional validations
        (asserts! (> (len ipfs-hash) u0) ERR-EMPTY-HASH)
        (asserts! (>= paper-id u0) ERR-INVALID-ID)
        (asserts! (is-none (map-get? Papers { paper-id: paper-id })) ERR-PAPER-EXISTS)
        
        (ok (map-set Papers { paper-id: paper-id } paper-data))
    )
)

;; Register as reviewer
(define-public (register-reviewer)
    (let
        (
            (stake-amount (var-get min-stake))
            (reviewer-data {
                stake: stake-amount,
                review-count: u0,
                reputation: u100,
                status: "active"
            })
        )
        ;; Additional validations
        (asserts! (is-none (map-get? Reviewers { reviewer: tx-sender })) ERR-ALREADY-REGISTERED)
        (asserts! (>= (stx-get-balance tx-sender) stake-amount) ERR-INSUFFICIENT-BALANCE)
        
        (try! (stx-transfer? stake-amount tx-sender (as-contract tx-sender)))
        (ok (map-set Reviewers { reviewer: tx-sender } reviewer-data))
    )
)


;; Submit review
(define-public (submit-review 
    (paper-id uint) 
    (score uint) 
    (comment-hash (string-ascii 64)))
    (let (
        (paper-data (unwrap! (map-get? Papers { paper-id: paper-id }) ERR-PAPER-NOT-FOUND))
        (reviewer-data (unwrap! (map-get? Reviewers { reviewer: tx-sender }) ERR-NOT-REVIEWER))
    )
        ;; Additional validations
        (asserts! (> (len comment-hash) u0) ERR-EMPTY-HASH)
        (asserts! (and (>= score u0) (<= score u100)) ERR-INVALID-SCORE)
        (asserts! (not (is-eq (get author paper-data) tx-sender)) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? Reviews { paper-id: paper-id, reviewer: tx-sender })) ERR-ALREADY-REVIEWED)
        (asserts! (is-eq (get status reviewer-data) "active") ERR-NOT-AUTHORIZED)

        ;; Set review
        (map-set Reviews 
            { paper-id: paper-id, reviewer: tx-sender }
            {
                score: score,
                comment-hash: comment-hash,
                timestamp: stacks-block-height,
                status: "submitted"
            }
        )

        ;; Update paper data
        (map-set Papers
            { paper-id: paper-id }
            {
                author: (get author paper-data),
                ipfs-hash: (get ipfs-hash paper-data),
                status: "reviewed",
                review-count: (+ (get review-count paper-data) u1),
                total-score: (+ (get total-score paper-data) score),
                timestamp: (get timestamp paper-data)
            }
        )

        ;; Update reviewer stats and send reward
        (map-set Reviewers
            { reviewer: tx-sender }
            {
                stake: (get stake reviewer-data),
                review-count: (+ (get review-count reviewer-data) u1),
                reputation: (+ (get reputation reviewer-data) u1),
                status: (get status reviewer-data)
            }
        )

        (try! (stx-transfer? (var-get review-reward) (as-contract tx-sender) tx-sender))
        (ok true)
    ))

;; Withdraw staked tokens (only for paused or inactive reviewers)
(define-public (withdraw-stake)
    (let (
        (reviewer-data (unwrap! (map-get? Reviewers { reviewer: tx-sender }) ERR-NOT-REVIEWER))
    )
        ;; Additional validations
        (asserts! (or (is-eq (get status reviewer-data) "paused") 
                     (is-eq (get status reviewer-data) "inactive")) 
                 ERR-NOT-AUTHORIZED)

        (try! (stx-transfer? (get stake reviewer-data) (as-contract tx-sender) tx-sender))
        (ok (map-delete Reviewers { reviewer: tx-sender }))
    )
)

;; Challenge a review
(define-public (challenge-review (paper-id uint) (reviewer principal) (reason (string-ascii 256)))
    (let (
        (review-data (unwrap! (map-get? Reviews { paper-id: paper-id, reviewer: reviewer }) ERR-PAPER-NOT-FOUND))
        (challenge-stake (var-get min-stake))
    )
        ;; Additional validations
        (asserts! (> (len reason) u0) ERR-EMPTY-REASON)
        (asserts! (not (is-eq reviewer tx-sender)) ERR-SELF-CHALLENGE)
        (asserts! (>= (stx-get-balance tx-sender) challenge-stake) ERR-INSUFFICIENT-BALANCE)

        (try! (stx-transfer? challenge-stake tx-sender (as-contract tx-sender)))

        (map-set Reviews
            { paper-id: paper-id, reviewer: reviewer }
            {
                score: (get score review-data),
                comment-hash: (get comment-hash review-data),
                timestamp: (get timestamp review-data),
                status: "challenged"
            }
        )
        (ok true)
    )
)

;; Update paper status
(define-public (update-paper-status (paper-id uint) (new-status (string-ascii 20)))
    (let (
        (paper-data (unwrap! (map-get? Papers { paper-id: paper-id }) ERR-PAPER-NOT-FOUND))
    )
        ;; Additional validations
        (asserts! (> (len new-status) u0) ERR-EMPTY-STATUS)
        (asserts! (or (is-eq new-status "pending") 
                     (is-eq new-status "reviewed")
                     (is-eq new-status "rejected")
                     (is-eq new-status "accepted")) ERR-INVALID-STATUS)
        (asserts! (is-eq tx-sender (get author paper-data)) ERR-NOT-AUTHORIZED)

        (ok (map-set Papers
            { paper-id: paper-id }
            {
                author: (get author paper-data),
                ipfs-hash: (get ipfs-hash paper-data),
                status: new-status,
                review-count: (get review-count paper-data),
                total-score: (get total-score paper-data),
                timestamp: (get timestamp paper-data)
            }
        ))
    )
)

;; Read-only functions
(define-read-only (get-paper-details (paper-id uint))
    (map-get? Papers { paper-id: paper-id })
)

(define-read-only (get-review-details (paper-id uint) (reviewer principal))
    (map-get? Reviews { paper-id: paper-id, reviewer: reviewer })
)

(define-read-only (get-reviewer-details (reviewer principal))
    (map-get? Reviewers { reviewer: reviewer })
)

(define-read-only (get-reviewer-earnings (reviewer principal))
    (match (map-get? Reviewers { reviewer: reviewer })
        reviewer-data (ok (* (get review-count reviewer-data) (var-get review-reward)))
        ERR-NOT-REVIEWER)
)

;; Administrative functions
(define-public (update-settings 
    (new-min-stake uint)
    (new-review-reward uint))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (var-set min-stake new-min-stake)
        (var-set review-reward new-review-reward)
        (ok true)
    )
)

(define-public (pause-reviewer (reviewer principal))
    (let (
        (reviewer-data (unwrap! (map-get? Reviewers { reviewer: reviewer }) ERR-NOT-REVIEWER))
    )
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (ok (map-set Reviewers
            { reviewer: reviewer }
            {
                stake: (get stake reviewer-data),
                review-count: (get review-count reviewer-data),
                reputation: (get reputation reviewer-data),
                status: "paused"
            }
        ))
    )
)