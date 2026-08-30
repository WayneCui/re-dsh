# 分镜总表（Storyboard）

19 张概念漫画，每张 2×2 四格，SVG 由 `comic-gen.ts` 程序化生成；同目录附 AI 重生成提示词（`prompts/`）。

## 《Head First harness-spine》（head-first-harness-spine/comics/）

| 文件 | 章 | 分镜概要 |
|---|---|---|
| 01-cover | 封面 | 机器旅馆全家福：门/前台/房间/五零件清单 |
| 02-ch01-wrapper-breaks | 1 | 套壳十分钟→凌晨三点露馅→「循环只是皮带」→五件套蓝图 |
| 03-ch02-turn-anatomy | 2 | 流水线六站→账本 7 行→誊本 2 行→差额有名字 |
| 04-ch03-ledger-and-transcript | 3 | append 四工序→只增不改→影印快照→chunk 折叠 |
| 05-ch04-security-lane | 4 | 查证件可遣返→引擎唯一点火→海关改标签→大喇叭广播 |
| 06-ch05-approval-counter | 5 | 仅此一次印章→问答双入账→空座位=拒绝→四结局塌缩 |
| 07-ch06-guest-not-master | 6 | 客人只动嘴→四级适配器→门房拦客人→点菜单不是判决 |
| 08-ch07-morning-reading | 7 | 早晨朗读→耳语不落纸→inbox 三种信→resume 契约 |
| 09-ch08-hotel | 8 | 共享前台→私人房间→隔音墙→父钥匙听连通房 |
| 10-ch09-cancel-checkpoint | 9 | 七检查点举手→cancelled 行→空闲不粘旗→无鬼魂 |
| 11-ch10-hot-swap | 10 | 四层蛋糕→吊车换客→刷新钥匙搬信→新旧共处一账 |

## 《从零构建 harness-spine》（build-harness-spine-from-scratch/comics/）

| 文件 | 步 | 分镜概要 |
|---|---|---|
| 01-cover | — | 空文件夹→图纸→11 站装配线→LAB-OK |
| 02-step1-pipeline | 1 | 最小回合流水线→echo 镜子→账本 7 行→第一个 LAB-OK |
| 03-step2-append-only | 2 | 追加四工序→FROZEN: before→拒收坏载荷→fork 另起一本 |
| 04-step3-derive | 3 | chunk 折叠→最终消息说了算→簿记碎纸篓→缓存上大叉 |
| 05-step5-waterfall-relay | 5 | 三棒接力→waterfall 洋葱→pre 拒绝计数器为 0→全都要广播 |
| 06-step9-keys-rooms | 9 | 铸不透明钥匙→两间 isolate→根上共享→scope 隔音墙 |
| 07-step10-cancel-track | 10 | 七检查点→cancelled 行→空闲不粘旗→disposed 不开工 |
| 08-step11-layers-swap | 11 | 四层叠层→cordis.yml 无 tools→reload 四步→STILL ALIVE |

## 与 AI 生成的关系

当前版本为**程序化 SVG**（风格即 baoyu-comic 的 minimalist/four-panel 预设：黑白线稿 + 点缀色 + 简笔角色）。`prompts/` 内保存了全部 19 张的 AI 生图提示词（ohmsha 预设：manga + neutral、视觉比喻、禁止 talking heads）；配置好 `OPENROUTER_API_KEY` 等生图密钥后，可用 baoyu-imagine 批量重生成 AI 版并替换同名文件（保持 `.svg`→`.png` 引用同步修改）。
