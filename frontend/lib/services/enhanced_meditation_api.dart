import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class EnhancedMeditationApi {
  static String get baseUrl {
    // 真机测试时，需要替换为您的电脑局域网IP地址
    // 例如：'http://192.168.1.100:8080'
    const String serverIP = '192.168.0.111'; // 请替换为您的实际IP地址
    
    if (Platform.isAndroid) return 'http://$serverIP:8080'; // Android真机
    if (Platform.isIOS) return 'http://$serverIP:8080';     // iOS真机
    return 'http://localhost:8080';      
  }

  /// 生成基于用户反馈优化的冥想内容
  static Future<Map<String, dynamic>> generateEnhancedMeditation({
    required String userId,
    required String mood,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enhanced-meditation/generate-enhanced-meditation'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'mood': mood,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('生成增强冥想失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 获取用户反馈分析结果
  static Future<Map<String, dynamic>> getUserFeedbackAnalysis(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/enhanced-meditation/user/$userId/feedback-analysis'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取反馈分析失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }

  /// 获取用户反馈历史
  static Future<Map<String, dynamic>> getUserFeedbackHistory(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/enhanced-meditation/user/$userId/feedback-history?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('获取反馈历史失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('网络请求失败: $e');
    }
  }
}
