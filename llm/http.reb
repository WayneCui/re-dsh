REBOL []

do %reply.reb

; Line protocol for http-post-stream bodies:
;   make map! [delta "hel"]
;   make map! [delta "lo"]
;   make map! [kind 'text text "hello"]     ; optional final reply
; Plain non-empty lines are treated as delta text.

parse-llm-stream-line: func [line [string!] /local parsed] [
    line: trim line
    if empty? line [return none]
    parsed: try [load/all line]
    if error? parsed [return none]
    if block? parsed [
        if empty? parsed [return none]
        parsed: first parsed
    ]
    either map? parsed [parsed][none]
]

run-llm-http: func [
    host [object!]
    url [url! string! file!]
    messages [block!]
    tool-specs [block!]
    /local req body r
] [
    unless object? host [return none]
    req: make-llm-request messages tool-specs
    body: mold/all req
    either file? url [
        ; Non-stream fixture: whole file is one mold reply (ignore POST for transport).
        r: try [read/string url]
        if error? r [return none]
        return parse-llm-reply-text r
    ][
        r: host/http-post url body
    ]
    unless map? r [return none]
    unless select r 'ok [return none]
    parse-llm-reply-text any [select r 'body ""]
]

run-llm-http-stream: func [
    host [object!]
    url [url! string! file!]
    messages [block!]
    tool-specs [block!]
    /on-chunk sink
    /cancel cancel-obj
    /local req body line-sink deltas final-reply line-map d text r
] [
    unless object? host [return none]
    req: make-llm-request messages tool-specs
    body: mold/all req
    deltas: copy []
    final-reply: none
    line-sink: make object! [
        sink-ref: sink
        deltas-ref: deltas
        final-ref: none
        call: func [line [string!] /local m d] [
            m: parse-llm-stream-line line
            unless map? m [return none]
            either select m 'kind [
                final-ref: m
            ][
                d: select m 'delta
                if string? d [
                    append deltas-ref d
                    if object? sink-ref [sink-ref/call d]
                ]
            ]
            none
        ]
    ]
    either all [object? cancel-obj] [
        r: host/http-post-stream/on-line/cancel url body line-sink cancel-obj
    ][
        r: host/http-post-stream/on-line url body line-sink
    ]
    final-reply: line-sink/final-ref
    unless map? final-reply [
        text: rejoin deltas
        final-reply: make map! []
        put final-reply 'kind 'text
        put final-reply 'text text
    ]
    if all [map? r  select r 'cancelled] [
        put final-reply 'cancelled true
    ]
    final-reply
]
