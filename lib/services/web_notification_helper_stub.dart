/// Stub implementation for non-web platforms.
class WebNotificationHelperImpl {
  static bool get isSupported => false;
  static String get permission => 'denied';
  static Future<bool> requestPermission() async => false;
  static void show(String title, {String? body}) {}
}
