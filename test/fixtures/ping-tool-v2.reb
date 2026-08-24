REBOL []
; ping tool v2 — same plugin name, new result text
make object! [
    name: "ping-tool"
    inject: [tools]
    apply: func [ctx [object!] config /local tools] [
        tools: ctx/reflect/get 'tools true ctx
        tools/register make object! [
            name: 'ping
            description: "ping v2"
            run: make object! [
                call: func [args /local m] [
                    m: make map! []
                    put m 'ok true
                    put m 'text "pong v2"
                    m
                ]
            ]
        ]
        none
    ]
]
