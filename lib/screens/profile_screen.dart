import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  Future<bool?> _confirmSignOut(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get(),
              builder: (ctx, snap) {
                final uData =
                    snap.data?.data() as Map<String, dynamic>? ?? {};

                final fullName = (uData['fullName'] as String?)?.trim();
                final displayName =
                    fullName?.isNotEmpty == true ? fullName! : (user.displayName ?? 'User');

                final phone = (uData['phone'] as String?)?.trim() ??
                    (uData['contact'] as String?)?.trim() ?? '';

                final initial = displayName.isNotEmpty
                    ? displayName[0].toUpperCase()
                    : 'U';

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const SizedBox(height: 20),

                    // ── Avatar + name ─────────────────────────────────
                    Center(
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: _kGreen,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        user.email ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 14),
                      ),
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
                        leading:
                            const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          final confirmed = await _confirmSignOut(context);
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
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500)),
    );
  }
}
