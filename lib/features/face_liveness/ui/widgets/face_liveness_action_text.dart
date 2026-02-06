import 'package:flutter/material.dart';
import 'package:humana/utils/liveness_action_util.dart';

class FaceLivenessActionText extends StatelessWidget {
  final LivenessAction? action;

  const FaceLivenessActionText({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final String label = LivenessActionUtil.getActionLabel(action);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
