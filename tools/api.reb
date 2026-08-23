REBOL []

; ============================================================
; tools/api.reb
;
; Provides ctx service 'tools:
;   register spec [object! name description run/call] -> disposer
;   list -> block of specs
;   execute name args -> map! or thenable (waterfall 'tools-execute)
;
; Waterfall args: [exec next] where exec is map [name args]
; Inner runs spec/run/call args.
; ============================================================

make-tools-service: func [ctx [object!] /local svc] [
    svc: make object! [
        ctx: none
        name: none
        registry: make map! []

        register: func [spec [object!] /local n ex dobj] [
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
            ; effect wraps the disposer; fields live on the inner item
            inner: first dobj/items
            inner/owner: self
            inner/n: n
            dobj
        ]

        list: func [/local specs spec] [
            specs: copy []
            foreach [n spec] registry [append specs spec]
            specs
        ]

        execute: func [tool-name [word!] args /local spec inner exec] [
            spec: select registry tool-name
            unless spec [
                exec: make map! []
                put exec 'ok false
                put exec 'error "unknown-tool"
                put exec 'name tool-name
                return exec
            ]
            inner: make object! [
                spec-ref: spec
                args-ref: args
                call: func [arg-block [block!] this-arg [object! none!]] [
                    spec-ref/run/call args-ref
                ]
            ]
            exec: make map! []
            put exec 'name tool-name
            put exec 'args args
            ctx/events/waterfall 'tools-execute reduce [exec] inner none
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
