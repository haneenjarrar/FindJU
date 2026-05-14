import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  String? _activeChatId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatId = ModalRoute.of(context)?.settings.arguments as String?;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (chatId != null && uid != null && chatId != _activeChatId) {
      _activeChatId = chatId;
      _markRead(chatId, uid);
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(
    String chatId,
    String uid,
    String displayName,
    List<String> participants,
  ) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      final otherUid = participants.firstWhere(
        (p) => p != uid,
        orElse: () => '',
      );
      final now = FieldValue.serverTimestamp();
      final batch = FirebaseFirestore.instance.batch();

      final msgRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'text': text,
        'senderId': uid,
        'senderName': displayName,
        'createdAt': now,
      });

      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(chatId);

      batch.update(chatRef, {
        'lastMessage': text,
        'lastMessageTime': now,
        'lastMessageSenderId': uid,
        'unreadCounts.$uid': 0,
        if (otherUid.isNotEmpty)
          'unreadCounts.$otherUid': FieldValue.increment(1),
      });

      await batch.commit();
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markRead(String chatId, String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({'unreadCounts.$uid': 0});
    } catch (_) {}
  }

  Future<void> _deleteChat(BuildContext context, String chatId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatId =
        ModalRoute.of(context)?.settings.arguments as String?;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (chatId == null || currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Chat not found')),
      );
    }

    final uid = currentUser.uid;
    final displayName = currentUser.displayName ??
        currentUser.email?.split('@').first ??
        'User';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .snapshots(),
      builder: (ctx, chatSnap) {
        final chatData =
            chatSnap.data?.data() as Map<String, dynamic>? ?? {};
        final participants =
            List<String>.from(chatData['participants'] ?? []);
        final otherUid = participants.firstWhere(
          (p) => p != uid,
          orElse: () => '',
        );
        final names = Map<String, dynamic>.from(
            chatData['participantNames'] ?? {});
        final otherName = (names[otherUid] as String?) ?? 'User';
        final itemTitle = (chatData['itemTitle'] as String?) ?? '';
        final itemId = (chatData['itemId'] as String?) ?? '';
        final itemType = (chatData['itemType'] as String?) ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: _kGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    otherName.isNotEmpty
                        ? otherName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(otherName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      if (itemTitle.isNotEmpty)
                        Text(
                          itemTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) {
                  if (v == 'delete') _deleteChat(context, chatId);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            color: Colors.red, size: 18),
                        SizedBox(width: 10),
                        Text('Delete chat',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Item reference card ───────────────────────────────
              if (itemTitle.isNotEmpty || itemId.isNotEmpty)
                GestureDetector(
                  onTap: itemId.isNotEmpty
                      ? () => Navigator.pushNamed(
                          context, '/item-detail',
                          arguments: itemId)
                      : null,
                  child: Container(
                    margin:
                        const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: itemType == 'Lost'
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: itemType == 'Lost'
                                ? Colors.red.shade600
                                : Colors.green.shade700,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemType.isNotEmpty
                                    ? '$itemType item'
                                    : 'Item',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey),
                              ),
                              Text(
                                itemTitle.isNotEmpty
                                    ? itemTitle
                                    : 'View item',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        if (itemId.isNotEmpty)
                          const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              // ── Messages ──────────────────────────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .collection('messages')
                      .orderBy('createdAt')
                      .snapshots(),
                  builder: (ctx, msgSnap) {
                    if (msgSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: _kGreen),
                      );
                    }

                    final messages = msgSnap.data?.docs ?? [];

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Say hello to $otherName!',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    _scrollToBottom();

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      itemCount: messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = messages[i].data()
                            as Map<String, dynamic>;
                        final isMe = msg['senderId'] == uid;
                        final text =
                            (msg['text'] as String?) ?? '';
                        final ts = msg['createdAt'];
                        String timeStr = '';
                        if (ts is Timestamp) {
                          final dt = ts.toDate();
                          final now = DateTime.now();
                          final h =
                              dt.hour.toString().padLeft(2, '0');
                          final m = dt.minute
                              .toString()
                              .padLeft(2, '0');
                          if (now.difference(dt).inHours < 24) {
                            timeStr = '$h:$m';
                          } else {
                            timeStr =
                                '${dt.month}/${dt.day}  $h:$m';
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: _kGreen
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    otherName.isNotEmpty
                                        ? otherName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                        color: _kGreen,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? _kGreen
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.only(
                                          topLeft:
                                              const Radius.circular(
                                                  16),
                                          topRight:
                                              const Radius.circular(
                                                  16),
                                          bottomLeft:
                                              Radius.circular(
                                                  isMe ? 16 : 4),
                                          bottomRight:
                                              Radius.circular(
                                                  isMe ? 4 : 16),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(
                                                    alpha: 0.06),
                                            blurRadius: 4,
                                            offset:
                                                const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      timeStr,
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMe)
                                const SizedBox(width: 6),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Input bar ─────────────────────────────────────────
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.fromLTRB(12, 10, 12, 16),
                child: SafeArea(
                  top: false,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          constraints:
                              const BoxConstraints(maxHeight: 120),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            textCapitalization:
                                TextCapitalization.sentences,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                  color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sending
                            ? null
                            : () => _send(chatId, uid, displayName,
                                participants),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                          ),
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
