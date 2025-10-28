import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';
import '../../models/book_listing.dart';
import '../../models/swap_offer.dart';
import '../../providers/swap_offers_provider.dart';

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
                          // TODO: Navigate to swap offers screen for this listing
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'TODO: See Swap Offers for this book.',
                              ),
                            ),
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
          return Stack(
            children: [
              ListView(
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
                    style: const TextStyle(
                      fontSize: 15.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 19, color: Colors.black45),
                      const SizedBox(width: 5),
                      Text(
                        isOwner ? 'You own this' : 'Owner: ${listing.ownerId}',
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
              if (bottomBar != null)
                Positioned(left: 0, right: 0, bottom: 0, child: bottomBar),
            ],
          );
        },
      ),
    );
  }
}
