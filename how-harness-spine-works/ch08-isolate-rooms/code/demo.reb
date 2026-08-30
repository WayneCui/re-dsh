REBOL []

; Chapter 08 lab: each agent isolates tools/shell/loop; session is shared;
; scoped tools-result does not leak to siblings.
; Run via code/run.sh so CWD is harness-spine/.

if system/options/path [change-dir system/options/path]
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

ra: agent-a/tools/execute 'whoami make map! []
rb: agent-b/tools/execute 'whoami make map! []
print rejoin ["WHO-A: " select ra 'stdout]
print rejoin ["WHO-B: " select rb 'stdout]

seen-a: false
seen-b: false
a-listener: func [args [block!]] [seen-a: true]
b-listener: func [args [block!]] [seen-b: true]
a-disp: agent-a/ctx/events/on 'tools-result 'a-listener none agent-a/ctx
b-disp: agent-b/ctx/events/on 'tools-result 'b-listener none agent-b/ctx

seen-a: false
seen-b: false
agent-a/tools/execute 'whoami make map! []
print rejoin ["A-HEARD-A: " mold seen-a]
print rejoin ["B-HEARD-A: " mold seen-b]

seen-a: false
seen-b: false
agent-b/tools/execute 'whoami make map! []
print rejoin ["B-HEARD-B: " mold seen-b]
print rejoin ["A-HEARD-B: " mold seen-a]
a-disp/dispose
b-disp/dispose

s: spine/sessions/create
agent-a/driver/run-turn s/id "from A"
agent-b/driver/run-turn s/id "from B"
msgs: spine/sessions/derive-messages s/id
print rejoin ["SHARED-MSGS: " mold length? msgs]
print rejoin ["FIRST-USER: " select msgs/1 'content]
print rejoin ["THIRD-USER: " select msgs/3 'content]

parent-key: mint-scope-key "parent"
child-agent: spawn-agent/parent spine "child" parent-key
attach-scope-ctx spine/ctx parent-key
parent-seen: false
parent-listener: func [args [block!]] [parent-seen: true]
p-disp: spine/ctx/events/on 'tools-result 'parent-listener none spine/ctx
child-agent/tools/register make-who "child"
child-agent/tools/execute 'whoami make map! []
print rejoin ["PARENT-HEARD-CHILD: " mold parent-seen]
p-disp/dispose

release-agent-handle agent-a
release-agent-handle agent-b
release-agent-handle child-agent
shutdown-spine spine
print "LAB-OK"
