REBOL []

do %reply.reb

path-absolute?: func [p [string!]] [
    any [find p "/" = 1  find p ":"]
]

llm-abs-path: func [p [file! string!] /local s] [
    s: to-string p
    either path-absolute? s [to-file s][
        join any [system/options/path %./] p
    ]
]

shell-quote-path: func [p [file! string!]] [
    replace/all to-string p "%" ""
]

run-llm-script: func [
    host [object!]
    script-path [file! string!]
    messages [block!]
    tool-specs [block!]
    /local req req-file script-file cmd r
] [
    unless object? host [return none]
    req: make-llm-request messages tool-specs
    req-file: llm-abs-path to-file rejoin ["llm-req-" random 999999 ".reb"]
    script-file: llm-abs-path script-path
    write req-file mold/all req
    cmd: rejoin [{r3 -q "} shell-quote-path script-file {" "} shell-quote-path req-file {"}]
    r: host/run-command cmd
    try [delete req-file]
    unless map? r [return none]
    unless select r 'ok [return none]
    parse-llm-reply-text any [select r 'stdout ""]
]
