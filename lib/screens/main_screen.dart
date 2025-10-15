import 'package:flutter/material.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late AnimationController _plusOneController;

  double _plusOneOpacity = 0;
  int _cloverCount = 0;
  double? _cloverX;
  double? _cloverY;
  bool _cloverVisible = true;
  static const double centerBoxSize = 120.0;
  static const double boxRadius = 24.0;
  Offset? _lastCloverPosition;

  final List<ActiveConfetti> _confettiList = [];
  static const int confettiDuration = 600;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: pi / 30).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _plusOneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
      setState(() {
        _plusOneOpacity = 1.0 - _plusOneController.value;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _setInitialCloverPosition(context));
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final confetti in _confettiList) {
      confetti.dispose();
    }
    _plusOneController.dispose();
    super.dispose();
  }

  void _cleanupConfetti() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _confettiList.removeWhere((e) {
      final shouldRemove = now > e.expireTime;
      if (shouldRemove) {
        e.dispose();
      }
      return shouldRemove;
    });
  }

  void _setInitialCloverPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeRadius = centerBoxSize * 0.62;
    final center = Offset(screenWidth / 2, screenHeight / 2);

    Offset pos;
    int tries = 0;
    do {
      final x = 60 + Random().nextDouble() * (screenWidth - 120);
      final y = 60 + Random().nextDouble() * (screenHeight - 120);
      pos = Offset(x, y);
      tries++;
      if (tries > 100) break;
    } while ((pos - center).distance < safeRadius);

    setState(() {
      _cloverX = pos.dx / screenWidth;
      _cloverY = pos.dy / screenHeight;
      _lastCloverPosition = Offset(pos.dx, pos.dy);
    });
  }

  void _moveCloverSafe(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeRadius = centerBoxSize * 0.62;
    final center = Offset(screenWidth / 2, screenHeight / 2);

    Offset newPos;
    int tries = 0;
    do {
      final x = 60 + Random().nextDouble() * (screenWidth - 120);
      final y = 60 + Random().nextDouble() * (screenHeight - 120);
      newPos = Offset(x, y);
      tries++;
      if (tries > 100) break;
    } while ((newPos - center).distance < safeRadius);

    setState(() {
      _cloverX = newPos.dx / screenWidth;
      _cloverY = newPos.dy / screenHeight;
    });
  }

  void _showPlusOne(Offset cloverCenter) async {
    setState(() {
      _plusOneOpacity = 1.0;
      _lastCloverPosition = cloverCenter;
    });
    _plusOneController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 180));
    setState(() {
      _plusOneOpacity = 0.0;
    });
  }

  void _onCloverPressed() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double cloverDx = (screenWidth * (_cloverX ?? 0)) - 60 + 60;
    double cloverDy = (screenHeight * (_cloverY ?? 0)) - 60 + 60;
    Offset cloverCenter = Offset(cloverDx, cloverDy);

    setState(() {
      _cloverCount++;
      _cloverVisible = false;
    });
    _showPlusOne(cloverCenter);
    _controller.forward(from: 0.0);

    // 각 위치별 confetti 위젯 추가 (컨페티량·지속시간 최적화)
    final now = DateTime.now().millisecondsSinceEpoch;
    final cloverController = ConfettiController(
      duration: Duration(milliseconds: confettiDuration),
    );
    final coinController = ConfettiController(
      duration: Duration(milliseconds: confettiDuration),
    );
    cloverController.play();
    coinController.play();
    setState(() {
      _confettiList.add(
        ActiveConfetti(
          position: cloverCenter,
          cloverController: cloverController,
          coinController: coinController,
          expireTime: now + confettiDuration,
        ),
      );
    });
    _moveCloverSafe(context);

    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _cloverVisible = true;
      _cleanupConfetti();
    });
  }

  Path _drawCloverConfetti(Size size) {
    final Path path = Path();
    final double r = size.width / 2.7;
    for (int i = 0; i < 4; i++) {
      final double theta = (pi / 2) * i;
      final double x = r * cos(theta);
      final double y = r * sin(theta);
      path.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
    }
    return path;
  }

  Path _drawCoin(Size size) {
    final double r = size.width / 2.2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Path outer = Path()..addOval(Rect.fromCircle(center: center, radius: r));
    final Path inner = Path()..addOval(Rect.fromCircle(center: center, radius: r * 0.65));
    return Path.combine(PathOperation.difference, outer, inner);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    _cleanupConfetti();

    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Stack(
        children: [
          Center(
            child: CustomPaint(
              painter: GoldAuraBoxPainter(),
              child: Container(
                width: centerBoxSize,
                height: centerBoxSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(boxRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lucky-Bank',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                        fontFamily: 'Raleway',
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      '$_cloverCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 여러 위치 동시 confetti
          ..._confettiList.map((c) => Positioned(
            left: c.position.dx - 60,
            top: c.position.dy - 60,
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ConfettiWidget(
                    confettiController: c.cloverController,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 7,
                    maxBlastForce: 25,
                    minBlastForce: 10,
                    emissionFrequency: 0.09,
                    shouldLoop: false,
                    createParticlePath: _drawCloverConfetti,
                  ),
                  ConfettiWidget(
                    confettiController: c.coinController,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 5,
                    maxBlastForce: 25,
                    minBlastForce: 10,
                    emissionFrequency: 0.11,
                    shouldLoop: false,
                    colors: [Colors.amber, Colors.yellow, Colors.orange],
                    createParticlePath: _drawCoin,
                  ),
                ],
              ),
            ),
          )),
          if (_plusOneOpacity > 0 && _lastCloverPosition != null)
            Positioned(
              left: _lastCloverPosition!.dx - 12,
              top: _lastCloverPosition!.dy - 32,
              child: AnimatedOpacity(
                opacity: _plusOneOpacity,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Text(
                  '+1',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.withOpacity(0.7),
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          (_cloverX != null && _cloverY != null)
              ? Positioned(
            left: screenWidth * _cloverX! - 60,
            top: screenHeight * _cloverY! - 60,
            child: Visibility(
              visible: _cloverVisible,
              child: GestureDetector(
                onTap: _onCloverPressed,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/clover.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ),
          )
              : SizedBox.shrink(),
        ],
      ),
    );
  }
}

class GoldAuraBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final RRect outerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(_MainScreenState.boxRadius),
    );
    // 바깥쪽 금빛 오라
    final Rect gradientRect = Rect.fromLTWH(-16, -16, size.width + 32, size.height + 32);
    final Gradient gradient = RadialGradient(
      center: Alignment.center,
      colors: [
        Colors.transparent,
        Colors.amber.shade300.withOpacity(0.7),
        Colors.orangeAccent.shade200.withOpacity(0.88),
        Colors.amber.shade800.withOpacity(0.93),
        Colors.transparent,
      ],
      stops: [0.74, 0.88, 0.93, 0.98, 1.0],
      radius: 0.9,
    );
    canvas.saveLayer(gradientRect, Paint());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-7, -7, size.width + 14, size.height + 14),
        Radius.circular(_MainScreenState.boxRadius + 10),
      ),
      Paint()
        ..shader = gradient.createShader(gradientRect)
        ..style = PaintingStyle.fill,
    );
    // 네모 clip
    canvas.drawRRect(
      outerRect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..color = Colors.white,
    );
    canvas.restore();
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ActiveConfetti {
  final Offset position;
  final ConfettiController cloverController;
  final ConfettiController coinController;
  final int expireTime;

  ActiveConfetti({
    required this.position,
    required this.cloverController,
    required this.coinController,
    required this.expireTime,
  });

  void dispose() {
    cloverController.dispose();
    coinController.dispose();
  }
}
