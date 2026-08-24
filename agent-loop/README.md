# agent-loop

职责：驱动一轮 turn：写 session、问 llm、经 tools waterfall 执行、再问，直到文本回复或步数用尽。

不做什么：不直接 spawn 进程、不实现模型、不解释 bash。

## API

| 方法 | 说明 |
|------|------|
| `run-turn session-id user-text` | 追加 user-message，再跑 turn |
| `resume-turn session-id` | **不**追加 user-message；仅从 `derive-messages` 继续 |
| `cancel-turn` | 请求取消当前 live turn；idle 时返回 `none` 且不粘滞标志 |

## 不变量

- 每一步的模型输入只来自 `sessions/derive-messages`（无旁路缓存）。
- 文本步走 `llm/stream`：先写 `assistant-chunk`，再写最终 `assistant-message`；derive 与非流式一致。
- 工具结果先入日志再进入下一步。
- dispose 后 `run-turn` / `resume-turn` 返回 `status: disposed`。
- `cancel-turn` 合作式：每步 / settle 每 tick 检查；取消后写 `cancelled` tool-result 与 `turn-end status: cancelled`，并清标志。
- `agents/dispose` 先 `cancel-turn` 再卸 fiber。
