REBOL []

do %./json.reb
do %./store.reb

; ============================================================
; session/api.reb
;
; Append-only event log with hardened payloads and replay from seed.
; Optional file backend via config store-dir (see session/store.reb).
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
    approval-asked approval-decided approval-policy
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
        approval-asked [
            unless string? any [select payload 'id][
                return "approval-asked requires string id"
            ]
            unless string? any [select payload 'tool-name][
                return "approval-asked requires tool-name"
            ]
            cid: select payload 'call-id
            unless any [none? cid string? cid][
                return "approval-asked call-id must be string"
            ]
            r: select payload 'reason
            unless any [none? r string? r][
                return "approval-asked reason must be string"
            ]
        ]
        approval-decided [
            unless string? any [select payload 'id][
                return "approval-decided requires string id"
            ]
            o: select payload 'outcome
            unless any [word? o string? o][
                return "approval-decided requires outcome"
            ]
        ]
        approval-policy [
            p: select payload 'policy
            unless any [equal? p 'ask equal? p 'never][
                return "approval-policy must be ask or never"
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

note-session-seq: func [store [object!] id [string!] /local n] [
    if all [
        string? id
        #"s" = id/1
        integer? try [n: to-integer copy next id]
    ][
        if n > store/seq [store/seq: n]
    ]
    none
]

resolve-store-backend: func [cfg /local dir] [
    unless map? cfg [return none]
    dir: any [select cfg 'store-dir select cfg "store-dir"]
    if string? dir [dir: to-file dir]
    either file? dir [make-file-session-backend dir][none]
]

make-session-store: func [
    ctx [object!]
    /config cfg [map! none!]
    /local store backend
] [
    backend: resolve-store-backend any [cfg none]
    store: make object! [
        ctx: none
        name: none
        sessions: make map! []
        seq: 0
        backend: none

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

        persist!: func [s [object!]] [
            if object? backend [
                backend/save-session s/id s/events
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
            persist! s
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
            persist! s
            s
        ]

        find-session: func [id [string!]] [
            select sessions id
        ]

        open: func [session-id [string!] /local events s i ev snap] [
            s: find-session session-id
            if object? s [return s]
            unless object? backend [
                session-error "open requires store-dir backend"
            ]
            events: backend/load-session session-id
            unless block? events [return none]
            validate-event-log events
            s: make object! [
                id: none
                events: copy []
                live-index: 0
            ]
            put s 'id session-id
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
            put sessions session-id s
            note-session-seq self session-id
            s
        ]

        save: func [session-id [string!] /local s] [
            s: find-session session-id
            unless object? s [return none]
            unless object? backend [
                session-error "save requires store-dir backend"
            ]
            persist! s
            s
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
            persist! s
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
    store/backend: backend
    if object? backend [
        foreach id backend/list-ids [note-session-seq store id]
    ]
    store
]

session-plugin: make object! [
    name: "session"
    inject: []
    apply: func [ctx [object!] config] [
        either map? config [
            make-service ctx 'sessions make-session-store/config ctx config
        ][
            make-service ctx 'sessions make-session-store ctx
        ]
        none
    ]
]
