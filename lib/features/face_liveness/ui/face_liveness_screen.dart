import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:humana/core/services/camera_service.dart';
import 'package:humana/core/services/face_detector_service.dart';
import '../bloc/liveness_bloc.dart';
import '../bloc/liveness_event.dart';
import '../bloc/liveness_state.dart';
import 'widgets/face_liveness_action_text.dart';
import 'widgets/face_liveness_dashbord.dart';
import 'widgets/face_liveness_painter.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceLivenessScreen extends StatelessWidget {
  final Function(File? image)? callback;

  const FaceLivenessScreen({super.key, this.callback});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => CameraService(),
          dispose: (service) => service.dispose(),
        ),
        RepositoryProvider(
          create: (_) => FaceDetectorService(),
          dispose: (service) => service.dispose(),
        ),
      ],
      child: BlocProvider(
        create: (context) => LivenessBloc(
          cameraService: context.read<CameraService>(),
          faceDetectorService: context.read<FaceDetectorService>(),
        )..add(LivenessStarted()),
        child: FaceLivenessView(callback: callback),
      ),
    );
  }
}

class FaceLivenessView extends StatelessWidget {
  final Function(File? image)? callback;

  const FaceLivenessView({super.key, this.callback});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LivenessBloc, LivenessState>(
      listener: (context, state) {
        if (state.status == LivenessStatus.completed) {
          callback?.call(state.imageFile);
          Navigator.of(context).pop();
        } else if (state.status == LivenessStatus.permissionDenied) {
          _showPermissionDeniedDialog(context);
        }
      },
      builder: (context, state) {
        final cameraService = context.read<CameraService>();

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              "Liveness Detection",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios),
            ),
          ),
          body: _buildBody(context, state, cameraService),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    LivenessState state,
    CameraService cameraService,
  ) {
    if (state.status == LivenessStatus.cameraLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (state.status == LivenessStatus.permissionDenied ||
        state.status == LivenessStatus.cameraError) {
      return const Center(
        child: Text(
          "Camera access is required for this feature.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (!cameraService.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      children: [
        // Camera Preview (Clipped)
        Positioned.fill(
          child: Center(
            child: ClipOval(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.45,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: AspectRatio(
                      aspectRatio: cameraService.aspectRatio == 0
                          ? 1.0
                          : 1 / cameraService.aspectRatio,
                      child: CameraPreview(cameraService.controller!),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Face Overlay (Border Only)
        Positioned.fill(
          child: CustomPaint(
            painter: FaceLivenessPainter(
              waitingForNeutral: state.waitingForNeutral,
              isFaceInFrame: state.isFaceInFrame,
              ovalWidth: MediaQuery.of(context).size.width * 0.7,
              ovalHeight: MediaQuery.of(context).size.height * 0.45,
            ),
          ),
        ),

        // Text Action
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 16,
          right: 16,
          child: FaceLivenessActionText(action: state.currentAction),
        ),

        // Dashboard
        Positioned(
          bottom: 16,
          left: 16,
          child: FaceLivenessDashbord(
            smilingProbability: state.smilingProbability,
            leftEyeOpenProbability: state.leftEyeOpenProbability,
            rightEyeOpenProbability: state.rightEyeOpenProbability,
            headEulerAngleY: state.headEulerAngleY,
            waitingForNeutral: state.waitingForNeutral,
            isFaceInFrame: state.isFaceInFrame,
            currentActionIndex: state.currentActionIndex,
            livenessActionsTotal: state.actions.length,
          ),
        ),
      ],
    );
  }

  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Camera Permission Required"),
          content: const Text(
            "This feature requires access to the camera.\n\n"
            "Please enable camera permission in settings.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit screen
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit screen
                await openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }
}
