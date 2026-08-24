REBOL []

passed: 0
failed: 0

assert: func [cond [logic!] label [string!]] [
    either cond [
        passed: passed + 1
        print rejoin ["PASS  " label]
    ][
        failed: failed + 1
        print rejoin ["FAIL  " label]
    ]
]

finish-tests: func [suite [string!]] [
    print rejoin ["^/==== " suite ": " passed " passed, " failed " failed ===="]
    if failed > 0 [quit 1]
]

capture-output: func [block [block!] /local out] [
    out: copy ""
    ; TODO: no shell redirect in-process; rely on direct probe instead
    do block
    out
]
