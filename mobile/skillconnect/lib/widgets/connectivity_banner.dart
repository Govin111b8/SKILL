import 'package:flutter/material.dart';
import '../services/offline/connectivity_service.dart';
import '../services/offline/offline_queue_service.dart';

/// Connectivity-aware banner widget that shows network status
/// and pending sync count at the top of the app.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectivityService.instance,
      builder: (context, _) {
        final status = ConnectivityService.instance.status;
        if (status == NetworkStatus.online) return const SizedBox.shrink();

        return Material(
          color: status == NetworkStatus.slow ? Colors.orange.shade700 : Colors.red.shade700,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == NetworkStatus.slow ? Icons.signal_wifi_statusbar_4_bar : Icons.wifi_off,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status == NetworkStatus.slow
                        ? 'Slow connection'
                        : 'You\'re offline',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  StreamBuilder<int>(
                    stream: OfflineQueueService.pendingCountStream,
                    initialData: OfflineQueueService.pendingCount,
                    builder: (context, snap) {
                      final count = snap.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count pending',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A wrapper that shows "Will send when online" indicator on actions
class OfflineActionIndicator extends StatelessWidget {
  final Widget child;
  final bool showWhenOffline;

  const OfflineActionIndicator({
    super.key,
    required this.child,
    this.showWhenOffline = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ConnectivityService.instance,
      builder: (context, _) {
        final isOffline = !ConnectivityService.instance.isOnline;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            if (isOffline && showWhenOffline)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Will send when online',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
