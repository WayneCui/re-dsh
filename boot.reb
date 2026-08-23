REBOL []

; ============================================================
; boot.reb — programmatic plugin tree. No YAML loader.
;
; Run from harness-spine/:
;   r3 -s boot.reb          (loads, prints ok)
;   do %boot.reb  then  spine: boot-spine
; ============================================================

if system/options/path [change-dir system/options/path]

do %../cordis-port/logger.reb
do %host/api.reb
do %session/api.reb
do %tools/api.reb
do %llm/api.reb
do %shell/api.reb
do %agent-loop/api.reb

; Attach a deterministic scheduler so thenable-wait can pump delays.
attach-scheduler: func [ctx [object!] /local scope] [
    scope: ctx-runtime-scope ctx
    scope/scheduler: make-deterministic-scheduler
    scope/scheduler
]

boot-spine: func [/local root iso handle] [
    root: make-context
    attach-scheduler root
    root/registry/plugin host-plugin none root
    root/registry/plugin session-plugin none root
    root/registry/plugin llm-plugin none root
    iso: root/isolate 'tools none
    iso/registry/plugin tools-plugin none iso
    iso/registry/plugin shell-plugin none iso
    iso/registry/plugin loop-plugin none iso
    handle: make object! [
        ctx: root
        agent-ctx: iso
        host: none
        sessions: none
        tools: none
        llm: none
        driver: none
        dispose: func [] [
            ctx/fiber/dispose/dispose
            none
        ]
    ]
    handle/host: root/reflect/get 'host true root
    handle/sessions: root/reflect/get 'sessions true root
    handle/llm: root/reflect/get 'llm true root
    handle/tools: iso/reflect/get 'tools true iso
    handle/driver: iso/reflect/get 'agent-loop true iso
    handle
]

print "harness-spine boot loaded"
