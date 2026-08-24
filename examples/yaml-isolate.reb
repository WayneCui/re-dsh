REBOL []

; YAML isolate demo: agents service registered under its own isolate label.
; Run from harness-spine/: r3 -s examples/yaml-isolate.reb

if system/options/path [change-dir system/options/path]
do %boot.reb
do %boot-yaml.reb

spine: boot-spine-from-config/config %examples/fixtures/cordis-isolate.yml
print ["agents service:" type? spine/agents]
print ["live agents:" length? spine/agents/list]
print ["root sees agents?" not none? spine/ctx/reflect/get 'agents false spine/ctx]

shutdown-spine spine
