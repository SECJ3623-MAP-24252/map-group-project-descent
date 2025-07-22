# Push Notification Feature for Calorie Tracking

This document describes the comprehensive push notification system implemented for the BiteWise calorie tracking app.

## Overview

The notification system provides users with timely reminders and updates about their calorie tracking progress, helping them stay motivated and consistent with their nutrition goals.

## Features

### 1. Meal Reminders
- **Breakfast Reminders**: Daily notifications at user-specified time (default: 8:00 AM)
- **Lunch Reminders**: Daily notifications at user-specified time (default: 12:00 PM)
- **Dinner Reminders**: Daily notifications at user-specified time (default: 7:00 PM)

### 2. Calorie Goal Tracking
- **Daily Progress Updates**: Notifications showing remaining calories for the day
- **Goal Achievement**: Celebratory notifications when users reach their daily calorie goal
- **Milestone Notifications**: Special notifications at 1000, 1500, and 2000 calorie milestones

### 3. Weekly Nutrition Reports
- **Weekly Summaries**: Scheduled reports showing nutrition progress for the week
- **Customizable Timing**: Users can choose the day and time for weekly reports

### 4. Water Intake Reminders
- **Hydration Reminders**: Optional notifications to remind users to drink water

## Technical Implementation

### Architecture
The notification system follows the MVVM pattern and integrates seamlessly with the existing app architecture:

```
lib/
├── data/
│   ├── services/
│   │   └── notification_service.dart          # Core notification functionality
│   └── repositories/
│       └── notification_repository.dart       # Data management for notifications
├── presentation/
│   ├── viewmodels/
│   │   └── notification_viewmodel.dart        # Business logic for notifications
│   └── views/
│       └── profile/
│           └── notification_settings_page.dart # UI for notification settings
```

### Key Components

#### 1. NotificationService
- Handles Firebase Cloud Messaging (FCM) setup
- Manages local notifications using `flutter_local_notifications`
- Schedules recurring notifications
- Processes notification taps and navigation

#### 2. NotificationRepository
- Manages notification preferences in SharedPreferences
- Stores FCM tokens in Firestore
- Handles notification history
- Provides methods for scheduling different notification types

#### 3. NotificationViewModel
- Manages notification state and preferences
- Integrates with meal tracking to trigger milestone notifications
- Provides methods for updating notification settings
- Handles notification history and read status

## Usage Examples

### 1. Basic Setup

```dart
// Initialize notifications in your app
final notificationService = NotificationService();
await notificationService.initialize();

// Get notification viewmodel
final notificationViewModel = getIt<NotificationViewModel>();
await notificationViewModel.initializeNotifications();
```

### 2. Schedule Meal Reminders

```dart
// Schedule breakfast reminder at 8:00 AM
await notificationService.scheduleMealReminder(
  mealType: 'breakfast',
  time: Time(8, 0),
  id: 1001,
);
```

### 3. Check Calorie Milestones

```dart
// This is automatically called when meals are added/updated
await notificationViewModel.checkCalorieMilestones();
```

### 4. Update Notification Preferences

```dart
// Toggle meal reminders
await notificationViewModel.toggleMealReminders(true);

// Update meal times
await notificationViewModel.updateMealTime('breakfast', '08:30');
```

### 5. Show Immediate Notifications

```dart
// Show calorie milestone notification
await notificationService.showCalorieMilestoneNotification(
  title: 'Calorie Milestone Reached! 🎉',
  body: 'Congratulations! You\'ve reached 1000 calories today.',
  data: {
    'type': 'calorie_milestone',
    'milestone': '1000 calories',
    'calories': 1000,
  },
);
```

## Integration with Existing Features

### Meal Tracking Integration
The notification system automatically integrates with the meal tracking feature:

1. **When meals are added**: The system checks for calorie milestones
2. **When meals are updated**: Calorie totals are recalculated and milestones checked
3. **When meals are deleted**: The system updates calorie totals and checks milestones

### Example Integration in NutritionViewModel

```dart
class NutritionViewModel extends BaseViewModel {
  final NotificationViewModel? _notificationViewModel;

  Future<void> addMeal(MealModel meal) async {
    // ... existing meal addition logic ...
    
    // Check for calorie milestones after adding a meal
    if (_notificationViewModel != null) {
      await _notificationViewModel!.checkCalorieMilestones();
    }
  }
}
```

## Configuration

### Notification Preferences
Users can configure the following settings:

- **Meal Reminders**: Enable/disable and set times for breakfast, lunch, dinner
- **Calorie Goals**: Enable/disable daily calorie goal reminders
- **Weekly Reports**: Enable/disable and set day/time for weekly summaries
- **Water Reminders**: Enable/disable hydration reminders

### Default Settings
```dart
{
  'mealRemindersEnabled': true,
  'calorieGoalsEnabled': true,
  'weeklyReportsEnabled': true,
  'waterRemindersEnabled': false,
  'breakfastTime': '08:00',
  'lunchTime': '12:00',
  'dinnerTime': '19:00',
  'calorieGoalTime': '20:00',
  'weeklyReportDay': 'sunday',
  'weeklyReportTime': '09:00',
}
```

## Firebase Setup

### Required Dependencies
```yaml
dependencies:
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
  permission_handler: ^11.0.1
  timezone: ^0.9.2
```

### Android Configuration
1. Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

2. Add to `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        // ... other config
        multiDexEnabled true
    }
}
```

### iOS Configuration
1. Add to `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Testing

### Local Testing
```dart
// Test immediate notification
await notificationService.showCalorieMilestoneNotification(
  title: 'Test Notification',
  body: 'This is a test notification',
  data: {'type': 'test'},
);

// Test scheduled notification
await notificationService.scheduleMealReminder(
  mealType: 'test',
  time: Time(DateTime.now().hour, DateTime.now().minute + 1),
  id: 9999,
);
```

### Firebase Testing
1. Use Firebase Console to send test messages
2. Test different notification types:
   - `meal_reminder`
   - `calorie_goal`
   - `weekly_report`
   - `calorie_milestone`

## Best Practices

### 1. Permission Handling
- Always request notification permissions on app startup
- Provide clear explanations for why permissions are needed
- Handle permission denial gracefully

### 2. Battery Optimization
- Use `AndroidScheduleMode.exactAllowWhileIdle` for important notifications
- Avoid excessive notification frequency
- Allow users to customize notification timing

### 3. User Experience
- Provide clear, actionable notification content
- Use appropriate notification sounds and vibrations
- Include navigation to relevant app sections when notifications are tapped

### 4. Data Management
- Store notification preferences locally for offline access
- Sync FCM tokens with backend for server-side notifications
- Maintain notification history for user reference

## Troubleshooting

### Common Issues

1. **Notifications not showing on Android**
   - Check battery optimization settings
   - Verify notification permissions
   - Ensure notification channel is created

2. **Scheduled notifications not firing**
   - Check device restart handling
   - Verify timezone settings
   - Ensure notification IDs are unique

3. **FCM token issues**
   - Handle token refresh properly
   - Store tokens securely
   - Implement retry logic for token updates

### Debug Logging
Enable debug logging to troubleshoot issues:
```dart
// In notification service
print('FCM Token: $token');
print('Notification scheduled: $id at $time');
print('Notification tapped: ${response.payload}');
```

## Future Enhancements

### Potential Features
1. **Smart Notifications**: AI-powered timing based on user behavior
2. **Social Features**: Share achievements with friends
3. **Custom Goals**: User-defined calorie and nutrition goals
4. **Integration**: Connect with fitness trackers and smart scales
5. **Analytics**: Detailed notification engagement metrics

### Performance Optimizations
1. **Batch Processing**: Group multiple notifications
2. **Caching**: Cache notification preferences and history
3. **Background Processing**: Optimize background notification handling
4. **Network Efficiency**: Minimize FCM token updates

## Conclusion

The notification system provides a comprehensive solution for keeping users engaged with their calorie tracking goals. By combining scheduled reminders, milestone celebrations, and progress updates, it helps users maintain consistency and motivation in their nutrition journey.

The modular architecture makes it easy to extend and customize the notification system for future requirements while maintaining compatibility with the existing app structure. 