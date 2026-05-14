import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'post_item_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const kGreen = Color.fromARGB(255, 41, 103, 43);
  static const kOrange = Color(0xFFF57C00);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();

  String _typeFilter = 'All';
  String _searchQuery = '';
  String? _categoryFilter;
  String? _locationFilter;
  String? _colorFilter;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _sortOrder = 'recent';

  bool get _hasActiveFilters =>
      _categoryFilter != null ||
      _locationFilter != null ||
      _colorFilter != null ||
      _fromDate != null ||
      _toDate != null ||
      _sortOrder != 'recent';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> get _itemsQuery =>
      FirebaseFirestore.instance
          .collection('items')
          .orderBy('createdAt', descending: true);

  void _showPostSheet(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostItemSheet(type: type),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialCategory: _categoryFilter,
        initialLocation: _locationFilter,
        initialColor: _colorFilter,
        initialFromDate: _fromDate,
        initialToDate: _toDate,
        initialSortOrder: _sortOrder,
        onApply: (cat, loc, color, from, to, sort) => setState(() {
          _categoryFilter = cat;
          _locationFilter = loc;
          _colorFilter = color;
          _fromDate = from;
          _toDate = to;
          _sortOrder = sort;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildDrawer(user),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildAppBar(user)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildWelcome(),
                    const SizedBox(height: 20),
                    _buildActionCards(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildFilterChips(),
                    if (_hasActiveFilters) ...[
                      const SizedBox(height: 8),
                      _buildActiveFilterBadges(),
                    ],
                    const SizedBox(height: 20),
                    _buildRecentHeader(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildItemsList(),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── DRAWER ───────────────────────────────────────────────────────────────────
  Widget _buildDrawer(User? user) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: kGreen,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Text(
                      (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: kGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('My Items'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/my-items');
              },
            ),
            ListTile(
              leading: const Icon(Icons.message_outlined),
              title: const Text('My Messages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/messages');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Sign Out',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    content:
                        const Text('Are you sure you want to sign out?'),
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
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/welcome');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar(User? user) {
    return Container(
      color: kGreen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child:
                const Icon(Icons.search, color: kGreen, size: 22),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FindJU',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              Text('University of Jordan',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const Spacer(),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('uid',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (ctx, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 24),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/notifications'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: Colors.orange, shape: BoxShape.circle),
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              );
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ],
      ),
    );
  }

  // ── WELCOME ──────────────────────────────────────────────────────────────────
  Widget _buildWelcome() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome to FindJU',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black87)),
        SizedBox(height: 4),
        Text(
          'Your campus lost and found platform for the\nUniversity of Jordan',
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
        ),
      ],
    );
  }

  // ── ACTION CARDS ─────────────────────────────────────────────────────────────
  Widget _buildActionCards() {
    return Column(
      children: [
        _actionCard(
          color: kGreen,
          icon: Icons.add,
          title: 'Report Lost Item',
          subtitle: 'Post details about your missing item',
          onTap: () => _showPostSheet('Lost'),
        ),
        const SizedBox(height: 12),
        _actionCard(
          color: kOrange,
          icon: Icons.search,
          title: 'Report Found Item',
          subtitle: 'Help someone find their lost item',
          onTap: () => _showPostSheet('Found'),
        ),
      ],
    );
  }

  Widget _actionCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH BAR ───────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name, category, location...',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.grey, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.grey, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _showFilterSheet,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _hasActiveFilters ? Colors.orange : kGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune,
                    color: Colors.white, size: 20),
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── TYPE CHIPS ───────────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    const filters = ['All', 'Lost', 'Found'];
    return Row(
      children: filters.map((f) {
        final active = _typeFilter == f;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => setState(() => _typeFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: active ? kGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? kGreen : Colors.grey.shade300,
                ),
              ),
              child: Text(
                f,
                style: TextStyle(
                  color: active ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── ACTIVE FILTER BADGES ─────────────────────────────────────────────────────
  Widget _buildActiveFilterBadges() {
    final fmt = DateFormat('MMM d');
    final badges = <Widget>[];
    if (_categoryFilter != null) {
      badges.add(_filterBadge(
          _categoryFilter!, () => setState(() => _categoryFilter = null)));
    }
    if (_locationFilter != null) {
      badges.add(_filterBadge(
          _locationFilter!, () => setState(() => _locationFilter = null)));
    }
    if (_colorFilter != null) {
      badges.add(_filterBadge(
          _colorFilter!, () => setState(() => _colorFilter = null)));
    }
    if (_fromDate != null || _toDate != null) {
      final label =
          '${_fromDate != null ? fmt.format(_fromDate!) : '…'} – ${_toDate != null ? fmt.format(_toDate!) : '…'}';
      badges.add(_filterBadge(label, () => setState(() {
            _fromDate = null;
            _toDate = null;
          })));
    }
    if (_sortOrder != 'recent') {
      badges.add(_filterBadge(
          'Oldest first', () => setState(() => _sortOrder = 'recent')));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: badges),
    );
  }

  Widget _filterBadge(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: kGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: kGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: kGreen),
          ),
        ],
      ),
    );
  }

  // ── RECENT HEADER ────────────────────────────────────────────────────────────
  Widget _buildRecentHeader() {
    final label = _typeFilter != 'All'
        ? '$_typeFilter Items'
        : (_hasActiveFilters || _searchQuery.isNotEmpty
            ? 'Filtered Items'
            : 'Recent Items');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/all-items'),
          child: const Text('View All →',
              style: TextStyle(
                  fontSize: 13,
                  color: kGreen,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ── ITEMS LIST ───────────────────────────────────────────────────────────────
  Widget _buildItemsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _itemsQuery.limit(50).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: kGreen)),
            ),
          );
        }
        if (snap.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        var docs = snap.data?.docs ?? [];

        // Keep reunited items in the feed but mark them as closed

        // Type filter (client-side — avoids composite index requirement)
        if (_typeFilter != 'All') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['type'] == _typeFilter;
          }).toList();
        }

        if (_categoryFilter != null) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['category'] == _categoryFilter;
          }).toList();
        }
        if (_locationFilter != null) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['location'] == _locationFilter;
          }).toList();
        }
        if (_colorFilter != null) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['color'] as String?)?.toLowerCase() ==
                _colorFilter!.toLowerCase();
          }).toList();
        }
        if (_fromDate != null) {
          docs = docs.where((d) {
            final ts =
                (d.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            return ts != null &&
                !ts.toDate().isBefore(_fromDate!);
          }).toList();
        }
        if (_toDate != null) {
          final toEnd = _toDate!.add(const Duration(days: 1));
          docs = docs.where((d) {
            final ts =
                (d.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            return ts != null && ts.toDate().isBefore(toEnd);
          }).toList();
        }
        if (_sortOrder == 'oldest') {
          docs = docs.reversed.toList();
        }
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final fields = [
              data['title'] ?? '',
              data['description'] ?? '',
              data['category'] ?? '',
              data['location'] ?? '',
            ].map((e) => e.toString().toLowerCase()).join(' ');
            return fields.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No items found.',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ItemCard(data: data, docId: docs[i].id),
              );
            },
            childCount: docs.length,
          ),
        );
      },
    );
  }
}

// ── FILTER BOTTOM SHEET ───────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String? initialCategory;
  final String? initialLocation;
  final String? initialColor;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String initialSortOrder;
  final void Function(
    String? category,
    String? location,
    String? color,
    DateTime? fromDate,
    DateTime? toDate,
    String sortOrder,
  ) onApply;

  const _FilterSheet({
    required this.initialCategory,
    required this.initialLocation,
    required this.initialColor,
    required this.initialFromDate,
    required this.initialToDate,
    required this.initialSortOrder,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  static const kGreen = Color.fromARGB(255, 41, 103, 43);

  String? _category;
  String? _location;
  String? _color;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _sortOrder = 'recent';

  @override
  void initState() {
    super.initState();
    _category  = widget.initialCategory;
    _location  = widget.initialLocation;
    _color     = widget.initialColor;
    _fromDate  = widget.initialFromDate;
    _toDate    = widget.initialToDate;
    _sortOrder = widget.initialSortOrder;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _fromDate : _toDate) ?? now,
      firstDate: isFrom ? DateTime(2020) : (_fromDate ?? DateTime(2020)),
      lastDate: isFrom ? (_toDate ?? now) : now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kGreen,
            onPrimary: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isFrom ? _fromDate = picked : _toDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Filter & Sort',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _category  = null;
                      _location  = null;
                      _color     = null;
                      _fromDate  = null;
                      _toDate    = null;
                      _sortOrder = 'recent';
                    }),
                    child: const Text('Reset all',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sort By ──────────────────────────────────────
                    _sectionLabel('Sort By'),
                    const SizedBox(height: 10),
                    Row(children: [
                      _sortChip('Most Recent', 'recent'),
                      const SizedBox(width: 8),
                      _sortChip('Oldest First', 'oldest'),
                    ]),
                    const SizedBox(height: 22),

                    // ── Category ─────────────────────────────────────
                    _sectionLabel('Category'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kCategories.map((cat) {
                        final active = _category == cat;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _category = active ? null : cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? kGreen
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(cat,
                                style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 13,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // ── Location ─────────────────────────────────────
                    _sectionLabel('Location'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String?>(
                        value: _location,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('All Locations',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 13),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Locations',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13)),
                          ),
                          ...kLocations.map((loc) =>
                              DropdownMenuItem<String?>(
                                value: loc,
                                child: Text(loc,
                                    style: const TextStyle(
                                        fontSize: 13)),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _location = v),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Color ────────────────────────────────────────
                    _sectionLabel('Color'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kColors.map((name) {
                        final val = kColorValues[name]!;
                        final active = _color == name;
                        return GestureDetector(
                          onTap: () => setState(
                              () => _color = active ? null : name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: active
                                  ? val.withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? val
                                    : Colors.grey.shade300,
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
                                        ? Border.all(
                                            color: Colors.grey.shade300)
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
                    const SizedBox(height: 22),

                    // ── Date Range ───────────────────────────────────
                    _sectionLabel('Date Range'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerButton(
                            label: 'From',
                            value: _fromDate != null
                                ? fmt.format(_fromDate!)
                                : null,
                            onTap: () => _pickDate(isFrom: true),
                            onClear: _fromDate != null
                                ? () => setState(() => _fromDate = null)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DatePickerButton(
                            label: 'To',
                            value: _toDate != null
                                ? fmt.format(_toDate!)
                                : null,
                            onTap: () => _pickDate(isFrom: false),
                            onClear: _toDate != null
                                ? () => setState(() => _toDate = null)
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Apply ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onApply(_category, _location, _color,
                              _fromDate, _toDate, _sortOrder);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text('Apply Filters',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
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

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.black87));

  Widget _sortChip(String label, String value) {
    final active = _sortOrder == value;
    return GestureDetector(
      onTap: () => setState(() => _sortOrder = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}

// ── DATE PICKER BUTTON ────────────────────────────────────────────────────────
class _DatePickerButton extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 15, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                    fontSize: 13,
                    color: value != null
                        ? Colors.black87
                        : Colors.grey),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 14, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}

// ── ITEM CARD ─────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _ItemCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final isLost = (data['type'] ?? '') == 'Lost';
    final isReunited = data['status'] == 'reunited';
    final imageUrl = data['imageUrl'] as String? ?? '';
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

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/item-detail', arguments: docId),
      child: Opacity(
        opacity: isReunited ? 0.72 : 1.0,
        child: Container(
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
            // ── Image ──────────────────────────────────────────────────
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
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
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
                    top: 10,
                    left: 10,
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
                  // Reunited badge — top right
                  if (isReunited)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B3FA0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Reunited ✓',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  // Time — bottom right over gradient
                  if (timeAgo.isNotEmpty && !isReunited)
                    Positioned(
                      bottom: 8,
                      right: 10,
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
            // ── Content ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
          ],
        ),
      ),
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
