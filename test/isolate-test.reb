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
iso-b: spine/ctx/isolate 'tools none
iso-b/registry/plugin tools-plugin none iso-b

spine/tools/register make-who "A"
tools-b: iso-b/reflect/get 'tools true iso-b
tools-b/register make-who "B"

ra: spine/tools/execute 'whoami make map! []
rb: tools-b/execute 'whoami make map! []
assert equal? "A" select ra 'stdout "agent A whoami"
assert equal? "B" select rb 'stdout "agent B whoami"

spine/dispose
finish-tests "isolate-test"
