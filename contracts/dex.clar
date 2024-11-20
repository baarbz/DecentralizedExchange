;; dex.clar
;; Simplified Decentralized Exchange (DEX) Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-pair (err u103))

;; Define data vars
(define-data-var fee-rate uint u3) ;; 0.3% fee

;; Define data maps
(define-map pools
  { token-x: principal, token-y: principal }
  { reserve-x: uint, reserve-y: uint, total-liquidity: uint }
)

(define-map liquidity-providers
  { provider: principal, token-x: principal, token-y: principal }
  uint
)

;; Define fungible token for liquidity shares
(define-fungible-token pool-token)

;; Read-only functions

(define-read-only (get-pool-details (token-x principal) (token-y principal))
  (map-get? pools { token-x: token-x, token-y: token-y })
)

(define-read-only (get-liquidity-provider-balance (provider principal) (token-x principal) (token-y principal))
  (default-to u0 (map-get? liquidity-providers { provider: provider, token-x: token-x, token-y: token-y }))
)

;; Private functions

(define-private (swap-tokens (token-x-amount uint) (token-y-amount uint) (token-x principal) (token-y principal))
  (let (
    (pool (unwrap! (map-get? pools { token-x: token-x, token-y: token-y }) (err err-invalid-pair)))
    (reserve-x (get reserve-x pool))
    (reserve-y (get reserve-y pool))
    (k (* reserve-x reserve-y))
    (new-reserve-x (+ reserve-x token-x-amount))
    (new-reserve-y (/ k new-reserve-x))
    (tokens-out (- reserve-y new-reserve-y))
    (fee (/ (* tokens-out (var-get fee-rate)) u1000))
    (tokens-out-with-fee (- tokens-out fee))
  )
    (if (>= tokens-out-with-fee token-y-amount)
      (begin
        (map-set pools { token-x: token-x, token-y: token-y } { reserve-x: new-reserve-x, reserve-y: new-reserve-y, total-liquidity: (get total-liquidity pool) })
        (ok tokens-out-with-fee)
      )
      (err err-insufficient-balance)
    )
  )
)

;; Public functions

(define-public (create-pool (token-x principal) (token-y principal) (amount-x uint) (amount-y uint))
  (let (
    (pool (map-get? pools { token-x: token-x, token-y: token-y }))
  )
    (asserts! (is-none pool) (err err-invalid-pair))
    (asserts! (and (> amount-x u0) (> amount-y u0)) (err err-insufficient-balance))

    (try! (contract-call? token-x transfer amount-x tx-sender (as-contract tx-sender)))
    (try! (contract-call? token-y transfer amount-y tx-sender (as-contract tx-sender)))

    (map-set pools { token-x: token-x, token-y: token-y } { reserve-x: amount-x, reserve-y: amount-y, total-liquidity: amount-x })
    (map-set liquidity-providers { provider: tx-sender, token-x: token-x, token-y: token-y } amount-x)
    (ft-mint? pool-token amount-x tx-sender)
  )
)

(define-public (add-liquidity (token-x principal) (token-y principal) (amount-x uint) (min-liquidity uint))
  (let (
    (pool (unwrap! (map-get? pools { token-x: token-x, token-y: token-y }) (err err-invalid-pair)))
    (reserve-x (get reserve-x pool))
    (reserve-y (get reserve-y pool))
    (total-liquidity (get total-liquidity pool))
    (amount-y (/ (* amount-x reserve-y) reserve-x))
    (liquidity-minted (/ (* amount-x total-liquidity) reserve-x))
  )
    (asserts! (>= liquidity-minted min-liquidity) (err err-insufficient-balance))

    (try! (contract-call? token-x transfer amount-x tx-sender (as-contract tx-sender)))
    (try! (contract-call? token-y transfer amount-y tx-sender (as-contract tx-sender)))

    (map-set pools { token-x: token-x, token-y: token-y }
      { reserve-x: (+ reserve-x amount-x), reserve-y: (+ reserve-y amount-y), total-liquidity: (+ total-liquidity liquidity-minted) }
    )
    (map-set liquidity-providers
      { provider: tx-sender, token-x: token-x, token-y: token-y }
      (+ (get-liquidity-provider-balance tx-sender token-x token-y) liquidity-minted)
    )
    (ft-mint? pool-token liquidity-minted tx-sender)
  )
)

(define-public (remove-liquidity (token-x principal) (token-y principal) (amount uint) (min-x uint) (min-y uint))
  (let (
    (pool (unwrap! (map-get? pools { token-x: token-x, token-y: token-y }) (err err-invalid-pair)))
    (reserve-x (get reserve-x pool))
    (reserve-y (get reserve-y pool))
    (total-liquidity (get total-liquidity pool))
    (provider-liquidity (get-liquidity-provider-balance tx-sender token-x token-y))
    (amount-x (/ (* amount reserve-x) total-liquidity))
    (amount-y (/ (* amount reserve-y) total-liquidity))
  )
    (asserts! (and (>= amount-x min-x) (>= amount-y min-y)) (err err-insufficient-balance))
    (asserts! (>= provider-liquidity amount) (err err-insufficient-balance))

    (try! (as-contract (contract-call? token-x transfer amount-x (as-contract tx-sender) tx-sender)))
    (try! (as-contract (contract-call? token-y transfer amount-y (as-contract tx-sender) tx-sender)))

    (map-set pools { token-x: token-x, token-y: token-y }
      { reserve-x: (- reserve-x amount-x), reserve-y: (- reserve-y amount-y), total-liquidity: (- total-liquidity amount) }
    )
    (map-set liquidity-providers
      { provider: tx-sender, token-x: token-x, token-y: token-y }
      (- provider-liquidity amount)
    )
    (ft-burn? pool-token amount tx-sender)
  )
)

(define-public (swap-x-for-y (token-x principal) (token-y principal) (dx uint) (min-dy uint))
  (let (
    (result (unwrap! (swap-tokens dx min-dy token-x token-y) (err err-insufficient-balance)))
  )
    (try! (contract-call? token-x transfer dx tx-sender (as-contract tx-sender)))
    (as-contract (try! (contract-call? token-y transfer result (as-contract tx-sender) tx-sender)))
    (ok result)
  )
)

(define-public (swap-y-for-x (token-x principal) (token-y principal) (dy uint) (min-dx uint))
  (let (
    (result (unwrap! (swap-tokens dy min-dx token-y token-x) (err err-insufficient-balance)))
  )
    (try! (contract-call? token-y transfer dy tx-sender (as-contract tx-sender)))
    (as-contract (try! (contract-call? token-x transfer result (as-contract tx-sender) tx-sender)))
    (ok result)
  )
)

;; Contract initialization
(begin
  (try! (ft-mint? pool-token u1000000000 contract-owner))
)
