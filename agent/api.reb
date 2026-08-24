REBOL []

; ============================================================
; agent/api.reb — live agent registry (create / dispose / lookup).
;
; Wraps scope/create-agent-handle with a root-level registry and
; agent-created / agent-disposed emits.
; ============================================================

agent-error: func [msg [string!]] [
    cause-error 'user 'message msg
]

make-agent-registry: func [ctx [object!] root-ctx [object!] /local svc] [
    svc: make object! [
        ctx: none
        name: none
        root-ctx: none
        live: make map! []

        emit-created: func [handle [object!]] [
            try [ctx/events/emit 'agent-created reduce [handle] none]
            none
        ]

        emit-disposed: func [handle [object!]] [
            try [ctx/events/emit 'agent-disposed reduce [handle] none]
            none
        ]

        register: func [handle [object!] /local id] [
            id: handle/id
            unless string? id [agent-error "agent handle missing id"]
            put live id handle
            none
        ]

        get: func [id [string!]] [
            select live id
        ]

        list: func [/local out] [
            out: copy []
            foreach [k v] live [append out v]
            out
        ]

        create: func [label [string!] /parent parent-key [object! none!] /local handle] [
            handle: either parent [
                create-agent-handle/parent root-ctx label parent-key
            ][
                create-agent-handle root-ctx label
            ]
            put live handle/id handle
            emit-created handle
            handle
        ]

        dispose: func [handle [object!] /local id driver] [
            unless object? handle [return none]
            id: handle/id
            unless select live id [return none]
            driver: select handle 'driver
            if object? driver [
                try [driver/cancel-turn]
            ]
            emit-disposed handle
            live: map-remove-key live id
            release-agent-handle handle
            none
        ]
    ]
    svc/ctx: ctx
    svc/root-ctx: root-ctx
    svc
]

agent-plugin: make object! [
    name: "agents"
    inject: []
    apply: func [ctx [object!] config /local svc] [
        svc: make-agent-registry ctx ctx
        make-service ctx 'agents svc
        none
    ]
]
