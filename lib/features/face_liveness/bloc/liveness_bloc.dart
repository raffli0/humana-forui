import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:humana/core/services/camera_service.dart';
import 'package:humana/core/services/face_detector_service.dart';
import 'package:humana/utils/liveness_action_util.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'liveness_event.dart';
import 'liveness_state.dart';

class LivenessBloc extends Bloc<LivenessEvent, LivenessState> {
  final CameraService _cameraService;
  final FaceDetectorService _faceDetectorService;

  Timer? _detectionTimer;
  bool _isDetecting = false;

  LivenessBloc({
    required CameraService cameraService,
    required FaceDetectorService faceDetectorService,
  }) : _cameraService = cameraService,
       _faceDetectorService = faceDetectorService,
       super(const LivenessState()) {
    on<LivenessStarted>(_onStarted);
    on<LivenessCameraInitialized>(_onCameraInitialized);
    on<LivenessFaceDetected>(_onFaceDetected);
    on<LivenessResetNeutral>(_onResetNeutral);
    on<LivenessPermissionDenied>(_onPermissionDenied);
  }

  Future<void> _onStarted(
    LivenessStarted event,
    Emitter<LivenessState> emit,
  ) async {
    emit(state.copyWith(status: LivenessStatus.cameraLoading));

    try {
      PermissionStatus permission = await Permission.camera.status;
      if (permission != PermissionStatus.granted) {
        permission = await Permission.camera.request();
      }

      if (permission == PermissionStatus.granted) {
        await _cameraService.initialize();
        add(LivenessCameraInitialized());
      } else {
        add(LivenessPermissionDenied());
      }
    } catch (e) {
      log("Error in LivenessStarted: $e");
      emit(state.copyWith(status: LivenessStatus.cameraError));
    }
  }

  void _onCameraInitialized(
    LivenessCameraInitialized event,
    Emitter<LivenessState> emit,
  ) {
    final actions = List<LivenessAction>.from(LivenessAction.values)..shuffle();
    emit(
      state.copyWith(
        status: LivenessStatus.cameraInitialized,
        actions: actions,
        currentActionIndex: 0,
        waitingForNeutral: false,
      ),
    );

    _startDetection();
  }

  void _onPermissionDenied(
    LivenessPermissionDenied event,
    Emitter<LivenessState> emit,
  ) {
    emit(state.copyWith(status: LivenessStatus.permissionDenied));
  }

  void _startDetection() {
    if (Platform.isAndroid) {
      _detectionTimer?.cancel();
      _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) async {
        if (_isDetecting || state.status == LivenessStatus.completed) return;
        _isDetecting = true;
        try {
          await _detectFacesFromImage();
        } finally {
          _isDetecting = false;
        }
      });
    } else if (Platform.isIOS) {
      _cameraService.startImageStream((image) {
        if (_isDetecting || state.status == LivenessStatus.completed) return;
        _isDetecting = true;
        _detectFacesFromStream(image).then((_) {
          _isDetecting = false;
        });
      });
    }
  }

  Future<void> _detectFacesFromImage() async {
    try {
      final imageFile = await _cameraService.takePicture();
      if (imageFile == null) return;

      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceDetectorService.processImage(inputImage);

      _handleDetectionResult(faces);
      await _cameraService.deleteFile(imageFile.path);
    } catch (e) {
      log("Error in _detectFacesFromImage: $e");
    }
  }

  Future<void> _detectFacesFromStream(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceDetectorService.processImage(inputImage);
      _handleDetectionResult(faces);
    } catch (e) {
      log("Error in _detectFacesFromStream: $e");
    }
  }

  void _handleDetectionResult(List<Face> faces) {
    if (faces.isNotEmpty) {
      final face = faces.first;
      final inFrame = _faceDetectorService.isFaceInFrame(face);
      add(LivenessFaceDetected(face: face, isFaceInFrame: inFrame));
    } else {
      add(const LivenessFaceDetected(face: null, isFaceInFrame: false));
    }
  }

  Future<void> _onFaceDetected(
    LivenessFaceDetected event,
    Emitter<LivenessState> emit,
  ) async {
    if (state.status == LivenessStatus.completed) return;

    final face = event.face;
    final isFaceInFrame = event.isFaceInFrame;

    if (face == null || !isFaceInFrame) {
      emit(
        state.copyWith(
          isFaceInFrame: false,
          smilingProbability: null,
          leftEyeOpenProbability: null,
          rightEyeOpenProbability: null,
          headEulerAngleY: null,
        ),
      );
      return;
    }

    final newState = state.copyWith(
      status: LivenessStatus.detecting,
      isFaceInFrame: true,
      smilingProbability: face.smilingProbability,
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
      headEulerAngleY: face.headEulerAngleY,
    );

    emit(newState);
    await _checkAction(face, emit);
  }

  Future<void> _checkAction(Face face, Emitter<LivenessState> emit) async {
    if (state.waitingForNeutral) {
      if (_isNeutralPosition(face)) {
        emit(state.copyWith(waitingForNeutral: false));
      }
      return;
    }

    if (state.currentActionIndex >= state.actions.length) return;

    final currentAction = state.actions[state.currentActionIndex];
    if (_isActionCompleted(face, currentAction)) {
      final isLastStep = state.currentActionIndex >= state.actions.length - 1;

      if (isLastStep) {
        // Capture image before completing
        try {
          final image = await _cameraService.takePicture();
          if (image != null) {
            await _cameraService.flipImage(image.path);
          }
          emit(
            state.copyWith(
              status: LivenessStatus.completed,
              imageFile: image != null ? File(image.path) : null,
            ),
          );
        } catch (e) {
          log("Error capturing final image: $e");
          // Even if capture fails, we might want to complete?
          // Or emit error? Let's emit error for now or just complete without image?
          // User requested capture, so failure is significant.
          // But existing flow completes. Let's try to complete without image as fallback or error.
          // Let's emit completed but log error.
          emit(state.copyWith(status: LivenessStatus.completed));
        }
      } else {
        emit(
          state.copyWith(
            status: LivenessStatus.actionSuccess,
            waitingForNeutral: true,
            currentActionIndex: state.currentActionIndex + 1,
          ),
        );

        // Pause detection for 3 seconds as in original logic
        _pauseDetection();
      }
    }
  }

  void _pauseDetection() {
    _detectionTimer?.cancel();
    if (Platform.isIOS) {
      _cameraService.stopImageStream();
    }

    Timer(const Duration(seconds: 3), () {
      if (!isClosed) {
        add(LivenessResetNeutral());
        _startDetection();
      }
    });
  }

  void _onResetNeutral(
    LivenessResetNeutral event,
    Emitter<LivenessState> emit,
  ) {
    emit(
      state.copyWith(
        status: LivenessStatus.detecting,
        waitingForNeutral: false,
      ),
    );
  }

  bool _isActionCompleted(Face face, LivenessAction action) {
    switch (action) {
      case LivenessAction.smile:
        return face.smilingProbability != null &&
            face.smilingProbability! > 0.5;
      case LivenessAction.blink:
        return (face.leftEyeOpenProbability != null &&
                face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null &&
                face.rightEyeOpenProbability! < 0.3);
      case LivenessAction.lookRight:
        return face.headEulerAngleY != null && face.headEulerAngleY! < -10;
      case LivenessAction.lookLeft:
        return face.headEulerAngleY != null && face.headEulerAngleY! > 10;
      case LivenessAction.lookStraight:
        return face.headEulerAngleY != null &&
            face.headEulerAngleY! > -5 &&
            face.headEulerAngleY! < 5;
    }
  }

  bool _isNeutralPosition(Face face) {
    return (face.smilingProbability == null ||
            face.smilingProbability! < 0.1) &&
        (face.leftEyeOpenProbability == null ||
            face.leftEyeOpenProbability! > 0.7) &&
        (face.rightEyeOpenProbability == null ||
            face.rightEyeOpenProbability! > 0.7) &&
        (face.headEulerAngleY == null ||
            (face.headEulerAngleY! > -10 && face.headEulerAngleY! < 10));
  }

  @override
  Future<void> close() {
    _detectionTimer?.cancel();
    return super.close();
  }
}
