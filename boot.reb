REBOL []

if system/options/path [change-dir system/options/path]

do %../cordis-port/logger.reb
do %scope/api.reb
do %host/api.reb
do %session/api.reb
do %tools/api.reb
do %llm/api.reb
do %shell/api.reb
do %agent-loop/api.reb

attach-scheduler: func [ctx [object!] /local scope] [
    scope: ctx-runtime-scope ctx
    scope/scheduler: make-deterministic-scheduler
    scope/scheduler
]

shutdown-spine: func [handle [map!] /local default-ctx root-ctx] [
    default-ctx: handle/agent-ctx
    root-ctx: handle/ctx
    default-ctx/fiber/dispose/dispose
    root-ctx/fiber/dispose/dispose
    none
]

spawn-agent: func [handle [map!] label [string!] /parent parent-key [object! none!]] [
    either parent [
        create-agent-handle/parent handle/root-ctx label parent-key
    ][
        create-agent-handle handle/root-ctx label
    ]
]

boot-spine: func [/local root boot-default handle default-ctx] [
    root: make-context
    attach-scheduler root
    root/registry/plugin host-plugin none root
    root/registry/plugin session-plugin none root
    root/registry/plugin llm-plugin none root
    boot-default: create-agent-handle root "default"
    default-ctx: boot-default/ctx
    handle: make map! []
    put handle 'ctx root
    put handle 'root-ctx root
    put handle 'default-agent boot-default
    put handle 'agent-ctx default-ctx
    put handle 'host root/reflect/get 'host true root
    put handle 'sessions root/reflect/get 'sessions true root
    put handle 'llm root/reflect/get 'llm true root
    put handle 'tools boot-default/tools
    put handle 'driver boot-default/driver
    handle
]

print "harness-spine boot loaded"
