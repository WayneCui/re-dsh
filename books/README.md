# harness-spine 双书

| 书 | 风格 | 适合 |
|---|---|---|
| [《Head First harness-spine》](head-first-harness-spine/HEAD_FIRST_HARNESS_SPINE.md) | 漫画 + 谜题 + 问答 + 动手实验 | 第一次建立直觉，每章 20 分钟 |
| [《从零构建 harness-spine》](build-harness-spine-from-scratch/BUILD_HARNESS_SPINE_FROM_SCRATCH.md) | 设计压力 → 代码 → 实验 → 检查点 | 想亲手搭一遍、吃透每个零件 |

两本书共用同一套**角色宇宙**（小壳 / 脊先生 / 阿粗 / 账房先生 / 客人 / 门房）与「门 · 账本 · 许可 · 客人 · 房间」比喻家族，与 [写给所有人的 Harness](../../harness-for-everyone/HARNESS_FOR_EVERYONE.md) 和 [harness-spine 是怎样工作的](../../how-harness-spine-works/HOW_HARNESS_SPINE_WORKS.md) 术语完全对齐。

## 目录结构

```text
books/
├── head-first-harness-spine/
│   ├── HEAD_FIRST_HARNESS_SPINE.md   # 全书正文（10 章 + 结业）
│   └── comics/                        # 11 张概念漫画（SVG）
├── build-harness-spine-from-scratch/
│   ├── BUILD_HARNESS_SPINE_FROM_SCRATCH.md  # 全书正文（Step 0–11 + 毕业项目）
│   └── comics/                        # 8 张概念漫画（SVG）
└── comic-cast/                        # 漫画生产线
    ├── comic-gen.ts                   # 生成器（bun comic-gen.ts 一键重绘 19 张）
    ├── characters/characters.md       # 角色设定表
    ├── storyboard.md                  # 分镜总表
    └── prompts/ai-prompts.md          # AI 重生成提示词（ohmsha 预设）
```

## 常用操作

```bash
# 重绘全部漫画（SVG）
cd comic-cast && bun comic-gen.ts

# 导出 PNG 预览（需 rsvg-convert）
for f in ../head-first-harness-spine/comics/*.svg ../build-harness-spine-from-scratch/comics/*.svg; do
  rsvg-convert -w 1200 "$f" -o "/tmp/$(basename ${f%.svg}).png"
done
```

漫画当前为程序化 SVG（baoyu-comic 的 minimalist/four-panel 风格）。想换成 AI 手绘版：在 `~/.baoyu-skills/.env` 配置生图密钥（如 `OPENROUTER_API_KEY`），按 `comic-cast/prompts/ai-prompts.md` 逐条生成并替换同名文件即可。
