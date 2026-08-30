# harness-spine

最小 agent 脊柱：挂在 `cordis-port` 内核上。装配可用代码 `boot-spine`，YAML `boot-spine-from-config`，或 profile `boot-spine-from-profile`（`profiles/` + `bundles/` 叠层）。

在 `harness-spine/` 下运行：

```
bash test/run-all.sh
r3 -s examples/echo-turn.reb
r3 -s examples/multi-step-turn.reb
r3 -s examples/inbox-turn.reb
r3 -s examples/pre-step-turn.reb
r3 -s examples/request-turn.reb
r3 -s examples/yaml-isolate.reb
r3 -s examples/full-chain.reb
r3 -s examples/profile-boot.reb
r3 -s examples/reload-llm.reb
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

## 教学材料

| 读本 | 路径 |
|------|------|
| 写给所有人的 Harness | [harness-for-everyone/](harness-for-everyone/) |
| harness-spine 是怎样工作的（带实验） | [how-harness-spine-works/](how-harness-spine-works/) |
| Head First / 从零构建 | [books/](books/) |

## 同像热替换（Phase 6）

- `reload-plugin ctx name path`（cordis-port loader）：`do path` 得新插件 → dispose 旧 fiber → 按旧 config/parent 挂新插件；加载失败或新插件启动失败（fiber FAILED）都会回滚到旧插件。
- `reload-agent-plugin agent-handle name path`：换 agent 隔离 ctx 下的插件；root 服务（sessions/llm）与 session 日志不动，兄弟 agent 互不影响。
- `reload-spine-plugin handle name path`：换 root 插件（如 llm）；先 `cancel-turn` 活 turn（同步 loop 在下一检查点收敛），换完刷新所有 agent handle 的 tools/driver 引用并迁移 pending inbox。
- 演示：`r3 -s examples/reload-llm.reb`——同一 session 内把 echo 适配器热换成 UPPERCASE 适配器，历史不丢。
