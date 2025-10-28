import 'package:flutter/material.dart';
import '../models/book_listing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BookListingsProvider with ChangeNotifier {
  final List<BookListing> _listings = [];
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  bool _isListening = false;

  List<BookListing> get listings => List.unmodifiable(_listings);
  bool get isEmpty => _listings.isEmpty;

  void startListening() {
    if (_isListening) return;
    _firestore
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _listings.clear();
          for (final doc in snapshot.docs) {
            _listings.add(BookListing.fromJson(doc.data()));
          }
          notifyListeners();
        });
    _isListening = true;
  }

  Future<String> uploadCover(File file) async {
    final ref = _storage
        .ref()
        .child('book_covers')
        .child(DateTime.now().millisecondsSinceEpoch.toString() + '.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> postListing({
    required String title,
    required String author,
    required String swapFor,
    required BookCondition condition,
    required String coverUrl,
    String description = '',
    required String ownerId,
  }) async {
    final doc = _firestore.collection('listings').doc();
    final listing = BookListing(
      id: doc.id,
      ownerId: ownerId,
      title: title,
      author: author,
      swapFor: swapFor,
      condition: condition,
      coverUrl: coverUrl,
      description: description,
      createdAt: DateTime.now(),
      isActive: true,
    );
    await doc.set(listing.toJson());
  }
}
