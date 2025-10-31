import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsStorage {
  // 保存 JSON 数据（以字符串形式存储）
  static Future<void> saveJson({
    required String key, // 存储的键（如 "user_data"）
    required Map<String, dynamic> jsonData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // 将 JSON Map 转为字符串
    final jsonString = jsonEncode(jsonData);
    // 存储字符串
    await prefs.setString(key, jsonString);
    print('JSON 保存到 SharedPreferences 成功');
  }

  static Future<void> save(
      {required String key, required String jsonValue}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonValue);
    print('JSON 保存到 SharedPreferences 成功');
  }

  // 读取 JSON 数据
  static Future<Map<String, dynamic>?> readJson({
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // 读取字符串
    final jsonString = prefs.getString(key);
    print('jsonString $jsonString');
    if (jsonString == null) {
      print('未找到 key 为 $key 的数据');
      return null;
    }
    // 将字符串转为 JSON Map
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// 查找键包含指定前缀的键值对（复用之前的前缀筛选逻辑）
  static Future<Map<String, dynamic>> findByKeyPrefix(String prefix) {
    return findWhere((key, value) => key.startsWith(prefix));
  }

  /// 条件查找：筛选值符合条件的键值对
  /// [condition]：筛选条件（参数为键和值，返回 bool 表示是否符合）
  static Future<Map<String, dynamic>> findWhere(
    bool Function(String key, dynamic value) condition,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final Map<String, dynamic> result = {};

    for (final key in allKeys) {
      final value = prefs.get(key); // 获取值（可能是 String、int、bool 等）
      if (condition(key, value)) {
        // 应用条件判断
        result[key] = value;
      }
    }

    // result.forEach((key, value) {
    //   print('prefs查询数据: $key _ _ $value');
    // });

    return result;
  }

  /// 查找值为指定字符串的键值对
  static Future<Map<String, dynamic>> findByStringValue(String targetValue) {
    return findWhere((key, value) => value is String && value == targetValue);
  }

  /// 查找数值（int/double）大于指定值的键值对
  static Future<Map<String, dynamic>> findNumbersGreaterThan(num minValue) {
    return findWhere((key, value) {
      if (value is int) return value > minValue;
      if (value is double) return value > minValue;
      return false;
    });
  }

  // 清除所有存储的数据
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // 清除所有数据
    bool success = await prefs.clear();

    if (success) {
      print('所有数据已清除');
    } else {
      print('清除数据失败');
    }
  }

  // 删除指定键的数据
  static Future<void> deleteData(String key) async {
    // 获取SharedPreferences实例
    final prefs = await SharedPreferences.getInstance();

    // 调用remove方法删除指定键的数据
    bool success = await prefs.remove(key);

    if (success) {
      print('删除成功: $key');
    } else {
      print('删除失败或键不存在: $key');
    }
  }
}
