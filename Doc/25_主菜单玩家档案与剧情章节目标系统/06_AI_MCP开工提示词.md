# 25-06 AI/MCP 开工提示词总纲

> 用途：后续让 AI/MCP 直接在 Godot 中开工时，优先读取本文件，再按任务跳转到 25-01 至 25-07。

## 1. 总体目标

实现从启动游戏到第一章结束的完整局外流程：

```text
主菜单
-> 用户名档案
-> 开场视频剧情，可跳过
-> 第一段“回到404哨所与背景故事”剧情
-> 局外仓库/出发准备，商人和研究所暂未解锁
-> 点击出发探索
-> 第二段首次出发任务剧情
-> 出发加载进度条
-> Loading 100% 后按任意按钮继续
-> 地面探索
-> 撤离/失败结算
-> 返回哨所 loading
-> Loading 100% 后按任意按钮回局外
-> 首次返回剧情
-> 解锁商人和研究所，并指引前往商人
-> 出售物资赚矿币
-> 为救出妹妹，5000 矿币解锁制造所
-> 第一章结束
```

## 2. 分阶段开工提示词

### 阶段一：主菜单和档案

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/01_主菜单与玩家档案本地存储.md。
实现 MainMenuScene：包含开始游戏和设置按钮。
点击开始游戏后，如果无本地 PlayerProfile，则弹出用户名输入；校验后创建档案并保存。
保存必须通过 SaveStorageAdapter：桌面默认 user://profile/profile.json，Web 版本通过 WebSaveStorageAdapter 适配。
```

### 阶段二：开场视频和回到404哨所与背景故事剧情

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/02_首次进入局内前剧情对白.md。
实现 IntroCinematicController、DialogueService 和 DialoguePanel。
主流程对白统一配置在 setting/dialogues.tab，代码按 dialogue_id 读取，不要把对白写死在脚本或 JSON 中。
说话人原画统一配置在 setting/dialogue_speakers.tab，player 使用主角原画，operator_404 显示为 404 哨所管理员并使用管理员原画。
所有对白立绘必须放在屏幕最左侧并左对齐，不使用主角右侧站位。
DialoguePanel 中左侧主立绘槽位中心常量必须保持 PORTRAIT_SLOT_CENTER_X_RATIO := 0.26，不要因自适应布局或代码清理改动。
玩家输入用户名并创建档案后，播放 opening_intro_cinematic；视频可跳过。
视频结束或跳过后设置 intro_cinematic_seen=true，并播放 world_intro_dialogue。
world_intro_dialogue 必须在首次进入对局前交代背景故事：2050 核战后人类退入地下哨所、地表被暗潮占据、普通人无法长时间暴露、玩家属于少数能短暂上地表的人、404 需要地表物资才能继续维持。
world_intro_dialogue 不能写成百科式世界观说明；它以“你回来了”开场，确认玩家本来就是 404 哨所成员，并通过自然对话承载背景故事。
world_intro_dialogue 中出现的道具名必须来自 setting/items.tab。
world_intro_dialogue 播放时，主角和 404 哨所管理员需要根据当前 speaker_id 在左侧立绘位切换原画高亮。
world_intro_dialogue 完成后设置 world_intro_dialogue_seen=true，并进入局外仓库/出发准备界面；商人和研究所保持锁定，不能点击进入。
```

### 阶段三：首次出发任务剧情

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/02_首次进入局内前剧情对白.md。
玩家第一次点击出发探索且出发校验通过后，播放 first_departure_outpost_dialogue。
first_departure_outpost_dialogue 从 setting/dialogues.tab 读取，修改对白只改表。
对白需要讲清楚：出发后通道暂时损坏、收集菱形前哨修复件、修复两处前哨站、撤离重新激活、视野会收缩、稳定值会下降、回到基地能恢复稳定值。
前哨修复件示例必须来自 setting/items.tab，例如前哨保险丝、净化滤芯。
对白 UI 需要显示主角和 404 哨所管理员原画，立绘统一在屏幕最左侧左对齐；当前说话者高亮，另一方弱化或隐藏。
播放完成或跳过后设置 first_departure_outpost_dialogue_seen=true，并进入 RunLoadingScreen。
```

### 阶段四：出发进入对局加载

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/07_出发进入对局加载进度条.md。
实现 RunLoadingController 和 RunLoadingScreen.tscn。
玩家确认出发后，不要直接进入 RunScene；先进入加载界面。
加载阶段包含装备校验、run_context、地图、玩家、背包、前哨、容器、撤离、HUD、音频和首帧渲染。
加载完成到 100% 后，停留在 loading 界面，阶段提示改为“按下任意按钮继续”。
loading 界面需要显示操作提示：WASD 移动、Tab 背包、F 拾取/交互、E 撤离。
loading 界面需要显示机制提示：视野会随暗潮压缩，稳定值会随在外时间下降，回到基地能恢复稳定值。
玩家按任意按钮后才提交装备 IN_RUN、surface_day +1，并保存 run_start。
如果 run_day_index == 2 且 second_day_black_tide_reveal_seen=false，进入 RunScene 后先播放 second_day_black_tide_reveal 视频；视频可跳过，跳过后播放 second_day_black_tide_reveal_dialogue，独白只显示主角原画。
该剧情期间必须冻结对局倒计时、稳定值、视野、容器、材料、前哨、撤离和怪物/事件计时，并屏蔽玩家输入；对白结束后才启动本局。
加载失败时返回出发准备界面，回滚 pending 装备，不增加 surface_day。
```

### 阶段五：首次返回剧情和第一章目标

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/03_首次返回剧情与第一章目标.md。
当玩家第一次成功撤离、完成结算、走完返回哨所 loading，并按任意按钮回到局外界面时，播放玩家独白，引出可售物资、商人、矿币、制造所目标，以及“救出妹妹”的第一章动机。
首次返回独白中出现的道具名必须来自 setting/items.tab，例如废金属、旧线圈、药粉、工具零件、安定糖、临时绷带、褪色照片、金色数据芯片、旧电池。
首次返回独白只显示主角原画，不显示 404 哨所管理员。
播放后设置 first_return_dialogue_seen=true、merchant_unlocked=true、research_station_unlocked=true，刷新局外顶部页签，并激活第一章目标：为救出妹妹，解锁制造所，矿币 0/5000。
目标卡提供“知道了”和“前往商人”；“前往商人”只在 merchant_unlocked=true 后切换到商人页签。
```

### 阶段六：制造所解锁和章节结束

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/04_制造所解锁与第一章结束.md，并联动 Doc/10_研究所与制作所系统。
未解锁时，制作所/制造所页签显示锁定状态：需要矿币 current/5000。
矿币足够时允许点击解锁制造所；确认后通过 CurrencyWallet 扣除 5000 mine_coin，设置 manufacturing_station_unlocked=true 和 chapter_1_completed=true。
成功后弹出第一章结束弹窗：你用了 {surface_day} 天，成功购买了旧时代制造机。也许，救出妹妹的路终于有了第一盏灯。
```

### 阶段七：Debug 验证

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/05_Godot模块与数据配置.md。
实现 Debug 工具：清除档案、重置开场视频 flag、重置回到404哨所与背景故事对白 flag、重置首次出发任务对白 flag、重置第二日暗潮物质剧情 flag、重置首次返回剧情 flag、增加 5000 矿币、surface_day +1、强制完成第一章、强制慢加载、强制加载失败、强制下一次入局触发第二日暗潮物质剧情、打印当前对白 speaker_id 与 portrait_path、打印 RunSimulationPauseService pause token。
验证新档、重启读档、开场视频、回到404哨所与背景故事剧情、首次出发任务剧情、出发加载、第二日暗潮物质剧情、首次返回剧情、制造所解锁和章节结束弹窗。
```

## 3. 硬约束

```text
不要把对白硬编码在 UI 脚本里。
不要把主角和 404 哨所管理员原画路径硬编码在 DialoguePanel；使用 setting/dialogue_speakers.tab。
不要把主角立绘放到右侧；所有剧情对白立绘都必须位于屏幕最左侧并左对齐。
不要修改 `PORTRAIT_SLOT_CENTER_X_RATIO := 0.26`；这是已调好的对白左侧主立绘槽位中心。
不要让 UI 直接写 profile.json 或 currencies。
不要让失败撤离触发首次返回剧情。
不要让新档第一天直接进入商人或研究所；两者必须在首次成功返回剧情结束后解锁。
不要让制造所免费解锁。
不要用桌面绝对路径做 Web 存档。
不要重复播放一次性剧情。
不要在局内资源未完成时把加载进度显示到 100%。
不要在加载失败时消耗出发装备或增加 surface_day。
不要让第二日暗潮剧情期间的 RunTimer、稳定值、视野、容器、材料、前哨或撤离计时继续走。
不要把第二日暗潮剧情当作第 3 日场景随机事件池。
不要让跳过开场视频跳过第一段“回到404哨所与背景故事”剧情。
不要让 loading 100% 后自动进入局内，必须等待任意按钮。
不要让结算返回哨所 loading 100% 后自动回局外，必须等待任意按钮。
```

## 4. 完成定义

- 启动游戏看到主菜单。
- 新玩家能输入用户名并保存。
- 新档创建后播放可跳过的视频剧情。
- 视频结束或跳过后播放第一段“回到404哨所与背景故事”剧情。
- 第一段剧情结束后只开放仓库和出发准备，商人和研究所仍锁定。
- 第一次点击出发探索后播放第二段任务剧情。
- 剧情对白显示主角和 404 哨所管理员原画；所有立绘位于最左侧左对齐，当前说话者高亮，首次返回独白只显示主角。
- 确认出发后进入加载界面，加载完成后显示“按下任意按钮继续”。
- Loading 界面显示 WASD、Tab、F、E 操作提示和稳定值/视野提示。
- 第 2 日首次进入局内会播放暗潮物质视频和主角独白，期间所有局内计时冻结，对白结束后才开始本局。
- 结算后返回哨所也进入 loading，完成后按任意按钮回局外。
- 首次成功返回后播放第一章目标剧情，解锁商人和研究所，并明确“救出妹妹”是第一章引子。
- 玩家能通过出售物资获得矿币，并看到“救出妹妹 / 解锁制造所”的 5000 矿币目标进度。
- 制造所解锁消耗 5000 矿币。
- 第一章结束弹窗显示用了多少天。
