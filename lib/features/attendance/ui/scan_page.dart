import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:humana/core/theme/app_colors.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage>
    with SingleTickerProviderStateMixin {
  // CAMERA
  CameraController? cameraController;

  // ML KIT
  late FaceDetector faceDetector;
  Rect? faceRect;
  bool faceFound = false;
  bool faceInsideOval = false;
  bool blinkDetected = false;

  // BLINK STATE
  bool wasOpen = false;
  bool isClosing = false;
  bool blinkDone = false;
  int debugFrame = 0; // ← INI YANG WAJIB ADA DI SINI

  // COUNTDOWN
  int countdown = 3;
  Timer? countdownTimer;

  // SCAN LINE ANIMATION
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();

    /// START LASER SCAN ANIMATION
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: -80, end: 80).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    /// INIT ML KIT
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    /// INIT CAMERA
    _initCamera();
  }

  @override
  void dispose() {
    _scanController.dispose();
    cameraController?.dispose();
    faceDetector.close();
    countdownTimer?.cancel();
    super.dispose();
  }

  // ===============================================================
  // CAMERA INIT
  // ===============================================================
  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await cameraController!.initialize();

    cameraController!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  // ===============================================================
  // PROCESS CAMERA IMAGE → FACE DETECTION + BLINK
  // ===============================================================
  Future<void> _processCameraImage(CameraImage image) async {
    if (blinkDetected) return;

    // Convert image to ML Kit input
    final WriteBuffer buffer = WriteBuffer();
    for (var plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }

    final bytes = buffer.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: imageSize,
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    // Detect faces
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      setState(() {
        faceFound = false;
        faceInsideOval = false;
        faceRect = null;
      });
      return;
    }

    faceFound = true;
    faceRect = faces.first.boundingBox;

    // Check if inside oval frame
    if (!mounted) return;
    final scanRect = _scanFrame(context);

    final faceCenter = faceRect!.center;
    faceInsideOval = scanRect.contains(faceCenter);

    if (faceInsideOval && countdown == 3) {
      _startCountdown();
    }

    // BLINK DETECTION
    // BLINK DETECTION (OPEN → CLOSED → OPEN)
    // if (countdown == 0 && !blinkDone) {
    //   final face = faces.first;

    //   final left = face.leftEyeOpenProbability ?? 1;
    //   final right = face.rightEyeOpenProbability ?? 1;

    //   final bothOpen = left > 0.6 && right > 0.6;
    //   final bothClosed = left < 0.45 && right < 0.45;

    //   // tahap 1: mata terbuka dulu
    //   if (bothOpen && !isClosing) {
    //     wasOpen = true;
    //   }

    //   // tahap 2: mata tertutup (blink phase)
    //   if (wasOpen && bothClosed) {
    //     isClosing = true;
    //   }

    //   // tahap 3: buka lagi → blink completed
    //   if (isClosing && bothOpen) {
    //     blinkDone = true;

    //     cameraController!.stopImageStream();
    //     final file = await cameraController!.takePicture();

    //     if (mounted) Navigator.pop(context, file.path);
    //   }
    // }

    // DEBUG FRAME COUNTER
    debugFrame++;

    // BLINK DETECTION (OPEN → CLOSED → OPEN)
    if (countdown == 0 && !blinkDone) {
      final face = faces.first;

      final left = face.leftEyeOpenProbability ?? -1;
      final right = face.rightEyeOpenProbability ?? -1;

      final bothOpen = left > 0.6 && right > 0.6;
      final bothClosed = left < 0.45 && right < 0.45;

      // DEBUG

      // tahap 1 — mata terbuka
      if (bothOpen && !isClosing) {
        if (!wasOpen) debugPrint("EVENT: Mata terbuka (wasOpen = true)");
        wasOpen = true;
      }

      // tahap 2 — mata tertutup
      if (wasOpen && bothClosed) {
        if (!isClosing) debugPrint("EVENT: Mata tertutup (isClosing = true)");
        isClosing = true;
      }

      // tahap 3 — mata terbuka kembali setelah tertutup
      if (isClosing && bothOpen) {
        debugPrint("EVENT: BLINK TERDETEKSI");
        blinkDone = true;

        cameraController!.stopImageStream();
        final file = await cameraController!.takePicture();

        debugPrint("EVENT: Foto berhasil diambil → ${file.path}");

        if (mounted) Navigator.pop(context, file.path);
      }
    }

    setState(() {});
  }

  // ===============================================================
  // COUNTDOWN
  // ===============================================================
  void _startCountdown() {
    countdownTimer?.cancel();
    countdown = 3;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() => countdown--);
      if (countdown == 0) {
        timer.cancel();
        if (faceFound && faceInsideOval && !blinkDone) {
          debugPrint("EVENT: AUTO CAPTURE TRIGGERED");
          blinkDone = true;
          cameraController!.stopImageStream();
          final file = await cameraController!.takePicture();
          if (mounted) Navigator.pop(context, file.path);
        }
      }
    });
  }

  // ===============================================================
  // OVAL POSITION
  // ===============================================================
  Rect _scanFrame(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // Rectangle with rounded corners aspect
    return Rect.fromCenter(
      center: Offset(w / 2, h * 0.4),
      width: w * 0.8,
      height: w * 0.8 * 1.2, // 4:5 aspect ratio
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.accent,
      body: Stack(
        children: [
          /// CAMERA PREVIEW
          Positioned.fill(
            child:
                cameraController == null ||
                    !cameraController!.value.isInitialized
                ? Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        "Loading Camera...",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                : Positioned.fill(
                    child: Transform.scale(
                      scale: cameraController!.value.aspectRatio,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1 / cameraController!.value.aspectRatio,
                          child: CameraPreview(cameraController!),
                        ),
                      ),
                    ),
                  ),
          ),

          /// FACE FRAME + SCAN LINE
          Center(
            child: SizedBox(
              // Should match _scanFrame size approximately or use LayoutBuilder
              // For simplicity, we use the same proportional sizing if possible
              // But here we use a fixed size container to match the rect logic roughly
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8 * 1.2,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accentSecondary.withValues(alpha: 0.3),
                          blurRadius: 35,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  AnimatedBuilder(
                    animation: _scanController,
                    builder: (_, child) {
                      return Transform.translate(
                        offset: Offset(0, _scanAnimation.value),
                        child: Container(
                          width: 230,
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                colors.accentSecondary.withValues(alpha: 0),
                                colors.accentSecondary,
                                colors.accentSecondary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          /// TOP BAR
          Positioned(
            top: 55,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Face Scan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),

          /// FLASH + SWITCH CAMERA BUTTONS
          Positioned(
            top: 120,
            right: 20,
            child: Column(
              children: [
                _circleButton(icon: CupertinoIcons.bolt_fill, onTap: () {}),
                const SizedBox(height: 16),
                _circleButton(icon: CupertinoIcons.switch_camera, onTap: () {}),
              ],
            ),
          ),

          /// INFO CARD
          Positioned(
            bottom: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const Text(
                    "Preparing Face Scan",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    faceFound
                        ? (faceInsideOval
                              ? "Hold still until capture"
                              : "Align your face inside the frame")
                        : "Position your face inside the frame",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// COUNTDOWN
          if (faceInsideOval && countdown > 0)
            Center(
              child: Text(
                "$countdown",
                style: const TextStyle(
                  fontSize: 110,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 20)],
                ),
              ),
            ),

          /// BUTTON
          Positioned(
            bottom: 45,
            left: 40,
            right: 40,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: LinearGradient(
                    colors: [colors.surface, colors.surface],
                  ),
                ),
                child: const Center(
                  child: Text(
                    "Scan Face",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
