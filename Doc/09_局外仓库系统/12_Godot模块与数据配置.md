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
systems/warehouse/warehouse_ui.gd
systems/warehouse/merchant_ui.gd
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
```

## 5. 验收标准

- 模块职责清楚。
- 08/10/出发准备可通过接口接入。
- 首次成功返回剧情结束前商人不可进入；解锁后商人可通过接口出售物品并获得 mine_coin。
- 保存服务独立。
- 局外道具详情 Tooltip 模块职责独立，且不接入局内界面。

## 6. 暂不实现

- 云同步。
- 完整视觉皮肤。
