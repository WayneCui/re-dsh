REBOL []

if system/options/path [change-dir system/options/path]

do %../cordis-port/logger.reb
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

boot-spine: func [/llm-config llm-map [map! none!] /local root boot-default handle default-ctx llm-cfg] [
    root: make-context
    attach-scheduler root
    root/registry/plugin host-plugin none root
    root/registry/plugin session-plugin none root
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
