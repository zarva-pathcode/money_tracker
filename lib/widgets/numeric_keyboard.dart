import 'package:flutter/material.dart';

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
          // Dipisah agar angka di bawah lebih lega
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
                        Icons.arrow_back_ios_rounded,
                        onCursorLeft!,
                      ),
                    if (onCursorRight != null)
                      _buildControlBtn(
                        Icons.arrow_forward_ios_rounded,
                        onCursorRight!,
                      ),
                  ],
                ),
                // Tombol Selesai / Tutup Keyboard
                TextButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(
                    Icons.keyboard_hide_rounded,
                    color: Colors.blue,
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

          // 2. GRID ANGKA (Menggunakan Expanded agar responsive)
          Expanded(
            child: Row(
              children: [
                // Kolom Kiri (1, 4, 7, .000)
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
                // Kolom Tengah (2, 5, 8, 0)
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
                // Kolom Kanan (3, 6, 9, Backspace)
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

  // Widget Tombol Angka Biasa
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
                fontWeight:
                    FontWeight.w400, // Font tipis tapi besar (Modern Style)
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Tombol Khusus (.000)
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

  // Widget Tombol Backspace
  Widget _buildBackspaceBtn() {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBackspace,
          onLongPress: () {
            // Opsional: Hapus banyak jika ditekan lama (logic bisa ditambah nanti)
            onBackspace();
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50], // Merah sangat muda
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.backspace_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Tombol Kontrol Kecil (Arrow)
  Widget _buildControlBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.grey[600]),
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
