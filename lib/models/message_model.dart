import 'dart:convert';

class MessageModel {
  final int? id;
  final String messageId; // UUID unik per pesan
  final String peerAddress;
  final String sender; // 'me' atau 'other'
  final String text;
  final String timestamp;
  final String status; // 'SENDING', 'SENT', 'DELIVERED', 'FAILED'

  MessageModel({
    this.id,
    required this.messageId,
    required this.peerAddress,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.status = 'SENT',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message_id': messageId,
      'peer_address': peerAddress,
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
      'status': status,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      messageId: map['message_id'] ?? '',
      peerAddress: map['peer_address'],
      sender: map['sender'],
      text: map['text'],
      timestamp: map['timestamp'],
      status: map['status'] ?? 'SENT',
    );
  }

  // Format untuk transmisi RFCOMM
  String toJsonPayload() {
    return jsonEncode({
      'type': 'CHAT',
      'id': messageId,
      'body': text,
      'timestamp': timestamp,
    });
  }
}