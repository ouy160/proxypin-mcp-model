# 功能测试用例清单

## 修改点
- `lib/ui/toolbox/mcp_server_page.dart`:
  - `_buildGroupedTools` 签名扩展为 `(List<Map<String, dynamic>> tools, ThemeData theme)`
  - `_buildConfigGuide` 调用点改为 `_buildGroupedTools(tools, theme)`
  - 消除 `_buildGroupedTools` 内部的 `McpTools.getToolDefinitions()` 重复调用

## 项目类型
Flutter / Dart（UI 模块）

## 测试维度

### 页面功能测试

| 用例ID | 用例名称 | 测试步骤 | 预期结果 | 对应验收点 | 执行状态 |
|--------|---------|---------|---------|-----------|---------|
| P001 | 工具数量徽标正确显示 | 1) 打开 MCP Server 页面 2) 滚动到"AI 配置指南"卡片 3) 观察 `${tools.length}` 徽标 | 徽标数字等于 `McpTools.getToolDefinitions()` 返回的工具数量 | 验收4（行为不变） | 通过（静态分析） |
| P002 | 工具列表正常渲染 | 1) 打开 MCP Server 页面 2) 滚动到"AI 配置指南"卡片底部 3) 观察工具列表 | 显示与 `McpTools.getToolDefinitions()` 内容一致的列表项 | 验收4（行为不变） | 通过（静态分析） |

### 逻辑测试

| 用例ID | 用例名称 | 测试步骤 | 预期结果 | 对应验收点 | 执行状态 |
|--------|---------|---------|---------|-----------|---------|
| L001 | 一次渲染链路中 getToolDefinitions 仅调用 1 次 | 运行 `debug_v2_fix.py` | 等效总调用次数 == 1 | 验收1、3 | 通过 |
| L002 | `_buildGroupedTools` 不再调用 getToolDefinitions | 静态分析 `_buildGroupedTools` 方法体 | `McpTools.getToolDefinitions()` 出现 0 次 | 验收2 | 通过 |
| L003 | `_buildGroupedTools` 签名包含 tools 参数 | 静态分析签名 | 包含 `List<Map<String, dynamic>> tools` | 验收3 | 通过 |
| L004 | 编译时类型一致 | 检查调用点与签名参数类型匹配 | 调用点传递 `tools`（`List<Map<String, dynamic>>`）和 `theme`（`ThemeData`） | 验收3 | 通过 |

### 后端逻辑测试

| 用例ID | 用例名称 | 测试步骤 | 预期结果 | 对应验收点 | 执行状态 |
|--------|---------|---------|---------|-----------|---------|
| B001 | `McpTools.getToolDefinitions()` 接口契约 | 阅读 `lib/network/mcp/mcp_tools.dart:35` 实现 | 返回 `List<Map<String, dynamic>>`，与 `_buildGroupedTools` 入参类型一致 | 验收3 | 通过 |

### 页面主流程测试

| 用例ID | 用例名称 | 主流程路径 | 测试步骤 | 预期结果 | 对应验收点 | 执行状态 |
|--------|---------|-----------|---------|---------|-----------|---------|
| M001 | 打开页面 → 配置指南渲染完整流程 | Toolbox → MCP Server → 滚动到配置指南 | 1) 启动应用 2) 导航到工具箱 3) 进入 MCP Server 页面 4) 滚动到配置指南 | 配置指南卡片正常显示，包含工具数量徽标和工具列表 | 验收1-4 | 通过（代码层验证） |

## 验收点对应

| 验收点 | 来源 | 覆盖用例 |
|--------|------|---------|
| 验收1 | `_buildConfigGuide` 等效调用 == 1 | L001 |
| 验收2 | `_buildGroupedTools` 内部 0 次调用 | L002 |
| 验收3 | `_buildGroupedTools` 签名含 tools 参数 | L003, L004, B001 |
| 验收4 | UI 行为不变 | P001, P002, M001 |
