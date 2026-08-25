import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:bluetooth_offline_chat/models/message_model.dart';
import 'package:bluetooth_offline_chat/services/database_helper.dart';
import 'package:bluetooth_offline_chat/services/permission_service.dart';
import 'package:bluetooth_offline_chat/services/bluetooth_service.dart';
import 'package:bluetooth_offline_chat/services/bluetooth_connection_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OfflineChatApp());
}

class OfflineChatApp extends StatelessWidget {
  const OfflineChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Offline Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BluetoothDevice> _bondedDevices = [];
  final List<BluetoothDiscoveryResult> _discoveryResults = [];
  bool _isDiscovering = false;
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    final granted = await PermissionService.requestBluetoothPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin Bluetooth diperlukan')),
        );
      }
      return;
    }

    final isEnabled = await BluetoothService.isBluetoothEnabled();
    if (!isEnabled) {
      await BluetoothService.requestEnableBluetooth();
    }

    _loadBondedDevices();
  }

  Future<void> _loadBondedDevices() async {
    try {
      final devices = await BluetoothService.getBondedDevices();
      if (mounted) {
        setState(() {
          _bondedDevices = devices;
        });
      }
    } catch (e) {
      debugPrint('Error get bonded devices: $e');
    }
  }

  void _startScanning() {
    setState(() {
      _isDiscovering = true;
      _discoveryResults.clear();
    });

    _discoveryStreamSubscription = BluetoothService.startDiscovery().listen(
      (result) {
        final existingIndex = _discoveryResults.indexWhere(
          (element) => element.device.address == result.device.address,
        );

        setState(() {
          if (existingIndex >= 0) {
            _discoveryResults[existingIndex] = result;
          } else {
            _discoveryResults.add(result);
          }
        });
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isDiscovering = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Discovery error: $e');
        if (mounted) {
          setState(() {
            _isDiscovering = false;
          });
        }
      },
    );
  }

  Future<void> _makeDiscoverable() async {
    final duration = await BluetoothService.requestDiscoverable(120);
    if (mounted && duration != null && duration > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perangkat terlihat selama $duration detik')),
      );
    }
  }

  @override
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mesh Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: _isDiscovering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Pindai Perangkat',
            onPressed: _isDiscovering ? null : _startScanning,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          if (_bondedDevices.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                'Perangkat Tersimpan (Paired)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
            ..._bondedDevices.map(
              (device) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.bluetooth, color: Colors.white),
                ),
                title: Text(device.name ?? 'Perangkat Tanpa Nama'),
                subtitle: Text(device.address),
                trailing: const Icon(Icons.link, color: Colors.green),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(
                        peerName: device.name ?? device.address,
                        peerAddress: device.address,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              'Perangkat Baru Sekitar',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
          ),
          if (_discoveryResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  _isDiscovering
                      ? 'Sedang mencari perangkat Bluetooth...'
                      : 'Tekan ikon refresh di atas untuk memindai.',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._discoveryResults.map(
              (result) {
                final device = result.device;
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.bluetooth_searching, color: Colors.white),
                  ),
                  title: Text(device.name ?? 'Unknown Device'),
                  subtitle: Text('${device.address} • RSSI: ${result.rssi} dBm'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          peerName: device.name ?? device.address,
                          peerAddress: device.address,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _makeDiscoverable,
        icon: const Icon(Icons.visibility),
        label: const Text('Buat Diri Terlihat'),
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String peerName;
  final String peerAddress;
  const ChatRoomScreen({
    super.key,
    required this.peerName,
    required this.peerAddress,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final BluetoothConnectionManager _connectionManager = BluetoothConnectionManager();

  List<MessageModel> _messages = [];
  bool _isConnecting = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initConnection();
  }

  Future<void> _initConnection() async {
    final success = await _connectionManager.connect(widget.peerAddress);
    if (!mounted) return;

    setState(() {
      _isConnecting = false;
      _isConnected = success;
    });

    if (success) {
      _connectionManager.listenMessages(
        onMessageReceived: _handleIncomingRawPayload,
        onDisconnected: _handleDisconnected,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat koneksi RFCOMM ke perangkat.')),
      );
    }
  }

  void _handleIncomingRawPayload(String rawPayload) async {
    try {
      final Map<String, dynamic> data = jsonDecode(rawPayload);
      final type = data['type'];

      if (type == 'CHAT') {
        final incomingId = data['id'] ?? '';
        final body = data['body'] ?? '';
        final timestamp = data['timestamp'] ?? '';

        final incomingMsg = MessageModel(
          messageId: incomingId,
          peerAddress: widget.peerAddress,
          sender: 'other',
          text: body,
          timestamp: timestamp,
          status: 'DELIVERED',
        );

        await DatabaseHelper.instance.insertMessage(incomingMsg);
        _loadMessages();

        // Kirim konfirmasi (ACK) balik ke pengirim
        if (_isConnected) {
          final ackPayload = jsonEncode({'type': 'ACK', 'id': incomingId});
          await _connectionManager.sendMessage(ackPayload);
        }
      } else if (type == 'ACK') {
        final ackId = data['id'];
        if (ackId != null) {
          await DatabaseHelper.instance.updateMessageStatus(ackId, 'DELIVERED');
          _loadMessages();
        }
      }
    } catch (e) {
      debugPrint('Error parsing incoming payload: $e');
    }
  }

  void _handleDisconnected() {
    if (mounted) {
      setState(() {
        _isConnected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi Bluetooth terputus.')),
      );
    }
  }

  Future<void> _loadMessages() async {
    try {
      final data = await DatabaseHelper.instance.getMessages(widget.peerAddress);
      if (mounted) {
        setState(() {
          _messages = data;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final generatedMsgId = '${now.millisecondsSinceEpoch}_${widget.peerAddress.hashCode}';

    final newMessage = MessageModel(
      messageId: generatedMsgId,
      peerAddress: widget.peerAddress,
      sender: 'me',
      text: text,
      timestamp: timeStr,
      status: _isConnected ? 'SENT' : 'SENDING',
    );

    _textController.clear();

    if (_isConnected) {
      await _connectionManager.sendMessage(newMessage.toJsonPayload());
    }

    try {
      await DatabaseHelper.instance.insertMessage(newMessage);
      await _loadMessages();
    } catch (e) {
      debugPrint('Error inserting message: $e');
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'DELIVERED':
        return Icons.done_all;
      case 'SENT':
        return Icons.done;
      default:
        return Icons.access_time;
    }
  }

  @override
  void dispose() {
    _connectionManager.disconnect();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName, style: const TextStyle(fontSize: 16)),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnecting
                      ? 'Menghubungkan...'
                      : (_isConnected ? 'Terhubung' : 'Terputus'),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada pesan. Mulai percakapan!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.sender == 'me';

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.indigo.shade600
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    msg.timestamp,
                                    style: TextStyle(
                                      color: isMe ? Colors.white70 : Colors.black54,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      _getStatusIcon(msg.status),
                                      size: 14,
                                      color: msg.status == 'DELIVERED'
                                          ? Colors.lightBlueAccent
                                          : Colors.white70,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _isConnected
                          ? 'Ketik pesan offline...'
                          : 'Perangkat tidak terhubung...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}