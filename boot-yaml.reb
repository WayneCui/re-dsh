REBOL []

; YAML-driven boot + --dump-config (Phase 3).
;   r3 -s boot-yaml.reb --dump-config
;   r3 -s boot-yaml.reb --dump-config cordis.yml

if system/options/path [change-dir system/options/path]

do %boot.reb
do %../cordis-port/loader/api.reb

make-spine-plugin-map: func [] [
    m: make map! []
    put m 'host host-plugin
    put m 'session session-plugin
    put m 'approval approval-plugin
    put m 'llm llm-plugin
    put m 'agents agent-plugin
    m
]

default-config-file: %cordis.yml

parse-boot-args: func [/local args mode file patches] [
    args: copy []
    if all [block? system/options/args  not empty? system/options/args] [
        args: system/options/args
    ]
    if all [block? system/script/args  not empty? system/script/args] [
        args: system/script/args
    ]
    mode: 'boot
    file: default-config-file
    patches: copy []
    while [all [block? args  not empty? args]] [
        either args/1 = "--dump-config" [
            mode: 'dump
            args: next args
            if all [block? args  not empty? args  string? args/1] [
                file: to-file args/1
                args: next args
            ]
        ][
            either args/1 = "--patch" [
                args: next args
                unless all [block? args  not empty? args] [break]
                append patches to-file args/1
                args: next args
            ][
                break
            ]
        ]
    ]
    m: make map! []
    put m 'mode mode
    put m 'file file
    put m 'patches patches
    m
]

compose-spine-entries: func [
    /config config-file [file!]
    /patches patch-files [block! none!]
] [
    either patches [
        compose-entry-config/patches any [config-file default-config-file] any [patch-files []]
    ][
        compose-entry-config any [config-file default-config-file]
    ]
]

dump-spine-config: func [
    /config config-file [file!]
    /patches patch-files [block! none!]
] [
    entries: either patches [
        compose-spine-entries/config/patches any [config-file default-config-file] any [patch-files []]
    ][
        compose-spine-entries/config any [config-file default-config-file]
    ]
    print dump-entry-block entries
    none
]

boot-spine-from-config: func [
    /config config-file [file!]
    /patches patch-files [block! none!]
    /local root entries boot-default default-ctx agents-svc handle plugin-map
] [
    entries: either patches [
        compose-spine-entries/config/patches any [config-file default-config-file] any [patch-files []]
    ][
        compose-spine-entries/config any [config-file default-config-file]
    ]
    root: make-context
    attach-scheduler root
    plugin-map: make-spine-plugin-map
    mount-entry-list root entries plugin-map
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

cli: parse-boot-args
either cli/mode = 'dump [
    either empty? cli/patches [
        dump-spine-config/config cli/file
    ][
        dump-spine-config/config/patches cli/file cli/patches
    ]
][
    print "harness-spine boot-yaml loaded"
]
