REBOL []
; Test fixture: script LLM adapter — first complete may return bash tool-call;
; after tool messages in history, returns fixed assistant text.

req-path: none
if system/options/args [
    if 1 <= length? system/options/args [
        req-path: to-file system/options/args/1
    ]
]
unless req-path [print "error: missing request path" quit]

req: load to-string read req-path
messages: any [select req 'messages copy []]
tools: any [select req 'tools copy []]

seen-tool: false
foreach m messages [
    if equal? select m 'role 'tool [seen-tool: true]
]

last-user: ""
foreach m messages [
    if equal? select m 'role 'user [
        last-user: any [select m 'content ""]
    ]
]

reply: none
either seen-tool [
    reply: make map! []
    put reply 'kind 'text
    put reply 'text "saw the tool"
][
    has-bash: false
    foreach spec tools [
        n: select spec 'name
        if any [equal? n 'bash equal? n "bash"] [has-bash: true]
    ]
    either has-bash [
        reply: make map! []
        put reply 'kind 'tool-call
        put reply 'name 'bash
        args: make map! []
        put args 'command "echo pipeline-ok"
        put reply 'args args
    ][
        reply: make map! []
        put reply 'kind 'text
        put reply 'text last-user
    ]
]

print mold/all reply
