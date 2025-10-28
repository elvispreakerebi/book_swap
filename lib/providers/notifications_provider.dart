import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationsProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<AppNotification> _notifications = [];
  bool _isListening = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  void startListening() {
    if (_isListening) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _notifications = snapshot.docs
              .map((doc) => AppNotification.fromJson(doc.data()))
              .toList();
          notifyListeners();
        });
    _isListening = true;
  }

  Future<void> fetchNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final qs = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .get();
    _notifications = qs.docs
        .map((doc) => AppNotification.fromJson(doc.data()))
        .toList();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final doc = _firestore.collection('notifications').doc(id);
    await doc.update({'read': true});
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(read: true);
      notifyListeners();
    }
  }

  Future<void> createNotification(AppNotification notification) async {
    final doc = _firestore.collection('notifications').doc(notification.id);
    await doc.set(notification.toJson());
    await fetchNotifications();
  }
}
