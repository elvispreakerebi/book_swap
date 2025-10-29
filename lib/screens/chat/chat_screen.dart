import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/chat_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatefulWidget {
  final String listingId;
  final String peerId;
  const ChatScreen({super.key, required this.listingId, required this.peerId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _peerDisplayName;
  String? _myDisplayName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Get peer display name
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.peerId)
          .get();
      setState(() => _peerDisplayName = snap.data()?['displayName'] ?? 'User');
      final me = FirebaseAuth.instance.currentUser;
      if (me != null) {
        final mySnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(me.uid)
            .get();
        setState(() => _myDisplayName = mySnap.data()?['displayName'] ?? 'Me');
      }
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          ChatProvider(listingId: widget.listingId, peerId: widget.peerId)
            ..startListening(),
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          final user = FirebaseAuth.instance.currentUser;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/listing/${widget.listingId}'),
              ),
              title: Text(_peerDisplayName ?? 'Chat'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 8,
                    ),
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, idx) {
                      final m = chatProvider.messages[idx];
                      final isMe = m.fromUserId == user?.uid;
                      final name = isMe ? _myDisplayName : _peerDisplayName;
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  backgroundColor: Colors.black12,
                                  child: Text(
                                    _getInitials(name),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 7),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 14,
                                  ),
                                  constraints: const BoxConstraints(
                                    maxWidth: 270,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Colors.yellow[700]
                                        : Color(0xFF191939),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Text(
                                    m.content,
                                    style: TextStyle(
                                      color: isMe ? Colors.black : Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 7),
                                CircleAvatar(
                                  backgroundColor: Colors.black12,
                                  child: Text(
                                    _getInitials(name),
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _textController,
                    builder: (context, value, _) {
                      final enabled = value.text.trim().isNotEmpty;
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(color: Colors.pink),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: enabled
                                ? () async {
                                    final content = _textController.text.trim();
                                    await Provider.of<ChatProvider>(
                                      context,
                                      listen: false,
                                    ).sendMessage(content);
                                    _textController.clear();
                                    Future.delayed(
                                      const Duration(milliseconds: 150),
                                      () {
                                        _scrollController.animateTo(
                                          _scrollController
                                              .position
                                              .maxScrollExtent,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeOut,
                                        );
                                      },
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              minimumSize: const Size(48, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.send, color: Colors.white),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
