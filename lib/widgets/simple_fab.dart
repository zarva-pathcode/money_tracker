import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '../utils/constants.dart';

class SimpleFab extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const SimpleFab({super.key, this.onCategorySelected});

  @override
  _SimpleFabState createState() => _SimpleFabState();
}

class _SimpleFabState extends State<SimpleFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _onCategorySelected(String category) {
    _toggle();
    Future.delayed(const Duration(milliseconds: 200), () {
      widget.onCategorySelected?.call(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        Constants.categories.where((c) => c != 'Semua Kategori').toList();
    final reversedCategories = categories.reversed.toList();

    // PENTING: Widget ini akan mengisi FULL SCREEN karena dipanggil dengan Positioned.fill di HomeScreen
    return Stack(
      // Kita tidak set alignment di sini agar anak-anaknya bisa bebas posisi
      children: [
        // 1. BLUR OVERLAY (Benar-benar Full Screen)
        // Logika: Jika Expanded, kita pasang overlay yang memenuhi stack parent
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle, // Ini akan menangkap tap di mana saja
              behavior:
                  HitTestBehavior.opaque, // Pastikan menangkap semua sentuhan
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.3,
                  ), // Warna gelap full screen
                ),
              ),
            ),
          ),

        // 2. GROUP FAB & MENU (Dipojokkan ke kanan bawah manual)
        // Kita bungkus menu dan tombol utama dalam satu Align/Positioned
        Positioned(
          right: 16, // Jarak dari kanan
          bottom: 16, // Jarak dari bawah
          child: Column(
            mainAxisSize: MainAxisSize.min, // Hanya setinggi konten
            crossAxisAlignment: CrossAxisAlignment.end, // Rata kanan
            children: [
              // A. MENU ITEMS
              if (_isExpanded) ...[
                // Kita buat list menu di sini
                ...List.generate(reversedCategories.length, (index) {
                  final category = reversedCategories[index];

                  final startInterval =
                      (reversedCategories.length - 1 - index) * 0.1;
                  final endInterval = startInterval + 0.4;

                  final itemAnimation = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      startInterval.clamp(0.0, 1.0),
                      endInterval.clamp(0.0, 1.0),
                      // easeOut — tanpa bounce
                      curve: Curves.easeOut,
                    ),
                  );

                  return _buildAnimatedCategoryButton(category, itemAnimation);
                }),
                const SizedBox(
                  height: 16,
                ), // Jarak antara menu terakhir dengan FAB Utama
              ],

              // B. FAB UTAMA — tanpa bounce animation, hanya rotation halus
              FloatingActionButton(
                onPressed: _toggle,
                backgroundColor: Theme.of(context).primaryColor,
                elevation: 4,
                shape: const CircleBorder(),
                child: RotationTransition(
                  turns: _rotateAnimation,
                  child: const Icon(
                    Icons.add_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCategoryButton(
    String categoryName,
    Animation<double> animation,
  ) {
    final style = Constants.getCategoryStyle(categoryName);
    final color = style.color;
    final icon = style.icon;

    return ScaleTransition(
      scale: animation,
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () => _onCategorySelected(categoryName),
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                height: 40,
                child: FloatingActionButton(
                  heroTag: 'fab_$categoryName',
                  onPressed: () => _onCategorySelected(categoryName),
                  backgroundColor: color,
                  elevation: 0,
                  shape: const CircleBorder(),
                  child: FaIcon(icon, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
