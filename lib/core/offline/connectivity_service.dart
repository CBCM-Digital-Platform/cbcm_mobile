import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

/// Foundation only. Sync logic that reacts to this is built in Week 4.
class ConnectivityNotifier extends Notifier<ConnectivityStatus> {
  late final Connectivity _connectivity;

  @override
  ConnectivityStatus build() {
    _connectivity = Connectivity();
    _init();
    return ConnectivityStatus.online; // optimistic default until checked
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    state = _statusFromResult(result);

    _connectivity.onConnectivityChanged.listen((result) {
      state = _statusFromResult(result);
    });
  }

  ConnectivityStatus _statusFromResult(List<ConnectivityResult> result) {
    final hasConnection =
        result.isNotEmpty && !result.contains(ConnectivityResult.none);
    return hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }
}

final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityStatus>(
  ConnectivityNotifier.new,
);