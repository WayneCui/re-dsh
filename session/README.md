# session

职责：只追加的会话事件日志，以及从日志投影模型可见消息。

不做什么：不调用 LLM、不执行工具、不做持久化。

不变量：append 只往尾部加；derive-messages 不改日志；缺会话时读写返回 none / 空块。
