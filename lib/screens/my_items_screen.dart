import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyItemsScreen extends StatelessWidget {
  const MyItemsScreen({super.key});

  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  Future<void> _deleteItem(
    BuildContext context,
    String docId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Item',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure you want to delete this item? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('items').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: _kGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: const Text('My Items'),
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('items')
                  .where('uid', isEqualTo: uid)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: _kGreen),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                }
                // Sort client-side descending by createdAt (avoids composite index)
                final docs = List.of(snap.data?.docs ?? [])
                  ..sort((a, b) {
                    final aTs =
                        (a.data() as Map<String, dynamic>)['createdAt'];
                    final bTs =
                        (b.data() as Map<String, dynamic>)['createdAt'];
                    if (aTs is! Timestamp || bTs is! Timestamp) return 0;
                    return bTs.toDate().compareTo(aTs.toDate());
                  });
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No items posted yet.',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15)),
                        SizedBox(height: 6),
                        Text(
                          'Go back to the home screen to post a lost\nor found item.',
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
                  separatorBuilder: (_, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final docId = docs[i].id;
                    return _MyItemCard(
                      data: data,
                      docId: docId,
                      onDelete: () =>
                          _deleteItem(context, docId),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _MyItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onDelete;

  const _MyItemCard({
    required this.data,
    required this.docId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLost = (data['type'] ?? '') == 'Lost';
    final imageUrl = data['imageUrl'] as String? ?? '';
    final status = data['status'] ?? 'active';
    final ts = data['createdAt'];
    String timeAgo = '';
    if (ts is Timestamp) {
      final diff = DateTime.now().difference(ts.toDate());
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours}h ago';
      } else {
        timeAgo = '${diff.inDays}d ago';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => _placeholder(),
                      )
                    : _placeholder(),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Type badge — top left
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isLost
                          ? Colors.red.shade600
                          : Colors.green.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['type'] ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                // Status badge — top right
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: status == 'active'
                          ? Colors.blue.shade600
                          : status == 'reunited'
                              ? const Color(0xFF7B3FA0)
                              : Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == 'active'
                          ? 'Active'
                          : status == 'reunited'
                              ? 'Reunited ✓'
                              : 'Resolved',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                // Time — bottom right over gradient
                if (timeAgo.isNotEmpty)
                  Positioned(
                    bottom: 8, right: 10,
                    child: Text(
                      timeAgo,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Untitled',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
                if ((data['category'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(data['category'],
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
                if ((data['location'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        data['location'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          // ── Action row ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                        context, '/item-detail',
                        arguments: docId),
                    icon: const Icon(Icons.visibility_outlined,
                        size: 16, color: Colors.grey),
                    label: const Text('View',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ),
                Container(
                    width: 1, height: 36, color: Colors.grey.shade100),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: Colors.red),
                    label: const Text('Delete',
                        style: TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 160,
        width: double.infinity,
        color: Colors.grey.shade100,
        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 40),
      );
}
