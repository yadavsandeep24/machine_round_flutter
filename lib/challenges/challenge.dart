import 'package:flutter/widgets.dart';

enum ChallengeKind { bug, optimisation }

class Challenge {
  const Challenge({
    required this.number,
    required this.title,
    required this.kind,
    required this.symptom,
    required this.reproduce,
    required this.rootCause,
    required this.fix,
    required this.buggy,
    required this.fixed,
  });

  final int number;
  final String title;
  final ChallengeKind kind;

  /// What the bug report / interviewer says.
  final String symptom;
  final String reproduce;
  final String rootCause;
  final String fix;
  final WidgetBuilder buggy;
  final WidgetBuilder fixed;
}
