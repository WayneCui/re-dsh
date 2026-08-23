# session

职责：只追加的会话事件日志、payload 硬化（JSON 快照）、从 seed 回放，以及从日志投影模型可见消息。

不做什么：不调用 LLM、不执行工具、不做持久化。

## API

| 方法 | 说明 |
|------|------|
| `create` | 空会话 |
| `create-from-log events` | 校验并回放事件块，设置 `live-index` |
| `append-event` | 校验 type/payload → 快照 → 提交 → `session-event` emit（观察者失败被 contain） |
| `events-of` / `events-snapshot` | 深拷贝日志 |
| `derive-messages` | 只读投影，不改日志 |

## 事件类型

`turn-start` `turn-end` `step-start` `step-end` `user-message` `assistant-message` `assistant-chunk` `tool-call` `tool-result` `session-end-seed`

`tool-call` / `tool-result` 可带 `call-id` 配对。`turn-end` 可带 `status` `steps` `text`。

## 不变量

- append 只往尾部加；index 连续 0..n-1。
- 调用方在 append 后改 payload 不影响已提交日志。
- replay：`create-from-log` 后 `derive-messages` 与线上一致。
