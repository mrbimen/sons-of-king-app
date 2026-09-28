import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // لفحص هل التطبيق يعمل على المتصفح أم لا
import 'package:webview_flutter/webview_flutter.dart'; // مكتبة المتصفح المدمج للموبايل
import 'dart:io' show Platform; // لفحص نظام التشغيل

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: const Color(0xFF0F172A), // اللون الداكن للمنظومة
        useMaterial3: true,
      ),
      home: const MainWebViewScreen(),
    );
  }
}

class MainWebViewScreen extends StatefulWidget {
  const MainWebViewScreen({super.key});

  @override
  State<MainWebViewScreen> createState() => _MainWebViewScreenState();
}
class _MainWebViewScreenState extends State<MainWebViewScreen> {
  WebViewController? _webController; // جعل المحرك اختياري تجنباً لانهيار الويب
  bool _isLoadingPage = true;
  bool _isMobilePlatform = false; // متغير لتحديد هل الجهاز موبايل أم كمبيوتر

  @override
  void initState() {
    super.initState();
    
    // فحص ذكي: إذا كان التطبيق لا يعمل على الويب (المتصفح) وكان الجهاز أندرويد أو آيفون
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _isMobilePlatform = true;
      
      // تهيئة محرك الموبايل بأمان كامل
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0F172A))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() => _isLoadingPage = true);
            },
            onPageFinished: (String url) {
              setState(() => _isLoadingPage = false);
            },
          ),
        )
        ..loadRequest(Uri.parse('https://sons-of-king.html-5.me'));
    } else {
      // إذا كان يعمل على المتصفح أو الويندوز، نلغي مؤشر التحميل فوراً ليعرض الواجهة البديلة
      _isLoadingPage = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // إذا كان الجهاز موبايل يعرض الـ WebView القياسي
            if (_isMobilePlatform && _webController != null)
              WebViewWidget(controller: _webController!)
            else
              // إذا كان جهاز كمبيوتر أو متصفح يعرض هذه الواجهة الاحترافية البديلة بدون انهيار
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.important_devices_rounded, size: 70, color: Color(0xFFFBBF24)),
                      const SizedBox(height: 18),
                      const Text(
                        'منظومة أولاد الملك الرقمية',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'أنت تتصفح المنظومة الآن من بيئة تطوير الويب/الكمبيوتر يرجى فتح الموقع مباشرة في المتصفح للاختبار السريع:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      SelectableText(
                        'https://sons-of-king.html-5.me',
                        style: TextStyle(color: Colors.blueAccent.shade100, fontSize: 15, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
            
            // مؤشر التحميل يظهر فقط عند تشغيل الموبايل البداية
            if (_isLoadingPage && _isMobilePlatform)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF6366F1)),
                    SizedBox(height: 12),
                    Text(
                      'جاري الاتصال بالمنظومة التقنية...',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
