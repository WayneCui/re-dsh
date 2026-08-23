REBOL []

; ============================================================
; llm/api.reb
;
; Provides ctx service 'llm:
;   complete messages [block!] tool-specs [block!] -> map
;     text:      kind: 'text  text: string!
;     tool-call: kind: 'tool-call  name: word!  args: map!
;   enqueue reply [map!]  — scripted adapter (tests)
;
; Production adapters (plugin config map):
;   script: path to r3 script — reads request file, prints reply mold
;   http-url: POST mold body, parse mold response
; ============================================================

do %reply.reb
do %script.reb
do %http.reb

make-llm-service: func [
    ctx [object!]
    /host host-svc [object! none!]
    /script script-path [file! string! none!]
    /http-url url [url! string! none!]
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

        complete: func [messages [block!] tool-specs [block!] /local reply ext] [
            unless empty? queue [
                reply: take queue
                return reply
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
    apply: func [ctx [object!] config /local host script-path http-url svc] [
        host: ctx/reflect/get 'host true ctx
        script-path: select config 'script
        http-url: select config 'http-url
        svc: make-llm-service/host ctx host
        if script-path [svc/script-path: script-path]
        if http-url [svc/http-url: http-url]
        make-service ctx 'llm svc
        none
    ]
]
