// debug_supplement.dart - 补充验证：独立实例 + 重复 close
import 'dart:async';

void main() {
  print('=== B004: 独立实例测试 ===');
  final a = StreamController<bool>.broadcast();
  final b = StreamController<bool>.broadcast();
  a.add(true);
  a.close();

  var aClosedAfterClose = false;
  try {
    a.add(false);
  } on StateError catch (e) {
    aClosedAfterClose = true;
    print('  ✅ A 关闭后 add: 抛出 StateError "${e.message}"');
  }

  var bWorksAfterAClosed = false;
  try {
    b.add(true);
    bWorksAfterAClosed = true;
    print('  ✅ B 仍可正常 add: success');
  } catch (e) {
    print('  ❌ B 异常: $e');
  }

  print('  - A 关闭后无法 add: $aClosedAfterClose');
  print('  - B 不受影响: $bWorksAfterAClosed');
  print('  - B004 结果: ${aClosedAfterClose && bWorksAfterAClosed ? "✅ 通过" : "❌ 失败"}');

  print('\n=== B008: 重复 close 测试 ===');
  final c = StreamController<bool>.broadcast();
  c.close();
  var doubleCloseOk = true;
  try {
    c.close();
    print('  ✅ 二次 close 未抛异常');
  } catch (e) {
    doubleCloseOk = false;
    print('  ❌ 二次 close 抛异常: $e');
  }
  print('  - B008 结果: ${doubleCloseOk ? "✅ 通过" : "❌ 失败"}');
}
