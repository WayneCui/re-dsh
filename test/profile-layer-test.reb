REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot-yaml.reb

entry-config: func [entries id [string!] /local entry] [
    foreach entry entries [
        if equal? entry-id-of entry id [return entry-config-of entry]
    ]
    none
]

entry-by-id: func [entries id [string!] /local entry] [
    foreach entry entries [
        if equal? entry-id-of entry id [return entry]
    ]
    none
]

; ---- minimal profile = cordis.yml parity ----
minimal: compose-profile-entries %profiles/minimal/
yaml-base: compose-entry-config %cordis.yml
assert equal? length? minimal length? yaml-base "minimal count matches cordis.yml"
foreach id ["host" "sessions" "approval" "llm" "agents"] [
    m: entry-by-id minimal id
    y: entry-by-id yaml-base id
    assert map? m rejoin ["minimal has " id]
    assert equal? entry-name-of m entry-name-of y rejoin ["minimal " id " name matches yaml"]
]

; ---- full profile adds store-dir + script via profile layer ----
full: compose-profile-entries %profiles/full/
sess-cfg: entry-config full "sessions"
llm-cfg: entry-config full "llm"
assert equal? %test/tmp-profile-full-store/ select sess-cfg 'store-dir "full profile store-dir"
assert equal? %examples/full-chain-llm.reb select llm-cfg 'script "full profile llm script"

; ---- layer order: CLI patch wins over profile ----
stacked: compose-profile-entries/patches %profiles/full/ reduce [%test/fixtures/profile-overlay-llm.reb]
llm-cfg2: entry-config stacked "llm"
assert equal? %test/fixtures/llm-pipeline-stub.reb select llm-cfg2 'script "cli patch overrides profile llm"

; ---- home layer between profile and CLI ----
with-home: compose-profile-entries/home/patches %profiles/minimal/
    %test/fixtures/profile-home-disable-approval.reb
    reduce [%test/fixtures/profile-overlay-enable-approval.reb]
ap: entry-by-id with-home "approval"
assert equal? false entry-disabled? ap "cli patch wins over home layer"

; ---- boot-spine-from-profile runs echo turn ----
spine: boot-spine-from-profile "minimal"
s: spine/sessions/create
out: spine/driver/run-turn s/id "profile-parity"
assert equal? 'text select out 'status "minimal profile boot turn"
assert equal? "profile-parity" select out 'text "minimal profile echo"
shutdown-spine spine

print "^/---- dump minimal profile ----"
dump-spine-config/profile "minimal"

finish-tests "profile-layer-test"
