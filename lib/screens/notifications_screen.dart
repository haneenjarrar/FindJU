import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  @override
  void initState() {
    super.initState();
    _markAllRead();
  }

  Future<void> _markAllRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final unread = await FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .get();
      if (unread.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('uid', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kGreen),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No notifications yet',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text(
                          'Subscribe to categories in your profile\nto get notified about new items.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final isRead = data['read'] == true;
                    final message =
                        (data['message'] as String?) ?? '';
                    final itemId =
                        (data['itemId'] as String?) ?? '';
                    final type =
                        (data['type'] as String?) ?? 'new_item';

                    IconData icon;
                    Color iconColor;
                    switch (type) {
                      case 'message':
                        icon = Icons.chat_bubble_outline;
                        iconColor = Colors.blue.shade600;
                        break;
                      case 'reunited':
                        icon = Icons.check_circle_outline;
                        iconColor = const Color(0xFF7B3FA0);
                        break;
                      default:
                        icon = Icons.inventory_2_outlined;
                        iconColor = _kGreen;
                    }

                    return GestureDetector(
                      onTap: itemId.isNotEmpty
                          ? () => Navigator.pushNamed(
                              context, '/item-detail',
                              arguments: itemId)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.white
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: isRead
                              ? null
                              : Border.all(
                                  color: _kGreen.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    iconColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon,
                                  color: iconColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: isRead
                                          ? FontWeight.w400
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  if (itemId.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    const Text('Tap to view item →',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: _kGreen)),
                                  ],
                                ],
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(
                                    top: 4, left: 6),
                                decoration: const BoxDecoration(
                                  color: _kGreen,
                                  shape: BoxShape.circle,
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
    );
  }
}
