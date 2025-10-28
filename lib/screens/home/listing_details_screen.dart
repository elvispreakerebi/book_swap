import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';
import '../../models/book_listing.dart';
import '../../models/swap_offer.dart';
import '../../providers/swap_offers_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    SwapOffersProvider provider,
    String listingId,
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              if (offer.state == SwapOfferState.pending)
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 38),
                                      ),
                                      onPressed: () async {
                                        // Accept: update state in Firestore
                                        await FirebaseFirestore.instance
                                            .collection('swap_offers')
                                            .doc(offer.offerId)
                                            .update({'state': 'accepted'});
                                        setState(() {
                                          provider.listingOffers[provider
                                              .listingOffers
                                              .indexWhere(
                                                (o) =>
                                                    o.offerId == offer.offerId,
                                              )] = offer.copyWith(
                                            state: SwapOfferState.accepted,
                                          );
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Offer accepted.'),
                                          ),
                                        );
                                      },
                                      child: const Text('Accept'),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        minimumSize: const Size(0, 38),
                                      ),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('swap_offers')
                                            .doc(offer.offerId)
                                            .update({'state': 'cancelled'});
                                        setState(() {
                                          provider.listingOffers[provider
                                              .listingOffers
                                              .indexWhere(
                                                (o) =>
                                                    o.offerId == offer.offerId,
                                              )] = offer.copyWith(
                                            state: SwapOfferState.cancelled,
                                          );
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Offer cancelled.'),
                                          ),
                                        );
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                )
                              else ...[
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
              builder: (context, snapshot) =>
                  (swapOffersProvider.listingOffers.isNotEmpty
                  ? Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                        ),
                        onPressed: () {
                          _showSwapOffersModal(
                            context,
                            swapOffersProvider,
                            listing.id,
                          );
                        },
                        child: const Text('See Swap Offers'),
                      ),
                    )
                  : SizedBox.shrink()),
            );
          } else {
            // Non-owner: show Swap button (disabled if offer exists)
            bottomBar = FutureBuilder(
              future: swapOffersProvider.fetchMySentOffers(),
              builder: (context, snapshot) {
                final hasPending = swapOffersProvider.mySentOffers.any(
                  (o) =>
                      o.listingId == listing.id &&
                      o.state == SwapOfferState.pending,
                );
                return Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    onPressed: hasPending
                        ? null
                        : () async {
                            final ok = await swapOffersProvider.createSwapOffer(
                              listingId: listing.id,
                              toUserId: listing.ownerId,
                            );
                            if (ok) {
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
                            style: TextStyle(color: Colors.white),
                          )
                        : const Text(
                            'Swap',
                            style: TextStyle(color: Colors.white),
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
                onPressed: () => context.pop(),
              ),
              title: Text(
                listing.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: isOwner
                  ? [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit',
                        onPressed: () {
                          context.push(
                            '/edit_book/${listing.id}',
                            extra: listing,
                          );
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                                              ),
                                              onPressed: isLoading
                                                  ? null
                                                  : () async {
                                                      setState(
                                                        () => isLoading = true,
                                                      );
                                                      await Provider.of<
                                                            BookListingsProvider
                                                          >(
                                                            context,
                                                            listen: false,
                                                          )
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
                                                          'title':
                                                              listing.title,
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
                    ]
                  : null,
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
                    Text(
                      isOwner ? 'You own this' : 'Owner: Unknown User',
                      style: TextStyle(
                        fontSize: 15,
                        color: isOwner ? Colors.pink : Colors.black87,
                      ),
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
