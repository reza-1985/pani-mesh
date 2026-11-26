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

class _StatusCardState extends State<StatusCard> with SingleTickerProviderStateMixin {
  Timer? _ticker;
  DateTime? _since;
  VpnStatus? _prevStatus;
  late final AnimationController _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);
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
    if (status == VpnStatus.connecting || status == VpnStatus.disconnecting) { if (!_animController.isAnimating) _animController.repeat(); } else if (_animController.isAnimating) { _animController.stop(); }
    if (_prevStatus != VpnStatus.connected && status == VpnStatus.connected && state.pingMs == null && !state.pinging) { WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) state.testPing(); }); }
_prevStatus = status;
  }

  @override
  void dispose() {
    _ticker?.cancel();
_animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
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
animation: _animController,
            busy: busy,
            onTap: status == VpnStatus.disconnecting ? null : state.toggle, // busy ? null : state.toggle,
          ),
          const SizedBox(height: 20),
          _Metrics(
            durationText: durationText,
            connected: connected,
            pinging: state.pinging,
            pingMs: state.pingMs,
            onPing: state.testPing,
            myIp: state.myIps?.other,
            workerIp: state.myIps?.cloudflare,
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
required this.animation,
    required this.onTap,
  });

  final VpnStatus status;
  final bool busy;
final Animation<double> animation;
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

    return AnimatedBuilder(animation: animation, builder: (context, _) { return SizedBox(
      width: 244,
      height: 244,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(244, 244),
            painter: _MeshRingPainter(
              primary: primary,
              secondary: secondary,
              tertiary: status == VpnStatus.disconnected ? _coralStart : secondary,
              connected: status == VpnStatus.connected,
              active: status == VpnStatus.connected || busy,
progress: animation.value,
            ),
          ),
          Container(
            width: 142,
            height: 142,
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
                  blurRadius: status == VpnStatus.connected ? 30 : 28,
                  spreadRadius: status == VpnStatus.connected ? 4 : 2,
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
                    shape: BoxShape.circle, gradient: status == VpnStatus.connected ? const RadialGradient(colors: [Color(0x66FF6B4A), Color(0x28FF4F5E), Color(0xFF1B1429)], stops: [0.0, 0.55, 1.0]) : null,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
                    ),
                  ),
                  child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(duration: const Duration(milliseconds: 400),
                        opacity: status == VpnStatus.connected ? 0.42 : (status == VpnStatus.connecting || status == VpnStatus.disconnecting ? 0.18 : 0.09),
                        child: Transform.scale(
                          scale: 1.45,
                          child: Image.asset(
                            'assets/icons/pani_mesh_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.power_settings_new_rounded,
                        size: 46, shadows: status == VpnStatus.connected ? const [Shadow(color: Color(0xCC000000), blurRadius: 10)] : null,
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
                          letterSpacing: 1.3, shadows: status == VpnStatus.connected ? const [Shadow(color: Color(0xCC000000), blurRadius: 8)] : null,
                        ),
                      ),
if (status == VpnStatus.connecting) ...[
const SizedBox(height: 2),
Text('TAP TO CANCEL', textAlign: TextAlign.center, style: TextStyle(color: labelColor.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
],
                    ],
                  ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
});
  }
}



class _MeshRingPainter extends CustomPainter {
  const _MeshRingPainter({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.active,
    required this.connected,
    this.progress = 0.0,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final bool active;
  final bool connected;
  final double progress;

  Color _nodeColor(int i, int count) {
    if (connected) {
      return Color.lerp(primary, secondary, (i % 3) / 2.0)!;
    }
    final t = (i / count) * 3.0;
    if (t < 1.0) return Color.lerp(primary, secondary, t)!;
    if (t < 2.0) return Color.lerp(secondary, tertiary, t - 1.0)!;
    return Color.lerp(tertiary, primary, t - 2.0)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.47;
    final midR = size.width * 0.36; final edgeR = size.width * 0.29;
    const count = 12;
    final spin = active && !connected ? progress * 2 * math.pi : 0.0;
    final pulse = active && !connected
        ? 0.5 + 0.5 * math.sin(progress * 2 * math.pi)
        : 0.0;

    final outerNodes = <Offset>[];
    final midNodes = <Offset>[]; final edgeNodes = <Offset>[];
    for (int i = 0; i < count; i++) {
      final a = (i / count) * 2 * math.pi - math.pi / 2 + spin;
      final aMid = a + math.pi / count;
     outerNodes.add(Offset(center.dx + outerR * math.cos(aMid), center.dy + outerR * math.sin(aMid))); midNodes.add(Offset(center.dx + midR * math.cos(a), center.dy + midR * math.sin(a))); edgeNodes.add(Offset(center.dx + edgeR * math.cos(a), center.dy + edgeR * math.sin(a)));
    }
    canvas.drawCircle(center, midR, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5..color = primary.withValues(alpha: connected ? 0.22 : 0.14 + 0.10 * pulse)); canvas.drawCircle(center, midR, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = primary.withValues(alpha: connected ? 0.55 : 0.35 + 0.15 * pulse));
    final faintPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final boldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45;

    for (int i = 0; i < count; i++) {
      final next = (i + 1) % count;
      final c = _nodeColor(i, count);
      faintPaint.color = c.withValues(alpha: connected ? 0.30 : 0.22 + 0.12 * pulse);
      boldPaint.color = c.withValues(alpha: connected ? 0.65 : 0.45 + 0.25 * pulse);

      canvas.drawLine(outerNodes[i], outerNodes[next], boldPaint);
      canvas.drawLine(midNodes[i], midNodes[next], faintPaint);
      canvas.drawLine(outerNodes[i], midNodes[i], boldPaint);
      canvas.drawLine(outerNodes[next], midNodes[i], faintPaint); canvas.drawLine(edgeNodes[i], midNodes[i], faintPaint); canvas.drawLine(edgeNodes[i], midNodes[next], faintPaint);
    }

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final c = _nodeColor(i, count) dotPaint.color = c.withValues(alpha: connected ? 0.26 : 0.18 + 0.10 * pulse); canvas.drawCircle(outerNodes[i], 6.5, dotPaint); canvas.drawCircle(midNodes[i], 5.5, dotPaint);;
      dotPaint.color = c.withValues(alpha: connected ? 0.95 : 0.8 + 0.2 * pulse);
      canvas.drawCircle(outerNodes[i], 3.2, dotPaint);
      dotPaint.color = c.withValues(alpha: connected ? 0.65 : 0.55);
      canvas.drawCircle(midNodes[i], 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MeshRingPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.tertiary != tertiary ||
      oldDelegate.progress != progress ||
      oldDelegate.active != active ||
      oldDelegate.connected != connected;
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

