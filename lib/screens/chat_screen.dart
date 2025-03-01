import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math';
import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showSendButton = false;
  late AnimationController _typingIndicatorController;

  @override
  void initState() {
    super.initState();
    _typingIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Listen for changes in text to show/hide the send button
    messageController.addListener(() {
      setState(() {
        _showSendButton = messageController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _typingIndicatorController.dispose();
    _scrollController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // Send message to Firestore
  void sendMessage() async {
    String message = messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _isTyping = false;
      });
      await _firestoreService.sendMessage(message);
      messageController.clear();

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat.jm().format(date); // Today, show time
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.EEEE().format(date); // Day of week
    } else {
      return DateFormat.yMMMd().format(date); // Full date
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Messages",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              "Online now",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            child: IconButton(
              icon: Icon(
                Icons.video_call_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            child: IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 16),
        ],
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Message timeline indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Today',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),

          // Chat messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getChatMessages(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> docs = snapshot.data!.docs;

                // Auto scroll to bottom when new messages come in
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: docs.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == docs.length && _isTyping) {
                      // Show typing indicator
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: _buildTypingIndicator(),
                      );
                    }

                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isSender =
                        data['senderId'] ==
                        FirebaseAuth.instance.currentUser?.uid;
                    String message = data['message'] ?? "";
                    Timestamp? timestamp = data['timestamp'] as Timestamp?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment:
                            isSender
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isSender) ...[
                            // Avatar for other user
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              child: const Text(
                                "U",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Message bubble
                          Flexible(
                            child: Column(
                              crossAxisAlignment:
                                  isSender
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSender
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft:
                                          isSender
                                              ? const Radius.circular(20)
                                              : const Radius.circular(5),
                                      bottomRight:
                                          isSender
                                              ? const Radius.circular(5)
                                              : const Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    message,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          isSender
                                              ? Colors.white
                                              : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),

                                // Timestamp
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatTimestamp(timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Attachment button
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {},
                          iconSize: 22,
                          padding: EdgeInsets.all(8),
                          constraints: BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Message input field
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 120),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: messageController,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                    hintText: "Message",
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  style: TextStyle(fontSize: 16),
                                  onChanged: (value) {
                                    // Show typing indicator for demo purposes
                                    setState(() {
                                      _isTyping = false;
                                    });
                                  },
                                ),
                              ),

                              // Camera button
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.camera_alt,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  onPressed: () {},
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send button (or microphone if no text)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (
                          Widget child,
                          Animation<double> animation,
                        ) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child:
                            _showSendButton
                                ? Container(
                                  key: const ValueKey('send'),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_upward,
                                      color: Colors.white,
                                    ),
                                    onPressed: sendMessage,
                                    iconSize: 22,
                                    padding: EdgeInsets.all(8),
                                    constraints: BoxConstraints(),
                                  ),
                                )
                                : Container(
                                  key: const ValueKey('mic'),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.mic,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    onPressed: () {},
                                    iconSize: 22,
                                    padding: EdgeInsets.all(8),
                                    constraints: BoxConstraints(),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _typingIndicatorController,
            builder: (context, child) {
              final double bounce =
                  sin((_typingIndicatorController.value * 6.28) + index * 1.0) *
                  3;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                transform: Matrix4.translationValues(0, -bounce, 0),
              );
            },
          );
        }),
      ),
    );
  }
}
