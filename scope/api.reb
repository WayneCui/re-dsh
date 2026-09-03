REBOL []

; ============================================================
; scope/api.reb � opaque scope keys for per-agent event routing.
;
; Mirrors dsh-scope minimally: mint key, parent chain, scopeTarget filter.
; ============================================================

scope-parents: make map! []
scope-labels: make map! []

scope-error: func [msg [string!]] [
    cause-error 'user 'message msg
]

scope-would-cycle?: func [child [object!] parent [object!] /local cursor] [
    cursor: parent
    while [object? cursor] [
        if same? cursor child [return true]
        cursor: select scope-parents cursor
    ]
    false
]

mint-scope-key: func [label [string!] /local key] [
    key: make object! []
    put key 'label copy label
    put scope-labels key label
    key
]

bind-scope-parent: func [child [object!] parent [object!]] [
    if select scope-parents child [
        scope-error "scope key already has a parent"
    ]
    if scope-would-cycle? child parent [
        scope-error "scope parent link would form a cycle"
    ]
    put scope-parents child parent
    none
]

scope-parent-of: func [key [object!]] [
    select scope-parents key
]

scope-chain-of: func [key [object! none!] /local chain cursor] [
    unless object? key [return copy []]
    chain: copy []
    cursor: key
    while [object? cursor] [
        append chain cursor
        cursor: select scope-parents cursor
    ]
    chain
]

scope-admits?: func [listener-key [object!] dispatch-key [object!] /local cursor] [
    cursor: dispatch-key
    while [object? cursor] [
        if same? cursor listener-key [return true]
        cursor: select scope-parents cursor
    ]
    false
]

attach-scope-ctx: func [ctx [object!] key [object!]] [
    put ctx/extra 'scope-key-ref key
    none
]

scope-ctx-parent: func [ctx [object! none!] /local fb parent pctx] [
    unless object? ctx [return none]
    fb: ctx/fiber
    unless object? fb [return none]
    parent: fb/parent
    unless object? parent [return none]
    ; Root fiber's parent is the context itself -- stop (else scope-of loops forever).
    if same? parent ctx [return none]
    if select parent 'ctx-marker [return parent]
    pctx: select parent 'ctx
    if object? pctx [return pctx]
    none
]

scope-of: func [ctx [object! none!] /local extra cursor key] [
    unless object? ctx [return none]
    cursor: ctx
    while [object? cursor] [
        extra: select cursor 'extra
        if map? extra [
            key: select extra 'scope-key-ref
            if object? key [return key]
        ]
        cursor: scope-ctx-parent cursor
    ]
    none
]

make-scope-filter-obj: func [dispatch-key [object! none!]] [
    make object! [
        dk: dispatch-key
        call: func [listener-ctx [object!]] [
            tag: scope-of listener-ctx
            either none? tag [
                true
            ][
                unless object? dk [return false]
                scope-admits? tag dk
            ]
        ]
    ]
]

make-scope-target: func [dispatch-key [object! none!] /local carrier fo] [
    fo: make-scope-filter-obj dispatch-key
    carrier: make object! [dispatch-key-ref: none filter: none]
    put carrier 'dispatch-key-ref dispatch-key
    put carrier 'filter :fo/call
    carrier
]

extend-agent-iso: func [root [object!] label [string!] /local iso-label imap props] [
    iso-label: to-word rejoin ["agent-" label]
    imap: copy any [root/isolate-map make map! []]
    put imap 'tools iso-label
    put imap 'shell iso-label
    put imap 'agent-loop iso-label
    props: make map! []
    put props 'isolate-map imap
    root/extend props
]

create-agent-handle: func [
    root [object!]
    label [string!]
    /parent parent-key [object! none!]
    /local key agent-iso tools-svc driver-svc ah
] [
    key: mint-scope-key label
    if parent [bind-scope-parent key parent-key]
    agent-iso: extend-agent-iso root label
    attach-scope-ctx agent-iso key
    agent-iso/registry/plugin tools-plugin none agent-iso
    agent-iso/registry/plugin shell-plugin none agent-iso
    agent-iso/registry/plugin loop-plugin none agent-iso
    tools-svc: agent-iso/reflect/get 'tools true agent-iso
    driver-svc: agent-iso/reflect/get 'agent-loop true agent-iso
    ; Object handle so inbox/turn methods live on the agent (not only on driver).
    ah: make object! [
        id: none
        scope-key: none
        ctx: none
        tools: none
        driver: none
        spine: none
        followup: func [text [string!]] [driver/followup text]
        steer: func [text [string!]] [driver/steer text]
        inject: func [text [string!]] [driver/inject text]
        run-turn: func [session-id [string!] user-text] [driver/run-turn session-id user-text]
        resume-turn: func [session-id [string!]] [driver/resume-turn session-id]
        cancel-turn: does [driver/cancel-turn]
    ]
    ah/id: copy label
    ah/scope-key: key
    ah/ctx: agent-iso
    ah/tools: tools-svc
    ah/driver: driver-svc
    ah
]

release-agent-handle: func [ah [object!]] [
    try [ah/driver/ctx/fiber/dispose/dispose]
    try [ah/tools/ctx/fiber/dispose/dispose]
    none
]
