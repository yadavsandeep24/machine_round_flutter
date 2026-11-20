import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log('${bloc.runtimeType} error', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
