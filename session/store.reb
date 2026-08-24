REBOL []

; ============================================================
; session/store.reb — file backend for append-only event logs.
;
; Format: one file per session, body = mold/all of events block.
; Does not validate events; caller (session/api) owns validation.
; ============================================================

session-store-error: func [msg [string!]] [
    cause-error 'user 'message msg
]

ensure-session-dir: func [dir [file!]] [
    unless exists? dir [
        make-dir/deep dir
    ]
    unless exists? dir [
        session-store-error rejoin ["cannot create store dir: " mold dir]
    ]
    dir
]

session-file-path: func [dir [file!] id [string!]] [
    to-file rejoin [dir id ".events.reb"]
]

make-file-session-backend: func [root-dir [file!] /local backend] [
    ensure-session-dir root-dir
    backend: make object! [
        root: root-dir

        path-of: func [id [string!]] [
            session-file-path root id
        ]

        save-session: func [id [string!] events [block!]] [
            write (path-of id) mold/all events
            none
        ]

        load-session: func [id [string!] /local path raw data] [
            path: path-of id
            unless exists? path [return none]
            raw: to-string read path
            if empty? trim copy raw [return copy []]
            data: load raw
            unless block? data [
                session-store-error rejoin ["corrupt session file: " mold path]
            ]
            data
        ]

        exists-session?: func [id [string!]] [
            not none? exists? (path-of id)
        ]

        list-ids: func [/local ids name stem] [
            ids: copy []
            foreach name read root [
                name: to-string name
                if find/last name ".events.reb" [
                    stem: copy/part name (length? name) - length? ".events.reb"
                    if not empty? stem [append ids stem]
                ]
            ]
            ids
        ]
    ]
    backend
]
