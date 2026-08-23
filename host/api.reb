REBOL []

; ============================================================
; host/api.reb
;
; Provides ctx service 'host:
;   run-command command [string!] -> map [ok code stdout stderr]
;   http-get source [url! file!] -> map
;   delay ms value -> thenable (scheduler) or value
;   settle value -> thenable-wait against this ctx's scheduler
; ============================================================

make-host-service: func [ctx [object!] /local svc] [
    svc: make object! [
        ctx: none
        name: none

        scheduler-of: func [/local scope] [
            scope: ctx-runtime-scope ctx
            select scope 'scheduler
        ]

        run-command: func [command [string!] /local out err code result] [
            out: copy ""
            err: copy ""
            code: try [call/wait/shell/output/error command out err]
            result: make map! []
            either error? code [
                put result 'ok false
                put result 'code -1
                put result 'stdout ""
                put result 'stderr form code
            ][
                put result 'ok equal? code 0
                put result 'code code
                put result 'stdout out
                put result 'stderr err
            ]
            result
        ]

        http-get: func [source [url! file!] /local body result] [
            body: try [read/string source]
            result: make map! []
            either error? body [
                put result 'ok false
                put result 'error form body
            ][
                put result 'ok true
                put result 'body body
            ]
            result
        ]

        delay: func [ms [integer!] value /local sched] [
            sched: scheduler-of
            either object? sched [
                thenable-delay sched ms value
            ][
                thenable-of value
            ]
        ]

        settle: func [value] [
            thenable-wait value scheduler-of
        ]
    ]
    svc/ctx: ctx
    svc
]

host-plugin: make object! [
    name: "host"
    inject: []
    apply: func [ctx [object!] config] [
        make-service ctx 'host make-host-service ctx
        none
    ]
]
