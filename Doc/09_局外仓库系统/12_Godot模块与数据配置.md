# 09-12 Godot 模块与数据配置

> 来源文档：`09_局外仓库系统_修订版_废土生存法则.md`
> 施工补充：开工前必须读取 `15_模块功能规则细化与AI开工提示词.md`、`Doc/29_局外杂货店经营与界面重构路线图.md`、`Doc/30_昼夜局外流程_店铺营业与夜间出发准备.md`、`Doc/31_掉落物资与制造经济规划.md`。

## 1. 推荐模块

```text
systems/warehouse/warehouse_manager.gd
systems/warehouse/warehouse_data.gd
systems/warehouse/warehouse_item.gd
systems/warehouse/settlement_transfer_service.gd
systems/warehouse/warehouse_query_service.gd
systems/warehouse/shelf_inventory_service.gd
systems/warehouse/currency_wallet.gd
systems/catalog/item_catalog_service.gd
systems/warehouse/warehouse_ui.gd
systems/catalog/catalog_ui.gd
systems/warehouse/warehouse_save_service.gd
systems/warehouse/warehouse_debug_panel.gd
systems/ui/item_tooltip/item_tooltip_service.gd
systems/ui/item_tooltip/item_tooltip_data_builder.gd
systems/ui/item_tooltip/item_tooltip_data.gd
systems/ui/item_tooltip/hoverable_item_icon.gd
scenes/ui/common/ItemTooltipPanel.tscn
scenes/ui/common/ItemTooltipPanel.gd
```

## 2. 推荐配置

```text
data/warehouse/default_warehouse_config.tres
data/warehouse/warehouse_sort_rules.tres
data/currencies.tab
data/items.tab
setting/sale_good_recipes.tab
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

- 给研究、制作、货台、出发准备查询和消耗。

ShelfInventoryService：

- 查询可上架的 `sale_good` 物资。
- 处理货台上架、撤下、成交扣货和未售出回仓。
- 确保货台事务原子化，失败不丢货、不重复扣货、不重复记账。

CurrencyWallet：

- 保存玩家持有货币字典。
- 通过 currency_id 增减和查询货币。
- 读取 DataRegistry 中 currencies.tab 的静态定义用于显示。
- 货币收入由店铺营业结算、系统奖励等业务服务调用，不由仓库 UI 直接修改。

ItemCatalogService：

- 绑定玩家存档中的 `collected_item_ids`。
- 从 items.tab 查询所有可展示道具并组装图鉴卡片数据。
- 在玩家获得道具时写入 item_id 点亮记录。
- 成交、消耗、升级使用、制作使用、丢弃和仓库清空不得移除点亮记录。
- 提供 `mark_collected`、`is_collected`、`get_catalog_items` 等只读/写入接口。

ItemTooltipService：

- 只在局外 BaseScene 的 TooltipLayer 中启用。
- 接收仓库、货台、研究所、制造所、图鉴和出发准备中的道具图标 hover 请求。
- 通过 ItemTooltipDataBuilder 从 items.tab 和 currencies.tab 构建展示数据。
- 处理 hover 延迟、显示位置、屏幕边界、切换功能入口/滚动/拖拽/弹窗时隐藏。

HoverableItemIcon：

- 挂在局外道具图标 Control 上。
- 持有 item_id 或 warehouse_item_id。
- 监听 mouse_entered / mouse_exited，并调用 ItemTooltipService。
- 禁止接入局内背包、局内容器、拾取提示和结算界面。

## 4. AI/MCP 开工提示词

```text
请建立 09 局外仓库系统 Godot 模块骨架。
要求：
1. 创建 WarehouseManager、WarehouseData、WarehouseItem、SettlementTransferService、WarehouseQueryService、ShelfInventoryService、CurrencyWallet、WarehouseUI、WarehouseSaveService。
2. 08 入库通过 SettlementTransferService。
3. 10 研究所、制造所、货台、出发准备通过 WarehouseQueryService。
4. 货台上架、撤下、成交扣货和未售出回仓通过 ShelfInventoryService；原材料 material 不能直接上架。
5. 货币通过 CurrencyWallet 按 currency_id 保存；店铺营业结算调用 CurrencyWallet 增加收入。
6. 仓库或货币变更后保存并 revision +1。
7. 不要让外部系统直接修改 WarehouseData.items 或 currencies。
8. 建立局外通用 ItemTooltipService / HoverableItemIcon / ItemTooltipPanel，仓库、货台、研究所、制造所、图鉴、出发准备中的道具图标 hover 时显示详情，数据来自 items.tab 和 currencies.tab。
9. 建立 ItemCatalogService 和图鉴入口，图鉴读取 items.tab 全量道具和 collected_item_ids 点亮状态，每行四张卡片，纵向滚动。
```

## 5. 验收标准

- 模块职责清楚。
- 08/10/货台/出发准备可通过接口接入。
- 仓库界面不提供旧式直接变现入口。
- 货台只接受 `sale_good` 可售物资，原材料不能上架。
- 店铺营业结算后通过 CurrencyWallet 增加 mine_coin。
- 保存服务独立。
- 局外道具详情 Tooltip 模块职责独立，且不接入局内界面。
- 图鉴模块职责独立，只记录曾经获得过的 item_id，不影响仓库数量、成交和消耗。

## 6. 暂不实现

- 云同步。
- 完整视觉皮肤。

## BDD 场景补充

```gherkin
Feature: 09-12 Godot 模块与数据配置
  作为 开发者
  我希望 仓库模块为制造、货台、图鉴和出发准备提供稳定接口
  以便 局外经营不会由 UI 直接改仓库或货币

  Scenario: 货台成交通过服务扣货
    Given 仓库中有 good_water_filter
    When 货台成交 good_water_filter
    Then ShelfInventoryService 应原子扣除货台物资
    And CurrencyWallet 应由营业结算阶段统一增加收入
```

验收方式：
- 文本验证：检查本文是否保留 `Feature`、`Scenario`、`Given`、`When`、`Then`。
- 执行验证：按本文既有“验收标准/调试工具/最小交付清单”执行。
