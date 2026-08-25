import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothConnectionManager {
  BluetoothConnection? _connection;
  bool get isConnected => _connection != null && _connection!.isConnected;

  // Hubungkan ke perangkat target sebagai Client
  Future<bool> connect(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address);
      return true;
    } catch (e) {
      debugPrint('Gagal terhubung ke $address: $e');
      return false;
    }
  }

  // Dengarkan aliran data byte masuk (Listening Stream)
  void listenMessages({
    required Function(String text) onMessageReceived,
    required Function() onDisconnected,
  }) {
    _connection?.input?.listen(
      (Uint8List data) {
        // Konversi byte UTF-8 menjadi string teks
        final message = utf8.decode(data);
        onMessageReceived(message);
      },
      onDone: () {
        onDisconnected();
      },
      onError: (error) {
        debugPrint('Error socket input: $error');
        onDisconnected();
      },
    );
  }

  // Kirim string teks sebagai byte UTF-8 ke socket target
  Future<bool> sendMessage(String text) async {
    if (!isConnected) return false;
    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode(text)));
      await _connection!.output.allSent;
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Putus koneksi socket
  void disconnect() {
    _connection?.dispose();
    _connection = null;
  }
}