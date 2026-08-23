# approval

Channel-neutral one-shot approval seam. `request` returns `allowed-once`, `rejected`, `cancelled`, or `unavailable`; missing answerers fail closed.

## Service

| Method | Purpose |
|--------|---------|
| `request session-id tool-name call-id reason` | Ask answerers; append `approval-asked` + `approval-decided` |
| `set-policy session-id policy` | Append `approval-policy` (`ask` / `never`) |
| `override-of session-id` | Last logged policy override |
| `effective-policy session-id` | Override or configured default |

## Events

| Session type | Payload |
|--------------|---------|
| `approval-asked` | `id`, `tool-name`, optional `call-id`, `reason` |
| `approval-decided` | `id`, `outcome` |
| `approval-policy` | `policy` |

## Waterfall

`approval-request` — return an outcome word to answer; default inner yields `unavailable`.

## Tools bridge

Tools with `approval: 'ask` on the spec, or a `tools-pre-execute` listener returning `{kind: ask}`, route through `approval/request` when the service is mounted.

## 不做什么

- 无持久 grant store、`allow-always`、或内置 human UI
- 不在 turn 外 request（会抛错）
