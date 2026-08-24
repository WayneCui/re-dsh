REBOL []

if system/options/path [change-dir system/options/path]

do %../cordis-port/logger.reb
do %../cordis-port/loader/api.reb
do %scope/api.reb
do %host/api.reb
do %session/api.reb
do %approval/api.reb
do %tools/api.reb
do %llm/api.reb
do %shell/api.reb
do %agent-loop/api.reb
do %agent/api.reb

attach-scheduler: func [ctx [object!] /local scope] [
    scope: ctx-runtime-scope ctx
    scope/scheduler: make-deterministic-scheduler
    scope/scheduler
]

shutdown-spine: func [handle [map!] /local agents root-ctx live ah] [
    root-ctx: handle/ctx
    agents: handle/agents
    if object? agents [
        live: agents/list
        foreach ah live [
            agents/dispose ah
        ]
    ]
    if object? root-ctx [
        root-ctx/fiber/dispose/dispose
    ]
    none
]

spawn-agent: func [handle [map!] label [string!] /parent parent-key [object! none!]] [
    either parent [
        handle/agents/create/parent label parent-key
    ][
        handle/agents/create label
    ]
]

; ------------------------------------------------------------
; Homomorphic reload (Phase 6)
;
; reload-agent-plugin: swap one plugin under an agent's isolate ctx.
;   Root services (sessions/llm/host) are untouched; the session log
;   survives because it lives on the root session service.
;   After the swap the agent handle's tools/driver refs are refreshed
;   (epoch reload of dependent fibers may have rebuilt them).
; ------------------------------------------------------------
refresh-agent-refs: func [agent-handle [map!] /local actx svc] [
    actx: agent-handle/ctx
    svc: actx/reflect/get 'tools false actx
    if object? svc [put agent-handle 'tools svc]
    svc: actx/reflect/get 'agent-loop false actx
    if object? svc [put agent-handle 'driver svc]
    none
]

reload-agent-plugin: func [
    agent-handle [map!]
    name [string!]
    path [file!]
    /local result
] [
    result: reload-plugin agent-handle/ctx name path
    unless equal? result true [return result]
    refresh-agent-refs agent-handle
    true
]

; reload-spine-plugin: swap a root plugin (e.g. llm), then refresh every
; live agent handle — dependent fibers epoch-reload, so service objects
; captured before the swap are stale.
reload-spine-plugin: func [
    handle [map!]
    name [string!]
    path [file!]
    /local result root svc ah
] [
    root: handle/ctx
    result: reload-plugin root name path
    unless equal? result true [return result]
    svc: root/reflect/get to-word name false root
    if object? svc [put handle to-word name svc]
    foreach ah handle/agents/list [
        refresh-agent-refs ah
        if same? ah select handle 'default-agent [
            put handle 'tools ah/tools
            put handle 'driver ah/driver
        ]
    ]
    true
]

boot-spine: func [
    /llm-config llm-map [map! none!]
    /session-config session-map [map! none!]
    /local root boot-default handle default-ctx llm-cfg session-cfg
] [
    root: make-context
    attach-scheduler root
    root/registry/plugin host-plugin none root
    session-cfg: any [session-map none]
    root/registry/plugin session-plugin session-cfg root
    root/registry/plugin approval-plugin none root
    llm-cfg: any [llm-map make map! []]
    root/registry/plugin llm-plugin llm-cfg root
    root/registry/plugin agent-plugin none root
    boot-default: create-agent-handle root "default"
    default-ctx: boot-default/ctx
    agents-svc: root/reflect/get 'agents true root
    agents-svc/register boot-default
    handle: make map! []
    put handle 'ctx root
    put handle 'root-ctx root
    put handle 'default-agent boot-default
    put handle 'agent-ctx default-ctx
    put handle 'agents agents-svc
    put handle 'host root/reflect/get 'host true root
    put handle 'sessions root/reflect/get 'sessions true root
    put handle 'approval root/reflect/get 'approval true root
    put handle 'llm root/reflect/get 'llm true root
    put handle 'tools boot-default/tools
    put handle 'driver boot-default/driver
    handle
]

print "harness-spine boot loaded"
