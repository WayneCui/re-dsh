REBOL []

; Shared LLM reply helpers (text | tool-call).

last-user-content: func [messages [block!] /local last msg] [
    last: ""
    foreach msg messages [
        if equal? select msg 'role 'user [
            last: any [select msg 'content ""]
        ]
    ]
    last
]

normalize-llm-reply: func [raw /local kind n] [
    unless map? raw [return none]
    kind: select raw 'kind
    either equal? kind 'text [
        unless string? any [select raw 'text][return none]
        raw
    ][
        either equal? kind 'tool-call [
            n: select raw 'name
            unless any [word? n string? n][return none]
            if string? n [put raw 'name to-word n]
            unless map? select raw 'args [return none]
            raw
        ][
            none
        ]
    ]
]

parse-llm-reply-text: func [text [string!] /local parsed] [
    unless string? text [return none]
    parsed: try [load/all trim text]
    if block? parsed [parsed: first parsed]
    normalize-llm-reply parsed
]

snapshot-tool-specs: func [tool-specs [block!] /local out spec entry] [
    out: copy []
    foreach spec tool-specs [
        entry: make map! []
        put entry 'name spec/name
        put entry 'description any [spec/description ""]
        append out entry
    ]
    out
]

make-llm-request: func [messages [block!] tool-specs [block!] /local req] [
    req: make map! []
    put req 'messages copy messages
    put req 'tools snapshot-tool-specs tool-specs
    req
]
