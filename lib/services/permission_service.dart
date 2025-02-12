import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class PermissionService {
  static Future<bool> requestAlarmPermission(BuildContext context) async {
    try {
      final bool isInitialized = await AndroidAlarmManager.initialize();

      if (!isInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not initialize alarm manager'),
          ),
        );
        return false;
      }

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting permission: $e'),
        ),
      );
      return false;
    }
  }
}
