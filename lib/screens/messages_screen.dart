import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  Future<void> _deleteChat(BuildContext context, String chatId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Conversation',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'This will permanently delete all messages in this conversation.'),
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
      final db = FirebaseFirestore.instance;
      var msgs = await db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      while (msgs.docs.isNotEmpty) {
        final batch = db.batch();
        for (final d in msgs.docs.take(400)) {
          batch.delete(d.reference);
        }
        await batch.commit();
        if (msgs.docs.length <= 400) break;
        msgs = await db
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();
      }
      await db.collection('chats').doc(chatId).delete();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
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
        title: const Text('Messages'),
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: uid)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kGreen),
                  );
                }

                final docs = List.of(snap.data?.docs ?? [])
                  ..sort((a, b) {
                    final aTs = (a.data() as Map<String, dynamic>)['lastMessageTime'];
                    final bTs = (b.data() as Map<String, dynamic>)['lastMessageTime'];
                    if (aTs is! Timestamp || bTs is! Timestamp) return 0;
                    return bTs.compareTo(aTs);
                  });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No messages yet',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap "Message Poster" on any item\nto start a conversation.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final chatId = docs[i].id;
                    final participants =
                        List<String>.from(data['participants'] ?? []);
                    final otherUid = participants.firstWhere(
                        (p) => p != uid,
                        orElse: () => '');
                    final names = Map<String, dynamic>.from(
                        data['participantNames'] ?? {});
                    final otherName =
                        (names[otherUid] as String?) ?? 'User';
                    final unreadCounts = Map<String, dynamic>.from(
                        data['unreadCounts'] ?? {});
                    final unread =
                        (unreadCounts[uid] as num?)?.toInt() ?? 0;
                    final lastMsg =
                        (data['lastMessage'] as String?) ?? '';
                    final lastTs = data['lastMessageTime'];
                    String timeStr = '';
                    if (lastTs is Timestamp) {
                      final diff =
                          DateTime.now().difference(lastTs.toDate());
                      if (diff.inMinutes < 60) {
                        timeStr = '${diff.inMinutes}m';
                      } else if (diff.inHours < 24) {
                        timeStr = '${diff.inHours}h';
                      } else {
                        timeStr = '${diff.inDays}d';
                      }
                    }

                    return _ChatTile(
                      chatId: chatId,
                      otherName: otherName,
                      itemTitle:
                          (data['itemTitle'] as String?) ?? '',
                      lastMsg: lastMsg,
                      timeStr: timeStr,
                      unread: unread,
                      onLongPress: () =>
                          _deleteChat(context, chatId),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId, otherName, itemTitle, lastMsg, timeStr;
  final int unread;
  final VoidCallback? onLongPress;

  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  const _ChatTile({
    required this.chatId,
    required this.otherName,
    required this.itemTitle,
    required this.lastMsg,
    required this.timeStr,
    required this.unread,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/chat', arguments: chatId),
      onLongPress: onLongPress,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _kGreen.withValues(alpha: 0.12),
              child: Text(
                otherName.isNotEmpty
                    ? otherName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: _kGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        otherName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: unread > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(timeStr,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                  ]),
                  if (itemTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      itemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: _kGreen,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(children: [
                    Expanded(
                      child: Text(
                        lastMsg.isEmpty
                            ? 'New conversation'
                            : lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: unread > 0
                              ? Colors.black87
                              : Colors.grey,
                          fontWeight: unread > 0
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _kGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
