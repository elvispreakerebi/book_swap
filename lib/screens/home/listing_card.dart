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

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  color: Colors.grey[200],
                  width: 60,
                  height: 85,
                  child: Image.network(
                    listing.coverUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
