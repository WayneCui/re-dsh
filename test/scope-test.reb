REBOL []
if system/options/path [change-dir system/options/path]
do %test/assert.reb
do %boot.reb

make-who: func [id [string!] /local spec] [
    spec: make object! [
        name: 'whoami
        description: "identity"
        run: make object! [
            id-ref: none
            call: func [args /local m] [
                m: make map! []
                put m 'ok true
                put m 'stdout id-ref
                m
            ]
        ]
    ]
    spec/run/id-ref: id
    spec
]

spine: boot-spine
agent-a: spawn-agent spine "A"
agent-b: spawn-agent spine "B"
agent-a/tools/register make-who "A"
agent-b/tools/register make-who "B"

; ---- scoped tools-result: siblings do not cross ----
seen-a: false
seen-b: false
a-listener: func [args [block!]] [seen-a: true]
b-listener: func [args [block!]] [seen-b: true]
a-disp: agent-a/ctx/events/on 'tools-result 'a-listener none agent-a/ctx
b-disp: agent-b/ctx/events/on 'tools-result 'b-listener none agent-b/ctx

seen-a: false
seen-b: false
agent-a/tools/execute 'whoami make map! []
assert seen-a "A listener sees A execute"
assert equal? false seen-b "B listener ignores A execute"

seen-a: false
seen-b: false
agent-b/tools/execute 'whoami make map! []
assert seen-b "B listener sees B execute"
assert equal? false seen-a "A listener ignores B execute"
a-disp/dispose
b-disp/dispose

; ---- same session, two agents, different tool sets ----
s: spine/sessions/create
agent-a/driver/run-turn s/id "from A"
agent-b/driver/run-turn s/id "from B"
msgs: spine/sessions/derive-messages s/id
assert equal? 4 length? msgs "shared session: two turns of user+assistant"
assert equal? "from A" select msgs/1 'content "first user message"
assert equal? "from B" select msgs/3 'content "second user message"

; ---- parent scope hears child dispatch ----
parent-key: mint-scope-key "parent"
child-agent: spawn-agent/parent spine "child" parent-key
attach-scope-ctx spine/ctx parent-key
parent-seen: false
parent-listener: func [args [block!]] [parent-seen: true]
p-disp: spine/ctx/events/on 'tools-result 'parent-listener none spine/ctx
child-agent/tools/register make-who "child"
child-agent/tools/execute 'whoami make map! []
assert parent-seen "parent scope hears child tools-result"
p-disp/dispose

release-agent-handle agent-a
release-agent-handle agent-b
release-agent-handle child-agent
shutdown-spine spine
finish-tests "scope-test"
