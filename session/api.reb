REBOL []

; ============================================================
; session/api.reb
;
; Provides ctx service 'sessions:
;   create -> session object [id events]
;   append id type payload -> event map! or none
;   events-of id -> block
;   derive-messages id -> block of map [role content ...]
;
; Event types (word!):
;   turn-start turn-end step-start step-end
;   user-message assistant-message tool-call tool-result
; ============================================================

make-session-store: func [ctx [object!] /local store] [
    store: make object! [
        ctx: none
        name: none
        sessions: make map! []
        seq: 0

        create: func [/local sid s] [
            seq: seq + 1
            sid: rejoin ["s" seq]
            s: make object! [
                id: none
                events: copy []
            ]
            s/id: sid
            put sessions sid s
            s
        ]

        find-session: func [id [string!]] [
            select sessions id
        ]

        append-event: func [id [string!] type [word!] payload [map!] /local s ev] [
            s: find-session id
            unless s [return none]
            ev: make map! []
            put ev 'type type
            put ev 'payload payload
            put ev 'index length? s/events
            append s/events ev
            ctx/events/emit 'session-event reduce [s ev] none
            ev
        ]

        events-of: func [id [string!] /local s] [
            s: find-session id
            either s [copy s/events] [copy []]
        ]

        derive-messages: func [id [string!] /local s msgs ev p m] [
            s: find-session id
            unless s [return copy []]
            msgs: copy []
            foreach ev s/events [
                p: select ev 'payload
                m: none
                switch select ev 'type [
                    user-message [
                        m: make map! []
                        put m 'role 'user
                        put m 'content any [select p 'text ""]
                    ]
                    assistant-message [
                        m: make map! []
                        put m 'role 'assistant
                        put m 'content any [select p 'text ""]
                    ]
                    tool-call [
                        m: make map! []
                        put m 'role 'assistant
                        put m 'kind 'tool-call
                        put m 'name select p 'name
                        put m 'args select p 'args
                    ]
                    tool-result [
                        m: make map! []
                        put m 'role 'tool
                        put m 'name select p 'name
                        put m 'content any [select p 'text ""]
                    ]
                ]
                if m [append msgs m]
            ]
            msgs
        ]
    ]
    store/ctx: ctx
    store
]

session-plugin: make object! [
    name: "session"
    inject: []
    apply: func [ctx [object!] config] [
        make-service ctx 'sessions make-session-store ctx
        none
    ]
]
