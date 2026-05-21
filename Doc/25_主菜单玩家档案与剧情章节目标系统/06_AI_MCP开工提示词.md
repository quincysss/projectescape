# 25-06 AI/MCP 开工提示词总纲

> 用途：后续让 AI/MCP 直接在 Godot 中开工时，优先读取本文件，再按任务跳转到 25-01 至 25-09。

## 1. 总体目标

实现从启动游戏到完成首次营业的完整流程：

```text
主菜单
-> 用户名档案
-> 开场视频剧情，可跳过
-> 第一段“回到404哨所与背景故事”剧情
-> 序章夜晚出发入口，可查看基础仓库
-> 点击出发探索
-> 第二段首次出发任务剧情
-> 出发加载进度条
-> Loading 100% 后按任意按钮继续
-> 地面探索
-> 撤离/失败结算
-> 返回哨所 loading
-> Loading 100% 后按任意按钮回局外
-> 序章返回剧情
-> 无论成功或失败，剧情发放一次性开店周转物资
-> 开启正式白天经营循环和研究所
-> 制造第一批可售物资
-> 上架货台
-> 开店营业并完成结算
-> 进入常规白天/夜晚循环
```

## 2. 分阶段开工提示词

### 阶段一：主菜单和档案

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/01_主菜单与玩家档案本地存储.md。
实现 MainMenuScene：包含开始游戏和设置按钮。
点击开始游戏后，如果无本地 PlayerProfile，则弹出用户名输入；校验后创建档案并保存。
保存必须通过 SaveStorageAdapter：桌面默认 user://profile/profile.json，Web 版本通过 WebSaveStorageAdapter 适配。
PlayerProfile 使用 shop_loop_unlocked、research_station_unlocked、starter_shop_supply_granted、first_shop_tutorial_completed、chapter_1_goal_active。
不要把 advanced_manufacturing_station_unlocked 作为新手目标或第一章目标依据。
```

### 阶段二：开场视频和回到404哨所与背景故事剧情

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/02_首次进入局内前剧情对白.md。
实现 IntroCinematicController、DialogueService 和 DialoguePanel。
主流程对白统一配置在 setting/dialogues.tab，代码按 dialogue_id 读取，不要把对白写死在脚本或 JSON 中。
说话人原画统一配置在 setting/dialogue_speakers.tab，player 使用主角原画，operator_404 显示为 404 哨所管理员并使用管理员原画。
所有对白立绘必须放在屏幕最左侧并左对齐，不使用主角右侧站位。
DialoguePanel 中左侧主立绘槽位中心常量必须保持 PORTRAIT_SLOT_CENTER_X_RATIO := 0.26。
玩家输入用户名并创建档案后，播放 opening_intro_cinematic；视频可跳过。
视频结束或跳过后设置 intro_cinematic_seen=true，并播放 world_intro_dialogue。
world_intro_dialogue 完成后设置 world_intro_dialogue_seen=true，并进入序章夜晚出发入口；此时不展示白天经营主流程。
```

### 阶段三：首次出发任务剧情

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/02_首次进入局内前剧情对白.md。
玩家第一次点击出发探索且出发校验通过后，播放 first_departure_outpost_dialogue。
first_departure_outpost_dialogue 从 setting/dialogues.tab 读取，修改对白只改表。
对白需要讲清楚：出发后通道暂时损坏、收集菱形前哨修复件、修复两处前哨站、撤离重新激活、视野会收缩、稳定值会下降、回到基地能恢复稳定值。
播放完成或跳过后设置 first_departure_outpost_dialogue_seen=true，并进入 RunLoadingScreen。
```

### 阶段四：出发进入对局加载

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/07_出发进入对局加载进度条.md。
实现 RunLoadingController 和 RunLoadingScreen.tscn。
玩家在夜晚出发准备确认后，不要直接进入 RunScene；先进入加载界面。
加载完成到 100% 后，停留在 loading 界面，阶段提示改为“按下任意按钮继续”。
玩家按任意按钮后才提交装备 IN_RUN、surface_day +1，并保存 run_start。
加载失败时返回出发准备界面，回滚 pending 装备，不增加 surface_day。
```

### 阶段五：序章返回剧情、周转物资和第一章目标

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/03_首次返回剧情与第一章目标.md。
当玩家完成序章首次探索结算、走完返回哨所 loading，并按任意按钮回到局外界面时，播放序章返回剧情。
该剧情不要求成功撤离：成功撤离使用成功版本对白，失败撤离或空包返回使用兜底版本对白。
序章返回剧情中出现的道具名必须来自 setting/items.tab。
播放时显示主角和 404 哨所管理员原画，按 speaker_id 切换，统一左侧显示。
播放后设置 first_return_dialogue_seen=true、shop_loop_unlocked=true、research_station_unlocked=true、starter_shop_supply_granted=true、chapter_1_goal_active=true，刷新局外昼夜阶段入口。
调用 StarterSupplyService 发放 prologue_shop_starter_pack 到仓库；该包只给原材料，不给可售物资，只能领取一次。
弹出第一章目标卡：重启杂货店，制造第一批可售物资、上架货台、完成第一次开店结算。
目标卡提供“知道了”“前往制造所”“查看需求榜”按钮。
```

### 阶段六：制造所默认开放和首次开店教学

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/04_制造所解锁与第一章结束.md，并联动 Doc/32_局外白天经营流程。
制造所设施默认存在，序章返回剧情后在白天准备阶段可点击。
玩家必须使用带回材料或周转物资，在制造所加工可售物资。
第一章目标追踪三步：制造第一批可售物资、上架货台、完成第一次开店结算。
完成第一次开店结算后设置 first_shop_tutorial_completed=true、chapter_1_completed=true。
不要实现固定矿币解锁制造所，不要实现额外制造设施章节终点。
```

### 阶段七：Debug 验证

```text
请读取 Doc/25_主菜单玩家档案与剧情章节目标系统/05_Godot模块与数据配置.md。
实现 Debug 工具：清除档案、重置开场视频 flag、重置回到404哨所与背景故事对白 flag、重置首次出发任务对白 flag、重置第二日暗潮物质剧情 flag、重置序章返回剧情 flag、重置周转物资领取状态、强制发放序章开店周转物资、surface_day +1、强制完成首次开店教学、强制慢加载、强制加载失败、强制开启经营循环/研究所、强制触发第二日暗潮物质剧情、打印当前对白 speaker_id 与 portrait_path、打印 RunSimulationPauseService pause token。
```

## 3. 硬约束

```text
不要把对白硬编码在 UI 脚本里。
不要把主角和 404 哨所管理员原画路径硬编码在 DialoguePanel；使用 setting/dialogue_speakers.tab。
不要把主角立绘放到右侧；所有剧情对白立绘都必须位于屏幕最左侧并左对齐。
不要修改 PORTRAIT_SLOT_CENTER_X_RATIO := 0.26。
不要让 UI 直接写 profile.json 或 currencies。
不要让失败撤离跳过序章返回剧情。
不要让序章失败且空包返回的玩家没有开店材料。
不要重复发放 starter_shop_supply_granted 对应的周转物资。
不要让新档序章直接进入白天开店主流程。
不要实现旧独立交易页签。
不要实现固定矿币解锁制造所。
不要实现额外制造设施作为第一章目标。
不要实现仓库原材料直接变现。
不要用桌面绝对路径做 Web 存档。
不要重复播放一次性剧情。
不要在加载失败时消耗出发装备或增加 surface_day。
不要让 loading 100% 后自动进入局内，必须等待任意按钮。
不要让结算返回哨所 loading 100% 后自动回局外，必须等待任意按钮。
```

## 4. 完成定义

- 启动游戏看到主菜单。
- 新玩家能输入用户名并保存。
- 新档创建后播放可跳过的视频剧情。
- 视频结束或跳过后播放第一段“回到404哨所与背景故事”剧情。
- 第一段剧情结束后进入序章夜晚出发入口，不展示白天开店主流程。
- 第一次点击出发探索后播放第二段任务剧情。
- 确认出发后进入加载界面，加载完成后显示“按下任意按钮继续”。
- 结算后返回哨所也进入 loading，完成后按任意按钮回局外。
- 序章返回后播放返回剧情，成功/失败使用不同对白分支。
- 序章返回剧情结束后发放一次性开店周转物资，开启正式白天经营循环和研究所。
- 玩家能通过制造所把材料加工成可售物资。
- 玩家能将可售物资上架到货台。
- 玩家能完成第一次开店结算。
- 完成首次开店结算后，`first_shop_tutorial_completed=true`、`chapter_1_completed=true`。
- 全流程不出现旧独立交易页签、额外制造设施章节目标或固定矿币解锁目标。

## BDD 场景补充

```gherkin
Feature: 25-06 AI/MCP 开工提示词总纲
  Scenario: 新流程不使用旧交易或旧解锁入口
    Given 玩家完成序章探索并返回局外
    When 序章返回剧情播放完成
    Then shop_loop_unlocked 应为 true
    And starter_shop_supply_granted 应为 true
    And 目标卡应指引前往制造所和查看需求榜
    And 不应出现旧独立交易页签
    And 不应出现额外制造设施章节目标
    And 不应出现固定矿币解锁制造所目标
```
