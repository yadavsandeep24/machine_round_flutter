import 'package:equatable/equatable.dart';

enum FaqCategory { payments, refunds, security }

class FaqItem extends Equatable {
  const FaqItem({required this.id, required this.question, required this.answer, required this.category});

  /// Stable id so deep links (`/?open=declined`) and expansion state survive filtering.
  final String id;
  final String question;
  final String answer;
  final FaqCategory category;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || question.toLowerCase().contains(q) || answer.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [id, question, answer, category];
}
