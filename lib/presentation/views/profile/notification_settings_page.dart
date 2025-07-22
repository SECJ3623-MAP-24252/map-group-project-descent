import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/common/loading_widget.dart';
import '../../../core/constants/app_constants.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late NotificationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<NotificationViewModel>(context, listen: false);
    _viewModel.initializeNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(AppConstants.primaryGreen),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isBusy) {
            return const LoadingWidget();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Meal Reminders'),
                _buildMealRemindersSection(viewModel),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Calorie Tracking'),
                _buildCalorieTrackingSection(viewModel),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Weekly Reports'),
                _buildWeeklyReportsSection(viewModel),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Water Reminders'),
                _buildWaterRemindersSection(viewModel),
                
                const SizedBox(height: 32),
                _buildClearAllButton(viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          color: Color(AppConstants.primaryGreen),
        ),
      ),
    );
  }

  Widget _buildMealRemindersSection(NotificationViewModel viewModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSwitchTile(
              title: 'Enable Meal Reminders',
              subtitle: 'Get reminded to log your meals',
              value: viewModel.getMealRemindersEnabled(),
              onChanged: (value) => viewModel.toggleMealReminders(value),
            ),
            if (viewModel.getMealRemindersEnabled()) ...[
              const Divider(),
              _buildTimePickerTile(
                title: 'Breakfast Time',
                time: viewModel.getBreakfastTime(),
                onTimeChanged: (time) => viewModel.updateMealTime('breakfast', time),
              ),
              _buildTimePickerTile(
                title: 'Lunch Time',
                time: viewModel.getLunchTime(),
                onTimeChanged: (time) => viewModel.updateMealTime('lunch', time),
              ),
              _buildTimePickerTile(
                title: 'Dinner Time',
                time: viewModel.getDinnerTime(),
                onTimeChanged: (time) => viewModel.updateMealTime('dinner', time),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieTrackingSection(NotificationViewModel viewModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSwitchTile(
              title: 'Calorie Goal Reminders',
              subtitle: 'Get updates on your daily calorie progress',
              value: viewModel.getCalorieGoalsEnabled(),
              onChanged: (value) => viewModel.toggleCalorieGoals(value),
            ),
            if (viewModel.getCalorieGoalsEnabled()) ...[
              const Divider(),
              _buildTimePickerTile(
                title: 'Daily Summary Time',
                time: viewModel.getCalorieGoalTime(),
                onTimeChanged: (time) => viewModel.updateMealTime('calorieGoal', time),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyReportsSection(NotificationViewModel viewModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSwitchTile(
              title: 'Weekly Nutrition Reports',
              subtitle: 'Get a summary of your weekly nutrition',
              value: viewModel.getWeeklyReportsEnabled(),
              onChanged: (value) => viewModel.toggleWeeklyReports(value),
            ),
            if (viewModel.getWeeklyReportsEnabled()) ...[
              const Divider(),
              _buildDayPickerTile(
                title: 'Report Day',
                day: viewModel.getWeeklyReportDay(),
                onDayChanged: (day) => viewModel.updateWeeklyReportSettings(day, viewModel.getWeeklyReportTime()),
              ),
              _buildTimePickerTile(
                title: 'Report Time',
                time: viewModel.getWeeklyReportTime(),
                onTimeChanged: (time) => viewModel.updateWeeklyReportSettings(viewModel.getWeeklyReportDay(), time),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaterRemindersSection(NotificationViewModel viewModel) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildSwitchTile(
          title: 'Water Intake Reminders',
          subtitle: 'Get reminded to drink water throughout the day',
          value: viewModel.getWaterRemindersEnabled(),
          onChanged: (value) => viewModel.toggleWaterReminders(value),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Color(AppConstants.primaryGreen),
    );
  }

  Widget _buildTimePickerTile({
    required String title,
    required String time,
    required Function(String) onTimeChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        time,
        style: TextStyle(
          fontFamily: 'Poppins',
          color: Color(AppConstants.primaryGreen),
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.access_time, color: Color(AppConstants.primaryGreen)),
      onTap: () => _showTimePicker(context, time, onTimeChanged),
    );
  }

  Widget _buildDayPickerTile({
    required String title,
    required String day,
    required Function(String) onDayChanged,
  }) {
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
              subtitle: Text(
          day.capitalize(),
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(AppConstants.primaryGreen),
            fontWeight: FontWeight.w600,
          ),
        ),
      trailing: Icon(Icons.calendar_today, color: Color(AppConstants.primaryGreen)),
      onTap: () => _showDayPicker(context, day, days, onDayChanged),
    );
  }

  Widget _buildClearAllButton(NotificationViewModel viewModel) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showClearAllDialog(context, viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Clear All Notifications',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, String currentTime, Function(String) onTimeChanged) {
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    showTimePicker(
      context: context,
      initialTime: initialTime,
    ).then((time) {
      if (time != null) {
        final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        onTimeChanged(timeString);
      }
    });
  }

  void _showDayPicker(BuildContext context, String currentDay, List<String> days, Function(String) onDayChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Day'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              return ListTile(
                title: Text(day.capitalize()),
                trailing: day == currentDay ? Icon(Icons.check, color: Color(AppConstants.primaryGreen)) : null,
                onTap: () {
                  onDayChanged(day);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, NotificationViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all scheduled notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              viewModel.clearAllNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 