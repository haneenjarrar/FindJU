import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _agreeToTerms = false;
  bool _passVisible = false;
  bool _confirmPassVisible = false;

  static const kGreen = Color.fromARGB(255, 41, 103, 43);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _idCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      studentId: _idCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, '/verify');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGreen, width: 1.5),
        ),
      );

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: const BoxDecoration(
                color: kGreen,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Expanded(
                  child: Text('Terms of Service',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: Colors.white70, size: 20),
                ),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _TermsSection(
                      title: '1. Eligibility',
                      body:
                          'FindJU is exclusively available to current students, faculty, and staff of the University of Jordan. You must have a valid university email address to register.',
                    ),
                    _TermsSection(
                      title: '2. Acceptable Use',
                      body:
                          'You agree to use FindJU solely for reporting genuinely lost or found items on the University of Jordan campus. You must not post false, misleading, or fraudulent item reports. Misuse of the platform may result in permanent account suspension.',
                    ),
                    _TermsSection(
                      title: '3. User Responsibilities',
                      body:
                          'You are solely responsible for the accuracy of any item you post. When reporting a found item, you agree to make a genuine effort to return it to its rightful owner. Do not demand payment or favors in exchange for returning found items.',
                    ),
                    _TermsSection(
                      title: '4. Contact Information',
                      body:
                          'By providing a phone number, you consent to other users contacting you regarding a specific item. Your contact details are visible only to registered university users.',
                    ),
                    _TermsSection(
                      title: '5. Limitation of Liability',
                      body:
                          'FindJU and the University of Jordan are not responsible for any loss, damage, or failure to recover items listed on the platform. The app serves as a communication tool only.',
                    ),
                    _TermsSection(
                      title: '6. Account Termination',
                      body:
                          'We reserve the right to suspend or permanently delete accounts that violate these terms without prior notice.',
                    ),
                    _TermsSection(
                      title: '7. Changes to Terms',
                      body:
                          'These terms may be updated periodically. Continued use of FindJU after changes are posted constitutes your acceptance of the revised terms.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('I Understand',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              decoration: const BoxDecoration(
                color: kGreen,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                const Expanded(
                  child: Text('Privacy Policy',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: Colors.white70, size: 20),
                ),
              ]),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _TermsSection(
                      title: '1. Information We Collect',
                      body:
                          'We collect your full name, university email address, student/staff ID, and any item details you choose to post, including photos, descriptions, and location.',
                    ),
                    _TermsSection(
                      title: '2. How We Use Your Information',
                      body:
                          'Your information is used solely to operate the FindJU lost-and-found platform — matching lost items with finders, enabling communication between users, and maintaining account security.',
                    ),
                    _TermsSection(
                      title: '3. Data Storage',
                      body:
                          'Your data is stored securely on Google Firebase servers. Item images are hosted on third-party image storage (ImgBB). We apply industry-standard security practices to protect your data.',
                    ),
                    _TermsSection(
                      title: '4. Visibility of Your Data',
                      body:
                          'Your name and contact number are visible to other registered FindJU users on item posts you create. Your student ID and email are never displayed publicly.',
                    ),
                    _TermsSection(
                      title: '5. Data Retention',
                      body:
                          'Your account data is retained for as long as your account is active. Item posts are retained until you delete them or your account is removed. You may request deletion of your data at any time.',
                    ),
                    _TermsSection(
                      title: '6. Third-Party Services',
                      body:
                          'FindJU uses Google Firebase (Authentication, Firestore) and ImgBB for image hosting. These services have their own privacy policies which govern their data handling.',
                    ),
                    _TermsSection(
                      title: '7. Contact Us',
                      body:
                          'For any privacy concerns or data deletion requests, please contact the FindJU team through the University of Jordan IT department.',
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Got It',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 41, 103, 43),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, top: 8),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/welcome'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search,
                              color: kGreen, size: 36),
                        ),
                        const SizedBox(height: 12),
                        const Text('FindJU',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        const Text('University of Jordan Lost & Found',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                ],
              ),

              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Full Name'),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _inputDec(
                            'Enter your full name', Icons.person_outline),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      _label('Email'),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: _inputDec(
                            'Enter your email', Icons.mail_outline),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 14),

                      _label('Student/Staff ID'),
                      TextFormField(
                        controller: _idCtrl,
                        decoration: _inputDec(
                            'Enter your 7-digit ID', Icons.badge_outlined),
                        keyboardType: TextInputType.number,
                        validator: Validators.studentId,
                      ),
                      const SizedBox(height: 14),

                      _label('Password'),
                      StatefulBuilder(
                        builder: (_, setInner) => TextFormField(
                          controller: _passCtrl,
                          obscureText: !_passVisible,
                          decoration: _inputDec(
                                  'Enter your password', Icons.lock_outline)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _passVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                  size: 20),
                              onPressed: () =>
                                  setInner(() => _passVisible = !_passVisible),
                            ),
                          ),
                          validator: Validators.strongPassword,
                        ),
                      ),
                      const SizedBox(height: 14),

                      _label('Confirm Password'),
                      StatefulBuilder(
                        builder: (_, setInner) => TextFormField(
                          controller: _confirmPassCtrl,
                          obscureText: !_confirmPassVisible,
                          decoration: _inputDec(
                                  'Confirm your password', Icons.lock_outline)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _confirmPassVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.grey,
                                  size: 20),
                              onPressed: () => setInner(() =>
                                  _confirmPassVisible = !_confirmPassVisible),
                            ),
                          ),
                          validator: (v) =>
                              Validators.confirmPassword(_passCtrl.text)(v),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _agreeToTerms,
                              activeColor: kGreen,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              onChanged: (v) =>
                                  setState(() => _agreeToTerms = v ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text('I agree to the ',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87)),
                                GestureDetector(
                                  onTap: _showTermsDialog,
                                  child: const Text(
                                    'Terms of Service',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: kGreen,
                                      fontWeight: FontWeight.w700,
                                      decoration:
                                          TextDecoration.underline,
                                      decorationColor: kGreen,
                                    ),
                                  ),
                                ),
                                const Text(' and ',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87)),
                                GestureDetector(
                                  onTap: _showPrivacyDialog,
                                  child: const Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: kGreen,
                                      fontWeight: FontWeight.w700,
                                      decoration:
                                          TextDecoration.underline,
                                      decorationColor: kGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Consumer<AuthProvider>(
                        builder: (_, auth, _) => SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                (_agreeToTerms && !auth.loading) ? _signUp : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: auth.loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Create Account',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/login'),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 13),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: TextStyle(
                                      color: kGreen,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String body;

  const _TermsSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black54, height: 1.5)),
        ],
      ),
    );
  }
}
