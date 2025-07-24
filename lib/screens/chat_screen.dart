import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  late String senderId;

  @override
  void initState() {
    super.initState();
    senderId = _auth.currentUser!.uid;
  }

  void sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final chatModel = ChatModel(
      senderId: senderId,
      receiverId: widget.receiverId,
      message: messageText,
      timestamp: timestamp,
    );

    final senderRoom = '$senderId-${widget.receiverId}';
    final receiverRoom = '${widget.receiverId}-$senderId';

    _database
        .child('chats')
        .child(senderRoom)
        .child(timestamp)
        .set(chatModel.toMap());
    _database
        .child('chats')
        .child(receiverRoom)
        .child(timestamp)
        .set(chatModel.toMap());

    _messageController.clear();
  }

  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    return DateFormat('hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final senderRoom = '$senderId-${widget.receiverId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _database
                  .child('chats')
                  .child(senderRoom)
                  .orderByKey()
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    (snapshot.data!).snapshot.value != null) {
                  final messagesMap = (snapshot.data!).snapshot.value as Map;
                  final messages =
                      messagesMap.entries.map((entry) {
                          return ChatModel.fromMap(
                            Map<String, dynamic>.from(entry.value),
                          );
                        }).toList()
                        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  return ListView.builder(
                    itemCount: messages.length,
                    padding: const EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == senderId;
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.message,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatTimestamp(msg.timestamp),
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: Text('No messages yet'));
                }
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
