import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'listing_card.dart';
import 'package:provider/provider.dart';
import '../../providers/book_listings_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../ui/app_bottom_nav.dart';

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
    final notificationsProvider = Provider.of<NotificationsProvider>(
      context,
      listen: true,
    );
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
      appBar: AppBar(
        title: const Text('Listings'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none),
                if (notificationsProvider.unreadCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '${notificationsProvider.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              // Show notifications in a modal bottom sheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                builder: (context) {
                  final notifications = notificationsProvider.notifications;
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 0,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: notifications.isEmpty
                                        ? null
                                        : () async {
                                            for (final n in notifications) {
                                              if (!n.read) {
                                                await notificationsProvider
                                                    .markAsRead(n.id);
                                              }
                                            }
                                            await notificationsProvider
                                                .fetchNotifications();
                                            (context as Element)
                                                .markNeedsBuild(); // force update
                                          },
                                    child: const Text('Mark all as read'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: notifications.isEmpty
                                        ? null
                                        : () async {
                                            final user = FirebaseAuth
                                                .instance
                                                .currentUser;
                                            if (user == null) return;
                                            final batch = FirebaseFirestore
                                                .instance
                                                .batch();
                                            final snap = await FirebaseFirestore
                                                .instance
                                                .collection('notifications')
                                                .where(
                                                  'userId',
                                                  isEqualTo: user.uid,
                                                )
                                                .get();
                                            for (final doc in snap.docs) {
                                              batch.delete(doc.reference);
                                            }
                                            await batch.commit();
                                            await notificationsProvider
                                                .fetchNotifications();
                                          },
                                    child: const Text(
                                      'Clear all',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          notifications.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Text(
                                    'No notifications yet.',
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: notifications.length,
                                    separatorBuilder: (c, i) => const Divider(),
                                    itemBuilder: (c, i) {
                                      final notif = notifications[i];
                                      return ListTile(
                                        leading: notif.read
                                            ? null
                                            : const Icon(
                                                Icons.brightness_1,
                                                size: 12,
                                                color: Colors.pink,
                                              ),
                                        title: Text(notif.title),
                                        subtitle: Text(notif.body),
                                        trailing:
                                            notif.type ==
                                                AppNotificationType.chatMsg
                                            ? const Icon(Icons.chat)
                                            : notif.type ==
                                                  AppNotificationType.offerMade
                                            ? const Icon(Icons.swap_horiz)
                                            : notif.type ==
                                                  AppNotificationType
                                                      .offerAccepted
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              )
                                            : notif.type ==
                                                  AppNotificationType
                                                      .offerRejected
                                            ? const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              )
                                            : null,
                                        onTap: () async {
                                          await notificationsProvider
                                              .markAsRead(notif.id);
                                          await notificationsProvider
                                              .fetchNotifications();
                                          (context as Element).markNeedsBuild();
                                          Navigator.pop(context); // close modal
                                          // Navigate as before
                                          if (notif.data != null &&
                                              notif.data!['listingId'] !=
                                                  null) {
                                            final listingId =
                                                notif.data!['listingId'];
                                            if (listingId is String &&
                                                listingId.isNotEmpty) {
                                              if (context.mounted)
                                                context.go(
                                                  '/listing/$listingId',
                                                );
                                            }
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
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
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
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
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}
