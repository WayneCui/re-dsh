REBOL []

; ============================================================
; llm/api.reb
;
; Provides ctx service 'llm:
;   complete messages [block!] tool-specs [block!] -> map
;     text:      kind: 'text  text: string!
;     tool-call: kind: 'tool-call  name: word!  args: map!
;   enqueue reply [map!]  — scripted adapter (tests)
; ============================================================

last-user-content: func [messages [block!] /local last msg] [
    last: ""
    foreach msg messages [
        if equal? select msg 'role 'user [
            last: any [select msg 'content ""]
        ]
    ]
    last
]

make-llm-service: func [ctx [object!] /local svc] [
    svc: make object! [
        ctx: none
        name: none
        queue: copy []

        enqueue: func [reply [map!]] [
            append queue reply
            reply
        ]

        complete: func [messages [block!] tool-specs [block!] /local reply m] [
            unless empty? queue [
                reply: take queue
                return reply
            ]
            m: make map! []
            put m 'kind 'text
            put m 'text last-user-content messages
            m
        ]
    ]
    svc/ctx: ctx
    svc
]

llm-plugin: make object! [
    name: "llm"
    inject: []
    apply: func [ctx [object!] config] [
        make-service ctx 'llm make-llm-service ctx
        none
    ]
]
