REBOL []

; ============================================================
; agent-loop/api.reb
;
; run-turn / resume-turn drive a turn from the session event log.
; cancel-turn requests cooperative cancel; dispose should call it first.
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

cancelled-tool-result: func [name call-id /local p] [
    p: make map! []
    put p 'name name
    put p 'call-id call-id
    put p 'text "cancelled"
    put p 'cancelled true
    p
]

make-agent-loop: func [ctx [object!] sessions [object!] tools [object!] llm [object!] /local loop] [
    loop: make object! [
        ctx: none
        name: none
        sessions: none
        tools: none
        llm: none
        max-steps: 8
        cancel-requested: false
        live-session-id: none

        scheduler-of: func [/local scope] [
            scope: ctx-runtime-scope ctx
            select scope 'scheduler
        ]

        turn-cancelled?: func [] [
            any [
                cancel-requested
                not agent-active?
            ]
        ]

        ; Pump thenables one scheduler tick at a time so cancel can interrupt.
        settle: func [value /local n item sched] [
            n: 0
            sched: scheduler-of
            while [all [thenable? value  value/pending  n < 10000]] [
                if turn-cancelled? [
                    return make map! [ok false error "cancelled" cancelled true]
                ]
                either all [object? sched  sched/pending?] [
                    item: sched/next-item
                    unless item [break]
                    sched/run-until item/due
                ][
                    break
                ]
                n: n + 1
            ]
            either all [thenable? value  not value/pending] [
                value/value
            ][
                value
            ]
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

        find-session?: func [session-id [string!]] [
            object? sessions/find-session session-id
        ]

        ; Request cancel of the live turn (if any). Safe when idle.
        cancel-turn: func [/local sid] [
            sid: live-session-id
            either string? sid [
                cancel-requested: true
                sid
            ][
                none
            ]
        ]

        finish-turn: func [
            session-id [string!]
            status [word!]
            step [integer!]
            last-text [string!]
            /local te
        ] [
            te: make map! []
            put te 'status status
            put te 'steps step
            put te 'text last-text
            log-event session-id 'turn-end te
            live-session-id: none
            cancel-requested: false
            copy te
        ]

        ; Core turn body. /resume skips logging a new user-message.
        run-turn-core: func [
            session-id [string!]
            /user user-text [string!]
            /resume
            /local step reply result status last-text p call-id meta tool-name cc sink
        ] [
            unless agent-active? [
                return disposed-turn-result
            ]
            unless find-session? session-id [
                session-error rejoin ["run-turn: session not found: " session-id]
            ]
            live-session-id: session-id
            cancel-requested: false
            log-event session-id 'turn-start make map! []
            unless resume [
                log-event session-id 'user-message payload-text any [user-text ""]
            ]
            if turn-cancelled? [
                return finish-turn session-id 'cancelled 0 ""
            ]
            step: 0
            status: 'text
            last-text: ""
            forever [
                if turn-cancelled? [
                    status: 'cancelled
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
                if turn-cancelled? [
                    status: 'cancelled
                    break
                ]
                ; Always rebuild model input from the event log (stream ? chunks + final).
                sink: make object! [
                    loop-ref: none
                    sid: none
                    call: func [text [string!] /local cp] [
                        if loop-ref/turn-cancelled? [return none]
                        cp: make map! []
                        put cp 'text text
                        loop-ref/log-event sid 'assistant-chunk cp
                        none
                    ]
                ]
                sink/loop-ref: self
                sink/sid: session-id
                cc: make object! [
                    loop-ref: none
                    call: func [] [loop-ref/turn-cancelled?]
                ]
                cc/loop-ref: self
                reply: llm/stream/on-chunk/cancel sessions/derive-messages session-id tools/list sink cc
                if turn-cancelled? [
                    status: 'cancelled
                    break
                ]
                either equal? select reply 'kind 'tool-call [
                    call-id: rejoin ["c" step]
                    tool-name: select reply 'name
                    put reply 'call-id call-id
                    log-event session-id 'tool-call reply
                    if turn-cancelled? [
                        log-event session-id 'tool-result (cancelled-tool-result tool-name call-id)
                        status: 'cancelled
                        break
                    ]
                    meta: make map! []
                    put meta 'session-id session-id
                    put meta 'call-id call-id
                    cc: make object! [
                        loop-ref: none
                        call: func [] [loop-ref/turn-cancelled?]
                    ]
                    cc/loop-ref: self
                    put meta 'cancel-check cc
                    result: settle tools/execute/meta tool-name select reply 'args meta
                    either turn-cancelled? [
                        log-event session-id 'tool-result (cancelled-tool-result tool-name call-id)
                        status: 'cancelled
                        break
                    ][
                        p: make map! []
                        put p 'name tool-name
                        put p 'call-id call-id
                        put p 'text form-tool-result result
                        log-event session-id 'tool-result p
                    ]
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
            finish-turn session-id status step last-text
        ]

        run-turn: func [session-id [string!] user-text [string!]] [
            run-turn-core/user session-id user-text
        ]

        resume-turn: func [session-id [string!]] [
            run-turn-core/resume session-id
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
