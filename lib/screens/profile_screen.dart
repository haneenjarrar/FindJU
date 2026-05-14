import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_item_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red.shade400)),
      );

  Future<void> _showEditProfile(
    BuildContext context,
    String uid,
    Map<String, dynamic> uData,
  ) async {
    final nameCtrl = TextEditingController(
        text: (uData['fullName'] as String?)?.trim() ?? '');
    final phoneCtrl = TextEditingController(
        text: (uData['phone'] as String?)?.trim() ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: StatefulBuilder(
            builder: (ctx, setInner) {
              bool saving = false;
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Edit Profile',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Full Name',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: _inputDec('Enter your full name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Phone (Optional)',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDec('+962 7X XXX XXXX'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final c = v
                            .trim()
                            .replaceAll(' ', '')
                            .replaceAll('-', '');
                        if (!RegExp(r'^(\+9627[789]\d{7}|07[789]\d{7})$')
                            .hasMatch(c)) {
                          return 'Enter a valid Jordanian number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    StatefulBuilder(
                      builder: (ctx2, setSaving) => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  setSaving(() => saving = true);
                                  try {
                                    final updates = <String, dynamic>{
                                      'fullName': nameCtrl.text.trim(),
                                    };
                                    final phone = phoneCtrl.text.trim();
                                    if (phone.isNotEmpty) {
                                      updates['phone'] = phone;
                                    }
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .update(updates);
                                    await FirebaseAuth.instance.currentUser
                                        ?.updateDisplayName(
                                            nameCtrl.text.trim());
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  } finally {
                                    setSaving(() => saving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Text('Save Changes',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<bool?> _confirmSignOut(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Sign Out',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (ctx, snap) {
                final uData =
                    snap.data?.data() as Map<String, dynamic>? ?? {};

                final fullName =
                    (uData['fullName'] as String?)?.trim();
                final displayName = fullName?.isNotEmpty == true
                    ? fullName!
                    : (user.displayName ?? 'User');
                final phone =
                    (uData['phone'] as String?)?.trim() ?? '';
                final studentId =
                    (uData['studentId'] as String?)?.trim() ?? '';
                final notifCategories = List<String>.from(
                    uData['notifCategories'] ?? []);
                final initial = displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : 'U';

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 20),

                    // ── Avatar ────────────────────────────────────────
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: _kGreen,
                            child: Text(initial,
                                style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          GestureDetector(
                            onTap: () => _showEditProfile(
                                context, user.uid, uData),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.edit,
                                  size: 14, color: _kGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(displayName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(user.email ?? '',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ),
                    const SizedBox(height: 32),

                    // ── Info card ─────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: displayName,
                          ),
                          const Divider(
                              height: 1, indent: 16, endIndent: 16),
                          _InfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email ?? '—',
                          ),
                          if (phone.isNotEmpty) ...[
                            const Divider(
                                height: 1, indent: 16, endIndent: 16),
                            _InfoTile(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: phone,
                            ),
                          ],
                          if (studentId.isNotEmpty) ...[
                            const Divider(
                                height: 1, indent: 16, endIndent: 16),
                            _InfoTile(
                              icon: Icons.badge_outlined,
                              label: 'Student ID',
                              value: studentId,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showEditProfile(context, user.uid, uData),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Edit Profile'),
                        style: TextButton.styleFrom(
                            foregroundColor: _kGreen),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ── Notification preferences ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notifications_outlined,
                                  size: 18, color: _kGreen),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Notify me when a new item is posted in:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: kCategories.map((cat) {
                              final active = notifCategories.contains(cat);
                              return GestureDetector(
                                onTap: () async {
                                  final updated = active
                                      ? notifCategories
                                          .where((c) => c != cat)
                                          .toList()
                                      : [...notifCategories, cat];
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .update({
                                    'notifCategories': updated,
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? _kGreen
                                        : Colors.grey.shade100,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: active
                                          ? _kGreen
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(cat,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: active
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: active
                                              ? FontWeight.w600
                                              : FontWeight.w400)),
                                ),
                              );
                            }).toList(),
                          ),
                          if (notifCategories.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Subscribed to ${notifCategories.length} ${notifCategories.length == 1 ? "category" : "categories"}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Sign out ──────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.logout,
                            color: Colors.red),
                        title: const Text('Sign Out',
                            style: TextStyle(color: Colors.red)),
                        onTap: () async {
                          final confirmed =
                              await _confirmSignOut(context);
                          if (confirmed == true && context.mounted) {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(
                                  context, '/welcome');
                            }
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _kGreen),
      title: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500)),
    );
  }
}
