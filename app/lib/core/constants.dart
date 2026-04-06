class AppConstants {
  AppConstants._();

  static const String appName = 'Favo de Colorir';

  // Class capacities
  static const int regularClassCapacity = 8;
  static const int workshopCapacity = 10;

  // Reposition limits
  static const int maxRepositionsPerMonth = 1;

  // Notification timing (hours before class)
  static const int attendanceReminderHours = 24;
  static const int attendanceFollowUpHours = 6;

  // Waitlist expiry (hours)
  static const int waitlistExpiryHours = 24;

  // Class duration (hours)
  static const int defaultClassDurationHours = 2;

  // Image limits
  static const int maxFeedPhotos = 10;
  static const double maxImageWidthPx = 1200;
  static const int maxAvatarSizeMB = 5;
  static const int maxFeedPhotoSizeMB = 10;

  // Pagination
  static const int defaultPageSize = 20;

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String feedBucket = 'feed';
}
