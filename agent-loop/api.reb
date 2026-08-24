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
        inbox-next-turn: copy []
        inbox-next-step: copy []

        ; ---- inbox: next-turn (followup, waking) / next-step (steer waking, inject non-waking) ----
        followup: func [text [string!] /local msg] [
            msg: make map! []
            put msg 'kind 'followup
            put msg 'text text
            append inbox-next-turn msg
            none
        ]

        steer: func [text [string!] /local msg] [
            msg: make map! []
            put msg 'kind 'steer
            put msg 'text text
            append inbox-next-step msg
            none
        ]

        inject: func [text [string!] /local msg] [
            msg: make map! []
            put msg 'kind 'inject
            put msg 'text text
            append inbox-next-step msg
            none
        ]

        inbox-empty?: func [] [
            all [empty? inbox-next-turn  empty? inbox-next-step]
        ]

        ; Claim one turn boundary batch: one next-turn, then all next-step.
        claim-next-turn: func [/local out] [
            out: copy []
            unless empty? inbox-next-turn [
                append out take inbox-next-turn
            ]
            append out inbox-next-step
            inbox-next-step: copy []
            out
        ]

        ; Claim next-step batch only (between steps).
        claim-next-step: func [/local out] [
            out: copy inbox-next-step
            inbox-next-step: copy []
            out
        ]

        ; Claimed messages become durable user-message rows (model-visible).
        log-inbox-claimed: func [session-id [string!] msgs [block!] /local m] [
            foreach m msgs [
                log-event session-id 'user-message payload-text select m 'text
            ]
            none
        ]

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

        ; agent-pre-step waterfall: return rewritten block, or map! [kind 'reject reason ...] to reject.
        ; Payload: [session-id step-n proposed-messages]
        ; carrier: none — agent/pre-step is a root-level event; scope filtering would drop root listeners.
        run-pre-step: func [session-id [string!] step [integer!] msgs [block!] /local args result inner] [
            args: reduce [session-id step copy/deep msgs]
            inner: make object! [
                call: func [arg-block [block!] this-arg [object! none!]] [
                    arg-block/3
                ]
            ]
            result: settle ctx/events/waterfall 'agent-pre-step args inner none
            if thenable? result [result: settle result]
            result
        ]

        pre-step-rejected?: func [value] [
            either map? value [
                equal? select value 'kind 'reject
            ][
                false
            ]
        ]

        pre-step-reject-reason: func [value] [
            either map? value [
                any [select value 'reason select value 'error "pre-step rejected"]
            ][
                "pre-step rejected"
            ]
        ]

        ; agent-request waterfall: rewrite the LLM request (messages / tools / llm)
        ; after pre-step. Payload: [session-id step-n request-map]
        ; Distinct from pre-step: pre-step edits the step's proposed messages;
        ; request is the last chance to reroute provider or reshape the call.
        run-request: func [session-id [string!] step [integer!] req [map!] /local args result inner] [
            args: reduce [session-id step req]
            inner: make object! [
                call: func [arg-block [block!] this-arg [object! none!]] [
                    arg-block/3
                ]
            ]
            result: settle ctx/events/waterfall 'agent-request args inner none
            if thenable? result [result: settle result]
            result
        ]

        request-rejected?: func [value] [
            either map? value [
                equal? select value 'kind 'reject
            ][
                false
            ]
        ]

        request-reject-reason: func [value] [
            either map? value [
                any [select value 'reason select value 'error "request rejected"]
            ][
                "request rejected"
            ]
        ]
        continuation-kind: func [session-id [string!] /local msgs m] [
            msgs: sessions/derive-messages session-id
            if empty? msgs [return none]
            m: last msgs
            either find [tool assistant] select m 'role [select m 'role][none]
        ]

        disposed-turn-result: func [] [
            te: make map! []
            put te 'status 'disposed
            put te 'steps 0
            put te 'text ""
            te
        ]

        ; Resume is meaningful when the log ends with tool result or assistant text.
        ; Inbox followup/steer also admits a turn: claimed messages will become user-message rows.
        can-admit-turn?: func [session-id [string!] claimed [block!]] [
            if continuation-kind session-id [return true]
            foreach m claimed [
                if equal? select m 'kind 'followup [return true]
                if equal? select m 'kind 'steer [return true]
            ]
            false
        ]

        no-input-turn-result: func [session-id [string!] /local te] [
            te: make map! []
            put te 'status 'no-input
            put te 'steps 0
            put te 'text ""
            log-event session-id 'turn-end te
            live-session-id: none
            cancel-requested: false
            copy te
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
            /local step reply result status last-text p call-id meta tool-name cc sink claimed claimed-step proposed pre-out req req-out spec step-llm
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
            ; Claim inbox: at turn start take one next-turn message + all next-step (steer/inject).
            ; For /user, caller text already logged; inbox still claims steer/inject context.
            claimed: claim-next-turn
            unless empty? claimed [
                log-inbox-claimed session-id claimed
            ]
            unless resume [
                log-event session-id 'user-message payload-text any [user-text ""]
            ]
            if turn-cancelled? [
                return finish-turn session-id 'cancelled 0 ""
            ]
            ; Resume is meaningful when the log ends with tool result or assistant text;
            ; inbox followup/steer also admits a turn. Only missing input means no-input.
            if all [resume not can-admit-turn? session-id claimed] [
                return no-input-turn-result session-id
            ]
            step: 0
            status: 'text
            last-text: ""
            forever [
                if turn-cancelled? [
                    status: 'cancelled
                    break
                ]
                if step >= max-steps [
                    status: 'max-steps
                    break
                ]
                step: step + 1
                p: make map! []
                put p 'n step
                log-event session-id 'step-start p
                if turn-cancelled? [
                    status: 'cancelled
                    break
                ]
                ; Between steps, claim any next-step inbox (steer/inject) as user messages.
                claimed-step: claim-next-step
                unless empty? claimed-step [
                    log-inbox-claimed session-id claimed-step
                ]
                ; agent-pre-step: listeners may reject or rewrite the proposed messages.
                proposed: sessions/derive-messages session-id
                pre-out: run-pre-step session-id step proposed
                if pre-step-rejected? pre-out [
                    p: make map! []
                    put p 'n step
                    put p 'reason pre-step-reject-reason pre-out
                    log-event session-id 'step-rejected p
                    status: 'rejected
                    break
                ]
                if block? pre-out [
                    proposed: pre-out
                ]
                ; agent-request: last rewrite of messages / tools / llm before the call.
                req: make map! []
                put req 'messages proposed
                put req 'tools tools/list
                put req 'llm llm
                req-out: run-request session-id step req
                if request-rejected? req-out [
                    p: make map! []
                    put p 'n step
                    put p 'reason request-reject-reason req-out
                    log-event session-id 'step-rejected p
                    status: 'rejected
                    break
                ]
                either map? req-out [
                    if block? select req-out 'messages [proposed: select req-out 'messages]
                    spec: select req-out 'tools
                    unless block? spec [spec: tools/list]
                    step-llm: select req-out 'llm
                    unless object? step-llm [step-llm: llm]
                ][
                    spec: tools/list
                    step-llm: llm
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
                reply: step-llm/stream/on-chunk/cancel proposed spec sink cc
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

        run-turn: func [session-id [string!] user-text [string! none!]] [
            either none? user-text [
                if inbox-empty? [
                    return no-input-turn-result session-id
                ]
                run-turn-core/resume session-id
            ][
                run-turn-core/user session-id user-text
            ]
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
    apply: func [ctx [object!] config /local sessions tools llm loop resolved ms] [
        sessions: ctx/reflect/get 'sessions true ctx
        tools: ctx/reflect/get 'tools true ctx
        llm: ctx/reflect/get 'llm true ctx
        loop: make-agent-loop ctx sessions tools llm
        make-service ctx 'agent-loop loop
        resolved: service-resolve-config loop either map? config [config][none] none
        ms: select resolved 'max-steps
        if integer? ms [loop/max-steps: ms]
        none
    ]
]
