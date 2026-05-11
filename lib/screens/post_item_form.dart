import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _imgbbApiKey = '943ebab802a5c68c9068270be579ca02';

const _kGreen  = Color.fromARGB(255, 41, 103, 43);
const _kOrange = Color(0xFFF57C00);

const kCategories = [
  'Electronics', 'Documents', 'Keys', 'Accessories',
  'Clothing', 'Books', 'Wallet / Purse', 'ID Card',
  'Water Bottle', 'Glasses', 'Bag / Backpack', 'Other',
];

const kLocations = [
  'King Abdullah II Library',
  'Faculty of Engineering',
  'Faculty of Science',
  'Faculty of Arts',
  'Faculty of Law',
  'Faculty of Business',
  'Faculty of Medicine',
  'Faculty of Pharmacy',
  'Faculty of Dentistry',
  'Faculty of Nursing',
  'Faculty of Information Technology',
  'Faculty of Agriculture',
  'Faculty of Physical Education',
  'Faculty of Rehabilitation Sciences',
  'Faculty of Foreign Languages',
  'Faculty of Educational Sciences',
  'Faculty of Sharia',
  'Faculty of Graduate Studies',
  'Central Cafeteria',
  'Sports Complex',
  'Student Center',
  'University Mosque',
  'University Hospital',
  'Administration Building',
  'Parking Lot A',
  'Parking Lot B',
  'Parking Lot C',
  'Parking Lot D',
  'Parking Lot E',
  'Main Gate Area',
  'Other',
];

const kColors = [
  'Red', 'Blue', 'Green', 'Black', 'White',
  'Yellow', 'Orange', 'Purple', 'Brown', 'Grey', 'Pink', 'Other',
];

const kColorValues = <String, Color>{
  'Red':    Color(0xFFE53935),
  'Blue':   Color(0xFF1E88E5),
  'Green':  Color(0xFF43A047),
  'Black':  Color(0xFF212121),
  'White':  Color(0xFFF5F5F5),
  'Yellow': Color(0xFFFDD835),
  'Orange': Color(0xFFFF8F00),
  'Purple': Color(0xFF8E24AA),
  'Brown':  Color(0xFF6D4C41),
  'Grey':   Color(0xFF757575),
  'Pink':   Color(0xFFE91E63),
  'Other':  Color(0xFF9E9E9E),
};

// ── Bottom sheet wrapper (used from homepage) ─────────────────────────────────
class PostItemSheet extends StatelessWidget {
  final String type;
  const PostItemSheet({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isLost = type == 'Lost';
    final accent = isLost ? _kGreen : _kOrange;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Drag handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Post Item',
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
            Divider(height: 16, color: Colors.grey.shade200),
            // Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isLost
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: accent, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      isLost ? 'Reporting a Lost Item' : 'Reporting a Found Item',
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Scrollable form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: PostItemForm(type: type),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dummy route screen (needed for main.dart routes) ─────────────────────────
class PostItemScreen extends StatelessWidget {
  final String type;
  const PostItemScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    // Immediately show the sheet and pop this transparent page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PostItemSheet(type: type),
      ).then((_) { if (context.mounted) Navigator.pop(context); });
    });
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}

// ── The actual form ───────────────────────────────────────────────────────────
class PostItemForm extends StatefulWidget {
  final String type;
  const PostItemForm({super.key, required this.type});

  @override
  State<PostItemForm> createState() => _PostItemFormState();
}

class _PostItemFormState extends State<PostItemForm> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _contactCtrl = TextEditingController();

  String    _category = kCategories.first;
  String    _location = kLocations.first;
  String?   _color;
  DateTime? _date;
  final List<XFile> _images = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kGreen,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickImages() async {
    if (_images.length >= 5) {
      _showSnack('Maximum 5 photos allowed.');
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: _kGreen, size: 20),
              ),
              title: const Text('Take a Photo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Open camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _kGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: _kGreen, size: 20),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Select up to ${5} photos'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    if (source == ImageSource.camera) {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
      );
      if (picked != null && mounted) {
        setState(() => _images.add(picked));
      }
    } else {
      final picked =
          await ImagePicker().pickMultiImage(imageQuality: 75);
      if (picked.isEmpty || !mounted) return;
      setState(() => _images.addAll(picked.take(5 - _images.length)));
    }
  }

  void _removeImage(int i) => setState(() => _images.removeAt(i));

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (final image in _images) {
      try {
        final bytes = await File(image.path).readAsBytes();
        final b64 = base64Encode(bytes);
        final res = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {'key': _imgbbApiKey, 'image': b64},
        );
        if (res.statusCode == 200) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          if (body['success'] == true) {
            urls.add((body['data'] as Map)['url'] as String);
          }
        }
      } catch (_) {}
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) { _showSnack('Please select a date.'); return; }

    setState(() => _isSubmitting = true);
    try {
      final uid    = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance.collection('items').doc();

      List<String> urls = [];
      if (_images.isNotEmpty) {
        urls = await _uploadImages();
      }

      await docRef.set({
        'type':        widget.type,
        'title':       _nameCtrl.text.trim(),
        'category':    _category,
        'description': _descCtrl.text.trim(),
        'location':    _location,
        'color':       _color ?? '',
        'date':        Timestamp.fromDate(_date!),
        'imageUrls':   urls,
        'imageUrl':    urls.isNotEmpty ? urls.first : '',
        'contact':     _contactCtrl.text.trim(),
        'uid':         uid,
        'status':      'active',
        'createdAt':   FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnack('Item posted successfully!', success: true);
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      _showSnack('Failed to save item (${e.code}): ${e.message}');
    } catch (e) {
      _showSnack('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: success ? _kGreen : Colors.red.shade600,
      ));

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      );

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _inputDec(''),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      );

  @override
  Widget build(BuildContext context) {
    final isLost = widget.type == 'Lost';
    final accent = isLost ? _kGreen : _kOrange;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _label('Item Name'),
          TextFormField(
            controller: _nameCtrl,
            decoration: _inputDec('e.g., Black Laptop Bag'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Item name is required' : null,
          ),

          _label('Category'),
          _dropdown(
            value: _category,
            items: kCategories,
            onChanged: (v) => setState(() => _category = v!),
          ),

          _label('Description'),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: _inputDec(
                'Provide detailed description including color, brand, distinctive features...'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Description is required' : null,
          ),

          _label('Color (Optional)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kColors.map((name) {
              final val = kColorValues[name]!;
              final active = _color == name;
              return GestureDetector(
                onTap: () => setState(() => _color = active ? null : name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? val.withValues(alpha: 0.18)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? val : Colors.grey.shade300,
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: val,
                          shape: BoxShape.circle,
                          border: name == 'White'
                              ? Border.all(color: Colors.grey.shade300)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(name,
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          _label('Location'),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Where was it lost/found?',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ]),
          const SizedBox(height: 6),
          _dropdown(
            value: _location,
            items: kLocations,
            onChanged: (v) => setState(() => _location = v!),
          ),

          _label('Date'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  _date == null
                      ? 'mm/dd/yyyy'
                      : DateFormat('MM/dd/yyyy').format(_date!),
                  style: TextStyle(
                      fontSize: 13,
                      color: _date == null ? Colors.grey : Colors.black87),
                ),
              ]),
            ),
          ),

          _label('Photos (up to 5) — Optional'),
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 22, color: Colors.grey.shade500),
                    const SizedBox(width: 10),
                    Icon(Icons.photo_library_outlined,
                        size: 22, color: Colors.grey.shade500),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Take a photo or choose from gallery',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 2),
                const Text('PNG, JPG · up to 5 photos',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
          ),

          if (_images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (_, i) => Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_images[i].path),
                        width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => _removeImage(i),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],

          _label('Contact Information'),
          TextFormField(
            controller: _contactCtrl,
            decoration: _inputDec('+962 7X XXX XXXX'),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Contact info is required';
              final cleaned = v.trim().replaceAll(' ', '').replaceAll('-', '');
              final valid = RegExp(r'^(\+9627[789]\d{7}|07[789]\d{7})$');
              if (!valid.hasMatch(cleaned)) {
                return 'Enter a valid Jordanian number (+962 7X XXX XXXX)';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Colors.black54, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Post Item',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}