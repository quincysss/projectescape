# 08-12 Godot 模块与数据配置

> 来源文档：`08_撤离与结算系统_修订版_废土生存法则.md`
> 施工补充：开工前必须读取 `15_模块功能规则细化与AI开工提示词.md`。

## 1. 推荐模块

```text
systems/extraction/extraction_controller.gd
systems/extraction/extraction_point.gd
systems/extraction/run_result_builder.gd
systems/extraction/settlement_transfer_service.gd
systems/extraction/settlement_ui.gd
systems/extraction/settlement_return_controller.gd
systems/extraction/return_to_base_loading_controller.gd
systems/extraction/return_to_base_load_context.gd
systems/extraction/run_stats_tracker.gd
systems/extraction/extraction_debug_panel.gd
```

## 2. 推荐配置

```text
data/extraction/extraction_rules.tres
data/extraction/settlement_sources.tres
data/extraction/run_stats_config.tres
```

## 3. 模块职责

ExtractionController：

- 管理撤离条件。
- 管理结束类型。
- 防止重复结算。

RunResultBuilder：

- 收集物品来源。
- 构建结算条目。
- 汇总统计。

SettlementTransferService：

- 调用 09 仓库接口。
- 更新结算条目状态。

SettlementReturnController：

- 接收 `返回哨所` 按钮请求。
- 防止重复提交结算。
- 创建返回 loading 上下文。

ReturnToBaseLoadingController：

- 复用 loading 条权重和平滑机制。
- 执行结算提交、仓库保存、局内清理和局外首帧预热。
- 100% 后等待任意按钮再通知 `GameFlowController` 回到局外。

## 4. AI/MCP 开工提示词

```text
请建立 08 撤离与结算系统的 Godot 模块骨架。
要求：
1. 创建 ExtractionController、ExtractionPoint、RunResultBuilder、SettlementTransferService、SettlementUI、SettlementReturnController、ReturnToBaseLoadingController、RunStatsTracker。
2. ExtractionController 不直接写仓库。
3. SettlementTransferService 通过 09 仓库接口入库。
4. RunResultBuilder 从 07 背包和 06 前哨收集 payload。
5. 所有结束流程防重复触发。
6. 结算返回哨所必须走 ReturnToBaseLoadingController，不能直接切回局外。
```

## 5. 验收标准

- 模块边界清楚。
- 08 不复制仓库逻辑。
- 08 能接入 06、07、09。
- 返回 loading 能接入 GameFlowController 回到局外。

## 6. 暂不实现

- 结算动画资源。
- 联机结算服务。
