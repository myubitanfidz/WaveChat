import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  static final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Cek apakah Bluetooth aktif di perangkat
  static Future<bool> isBluetoothEnabled() async {
    return await _bluetooth.isEnabled ?? false;
  }

  // Minta sistem mengaktifkan Bluetooth jika masih mati
  static Future<bool> requestEnableBluetooth() async {
    return await _bluetooth.requestEnable() ?? false;
  }

  // Ambil daftar perangkat yang sudah pernah dipairing sebelumnya
  static Future<List<BluetoothDevice>> getBondedDevices() async {
    return await _bluetooth.getBondedDevices();
  }

  // Mulai memindai (discovery) perangkat baru di sekitar
  static Stream<BluetoothDiscoveryResult> startDiscovery() {
    return _bluetooth.startDiscovery();
  }

  // Buat perangkat terlihat oleh HP lain selama durasi tertentu (detik)
  static Future<int?> requestDiscoverable(int seconds) async {
    return await _bluetooth.requestDiscoverable(seconds);
  }
}