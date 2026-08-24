REBOL []

; YAML-driven boot + --dump-config (Phase 3).
;   r3 -s boot-yaml.reb --dump-config
;   r3 -s boot-yaml.reb --dump-config cordis.yml

if system/options/path [change-dir system/options/path]

do %boot.reb
do %../cordis-port/loader/api.reb
do %profile.reb

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

parse-boot-args: func [/local args mode file patches profile] [
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
    profile: none
    while [all [block? args  not empty? args]] [
        either args/1 = "--dump-config" [
            mode: 'dump
            args: next args
            if all [block? args  not empty? args  string? args/1] [
                file: to-file args/1
                args: next args
            ]
        ][
            either args/1 = "--profile" [
                args: next args
                unless all [block? args  not empty? args  string? args/1] [break]
                profile: args/1
                args: next args
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
    ]
    m: make map! []
    put m 'mode mode
    put m 'file file
    put m 'patches patches
    put m 'profile profile
    m
]

compose-spine-entries: func [
    /config config-file [file!]
    /profile profile-name [string! none!]
    /patches patch-files [block! none!]
    /local home
] [
    home: default-home-patch-path
    either string? profile-name [
        either home [
            compose-profile-entries/home/patches profile-dir-of profile-name home any [patch-files []]
        ][
            compose-profile-entries/patches profile-dir-of profile-name any [patch-files []]
        ]
    ][
        either patches [
            compose-entry-config/patches any [config-file default-config-file] any [patch-files []]
        ][
            compose-entry-config any [config-file default-config-file]
        ]
    ]
]

dump-spine-config: func [
    /config config-file [file!]
    /profile profile-name [string! none!]
    /patches patch-files [block! none!]
] [
    entries: compose-spine-entries/config/profile/patches
        any [config-file default-config-file]
        profile-name
        any [patch-files []]
    print dump-entry-block entries
    none
]

boot-spine-from-config: func [
    /config config-file [file!]
    /profile profile-name [string! none!]
    /patches patch-files [block! none!]
    /local root entries boot-default default-ctx agents-svc handle plugin-map
] [
    entries: compose-spine-entries/config/profile/patches
        any [config-file default-config-file]
        profile-name
        any [patch-files []]
    root: make-context
    attach-scheduler root
    plugin-map: make-spine-plugin-map
    isolated-ctxs: make map! []
    mount-entry-list-with-isolate: func [
        ctx [object!]
        entries [block!]
        plugin-map [map!]
        /local item plugin plugin-name cfg sub target
    ] [
        foreach item entries [
            if entry-disabled? item [continue]
            if entry-group? item [
                sub: entry-config-of item
                if block? sub [mount-entry-list-with-isolate ctx sub plugin-map]
                continue
            ]
            plugin-name: entry-plugin-name item
            plugin: select plugin-map plugin-name
            unless object? plugin [
                loader-error rejoin ["unknown plugin: " mold plugin-name]
            ]
            cfg: entry-config-of item
            target: entry-mount-ctx ctx item
            if not same? target ctx [
                put isolated-ctxs plugin-name target
            ]
            target/registry/plugin plugin any [cfg none] target
        ]
        none
    ]
    mount-entry-list-with-isolate root entries plugin-map
    boot-default: create-agent-handle root "default"
    default-ctx: boot-default/ctx
    agents-svc: root/reflect/get 'agents true root
    unless object? agents-svc [
        ; YAML isolate may register agents under a label; fall back to the isolated ctx.
        iso: select isolated-ctxs 'agents
        if object? iso [
            agents-svc: iso/reflect/get 'agents true iso
        ]
    ]
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

boot-spine-from-profile: func [
    profile-name [string!]
    /patches patch-files [block! none!]
] [
    boot-spine-from-config/profile/patches profile-name any [patch-files []]
]

cli: parse-boot-args
either cli/mode = 'dump [
    dump-spine-config/config/profile/patches cli/file cli/profile cli/patches
][
    print "harness-spine boot-yaml loaded"
]
