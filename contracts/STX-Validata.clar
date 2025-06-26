
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
