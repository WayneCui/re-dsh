REBOL []

; ============================================================
; agent-loop/api.reb
; ============================================================

payload-text: func [text /local p] [
    p: make map! []
    put p 'text any [text ""]
    p
]

form-tool-result: func [result /local text] [
    if thenable? result [return form-tool-result thenable-wait result none]
    if map? result [
        text: any [
            select result 'stdout
            select result 'text
            select result 'error
            mold result
        ]
        return text
    ]
    form result
]

make-agent-loop: func [ctx [object!] sessions [object!] tools [object!] llm [object!] /local loop] [
    loop: make object! [
        ctx: none
        name: none
        sessions: none
        tools: none
        llm: none
        max-steps: 8

        scheduler-of: func [/local scope] [
            scope: ctx-runtime-scope ctx
            select scope 'scheduler
        ]

        settle: func [value] [
            thenable-wait value scheduler-of
        ]

        log-event: func [session-id [string!] ev-type [word!] payload [map!]] [
            sessions/append-event session-id ev-type payload /dispatch-ctx ctx
        ]

        agent-active?: func [] [
            all [
                object? ctx
                object? ctx/fiber
                not none? ctx/fiber/uid
            ]
        ]

        disposed-turn-result: func [] [
            te: make map! []
            put te 'status 'disposed
            put te 'steps 0
            put te 'text ""
            te
        ]

        run-turn: func [session-id [string!] user-text [string!] /local step reply result status last-text p call-id te cancelled] [
            unless agent-active? [
                return disposed-turn-result
            ]
            log-event session-id 'turn-start make map! []
            log-event session-id 'user-message payload-text user-text
            step: 0
            status: 'text
            last-text: ""
            forever [
                unless agent-active? [
                    status: 'cancelled
                    cancelled: true
                    break
                ]
                step: step + 1
                if step > max-steps [
                    status: 'max-steps
                    break
                ]
                p: make map! []
                put p 'n step
                log-event session-id 'step-start p
                reply: llm/complete sessions/derive-messages session-id tools/list
                either equal? select reply 'kind 'tool-call [
                    call-id: rejoin ["c" step]
                    put reply 'call-id call-id
                    log-event session-id 'tool-call reply
                    meta: make map! []
                    put meta 'session-id session-id
                    put meta 'call-id call-id
                    result: settle tools/execute/meta select reply 'name select reply 'args meta
                    p: make map! []
                    put p 'name select reply 'name
                    put p 'call-id call-id
                    put p 'text form-tool-result result
                    log-event session-id 'tool-result p
                ][
                    last-text: any [select reply 'text ""]
                    log-event session-id 'assistant-message payload-text last-text
                    p: make map! []
                    put p 'n step
                    log-event session-id 'step-end p
                    status: 'text
                    break
                ]
                p: make map! []
                put p 'n step
                log-event session-id 'step-end p
            ]
            te: make map! []
            put te 'status either [cancelled 'cancelled] [status]
            put te 'steps step
            put te 'text last-text
            log-event session-id 'turn-end te
            copy te
        ]
    ]
    loop/ctx: ctx
    loop/sessions: sessions
    loop/tools: tools
    loop/llm: llm
    loop
]

loop-plugin: make object! [
    name: "agent-loop"
    inject: [sessions tools llm]
    apply: func [ctx [object!] config /local sessions tools llm] [
        sessions: ctx/reflect/get 'sessions true ctx
        tools: ctx/reflect/get 'tools true ctx
        llm: ctx/reflect/get 'llm true ctx
        make-service ctx 'agent-loop make-agent-loop ctx sessions tools llm
        none
    ]
]
