import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NumericKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final VoidCallback? onCursorLeft;
  final VoidCallback? onCursorRight;

  const NumericKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onSubmit,
    this.onCursorLeft,
    this.onCursorRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Background bersih
      child: Column(
        children: [
          // 1. BARIS KONTROL (Cursor & Submit)
          Container(
            height: 48,
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Group Cursor Kiri/Kanan
                Row(
                  children: [
                    if (onCursorLeft != null)
                      _buildControlBtn(
                        FontAwesomeIcons.chevronLeft,
                        onCursorLeft!,
                      ),
                    if (onCursorRight != null)
                      _buildControlBtn(
                        FontAwesomeIcons.chevronRight,
                        onCursorRight!,
                      ),
                  ],
                ),
                // Tombol Selesai / Tutup Keyboard
                TextButton.icon(
                  onPressed: onSubmit,
                  icon: const FaIcon(
                    FontAwesomeIcons.keyboard,
                    color: Colors.blue,
                    size: 16,
                  ),
                  label: const Text(
                    "Selesai",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // 2. GRID ANGKA
          Expanded(
            child: Row(
              children: [
                // Kolom Kiri
                Expanded(
                  child: Column(
                    children: [
                      _buildNumberBtn('1'),
                      _buildNumberBtn('4'),
                      _buildNumberBtn('7'),
                      _buildCustomBtn(
                        '.000',
                        color: Colors.blue[50],
                        textColor: Colors.blue[800],
                      ),
                    ],
                  ),
                ),
                // Kolom Tengah
                Expanded(
                  child: Column(
                    children: [
                      _buildNumberBtn('2'),
                      _buildNumberBtn('5'),
                      _buildNumberBtn('8'),
                      _buildNumberBtn('0'),
                    ],
                  ),
                ),
                // Kolom Kanan
                Expanded(
                  child: Column(
                    children: [
                      _buildNumberBtn('3'),
                      _buildNumberBtn('6'),
                      _buildNumberBtn('9'),
                      _buildBackspaceBtn(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberBtn(String label) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onKeyPressed(label),
          splashColor: Colors.grey.withOpacity(0.1),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBtn(String label, {Color? color, Color? textColor}) {
    return Expanded(
      child: Material(
        color: color ?? Colors.white,
        child: InkWell(
          onTap: () => onKeyPressed(label),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceBtn() {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBackspace,
          onLongPress: () {
            onBackspace();
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.deleteLeft,
                color: Colors.red,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBtn(dynamic icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: FaIcon(icon, size: 14, color: Colors.grey[600]),
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
