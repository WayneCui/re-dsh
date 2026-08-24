REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb
do %boot-yaml.reb

; ---- YAML isolate: agents service lives in its own label ----
spine: boot-spine-from-config/config %test/fixtures/cordis-isolate.yml
assert map? spine "boot with isolate ok"
assert object? spine/agents "agents service resolved"
assert equal? 1 length? spine/agents/list "default agent registered"

; root does not see agents under default label
assert none? spine/ctx/reflect/get 'agents false spine/ctx "root agents none"
; but the handle got the isolated one
assert object? spine/agents "handle agents object"

; ---- intercept overlays agent-loop max-steps via resolveConfig ----
spine2: boot-spine-from-config/config %test/fixtures/cordis-intercept.yml
assert map? spine2 "boot with intercept ok"
assert equal? 2 spine2/driver/max-steps "YAML intercept sets max-steps"
assert equal? 1 length? spine2/agents/list "agents still registered"

; intercept chain is inherited by the agent isolate ctx
chain: select spine2/agent-ctx 'intercept-chain
assert block? chain "agent ctx has intercept-chain"
found-ms: false
foreach m chain [
    if map? m [
        cfg: select m 'agent-loop
        if all [map? cfg equal? 2 select cfg 'max-steps] [found-ms: true]
    ]
]
assert found-ms "agent-loop intercept visible on isolate ctx"

shutdown-spine spine
shutdown-spine spine2
finish-tests "yaml-isolate-test"
