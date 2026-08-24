[
    make map! compose [id "sessions" config (make map! [store-dir %test/tmp-profile-full-store/])]
    make map! compose [id "llm" config (make map! [script %examples/full-chain-llm.reb])]
]
