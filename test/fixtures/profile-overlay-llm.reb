[
    make map! compose [
        id "llm"
        config (make map! [script %test/fixtures/llm-pipeline-stub.reb])
    ]
]
