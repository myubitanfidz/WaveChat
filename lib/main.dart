import 'package:flutter/material.dart';

void main() {
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
  // Simulasi data perangkat/teman di sekitar (Dummy Data)
  final List<Map<String, dynamic>> _dummyPeers = [
    {
      'name': 'Andi_Redmi9',
      'uuid': 'UUID-9CAA-1B54',
      'status': 'Online (Dekat)',
      'distance': '~12 m',
    },
    {
      'name': 'Budi_Laptop',
      'uuid': 'UUID-7F21-44A9',
      'status': 'Offline',
      'distance': 'Terakhir terlihat 5m lalu',
    },
    {
      'name': 'Citra_Phone',
      'uuid': 'UUID-3B89-11C0',
      'status': 'Online (Dekat)',
      'distance': '~25 m',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mesh Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Pindai Ulang',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memindai perangkat di sekitar...')),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8.0),
        itemCount: _dummyPeers.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final peer = _dummyPeers[index];
          final isOnline = peer['status'].toString().contains('Online');

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isOnline ? Colors.indigo : Colors.grey,
              child: Text(
                peer['name'][0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              peer['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${peer['uuid']} • ${peer['distance']}'),
            trailing: Icon(
              Icons.circle,
              size: 12,
              color: isOnline ? Colors.green : Colors.grey,
            ),
            onTap: () {
              // Navigasi ke ruang percakapan
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomScreen(peerName: peer['name']),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Membuka mode penerima/beacon...')),
          );
        },
        icon: const Icon(Icons.bluetooth_searching),
        label: const Text('Buat Diri Terlihat'),
      ),
    );
  }
}

class ChatRoomScreen extends StatefulWidget {
  final String peerName;
  const ChatRoomScreen({super.key, required this.peerName});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();

  // Simulasi riwayat chat lokal
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'other',
      'text': 'Halo! Apakah sinyal Bluetooth sampai ke situ?',
      'time': '10:00',
    },
    {
      'sender': 'me',
      'text': 'Sampai, koneksi RFCOMM aman tanpa internet!',
      'time': '10:01',
    },
  ];

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'sender': 'me',
        'text': _textController.text.trim(),
        'time': '10:05',
      });
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == 'me';

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
                          ? CrossCastAlignEnd(CrossAxisAlignment.end)
                          : CrossCastAlignStart(CrossAxisAlignment.start),
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'],
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 11,
                          ),
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
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur kirim foto akan diintegrasikan')),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan offline...',
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

// Helper alignment
CrossAxisAlignment CrossCastAlignEnd(CrossAxisAlignment val) => CrossAxisAlignment.end;
CrossAxisAlignment CrossCastAlignStart(CrossAxisAlignment val) => CrossAxisAlignment.start;