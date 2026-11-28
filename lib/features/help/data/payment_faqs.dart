import '../domain/faq_item.dart';

/// Static content for the demo. A real app would fetch this from a CMS and cache it.
const paymentFaqs = <FaqItem>[
  FaqItem(
    id: 'declined',
    question: 'Why was my payment declined?',
    answer: 'Your bank may have blocked it for low balance, a daily limit, or a failed OTP. No money was taken.',
    category: FaqCategory.payments,
  ),
  FaqItem(
    id: 'pending',
    question: 'My payment is pending. What now?',
    answer: 'Pending payments settle within 48 hours. If it fails, the amount is returned to your account.',
    category: FaqCategory.payments,
  ),
  FaqItem(
    id: 'refund-time',
    question: 'How long does a refund take?',
    answer: 'UPI refunds take up to 2 working days. Card refunds take 5 to 7 working days.',
    category: FaqCategory.refunds,
  ),
  FaqItem(
    id: 'partial-refund',
    question: 'Can I get a partial refund?',
    answer: 'Yes. The merchant decides the amount. You will see each refund as its own line in history.',
    category: FaqCategory.refunds,
  ),
  FaqItem(
    id: 'card-safe',
    question: 'Is my card number stored?',
    answer: 'No. We keep a network token, never the full card number or the CVV.',
    category: FaqCategory.security,
  ),
];
