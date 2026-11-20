import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';

/// Debounce events, then cancel the previous handler when a new event
/// arrives (the Bloc equivalent of `debounce` + `flatMapLatest`).
EventTransformer<E> debounceRestartable<E>(Duration duration) {
  return (events, mapper) => restartable<E>().call(events.debounce(duration), mapper);
}

/// Ignore new events while one is being handled (load-more guard).
EventTransformer<E> dropWhileBusy<E>() => droppable<E>();
