REBOL []

do %./json.reb

; ============================================================
; session/api.reb
;
; Append-only event log with hardened payloads and replay from seed.
;
; Event types (word!):
;   turn-start turn-end step-start step-end
;   user-message assistant-message assistant-chunk
;   tool-call tool-result session-end-seed
; ============================================================

session-event-types: [
    turn-start turn-end step-start step-end
    user-message assistant-message assistant-chunk
    tool-call tool-result session-end-seed
]

session-error: func [msg [string!]] [
    cause-error 'user 'message msg
]

validate-payload: func [ev-type [word!] payload [map!]] [
    unless find session-event-types ev-type [
        return rejoin ["unknown event type: " to-string ev-type]
    ]
    unless json-map? payload [
        return "payload must be JSON-serializable map"
    ]
    switch ev-type [
        user-message assistant-message [
            unless string? any [select payload 'text][
                return "message text must be string"
            ]
        ]
        assistant-chunk [
            unless string? any [select payload 'text][
                return "chunk text must be string"
            ]
        ]
        tool-call [
            n: select payload 'name
            unless any [word? n string? n][
                return "tool-call name required"
            ]
            unless map? select payload 'args [
                return "tool-call args required"
            ]
            cid: select payload 'call-id
            unless any [none? cid string? cid integer? cid][
                return "tool-call call-id must be string or integer"
            ]
        ]
        tool-result [
            n: select payload 'name
            unless any [word? n string? n][
                return "tool-result name required"
            ]
            t: select payload 'text
            unless any [none? t string? t][
                return "tool-result text must be string"
            ]
            cid: select payload 'call-id
            unless any [none? cid string? cid integer? cid][
                return "tool-result call-id must be string or integer"
            ]
        ]
        step-start step-end [
            unless integer? select payload 'n [
                return "step event requires integer n"
            ]
        ]
        session-end-seed [
            unless integer? any [select payload 'count][
                return "session-end-seed requires integer count"
            ]
        ]
    ]
    none
]

make-event-record: func [ev-type [word!] payload [map!] index [integer!]] [
    ev: make map! []
    put ev 'type ev-type
    put ev 'payload payload
    put ev 'index index
    ev
]

validate-event-log: func [events [block!] /local i ev err] [
    unless block? events [
        session-error "event log must be a block"
    ]
    i: 0
    foreach ev events [
        unless map? ev [
            session-error "each event must be a map"
        ]
        unless word? select ev 'type [
            session-error "event missing type"
        ]
        unless map? select ev 'payload [
            session-error "event missing payload map"
        ]
        err: validate-payload select ev 'type select ev 'payload
        if err [session-error err]
        unless equal? i select ev 'index [
            session-error rejoin ["event index must be " i " got " mold select ev 'index]
        ]
        i: i + 1
    ]
]

make-session-store: func [ctx [object!] /local store] [
    store: make object! [
        ctx: none
        name: none
        sessions: make map! []
        seq: 0

        safe-emit: func [session [object!] ev [map!] carrier [object! none!]] [
            try [
                either object? carrier [
                    ctx/events/emit 'session-event reduce [session ev] carrier
                ][
                    ctx/events/emit 'session-event reduce [session ev] none
                ]
            ]
            none
        ]

        create: func [/local sid s] [
            seq: seq + 1
            sid: rejoin ["s" seq]
            s: make object! [
                id: sid
                events: copy []
                live-index: 0
            ]
            put sessions sid s
            s
        ]

        create-from-log: func [events [block!] /local sid s i ev snap] [
            validate-event-log events
            seq: seq + 1
            sid: rejoin ["s" seq]
            s: make object! [
                id: sid
                events: copy []
                live-index: 0
            ]
            i: 0
            foreach ev events [
                snap: make-event-record
                    select ev 'type
                    snapshot-json-map select ev 'payload
                    i
                append s/events snap
                i: i + 1
            ]
            s/live-index: length? s/events
            put sessions sid s
            s
        ]

        find-session: func [id [string!]] [
            select sessions id
        ]

        append-event: func [
            id [string!]
            ev-type [word!]
            payload [map!]
            /dispatch-ctx dc [object!]
            /local s err snap ev carrier
        ] [
            s: find-session id
            unless s [return none]
            err: validate-payload ev-type payload
            if err [session-error err]
            snap: snapshot-json-map payload
            ev: make-event-record ev-type snap length? s/events
            append s/events ev
            carrier: if dispatch-ctx [make-scope-target scope-of dc][none]
            safe-emit s ev carrier
            ev
        ]

        events-of: func [id [string!] /local s] [
            s: find-session id
            either s [copy/deep s/events] [copy []]
        ]

        events-snapshot: func [id [string!] /local s] [
            s: find-session id
            unless s [return copy []]
            copy/deep s/events
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
                        either cid: select p 'call-id [put m 'call-id cid][]
                    ]
                    tool-result [
                        m: make map! []
                        put m 'role 'tool
                        put m 'name select p 'name
                        put m 'content any [select p 'text ""]
                        either cid: select p 'call-id [put m 'call-id cid][]
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
