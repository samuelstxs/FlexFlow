;; FlexFlow - Dynamic Liquidity Pool Protocol
;; A flexible liquidity pool system with automated market making

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_POOL_NOT_FOUND (err u103))
(define-constant ERR_SLIPPAGE_EXCEEDED (err u104))
(define-constant ERR_INVALID_RATIO (err u105))
(define-constant ERR_ZERO_LIQUIDITY (err u106))
(define-constant ERR_MINIMUM_LIQUIDITY (err u107))
(define-constant MINIMUM_LIQUIDITY u1000)
(define-constant FEE_DENOMINATOR u10000)
(define-constant DEFAULT_FEE u30) ;; 0.3%

;; Data Variables
(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var pool-count uint u0)
(define-data-var protocol-fee-rate uint u5) ;; 0.05%
(define-data-var emergency-shutdown bool false)

;; Data Maps
(define-map pools uint {
    token-a: principal,
    token-b: principal,
    reserve-a: uint,
    reserve-b: uint,
    total-supply: uint,
    fee-rate: uint,
    active: bool,
    created-at: uint
})

(define-map user-balances {user: principal, pool-id: uint} uint)
(define-map pool-lookup {token-a: principal, token-b: principal} uint)

;; Read-only functions
(define-read-only (get-pool-info (pool-id uint))
    (map-get? pools pool-id)
)

(define-read-only (get-user-balance (user principal) (pool-id uint))
    (default-to u0 (map-get? user-balances {user: user, pool-id: pool-id}))
)

(define-read-only (get-pool-by-tokens (token-a principal) (token-b principal))
    (map-get? pool-lookup {token-a: token-a, token-b: token-b})
)

(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

(define-read-only (get-pool-count)
    (var-get pool-count)
)

(define-read-only (calculate-swap-output (pool-id uint) (amount-in uint) (token-in principal))
    (let ((pool-data (unwrap! (map-get? pools pool-id) ERR_POOL_NOT_FOUND)))
        (if (is-eq token-in (get token-a pool-data))
            (let ((reserve-in (get reserve-a pool-data))
                  (reserve-out (get reserve-b pool-data))
                  (fee-rate (get fee-rate pool-data)))
                (ok (calculate-output-amount amount-in reserve-in reserve-out fee-rate)))
            (let ((reserve-in (get reserve-b pool-data))
                  (reserve-out (get reserve-a pool-data))
                  (fee-rate (get fee-rate pool-data)))
                (ok (calculate-output-amount amount-in reserve-in reserve-out fee-rate)))))
)

(define-read-only (get-emergency-status)
    (var-get emergency-shutdown)
)

;; Private functions
(define-private (calculate-output-amount (amount-in uint) (reserve-in uint) (reserve-out uint) (fee-rate uint))
    (let ((amount-in-with-fee (- (* amount-in (- FEE_DENOMINATOR fee-rate)) u0))
          (numerator (* amount-in-with-fee reserve-out))
          (denominator (+ (* reserve-in FEE_DENOMINATOR) amount-in-with-fee)))
        (if (> denominator u0)
            (/ numerator denominator)
            u0))
)

(define-private (min-uint (a uint) (b uint))
    (if (< a b) a b)
)

(define-private (calculate-liquidity (amount-a uint) (amount-b uint) (reserve-a uint) (reserve-b uint) (total-supply uint))
    (if (is-eq total-supply u0)
        (- (sqrti (* amount-a amount-b)) MINIMUM_LIQUIDITY)
        (min-uint (/ (* amount-a total-supply) reserve-a)
                  (/ (* amount-b total-supply) reserve-b)))
)

(define-private (is-authorized (user principal))
    (or (is-eq user (var-get contract-owner))
        (is-eq user CONTRACT_OWNER))
)

(define-private (is-valid-principal (principal-to-check principal))
    true
)

(define-private (validate-amount (amount uint))
    (> amount u0)
)

(define-private (validate-pool-active (pool-id uint))
    (match (map-get? pools pool-id)
        pool-data (get active pool-data)
        false)
)

;; Public functions
(define-public (create-pool (token-a principal) (token-b principal) (initial-a uint) (initial-b uint))
    (let ((pool-id (+ (var-get pool-count) u1))
          (current-height stacks-block-height)
          (initial-liquidity (- (sqrti (* initial-a initial-b)) MINIMUM_LIQUIDITY)))
        (asserts! (not (var-get emergency-shutdown)) ERR_UNAUTHORIZED)
        (asserts! (is-valid-principal token-a) ERR_INVALID_AMOUNT)
        (asserts! (is-valid-principal token-b) ERR_INVALID_AMOUNT)
        (asserts! (not (is-eq token-a token-b)) ERR_INVALID_RATIO)
        (asserts! (validate-amount initial-a) ERR_INVALID_AMOUNT)
        (asserts! (validate-amount initial-b) ERR_INVALID_AMOUNT)
        (asserts! (> initial-liquidity u0) ERR_MINIMUM_LIQUIDITY)
        (asserts! (is-none (map-get? pool-lookup {token-a: token-a, token-b: token-b})) ERR_INVALID_RATIO)
        (asserts! (is-none (map-get? pool-lookup {token-a: token-b, token-b: token-a})) ERR_INVALID_RATIO)
        
        (map-set pools pool-id {
            token-a: token-a,
            token-b: token-b,
            reserve-a: initial-a,
            reserve-b: initial-b,
            total-supply: initial-liquidity,
            fee-rate: DEFAULT_FEE,
            active: true,
            created-at: current-height
        })
        
        (map-set pool-lookup {token-a: token-a, token-b: token-b} pool-id)
        (map-set user-balances {user: tx-sender, pool-id: pool-id} initial-liquidity)
        (var-set pool-count pool-id)
        
        (ok pool-id))
)

(define-public (add-liquidity (pool-id uint) (amount-a uint) (amount-b uint) (min-liquidity uint))
    (let ((pool-data (unwrap! (map-get? pools pool-id) ERR_POOL_NOT_FOUND))
          (reserve-a (get reserve-a pool-data))
          (reserve-b (get reserve-b pool-data))
          (total-supply (get total-supply pool-data))
          (liquidity (calculate-liquidity amount-a amount-b reserve-a reserve-b total-supply))
          (current-balance (get-user-balance tx-sender pool-id)))
        
        (asserts! (not (var-get emergency-shutdown)) ERR_UNAUTHORIZED)
        (asserts! (validate-amount amount-a) ERR_INVALID_AMOUNT)
        (asserts! (validate-amount amount-b) ERR_INVALID_AMOUNT)
        (asserts! (validate-pool-active pool-id) ERR_POOL_NOT_FOUND)
        (asserts! (>= liquidity min-liquidity) ERR_SLIPPAGE_EXCEEDED)
        
        (map-set pools pool-id (merge pool-data {
            reserve-a: (+ reserve-a amount-a),
            reserve-b: (+ reserve-b amount-b),
            total-supply: (+ total-supply liquidity)
        }))
        
        (map-set user-balances {user: tx-sender, pool-id: pool-id} (+ current-balance liquidity))
        
        (ok liquidity))
)

(define-public (remove-liquidity (pool-id uint) (liquidity uint) (min-amount-a uint) (min-amount-b uint))
    (let ((pool-data (unwrap! (map-get? pools pool-id) ERR_POOL_NOT_FOUND))
          (user-balance (get-user-balance tx-sender pool-id))
          (total-supply (get total-supply pool-data))
          (reserve-a (get reserve-a pool-data))
          (reserve-b (get reserve-b pool-data))
          (amount-a (/ (* liquidity reserve-a) total-supply))
          (amount-b (/ (* liquidity reserve-b) total-supply)))
        
        (asserts! (not (var-get emergency-shutdown)) ERR_UNAUTHORIZED)
        (asserts! (validate-amount liquidity) ERR_INVALID_AMOUNT)
        (asserts! (validate-pool-active pool-id) ERR_POOL_NOT_FOUND)
        (asserts! (>= user-balance liquidity) ERR_INSUFFICIENT_BALANCE)
        (asserts! (>= amount-a min-amount-a) ERR_SLIPPAGE_EXCEEDED)
        (asserts! (>= amount-b min-amount-b) ERR_SLIPPAGE_EXCEEDED)
        (asserts! (> total-supply liquidity) ERR_ZERO_LIQUIDITY)
        
        (map-set pools pool-id (merge pool-data {
            reserve-a: (- reserve-a amount-a),
            reserve-b: (- reserve-b amount-b),
            total-supply: (- total-supply liquidity)
        }))
        
        (map-set user-balances {user: tx-sender, pool-id: pool-id} (- user-balance liquidity))
        
        (ok {amount-a: amount-a, amount-b: amount-b}))
)

(define-public (swap (pool-id uint) (token-in principal) (amount-in uint) (min-amount-out uint))
    (let ((pool-data (unwrap! (map-get? pools pool-id) ERR_POOL_NOT_FOUND))
          (token-a (get token-a pool-data))
          (token-b (get token-b pool-data))
          (reserve-a (get reserve-a pool-data))
          (reserve-b (get reserve-b pool-data))
          (fee-rate (get fee-rate pool-data)))
        
        (asserts! (not (var-get emergency-shutdown)) ERR_UNAUTHORIZED)
        (asserts! (validate-amount amount-in) ERR_INVALID_AMOUNT)
        (asserts! (validate-pool-active pool-id) ERR_POOL_NOT_FOUND)
        (asserts! (or (is-eq token-in token-a) (is-eq token-in token-b)) ERR_INVALID_AMOUNT)
        
        (if (is-eq token-in token-a)
            (let ((amount-out (calculate-output-amount amount-in reserve-a reserve-b fee-rate)))
                (asserts! (>= amount-out min-amount-out) ERR_SLIPPAGE_EXCEEDED)
                (asserts! (> reserve-b amount-out) ERR_INSUFFICIENT_BALANCE)
                
                (map-set pools pool-id (merge pool-data {
                    reserve-a: (+ reserve-a amount-in),
                    reserve-b: (- reserve-b amount-out)
                }))
                
                (ok amount-out))
            (let ((amount-out (calculate-output-amount amount-in reserve-b reserve-a fee-rate)))
                (asserts! (>= amount-out min-amount-out) ERR_SLIPPAGE_EXCEEDED)
                (asserts! (> reserve-a amount-out) ERR_INSUFFICIENT_BALANCE)
                
                (map-set pools pool-id (merge pool-data {
                    reserve-a: (- reserve-a amount-out),
                    reserve-b: (+ reserve-b amount-in)
                }))
                
                (ok amount-out))))
)

;; Admin functions
(define-public (set-pool-fee (pool-id uint) (new-fee uint))
    (let ((pool-data (unwrap! (map-get? pools pool-id) ERR_POOL_NOT_FOUND)))
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (<= new-fee u300) ERR_INVALID_AMOUNT) ;; Max 3% fee
        (asserts! (validate-amount pool-id) ERR_INVALID_AMOUNT)
        
        (map-set pools pool-id (merge pool-data {fee-rate: new-fee}))
        (ok true))
)

(define-public (toggle-pool-status (pool-id uint))
    (let ((pool-data (unwrap! (map-get? pools pool-id) ERR_POOL_NOT_FOUND)))
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (validate-amount pool-id) ERR_INVALID_AMOUNT)
        
        (map-set pools pool-id (merge pool-data {active: (not (get active pool-data))}))
        (ok true))
)

(define-public (set-emergency-shutdown (shutdown bool))
    (begin
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (var-set emergency-shutdown shutdown)
        (ok true))
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-authorized tx-sender) ERR_UNAUTHORIZED)
        (asserts! (is-valid-principal new-owner) ERR_INVALID_AMOUNT)
        (asserts! (not (is-eq new-owner (var-get contract-owner))) ERR_INVALID_RATIO)
        (var-set contract-owner new-owner)
        (ok true))
)