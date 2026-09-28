import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // جعل التطبيق Full Screen
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // السماح بالوضع الرأسي
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const SonsOfKingApp());
}

class SonsOfKingApp extends StatelessWidget {
  const SonsOfKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'منظومة أولاد الملك',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color(0xFF0F172A),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),

      home: const MainWebViewScreen(),
    );
  }
}

class MainWebViewScreen extends StatefulWidget {
  const MainWebViewScreen({super.key});

  @override
  State<MainWebViewScreen> createState() =>
      _MainWebViewScreenState();
}

class _MainWebViewScreenState
    extends State<MainWebViewScreen> {

  static const String websiteUrl =
      'https://sons-of-king.html-5.me';

  late final WebViewController _controller;

  StreamSubscription<List<ConnectivityResult>>?
      _connectivitySubscription;

  bool _isLoading = true;
  bool _hasInternet = true;
  bool _hasError = false;

  int _progress = 0;

  @override
  void initState() {
    super.initState();

    _initializeWebView();
    _checkInternet();
    _listenToInternet();
  }

  // =========================================================
  // تهيئة WebView
  // =========================================================

  void _initializeWebView() {

    _controller = WebViewController()

      // JavaScript
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )

      // لون الخلفية
      ..setBackgroundColor(
        const Color(0xFF0F172A),
      )

      // التحكم في التنقل
      ..setNavigationDelegate(
        NavigationDelegate(

          // نسبة تحميل الصفحة
          onProgress: (progress) {

            if (!mounted) return;

            setState(() {
              _progress = progress;
            });
          },

          // بداية تحميل الصفحة
          onPageStarted: (url) {

            if (!mounted) return;

            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },

          // انتهاء تحميل الصفحة
          onPageFinished: (url) {

            if (!mounted) return;

            setState(() {
              _isLoading = false;
              _progress = 100;
            });
          },

          // خطأ في تحميل الصفحة
          onWebResourceError: (error) {

            if (!mounted) return;

            // نتعامل فقط مع أخطاء الصفحة الرئيسية
            if (error.isForMainFrame ?? true) {

              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },

          // التحكم في الروابط
          onNavigationRequest: (request) async {

            final uri = Uri.tryParse(
              request.url,
            );

            if (uri == null) {
              return NavigationDecision.prevent;
            }

            // روابط الهاتف
            if (uri.scheme == 'tel') {

              await _openExternalUrl(uri);

              return NavigationDecision.prevent;
            }

            // البريد الإلكتروني
            if (uri.scheme == 'mailto') {

              await _openExternalUrl(uri);

              return NavigationDecision.prevent;
            }

            // الروابط العادية تظل داخل التطبيق
            return NavigationDecision.navigate;
          },
        ),
      )

      // فتح الموقع
      ..loadRequest(
        Uri.parse(websiteUrl),
      );

    // إعدادات Android الخاصة بالـ WebView
    if (Platform.isAndroid) {

      final androidController =
          _controller.platform
              as AndroidWebViewController;

      // تشغيل Debug فقط أثناء التطوير
      AndroidWebViewController.enableDebugging(
        false,
      );

      // دعم اختيار الملفات
      androidController.setOnShowFileSelector(
        (params) async {

          final result =
              await FilePicker.platform.pickFiles(
            allowMultiple:
                params.mode ==
                    FileSelectorMode.openMultiple,

            type: FileType.any,
          );

          if (result == null) {
            return <String>[];
          }

          return result.files
              .where(
                (file) => file.path != null,
              )
              .map(
                (file) => file.path!,
              )
              .toList();
        },
      );
    }
  }

  // =========================================================
  // فحص الإنترنت
  // =========================================================

  Future<void> _checkInternet() async {

    final results =
        await Connectivity()
            .checkConnectivity();

    if (!mounted) return;

    final connected =
        !results.contains(
          ConnectivityResult.none,
        );

    setState(() {
      _hasInternet = connected;
    });

    if (connected && _hasError) {
      _reloadWebsite();
    }
  }

  // =========================================================
  // مراقبة الإنترنت
  // =========================================================

  void _listenToInternet() {

    _connectivitySubscription =
        Connectivity()
            .onConnectivityChanged
            .listen((results) {

      if (!mounted) return;

      final connected =
          !results.contains(
            ConnectivityResult.none,
          );

      setState(() {
        _hasInternet = connected;
      });

      if (connected) {
        _reloadWebsite();
      }
    });
  }

  // =========================================================
  // إعادة تحميل الموقع
  // =========================================================

  Future<void> _reloadWebsite() async {

    if (!_hasInternet) {
      await _checkInternet();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _progress = 0;
    });

    await _controller.reload();
  }

  // =========================================================
  // فتح رابط خارجي
  // =========================================================

  Future<void> _openExternalUrl(
      Uri uri) async {

    try {

      if (await canLaunchUrl(uri)) {

        await launchUrl(
          uri,
          mode:
              LaunchMode.externalApplication,
        );
      }

    } catch (_) {}
  }

  // =========================================================
  // زر الرجوع
  // =========================================================

  Future<bool> _handleBackButton() async {

    if (await _controller.canGoBack()) {

      await _controller.goBack();

      return false;
    }

    return true;
  }

  // =========================================================
  // تنظيف الموارد
  // =========================================================

  @override
  void dispose() {

    _connectivitySubscription?.cancel();

    super.dispose();
  }

  // =========================================================
  // واجهة التطبيق
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,

      onPopInvokedWithResult:
          (didPop, result) async {

        if (didPop) return;

        final shouldExit =
            await _handleBackButton();

        if (shouldExit && mounted) {

          Navigator.of(context).pop();
        }
      },

      child: Scaffold(

        backgroundColor:
            const Color(0xFF0F172A),

        body: Stack(

          children: [

            // =================================================
            // الموقع
            // =================================================

            Positioned.fill(
              child: WebViewWidget(
                controller: _controller,
              ),
            ),

            // =================================================
            // شاشة عدم وجود إنترنت
            // =================================================

            if (!_hasInternet)

              Positioned.fill(
                child: _buildOfflineScreen(),
              ),

            // =================================================
            // شاشة الخطأ
            // =================================================

            if (_hasInternet && _hasError)

              Positioned.fill(
                child: _buildErrorScreen(),
              ),

            // =================================================
            // شاشة التحميل
            // =================================================

            if (_isLoading && _hasInternet)

              Positioned.fill(
                child: _buildLoadingScreen(),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // شاشة التحميل
  // =========================================================

  Widget _buildLoadingScreen() {

    return Container(
      color: const Color(0xFF0F172A),

      child: Center(

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            // أيقونة التطبيق
            Container(
              width: 90,
              height: 90,

              decoration: BoxDecoration(
                color:
                    const Color(0xFF1E293B),

                borderRadius:
                    BorderRadius.circular(22),

                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),

              child: const Icon(
                Icons.church_rounded,
                size: 50,
                color:
                    Color(0xFFFBBF24),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'منظومة أولاد الملك',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'جاري الاتصال بالمنظومة...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: 200,

              child:
                  LinearProgressIndicator(
                value:
                    _progress > 0
                        ? _progress / 100
                        : null,

                minHeight: 5,

                borderRadius:
                    BorderRadius.circular(10),

                backgroundColor:
                    Colors.white12,

                color:
                    const Color(0xFF6366F1),
              ),
            ),

            const SizedBox(height: 10),

            if (_progress > 0)

              Text(
                '$_progress%',
                style:
                    const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // شاشة Offline
  // =========================================================

  Widget _buildOfflineScreen() {

    return Container(
      color: const Color(0xFF0F172A),

      child: Center(

        child: Padding(
          padding:
              const EdgeInsets.all(30),

          child: Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              const Icon(
                Icons
                    .wifi_off_rounded,
                size: 75,
                color:
                    Color(0xFFFBBF24),
              ),

              const SizedBox(height: 25),

              const Text(
                'لا يوجد اتصال بالإنترنت',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'يرجى التأكد من اتصال الهاتف بالإنترنت ثم المحاولة مرة أخرى.',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(

                onPressed:
                    _checkInternet,

                icon: const Icon(
                  Icons.refresh,
                ),

                label: const Text(
                  'إعادة المحاولة',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                          0xFF6366F1),

                  foregroundColor:
                      Colors.white,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 25,
                    vertical: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // شاشة الخطأ
  // =========================================================

  Widget _buildErrorScreen() {

    return Container(
      color: const Color(0xFF0F172A),

      child: Center(

        child: Padding(
          padding:
              const EdgeInsets.all(30),

          child: Column(

            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              const Icon(
                Icons
                    .cloud_off_rounded,
                size: 75,
                color:
                    Color(0xFFFBBF24),
              ),

              const SizedBox(height: 25),

              const Text(
                'تعذر تحميل المنظومة',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'حدث خطأ أثناء الاتصال بالموقع. حاول مرة أخرى.',
                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(

                onPressed:
                    _reloadWebsite,

                icon: const Icon(
                  Icons.refresh,
                ),

                label: const Text(
                  'إعادة تحميل',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                          0xFF6366F1),

                  foregroundColor:
                      Colors.white,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 25,
                    vertical: 13,
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