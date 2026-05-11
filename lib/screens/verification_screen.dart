import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  static const kGreen = Color.fromARGB(255, 41, 103, 43);

  Future<void> _checkVerification(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final verified = await auth.reloadAndCheckVerified();
    if (!context.mounted) return;

    if (verified) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Please check your inbox.'),
        ),
      );
    }
  }

  Future<void> _resend(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.resendVerificationEmail();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Verification email sent!'
            : (auth.error ?? 'Could not resend. Try again later.')),
        backgroundColor: success ? kGreen : Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        context.read<AuthProvider>().currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 41, 103, 43),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_unread_outlined,
                          color: kGreen, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verify your email',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We sent a verification link to\n$email\n\nPlease check your inbox and click the link to activate your account.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54, height: 1.6),
                    ),
                    const SizedBox(height: 36),

                    Consumer<AuthProvider>(
                      builder: (_, auth, _) => Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: auth.loading
                                  ? null
                                  : () => _checkVerification(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kGreen,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: auth.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      "I've verified my email",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: auth.loading
                                  ? null
                                  : () => _resend(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kGreen,
                                side:
                                    const BorderSide(color: kGreen, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Resend email',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
