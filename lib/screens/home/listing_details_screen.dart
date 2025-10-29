import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';
import '../../models/book_listing.dart';
import '../../models/swap_offer.dart';
import '../../providers/swap_offers_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification_model.dart';
import '../../services/cloudinary_service.dart';

class ListingDetailsScreen extends StatelessWidget {
  final String listingId;
  const ListingDetailsScreen({super.key, required this.listingId});

  String _bookConditionText(BookCondition condition) {
    try {
      // Dart 2.15+ enums
      // ignore: invalid_use_of_protected_member
      // ignore: invalid_use_of_internal_member
      return (condition as dynamic).name != null
          ? (condition as dynamic).name.toString().replaceAll(
              'LikeNew',
              'Like New',
            )
          : condition
                .toString()
                .replaceAll('BookCondition.', '')
                .replaceAll('LikeNew', 'Like New');
    } catch (_) {
      return condition
          .toString()
          .replaceAll('BookCondition.', '')
          .replaceAll('LikeNew', 'Like New');
    }
  }

  void _showSwapOffersModal(
    BuildContext context,
    BuildContext rootContext,
    SwapOffersProvider provider,
    String listingId,
    BookListing listing,
  ) async {
    await provider.fetchListingOffers(listingId);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final offers = provider.listingOffers;
            final Map<String, bool> loading = {};
            return Padding(
              padding: MediaQuery.of(
                context,
              ).viewInsets.add(const EdgeInsets.all(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Swap Offers',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (offers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'No swap offers yet.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  else
                    ...offers.map(
                      (offer) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>
                                  >(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(offer.fromUserId)
                                        .get(),
                                    builder: (context, snap) {
                                      final data = snap.data?.data();
                                      final display =
                                          data != null &&
                                              (data['displayName'] as String?)
                                                      ?.isNotEmpty ==
                                                  true
                                          ? data['displayName']
                                          : 'Unknown User';
                                      return Text(
                                        'From: $display',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chat,
                                      color: Colors.pink,
                                    ),
                                    tooltip: 'Chat',
                                    onPressed: () {
                                      context.go(
                                        '/chat/${listing.id}/${offer.fromUserId}',
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (offer.state == SwapOfferState.pending)
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 38),
                                      ),
                                      onPressed:
                                          (loading[offer.offerId] == true)
                                          ? null
                                          : () async {
                                              setState(
                                                () => loading[offer.offerId] =
                                                    true,
                                              );
                                              // Accept button pressed
                                              // Accept this offer
                                              await FirebaseFirestore.instance
                                                  .collection('swap_offers')
                                                  .doc(offer.offerId)
                                                  .update({
                                                    'state': 'accepted',
                                                  });
                                              // Fetch displayName for the snack
                                              final userSnap =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(offer.fromUserId)
                                                      .get();
                                              final displayName =
                                                  (userSnap.data()?['displayName']
                                                          as String?)
                                                      ?.trim() ??
                                                  'user';
                                              // Send notification to initiator
                                              final notif = AppNotification(
                                                id: DateTime.now()
                                                    .millisecondsSinceEpoch
                                                    .toString(),
                                                userId: offer.fromUserId,
                                                type: AppNotificationType
                                                    .offerAccepted,
                                                title: 'Swap Offer Accepted',
                                                body:
                                                    'Your swap offer for ${listing.title} was accepted.',
                                                data: {
                                                  'listingId': listing.id,
                                                  'offerId': offer.offerId,
                                                },
                                                read: false,
                                                createdAt: DateTime.now(),
                                              );
                                              await Provider.of<
                                                    NotificationsProvider
                                                  >(context, listen: false)
                                                  .createNotification(notif);

                                              // Reject all other pending offers on this listing and notify their users
                                              final snapshot =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('swap_offers')
                                                      .where(
                                                        'listingId',
                                                        isEqualTo: listing.id,
                                                      )
                                                      .get();
                                              for (var doc in snapshot.docs) {
                                                final data = doc.data();
                                                if (doc.id != offer.offerId &&
                                                    data['state'] ==
                                                        'pending') {
                                                  await doc.reference.update({
                                                    'state': 'cancelled',
                                                  });
                                                  final rejectedNotif = AppNotification(
                                                    id: DateTime.now()
                                                        .millisecondsSinceEpoch
                                                        .toString(),
                                                    userId: data['fromUserId'],
                                                    type: AppNotificationType
                                                        .offerRejected,
                                                    title:
                                                        'Swap Offer Rejected',
                                                    body:
                                                        'Your swap offer for ${listing.title} was rejected.',
                                                    data: {
                                                      'listingId': listing.id,
                                                      'offerId': doc.id,
                                                    },
                                                    read: false,
                                                    createdAt: DateTime.now(),
                                                  );
                                                  await Provider.of<
                                                        NotificationsProvider
                                                      >(context, listen: false)
                                                      .createNotification(
                                                        rejectedNotif,
                                                      );
                                                }
                                              }

                                              // Locally update state so UI disables all accept buttons, etc
                                              setState(() {
                                                for (
                                                  int i = 0;
                                                  i <
                                                      provider
                                                          .listingOffers
                                                          .length;
                                                  i++
                                                ) {
                                                  final o =
                                                      provider.listingOffers[i];
                                                  if (o.offerId ==
                                                      offer.offerId) {
                                                    provider.listingOffers[i] =
                                                        o.copyWith(
                                                          state: SwapOfferState
                                                              .accepted,
                                                        );
                                                  } else if (o.state ==
                                                      SwapOfferState.pending) {
                                                    provider.listingOffers[i] =
                                                        o.copyWith(
                                                          state: SwapOfferState
                                                              .cancelled,
                                                        );
                                                  }
                                                }
                                              });
                                              setState(
                                                () => loading[offer.offerId] =
                                                    false,
                                              );
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(
                                                rootContext,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Offer successfully accepted. $displayName has been notified.',
                                                  ),
                                                ),
                                              );
                                            },
                                      child: loading[offer.offerId] == true
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.2,
                                              ),
                                            )
                                          : const Text('Accept'),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        minimumSize: const Size(0, 38),
                                      ),
                                      onPressed:
                                          (loading[offer.offerId] == true)
                                          ? null
                                          : () async {
                                              setState(
                                                () => loading[offer.offerId] =
                                                    true,
                                              );
                                              await FirebaseFirestore.instance
                                                  .collection('swap_offers')
                                                  .doc(offer.offerId)
                                                  .update({
                                                    'state': 'cancelled',
                                                  });
                                              final userSnap =
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(offer.fromUserId)
                                                      .get();
                                              final displayName =
                                                  (userSnap.data()?['displayName']
                                                          as String?)
                                                      ?.trim() ??
                                                  'user';
                                              // Send notification to initiator
                                              final notif = AppNotification(
                                                id: DateTime.now()
                                                    .millisecondsSinceEpoch
                                                    .toString(),
                                                userId: offer.fromUserId,
                                                type: AppNotificationType
                                                    .offerRejected,
                                                title: 'Swap Offer Rejected',
                                                body:
                                                    'Your swap offer for ${listing.title} was rejected.',
                                                data: {
                                                  'listingId': listing.id,
                                                  'offerId': offer.offerId,
                                                },
                                                read: false,
                                                createdAt: DateTime.now(),
                                              );
                                              await Provider.of<
                                                    NotificationsProvider
                                                  >(context, listen: false)
                                                  .createNotification(notif);
                                              setState(() {
                                                provider.listingOffers[provider
                                                    .listingOffers
                                                    .indexWhere(
                                                      (o) =>
                                                          o.offerId ==
                                                          offer.offerId,
                                                    )] = offer.copyWith(
                                                  state:
                                                      SwapOfferState.cancelled,
                                                );
                                              });
                                              setState(
                                                () => loading[offer.offerId] =
                                                    false,
                                              );
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(
                                                rootContext,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Offer successfully rejected. $displayName has been notified.',
                                                  ),
                                                ),
                                              );
                                            },
                                      child: loading[offer.offerId] == true
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.pink,
                                                strokeWidth: 2.2,
                                              ),
                                            )
                                          : const Text('Cancel'),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  offer.state == SwapOfferState.accepted
                                      ? 'Accepted'
                                      : offer.state == SwapOfferState.cancelled
                                      ? 'Cancelled'
                                      : offer.state.name,
                                  style: TextStyle(
                                    color:
                                        offer.state == SwapOfferState.accepted
                                        ? Colors.green
                                        : offer.state ==
                                              SwapOfferState.cancelled
                                        ? Colors.red
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookListingsProvider>(context);
    final listing = provider.listings.cast<dynamic>().firstWhere(
      (l) => l != null && l.id == listingId,
      orElse: () => null,
    );
    final user = FirebaseAuth.instance.currentUser;
    final isOwner =
        user != null && listing != null && listing.ownerId == user.uid;

    if (listing == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Listing Details'),
          leading: BackButton(onPressed: () => context.pop()),
        ),
        body: const Center(child: Text('Listing not found.')),
      );
    }
    return ChangeNotifierProvider(
      create: (_) => SwapOffersProvider(),
      child: Builder(
        builder: (context) {
          final extra = GoRouterState.of(context).extra;
          if (extra is Map && extra['edited'] == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Changes saved.'),
                  duration: Duration(seconds: 2),
                ),
              );
            });
          }
          final swapOffersProvider = Provider.of<SwapOffersProvider>(context);
          final user = FirebaseAuth.instance.currentUser;
          final isOwner = user != null && listing.ownerId == user.uid;
          Widget? bottomBar;
          if (isOwner) {
            // Owner: see pending offers (if any)
            bottomBar = FutureBuilder(
              future: swapOffersProvider.fetchListingOffers(listing.id),
              builder: (context, snapshot) {
                final offers = swapOffersProvider.listingOffers;
                final acceptedOffer = offers.any(
                  (offer) => offer.state == SwapOfferState.accepted,
                );
                if (acceptedOffer) {
                  // Green button: swap offer accepted, cannot accept more
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: null, // disabled
                      child: const Text(
                        'Swap offer accepted',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  );
                }
                if (offers.isNotEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _showSwapOffersModal(
                          context,
                          context,
                          swapOffersProvider,
                          listing.id,
                          listing,
                        );
                      },
                      child: const Text(
                        'See Swap Offers',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          } else {
            // Non-owner: show Swap button (disabled if offer exists)
            bottomBar = FutureBuilder(
              future: swapOffersProvider.fetchMySentOffers(),
              builder: (context, snapshot) {
                final myOffers = swapOffersProvider.mySentOffers
                    .where((o) => o.listingId == listing.id)
                    .toList();
                SwapOfferState? userState = myOffers.isNotEmpty
                    ? myOffers.first.state
                    : null;
                if (userState == SwapOfferState.accepted) {
                  // Green: offer accepted for this user
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: null,
                      child: const Text(
                        'Offer accepted',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  );
                }
                if (userState == SwapOfferState.cancelled) {
                  // Grey, rejected
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: null,
                      child: const Text(
                        'Offer rejected',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  );
                }
                final hasPending = userState == SwapOfferState.pending;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: hasPending
                        ? null
                        : () async {
                            final ok = await swapOffersProvider.createSwapOffer(
                              listingId: listing.id,
                              toUserId: listing.ownerId,
                            );
                            if (ok) {
                              final notif = AppNotification(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                userId: listing.ownerId,
                                type: AppNotificationType.offerMade,
                                title: 'New Swap Offer',
                                body:
                                    'You received a swap offer for ${listing.title}.',
                                data: {
                                  'listingId': listing.id,
                                  'fromUser': user?.uid ?? '',
                                },
                                read: false,
                                createdAt: DateTime.now(),
                              );
                              await Provider.of<NotificationsProvider>(
                                context,
                                listen: false,
                              ).createNotification(notif);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Swap offer sent!'),
                                ),
                              );
                            }
                          },
                    child: hasPending
                        ? const Text(
                            'Pending',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          )
                        : const Text(
                            'Swap',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                );
              },
            );
          }
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: Text(
                listing.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (isOwner) ...[
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: () {
                      context.push('/edit_book/${listing.id}', extra: listing);
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    onPressed: () async {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (context) {
                          bool isLoading = false;
                          return StatefulBuilder(
                            builder: (context, setState) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Delete Listing',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Are you sure you want to delete this listing? This action cannot be undone.',
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: BorderSide(
                                              color: Colors.pink,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.pink,
                                            minimumSize: Size.fromHeight(48),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: isLoading
                                              ? null
                                              : () async {
                                                  setState(
                                                    () => isLoading = true,
                                                  );
                                                  // Prevent delete if ANY offers for this listing exist AND some are pending or accepted
                                                  final swapOffersProvider =
                                                      Provider.of<
                                                        SwapOffersProvider
                                                      >(context, listen: false);
                                                  await swapOffersProvider
                                                      .fetchListingOffers(
                                                        listing.id,
                                                      );
                                                  final hasUnresolved =
                                                      swapOffersProvider
                                                          .listingOffers
                                                          .any(
                                                            (o) =>
                                                                o.state ==
                                                                    SwapOfferState
                                                                        .pending ||
                                                                o.state ==
                                                                    SwapOfferState
                                                                        .accepted,
                                                          );
                                                  final hasReceivedOffer =
                                                      swapOffersProvider
                                                          .listingOffers
                                                          .isNotEmpty;
                                                  if (hasReceivedOffer &&
                                                      hasUnresolved) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Cannot delete listing while there are pending or accepted swap offers. Please reject or resolve all offers first.',
                                                        ),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  // Delete from Cloudinary first, then Firestore
                                                  try {
                                                    await CloudinaryService()
                                                        .deleteImage(
                                                          listing.coverUrl,
                                                        );
                                                  } catch (_) {}
                                                  await Provider.of<
                                                        BookListingsProvider
                                                      >(context, listen: false)
                                                      .deleteListing(
                                                        listing.id,
                                                      );
                                                  setState(
                                                    () => isLoading = false,
                                                  );
                                                  Navigator.of(
                                                    context,
                                                  ).pop(); // Close bottom sheet
                                                  context.go(
                                                    '/home',
                                                    extra: {
                                                      'deleted': true,
                                                      'title': listing.title,
                                                    },
                                                  );
                                                },
                                          child: isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.3,
                                                      ),
                                                )
                                              : const Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
                if (!isOwner)
                  IconButton(
                    icon: const Icon(Icons.chat),
                    tooltip: 'Chat',
                    onPressed: () {
                      context.go('/chat/${listing.id}/${listing.ownerId}');
                    },
                  ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AspectRatio(
                  aspectRatio: 1 / 1.45,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      listing.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey[200],
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  listing.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'by ${listing.author}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _bookConditionText(listing.condition),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.pink,
                        fontSize: 15.7,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Swap For: ${listing.swapFor}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text(
                  listing.description.isEmpty
                      ? 'No description provided.'
                      : listing.description,
                  style: const TextStyle(fontSize: 15.5, color: Colors.black87),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Icon(Icons.person, size: 19, color: Colors.black45),
                    const SizedBox(width: 5),
                    if (isOwner)
                      const Text(
                        'You own this',
                        style: TextStyle(fontSize: 15, color: Colors.pink),
                      )
                    else
                      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(listing.ownerId)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data?.data() == null) {
                            return const Text(
                              'Owner: Unknown User',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            );
                          }
                          final data = snapshot.data!.data()!;
                          final displayName = (data['displayName'] as String?)
                              ?.trim();
                          return Text(
                            'Owner: ${displayName != null && displayName.isNotEmpty ? displayName : 'Unknown User'}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 17,
                      color: Colors.black38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      listing.createdAt.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            bottomNavigationBar: bottomBar,
          );
        },
      ),
    );
  }
}
