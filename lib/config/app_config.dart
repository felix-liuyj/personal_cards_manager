class AppConfig {
  static const String appName = '卡片管理';
  static const String databaseName = 'pcm_database';
  static const int databaseVersion = 1;

  // Security
  static const int pinMinLength = 4;
  static const int pinMaxLength = 8;
  static const int maxPinAttempts = 5;
  static const int lockoutDurationSeconds = 300;
  static const int autoLockTimeoutMinutes = 5;
  static const int sensitiveInfoDisplaySeconds = 30;
  static const int clipboardClearSeconds = 60;

  // Reminders
  static const List<int> defaultReminderDays = [30, 14, 7, 3, 0];
}
