import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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

  @override
  void initState() {
    super.initState();
    // Listen for real-time Firestore updates.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final listingsProvider = Provider.of<BookListingsProvider>(
        context,
        listen: false,
      );
      listingsProvider.startListening();
    });
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
    // Show deletion success snackbar if routed from details page with extra data
    final extra = GoRouterState.of(context).extra;
    if (extra is Map && extra['deleted'] == true) {
      final title = extra['title'] ?? 'Listing';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title deleted successfully!'),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Listings'), centerTitle: false),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        onPressed: () => context.go('/post_book'),
        child: const Icon(Icons.add, size: 31, color: Colors.white),
      ),
      body: isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: listings.length,
              itemBuilder: (context, idx) => BookListingCard(
                listing: listings[idx],
                onTap: () {
                  final id = listings[idx].id;
                  print('BookListingCard tap: Navigating to /listing/$id');
                  if (id.isNotEmpty) context.push('/listing/$id');
                },
              ),
              separatorBuilder: (context, idx) => const Divider(
                height: 1,
                color: Color(0xFFEAEAEA),
                thickness: 1.2,
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.black54,
        onTap: (idx) {
          setState(() => _selectedIndex = idx);
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
