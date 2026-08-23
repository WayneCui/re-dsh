REBOL []

; ============================================================
; shell/api.reb
;
; inject [tools host]. Registers tool 'bash on tools.
; ============================================================

make-bash-spec: func [host [object!] /local spec] [
    spec: make object! [
        name: 'bash
        description: "Run a shell command"
        run: make object! [
            host-ref: host
            call: func [args /local cmd m] [
                cmd: select args 'command
                unless string? cmd [
                    m: make map! []
                    put m 'ok false
                    put m 'error "missing command"
                    return m
                ]
                host-ref/run-command cmd
            ]
        ]
    ]
    spec
]

shell-plugin: make object! [
    name: "shell"
    inject: [tools host]
    apply: func [ctx [object!] config /local tools host] [
        tools: ctx/reflect/get 'tools true ctx
        host: ctx/reflect/get 'host true ctx
        tools/register make-bash-spec host
        none
    ]
]
