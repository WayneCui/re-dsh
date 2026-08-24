# session

职责：只追加的会话事件日志、payload 硬化（JSON 快照）、从 seed 回放、从日志投影模型可见消息；可选文件落盘。

不做什么：不调用 LLM、不执行工具、不做 fork/resume（4.2）、不做流式折叠策略以外的业务。

## API

| 方法 | 说明 |
|------|------|
| `create` | 空会话（有 backend 时写空文件） |
| `create-from-log events` | 校验并回放事件块，设置 `live-index` |
| `open id` | 从 `store-dir` 加载到内存（保留 id）；无 backend 则报错 |
| `save id` | 强制 flush 当前日志到磁盘 |
| `append-event` | 校验 → 快照 → 提交 → emit → 若有 backend 则落盘 |
| `events-of` / `events-snapshot` | 深拷贝日志 |
| `derive-messages` | 只读投影，不改日志 |

## 持久化

插件 config：

```rebol
make map! [store-dir %data/sessions]
```

或 boot：

```rebol
boot-spine/session-config make map! [store-dir %data/sessions]
```

文件格式：`store-dir/<id>.events.reb`，内容为 `mold/all` 的 events block。默认无 `store-dir` = 纯内存。

## 事件类型

`turn-start` `turn-end` `step-start` `step-end` `user-message` `assistant-message` `assistant-chunk` `tool-call` `tool-result` `session-end-seed`

另有 approval：`approval-asked` `approval-decided` `approval-policy`。

## 不变量

- append 只往尾部加；index 连续 0..n-1。
- 调用方在 append 后改 payload 不影响已提交日志。
- replay：`create-from-log` / `open` 后 `derive-messages` 与线上一致。
- 有 backend 时，每次 append 后磁盘与内存一致。
