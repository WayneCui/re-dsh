REBOL []

do %../cordis-port/include/api.reb

profile-error: func [msg [string!]] [
    cause-error 'user 'message msg
]

; profiles/<name>/manifest.reb ? make map! [bundles [%path/to/bundle.patch.reb ...]]
load-profile-manifest: func [profile-dir [file!] /local path manifest] [
    path: join profile-dir %manifest.reb
    unless exists? path [
        profile-error rejoin ["profile manifest not found: " mold path]
    ]
    manifest: try [do path]
    if error? manifest [
        profile-error rejoin ["profile manifest failed: " mold path]
    ]
    unless map? manifest [
        profile-error "profile manifest must return a map"
    ]
    manifest
]

resolve-patch-file: func [path [file! string!]] [
    either file? path [path][to-file path]
]

; bundle patches ? profile cordis.patch.reb ? home ? CLI --patch files.
compose-profile-entries: func [
    profile-dir [file!]
    /home home-file [file! none!]
    /patches patch-files [block! none!]
    /local layers manifest bundle-path profile-patch-path
] [
    manifest: load-profile-manifest profile-dir
    layers: copy []
    foreach bundle-path any [select manifest 'bundles copy []] [
        append/only layers load-reb-patches resolve-patch-file bundle-path
    ]
    profile-patch-path: join profile-dir %cordis.patch.reb
    if exists? profile-patch-path [
        append/only layers load-reb-patches profile-patch-path
    ]
    if all [file? home-file  exists? home-file] [
        append/only layers load-reb-patches home-file
    ]
    if block? patch-files [
        foreach f patch-files [
            append/only layers load-reb-patches resolve-patch-file f
        ]
    ]
    compose-entry-layers layers
]

default-home-patch-path: func [/local env home] [
    env: get-env "HARNESS_HOME"
    if string? env [
        home: join to-file env %cordis.patch.reb
        if exists? home [return home]
    ]
    if exists? %cordis.patch.reb [return %cordis.patch.reb]
    none
]

profile-dir-of: func [name [string!]] [
    rejoin [%profiles/ to-file name %/]
]
