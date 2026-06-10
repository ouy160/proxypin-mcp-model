# 简化需求要点

## 需求
消除 `lib/ui/toolbox/mcp_server_page.dart` 中 `_buildConfigGuide` 与 `_buildGroupedTools` 对 `McpTools.getToolDefinitions()` 的重复调用。

## 修改范围
- `lib/ui/toolbox/mcp_server_page.dart`（单文件）

## 模块依赖分析
**前端模块**：
- `_McpServerPageState._buildConfigGuide`（行 330-383）
- `_McpServerPageState._buildGroupedTools`（行 386-393）

**后端模块**：
- `McpTools.getToolDefinitions()`（静态方法，每次调用返回新建 List，无副作用）

**修改影响范围**：
- 主修改点：`_buildGroupedTools` 签名增加 `List<Map<String, dynamic>> tools` 参数
- 连带修改点：`_buildConfigGuide` 内对 `_buildGroupedTools(theme)` 的调用改为 `_buildGroupedTools(tools, theme)`

**适配清单**：
- 无外部调用方（私有方法）
- 无 API 变更

## 验收标准
1. `_buildConfigGuide` 函数体内（含其调用的子方法）`McpTools.getToolDefinitions()` 仅出现 1 次
2. `_buildGroupedTools` 函数体内 `McpTools.getToolDefinitions()` 出现 0 次
3. `_buildGroupedTools` 签名变为 `List<Widget> _buildGroupedTools(List<Map<String, dynamic>> tools, ThemeData theme)`
4. UI 显示行为不变：tools 数量、列表渲染保持一致

## 创建时间
26-06-11-03-56-30
