# 25-05 Godot 模块与数据配置

> 目标：整理主菜单、玩家档案、剧情、章节目标和制造所解锁的工程落地方式。

## 1. 推荐模块

```text
systems/profile/player_profile.gd
systems/profile/profile_service.gd
systems/profile/save_storage_adapter.gd
systems/profile/file_save_storage_adapter.gd
systems/profile/web_save_storage_adapter.gd

systems/flow/main_menu_controller.gd
systems/flow/game_flow_controller.gd
systems/flow/intro_cinematic_controller.gd
systems/flow/run_loading_controller.gd
systems/flow/run_story_gate_controller.gd
systems/flow/run_simulation_pause_service.gd
systems/flow/run_load_context.gd
systems/flow/run_load_task.gd
systems/flow/loading_screen_mode.gd

systems/base/base_feature_unlock_service.gd

systems/dialogue/dialogue_sequence.gd
systems/dialogue/dialogue_service.gd
systems/dialogue/dialogue_speaker_registry.gd
systems/dialogue/dialogue_speaker_definition.gd
systems/dialogue/dialogue_portrait_controller.gd
systems/dialogue/dialogue_ui.gd

systems/chapters/chapter_progress_service.gd
systems/chapters/chapter_goal_ui.gd
systems/chapters/manufacturing_unlock_service.gd

addons/ffmpeg/ffmpeg.gdextension
```

## 2. 推荐场景

```text
scenes/ui/MainMenuScene.tscn
scenes/ui/UsernameInputDialog.tscn
scenes/ui/SettingsPanel.tscn
scenes/ui/dialogue/DialoguePanel.tscn
scenes/ui/dialogue/DialoguePortraitView.tscn
scenes/ui/ChapterGoalPopup.tscn
scenes/ui/ChapterCompletePopup.tscn
scenes/ui/RunLoadingScreen.tscn
```

## 3. 推荐数据

```text
data/cinematics/opening_intro_cinematic.json
data/cinematics/second_day_black_tide_reveal.json
setting/dialogues.tab
setting/dialogue_speakers.tab
data/chapters/chapter_1.json
data/loading/run_loading_stages.json
data/loading/run_loading_tips.json
```

`dialogues.tab` 是剧情对白的运行时唯一配置源，按行配置每一句对白：

```text
dialogue_id	skippable	order	speaker_id	speaker_name	text	enabled	notes
world_intro_dialogue	false	10	operator_404	404 哨所调度员	你回来了。	true	25-02 第一段剧情
```

字段规则：

- `dialogue_id`：对白段落 ID，例如 `world_intro_dialogue`、`first_departure_outpost_dialogue`、`first_return_chapter_1`。
- `skippable`：整段对白是否允许跳过；同一个 `dialogue_id` 下建议保持一致。
- `order`：句子顺序，建议以 10 递增，方便中间插入新句。
- `speaker_id`：说话人逻辑 ID；`player` 会在运行时显示为玩家输入的用户名。
- `speaker_name`：非玩家说话人显示名。
- `text`：对白正文，不要包含制表符。
- `enabled`：是否启用该句，临时下线可填 `false`。

`dialogue_speakers.tab` 是对白说话人展示配置，按 `speaker_id` 关联对白行：

```text
speaker_id	display_name	portrait_path	portrait_side	nameplate_color	enabled_version	notes
player	玩家	res://assets/characters/dialogue/player/player_dialogue_bust_01.png	left	#c8d4dc	v0.1	主角默认对白半身原画
operator_404	404 哨所管理员	res://assets/characters/dialogue/operator_404/operator_404_dialogue_bust_01.png	left	#d6c07a	v0.1	兼容 dialogues.tab 中的 operator_404
```

字段规则：

- `speaker_id`：必须能匹配 `dialogues.tab.speaker_id`。
- `display_name`：非玩家说话人显示名；`player` 运行时优先使用 PlayerProfile.username。
- `portrait_path`：对白半身原画 PNG。
- `portrait_side`：默认站位，V0.1 统一使用 `left`；所有对白立绘都放在屏幕最左侧并左对齐。
- `nameplate_color`：说话人名牌强调色。
- `enabled_version`：启用版本。
- `notes`：备注。

`opening_intro_cinematic.json` 示例：

```json
{
  "cinematic_id": "opening_intro_cinematic",
  "resource_path": "res://assets/cinematics/source/opening_intro_cinematic_720p.mp4",
  "fallback_resource_path": "res://assets/cinematics/opening_intro_cinematic_720p.ogv",
  "placeholder": {
    "type": "black_screen_16x9",
    "duration_seconds": 2.0,
    "resolution": "1280x720"
  },
  "skip_label": "跳过影像",
  "next_flow": "world_intro_dialogue"
}
```

MP4 播放依赖 `addons/ffmpeg/ffmpeg.gdextension`。如果扩展不可用，播放控制器需要尝试 `fallback_resource_path` 或黑屏占位，不能阻断新档流程。

`second_day_black_tide_reveal.json` 示例：

```json
{
  "cinematic_id": "second_day_black_tide_reveal",
  "resource_path": "res://assets/cinematics/source/second_day_black_tide_reveal_720p.mp4",
  "fallback_resource_path": "res://assets/cinematics/second_day_black_tide_reveal_720p.ogv",
  "placeholder": {
    "type": "black_screen_16x9",
    "duration_seconds": 1.5,
    "resolution": "1280x720"
  },
  "skip_label": "跳过影像",
  "next_flow": "second_day_black_tide_reveal_dialogue"
}
```

`chapter_1.json` 示例：

```json
{
  "chapter_id": "chapter_1",
  "title": "第一章：救出妹妹",
  "subtitle": "解锁制造所",
  "goal_type": "unlock_feature",
  "feature_id": "manufacturing_station",
  "currency_id": "mine_coin",
  "currency_cost": 5000
}
```

## 4. 核心服务职责

ProfileService：

- 创建档案。
- 读取档案。
- 保存档案。
- 更新剧情 flag。

IntroCinematicController：

- 在新档创建后播放开场视频剧情。
- 支持跳过视频。
- 视频结束或跳过后写入 `intro_cinematic_seen=true`。
- 通知 `GameFlowController` 进入第一段“回到404哨所与背景故事”对白。

DialogueService：

- 从 `setting/dialogues.tab#dialogue_id` 读取 DialogueSequence。
- 按 `speaker_id` 关联 DialogueSpeakerRegistry。
- 兼容旧 JSON DialogueSequence，但主流程对白不再使用 JSON。
- 播放 DialogueSequence。
- 支持逐字显示。
- 支持跳过。
- 播放完成回调。
- 分别处理 `world_intro_dialogue`、`first_departure_outpost_dialogue`、`first_return_chapter_1_dialogue`。

DialogueSpeakerRegistry：

- 读取 `setting/dialogue_speakers.tab`。
- 为 `DialoguePanel` 提供 display_name、portrait_path、portrait_side、nameplate_color。
- `player` 的 display_name 优先返回玩家输入的用户名。
- 找不到配置或资源缺失时返回 placeholder，并在 Debug 模式记录 warning。

DialoguePortraitController：

- 根据当前对白行 `speaker_id` 控制左侧角色原画。
- 当前说话者高亮，非说话者弱化。
- 玩家独白时只显示主角原画。
- 所有角色原画必须锚定屏幕最左侧左对齐，不使用主角右侧站位。
- `DialoguePanel` 中 `PORTRAIT_SLOT_CENTER_X_RATIO` 必须固定为 `0.26`；该值是人工调好的左侧主立绘槽位中心，不得在常规代码整理、响应式适配或 AI 重写时改动。
- 跳过对白、对白结束、进入 loading 或局外界面时隐藏所有原画。

BaseFeatureUnlockService：

- 管理局外功能入口解锁状态。
- 新档默认 `shop_loop_unlocked=false`、`research_station_unlocked=false`、`advanced_manufacturing_station_unlocked=false`。
- 第一段“回到404哨所与背景故事”对白完成后，只开放序章夜晚出发入口和基础仓库。
- 首次成功撤离返回剧情播放完成后，设置 `shop_loop_unlocked=true` 和 `research_station_unlocked=true`。
- 通知局外昼夜阶段入口刷新锁定/可点击状态。
- 旧档缺少 shop_loop/research 解锁字段时，如果 `first_return_dialogue_seen==true`，读取时补齐为已解锁。

ChapterProgressService：

- 管理当前章节。
- 更新目标进度。
- 判断制造所是否可解锁。
- 触发章节完成。

ManufacturingUnlockService：

- 校验 5000 矿币。
- 调用 CurrencyWallet 扣币。
- 写入高级制造所解锁。
- 触发第一章结束弹窗。

RunLoadingController：

- 接收 `LoadoutManager` 生成的待出发快照。
- 按阶段加载 RunScene、地图、玩家、背包、前哨、容器、撤离、HUD 和音频。
- 通过任务权重驱动进度条。
- 加载成功后进入 `READY_TO_CONTINUE`，显示“按下任意按钮继续”。
- 玩家按任意按钮后通知 `GameFlowController` 进入局内。
- 加载失败时通知 `LoadoutManager` 回滚待出发装备。
- 支持 `RETURN_TO_BASE` mode：结算后返回哨所 loading 到 100% 后等待任意按钮，再通知 `GameFlowController` 回到局外。

RunStoryGateController：

- 在 ENTER_RUN loading 完成、玩家按任意按钮并切入 RunScene 后运行。
- 检查 `run_context.run_day_index` 和 PlayerProfile 剧情 flag。
- 当 `run_day_index == 2` 且 `second_day_black_tide_reveal_seen == false` 时，触发第二日暗潮物质视频和主角独白。
- 剧情完成后写入 `second_day_black_tide_reveal_seen=true` 并保存。
- 剧情结束前不得启动局内玩法计时。

RunSimulationPauseService：

- 提供统一 story pause token。
- 冻结对局倒计时、稳定值、视野、容器、材料、前哨、撤离、怪物和随机事件计时。
- 屏蔽玩家移动、背包、拾取、交互和撤离输入。
- 所有局内计时器必须读取该暂停状态，不能只暂停 HUD。

## 5. 信号建议

```gdscript
signal profile_created(profile)
signal profile_loaded(profile)
signal intro_cinematic_finished(skipped)
signal dialogue_started(dialogue_id)
signal dialogue_finished(dialogue_id)
signal base_feature_unlocked(feature_id)
signal chapter_goal_updated(chapter_id, current, required)
signal feature_unlocked(feature_id)
signal chapter_completed(chapter_id, surface_day)
signal run_loading_started(run_id)
signal run_loading_progress_changed(progress, stage_id, stage_text)
signal run_loading_failed(reason)
signal run_loading_completed(run_context)
signal run_loading_ready_to_continue(run_context)
signal run_enter_committed(run_context)
signal run_story_gate_started(gate_id, run_context)
signal run_story_gate_finished(gate_id, run_context)
signal run_simulation_pause_changed(paused, reason)
signal return_to_base_loading_started(settlement_id)
signal return_to_base_ready_to_continue(settlement_result)
signal return_to_base_committed(settlement_result)
```

## 6. 保存字段合并边界

货币仍由 09 的 `CurrencyWallet` 管理，但玩家档案可以保存 currencies 字典或引用同一存档对象。

推荐最终存档：

```gdscript
{
    "profile": {},
    "warehouse": {},
    "currencies": {},
    "settings": {}
}
```

V0.1 可以先拆文件保存，但必须由统一 SaveService 组织。

## 7. Debug 工具

需要提供：

- 清除本地档案。
- 重置开场视频 flag。
- 重置回到404哨所与背景故事对白 flag。
- 重置首次出发任务对白 flag。
- 重置第二日暗潮物质剧情 flag。
- 重置首次返回剧情 flag。
- 重置经营循环/研究所解锁状态。
- 强制开启经营循环/研究所。
- 增加 5000 矿币。
- 强制完成第一章。
- surface_day +1。
- 强制慢速出发加载。
- 强制下一次出发加载失败。
- 打印出发加载阶段和进度。
- 强制下一次进入局内触发第二日暗潮物质剧情。
- 打印当前 RunSimulationPauseService pause token。
- 强制慢速返回哨所加载。
- 强制下一次返回哨所加载失败。
- 打印返回哨所加载阶段和进度。

Debug 操作必须只在 Debug 模式显示。

## 8. AI/MCP 开工提示词

```text
请根据 Doc/25_主菜单玩家档案与剧情章节目标系统 实现 Godot 模块骨架。

要求：
1. 建立 MainMenuScene、UsernameInputDialog、DialoguePanel、ChapterGoalPopup、ChapterCompletePopup、RunLoadingScreen。
2. 建立 ProfileService、SaveStorageAdapter、BaseFeatureUnlockService、DialogueService、DialogueSpeakerRegistry、DialoguePortraitController、ChapterProgressService、ManufacturingUnlockService、RunLoadingController。
3. 玩家档案保存 username、surface_day、intro_cinematic_seen、world_intro_dialogue_seen、first_departure_outpost_dialogue_seen、second_day_black_tide_reveal_seen、first_return_dialogue_seen、shop_loop_unlocked、research_station_unlocked、advanced_manufacturing_station_unlocked、chapter_1_completed。
4. 桌面保存到 user://profile/profile.json；Web 通过 WebSaveStorageAdapter 适配，不在 UI 中写平台判断。
5. 新档创建后播放 opening_intro_cinematic；视频可跳过，跳过后仍进入 world_intro_dialogue。该 DialogueSequence 的剧情定位是“回到404哨所与背景故事”：必须交代背景故事，但要通过自然对白呈现，不写成百科式世界观说明。
6. world_intro_dialogue 完成后进入序章夜晚出发入口；研究所和高级制造所仍为锁定状态，不允许点击。
7. 玩家第一次点击出发探索且校验通过后，播放 first_departure_outpost_dialogue。
8. DialoguePanel 必须从 setting/dialogue_speakers.tab 读取主角和 404 哨所管理员原画；player 说话显示主角，operator_404 说话显示 404 哨所管理员；所有立绘统一放在屏幕最左侧左对齐，当前说话者高亮；立绘槽位中心常量保持 `PORTRAIT_SLOT_CENTER_X_RATIO := 0.26`。
9. first_departure_outpost_dialogue 完成后进入 RunLoadingScreen，由 RunLoadingController 加载局内资源。
10. 出发加载到 100% 后显示“按下任意按钮继续”，并展示操作提示与稳定值/视野说明。
11. 玩家按任意按钮后才提交 IN_RUN、surface_day +1，并保存 run_start。
12. 如果本次 `run_day_index == 2` 且 second_day_black_tide_reveal_seen=false，进入 RunScene 后先播放第二日暗潮物质视频和主角独白；演出期间冻结所有局内计时，对白结束后才启动本局玩法。
13. 首次成功撤离返回后播放 first_return_chapter_1_dialogue；对白结束后开启正式白天经营循环和研究所，并激活第一章目标；该独白只显示主角原画。
14. 高级制造所解锁消耗 5000 mine_coin，成功后弹出第一章结束，显示 surface_day。
15. 结算界面点击返回哨所后进入 RETURN_TO_BASE loading，100% 后显示“按下任意按钮继续”，玩家按任意按钮后才回局外。
16. RETURN_TO_BASE loading 不增加 surface_day，不提交出发装备，不启用局内控制。
```

## 9. 验收标准

- 新档创建、保存、重启读取正常。
- 开场视频、回到404哨所与背景故事对白、首次出发任务对白、首次返回剧情只触发一次。
- 新档序章研究所和高级制造所锁定；首次成功返回剧情结束后开启正式白天经营循环和研究所。
- 剧情对白能显示主角和 404 哨所管理员原画，并随 speaker_id 正确切换高亮；所有立绘均在最左侧左对齐，`PORTRAIT_SLOT_CENTER_X_RATIO` 保持 `0.26`。
- 确认出发后进入加载界面，加载完成后等待任意按钮才进入可操作局内。
- 第二日首次进入局内时会播放暗潮物质视频和主角独白，期间所有局内计时冻结。
- 结算返回哨所进入 loading，加载完成后等待任意按钮才回到局外。
- 加载失败能回滚待出发装备，不增加 surface_day。
- 第一章目标能显示矿币进度。
- 5000 矿币能解锁制造所。
- 解锁后章节完成弹窗显示天数。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 25-05 Godot 模块与数据配置
  作为 开发者
  我希望按本文规则完成 25-05 Godot 模块与数据配置
  以便对应功能、数据和验收保持一致

  Scenario: 按本文规则完成核心行为
    Given 已读取 `Doc/00_AI开工入口.md`
    And 已读取 `Doc/00_BDD需求文档规范.md`
    And 当前任务属于 "25_主菜单玩家档案与剧情章节目标系统"
    When 根据本文新增、修改或验证对应功能
    Then 必须覆盖本文定义的前置条件、触发行为、结果反馈和边界情况
    And 必须把验证结果记录到本文验收标准或对应调试验证清单
```

验收方式：
- 文本验证：检查本文是否保留 `Feature`、`Scenario`、`Given`、`When`、`Then`。
- 执行验证：按本文既有“验收标准/调试工具/最小交付清单”执行。
- 缺口记录：若本文尚未拆出具体失败或边界场景，后续需求整理时继续补齐。
