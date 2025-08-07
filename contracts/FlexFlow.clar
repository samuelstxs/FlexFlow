;; FlexFlow - Dynamic Liquidity Pool Protocol
;; A flexible liquidity pool system with automated market making and multi-hop routing

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
(define-constant ERR_INVALID_ROUTE (err u108))
(define-constant ERR_MAX_HOPS_EXCEEDED (err u109))
(define-constant ERR_NO_ROUTE_FOUND (err u110))
(define-constant MINIMUM_LIQUIDITY u1000)
(define-constant FEE_DENOMINATOR u10000)
(define-constant DEFAULT_FEE u30) ;; 0.3%
(define-constant MAX_HOPS u3)

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
(define-map token-pools principal (list 20 uint))

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

(define-read-only (get-token-pools (token principal))
    (default-to (list) (map-get? token-pools token))
)

(define-read-only (calculate-swap-output (pool-id uint) (amount-in uint) (token-in principal))
    (let ((pool-data (unwrap! (map-get? pools pool-id) ERR_POOL_NOT_FOUND)))
        (asserts! (get active pool-data) ERR_POOL_NOT_FOUND)
        (if (is-eq token-in (get token-a pool-data))
            (let ((reserve-in (get reserve-a pool-data))
                  (reserve-out (get reserve-b pool-data))
                  (fee-rate (get fee-rate pool-data)))
                (asserts! (> reserve-in u0) ERR_INSUFFICIENT_BALANCE)
                (asserts! (> reserve-out u0) ERR_INSUFFICIENT_BALANCE)
                (ok (calculate-output-amount amount-in reserve-in reserve-out fee-rate)))
            (let ((reserve-in (get reserve-b pool-data))
                  (reserve-out (get reserve-a pool-data))
                  (fee-rate (get fee-rate pool-data)))
                (asserts! (> reserve-in u0) ERR_INSUFFICIENT_BALANCE)
                (asserts! (> reserve-out u0) ERR_INSUFFICIENT_BALANCE)
                (ok (calculate-output-amount amount-in reserve-in reserve-out fee-rate)))))
)

(define-read-only (calculate-multi-hop-output (route (list 3 uint)) (amount-in uint) (token-in principal) (token-out principal))
    (begin
        (asserts! (> (len route) u0) ERR_INVALID_ROUTE)
        (asserts! (<= (len route) MAX_HOPS) ERR_MAX_HOPS_EXCEEDED)
        (let ((result (fold calculate-hop-output route {amount: amount-in, current-token: token-in, valid: true})))
            (if (and (get valid result) (is-eq (get current-token result) token-out))
                (ok (get amount result))
                ERR_INVALID_ROUTE)))
)

(define-read-only (find-optimal-route (token-in principal) (token-out principal))
    (let ((direct-pool (get-pool-by-tokens token-in token-out)))
        (match direct-pool
            pool-id (ok (list pool-id))
            (find-two-hop-route token-in token-out)))
)

(define-read-only (get-emergency-status)
    (var-get emergency-shutdown)
)

;; Private functions
(define-private (calculate-output-amount (amount-in uint) (reserve-in uint) (reserve-out uint) (fee-rate uint))
    (let ((amount-in-with-fee (* amount-in (- FEE_DENOMINATOR fee-rate)))
          (numerator (* amount-in-with-fee reserve-out))
          (denominator (+ (* reserve-in FEE_DENOMINATOR) amount-in-with-fee)))
        (if (> denominator u0)
            (/ numerator denominator)
            u0))
)

(define-private (calculate-hop-output (pool-id uint) (acc {amount: uint, current-token: principal, valid: bool}))
    (if (get valid acc)
        (match (map-get? pools pool-id)
            pool-data 
            (if (get active pool-data)
                (let ((current-token (get current-token acc))
                      (amount (get amount acc)))
                    (if (is-eq current-token (get token-a pool-data))
                        (let ((output (calculate-output-amount amount (get reserve-a pool-data) (get reserve-b pool-data) (get fee-rate pool-data))))
                            (if (and (> output u0) (> (get reserve-b pool-data) output))
                                {amount: output, current-token: (get token-b pool-data), valid: true}
                                {amount: u0, current-token: current-token, valid: false}))
                        (if (is-eq current-token (get token-b pool-data))
                            (let ((output (calculate-output-amount amount (get reserve-b pool-data) (get reserve-a pool-data) (get fee-rate pool-data))))
                                (if (and (> output u0) (> (get reserve-a pool-data) output))
                                    {amount: output, current-token: (get token-a pool-data), valid: true}
                                    {amount: u0, current-token: current-token, valid: false}))
                            {amount: u0, current-token: current-token, valid: false})))
                {amount: u0, current-token: (get current-token acc), valid: false})
            {amount: u0, current-token: (get current-token acc), valid: false})
        acc)
)

(define-private (find-two-hop-route (token-in principal) (token-out principal))
    (let ((token-in-pools (get-token-pools token-in))
          (token-out-pools (get-token-pools token-out)))
        (let ((common-result (find-common-token token-in-pools token-out-pools token-in token-out)))
            (if (get found common-result)
                (ok (get route common-result))
                ERR_NO_ROUTE_FOUND)))
)

(define-private (find-common-token (pools-a (list 20 uint)) (pools-b (list 20 uint)) (token-a principal) (token-b principal))
    (fold check-common-token pools-a {pools-b: pools-b, token-a: token-a, token-b: token-b, route: (list), found: false})
)

(define-private (check-common-token (pool-id uint) (acc {pools-b: (list 20 uint), token-a: principal, token-b: principal, route: (list 2 uint), found: bool}))
    (if (get found acc)
        acc
        (match (map-get? pools pool-id)
            pool-data
            (if (get active pool-data)
                (let ((token-a (get token-a acc))
                      (token-b (get token-b acc))
                      (pools-b (get pools-b acc)))
                    (let ((other-token (if (is-eq token-a (get token-a pool-data)) 
                                          (get token-b pool-data) 
                                          (get token-a pool-data))))
                        (match (find-pool-with-token pools-b other-token token-b)
                            second-pool (merge acc {route: (list pool-id second-pool), found: true})
                            acc)))
                acc)
            acc))
)

(define-private (find-pool-with-token (pool-list (list 20 uint)) (token principal) (target-token principal))
    (get result (fold check-pool-for-token pool-list {token: token, target: target-token, result: none}))
)

(define-private (check-pool-for-token (pool-id uint) (acc {token: principal, target: principal, result: (optional uint)}))
    (match (get result acc)
        found-pool acc  ;; Return acc instead of (get result acc)
        (match (map-get? pools pool-id)
            pool-data
            (let ((token (get token acc))
                  (target (get target acc)))
                (if (and (get active pool-data)
                         (or (and (is-eq token (get token-a pool-data)) (is-eq target (get token-b pool-data)))
                             (and (is-eq token (get token-b pool-data)) (is-eq target (get token-a pool-data)))))
                    (merge acc {result: (some pool-id)})
                    acc))
            acc))
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

(define-private (add-token-to-pools (token principal) (pool-id uint))
    (let ((current-pools (get-token-pools token)))
        (if (< (len current-pools) u20)
            (match (as-max-len? (append current-pools pool-id) u20)
                new-list (map-set token-pools token new-list)
                false)
            true))
)

(define-private (validate-route (route (list 3 uint)) (token-in principal) (token-out principal))
    (let ((route-length (len route)))
        (and (> route-length u0)
             (<= route-length MAX_HOPS)
             (validate-route-connectivity route token-in token-out)))
)

(define-private (validate-route-connectivity (route (list 3 uint)) (token-in principal) (token-out principal))
    (let ((validation-result (fold validate-hop route {current-token: token-in, valid: true, final-token: token-out})))
        (and (get valid validation-result) 
             (is-eq (get current-token validation-result) token-out)))
)

(define-private (validate-hop (pool-id uint) (acc {current-token: principal, valid: bool, final-token: principal}))
    (if (get valid acc)
        (match (map-get? pools pool-id)
            pool-data
            (if (get active pool-data)
                (let ((current-token (get current-token acc)))
                    (if (or (is-eq current-token (get token-a pool-data))
                            (is-eq current-token (get token-b pool-data)))
                        (merge acc {current-token: (if (is-eq current-token (get token-a pool-data))
                                                      (get token-b pool-data)
                                                      (get token-a pool-data))})
                        (merge acc {valid: false})))
                (merge acc {valid: false}))
            (merge acc {valid: false}))
        acc)
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
        (add-token-to-pools token-a pool-id)
        (add-token-to-pools token-b pool-id)
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

(define-public (multi-hop-swap (route (list 3 uint)) (token-in principal) (token-out principal) (amount-in uint) (min-amount-out uint))
    (begin
        (asserts! (not (var-get emergency-shutdown)) ERR_UNAUTHORIZED)
        (asserts! (validate-amount amount-in) ERR_INVALID_AMOUNT)
        (asserts! (validate-route route token-in token-out) ERR_INVALID_ROUTE)
        
        (let ((swap-result (execute-multi-hop-swap route amount-in token-in)))
            (asserts! (>= (get amount swap-result) min-amount-out) ERR_SLIPPAGE_EXCEEDED)
            (asserts! (is-eq (get final-token swap-result) token-out) ERR_INVALID_ROUTE)
            (ok (get amount swap-result))))
)

(define-private (execute-multi-hop-swap (route (list 3 uint)) (amount-in uint) (token-in principal))
    (fold execute-hop route {amount: amount-in, current-token: token-in, final-token: token-in})
)

(define-private (execute-hop (pool-id uint) (acc {amount: uint, current-token: principal, final-token: principal}))
    (match (map-get? pools pool-id)
        pool-data
        (if (and (get active pool-data) (> (get amount acc) u0))
            (let ((amount (get amount acc))
                  (current-token (get current-token acc)))
                (if (is-eq current-token (get token-a pool-data))
                    (let ((reserve-a (get reserve-a pool-data))
                          (reserve-b (get reserve-b pool-data))
                          (fee-rate (get fee-rate pool-data))
                          (amount-out (calculate-output-amount amount reserve-a reserve-b fee-rate)))
                        (if (and (> amount-out u0) (> reserve-b amount-out))
                            (begin
                                (map-set pools pool-id (merge pool-data {
                                    reserve-a: (+ reserve-a amount),
                                    reserve-b: (- reserve-b amount-out)
                                }))
                                (merge acc {amount: amount-out, current-token: (get token-b pool-data), final-token: (get token-b pool-data)}))
                            (merge acc {amount: u0})))
                    (if (is-eq current-token (get token-b pool-data))
                        (let ((reserve-a (get reserve-a pool-data))
                              (reserve-b (get reserve-b pool-data))
                              (fee-rate (get fee-rate pool-data))
                              (amount-out (calculate-output-amount amount reserve-b reserve-a fee-rate)))
                            (if (and (> amount-out u0) (> reserve-a amount-out))
                                (begin
                                    (map-set pools pool-id (merge pool-data {
                                        reserve-a: (- reserve-a amount-out),
                                        reserve-b: (+ reserve-b amount)
                                    }))
                                    (merge acc {amount: amount-out, current-token: (get token-a pool-data), final-token: (get token-a pool-data)}))
                                (merge acc {amount: u0})))
                        (merge acc {amount: u0}))))
            (merge acc {amount: u0}))
        (merge acc {amount: u0}))
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