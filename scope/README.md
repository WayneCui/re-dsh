# scope

职责：为每个 agent 提供 opaque scope key，以及事件路由用的 `make-scope-target` filter。

不做什么：不管理 session、不登记工具、不跑 turn。

## API

| 函数 | 说明 |
|------|------|
| `mint-scope-key label` | 生成唯一 key |
| `bind-scope-parent child parent` | 建立父链（子事件可被父 scope 监听器接收） |
| `scope-of ctx` | 读 ctx 上绑定的 key |
| `make-scope-target key` | 带 `filter` 的 dispatch carrier |
| `create-agent-handle root label` | isolate tools + 插件 + scope |

## 路由规则

- 无 scope 的 listener：全局接收（在 filter 通过后）。
- 有 scope 的 listener：仅当 dispatch key 在自身 key 的祖先链上时接收（事件向上冒泡）。
