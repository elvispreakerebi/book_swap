import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../models/book_listing.dart';
import 'listing_card.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.menu_book, color: Colors.pink, size: 50),
          SizedBox(height: 16),
          Text(
            'No books listed yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'New books added by users will appear here.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingsProvider = Provider.of<BookListingsProvider>(context);
    final listings = listingsProvider.listings;
    final isEmpty = listingsProvider.isEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Listings'), centerTitle: false),
      body: isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: listings.length,
              itemBuilder: (context, idx) =>
                  BookListingCard(listing: listings[idx]),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.black54,
        onTap: (idx) {
          setState(() => _selectedIndex = idx);
          // Handle navigation to different root screens here!
          switch (idx) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/my_listings');
              break;
            case 2:
              context.go('/chats');
              break;
            case 3:
              context.go('/settings');
              break;
          }
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
