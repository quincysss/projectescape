# 09-12 Godot 模块与数据配置

> 来源文档：`09_局外仓库系统_修订版_废土生存法则.md`
> 施工补充：开工前必须读取 `15_模块功能规则细化与AI开工提示词.md`。

## 1. 推荐模块

```text
systems/warehouse/warehouse_manager.gd
systems/warehouse/warehouse_data.gd
systems/warehouse/warehouse_item.gd
systems/warehouse/settlement_transfer_service.gd
systems/warehouse/warehouse_query_service.gd
systems/warehouse/warehouse_ui.gd
systems/warehouse/warehouse_save_service.gd
systems/warehouse/warehouse_debug_panel.gd
```

## 2. 推荐配置

```text
data/warehouse/default_warehouse_config.tres
data/warehouse/warehouse_sort_rules.tres
```

## 3. 模块职责

WarehouseManager：

- 管理仓库数据。
- 入库、移动、丢弃、堆叠。
- 发出变更信号。

SettlementTransferService：

- 接 08 结算条目。
- 返回 stored/overflow/rejected。

WarehouseQueryService：

- 给研究、制作、出发准备查询和消耗。

## 4. AI/MCP 开工提示词

```text
请建立 09 局外仓库系统 Godot 模块骨架。
要求：
1. 创建 WarehouseManager、WarehouseData、WarehouseItem、SettlementTransferService、WarehouseQueryService、WarehouseUI、WarehouseSaveService。
2. 08 入库通过 SettlementTransferService。
3. 10 研究所、制作所、出发准备通过 WarehouseQueryService。
4. 仓库变更后保存并 revision +1。
5. 不要让外部系统直接修改 WarehouseData.items。
```

## 5. 验收标准

- 模块职责清楚。
- 08/10/出发准备可通过接口接入。
- 保存服务独立。

## 6. 暂不实现

- 云同步。
- 完整视觉皮肤。
