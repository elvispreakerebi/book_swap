import 'package:flutter/material.dart';
import '../models/book_listing.dart';

class BookListingsProvider with ChangeNotifier {
  final List<BookListing> _listings = [
    BookListing(
      id: '1',
      ownerId: 'owner1',
      title: 'Data Structures & Algorithms',
      author: 'V Dermon',
      condition: BookCondition.LikeNew,
      coverUrl: 'https://dummyimage.com/100x150/cccccc/000000&text=Book1',
      description: 'A classic textbook.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isActive: true,
    ),
    BookListing(
      id: '2',
      ownerId: 'owner2',
      title: 'Operating Systems',
      author: 'John Doe',
      condition: BookCondition.Used,
      coverUrl: 'https://dummyimage.com/100x150/cccccc/000000&text=Book2',
      description: 'Slightly used.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isActive: true,
    ),
  ];

  List<BookListing> get listings => List.unmodifiable(_listings);

  bool get isEmpty => _listings.isEmpty;

  // Placeholder: in the future, add methods for fetch/add/delete from Firestore.
}
