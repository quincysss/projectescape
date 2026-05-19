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
systems/warehouse/merchant_service.gd
systems/warehouse/currency_wallet.gd
systems/catalog/item_catalog_service.gd
systems/warehouse/warehouse_ui.gd
systems/warehouse/merchant_ui.gd
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

MerchantService：

- 只允许在 `PlayerProfile.merchant_unlocked == true` 后被 MerchantPanel 调用出售流程。
- 查询仓库中可出售物品。
- 根据 items.tab 的 sell_currency_id 和 sell_value 计算售价。
- 调用 WarehouseManager 扣除售卖数量。
- 调用 CurrencyWallet 增加 currency_id 对应货币。
- 返回出售结果和失败 reason。

CurrencyWallet：

- 保存玩家持有货币字典。
- 通过 currency_id 增减和查询货币。
- 读取 DataRegistry 中 currencies.tab 的静态定义用于显示。

ItemCatalogService：

- 绑定玩家存档中的 `collected_item_ids`。
- 从 items.tab 查询所有可展示道具并组装图鉴卡片数据。
- 在玩家获得道具时写入 item_id 点亮记录。
- 出售、消耗、升级使用、制作使用、丢弃和仓库清空不得移除点亮记录。
- 提供 `mark_collected`、`is_collected`、`get_catalog_items` 等只读/写入接口。

ItemTooltipService：

- 只在局外 BaseScene 的 TooltipLayer 中启用。
- 接收仓库、商人、研究所、制作所中的道具图标 hover 请求。
- 通过 ItemTooltipDataBuilder 从 items.tab 和 currencies.tab 构建展示数据。
- 处理 hover 延迟、显示位置、屏幕边界、切页/滚动/拖拽/弹窗时隐藏。

HoverableItemIcon：

- 挂在局外道具图标 Control 上。
- 持有 item_id 或 warehouse_item_id。
- 监听 mouse_entered / mouse_exited，并调用 ItemTooltipService。
- 禁止接入局内背包、局内容器、拾取提示和结算界面。

## 4. AI/MCP 开工提示词

```text
请建立 09 局外仓库系统 Godot 模块骨架。
要求：
1. 创建 WarehouseManager、WarehouseData、WarehouseItem、SettlementTransferService、WarehouseQueryService、MerchantService、CurrencyWallet、WarehouseUI、MerchantUI、WarehouseSaveService。
2. 08 入库通过 SettlementTransferService。
3. 10 研究所、制作所、出发准备通过 WarehouseQueryService。
4. 商人出售通过 MerchantService，货币通过 CurrencyWallet 按 currency_id 保存；MerchantPanel 进入前必须检查 merchant_unlocked。
5. 仓库或货币变更后保存并 revision +1。
6. 不要让外部系统直接修改 WarehouseData.items 或 currencies。
7. 建立局外通用 ItemTooltipService / HoverableItemIcon / ItemTooltipPanel，仓库、商人、研究所、制作所中的道具图标 hover 时显示详情，数据来自 items.tab 和 currencies.tab。
8. 建立 ItemCatalogService 和图鉴页签，图鉴读取 items.tab 全量道具和 collected_item_ids 点亮状态，每行四张卡片，纵向滚动。
```

## 5. 验收标准

- 模块职责清楚。
- 08/10/出发准备可通过接口接入。
- 首次成功返回剧情结束前商人不可进入；解锁后商人可通过接口出售物品并获得 mine_coin。
- 保存服务独立。
- 局外道具详情 Tooltip 模块职责独立，且不接入局内界面。
- 图鉴模块职责独立，只记录曾经获得过的 item_id，不影响仓库数量、交易和消耗。

## 6. 暂不实现

- 云同步。
- 完整视觉皮肤。
## BDD 场景补充

> 初始迁移：本节把本文规则挂接到 BDD 验收链路。后续重整本文时，应继续把关键成功、失败和边界规则拆成独立 Scenario。

```gherkin
Feature: 09-12 Godot 模块与数据配置
  作为 开发者
  我希望按本文规则完成 09-12 Godot 模块与数据配置
  以便对应功能、数据和验收保持一致

  Scenario: 按本文规则完成核心行为
    Given 已读取 `Doc/00_AI开工入口.md`
    And 已读取 `Doc/00_BDD需求文档规范.md`
    And 当前任务属于 "09_局外仓库系统"
    When 根据本文新增、修改或验证对应功能
    Then 必须覆盖本文定义的前置条件、触发行为、结果反馈和边界情况
    And 必须把验证结果记录到本文验收标准或对应调试验证清单
```

验收方式：
- 文本验证：检查本文是否保留 `Feature`、`Scenario`、`Given`、`When`、`Then`。
- 执行验证：按本文既有“验收标准/调试工具/最小交付清单”执行。
- 缺口记录：若本文尚未拆出具体失败或边界场景，后续需求整理时继续补齐。
