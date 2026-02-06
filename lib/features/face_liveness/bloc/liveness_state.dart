import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:humana/utils/liveness_action_util.dart';

enum LivenessStatus {
  initial,
  cameraLoading,
  cameraInitialized,
  cameraError,
  detecting,
  actionSuccess,
  completed,
  permissionDenied,
}

class LivenessState extends Equatable {
  final LivenessStatus status;
  final List<LivenessAction> actions;
  final int currentActionIndex;
  final bool waitingForNeutral;
  final bool isFaceInFrame;
  final double? smilingProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? headEulerAngleY;
  final File? imageFile;

  const LivenessState({
    this.status = LivenessStatus.initial,
    this.actions = const [],
    this.currentActionIndex = 0,
    this.waitingForNeutral = false,
    this.isFaceInFrame = false,
    this.smilingProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.headEulerAngleY,
    this.imageFile,
  });

  LivenessAction? get currentAction =>
      (currentActionIndex < actions.length &&
          status != LivenessStatus.completed &&
          isFaceInFrame)
      ? actions[currentActionIndex]
      : null;

  LivenessState copyWith({
    LivenessStatus? status,
    List<LivenessAction>? actions,
    int? currentActionIndex,
    bool? waitingForNeutral,
    bool? isFaceInFrame,
    double? smilingProbability,
    double? leftEyeOpenProbability,
    double? rightEyeOpenProbability,
    double? headEulerAngleY,
    File? imageFile,
  }) {
    return LivenessState(
      status: status ?? this.status,
      actions: actions ?? this.actions,
      currentActionIndex: currentActionIndex ?? this.currentActionIndex,
      waitingForNeutral: waitingForNeutral ?? this.waitingForNeutral,
      isFaceInFrame: isFaceInFrame ?? this.isFaceInFrame,
      smilingProbability: smilingProbability ?? this.smilingProbability,
      leftEyeOpenProbability:
          leftEyeOpenProbability ?? this.leftEyeOpenProbability,
      rightEyeOpenProbability:
          rightEyeOpenProbability ?? this.rightEyeOpenProbability,
      headEulerAngleY: headEulerAngleY ?? this.headEulerAngleY,
      imageFile: imageFile ?? this.imageFile,
    );
  }

  @override
  List<Object?> get props => [
    status,
    actions,
    currentActionIndex,
    waitingForNeutral,
    isFaceInFrame,
    smilingProbability,
    leftEyeOpenProbability,
    rightEyeOpenProbability,
    headEulerAngleY,
    imageFile,
  ];
}
