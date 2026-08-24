# agent

职责：根上的 live agent 注册表 — `create`、`dispose`、`get`、`list`、`register`。

不做什么：不驱动 turn（转发到 `agent-loop`）、不创建 session、不实现工厂策略。

## Service

| 方法 | 语义 |
|------|------|
| `create label` | `create-agent-handle` + 登记 + `agent-created` emit |
| `create/parent label parent-key` | 子 scope 继承父链 |
| `dispose handle` | `agent-disposed` emit → 从表移除 → `release-agent-handle` |
| `register handle` | 登记已存在 handle（boot 默认 agent） |
| `get id` | 按 label 查找 |
| `list` | 所有 live handle |

## Handle

agent handle 是 object（不是 map）：inbox / turn 方法在 handle 上，内部转给 `driver`。

| 方法 | 语义 |
|------|------|
| `followup text` | 入队 next-turn（waking） |
| `steer text` | 入队 next-step（waking） |
| `inject text` | 入队 next-step（非 waking） |
| `run-turn session-id user-text` | 转 `driver/run-turn` |
| `resume-turn session-id` | 转 `driver/resume-turn` |
| `cancel-turn` | 转 `driver/cancel-turn` |

`driver` / `tools` / `ctx` / `scope-key` / `spine` 仍可直接访问。

## 事件

| 事件 | 参数 |
|------|------|
| `agent-created` | agent handle object |
| `agent-disposed` | agent handle object |

## 不变量

- dispose 后 agent isolate fiber 卸掉；`run-turn` 返回 `status: disposed`。
- tools 登记随 fiber dispose 撤回（cordis effect）。
- reload 后 `handle/driver` 指向新 loop；handle 上的 inbox 方法跟过去（读当前 `driver` 字段）。
