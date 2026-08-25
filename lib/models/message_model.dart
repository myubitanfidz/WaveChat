class MessageModel {
  final int? id;
  final String peerAddress;
  final String sender; // 'me' atau 'other'
  final String text;
  final String timestamp;

  MessageModel({
    this.id,
    required this.peerAddress,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {  
    return {
      'id': id,
      'peer_address': peerAddress,
      'sender': sender,
      'text': text,
      'timestamp': timestamp,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      peerAddress: map['peer_address'],
      sender: map['sender'],
      text: map['text'],
      timestamp: map['timestamp'],
    );
  }
}