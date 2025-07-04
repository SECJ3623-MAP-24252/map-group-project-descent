import 'package:flutter/material.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../viewmodels/base_viewmodel.dart';

class NotificationViewModel extends BaseViewModel {
  final NotificationRepository _notificationRepository;
  final MealRepository _mealRepository;
  final UserRepository _userRepository;

  NotificationViewModel(
    this._notificationRepository,
    this._mealRepository,
    this._userRepository,
  );

  // Notification preferences
  Map<String, dynamic> _notificationPreferences = {};
  Map<String, dynamic> get notificationPreferences => _notificationPreferences;

  // Notification history
  List<Map<String, dynamic>> _notificationHistory = [];
  List<Map<String, dynamic>> get notificationHistory => _notificationHistory;

  // Unread notification count
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Initialize notification settings
  Future<void> initializeNotifications() async {
    setState(ViewState.busy);
    try {
      // Load notification preferences
      _notificationPreferences = await _notificationRepository.getNotificationPreferences();
      
      // Get current user
      final currentUser = _userRepository.currentUser;
      if (currentUser != null) {
        // Load notification history
        _notificationHistory = await _notificationRepository.getNotificationHistory(currentUser.uid);
        
        // Get unread count
        _unreadCount = await _notificationRepository.getUnreadNotificationCount(currentUser.uid);
        
        // Schedule notifications based on preferences
        await _scheduleNotifications();
      }
    } catch (e) {
      setError('Failed to initialize notifications: $e');
    } finally {
      setState(ViewState.idle);
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences(Map<String, dynamic> preferences) async {
    setState(ViewState.busy);
    try {
      await _notificationRepository.saveNotificationPreferences(preferences);
      _notificationPreferences = preferences;
      
      // Reschedule notifications with new preferences
      await _scheduleNotifications();
      
      notifyListeners();
    } catch (e) {
      setError('Failed to update notification preferences: $e');
    } finally {
      setState(ViewState.idle);
    }
  }

  // Schedule all notifications based on preferences
  Future<void> _scheduleNotifications() async {
    try {
      // Cancel existing notifications
      await _notificationRepository.cancelAllScheduledNotifications();
      
      // Schedule meal reminders
      await _notificationRepository.scheduleMealReminders(_notificationPreferences);
      
      // Schedule weekly report
      await _notificationRepository.scheduleWeeklyReport(_notificationPreferences);
      
      // Schedule calorie goal reminder (will be updated when meals are logged)
      await _updateCalorieGoalReminder();
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  // Update calorie goal reminder based on current calorie intake
  Future<void> _updateCalorieGoalReminder() async {
    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser == null) return;

      // Get today's meals
      final today = DateTime.now();
      final meals = await _mealRepository.getMealsForDate(currentUser.uid, today);
      
      // Calculate total calories for today
      double totalCalories = 0;
      for (final meal in meals) {
        totalCalories += meal.calories;
      }

      // Get user's calorie goal (you might want to store this in user preferences)
      const int targetCalories = 2000; // Default value, should come from user settings
      
      // Schedule calorie goal reminder
      await _notificationRepository.scheduleCalorieGoalReminder(
        targetCalories: targetCalories,
        currentCalories: totalCalories.toInt(),
        preferences: _notificationPreferences,
      );
    } catch (e) {
      print('Error updating calorie goal reminder: $e');
    }
  }

  // Check for calorie milestones and show notifications
  Future<void> checkCalorieMilestones() async {
    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser == null) return;

      // Get today's meals
      final today = DateTime.now();
      final meals = await _mealRepository.getMealsForDate(currentUser.uid, today);
      
      // Calculate total calories for today
      double totalCalories = 0;
      for (final meal in meals) {
        totalCalories += meal.calories;
      }

      final int calories = totalCalories.toInt();

      // Check for milestones
      if (calories >= 1000 && calories < 1100) {
        await _notificationRepository.showCalorieMilestoneNotification(
          userId: currentUser.uid,
          milestone: '1000 calories',
          calories: calories,
        );
      } else if (calories >= 1500 && calories < 1600) {
        await _notificationRepository.showCalorieMilestoneNotification(
          userId: currentUser.uid,
          milestone: '1500 calories',
          calories: calories,
        );
      } else if (calories >= 2000 && calories < 2100) {
        await _notificationRepository.showCalorieMilestoneNotification(
          userId: currentUser.uid,
          milestone: '2000 calories',
          calories: calories,
        );
      }

      // Update calorie goal reminder
      await _updateCalorieGoalReminder();
    } catch (e) {
      print('Error checking calorie milestones: $e');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser == null) return;

      await _notificationRepository.markNotificationAsRead(currentUser.uid, notificationId);
      
      // Update local state
      final index = _notificationHistory.indexWhere((notification) => notification['id'] == notificationId);
      if (index != -1) {
        _notificationHistory[index]['read'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
        notifyListeners();
      }
    } catch (e) {
      setError('Failed to mark notification as read: $e');
    }
  }

  // Refresh notification history
  Future<void> refreshNotificationHistory() async {
    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser == null) return;

      _notificationHistory = await _notificationRepository.getNotificationHistory(currentUser.uid);
      _unreadCount = await _notificationRepository.getUnreadNotificationCount(currentUser.uid);
      notifyListeners();
    } catch (e) {
      setError('Failed to refresh notification history: $e');
    }
  }

  // Save FCM token
  Future<void> saveFCMToken(String token) async {
    try {
      final currentUser = _userRepository.currentUser;
      if (currentUser == null) return;

      await _notificationRepository.saveFCMToken(currentUser.uid, token);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Get notification preferences for specific type
  bool getMealRemindersEnabled() {
    return _notificationPreferences['mealRemindersEnabled'] ?? true;
  }

  bool getCalorieGoalsEnabled() {
    return _notificationPreferences['calorieGoalsEnabled'] ?? true;
  }

  bool getWeeklyReportsEnabled() {
    return _notificationPreferences['weeklyReportsEnabled'] ?? true;
  }

  bool getWaterRemindersEnabled() {
    return _notificationPreferences['waterRemindersEnabled'] ?? false;
  }

  String getBreakfastTime() {
    return _notificationPreferences['breakfastTime'] ?? '08:00';
  }

  String getLunchTime() {
    return _notificationPreferences['lunchTime'] ?? '12:00';
  }

  String getDinnerTime() {
    return _notificationPreferences['dinnerTime'] ?? '19:00';
  }

  String getCalorieGoalTime() {
    return _notificationPreferences['calorieGoalTime'] ?? '20:00';
  }

  String getWeeklyReportDay() {
    return _notificationPreferences['weeklyReportDay'] ?? 'sunday';
  }

  String getWeeklyReportTime() {
    return _notificationPreferences['weeklyReportTime'] ?? '09:00';
  }

  // Toggle specific notification types
  Future<void> toggleMealReminders(bool enabled) async {
    final newPreferences = Map<String, dynamic>.from(_notificationPreferences);
    newPreferences['mealRemindersEnabled'] = enabled;
    await updateNotificationPreferences(newPreferences);
  }

  Future<void> toggleCalorieGoals(bool enabled) async {
    final newPreferences = Map<String, dynamic>.from(_notificationPreferences);
    newPreferences['calorieGoalsEnabled'] = enabled;
    await updateNotificationPreferences(newPreferences);
  }

  Future<void> toggleWeeklyReports(bool enabled) async {
    final newPreferences = Map<String, dynamic>.from(_notificationPreferences);
    newPreferences['weeklyReportsEnabled'] = enabled;
    await updateNotificationPreferences(newPreferences);
  }

  Future<void> toggleWaterReminders(bool enabled) async {
    final newPreferences = Map<String, dynamic>.from(_notificationPreferences);
    newPreferences['waterRemindersEnabled'] = enabled;
    await updateNotificationPreferences(newPreferences);
  }

  // Update meal times
  Future<void> updateMealTime(String mealType, String time) async {
    final newPreferences = Map<String, dynamic>.from(_notificationPreferences);
    newPreferences['${mealType}Time'] = time;
    await updateNotificationPreferences(newPreferences);
  }

  // Update weekly report settings
  Future<void> updateWeeklyReportSettings(String day, String time) async {
    final newPreferences = Map<String, dynamic>.from(_notificationPreferences);
    newPreferences['weeklyReportDay'] = day;
    newPreferences['weeklyReportTime'] = time;
    await updateNotificationPreferences(newPreferences);
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationRepository.cancelAllScheduledNotifications();
      _notificationHistory.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      setError('Failed to clear notifications: $e');
    }
  }
} 