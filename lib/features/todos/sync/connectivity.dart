import 'dart:async';

/// Swap for a `connectivity_plus` adapter in production. Remember that
/// "has a network interface" is not "can reach the server": the sync engine
/// still treats every request failure as possibly offline.
abstract interface class Connectivity {
  bool get isOnline;
  Stream<bool> get changes;
}

/// Demo and test implementation driven by a switch in the app bar.
class ManualConnectivity implements Connectivity {
  ManualConnectivity({bool online = true}) : _online = online;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get changes => _controller.stream;

  void set(bool online) {
    if (online == _online) return;
    _online = online;
    _controller.add(online);
  }
}
