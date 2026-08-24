REBOL []

; ============================================================
; llm/api.reb
;
; Provides ctx service 'llm:
;   complete messages tool-specs -> map (text | tool-call)
;   stream/on-chunk/cancel messages tool-specs sink cancel-obj -> map
;   enqueue reply — scripted adapter (tests; optional chunks block)
;
; Production adapters (plugin config map):
;   script: path to r3 script
;   http-url: url! | file! fixture — POST mold body; stream uses line protocol
; ============================================================

do %reply.reb
do %script.reb
do %http.reb

llm-cancelled?: func [cancel-obj] [
    all [object? cancel-obj  cancel-obj/call]
]

emit-text-chunks: func [
    reply [map!]
    sink
    cancel-obj
    /local chunks c text
] [
    unless all [object? sink  equal? select reply 'kind 'text] [return none]
    chunks: select reply 'chunks
    either all [block? chunks  not empty? chunks] [
        foreach c chunks [
            if llm-cancelled? cancel-obj [return 'cancelled]
            if string? c [sink/call c]
        ]
    ][
        if llm-cancelled? cancel-obj [return 'cancelled]
        text: any [select reply 'text ""]
        sink/call text
    ]
    either llm-cancelled? cancel-obj ['cancelled]['ok]
]

make-llm-service: func [
    ctx [object!]
    /host host-svc [object! none!]
    /script script-path [file! string! none!]
    /http-url url [url! string! file! none!]
    /local svc
] [
    svc: make object! [
        ctx: none
        name: none
        queue: copy []
        host-ref: none
        script-path: none
        http-url: none

        enqueue: func [reply [map!]] [
            append queue reply
            reply
        ]

        resolve-reply: func [messages [block!] tool-specs [block!] /local reply ext] [
            unless empty? queue [
                return take queue
            ]
            unless none? script-path [
                ext: run-llm-script host-ref script-path messages tool-specs
                if map? ext [return ext]
            ]
            unless none? http-url [
                ext: run-llm-http host-ref http-url messages tool-specs
                if map? ext [return ext]
            ]
            reply: make map! []
            put reply 'kind 'text
            put reply 'text last-user-content messages
            reply
        ]

        complete: func [messages [block!] tool-specs [block!]] [
            resolve-reply messages tool-specs
        ]

        stream: func [
            messages [block!]
            tool-specs [block!]
            /on-chunk sink
            /cancel cancel-obj
            /local reply st
        ] [
            ; HTTP stream path (skip blocking complete post).
            if all [empty? queue  none? script-path  not none? http-url] [
                either object? cancel-obj [
                    return run-llm-http-stream/on-chunk/cancel host-ref http-url messages tool-specs sink cancel-obj
                ][
                    return run-llm-http-stream/on-chunk host-ref http-url messages tool-specs sink
                ]
            ]
            reply: resolve-reply messages tool-specs
            st: emit-text-chunks reply sink cancel-obj
            if equal? st 'cancelled [
                put reply 'cancelled true
            ]
            reply
        ]
    ]
    svc/ctx: ctx
    svc/host-ref: host-svc
    svc/script-path: script-path
    svc/http-url: url
    svc
]

llm-plugin: make object! [
    name: "llm"
    inject: [host]
    apply: func [ctx [object!] config /local host script-path http-url svc resolved] [
        host: ctx/reflect/get 'host true ctx
        svc: make-llm-service/host ctx host
        make-service ctx 'llm svc
        resolved: service-resolve-config svc either map? config [config][none] none
        script-path: select resolved 'script
        http-url: select resolved 'http-url
        if script-path [svc/script-path: script-path]
        if http-url [svc/http-url: http-url]
        none
    ]
]
