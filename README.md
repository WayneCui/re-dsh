# harness-spine

最小 agent 脊柱：挂在 `cordis-port` 内核上，用代码 `plugin()` 装配，不引入 YAML Loader。

在 `harness-spine/` 下运行：

```
bash test/run-all.sh
r3 -s examples/echo-turn.reb
```

内核异步契约（thenable + delayed waterfall）：

```
cd ../cordis-port
r3 -s test/thenable-test.reb
r3 -s test/events-async-test.reb
```

模块地图见 [ARCHITECTURE.md](ARCHITECTURE.md)。
