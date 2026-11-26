import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../services/my_ip.dart';
import '../services/vpn_channel.dart';
import '../state/app_state.dart';
import 'format.dart';

const _cardBg = Color(0xFF1A1F38);
const _innerBg = Color(0xFF121528);
const _cyan = Color(0xFF00D2FF);
const _purple = Color(0xFF8B5CF6);
const _coralStart = Color(0xFFFF6B4A);
const _coralEnd = Color(0xFFFF4F5E);
const _tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

class StatusCard extends StatefulWidget {
  const StatusCard({super.key});

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  Timer? _ticker;
  DateTime? _since;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateScope.of(context);
    final status = state.status;
    if (status == VpnStatus.connected) {
      _since ??= state.connectedAt ?? DateTime.now();
      _ticker ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (mounted) setState(() {});
        },
      );
    } else {
      _ticker?.cancel();
      _ticker = null;
      _since = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final status = state.status;
    final busy = state.isBusy;
    final connected = status == VpnStatus.connected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final durationText = connected && _since != null
        ? formatDuration(DateTime.now().difference(_since!))
        : '--:--:--';

    final cardColor = isDark ? _cardBg : theme.colorScheme.surfaceContainerLow;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          _PowerButton(
            status: status,
            busy: busy,
            onTap: busy ? null : state.toggleConnection,
          ),
          const SizedBox(height: 20),
          _Metrics(
            durationText: durationText,
            connected: connected,
            pinging: state.pinging,
            pingMs: state.pingMs,
            onPing: state.ping,
            myIp: state.myIp,
            workerIp: state.workerIp,
            lanIp: state.lanIp,
          ),
        ],
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.status,
    required this.busy,
    required this.onTap,
  });

  final VpnStatus status;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final (Color primary, Color secondary, String label) = switch (status) {
      VpnStatus.connected => (_coralStart, _coralEnd, 'CONNECTED'),
      VpnStatus.connecting => (_purple, const Color(0xFF6D28D9), 'CONNECTING'),
      VpnStatus.disconnecting => (
        _purple,
        const Color(0xFF6D28D9),
        'DISCONNECTING',
      ),
      VpnStatus.disconnected => (_cyan, _purple, 'TAP TO CONNECT'),
    };

    final innerColor = isDark ? _innerBg : theme.colorScheme.surface;
    final labelColor = isDark
        ? Colors.white.withValues(alpha: 0.92)
        : theme.colorScheme.onSurface;

    return SizedBox(
      width: 248,
      height: 248,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(248, 248),
            painter: _MeshRingPainter(
              primary: primary,
              secondary: secondary,
              active: status == VpnStatus.connected || busy,
            ),
          ),
          Container(
            width: 188,
            height: 188,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primary, secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.42),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: secondary.withValues(alpha: 0.28),
                  blurRadius: 36,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Material(
              color: innerColor,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.power_settings_new_rounded,
                        size: 52,
                        color: primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeshRingPainter extends CustomPainter {
  const _MeshRingPainter({
    required this.primary,
    required this.secondary,
    required this.active,
  });

  final Color primary;
  final Color secondary;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;
    const nodeCount = 8;

    final points = List<Offset>.generate(nodeCount, (i) {
      final angle = -math.pi / 2 + (2 * math.pi * i / nodeCount);
      return Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    });

    final linePaint = Paint()
      ..color = primary.withValues(alpha: active ? 0.42 : 0.26)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final crossPaint = Paint()
      ..color = secondary.withValues(alpha: active ? 0.22 : 0.12)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < nodeCount; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % nodeCount];
      final p3 = points[(i + 2) % nodeCount];
      canvas.drawLine(p1, p2, linePaint);
      canvas.drawLine(p1, p3, crossPaint);
    }

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    for (var i = 0; i < nodeCount; i++) {
      final nodeColor = i.isEven ? primary : secondary;
      glowPaint.color = nodeColor.withValues(alpha: active ? 0.85 : 0.6);
      canvas.drawCircle(points[i], 5.5, glowPaint);

      final corePaint = Paint()..color = nodeColor;
      canvas.drawCircle(points[i], 3.0, corePaint);
    }
  }

  @override
  bool shouldRepaint(_MeshRingPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.active != active;
}

class _Metrics extends StatelessWidget {
  const _Metrics({
    required this.durationText,
    required this.connected,
    required this.pinging,
    required this.pingMs,
    required this.onPing,
    required this.myIp,
    required this.workerIp,
    required this.lanIp,
  });

  final String durationText;
  final bool connected;
  final bool pinging;
  final int? pingMs;
  final Future<void> Function() onPing;
  final IpInfo? myIp;
  final IpInfo? workerIp;
  final String? lanIp;

  @override
  Widget build(BuildContext context) {
    final pingText = pinging
        ? '...'
        : pingMs == null
            ? '--'
            : '${pingMs}ms';

    final twoIps = workerIp != null && workerIp?.ip != myIp?.ip;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: 'Duration',
                value: durationText,
                tabular: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                label: 'Ping',
                value: pingText,
                tabular: true,
                trailing: connected
                    ? _PingButton(pinging: pinging, onTap: onPing)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: 'My IP',
                value: _formatIp(myIp),
                copyValue: myIp?.ip,
                tabular: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                label: 'LAN IP',
                value: lanIp ?? '--',
                copyValue: lanIp,
                tabular: true,
              ),
            ),
          ],
        ),
        if (twoIps) ...[
          const SizedBox(height: 10),
          _Metric(
            label: 'Worker IP',
            value: _formatIp(workerIp),
            copyValue: workerIp?.ip,
            tabular: true,
          ),
        ],
      ],
    );
  }

  static String _formatIp(IpInfo? info) {
    if (info == null) return '--';
    final loc = info.country ?? '';
    return loc.isEmpty ? info.ip : '${info.ip} ($loc)';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.copyValue,
    this.trailing,
    this.tabular = false,
  });

  final String label;
  final String value;
  final String? copyValue;
  final Widget? trailing;
  final bool tabular;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final bg = isDark
        ? _innerBg.withValues(alpha: 0.72)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.55)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (tabular
                          ? theme.textTheme.bodyMedium?.merge(_tabular)
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (copyValue == null || copyValue!.isEmpty) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: copyValue!));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied $copyValue'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: content,
      ),
    );
  }
}

class _PingButton extends StatelessWidget {
  const _PingButton({required this.pinging, required this.onTap});

  final bool pinging;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: pinging ? null : onTap,
      tooltip: 'Test ping',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      icon: pinging
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Symbols.speed_rounded, size: 18, color: _cyan),
    );
  }
}

