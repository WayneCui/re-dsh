REBOL []

; ============================================================
; approval/api.reb — one-shot approval seam (dsh-shaped minimal).
;
;   request session-id tool-name call-id reason -> outcome word!
;   set-policy session-id policy
;   override-of session-id -> policy | none
;
; Outcomes: allowed-once | rejected | cancelled | unavailable
; Policies: ask | never
; ============================================================

approval-outcomes: [allowed-once rejected cancelled unavailable]
approval-policies: [ask never]

approval-error: func [msg [string!]] [
    cause-error 'user 'message msg
]

mint-approval-id: func [] [
    rejoin ["a" random 999999]
]

approval-policy-from-events: func [events [block!] /local ev p] [
    foreach ev reverse copy events [
        if equal? select ev 'type 'approval-policy [
            p: select ev 'payload
            return select p 'policy
        ]
    ]
    none
]

effective-approval-policy: func [events [block!] default-policy [word!]] [
    any [approval-policy-from-events events default-policy]
]

approval-has-open-turn?: func [events [block!] /local ev t] [
    foreach ev reverse copy events [
        t: select ev 'type
        if equal? t 'turn-start [return true]
        if equal? t 'turn-end [return false]
    ]
    false
]

normalize-approval-outcome: func [value /local o] [
    o: value
    if string? o [o: to-word o]
    if find approval-outcomes o [return o]
    'unavailable
]

make-approval-service: func [
    ctx [object!]
    sessions [object!]
    /default pol [word! none!]
    /local svc p
] [
    p: any [pol 'ask]
    unless find approval-policies p [
        approval-error "default policy must be ask or never"
    ]
    svc: make object! [
        ctx: none
        name: none
        sessions: none
        default-pol: none

        scheduler-of: func [/local scope] [
            scope: ctx-runtime-scope ctx
            select scope 'scheduler
        ]

        settle: func [value] [
            thenable-wait value scheduler-of
        ]

        override-of: func [session-id [string!]] [
            approval-policy-from-events sessions/events-of session-id
        ]

        effective-policy: func [session-id [string!]] [
            effective-approval-policy sessions/events-of session-id default-pol
        ]

        set-policy: func [session-id [string!] policy [word!] /local payload] [
            unless find approval-policies policy [
                approval-error "approval policy must be ask or never"
            ]
            payload: make map! []
            put payload 'policy policy
            sessions/append-event session-id 'approval-policy payload /dispatch-ctx ctx
            none
        ]

        decide-outcome: func [tool-name call-id reason /local req inner answer] [
            req: make map! []
            put req 'tool-name to-string tool-name
            if string? call-id [put req 'call-id call-id]
            if string? reason [put req 'reason reason]
            inner: make object! [
                call: func [arg-block [block!] this-arg [object! none!]] [
                    'unavailable
                ]
            ]
            answer: ctx/events/waterfall 'approval-request reduce [req] inner none
            if thenable? answer [answer: settle answer]
            normalize-approval-outcome answer
        ]

        request: func [
            session-id [string!]
            tool-name [word! string!]
            call-id [string! none!]
            reason [string! none!]
            /local events policy req-id asked decided outcome
        ] [
            events: sessions/events-of session-id
            unless approval-has-open-turn? events [
                approval-error "approval.request outside open turn"
            ]
            policy: effective-approval-policy events default-pol
            req-id: mint-approval-id
            asked: make map! []
            put asked 'id req-id
            put asked 'tool-name to-string tool-name
            if string? call-id [put asked 'call-id call-id]
            if string? reason [put asked 'reason reason]
            sessions/append-event session-id 'approval-asked asked /dispatch-ctx ctx
            either equal? policy 'never [
                outcome: 'rejected
            ][
                outcome: decide-outcome tool-name call-id reason
            ]
            decided: make map! []
            put decided 'id req-id
            put decided 'outcome outcome
            sessions/append-event session-id 'approval-decided decided /dispatch-ctx ctx
            outcome
        ]
    ]
    svc/ctx: ctx
    svc/sessions: sessions
    svc/default-pol: p
    svc
]

approval-plugin: make object! [
    name: "approval"
    inject: [sessions]
    apply: func [ctx [object!] config /local sessions svc policy] [
        sessions: ctx/reflect/get 'sessions true ctx
        policy: select config 'policy
        svc: make-approval-service/default ctx sessions policy
        make-service ctx 'approval svc
        none
    ]
]
