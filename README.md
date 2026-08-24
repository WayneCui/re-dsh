# harness-spine

最小 agent 脊柱：挂在 `cordis-port` 内核上。装配可用代码 `boot-spine`，YAML `boot-spine-from-config`，或 profile `boot-spine-from-profile`（`profiles/` + `bundles/` 叠层）。

在 `harness-spine/` 下运行：

```
bash test/run-all.sh
r3 -s examples/echo-turn.reb
r3 -s examples/multi-step-turn.reb
r3 -s examples/full-chain.reb
r3 -s examples/profile-boot.reb
r3 -s boot-yaml.reb --dump-config
r3 -s boot-yaml.reb --profile minimal --dump-config
r3 -s boot-yaml.reb --profile full --dump-config
```

内核异步契约（thenable + delayed waterfall）：

```
cd ../cordis-port
r3 -s test/thenable-test.reb
r3 -s test/events-async-test.reb
r3 -s test/include-test.reb
r3 -s test/loader-test.reb
```

模块地图见 [ARCHITECTURE.md](ARCHITECTURE.md)。
