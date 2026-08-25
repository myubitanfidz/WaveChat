import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) return true;

    // Untuk Android 12+ (API 31+)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ].request();

    bool allGranted = statuses.values.every(
      (status) => status.isGranted || status.isLimited,
    );

    return allGranted;
  }
}