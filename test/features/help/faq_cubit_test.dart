import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:machine_round/features/help/data/payment_faqs.dart';
import 'package:machine_round/features/help/presentation/faq_cubit.dart';

void main() {
  FaqCubit build({String? open}) => FaqCubit(paymentFaqs, initiallyOpen: open);

  test('deep link opens a known id and ignores an unknown one', () {
    expect(build(open: 'declined').state.expanded, {'declined'});
    expect(build(open: 'nope').state.expanded, isEmpty);
  });

  blocTest<FaqCubit, FaqState>(
    'accordion mode keeps only one item open',
    build: build,
    act: (cubit) => cubit
      ..toggle('declined')
      ..toggle('pending'),
    verify: (cubit) => expect(cubit.state.expanded, {'pending'}),
  );

  blocTest<FaqCubit, FaqState>(
    'toggling an open item closes it',
    build: () => build(open: 'declined'),
    act: (cubit) => cubit.toggle('declined'),
    verify: (cubit) => expect(cubit.state.expanded, isEmpty),
  );

  blocTest<FaqCubit, FaqState>(
    'multi mode lets several items stay open',
    build: build,
    act: (cubit) => cubit
      ..setSingleOpen(false)
      ..toggle('declined')
      ..toggle('pending'),
    verify: (cubit) => expect(cubit.state.expanded, {'declined', 'pending'}),
  );

  blocTest<FaqCubit, FaqState>(
    'expand all opens every visible item and switches to multi mode',
    build: build,
    act: (cubit) => cubit
      ..setQuery('refund')
      ..expandAll(),
    verify: (cubit) {
      expect(cubit.state.singleOpen, isFalse);
      expect(cubit.state.expanded, {'refund-time', 'partial-refund'});
    },
  );

  blocTest<FaqCubit, FaqState>(
    'switching back to accordion mode keeps the first open item only',
    build: build,
    act: (cubit) => cubit
      ..expandAll()
      ..setSingleOpen(true),
    verify: (cubit) => expect(cubit.state.expanded, {'declined'}),
  );

  blocTest<FaqCubit, FaqState>(
    'collapse all closes everything',
    build: build,
    act: (cubit) => cubit
      ..expandAll()
      ..collapseAll(),
    verify: (cubit) => expect(cubit.state.expanded, isEmpty),
  );

  test('search matches question and answer text, case-insensitive', () {
    final cubit = build()..setQuery('CVV');
    expect(cubit.state.visible.map((i) => i.id), ['card-safe']);
  });
}
