import 'package:flutter/material.dart';
import '../../models/book_listing.dart';
import 'package:intl/intl.dart';

class BookListingCard extends StatelessWidget {
  final BookListing listing;
  const BookListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat.yMMMd().format(listing.createdAt);
    String condText = listing.condition.name.replaceAll('LikeNew', 'Like New');
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // TODO: navigate to details
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  listing.coverUrl,
                  fit: BoxFit.cover,
                  height: 80,
                  width: 55,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      listing.author,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: condText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.pink,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: "   ",
                            style: const TextStyle(color: Colors.black54),
                          ),
                          WidgetSpan(
                            child: Icon(
                              Icons.calendar_today,
                              size: 13,
                              color: Colors.black45,
                            ),
                          ),
                          TextSpan(
                            text: ' $dateText',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
