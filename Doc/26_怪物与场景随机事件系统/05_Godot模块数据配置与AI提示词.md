# 26-05 Godot 模块、数据配置与 AI/MCP 提示词

> 目标：整理场景随机事件系统的脚本、场景、配置表、信号和总开工提示词，覆盖怪物、时间事件、随机障碍三条落地线。

## 1. 推荐模块

场景事件：

```text
scripts/events/scene_random_event_director.gd
scripts/events/run_event_context.gd
scripts/events/scene_random_event_definition.gd
scripts/events/run_time_event_applier.gd
```

地图点位：

```text
scripts/map/monster_spawn_point.gd
scripts/map/random_obstacle_spawn_point.gd
```

怪物：

```text
scripts/monsters/monster_spawn_controller.gd
scripts/monsters/monster_basic.gd
scripts/monsters/monster_patrol_controller.gd
scripts/monsters/monster_vision_cone.gd
```

随机障碍：

```text
scripts/obstacles/random_obstacle_controller.gd
scripts/obstacles/random_obstacle_entity.gd
scripts/obstacles/random_obstacle_definition.gd
```

UI：

```text
scripts/ui/monster_vision_cone_view.gd
scripts/ui/run_event_toast_view.gd
```

Debug：

```text
scripts/debug/monster_spawn_validator.gd
scripts/debug/random_obstacle_spawn_validator.gd
scripts/debug/scene_event_debug_overlay.gd
```

## 2. 推荐场景

```text
scenes/monsters/MonsterBasic.tscn
scenes/obstacles/RandomObstacleEntity.tscn
scenes/debug/DebugSceneRandomEvents.tscn
```

## 3. 推荐数据表

```text
setting/scene_random_events.tab
setting/monster_defs.tab
setting/monster_spawn_points.tab
setting/random_obstacle_defs.tab
setting/random_obstacle_spawn_points.tab
```

`scene_random_events.tab` 建议字段：

```text
event_id	display_name	slot	min_day	guaranteed_day	daily_chance	conflict_group	can_stack	gm_forceable	payload	notes
monster_presence	怪物出现	threat	3	3	0.50		false	true	monster_count=4;spawn_group=monster_spawn_street	第三日必出，之后每日50%
super_time	超级时间	time_modifier	3		0.10	run_duration	false	true	duration_seconds=480	本局对局时长8分钟
short_time	超短时间	time_modifier	3		0.10	run_duration	false	true	duration_seconds=210	本局对局时长3分30秒
road_obstacle	随机障碍	map_blocker	3		0.30		true	true	count_min=2;count_max=4;spawn_group=random_obstacle_spawn	生成玩家不可通过障碍
```

`monster_defs.tab` 建议字段：

```text
monster_id	display_name	patrol_speed	charge_speed	vision_angle	vision_radius	warning_seconds	stability_damage	patrol_radius
basic_shadow	暗潮游荡体	45	180	70	220	5	20	180
```

`random_obstacle_defs.tab` 建议字段：

```text
obstacle_id	display_name	texture_path	block_shape	collider_size	player_blocks	monster_blocks	weight
ground_decal_block	破裂地面	res://assets/map/decals/overlays/ground_decal_overlay_002.png	wide	96x64	true	false	1
road_cone_cluster	路锥堆	res://assets/map/props/placement/road_cone_01.png	small	64x48	true	false	2
broken_signboard	倒塌路牌	res://assets/map/props/placement/broken_signboard_blank_01.png	line	128x48	true	false	2
```

点位表可选。如果点位全部来自场景节点，则 `monster_spawn_points.tab` 和 `random_obstacle_spawn_points.tab` 只做校验导出。

## 4. RunContext 字段

建议增加：

```gdscript
{
    "run_day_index": 3,
    "base_run_duration_seconds": 300,
    "run_duration_seconds": 300,
    "scene_events": {},
    "active_time_event_id": "",
    "monster_event_active": true,
    "monster_spawn_point_ids": [],
    "active_monster_ids": [],
    "obstacle_event_active": false,
    "obstacle_spawn_point_ids": [],
    "active_obstacle_ids": []
}
```

`run_duration_seconds` 必须来自事件解析结果。没有时间事件时才使用默认 300。

## 5. 信号汇总

随机事件：

```gdscript
signal scene_events_resolved(run_day_index: int, events: Dictionary)
signal scene_event_forced(event_id: StringName)
signal scene_event_rejected(event_id: StringName, reason: StringName)
```

时间事件：

```gdscript
signal run_duration_resolved(duration_seconds: int, source_event_id: StringName)
```

怪物生成：

```gdscript
signal monsters_spawned(monster_ids: Array)
signal monster_alert_started(monster_id, player_id)
signal monster_charged(monster_id, player_id)
signal monster_hit_player(monster_id, stability_damage)
```

随机障碍：

```gdscript
signal random_obstacles_spawned(obstacle_ids: Array)
signal random_obstacle_rejected(point_id: StringName, reason: StringName)
signal random_obstacle_path_validation_completed(success: bool)
```

## 6. 依赖关系

| 系统 | 依赖 |
| --- | --- |
| 02 核心循环 | 初始化 RunContext、对局时长、场景事件 |
| 03 地图 | 读取 `monster_spawn_street` 与 `random_obstacle_spawn` 点位 |
| 04 稳定值 | 怪物碰撞调用 `apply_instant_delta(-20, "monster_contact")` |
| 08 撤离 | 对局时间归零仍按现有失败规则处理 |
| 20 UI | 渲染怪物扇形视野、顶部实际倒计时 |
| GM/Debug | 强制事件、显示点位、验证障碍路径 |

## 7. 总 AI/MCP 开工提示词

```text
请实现 V0.1 场景随机事件系统。

必须读取：
Doc/26_怪物与场景随机事件系统/00_系统总览与落地边界.md
Doc/26_怪物与场景随机事件系统/01_场景随机事件框架.md
Doc/26_怪物与场景随机事件系统/02_怪物街道点位与生成规则.md
Doc/26_怪物与场景随机事件系统/03_怪物巡逻视野警戒与冲撞.md
Doc/26_怪物与场景随机事件系统/04_GM调试面板与验证清单.md
Doc/26_怪物与场景随机事件系统/06_时间类随机事件规则.md
Doc/26_怪物与场景随机事件系统/07_随机障碍事件规则.md
Doc/03_地图与安全区规则/14_怪物街道刷新点位.md
Doc/03_地图与安全区规则/15_随机障碍点位.md

实现目标：
1. 新增 SceneRandomEventDirector 和 RunEventContext，按 run_day_index=surface_day+1 抽取事件。
2. 第 1/2 日不自然触发任何场景随机事件；第 3 日开始启用事件池。
3. monster_presence 第 3 日必出，第 4 日后每日 50%，GM 强制优先。
4. 地图读取 10 个 monster_spawn_street 点位，怪物事件命中时抽 4 个生成 MonsterBasic。
5. super_time 与 short_time 从第 3 日后可抽取，二者互斥。
6. super_time 让本局 run_duration_seconds=480，short_time 让本局 run_duration_seconds=210；默认局为 300。
7. road_obstacle 从第 3 日后可抽取，命中后读取 10 个 random_obstacle_spawn 点位，生成 2-4 个障碍。
8. 障碍使用 ground_decal_overlay_002.png、road_cone_01.png、broken_signboard_blank_01.png 之一。
9. 障碍必须阻挡玩家，但怪物可以穿过。
10. 障碍生成后必须做主流程路径校验，不可堵死前哨、材料点或撤离路线。
11. GM 面板支持强制怪物、强制超级时间、强制超短时间、强制随机障碍。

禁止范围：
- 不实现雨天、污染风暴、高收益窗口的真实效果。
- 不实现怪物掉落、怪物血量、玩家攻击怪物。
- 不让时间事件永久修改全局默认对局时长。
- 不让随机障碍阻挡怪物。

完成后请验证：
- 第 1/2/3/4 日事件规则。
- 默认 05:00、超级时间 08:00、超短时间 03:30。
- 怪物事件命中生成 4 个怪物。
- 玩家进扇形 5 秒触发冲撞。
- 碰撞后稳定值 -20，怪物消失。
- 随机障碍生成 2-4 个，玩家无法通过，怪物可通过。
- 障碍不会堵死主流程路线。
```

## 8. 最小验收

- 场景随机事件池从第 3 日开始启用。
- `RunEventContext` 能记录所有本局事件结果。
- `monster_presence` 能按规则命中并生成 4 个怪物。
- `super_time/short_time` 能正确改写当前局倒计时。
- `road_obstacle` 能按规则生成障碍并做路径校验。
- GM 面板能强制所有当前事件。

## 9. 当前落地状态（2026-05-12）

本次已落地的实际模块如下：

| 类型 | 路径 |
| --- | --- |
| 事件上下文 | `res://scripts/events/run_event_context.gd` |
| 事件解析 | `res://scripts/events/scene_random_event_director.gd` |
| 事件配置 | `res://setting/scene_random_events.tab` |
| 怪物配置 | `res://setting/monster_defs.tab` |
| 怪物生成 | `res://scripts/monsters/monster_spawn_controller.gd` |
| 怪物行为 | `res://scripts/monsters/monster_basic.gd` |
| 视野绘制 | `res://scripts/monsters/monster_vision_cone.gd` |
| 怪物场景 | `res://scenes/entities/monsters/MonsterBasic.tscn` |
| 地图点位 | `RunScene/WorldRoot/MapLayout/Points/MonsterSpawnPoints` |
| GM 强制 | `GameState.debug_force_monster_presence_next_run()` 与 BaseScene 调试按钮 |

当前和推荐稿有两点实现差异：

- 怪物点位没有新建 `MonsterSpawnPoint.gd`，而是复用 `map_layout_point.gd` 并新增 `point_type = "monster"`。
- 扇形视野没有单独拆 `monster_vision_cone_view.gd`，当前由 `monster_vision_cone.gd` 直接绘制。

2026-05-12 优化补充：

- 怪物刷新点支持子层 `PatrolPath/Patrol_XX`，`monster_spawn_controller.gd` 会读取这些子点作为巡逻轨迹。
- `map_layout_point.gd` 会在编辑器中为怪物刷新点绘制橙色巡逻线，方便直接调整路径。
- `MonsterBasic` 的视野锚点改为读取表现资源 `EyeFocus`，视觉绘制与判定都以眼睛位置为准。
- `black_tide_boundary_essence_visual.gd` 会按表现缩放同步 `EyeFocus` 与碰撞参考位置。

本次验证命令覆盖：

```text
Godot --headless --path . --script res://tests/scene_random_event_rules_check.gd
Godot --headless --path . --script res://tests/monster_spawn_and_behavior_check.gd
Godot --headless --path . --script res://tests/map_spawn_point_sanity_check.gd
Godot --headless --path . --script res://tests/editor_layout_exposure_check.gd
Godot --headless --path . --script res://tests/run_core_loop_check.gd
Godot --headless --path . --script res://tests/run_playable_loop_check.gd
Godot --headless --path . --script res://tests/base_debug_panel_check.gd
```
