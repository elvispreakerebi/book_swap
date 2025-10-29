import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/book_listings_provider.dart';
import '../home/listing_card.dart';
import 'package:go_router/go_router.dart';
import '../ui/app_bottom_nav.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listingsProvider = Provider.of<BookListingsProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final myListings = listingsProvider.listings
        .where((l) => l.ownerId == user?.uid)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: myListings.isEmpty
          ? const Center(child: Text('You have not posted any listings yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: myListings.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: Color(0xFFEAEAEA),
                thickness: 1.2,
              ),
              itemBuilder: (context, idx) => BookListingCard(
                listing: myListings[idx],
                onTap: () {
                  final id = myListings[idx].id;
                  if (id.isNotEmpty) context.push('/listing/$id');
                },
              ),
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (idx) {
          switch (idx) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/my_listings');
              break;
            case 2:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}
