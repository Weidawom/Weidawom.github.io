import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

/// 更新信息模型
class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String releaseTime;
  final String apkUrl;
  final List<dynamic> changelog;

  UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.releaseTime,
    required this.apkUrl,
    required this.changelog,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '1.0.0',
      releaseNotes: json['release_notes'] ?? '',
      releaseTime: json['release_time'] ?? '',
      apkUrl: json['apk_url'] ?? '',
      changelog: json['changelog'] ?? [],
    );
  }
}

/// 自动更新服务
class UpdateService {
  static const String updateServerUrl = 'http://100.69.100.122:8081';
  
  /// 检查更新
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse('$updateServerUrl/version'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UpdateInfo.fromJson(data);
      }
    } catch (e) {
      print('检查更新失败: $e');
    }
    return null;
  }
  
  /// 比较版本号
  static Future<bool> isNewVersionAvailable(UpdateInfo updateInfo) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // 简单版本比较（可以改进为更精确的语义版本比较）
      return updateInfo.version != currentVersion;
    } catch (e) {
      print('版本比较失败: $e');
      return false;
    }
  }
  
  /// 下载并安装APK
  static Future<void> downloadAndInstallApk(BuildContext context, String apkUrl) async {
    try {
      // 请求存储权限
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('需要存储权限才能下载更新')),
          );
          return;
        }
      }
      
      // 显示下载进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('下载更新'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在下载...'),
            ],
          ),
        ),
      );
      
      // 下载APK
      final taskId = await FlutterDownloader.enqueue(
        url: apkUrl,
        savedDir: '/sdcard/Download',
        fileName: 'chengxiang_update.apk',
        showNotification: true,
        openFileFromNotification: true,
      );
      
      if (taskId != null) {
        // 监听下载进度
        FlutterDownloader.registerCallback((id, status, progress) {
          print('下载进度: $progress%');
          
          if (status == DownloadTaskStatus.complete) {
            // 下载完成，安装APK
            installApk('/sdcard/Download/chengxiang_update.apk');
            Navigator.of(context).pop(); // 关闭对话框
          }
        });
      }
    } catch (e) {
      print('下载失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $e')),
      );
    }
  }
  
  /// 安装APK
  static Future<void> installApk(String apkPath) async {
    try {
      await OpenFile.open(apkPath);
    } catch (e) {
      print('安装失败: $e');
    }
  }
  
  /// 显示更新对话框
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('发现新版本 v${updateInfo.version}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('更新内容：', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(updateInfo.releaseNotes),
              SizedBox(height: 16),
              Text('发布时间: ${updateInfo.releaseTime}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('稍后再说'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              downloadAndInstallApk(context, updateInfo.apkUrl);
            },
            child: Text('立即更新'),
          ),
        ],
      ),
    );
  }
}
