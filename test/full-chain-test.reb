REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot-yaml.reb

has-type?: func [types [block!] t [word!]] [
    not none? find types t
]

event-types: func [sessions id /local types ev] [
    types: copy []
    foreach ev sessions/events-of id [append types select ev 'type]
    types
]

store-dir: %test/tmp-full-chain-store/
wipe-store: does [
    if exists? store-dir [
        foreach f read store-dir [
            try [delete to-file rejoin [store-dir f]]
        ]
        try [delete store-dir]
    ]
]
wipe-store

cfg: %examples/full-chain.yml

print "^/---- 1 YAML compose ----"
entries: compose-spine-entries/config cfg
dump: dump-entry-block entries
assert not none? find dump "id: host" "dump lists host"
assert not none? find dump "store-dir" "dump lists session store-dir"
assert not none? find dump "full-chain-llm" "dump lists llm script"

print "^/---- 2 YAML boot: tool + stream turn ----"
spine1: boot-spine-from-config/config cfg
assert object? spine1/sessions/backend "yaml boot mounted file backend"
s: spine1/sessions/create
sid: s/id
out: spine1/driver/run-turn sid "run full chain"
assert equal? 'text select out 'status "turn status text"
assert equal? "full-chain-ok" select out 'text "streamed follow-up text"
assert equal? 2 select out 'steps "tool + follow-up = 2 steps"

types: event-types spine1/sessions sid
assert has-type? types 'tool-call "logged tool-call"
assert has-type? types 'tool-result "logged tool-result"
assert has-type? types 'assistant-chunk "logged stream chunks"
assert has-type? types 'assistant-message "logged final assistant"

msgs: spine1/sessions/derive-messages sid
roles: copy []
foreach m msgs [append roles select m 'role]
assert equal? [user assistant tool assistant] roles "derive: user, tool-call, result, assistant"
assert equal? "full-chain-ok" select msgs/4 'content "derive folds chunks to final text"
live-msgs: copy/deep msgs
shutdown-spine spine1

print "^/---- 3 persist: reboot + open ----"
spine2: boot-spine-from-config/config cfg
assert none? spine2/sessions/find-session sid "memory empty after reboot"
opened: spine2/sessions/open sid
assert object? opened "open restores session"
assert equal? live-msgs spine2/sessions/derive-messages sid "derive matches across reboot"

print "^/---- 4 fork + resume-turn ----"
branch: spine2/sessions/fork sid
assert equal? sid (select branch 'forked-from) "forked-from parent"
assert equal? live-msgs spine2/sessions/derive-messages branch/id "branch starts at parent cut"
resume-reply: make map! []
put resume-reply 'kind 'text
put resume-reply 'text "from-branch"
put resume-reply 'chunks ["from-" "branch"]
spine2/llm/enqueue resume-reply
bout: spine2/driver/resume-turn branch/id
assert equal? "from-branch" select bout 'text "resume streamed text"
assert equal? live-msgs spine2/sessions/derive-messages sid "parent unchanged after branch resume"
b-roles: copy []
foreach m spine2/sessions/derive-messages branch/id [append b-roles select m 'role]
assert equal? [user assistant tool assistant assistant] b-roles "resume appends assistant, not user"
shutdown-spine spine2

print "^/---- 5 cancel mid delayed tool ----"
spine3: boot-spine-from-config/config cfg
delay-tool: make object! [
    name: 'slow
    description: "cancels then returns a delayed thenable"
    run: make object! [
        drv: spine3/driver
        host-ref: spine3/host
        call: func [args] [
            drv/cancel-turn
            host-ref/delay 20 "late"
        ]
    ]
]
spine3/tools/register delay-tool
tc: make map! []
put tc 'kind 'tool-call
put tc 'name 'slow
put tc 'args make map! []
spine3/llm/enqueue tc
s3: spine3/sessions/create
out3: spine3/driver/run-turn s3/id "go slow"
assert equal? 'cancelled select out3 'status "delayed settle cancelled"
tr: none
foreach ev spine3/sessions/events-of s3/id [
    if equal? select ev 'type 'tool-result [tr: select ev 'payload]
]
assert equal? true select tr 'cancelled "cancelled tool-result"

print "^/---- 6 HTTP stream fixture + abort ----"
shutdown-spine spine3
spine4: boot-spine/llm-config make map! [http-url %test/fixtures/llm-http-stream.txt]
seen: copy []
state: make object! [n: 0]
sink: make object! [
    st: state
    call: func [text [string!]] [
        st/n: st/n + 1
        append seen text
    ]
]
cancel: make object! [
    st: state
    call: func [] [st/n >= 1]
]
aborted: spine4/llm/stream/on-chunk/cancel copy [] copy [] sink cancel
assert equal? true select aborted 'cancelled "http stream aborted"
assert equal? ["hel"] seen "only first http delta"

s4: spine4/sessions/create
hout: spine4/driver/run-turn s4/id "http"
assert equal? "hello" select hout 'text "http stream turn text"
assert has-type? (event-types spine4/sessions s4/id) 'assistant-chunk "http turn logged chunks"
shutdown-spine spine4

wipe-store
finish-tests "full-chain-test"
