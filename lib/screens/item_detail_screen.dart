import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  static const _kGreen = Color.fromARGB(255, 41, 103, 43);
  int _selectedImage = 0;
  bool _creatingChat = false;

  // ── Mark as Reunited ──────────────────────────────────────────────────────
  Future<void> _markReunited(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as Reunited?'),
        content: const Text('This will mark the item as successfully reunited.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await FirebaseFirestore.instance
        .collection('items')
        .doc(docId)
        .update({'status': 'reunited'});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item marked as reunited!'),
          backgroundColor: _kGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ── Open or create chat ───────────────────────────────────────────────────
  Future<void> _openOrCreateChat(
    String posterUid,
    Map<String, dynamic> itemData,
    String docId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;

    if (currentUser.uid == posterUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message yourself")),
      );
      return;
    }

    setState(() => _creatingChat = true);
    try {
      final uid = currentUser.uid;
      final displayName = (currentUser.displayName?.trim().isNotEmpty == true
              ? currentUser.displayName!
              : null) ??
          currentUser.email?.split('@').first ??
          'User';

      final ids = [uid, posterUid]..sort();
      final chatId = '${ids[0]}_${ids[1]}';
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        String posterName = 'User';
        try {
          final pd = await FirebaseFirestore.instance
              .collection('users')
              .doc(posterUid)
              .get();
          final d = pd.data();
          posterName = (d?['fullName'] as String?)?.trim().isNotEmpty == true
              ? d!['fullName'] as String
              : (d?['displayName'] as String?) ?? 'User';
        } catch (_) {}

        await chatRef.set({
          'participants': [uid, posterUid],
          'participantNames': {uid: displayName, posterUid: posterName},
          'itemId': docId,
          'itemTitle': itemData['title'] ?? 'Untitled',
          'itemType': itemData['type'] ?? '',
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'unreadCounts': {uid: 0, posterUid: 0},
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await chatRef.update({
          'itemId': docId,
          'itemTitle': itemData['title'] ?? 'Untitled',
          'itemType': itemData['type'] ?? '',
        });
      }

      if (mounted) {
        Navigator.pushNamed(context, '/chat', arguments: chatId);
      }
    } finally {
      if (mounted) setState(() => _creatingChat = false);
    }
  }

  // ── Flag item ─────────────────────────────────────────────────────────────
  Future<void> _flagItem(String docId) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'itemId':    docId,
      'reportedBy': FirebaseAuth.instance.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item reported. Thank you!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docId = ModalRoute.of(context)?.settings.arguments as String?;

    if (docId == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _kGreen,
          foregroundColor: Colors.white,
          title: const Text('Item Details'),
          elevation: 0,
        ),
        body: const Center(child: Text('Item not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('items').doc(docId).get(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kGreen));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Item not found'));
          }

          final data    = snap.data!.data() as Map<String, dynamic>;
          final isLost  = (data['type'] ?? '') == 'Lost';
          final images  = List<String>.from(data['imageUrls'] ?? []);
          if (images.isEmpty && (data['imageUrl'] ?? '').isNotEmpty) {
            images.add(data['imageUrl']);
          }

          // Date formatting
          String dateStr = '';
          final ts = data['date'] ?? data['createdAt'];
          if (ts is Timestamp) {
            dateStr = DateFormat('MMM d, yyyy').format(ts.toDate());
          }

          final posterUid = data['uid'] ?? '';

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Text('Item Details',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 20, color: Colors.grey.shade200),

                  // ── Main image ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: images.isNotEmpty
                          ? Image.network(
                              images[_selectedImage],
                              width: double.infinity,
                              height: 210,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _placeholder(210),
                            )
                          : _placeholder(210),
                    ),
                  ),

                  // ── Thumbnail strip ────────────────────────────────────
                  if (images.length > 1) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: List.generate(
                          images.length > 4 ? 4 : images.length,
                          (i) => GestureDetector(
                            onTap: () => setState(() => _selectedImage = i),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedImage == i
                                      ? _kGreen
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.network(
                                  images[i],
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _placeholder(70),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Show 3 empty thumbnails like the mockup when no extra images
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: List.generate(3, (_) => Container(
                          width: 70, height: 70,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )),
                      ),
                    ),
                  ],

                  // ── Title + badge ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? 'Untitled',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isLost
                                ? Colors.red.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isLost ? 'Lost Item' : 'Found Item',
                            style: TextStyle(
                              color: isLost
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Category / Location / Date ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        if ((data['category'] ?? '').isNotEmpty)
                          _InfoRow(
                            icon: Icons.sell_outlined,
                            label: 'Category',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(data['category'],
                                  style: TextStyle(
                                      color: Colors.orange.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        if ((data['location'] ?? '').isNotEmpty)
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: data['location'],
                          ),
                        if (dateStr.isNotEmpty)
                          _InfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date',
                            value: dateStr,
                          ),
                      ],
                    ),
                  ),

                  // ── Description ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87)),
                        const SizedBox(height: 8),
                        Text(data['description'] ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.6)),
                      ],
                    ),
                  ),

                  // ── Posted By ──────────────────────────────────────────
                  if (posterUid.isNotEmpty)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(posterUid)
                          .get(),
                      builder: (ctx, userSnap) {
                        final uData = userSnap.data?.data()
                            as Map<String, dynamic>?;
                        final name = (uData?['fullName'] as String?)
                            ?.trim().isNotEmpty == true
                            ? uData!['fullName'] as String
                            : (uData?['displayName'] as String?) ?? 'Unknown';
                        final role =
                            (uData?['role'] ?? uData?['department'] ?? '') as String;
                        final initials = name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'U';

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Posted By',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87)),
                                const SizedBox(height: 10),
                                Row(children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: _kGreen,
                                    child: Text(initials,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16)),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87)),
                                      if (role.isNotEmpty)
                                        Text(role,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54)),
                                    ],
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // ── Message + Flag buttons ────────────────────────────
                  if (posterUid != FirebaseAuth.instance.currentUser?.uid)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _creatingChat || posterUid.isEmpty
                              ? null
                              : () => _openOrCreateChat(
                                    posterUid, data, docId),
                          icon: _creatingChat
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(Icons.chat_bubble_outline,
                                  size: 16, color: Colors.white),
                          label: const Text('Message Poster',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => _flagItem(docId),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.flag_outlined,
                            color: Colors.black54, size: 20),
                      ),
                    ]),
                  ),

                  // ── Reunited banner / Mark as Reunited ────────────────
                  if (data['status'] == 'reunited')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B3FA0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF7B3FA0).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF7B3FA0), size: 20),
                            SizedBox(width: 8),
                            Text('This item has been reunited!',
                                style: TextStyle(
                                    color: Color(0xFF7B3FA0),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    )
                  else if (posterUid == FirebaseAuth.instance.currentUser?.uid)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _markReunited(docId),
                          icon: const Icon(Icons.check_circle_outline,
                              size: 18, color: Colors.white),
                          label: const Text('Mark as Reunited',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),

                  // ── Similar Items ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: const Text('Similar Items',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('items')
                        .where('category', isEqualTo: data['category'])
                        .limit(10)
                        .snapshots(),
                    builder: (ctx, simSnap) {
                      final simDocs = (simSnap.data?.docs ?? [])
                          .where((d) {
                            if (d.id == docId) return false;
                            final sd = d.data() as Map<String, dynamic>;
                            return sd['type'] == data['type'];
                          })
                          .take(3)
                          .toList();

                      return SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: simDocs.isEmpty ? 3 : simDocs.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            if (simDocs.isEmpty) {
                              return Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            }
                            final sd = simDocs[i].data()
                                as Map<String, dynamic>;
                            final sImg = (sd['imageUrls'] as List?)
                                    ?.firstOrNull ??
                                sd['imageUrl'] ?? '';
                            final sTitle = sd['title'] ?? '';
                            final sTs = sd['createdAt'];
                            String sDate = '';
                            if (sTs is Timestamp) {
                              sDate = DateFormat('MMM d, yyyy')
                                  .format(sTs.toDate());
                            }
                            return GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ItemDetailScreen(),
                                  settings: RouteSettings(
                                      arguments: simDocs[i].id),
                                ),
                              ),
                              child: SizedBox(
                                width: 90,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      child: sImg.isNotEmpty
                                          ? Image.network(sImg,
                                              width: 90,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _placeholder(80))
                                          : _placeholder(80),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(sTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87)),
                                    Text(sDate,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder(double h) => Container(
        width: double.infinity,
        height: h,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image_outlined, color: Colors.grey, size: 36),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? child;

  const _InfoRow({required this.icon, required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color.fromARGB(255, 41, 103, 43)),
          const SizedBox(width: 10),
          Text('$label:  ',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          ?child,
          if (value != null)
            Expanded(
              child: Text(value!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ),
        ],
      ),
    );
  }
}