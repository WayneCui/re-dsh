REBOL []

; ============================================================
; session/json.reb — JSON-safe payload snapshots for append/replay.
; ============================================================

json-value?: func [v] [
    either none? v [return true]
    either any [string? v tag? v integer? v decimal? v logic? v date? v time? v][
        true
    ][
        either word? v [
            true
        ][
            either block? v [
                foreach item v [unless json-value? item [return false]]
                true
            ][
                either map? v [
                    foreach key-n keys-of v [
                        unless json-value? v/:key-n [return false]
                    ]
                    true
                ][
                    false
                ]
            ]
        ]
    ]
]

json-map?: func [m /local key-n] [
    either map? m [
        foreach key-n keys-of m [
            unless json-value? m/:key-n [return false]
        ]
        true
    ][
        false
    ]
]

snapshot-json-value: func [v] [
    either map? v [
        snapshot-json-map v
    ][
        either block? v [
            b: copy []
            foreach item v [append b snapshot-json-value item]
            b
        ][
            v
        ]
    ]
]

snapshot-json-map: func [m [map!] /local out key-n] [
    out: make map! []
    foreach key-n keys-of m [
        put out key-n snapshot-json-value m/:key-n
    ]
    out
]
