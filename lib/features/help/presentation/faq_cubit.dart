import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/faq_item.dart';

class FaqState extends Equatable {
  const FaqState({required this.all, this.query = '', this.expanded = const {}, this.singleOpen = true});

  final List<FaqItem> all;
  final String query;

  /// Ids of open items. The cubit is the single source of truth;
  /// each tile's ExpansibleController just mirrors this set.
  final Set<String> expanded;

  /// Accordion mode: opening one item closes the others.
  final bool singleOpen;

  List<FaqItem> get visible => all.where((item) => item.matches(query)).toList();

  bool isExpanded(String id) => expanded.contains(id);

  FaqState copyWith({String? query, Set<String>? expanded, bool? singleOpen}) => FaqState(
    all: all,
    query: query ?? this.query,
    expanded: expanded ?? this.expanded,
    singleOpen: singleOpen ?? this.singleOpen,
  );

  @override
  List<Object?> get props => [all, query, expanded, singleOpen];
}

class FaqCubit extends Cubit<FaqState> {
  FaqCubit(List<FaqItem> items, {String? initiallyOpen})
    : super(
        FaqState(
          all: items,
          expanded: {if (initiallyOpen != null && items.any((i) => i.id == initiallyOpen)) initiallyOpen},
        ),
      );

  void toggle(String id) {
    if (state.isExpanded(id)) {
      emit(state.copyWith(expanded: {...state.expanded}..remove(id)));
    } else {
      emit(state.copyWith(expanded: state.singleOpen ? {id} : {...state.expanded, id}));
    }
  }

  /// Expand-all only makes sense in multi-open mode, so it switches the mode.
  void expandAll() => emit(
    state.copyWith(singleOpen: false, expanded: {for (final item in state.visible) item.id}),
  );

  void collapseAll() => emit(state.copyWith(expanded: const {}));

  void setSingleOpen(bool value) {
    if (value == state.singleOpen) return;
    // Switching to accordion mode keeps at most one open item (the first visible one).
    final keep = value
        ? state.visible.map((i) => i.id).where(state.expanded.contains).take(1).toSet()
        : state.expanded;
    emit(state.copyWith(singleOpen: value, expanded: keep));
  }

  void setQuery(String text) => emit(state.copyWith(query: text));
}
