import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:money_tracker/providers/expense_provider.dart';
import 'package:money_tracker/providers/plan_provider.dart';
import 'package:money_tracker/providers/settings_provider.dart';
import 'package:money_tracker/screens/home_screen.dart';
import 'package:money_tracker/screens/monthly_report_screen.dart';
import 'package:money_tracker/screens/plan_screen.dart';
import 'package:money_tracker/screens/settings_screen.dart';
import 'package:money_tracker/screens/add_expense_screen.dart';
import 'package:money_tracker/screens/scan_receipt_screen.dart';
import 'package:money_tracker/screens/subscription_screen.dart';
import 'package:money_tracker/services/speech_service.dart';
import 'package:money_tracker/services/transaction_parser_service.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/voice_transaction_service.dart';
import '../widgets/fade_indexed_stack.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final SpeechService _speechService = SpeechService();
  bool _isRecording = false;
  bool _isProcessing = false;
  String _liveText = '';
  late AnimationController _pulseController;
  double? _dragStartY;
  double _cancelProgress = 0;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pendingWidgetUri != null) {
        final uri = pendingWidgetUri!;
        pendingWidgetUri = null;

        final voice = uri.queryParameters['voice'];
        if (voice == 'true') {
          _startRecording();
          return;
        }

        final category = uri.queryParameters['category'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AddExpenseScreen(
                  preSelectedCategory: category == 'empty' ? null : category,
                ),
          ),
        );
      }
    });

    onWidgetVoiceTrigger = _startRecording;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const MonthlyReportScreen(),
    const PlanScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Sembunyikan FAB + navbar saat keyboard terbuka agar layar penuh
    // untuk konten (mis. hasil pencarian), tanpa balok putih melayang.
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          FadeIndexedStack(index: _currentIndex, children: _screens),
          if (_isRecording) _buildRecordingOverlay(),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: keyboardVisible
          ? null
          : GestureDetector(
        onTap: () => _showAddTransactionBottomSheet(context),
        onLongPressStart: (details) {
          _dragStartY = details.globalPosition.dy;
          _cancelProgress = 0;
          _isCancelling = false;
          _startRecording();
        },
        onLongPressMoveUpdate: (details) {
          if (_dragStartY == null) return;
          final dy = _dragStartY! - details.globalPosition.dy;
          final progress = (dy / 80).clamp(0.0, 1.0);
          if (progress != _cancelProgress ||
              (progress >= 1.0) != _isCancelling) {
            setState(() {
              _cancelProgress = progress;
              _isCancelling = progress >= 1.0;
            });
          }
        },
        onLongPressEnd: (_) {
          _dragStartY = null;
          _cancelProgress = 0;
          if (_isCancelling) {
            _isCancelling = false;
            _cancelRecording();
          } else {
            _stopAndSave();
          }
        },
        onLongPressCancel: () {
          _cancelProgress = 0;
          _isCancelling = false;
          _cancelRecording();
        },
        child: FloatingActionButton(
          heroTag: 'main_add_fab',
          onPressed: null,
          backgroundColor:
              _isRecording ? Colors.red : Theme.of(context).primaryColor,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          child: _isRecording
              ? const Icon(Icons.stop, color: Colors.white, size: 24)
              : const FaIcon(FontAwesomeIcons.plus, size: 24, color: Colors.white),
        ),
      ),
      bottomNavigationBar: keyboardVisible
          ? null
          : BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              color: Colors.white,
              elevation: 20,
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(FontAwesomeIcons.house, 'Home', 0),
                    _buildNavItem(FontAwesomeIcons.chartPie, 'Report', 1),
                    const SizedBox(width: 48),
                    _buildNavItem(FontAwesomeIcons.piggyBank, 'Plan', 2),
                    _buildNavItem(FontAwesomeIcons.gears, 'Settings', 3),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRecordingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recording card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = 1.0 + (_pulseController.value * 0.15);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(
                                  0.9 - (_pulseController.value * 0.3),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Merekam...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _liveText.isEmpty
                                ? 'Belum ada suara terdeteksi...'
                                : _liveText,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  _liveText.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _stopAndSave,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10375C),
                            side: const BorderSide(
                              color: Color(0xFF10375C),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Selesai',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Boundary indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 1,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_upward,
                      size: 12,
                      color: Colors.white.withOpacity(0.35),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Geser ke atas untuk batalkan',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_upward,
                      size: 12,
                      color: Colors.white.withOpacity(0.35),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 1,
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Cancel zone
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isCancelling ? 200 : 180,
                  height: _isCancelling ? 64 : 56,
                  decoration: BoxDecoration(
                    color:
                        _isCancelling
                            ? Colors.red.withOpacity(0.9)
                            : Colors.white.withOpacity(
                              0.15 + _cancelProgress * 0.5,
                            ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color:
                          _isCancelling
                              ? Colors.red[300]!
                              : Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCancelling ? Icons.cancel : Icons.keyboard_arrow_up,
                        color: _isCancelling ? Colors.white : Colors.white70,
                        size: 28,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isCancelling ? 'Lepaskan!' : 'Geser ke sini',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isCancelling ? Colors.white : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                SizedBox(
                  width: 120,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _cancelProgress,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isCancelling ? Colors.red[300]! : Colors.white54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black54,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Memproses transaksi...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Harap tunggu sebentar',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(dynamic icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color =
        isSelected ? Theme.of(context).primaryColor : Colors.grey[400];

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    final available = await _speechService.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech-to-text tidak tersedia. Izin mikrofon belum diberikan.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _liveText = '';
    });
    _pulseController.repeat(reverse: true);

    _speechService.startListening(
      onResult: (text) {
        if (mounted) {
          setState(() => _liveText = text);
        }
      },
      onError: (error) {
        if (mounted) _cancelRecording();
      },
    );
  }

  Future<void> _stopAndSave() async {
    if (!_isRecording) return;

    await _speechService.stopListening();
    _pulseController.stop();
    _pulseController.reset();

    final text = _liveText.trim();
    setState(() {
      _isRecording = false;
      _liveText = '';
      _isProcessing = true;
    });

    try {
      if (text.length < 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Teks terlalu pendek, tidak ada transaksi disimpan',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final results = await Future(() => TransactionParserService.parse(text));
      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat mengenali transaksi dari suara'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final expenseProvider = Provider.of<ExpenseProvider>(
        context,
        listen: false,
      );

      // Handle overspend for voice transactions
      final netAdditionalExpense = VoiceTransactionService.calculateNetExpense(
        results,
      );
      if (netAdditionalExpense > 0) {
        final handled = await _handleOverspend(netAdditionalExpense);
        if (!handled) return;
      }

      final expenses = VoiceTransactionService.buildExpenses(results);
      for (final expense in expenses) {
        await expenseProvider.addExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${expenses.length} transaksi berhasil ditambahkan',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<bool> _handleOverspend(double netAdditionalExpense) async {
    final expenseProvider = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    );
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    if (mounted) setState(() => _isProcessing = false);

    final proceed = await expenseProvider.handleOverspendIfNeeded(
      amount: netAdditionalExpense,
      payDay: settingsProvider.periodStartDay,
      context: context,
      planProvider: planProvider,
    );

    if (mounted) setState(() => _isProcessing = true);
    return proceed;
  }

  void _cancelRecording() {
    if (!_isRecording) return;
    _speechService.stopListening();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isRecording = false;
      _liveText = '';
    });
  }

  void _showAddTransactionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tambah Transaksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih jenis pencatatan yang ingin kamu buat',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ...[
                _buildTransactionOption(
                  context: context,
                  icon: FontAwesomeIcons.arrowUp,
                  label: 'Pengeluaran',
                  subtitle: 'Catat belanja, jajan, atau tagihan harian',
                  color: Colors.red[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const AddExpenseScreen(
                              initialTransactionType: 'expense',
                            ),
                      ),
                    );
                  },
                ),
                _buildTransactionOption(
                  context: context,
                  icon: FontAwesomeIcons.arrowDown,
                  label: 'Pemasukan',
                  subtitle: 'Catat gaji, bonus, atau transfer masuk',
                  color: Colors.green[700]!,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const AddExpenseScreen(
                              initialTransactionType: 'income',
                            ),
                      ),
                    );
                  },
                ),
                _buildTransactionOption(
                  context: context,
                  icon: FontAwesomeIcons.receipt,
                  label: 'Scan Struk Belanja',
                  subtitle: 'Ekstrak total langsung dari foto nota',
                  color: Colors.blue[700]!,
                  badge: 'Otomatis',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScanReceiptScreen(),
                      ),
                    );
                  },
                ),
                _buildTransactionOption(
                  context: context,
                  icon: FontAwesomeIcons.repeat,
                  label: 'Langganan Rutin',
                  subtitle: 'Kelola pengeluaran berulang tiap bulan',
                  color: Colors.indigo[400]!,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
              ].animate(interval: 60.ms).fadeIn(duration: 300.ms, curve: Curves.easeOut).slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 300.ms,
                    curve: Curves.easeOutQuad,
                  ),
            ],
          ),
        );
      },
    );
  }

  /// Kartu pilihan full-width: ikon tint + judul + subtitle + chevron.
  Widget _buildTransactionOption({
    required BuildContext context,
    required dynamic icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(child: FaIcon(icon, color: color, size: 20)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
