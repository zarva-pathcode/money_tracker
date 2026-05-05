import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:money_tracker/screens/main_screen.dart';
import 'package:money_tracker/screens/add_expense_screen.dart';
import '../services/hive_service.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isAgreed = false; // State untuk checkbox

  // Data Slide Onboarding
  final List<Map<String, String>> _contents = [
    {
      "title": "Catat Pengeluaran",
      "desc":
          "Pantau kemana perginya uangmu setiap hari dengan mudah dan cepat.",
      "icon": "📝",
    },
    {
      "title": "Analisis Statistik",
      "desc":
          "Lihat grafik tren mingguan dan bulanan untuk mengatur budget lebih baik.",
      "icon": "📊",
    },
    {
      "title": "Aman & Offline",
      "desc":
          "Data tersimpan lokal di HP kamu. Privasi terjaga, tanpa perlu internet.",
      "icon": "🔒",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == _contents.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. SKIP BUTTON (Hanya muncul jika bukan halaman terakhir)
            Align(
              alignment: Alignment.topRight,
              child:
                  !isLastPage
                      ? TextButton(
                        onPressed:
                            () => _pageController.jumpToPage(
                              _contents.length - 1,
                            ),
                        child: const Text(
                          "Lewati",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                      : const SizedBox(
                        height: 48,
                      ), // Spacer agar layout tidak naik
            ),

            // 2. PAGE VIEW (SLIDER)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _contents[index]['icon']!,
                              style: const TextStyle(fontSize: 80),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _contents[index]['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _contents[index]['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. PRIVACY POLICY CHECKBOX (Hanya di Halaman Terakhir)
            if (isLastPage)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start, // Agar checkbox sejajar teks atas
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _isAgreed,
                        activeColor: Colors.blue[800],
                        onChanged: (val) {
                          setState(() => _isAgreed = val ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            height: 1.3,
                          ),
                          children: [
                            const TextSpan(text: "Saya menyetujui "),
                            TextSpan(
                              text: "Kebijakan Privasi",
                              style: TextStyle(
                                color: Colors.blue[800],
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap = () => _showPrivacyPolicy(context),
                            ),
                            const TextSpan(
                              text:
                                  " dan menyadari bahwa data disimpan secara lokal di perangkat ini.",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. NAVIGATION AREA
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots Indicator
                  Row(
                    children: List.generate(
                      _contents.length,
                      (index) => _buildDot(index),
                    ),
                  ),

                  // Tombol Next / Mulai
                  ElevatedButton(
                    onPressed: () {
                      if (isLastPage) {
                        if (_isAgreed) {
                          _finishOnboarding();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Mohon setujui kebijakan privasi untuk melanjutkan",
                              ),
                            ),
                          );
                        }
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isLastPage
                              ? (_isAgreed
                                  ? Colors.blue[800]
                                  : Colors.grey[300]) // Abu jika belum setuju
                              : Colors.blue[800],
                      foregroundColor:
                          isLastPage
                              ? (_isAgreed ? Colors.white : Colors.grey[500])
                              : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: (isLastPage && !_isAgreed) ? 0 : 2,
                    ),
                    child: Text(
                      isLastPage ? "Mulai Sekarang" : "Lanjut",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentIndex == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentIndex == index ? Colors.blue[800] : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            height:
                MediaQuery.of(context).size.height * 0.7, // 70% tinggi layar
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Text(
                  "Kebijakan Privasi",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPolicyItem(
                          "1. Pengumpulan Data",
                          "Aplikasi ini tidak mengumpulkan, menyimpan, atau mengirimkan data pribadi Anda ke server eksternal manapun.",
                        ),
                        _buildPolicyItem(
                          "2. Penyimpanan Lokal",
                          "Seluruh data transaksi disimpan secara lokal di dalam memori perangkat Anda menggunakan teknologi Hive Database.",
                        ),
                        _buildPolicyItem(
                          "3. Akses Internet",
                          "Aplikasi ini tidak memerlukan koneksi internet untuk berfungsi utama.",
                        ),
                        _buildPolicyItem(
                          "4. Keamanan",
                          "Karena data disimpan di perangkat Anda, keamanan data bergantung pada keamanan fisik dan sistem penguncian perangkat Anda.",
                        ),
                        _buildPolicyItem(
                          "5. Penghapusan Data",
                          "Anda dapat menghapus seluruh data secara permanen melalui menu Pengaturan > Hapus Semua Data.",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Saya Mengerti"),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPolicyItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    await HiveService.setOnboardingSeen();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );

      // If there was a pending widget click during onboarding, handle it now
      if (pendingWidgetUri != null) {
        final uri = pendingWidgetUri!;
        pendingWidgetUri = null;
        
        final category = uri.queryParameters['category'];
        
        // Use a slight delay to ensure MainScreen is mounted
        Future.delayed(const Duration(milliseconds: 100), () {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => AddExpenseScreen(
                preSelectedCategory: category == 'empty' ? null : category,
              ),
            ),
          );
        });
      }
    }
  }
}
