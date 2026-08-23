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

ra: agent-a/tools/execute 'whoami make map! []
rb: agent-b/tools/execute 'whoami make map! []
assert equal? "A" select ra 'stdout "agent A whoami"
assert equal? "B" select rb 'stdout "agent B whoami"

release-agent-handle agent-a
release-agent-handle agent-b
shutdown-spine spine
finish-tests "isolate-test"
