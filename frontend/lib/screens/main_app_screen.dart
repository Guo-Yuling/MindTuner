import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/audio_service.dart';
import '../services/reminder_service.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'auth/login_screen.dart';
import 'meditation_reminder_screen.dart';
import 'rating_history_detail_screen.dart';
import 'rating_history_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  
  // 用户状态管理
  bool _isLoggedIn = false;
  String _userId = 'test-user';
  String _userEmail = '';
  String _userDisplayName = '';
  
  // 提醒状态管理
  bool _isReminderEnabled = false;
  String _reminderTime = '08:00';
  List<bool> _reminderDays = [true, true, true, true, true, false, false];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadReminderStatus();
  }

  // 检查登录状态
    void _checkLoginStatus() {
      // 这里可以检查本地存储或Firebase Auth状态
      // 暂时使用简单的逻辑
      setState(() {
        _isLoggedIn = _userId != 'test-user';
      });
    }

  // 更新用户信息
  void _updateUserInfo(String userId, String userEmail, String userDisplayName) {
    setState(() {
      _userId = userId;
      _userEmail = userEmail;
      _userDisplayName = userDisplayName;
      _isLoggedIn = true;
    });
  }

  // 清除用户信息
  void _clearUserInfo() {
    setState(() {
      _userId = 'test-user';
      _userEmail = '';
      _userDisplayName = '';
      _isLoggedIn = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MindTuner', style: AppStyles.titleStyle),
        actions: [
          // 冥想提醒设置按钮
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  _isReminderEnabled ? Icons.notifications_active : Icons.notifications,
                  color: _isReminderEnabled ? Colors.green : Colors.grey,
                ),
                tooltip: _isReminderEnabled 
                            ? 'Meditation reminder enabled (${ReminderService.getSelectedDaysDescription(_reminderDays)})'
        : 'Meditation Reminder Settings',
                onPressed: _openMeditationReminder,
              ),
              if (_isReminderEnabled)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // 评分历史详情按钮
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Rating History Details',
            onPressed: _openRatingHistoryDetail,
          ),

          // // 评分历史按钮
          // IconButton(
          //   icon: const Icon(Icons.history),
          //   tooltip: 'Rating History',
          //   onPressed: _viewRatingHistory,
          // ),


          // 用户信息显示
          if (_isLoggedIn && _userDisplayName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  'Welcome, $_userDisplayName',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          // 登录/登出按钮
          IconButton(
            icon: Icon(_isLoggedIn ? Icons.logout : Icons.login),
            tooltip: _isLoggedIn ? 'Sign out' : 'Sign in',
            onPressed: _isLoggedIn ? _logout : _showLoginDialog,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Meditation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // 根据当前索引和登录状态构建body
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return HomeScreen(
          userId: _userId,
          userEmail: _userEmail,
          userDisplayName: _userDisplayName,
        );
      case 1:
        return HistoryScreen(
          userId: _userId,
          userEmail: _userEmail,
          userDisplayName: _userDisplayName,
        );
      case 2:
        return ProfileScreen(
          isLoggedIn: _isLoggedIn,
          userId: _userId,
          userEmail: _userEmail,
          userDisplayName: _userDisplayName,
          onLogin: _showLoginDialog,
          onLogout: _logout,
        );
      default:
        return const Center(child: Text('页面不存在'));
    }
  }

  // 显示登录对话框
  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Sign In'),
        content: const Text('Please sign in to use the full features'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  // 导航到登录页面
  void _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
    
    if (result != null && result['success']) {
      // 登录成功，更新用户信息
      _updateUserInfo(
        result['uid'],
        result['email'],
        result['display_name'],
      );
      
             // 显示欢迎消息
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Welcome back, ${result['display_name']}!'),
           backgroundColor: Colors.green,
         ),
       );
      
      // 跳转到个人信息页面
      setState(() {
        _currentIndex = 2; // 切换到个人信息页面
      });
    }
  }

  // 用户登出
  void _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      _clearUserInfo();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully logged out'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // 打开冥想提醒设置
  void _openMeditationReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MeditationReminderScreen(),
      ),
    );
    
    // 如果从提醒设置页面返回，重新加载提醒状态
    if (result == true) {
      _loadReminderStatus();
    }
  }



  // 打开评分历史详情
  void _openRatingHistoryDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RatingHistoryDetailScreen(),
      ),
    );
  }

  // // 打开增强冥想页面
  // void _openEnhancedMeditation() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => EnhancedMeditationScreen(userId: _userId),
  //     ),
  //   );
  // }

  // 查看评分历史
  void _viewRatingHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RatingHistoryScreen(userId: _userId),
      ),
    );
  }

  // // 测试评分功能
  // void _testRating() {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => TestRatingScreen(userId: _userId),
  //     ),
  //   );
  // }
}
