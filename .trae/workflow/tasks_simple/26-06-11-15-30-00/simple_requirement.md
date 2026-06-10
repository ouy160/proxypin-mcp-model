# 简化需求要点

## 需求
修复 ProxyServer 中 _statusController 未关闭导致的内存泄漏问题。在 ProxyServer 中添加 dispose 方法关闭控制器。

## 修改范围
- 文件：`d:\Git\proxypin-mcp\lib\network\bin\server.dart`
- 新增方法：`dispose()`

## 模块依赖分析

**后端模块**：
- `ProxyServer`（`lib/network/bin/server.dart`）：
  - `_statusController` 字段（第 58 行）
  - 新增方法：`dispose()`，调用 `_statusController.close()`

**连带修改点**：
- 无（本次仅在 ProxyServer 类内部新增方法，不修改外部调用方）

**适配清单**：
- 后端适配：无（调用 dispose() 由调用方决定，本任务范围仅添加方法）

## 验收标准
1. ProxyServer 类包含 `dispose()` 方法
2. `dispose()` 方法能正确关闭 `_statusController`
3. 关闭后再次调用 close() 不会抛出异常
4. 关闭后 stream 不再接受新事件（add 调用安全失败）

## 创建时间
26-06-11-15-30-00
