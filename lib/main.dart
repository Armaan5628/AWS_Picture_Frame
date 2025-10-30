import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() => runApp(const DigitalPictureFrameApp());

class DigitalPictureFrameApp extends StatelessWidget {
  const DigitalPictureFrameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Digital Picture Frame",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        useMaterial3: true,
      ),
      home: const PictureFrame(),
    );
  }
}

class PictureFrame extends StatefulWidget {
  const PictureFrame({super.key});

  @override
  State<PictureFrame> createState() => _PictureFrameState();
}

class _PictureFrameState extends State<PictureFrame> with TickerProviderStateMixin {
  // 👇 Replace with your real AWS S3 .jpg image URLs
  final List<String> imageUrls = const [
    "https://amzn-s3-mustang-bucket.s3.us-east-2.amazonaws.com/2022+ford.jpg",
    "https://amzn-s3-mustang-bucket.s3.us-east-2.amazonaws.com/2023.jpg",
    "https://amzn-s3-mustang-bucket.s3.us-east-2.amazonaws.com/2024.jpg",
    "https://amzn-s3-mustang-bucket.s3.us-east-2.amazonaws.com/gtd.jpg",
  ];

  int _index = 0;
  bool _paused = false;
  Timer? _timer;

  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    _fadeCtrl.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_paused) {
        setState(() {
          _index = (_index + 1) % imageUrls.length;
          _fadeCtrl
            ..reset()
            ..forward();
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = imageUrls[_index];

    return SafeArea(
      child: Stack(
        children: [
          // 🖼 The main image with custom frame
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dpr = MediaQuery.of(context).devicePixelRatio;
                  final memCacheWidth = (constraints.maxWidth * dpr).round();

                  return CustomPaint(
                    painter: PineappleFramePainter(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: FadeTransition(
                          opacity: _fade,
                          child: CachedNetworkImage(
                            imageUrl: currentUrl,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            memCacheWidth: memCacheWidth,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(color: Colors.yellow),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Text(
                                "Failed to load image",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 🕹 Control buttons (Pause / Resume)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: _togglePause,
                icon: Icon(
                  _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: Colors.black,
                  size: 26,
                ),
                label: Text(
                  _paused ? "Resume Slideshow" : "Pause Slideshow",
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 Pineapple-style golden frame
class PineappleFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Rect.fromLTWH(0, 0, size.width, size.height);
    final inner = Rect.fromLTWH(20, 20, size.width - 40, size.height - 40);

    final border = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD36E), Color(0xFFB8891E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(outer);

    final matte = Paint()..color = const Color(0xFF0B0C10);

    final outerR = RRect.fromRectAndRadius(outer, const Radius.circular(30));
    final innerR = RRect.fromRectAndRadius(inner, const Radius.circular(20));

    canvas.drawRRect(outerR, border);
    canvas.drawRRect(innerR, matte);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
