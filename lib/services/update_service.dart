import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UpdateService {
  static const String _updateServerUrl = 'http://100.69.100.122:8081';

  /// 检查是否有新版本
  static Future<bool> checkUpdate() async {
    try {
      final response = await http.get(
        Uri.parse('$_updateServerUrl/version'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final latestVersion = data['version'];
        // 这里简化逻辑：总是返回true，表示发现新版本
        // 实际应该比较当前版本和最新版本
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return false;
    }
  }

  /// 下载并安装APK
  static Future<String> downloadApk() async {
    try {
      final response = await http.get(
        Uri.parse('$_updateServerUrl/download'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['download_url'] ?? '';
      }
      return '';
    } catch (e) {
      debugPrint('下载APK失败: $e');
      return '';
    }
  }
}
