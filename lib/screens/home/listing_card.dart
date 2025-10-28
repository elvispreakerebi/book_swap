import 'package:flutter/material.dart';
import '../../models/book_listing.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookListingCard extends StatelessWidget {
  final BookListing listing;
  final void Function()? onTap;
  const BookListingCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat.yMMMd().format(listing.createdAt);
    String condText = listing.condition.name.replaceAll('LikeNew', 'Like New');

    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user != null && user.uid == listing.ownerId;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 15),
                child: SizedBox(
                  width: 60, // fixed width for image/placeholder area
                  height: 85, // fixed height for image/placeholder area
                  child: (listing.coverUrl.isEmpty)
                      ? Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            size: 30,
                            color: Colors.grey,
                          ),
                        )
                      : AspectRatio(
                          aspectRatio: 0.72,
                          child: Image.network(
                            listing.coverUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: Colors.black,
                          height: 1.09,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        listing.author,
                        style: const TextStyle(
                          fontSize: 15.2,
                          color: Colors.black87,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        condText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.3,
                          color: Colors.black,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 15,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateText,
                            style: const TextStyle(
                              fontSize: 14.2,
                              color: Colors.black54,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Builder(
                        builder: (context) {
                          // Don't render for legacy/corrupt listings
                          if (listing.ownerId.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          if (isOwner) {
                            return const Text(
                              'You own this',
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.w500,
                                fontSize: 13.7,
                              ),
                            );
                          }
                          // Safe Firestore lookup (never empty)
                          return FutureBuilder<
                            DocumentSnapshot<Map<String, dynamic>>
                          >(
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
                                    fontSize: 13.7,
                                  ),
                                );
                              }
                              final data = snapshot.data!.data()!;
                              final displayName =
                                  (data['displayName'] as String?)?.trim();
                              return Text(
                                'Owner: ${displayName != null && displayName.isNotEmpty ? displayName : 'Unknown User'}',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.7,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
