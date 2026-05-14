import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_item_form.dart';

class EditItemSheet extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditItemSheet({super.key, required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final isLost = (data['type'] ?? '') == 'Lost';
    final accent = isLost
        ? const Color.fromARGB(255, 41, 103, 43)
        : const Color(0xFFF57C00);

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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Edit Post',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                    Icon(Icons.edit_outlined, color: accent, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      isLost ? 'Editing Lost Item' : 'Editing Found Item',
                      style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: _EditItemForm(docId: docId, initialData: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditItemForm extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const _EditItemForm({required this.docId, required this.initialData});

  @override
  State<_EditItemForm> createState() => _EditItemFormState();
}

class _EditItemFormState extends State<_EditItemForm> {
  static const _kGreen = Color.fromARGB(255, 41, 103, 43);

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _contactCtrl;
  late String _category;
  late String _location;
  String? _color;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.initialData['title'] as String? ?? '');
    _descCtrl = TextEditingController(
        text: widget.initialData['description'] as String? ?? '');
    _contactCtrl = TextEditingController(
        text: widget.initialData['contact'] as String? ?? '');

    final cat = widget.initialData['category'] as String? ?? '';
    _category = kCategories.contains(cat) ? cat : kCategories.first;

    final loc = widget.initialData['location'] as String? ?? '';
    _location = kLocations.contains(loc) ? loc : kLocations.first;

    final col = widget.initialData['color'] as String? ?? '';
    _color = (col.isNotEmpty && kColors.contains(col)) ? col : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.docId)
          .update({
        'title': _nameCtrl.text.trim(),
        'category': _category,
        'description': _descCtrl.text.trim(),
        'location': _location,
        'color': _color ?? '',
        'contact': _contactCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated successfully!'),
            backgroundColor: _kGreen,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      );

  @override
  Widget build(BuildContext context) {
    final isLost = (widget.initialData['type'] ?? '') == 'Lost';
    final accent = isLost ? _kGreen : const Color(0xFFF57C00);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Item Name'),
          TextFormField(
            controller: _nameCtrl,
            decoration: _inputDec('e.g., Black Laptop Bag'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Item name is required'
                : null,
          ),

          _label('Category'),
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: _inputDec(''),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            style:
                const TextStyle(fontSize: 13, color: Colors.black87),
            items: kCategories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),

          _label('Description'),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: _inputDec('Detailed description...'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Description is required'
                : null,
          ),

          _label('Color (Optional)'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kColors.map((name) {
              final val = kColorValues[name]!;
              final active = _color == name;
              return GestureDetector(
                onTap: () =>
                    setState(() => _color = active ? null : name),
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
          DropdownButtonFormField<String>(
            initialValue: _location,
            isExpanded: true,
            decoration: _inputDec(''),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
            style:
                const TextStyle(fontSize: 13, color: Colors.black87),
            items: kLocations
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _location = v!),
          ),

          _label('Contact Information'),
          TextFormField(
            controller: _contactCtrl,
            decoration: _inputDec('+962 7X XXX XXXX'),
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Contact info is required';
              }
              final c = v.trim().replaceAll(' ', '').replaceAll('-', '');
              if (!RegExp(r'^(\+9627[789]\d{7}|07[789]\d{7})$')
                  .hasMatch(c)) {
                return 'Enter a valid Jordanian number (+962 7X XXX XXXX)';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600)),
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
