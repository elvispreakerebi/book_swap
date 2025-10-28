import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../models/book_listing.dart';
import 'listing_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Placeholder listings
  List<BookListing> listings = [
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

  @override
  void didChangeDependencies() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Listings'), centerTitle: false),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: listings.length,
        itemBuilder: (context, idx) => BookListingCard(listing: listings[idx]),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.black54,
        onTap: (idx) {
          setState(() => _selectedIndex = idx);
          // TODO: route to other screens here
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'My listings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
