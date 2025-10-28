import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/swap_offer.dart';

class SwapOffersProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  List<SwapOffer> _mySentOffers = [];
  List<SwapOffer> _listingOffers = [];

  List<SwapOffer> get mySentOffers => List.unmodifiable(_mySentOffers);
  List<SwapOffer> get listingOffers => List.unmodifiable(_listingOffers);

  Future<void> fetchMySentOffers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final qs = await _firestore
        .collection('swap_offers')
        .where('fromUserId', isEqualTo: user.uid)
        .get();
    _mySentOffers = qs.docs.map((e) => SwapOffer.fromJson(e.data())).toList();
    notifyListeners();
  }

  Future<void> fetchListingOffers(String listingId) async {
    final qs = await _firestore
        .collection('swap_offers')
        .where('listingId', isEqualTo: listingId)
        .get();
    _listingOffers = qs.docs.map((e) => SwapOffer.fromJson(e.data())).toList();
    notifyListeners();
  }

  Future<bool> createSwapOffer({
    required String listingId,
    required String toUserId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    // Only one active offer per listing/user
    final exists = await _firestore
        .collection('swap_offers')
        .where('listingId', isEqualTo: listingId)
        .where('fromUserId', isEqualTo: user.uid)
        .get();
    if (exists.docs.isNotEmpty) return false;
    final doc = _firestore.collection('swap_offers').doc();
    final offer = SwapOffer(
      offerId: doc.id,
      listingId: listingId,
      fromUserId: user.uid,
      toUserId: toUserId,
      state: SwapOfferState.pending,
      createdAt: DateTime.now(),
    );
    await doc.set(offer.toJson());
    await fetchMySentOffers();
    return true;
  }

  // Optionally: listener/stream for real-time updates
}
