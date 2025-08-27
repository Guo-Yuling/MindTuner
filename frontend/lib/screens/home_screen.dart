import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../widgets/mood_button.dart';
import '../utils/constants.dart';
import '../services/meditation_api.dart';
import '../services/audio_service.dart';
import '../services/reminder_service.dart';
import '../services/meditation_stats_service.dart';
import 'meditation_screens.dart';
import 'settings_screen.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart'; // Added import for ProfileScreen
import 'meditation_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String? userEmail;
  final String? userDisplayName;
  
  const HomeScreen({
    super.key,
    this.userId,
    this.userEmail,
    this.userDisplayName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMood = '';
  final TextEditingController _feelingController = TextEditingController();
  bool _isGenerating = false;
  String? _errorMessage;
  bool _isTestingNetwork = false;
  
  // 提醒状态
  bool _isReminderEnabled = false;
  String _reminderTime = '08:00';
  List<bool> _reminderDays = [true, true, true, true, true, false, false];
  
  // 冥想统计状态
  String _todayMeditationTime = '00:00';
  String _totalMeditationTime = '00:00';
  bool _isLoadingStats = true;
  
  // 用户信息 - 使用传入的参数
  String get _userId => widget.userId ?? 'test-user';
  String get _userEmail => widget.userEmail ?? '';
  String get _userDisplayName => widget.userDisplayName ?? '';

  // 加载提醒状态
  Future<void> _loadReminderStatus() async {
    try {
      final settings = await ReminderService.loadReminderSettings();
      setState(() {
        _isReminderEnabled = settings['isEnabled'] ?? false;
        _reminderTime = settings['time'] ?? '08:00';
        _reminderDays = List<bool>.from(settings['days'] ?? [true, true, true, true, true, false, false]);
      });
    } catch (e) {
      print('加载提醒状态失败: $e');
    }
  }

  // 加载冥想统计
  Future<void> _loadMeditationStats() async {
    print('📊 开始加载冥想统计...');
    try {
      final stats = await MeditationStatsService.getTodayStats();
      print('📊 获取到统计数据:');
      print('  - 今日时长: ${stats['todayTime']}秒 (${stats['todayFormatted']})');
      print('  - 总时长: ${stats['totalTime']}秒 (${stats['totalFormatted']})');
      
      if (mounted) {
        setState(() {
          _todayMeditationTime = stats['todayFormatted'];
          _totalMeditationTime = stats['totalFormatted'];
          _isLoadingStats = false;
        });
        print('✅ 冥想统计已更新到UI');
      }
    } catch (e) {
      print('❌ 加载冥想统计失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 不再需要 _loadUserInfo，因为用户信息通过参数传入
    _loadReminderStatus();
    _loadMeditationStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 顶部渐变背景
            SliverToBoxAdapter(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryBlue.withOpacity(0.1),
                      AppColors.lightBlue.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Welcome to MindTuner',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find your inner peace through guided meditation',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 主要内容
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  _buildReminderStatusCard(),
                  const SizedBox(height: 24),
                  _buildMoodSection(),
                  const SizedBox(height: 24),
                  _buildMeditationSection(),
                  const SizedBox(height: 24),
                  _buildFeelingInput(),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) _buildErrorMessage(),
                  const SizedBox(height: 24),
                  _buildStartButton(),
                  const SizedBox(height: 24),
                  _buildDebugSection(),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How are you feeling today?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose your current mood to personalize your meditation',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMoodChip('happy', 'Happy', Icons.sentiment_satisfied, Colors.green),
                _buildMoodChip('sad', 'Sad', Icons.sentiment_dissatisfied, Colors.blue),
                _buildMoodChip('neutral', 'Neutral', Icons.sentiment_neutral, Colors.grey),
                _buildMoodChip('anxious', 'Anxious', Icons.sentiment_very_dissatisfied, Colors.orange),
                _buildMoodChip('stressed', 'Stressed', Icons.sentiment_very_dissatisfied, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodChip(String mood, String label, IconData icon, Color color) {
    final isSelected = _selectedMood == mood;
    
    return GestureDetector(
      onTap: () {
        print('🎯 选择心情: $mood');
        setState(() => _selectedMood = mood);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeditationSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.timer,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Meditation Progress',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your daily meditation journey',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isLoadingStats ? null : _loadMeditationStats,
                  icon: _isLoadingStats 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, color: AppColors.primaryBlue),
                  tooltip: 'Refresh Stats',
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isGenerating) 
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Generating your personalized meditation...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (_isLoadingStats)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Loading your meditation stats...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today',
                      _todayMeditationTime,
                      Icons.today,
                      AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      _totalMeditationTime,
                      Icons.all_inclusive,
                      Colors.green,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            time,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'minutes',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_note,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Your Thoughts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tell us what\'s on your mind for a personalized experience',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _feelingController,
              maxLines: 4,
              enabled: !_isGenerating,
              onChanged: (value) {
                print('📝 内容变化: "${value.trim()}" (${value.trim().isNotEmpty})');
                setState(() {}); // 强制重新构建以更新按钮状态
              },
              decoration: InputDecoration(
                hintText: 'e.g.: I feel stressed about work and need to relax...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildStartButton() {
    final canGenerate = _selectedMood.isNotEmpty && 
                       _feelingController.text.trim().isNotEmpty && 
                       !_isGenerating;

    // 添加调试信息
    print('🔍 生成按钮状态检查:');
    print('  - 选中心情: "$_selectedMood" (${_selectedMood.isNotEmpty})');
    print('  - 内容文本: "${_feelingController.text.trim()}" (${_feelingController.text.trim().isNotEmpty})');
    print('  - 正在生成: $_isGenerating');
    print('  - 可以生成: $canGenerate');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: canGenerate ? [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: canGenerate ? _generateMeditation : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canGenerate ? AppColors.primaryBlue : Colors.grey.shade300,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Creating your meditation...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.self_improvement,
                    size: 24,
                    color: canGenerate ? Colors.white : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    canGenerate ? 'Begin Your Meditation' : 'Select mood and describe your feelings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: canGenerate ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildDebugSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bug_report,
                    color: Colors.orange.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Developer Tools',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Advanced testing and debugging options',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildDebugButton(
                  'Network Test',
                  Icons.wifi,
                  Colors.blue,
                  _isTestingNetwork ? null : _testNetworkConnectivity,
                  isLoading: _isTestingNetwork,
                ),
                _buildDebugButton(
                  'Audio Test',
                  Icons.music_note,
                  Colors.green,
                  _testAudioUrls,
                ),
                _buildDebugButton(
                  'Backend Test',
                  Icons.dns,
                  Colors.purple,
                  _testBackendConnection,
                ),
                _buildDebugButton(
                  'Database Test',
                  Icons.storage,
                  Colors.orange,
                  _testDatabaseConnection,
                ),
                _buildDebugButton(
                  'Network Diagnosis',
                  Icons.medical_services,
                  Colors.red,
                  _diagnoseNetworkIssues,
                ),
                _buildDebugButton(
                  'Reset Stats',
                  Icons.restore,
                  Colors.brown,
                  _resetMeditationStats,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugButton(String label, IconData icon, Color color, VoidCallback? onPressed, {bool isLoading = false}) {
    return SizedBox(
      width: 120,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
        label: Text(
          isLoading ? 'Testing...' : label,
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // 重置冥想统计
  Future<void> _resetMeditationStats() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
                 title: const Text('Reset Statistics'),
         content: const Text('Are you sure you want to reset all meditation statistics? This action cannot be undone.'),
        actions: [
                     TextButton(
             onPressed: () => Navigator.of(context).pop(false),
             child: const Text('Cancel'),
           ),
           ElevatedButton(
             onPressed: () => Navigator.of(context).pop(true),
             style: ElevatedButton.styleFrom(
               surfaceTintColor: Colors.red,
               foregroundColor: Colors.white,
             ),
             child: const Text('Reset'),
           ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await MeditationStatsService.resetAllStats();
      await _loadMeditationStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(
             content: Text('Meditation statistics have been reset'),
             backgroundColor: Colors.orange,
             duration: Duration(seconds: 2),
           ),
        );
      }
    }
  }

  Future<void> _generateMeditation() async {
    print('🚀 开始生成冥想...');
    print('  - 选中心情: "$_selectedMood"');
    print('  - 内容文本: "${_feelingController.text.trim()}"');
    
    if (_selectedMood.isEmpty || _feelingController.text.trim().isEmpty) {
      print('❌ 生成条件不满足');
      if (mounted) {
        setState(() {
          _errorMessage = 'Please select a mood and describe your feeling.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isGenerating = true;
        _errorMessage = null;
      });
    }

    try {
             print('🎯 Starting meditation generation, User ID: $_userId');
       print('📝 Mood: $_selectedMood');
       print('📄 Description: ${_feelingController.text.trim()}');
      
      final result = await MeditationApi.generateMeditation(
        userId: _userId,
        mood: _selectedMood,
        description: _feelingController.text.trim(),
      );

      print('API Response - recordId: ${result.recordId}');
      print('API Response - script length: ${result.script.length}');
      print('API Response - audioUrl: ${result.audioUrl}');

      // 生成成功后，跳转到播放页面
      if (mounted) {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeditationPlayScreen(
              meditationScript: result.script,
              recordId: result.recordId,
              mood: _selectedMood,
              audioUrl: result.audioUrl,
              originalDescription: _feelingController.text.trim(), // 传递原始描述
            ),
          ),
        );
        
        // 如果冥想播放页面返回了刷新信号，则刷新统计数据
        if (mounted && shouldRefresh == true) {
          print('🔄 收到冥想播放页面的刷新信号，开始刷新统计数据...');
          await _loadMeditationStats();
          print('✅ 统计数据自动刷新完成');
          
                     // 显示统计更新提示
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Meditation statistics updated'),
               backgroundColor: Colors.green,
               duration: Duration(seconds: 2),
             ),
           );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate meditation: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  // 后端连接测试方法
  Future<void> _testBackendConnection() async {
    try {
             print('🔍 Starting backend connection test...');
       
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Starting backend connection test...'),
           duration: Duration(seconds: 2),
         ),
       );

      final result = await MeditationApi.testBackendConnection();
      
      if (mounted) {
        if (result['success']) {
                     ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('✅ Backend connection successful!\n${result['response']}'),
               backgroundColor: Colors.green,
               duration: const Duration(seconds: 5),
             ),
           );
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('❌ Backend connection failed!\n${result['error']}'),
               backgroundColor: Colors.red,
               duration: const Duration(seconds: 8),
             ),
           );
         }
      }
      
         } catch (e) {
       print('❌ Backend test exception: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Backend test exception: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
  }

  // 数据库连接测试方法
  Future<void> _testDatabaseConnection() async {
    try {
             print('🔍 Starting database connection test...');
       
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Starting database connection test...'),
           duration: Duration(seconds: 2),
         ),
       );

             // Test database connection via backend API
      final url = Uri.parse('${MeditationApi.baseUrl}/history/test-database');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      
      final result = {
        'success': res.statusCode == 200,
        'response': res.body,
        'statusCode': res.statusCode,
      };
      
      if (mounted) {
        if (result['success'] == true) {
                     ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('✅ Database connection successful!\n${result['response']}'),
               backgroundColor: Colors.green,
               duration: const Duration(seconds: 5),
             ),
           );
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('❌ Database connection failed!\n${result['response']}'),
               backgroundColor: Colors.red,
               duration: const Duration(seconds: 8),
             ),
           );
         }
      }
      
         } catch (e) {
       print('❌ Database test exception: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Database test exception: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
  }

  // 网络诊断方法
  Future<void> _diagnoseNetworkIssues() async {
    try {
             print('🔍 Starting network diagnosis...');
       
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Starting network diagnosis...'),
           duration: Duration(seconds: 2),
         ),
       );

      final diagnosis = await AudioService.diagnoseNetworkIssues();
      
      if (mounted) {
        _showNetworkDiagnosisResults(diagnosis);
      }
      
         } catch (e) {
       print('❌ Network diagnosis exception: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Network diagnosis exception: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
  }

  // 显示网络诊断结果
  void _showNetworkDiagnosisResults(Map<String, dynamic> diagnosis) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Diagnosis Results'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 总结信息
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             Text(
                         'Test time: ${diagnosis['timestamp']}',
                         style: const TextStyle(fontSize: 12),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         'Success rate: ${diagnosis['summary']['success_rate']}',
                         style: const TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                                 // Detailed test results
                ...diagnosis['tests'].entries.map((entry) {
                  final testName = entry.key;
                  final testResult = entry.value;
                  final isSuccess = testResult['success'] == true;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
                      border: Border.all(
                        color: isSuccess ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSuccess ? Icons.check_circle : Icons.error,
                              color: isSuccess ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                testResult['message'] ?? testName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                                                 if (testResult['statusCode'] != null) ...[
                           const SizedBox(height: 4),
                           Text(
                             'Status code: ${testResult['statusCode']}',
                             style: const TextStyle(fontSize: 12),
                           ),
                         ],
                         if (testResult['error'] != null) ...[
                           const SizedBox(height: 4),
                           Text(
                             'Error: ${testResult['error']}',
                             style: TextStyle(
                               fontSize: 12,
                               color: Colors.red.shade700,
                             ),
                           ),
                         ],
                         if (testResult['response'] != null) ...[
                           const SizedBox(height: 4),
                           Text(
                             'Response: ${testResult['response']}',
                             style: const TextStyle(fontSize: 12),
                           ),
                         ],
                      ],
                    ),
                  );
                }).toList(),
                
                                 // Suggestions
                if (diagnosis['tests']['google_connectivity']?['success'] == false) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                                 Text(
                           '💡 Suggestions',
                           style: TextStyle(
                             fontWeight: FontWeight.bold,
                             color: Colors.orange,
                           ),
                         ),
                         SizedBox(height: 8),
                         Text('• Check if emulator proxy settings are correct'),
                         Text('• Verify proxy server is working properly'),
                         Text('• Try restarting the emulator'),
                         Text('• Check firewall settings'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Audio URL test method
  Future<void> _testAudioUrls() async {
    try {
             print('🎵 Starting audio URL test...');
       
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Starting audio URL test...'),
           duration: Duration(seconds: 2),
         ),
       );

      await AudioService.testMultipleUrls();
      
      if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('✅ Audio URL test completed!'),
             backgroundColor: Colors.green,
           ),
         );
      }
      
         } catch (e) {
       print('❌ Audio URL test exception: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Audio URL test exception: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
  }

  // Network connectivity test method
  Future<void> _testNetworkConnectivity() async {
    if (_isTestingNetwork) return;

    setState(() {
      _isTestingNetwork = true;
    });

    try {
             print('🌐 Starting network connectivity test...');
       
       // Show test start message
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Starting network connectivity test...'),
           duration: Duration(seconds: 2),
         ),
       );

      final results = await AudioService.testNetworkConnectivity();
      
             // Count results
       final successCount = results.values.where((r) => r['success'] == true).length;
       final totalCount = results.length;
       
       String message;
       Color backgroundColor;
       
       if (successCount == 0) {
         message = '❌ All websites are inaccessible - Network may be completely down or blocked';
         backgroundColor = Colors.red;
       } else if (successCount < totalCount) {
         message = '⚠️ Some websites are inaccessible - Partial blocking detected ($successCount/$totalCount)';
         backgroundColor = Colors.orange;
       } else {
         message = '✅ All websites are accessible - Network is normal ($successCount/$totalCount)';
         backgroundColor = Colors.green;
       }
      
             // Show test results
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(message),
             backgroundColor: backgroundColor,
             duration: const Duration(seconds: 8),
             action: SnackBarAction(
               label: 'Details',
               textColor: Colors.white,
               onPressed: () => _showNetworkTestDetails(results),
             ),
           ),
         );
       }
      
             // Print detailed results to console
       print('\n📊 Detailed network test results:');
       results.forEach((url, result) {
         final status = result['success'] ? '✅' : '❌';
         final statusCode = result['statusCode'] ?? 'N/A';
         final error = result['error'] ?? '';
         print('$status $url - Status code: $statusCode ${error.isNotEmpty ? '- Error: $error' : ''}');
       });
      
         } catch (e) {
       print('❌ Network test exception: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Network test exception: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     } finally {
      if (mounted) {
        setState(() {
          _isTestingNetwork = false;
        });
      }
    }
  }

     // Show network test details
   void _showNetworkTestDetails(Map<String, dynamic> results) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Network Test Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final url = results.keys.elementAt(index);
              final result = results[url];
              final isSuccess = result['success'] == true;
              
              return ListTile(
                leading: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                title: Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                         Text('Status code: ${result['statusCode'] ?? 'N/A'}'),
                     if (result['error'] != null)
                       Text(
                         'Error: ${result['error']}',
                         style: const TextStyle(color: Colors.red),
                       ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // 构建提醒状态卡片
  Widget _buildReminderStatusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isReminderEnabled ? AppColors.primaryBlue.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isReminderEnabled ? Icons.notifications_active : Icons.notifications_off,
                    color: _isReminderEnabled ? AppColors.primaryBlue : Colors.grey.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                             const Text(
                         'Meditation Reminder',
                         style: TextStyle(
                           fontSize: 20,
                           fontWeight: FontWeight.bold,
                           color: AppColors.darkText,
                         ),
                       ),
                      const SizedBox(height: 2),
                                             Text(
                         _isReminderEnabled ? 'Daily reminder is set' : 'Set daily meditation reminder',
                         style: TextStyle(
                           fontSize: 14,
                           color: Colors.grey.shade600,
                         ),
                       ),
                    ],
                  ),
                ),
                if (_isReminderEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                                                 const Text(
                           'Enabled',
                           style: TextStyle(
                             color: Colors.green,
                             fontSize: 12,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isReminderEnabled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.access_time, size: 16, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                                             Text(
                                 'Reminder Time',
                                 style: TextStyle(
                                   color: Colors.grey.shade600,
                                   fontSize: 12,
                                 ),
                               ),
                              Text(
                                ReminderService.formatTimeForDisplay(_reminderTime),
                                style: const TextStyle(
                                  color: AppColors.darkText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.calendar_today, size: 16, color: AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                                             Text(
                                 'Reminder Days',
                                 style: TextStyle(
                                   color: Colors.grey.shade600,
                                   fontSize: 12,
                                 ),
                               ),
                              Text(
                                ReminderService.getSelectedDaysDescription(_reminderDays),
                                style: const TextStyle(
                                  color: AppColors.darkText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                                             child: Text(
                         'Set daily meditation reminders to build healthy meditation habits',
                         style: TextStyle(
                           color: Colors.grey.shade600,
                           fontSize: 14,
                         ),
                       ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // 直接导航到提醒设置页面
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MeditationReminderScreen(),
                        ),
                      );
                      
                      // 如果从提醒设置页面返回，重新加载提醒状态
                      if (result == true) {
                        await _loadReminderStatus();
                      }
                    },
                    icon: Icon(_isReminderEnabled ? Icons.edit : Icons.add),
                                         label: Text(_isReminderEnabled ? 'Edit Settings' : 'Set Reminder'),
                                         style: ElevatedButton.styleFrom(
                       surfaceTintColor: _isReminderEnabled ? AppColors.primaryBlue : Colors.green,
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                     ),
                  ),
                ),
                if (_isReminderEnabled) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // 显示确认对话框
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                                                         title: const Text('Cancel Reminder'),
                             content: const Text('Are you sure you want to cancel the daily meditation reminder?'),
                            actions: [
                                                             TextButton(
                                 onPressed: () => Navigator.of(context).pop(false),
                                 child: const Text('Keep'),
                               ),
                               ElevatedButton(
                                 onPressed: () => Navigator.of(context).pop(true),
                                 style: ElevatedButton.styleFrom(
                                   surfaceTintColor: Colors.red,
                                   foregroundColor: Colors.white,
                                 ),
                                 child: const Text('Cancel Reminder'),
                               ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          // 关闭提醒
                          await ReminderService.saveReminderSettings(
                            isEnabled: false,
                            time: _reminderTime,
                            days: _reminderDays,
                          );
                          await _loadReminderStatus();
                          ScaffoldMessenger.of(context).showSnackBar(
                                                       const SnackBar(
                             content: Text('Meditation reminder has been cancelled'),
                             backgroundColor: Colors.orange,
                             duration: Duration(seconds: 2),
                           ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_off, size: 18),
                                             label: const Text('Cancel Reminder'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}