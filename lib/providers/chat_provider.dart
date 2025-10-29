import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatProvider with ChangeNotifier {
  final String listingId;
  final String peerId;
  final _firestore = FirebaseFirestore.instance;
  List<ChatMessage> _messages = [];
  bool _isListening = false;
  ChatProvider({required this.listingId, required this.peerId});

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  int get unreadCount => _messages
      .where(
        (m) => !m.read && m.toUserId == FirebaseAuth.instance.currentUser?.uid,
      )
      .length;

  void startListening() {
    if (_isListening) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    _firestore
        .collection('chat_messages')
        .where('listingId', isEqualTo: listingId)
        .where('peerIds', arrayContains: userId)
        .orderBy('createdAt')
        .snapshots()
        .listen((snapshot) {
          _messages = snapshot.docs
              .map((doc) => ChatMessage.fromJson(doc.data()))
              .toList();
          notifyListeners();
        });
    _isListening = true;
  }

  Future<void> sendMessage(String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = _firestore.collection('chat_messages').doc();
    final msg = ChatMessage(
      id: doc.id,
      listingId: listingId,
      fromUserId: user.uid,
      toUserId: peerId,
      content: content,
      read: false,
      createdAt: DateTime.now(),
    );
    // Add message locally for instant UI update
    _messages.add(msg);
    notifyListeners();
    await doc.set({
      ...msg.toJson(),
      'peerIds': [user.uid, peerId],
    });
    // Notification for peer
    final notificationDoc = FirebaseFirestore.instance
        .collection('notifications')
        .doc();
    await notificationDoc.set({
      'id': notificationDoc.id,
      'userId': peerId,
      'type': 'chatMsg',
      'title': 'New message',
      'body': content.length > 50 ? content.substring(0, 50) + '...' : content,
      'data': {'listingId': listingId, 'messageId': doc.id},
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> markMessageAsRead(String messageId) async {
    await _firestore.collection('chat_messages').doc(messageId).update({
      'read': true,
    });
  }

  @override
  void dispose() {
    _isListening = false;
    super.dispose();
  }
}
