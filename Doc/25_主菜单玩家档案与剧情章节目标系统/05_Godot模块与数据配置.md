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
systems/flow/run_load_context.gd
systems/flow/run_load_task.gd
systems/flow/loading_screen_mode.gd

systems/dialogue/dialogue_sequence.gd
systems/dialogue/dialogue_service.gd
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
scenes/ui/DialoguePanel.tscn
scenes/ui/ChapterGoalPopup.tscn
scenes/ui/ChapterCompletePopup.tscn
scenes/ui/RunLoadingScreen.tscn
```

## 3. 推荐数据

```text
data/cinematics/opening_intro_cinematic.json
data/dialogue/world_intro_dialogue.json
data/dialogue/first_departure_outpost_dialogue.json
data/dialogue/first_return_chapter_1_dialogue.json
data/chapters/chapter_1.json
data/loading/run_loading_stages.json
data/loading/run_loading_tips.json
```

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

`chapter_1.json` 示例：

```json
{
  "chapter_id": "chapter_1",
  "title": "第一章：解锁制造所",
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
- 通知 `GameFlowController` 进入第一段世界观对白。

DialogueService：

- 播放 DialogueSequence。
- 支持逐字显示。
- 支持跳过。
- 播放完成回调。
- 分别处理 `world_intro_dialogue`、`first_departure_outpost_dialogue`、`first_return_chapter_1_dialogue`。

ChapterProgressService：

- 管理当前章节。
- 更新目标进度。
- 判断制造所是否可解锁。
- 触发章节完成。

ManufacturingUnlockService：

- 校验 5000 矿币。
- 调用 CurrencyWallet 扣币。
- 写入制造所解锁。
- 触发第一章结束弹窗。

RunLoadingController：

- 接收 `LoadoutManager` 生成的待出发快照。
- 按阶段加载 RunScene、地图、玩家、背包、前哨、容器、撤离、HUD 和音频。
- 通过任务权重驱动进度条。
- 加载成功后进入 `READY_TO_CONTINUE`，显示“按下任意按钮继续”。
- 玩家按任意按钮后通知 `GameFlowController` 进入局内。
- 加载失败时通知 `LoadoutManager` 回滚待出发装备。
- 支持 `RETURN_TO_BASE` mode：结算后返回哨所 loading 到 100% 后等待任意按钮，再通知 `GameFlowController` 回到局外。

## 5. 信号建议

```gdscript
signal profile_created(profile)
signal profile_loaded(profile)
signal intro_cinematic_finished(skipped)
signal dialogue_started(dialogue_id)
signal dialogue_finished(dialogue_id)
signal chapter_goal_updated(chapter_id, current, required)
signal feature_unlocked(feature_id)
signal chapter_completed(chapter_id, surface_day)
signal run_loading_started(run_id)
signal run_loading_progress_changed(progress, stage_id, stage_text)
signal run_loading_failed(reason)
signal run_loading_completed(run_context)
signal run_loading_ready_to_continue(run_context)
signal run_enter_committed(run_context)
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
- 重置世界观对白 flag。
- 重置首次出发任务对白 flag。
- 重置首次返回剧情 flag。
- 增加 5000 矿币。
- 强制完成第一章。
- surface_day +1。
- 强制慢速出发加载。
- 强制下一次出发加载失败。
- 打印出发加载阶段和进度。
- 强制慢速返回哨所加载。
- 强制下一次返回哨所加载失败。
- 打印返回哨所加载阶段和进度。

Debug 操作必须只在 Debug 模式显示。

## 8. AI/MCP 开工提示词

```text
请根据 Doc/25_主菜单玩家档案与剧情章节目标系统 实现 Godot 模块骨架。

要求：
1. 建立 MainMenuScene、UsernameInputDialog、DialoguePanel、ChapterGoalPopup、ChapterCompletePopup、RunLoadingScreen。
2. 建立 ProfileService、SaveStorageAdapter、DialogueService、ChapterProgressService、ManufacturingUnlockService、RunLoadingController。
3. 玩家档案保存 username、surface_day、intro_cinematic_seen、world_intro_dialogue_seen、first_departure_outpost_dialogue_seen、first_return_dialogue_seen、manufacturing_station_unlocked、chapter_1_completed。
4. 桌面保存到 user://profile/profile.json；Web 通过 WebSaveStorageAdapter 适配，不在 UI 中写平台判断。
5. 新档创建后播放 opening_intro_cinematic；视频可跳过，跳过后仍进入 world_intro_dialogue。
6. world_intro_dialogue 完成后进入局外仓库/商人/研究所/出发准备界面。
7. 玩家第一次点击出发探索且校验通过后，播放 first_departure_outpost_dialogue。
8. first_departure_outpost_dialogue 完成后进入 RunLoadingScreen，由 RunLoadingController 加载局内资源。
9. 出发加载到 100% 后显示“按下任意按钮继续”，并展示操作提示与稳定值/视野说明。
10. 玩家按任意按钮后才提交 IN_RUN、surface_day +1，并保存 run_start。
11. 首次成功撤离返回后播放 first_return_chapter_1_dialogue，并激活第一章目标。
12. 制造所解锁消耗 5000 mine_coin，成功后弹出第一章结束，显示 surface_day。
13. 结算界面点击返回哨所后进入 RETURN_TO_BASE loading，100% 后显示“按下任意按钮继续”，玩家按任意按钮后才回局外。
14. RETURN_TO_BASE loading 不增加 surface_day，不提交出发装备，不启用局内控制。
```

## 9. 验收标准

- 新档创建、保存、重启读取正常。
- 开场视频、世界观对白、首次出发任务对白、首次返回剧情只触发一次。
- 确认出发后进入加载界面，加载完成后等待任意按钮才进入可操作局内。
- 结算返回哨所进入 loading，加载完成后等待任意按钮才回到局外。
- 加载失败能回滚待出发装备，不增加 surface_day。
- 第一章目标能显示矿币进度。
- 5000 矿币能解锁制造所。
- 解锁后章节完成弹窗显示天数。
