# agent

职责：根上的 live agent 注册表 — `create`、`dispose`、`get`、`list`、`register`。

不做什么：不驱动 turn（`agent-loop`）、不创建 session、不实现工厂策略。

## Service

| 方法 | 语义 |
|------|------|
| `create label` | `create-agent-handle` + 登记 + `agent-created` emit |
| `create/parent label parent-key` | 子 scope 继承父链 |
| `dispose handle` | `agent-disposed` emit → 从表移除 → `release-agent-handle` |
| `register handle` | 登记已存在 handle（boot 默认 agent） |
| `get id` | 按 label 查找 |
| `list` | 所有 live handle |

## 事件

| 事件 | 参数 |
|------|------|
| `agent-created` | agent handle map |
| `agent-disposed` | agent handle map |

## 不变量

- dispose 后 agent isolate fiber 卸掉；`agent-loop/run-turn` 返回 `status: disposed`。
- tools 登记随 fiber dispose 撤回（cordis effect）。
