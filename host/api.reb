REBOL []

; ============================================================
; host/api.reb
;
; Provides ctx service 'host:
;   run-command / http-get / http-post
;   http-post-stream source body /on-line sink /cancel cancel-obj
;     -> map [ok cancelled body error]
;     file!: response fixture on disk
;     url!: curl -N to tempfile; cancel kills curl pid
;   delay / settle
; ============================================================

host-cancelled?: func [cancel-obj] [
    all [object? cancel-obj  cancel-obj/call]
]

host-flush-line: func [sink line [string!]] [
    line: trim/tail copy line
    if all [string? line  not empty? line  object? sink] [
        sink/call line
    ]
    none
]

; Emit complete lines from text; return 'cancelled or 'ok.
host-emit-lines: func [
    text [string!]
    sink
    cancel-obj
    /local lines line
] [
    lines: split text "^/"
    foreach line lines [
        if host-cancelled? cancel-obj [return 'cancelled]
        host-flush-line sink line
    ]
    either host-cancelled? cancel-obj ['cancelled]['ok]
]

; Append chunk to buf, emit complete lines. /final flushes remainder.
; Returns [status buf] as reduce block: status 'ok|'cancelled, buf leftover string.
host-drain-buf: func [
    buf [string!]
    chunk [string!]
    sink
    cancel-obj
    /final
    /local p
] [
    append buf chunk
    while [p: find buf "^/"] [
        if host-cancelled? cancel-obj [
            return reduce ['cancelled buf]
        ]
        host-flush-line sink copy/part buf p
        buf: copy next p
    ]
    if final [
        unless empty? buf [
            host-flush-line sink buf
            buf: copy ""
        ]
    ]
    either host-cancelled? cancel-obj [
        reduce ['cancelled buf]
    ][
        reduce ['ok buf]
    ]
]

host-pid-alive?: func [host-svc pid [string!] /local r] [
    unless all [string? pid  not empty? pid] [return false]
    r: host-svc/run-command rejoin ["kill -0 " pid " 2>/dev/null"]
    equal? 0 select r 'code
]

host-kill-pid: func [pid [string!]] [
    if all [string? pid  not empty? pid] [
        try [call/wait/shell rejoin ["kill " pid " 2>/dev/null"]]
    ]
    none
]

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
                put result 'body ""
                put result 'error form body
            ][
                put result 'ok true
                put result 'body body
            ]
            result
        ]

        http-post: func [url [url! string!] body [string!] /local tmp cmd out err code result] [
            tmp: to-file rejoin ["http-post-" random 999999 ".txt"]
            write tmp body
            cmd: rejoin ["curl -s -S -X POST --data-binary @" tmp " " mold url]
            out: copy ""
            err: copy ""
            code: try [call/wait/shell/output/error cmd out err]
            try [delete tmp]
            result: make map! []
            either error? code [
                put result 'ok false
                put result 'error form code
            ][
                put result 'ok equal? code 0
                put result 'code code
                put result 'body out
                put result 'stderr err
            ]
            result
        ]

        http-post-stream: func [
            source [url! file! string!]
            body [string!]
            /on-line sink
            /cancel cancel-obj
            /local result body-text st tmp outfile pidfile cmd launch pid seen buf chunk drained n sched item self-ref
        ] [
            result: make map! []
            put result 'ok false
            put result 'cancelled false
            put result 'body ""
            self-ref: self

            if host-cancelled? cancel-obj [
                put result 'cancelled true
                put result 'ok true
                return result
            ]

            either file? source [
                body-text: try [read/string source]
                if error? body-text [
                    put result 'error form body-text
                    return result
                ]
                put result 'body body-text
                st: host-emit-lines body-text sink cancel-obj
                put result 'cancelled equal? st 'cancelled
                put result 'ok true
                return result
            ][
                tmp: to-file rejoin ["http-stream-in-" random 999999 ".txt"]
                outfile: to-file rejoin ["http-stream-out-" random 999999 ".txt"]
                pidfile: to-file rejoin ["http-stream-pid-" random 999999 ".txt"]
                write tmp body
                write outfile ""
                cmd: rejoin [
                    "curl -s -S -N -X POST --data-binary @" tmp
                    " -o " outfile " "
                    mold either url? source [source][to-url source]
                    " & echo $! > " pidfile
                ]
                launch: try [call/wait/shell cmd]
                if error? launch [
                    try [delete tmp]
                    try [delete outfile]
                    try [delete pidfile]
                    put result 'error form launch
                    return result
                ]
                pid: trim any [attempt [read/string pidfile] ""]
                seen: 0
                buf: copy ""
                n: 0
                sched: scheduler-of
                while [n < 10000] [
                    if host-cancelled? cancel-obj [
                        host-kill-pid pid
                        put result 'cancelled true
                        break
                    ]
                    body-text: any [attempt [read/string outfile] ""]
                    if (length? body-text) > seen [
                        chunk: copy/part skip body-text seen ((length? body-text) - seen)
                        seen: length? body-text
                        drained: host-drain-buf buf chunk sink cancel-obj
                        buf: drained/2
                        if equal? drained/1 'cancelled [
                            host-kill-pid pid
                            put result 'cancelled true
                            break
                        ]
                    ]
                    either host-pid-alive? self-ref pid [
                        either all [object? sched  sched/pending?] [
                            item: sched/next-item
                            if item [sched/run-until item/due]
                        ][
                            try [call/wait/shell "sleep 0.01"]
                        ]
                    ][
                        body-text: any [attempt [read/string outfile] ""]
                        if (length? body-text) > seen [
                            chunk: copy/part skip body-text seen ((length? body-text) - seen)
                            seen: length? body-text
                            drained: host-drain-buf/final buf chunk sink cancel-obj
                            buf: drained/2
                            if equal? drained/1 'cancelled [
                                put result 'cancelled true
                            ]
                        ][
                            drained: host-drain-buf/final buf "" sink cancel-obj
                            if equal? drained/1 'cancelled [
                                put result 'cancelled true
                            ]
                        ]
                        break
                    ]
                    n: n + 1
                ]
                body-text: any [attempt [read/string outfile] ""]
                put result 'body body-text
                put result 'ok true
                try [delete tmp]
                try [delete outfile]
                try [delete pidfile]
                result
            ]
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
