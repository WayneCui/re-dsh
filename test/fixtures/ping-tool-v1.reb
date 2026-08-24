REBOL []
; ping tool v1 — mounted on an agent isolate ctx
make object! [
    name: "ping-tool"
    inject: [tools]
    apply: func [ctx [object!] config /local tools] [
        tools: ctx/reflect/get 'tools true ctx
        tools/register make object! [
            name: 'ping
            description: "ping v1"
            run: make object! [
                call: func [args /local m] [
                    m: make map! []
                    put m 'ok true
                    put m 'text "pong v1"
                    m
                ]
            ]
        ]
        none
    ]
]
