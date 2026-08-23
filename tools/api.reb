REBOL []

; ============================================================
; tools/api.reb
;
; Pipeline (dsh-shaped, sync + thenable):
;   tools-pre-execute  waterfall  -> allow | deny
;   tools-execute      waterfall  -> inner runs tool body
;   tools-post-execute waterfall  -> accept | block (rewrite stdout/text)
;   tools-result       emit       -> observe frozen outcome
;
; exec map: [name args]
; tool result map: [ok code stdout stderr text error ...]
; ============================================================

tool-result-deny: func [exec [map!] reason [string!] /local m] [
    m: make map! []
    put m 'ok false
    put m 'name select exec 'name
    put m 'error reason
    m
]

pre-denied?: func [value] [
    either map? value [
        any [
            equal? select value 'kind 'deny
            equal? select value 'kind 'rejected
            equal? false select value 'ok
        ]
    ][false]
]

pre-deny-reason: func [value [map!]] [
    any [select value 'error select value 'reason "denied"]
]

pre-ask?: func [value] [
    either map? value [
        equal? select value 'kind 'ask
    ][
        false
    ]
]

ask-reason: func [value [map!]] [
    any [select value 'reason select value 'error "tool requires approval"]
]

resolve-approval-ask: func [
    ctx [object!]
    exec [map!]
    reason [string!]
    session-id [string! none!]
    call-id [string! none!]
    /local approval outcome err
] [
    approval: try [ctx/reflect/get 'approval false ctx]
    unless object? approval [
        return tool-result-deny exec any [reason "approval unavailable"]
    ]
    unless string? session-id [
        return tool-result-deny exec "approval ask requires session"
    ]
    outcome: try [approval/request session-id select exec 'name call-id reason]
    if error? outcome [
        return tool-result-deny exec form outcome
    ]
    either equal? outcome 'allowed-once [
        none
    ][
        err: switch outcome [
            rejected [rejoin ["user rejected tool " to-string select exec 'name]]
            cancelled [rejoin ["approval cancelled for tool " to-string select exec 'name]]
            unavailable [rejoin ["approval unavailable for tool " to-string select exec 'name]]
        ]
        tool-result-deny exec any [err "approval denied"]
    ]
]

make-tools-service: func [ctx [object!] /local svc] [
    svc: make object! [
        ctx: none
        name: none
        registry: make map! []
        result-log: copy []

        scheduler-of: func [/local scope] [
            scope: ctx-runtime-scope ctx
            select scope 'scheduler
        ]

        settle: func [value] [
            thenable-wait value scheduler-of
        ]

        scope-carrier: func [] [
            make-scope-target scope-of ctx
        ]

        register: func [spec [object!] /local n ex dobj inner] [
            n: spec/name
            put registry n spec
            ex: func [] [
                make object! [
                    owner: none
                    n: none
                    dispose: func [] [
                        if owner [
                            owner/registry: map-remove-key owner/registry n
                        ]
                        none
                    ]
                ]
            ]
            dobj: ctx/fiber/effect :ex rejoin ["tool:" to-string n]
            inner: first dobj/items
            inner/owner: self
            inner/n: n
            dobj
        ]

        list: func [/local specs] [
            specs: copy []
            foreach [n spec] registry [append specs spec]
            specs
        ]

        emit-result: func [exec [map!] result [map!] /local carrier] [
            append result-log reduce [exec result]
            carrier: scope-carrier
            ctx/events/emit 'tools-result reduce [exec result] carrier
            none
        ]

        execute: func [
            tool-name [word!]
            args
            /meta meta-map [map! none!]
            /local spec exec pre-inner exec-inner post-inner pre-out body-out final carrier deny ap sid cid
        ] [
            spec: select registry tool-name
            unless spec [
                exec: make map! []
                put exec 'name tool-name
                put exec 'args args
                final: tool-result-deny exec "unknown-tool"
                emit-result exec final
                return final
            ]

            exec: make map! []
            put exec 'name tool-name
            put exec 'args args
            sid: none
            cid: none
            if map? meta-map [
                sid: select meta-map 'session-id
                cid: select meta-map 'call-id
            ]

            carrier: scope-carrier

            pre-inner: make object! [
                call: func [arg-block [block!] this-arg [object! none!] /local m] [
                    m: make map! []
                    put m 'kind 'allow
                    m
                ]
            ]
            pre-out: settle ctx/events/waterfall 'tools-pre-execute reduce [exec] pre-inner carrier
            if pre-denied? pre-out [
                final: tool-result-deny exec pre-deny-reason pre-out
                emit-result exec final
                return final
            ]
            unless pre-ask? pre-out [
                ap: any [select spec 'approval 'allow]
                if equal? ap 'ask [
                    pre-out: make map! []
                    put pre-out 'kind 'ask
                    put pre-out 'reason any [select spec 'approval-reason "tool requires approval"]
                ]
            ]
            if pre-ask? pre-out [
                deny: resolve-approval-ask ctx exec ask-reason pre-out sid cid
                if map? deny [
                    emit-result exec deny
                    return deny
                ]
            ]

            exec-inner: make object! [
                spec-ref: spec
                args-ref: args
                call: func [arg-block [block!] this-arg [object! none!]] [
                    spec-ref/run/call args-ref
                ]
            ]
            body-out: settle ctx/events/waterfall 'tools-execute reduce [exec] exec-inner carrier

            post-inner: make object! [
                call: func [arg-block [block!] this-arg [object! none!]] [
                    arg-block/2
                ]
            ]
            final: settle ctx/events/waterfall 'tools-post-execute reduce [exec body-out] post-inner carrier
            if map? final [
                if any [select final 'text select final 'stdout] [
                    unless select final 'name [put final 'name tool-name]
                ]
            ]
            emit-result exec final
            final
        ]
    ]
    svc/ctx: ctx
    svc
]

tools-plugin: make object! [
    name: "tools"
    inject: []
    apply: func [ctx [object!] config] [
        make-service ctx 'tools make-tools-service ctx
        none
    ]
]
