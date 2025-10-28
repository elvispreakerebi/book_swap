import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';
import '../../models/book_listing.dart';

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
                    // TODO: Implement edit functionality
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
                                                    >(context, listen: false)
                                                    .deleteListing(listing.id);
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
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'by ${listing.author}',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
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
              const Icon(Icons.calendar_today, size: 17, color: Colors.black38),
              const SizedBox(width: 6),
              Text(
                listing.createdAt.toString(),
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
