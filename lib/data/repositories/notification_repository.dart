import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  final FirebaseService _firebaseService;
  final NotificationService _notificationService;

  NotificationRepository(this._firebaseService, this._notificationService);

  // Notification preferences model
  static const String _prefsKey = 'notification_preferences';
  static const String _mealRemindersKey = 'meal_reminders_enabled';
  static const String _calorieGoalsKey = 'calorie_goals_enabled';
  static const String _weeklyReportsKey = 'weekly_reports_enabled';
  static const String _waterRemindersKey = 'water_reminders_enabled';

  // Get notification preferences from local storage
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'mealRemindersEnabled': prefs.getBool(_mealRemindersKey) ?? true,
      'calorieGoalsEnabled': prefs.getBool(_calorieGoalsKey) ?? true,
      'weeklyReportsEnabled': prefs.getBool(_weeklyReportsKey) ?? true,
      'waterRemindersEnabled': prefs.getBool(_waterRemindersKey) ?? false,
      'breakfastTime': prefs.getString('breakfast_time') ?? '08:00',
      'lunchTime': prefs.getString('lunch_time') ?? '12:00',
      'dinnerTime': prefs.getString('dinner_time') ?? '19:00',
      'calorieGoalTime': prefs.getString('calorie_goal_time') ?? '20:00',
      'weeklyReportDay': prefs.getString('weekly_report_day') ?? 'sunday',
      'weeklyReportTime': prefs.getString('weekly_report_time') ?? '09:00',
    };
  }

  // Save notification preferences to local storage
  Future<void> saveNotificationPreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_mealRemindersKey, preferences['mealRemindersEnabled'] ?? true);
    await prefs.setBool(_calorieGoalsKey, preferences['calorieGoalsEnabled'] ?? true);
    await prefs.setBool(_weeklyReportsKey, preferences['weeklyReportsEnabled'] ?? true);
    await prefs.setBool(_waterRemindersKey, preferences['waterRemindersEnabled'] ?? false);
    await prefs.setString('breakfast_time', preferences['breakfastTime'] ?? '08:00');
    await prefs.setString('lunch_time', preferences['lunchTime'] ?? '12:00');
    await prefs.setString('dinner_time', preferences['dinnerTime'] ?? '19:00');
    await prefs.setString('calorie_goal_time', preferences['calorieGoalTime'] ?? '20:00');
    await prefs.setString('weekly_report_day', preferences['weeklyReportDay'] ?? 'sunday');
    await prefs.setString('weekly_report_time', preferences['weeklyReportTime'] ?? '09:00');
  }

  // Save FCM token to Firestore
  Future<void> saveFCMToken(String userId, String token) async {
    try {
      await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc('fcm_token')
          .set({
        'token': token,
        'platform': _getPlatform(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Get FCM token from Firestore
  Future<String?> getFCMToken(String userId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc('fcm_token')
          .get();
      
      if (doc.exists) {
        return doc.data()?['token'];
      }
      return null;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Save notification history to Firestore
  Future<void> saveNotificationHistory({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error saving notification history: $e');
    }
  }

  // Get notification history from Firestore
  Future<List<Map<String, dynamic>>> getNotificationHistory(String userId) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error getting notification history: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Schedule meal reminders based on preferences
  Future<void> scheduleMealReminders(Map<String, dynamic> preferences) async {
    if (preferences['mealRemindersEnabled'] == true) {
      // Schedule breakfast reminder
      if (preferences['breakfastTime'] != null) {
        final time = _parseTimeString(preferences['breakfastTime']);
        await _notificationService.scheduleMealReminder(
          mealType: 'breakfast',
          scheduledTime: time,
          id: 1001,
        );
      }

      // Schedule lunch reminder
      if (preferences['lunchTime'] != null) {
        final time = _parseTimeString(preferences['lunchTime']);
        await _notificationService.scheduleMealReminder(
          mealType: 'lunch',
          scheduledTime: time,
          id: 1002,
        );
      }

      // Schedule dinner reminder
      if (preferences['dinnerTime'] != null) {
        final time = _parseTimeString(preferences['dinnerTime']);
        await _notificationService.scheduleMealReminder(
          mealType: 'dinner',
          scheduledTime: time,
          id: 1003,
        );
      }
    }
  }

  // Schedule calorie goal reminder
  Future<void> scheduleCalorieGoalReminder({
    required int targetCalories,
    required int currentCalories,
    required Map<String, dynamic> preferences,
  }) async {
    if (preferences['calorieGoalsEnabled'] == true) {
      final time = _parseTimeString(preferences['calorieGoalTime'] ?? '20:00');
      await _notificationService.scheduleCalorieGoalReminder(
        targetCalories: targetCalories,
        currentCalories: currentCalories,
        scheduledTime: time,
      );
    }
  }

  // Schedule weekly report
  Future<void> scheduleWeeklyReport(Map<String, dynamic> preferences) async {
    if (preferences['weeklyReportsEnabled'] == true) {
      final reportDate = _getNextWeeklyReportDate(
        preferences['weeklyReportDay'] ?? 'sunday',
        preferences['weeklyReportTime'] ?? '09:00',
      );
      
      await _notificationService.scheduleWeeklyReport(
        reportDate: reportDate,
      );
    }
  }

  // Show calorie milestone notification
  Future<void> showCalorieMilestoneNotification({
    required String userId,
    required String milestone,
    required int calories,
  }) async {
    final title = 'Calorie Milestone Reached! 🎉';
    final body = 'Congratulations! You\'ve reached $milestone with $calories calories today.';
    
    await _notificationService.showCalorieMilestoneNotification(
      title: title,
      body: body,
      data: {
        'type': 'calorie_milestone',
        'milestone': milestone,
        'calories': calories,
      },
    );

    // Save to history
    await saveNotificationHistory(
      userId: userId,
      type: 'calorie_milestone',
      title: title,
      body: body,
      data: {
        'milestone': milestone,
        'calories': calories,
      },
    );
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    await _notificationService.cancelAllNotifications();
  }

  // Helper method to parse time string (HH:mm format)
  DateTime _parseTimeString(String timeString) {
    final now = DateTime.now();
    final parts = timeString.split(':');
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  // Helper method to get platform
  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  // Helper method to get next weekly report date
  DateTime _getNextWeeklyReportDate(String day, String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final targetHour = int.parse(timeParts[0]);
    final targetMinute = int.parse(timeParts[1]);
    
    // Map day names to weekday numbers (1 = Monday, 7 = Sunday)
    final dayMap = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    
    final targetWeekday = dayMap[day.toLowerCase()] ?? 7;
    final currentWeekday = now.weekday;
    
    int daysToAdd = targetWeekday - currentWeekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7; // Next week
    }
    
    return DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      targetHour,
      targetMinute,
    );
  }
} 