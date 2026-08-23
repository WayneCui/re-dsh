REBOL []

do %reply.reb

run-llm-http: func [
    host [object!]
    url [url! string!]
    messages [block!]
    tool-specs [block!]
    /local req body r
] [
    unless object? host [return none]
    req: make-llm-request messages tool-specs
    body: mold/all req
    r: host/http-post url body
    unless map? r [return none]
    unless select r 'ok [return none]
    parse-llm-reply-text any [select r 'body ""]
]
