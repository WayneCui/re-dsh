REBOL []
; LLM adapter v2 — UPPERCASE echo. A hot-swappable replacement for the
; default echo adapter; reloaded via reload-spine-plugin spine "llm" path.
; Nested do paths would rebase against this file's directory, so this
; fixture is self-contained.
make object! [
    name: "llm"
    inject: []
    apply: func [ctx [object!] config /local svc] [
        svc: make object! [
            ctx: none
            name: none
            queue: copy []
            enqueue: func [reply [map!]] [
                append queue reply
                reply
            ]
            last-user-text: func [messages [block!] /local m] [
                foreach m reverse copy messages [
                    if equal? select m 'role 'user [return any [select m 'content ""]]
                ]
                ""
            ]
            complete: func [messages [block!] tool-specs [block!] /local r] [
                unless empty? queue [return take queue]
                r: make map! []
                put r 'kind 'text
                put r 'text uppercase self/last-user-text messages
                r
            ]
            stream: func [
                messages [block!]
                tool-specs [block!]
                /on-chunk sink
                /cancel cancel-obj
                /local reply
            ] [
                reply: self/complete messages tool-specs
                if all [object? sink string? select reply 'text] [
                    sink/call select reply 'text
                ]
                reply
            ]
        ]
        svc/ctx: ctx
        make-service ctx 'llm svc
        none
    ]
]
