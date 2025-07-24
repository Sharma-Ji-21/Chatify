import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import '../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverEmail,
    required this.receiverName,
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                color: Colors.transparent,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const CircleAvatar(
                      backgroundColor: Colors.tealAccent,
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.receiverName,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),

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
                      final messagesMap =
                          (snapshot.data!).snapshot.value as Map;
                      final messages =
                          messagesMap.entries
                              .map(
                                (entry) => ChatModel.fromMap(
                                  Map<String, dynamic>.from(entry.value),
                                ),
                              )
                              .toList()
                            ..sort(
                              (a, b) => a.timestamp.compareTo(b.timestamp),
                            );

                      return ListView.builder(
                        itemCount: messages.length,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.senderId == senderId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.tealAccent.shade700
                                    : Colors.white10,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe
                                      ? const Radius.circular(16)
                                      : const Radius.circular(0),
                                  bottomRight: isMe
                                      ? const Radius.circular(0)
                                      : const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.message,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTimestamp(msg.timestamp),
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white12,
                  border: Border(top: BorderSide(color: Colors.white24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.white,
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          hintText: 'Type your message...',
                          hintStyle: const TextStyle(color: Colors.white60),
                          filled: true,
                          fillColor: Colors.white24,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.tealAccent.shade700,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.black),
                        onPressed: sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
