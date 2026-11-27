import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
    if (status == VpnStatus.disconnected) { if (_animController.isAnimating) _animController.stop(); } else { final targetDuration = (status == VpnStatus.connecting || status == VpnStatus.disconnecting) ? const Duration(milliseconds: 19800) : const Duration(seconds: 156); if (_animController.duration != targetDuration) { _animController.duration = targetDuration; _animController.repeat(); } else if (!_animController.isAnimating) { _animController.repeat(); } }
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
      width: 286,
      height: 286,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(286, 286),
            painter: _MeshRingPainter(
              primary: primary,
              secondary: secondary,
              tertiary: status == VpnStatus.disconnected ? _coralStart : secondary,
              connected: status == VpnStatus.connected,
              active: busy,
progress: animation.value,
            ),
          ),
          Container(
            width: 146,
            height: 146,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: const [Color(0xFF00D2FF), Color(0xFF8B5CF6), Color(0xFFFF6B4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: status == VpnStatus.connected ? 0.56 : 0.26),
                  blurRadius: status == VpnStatus.connected ? 30 : 28,
                  spreadRadius: status == VpnStatus.connected ? 4 : 2,
                ),
                BoxShadow(
                  color: secondary.withValues(alpha: 0.28),
                  blurRadius: 36,
                  spreadRadius: 1,
                ),
if (status == VpnStatus.connected)
                BoxShadow(
color: primary.withValues(alpha: 0.34),
blurRadius: 52,
spreadRadius: 6,
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
                    shape: BoxShape.circle, gradient: status == VpnStatus.connected ? const RadialGradient(colors: [Color(0x45FFA56E), Color(0x2E8B5CF6), Color(0xFF1B1469)], stops: [0.0, 0.55, 1.0]) : null,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2),
                    ),
                  ),
                  child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(duration: const Duration(milliseconds: 400),
                        opacity: status == VpnStatus.connected ? 0.96 : (status == VpnStatus.connecting || status == VpnStatus.disconnecting ? 0.24 : 0.11),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 450), scale: status == VpnStatus.connected ? 1.04 : 0.96,
                          child: Image.asset(
                            'assets/icons/pani_face_only.png',
                            width: 120, height: 120, fit: BoxFit.contain,
                          ),
                        ),
                      ),
                AnimatedOpacity(opacity: status == VpnStatus.connected ? 0.0 : 1.0, duration: const Duration(milliseconds: 450), child:       Column(
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
                  ), ),
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

  static const _palette = [Color(0xFF00D2FF), Color(0xFF8B5CF6), Color(0xFFFF6B4A)];

  Color _nodeColor(int i, int count) {
    final t = (i / count) * 3.0;
    if (t < 1.0) return Color.lerp(_palette[0], _palette[1], t)!;
    if (t < 2.0) return Color.lerp(_palette[1], _palette[2], t - 1.0)!;
    return Color.lerp(_palette[2], _palette[0], t - 2.0)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    const n = 12;
    final rEdge = w * 0.265;
    final r1 = w * 0.328;
    final r2 = w * 0.405;
    final r3 = w * 0.468;
    final intensity = connected ? 1.0 : (active ? 0.85 : 0.62);
 final rot1 = (!active && !connected) ? 0.0 : progress * 6 * math.pi; final rot2 = (!active && !connected) ? 0.0 : -progress * 4 * math.pi; final pulse = (!active && !connected) ? 0.45 : (active ? 0.5 + 0.5 * math.sin(progress * 2 * math.pi * 16) : 0.7 + 0.3 * math.sin(progress * 2 * math.pi * 55));
    final edgeNodes = <Offset>[];
    final ring1Nodes = <Offset>[];
    final ring2Nodes = <Offset>[];
    final ring3Nodes = <Offset>[];
    final outerDotNodes = <Offset>[];
    for (int i = 0; i < n; i++) {
     final baseA = (i / n) * 2 * math.pi - math.pi / 2 + rot1;
      final a1 = baseA + math.pi / n;
      final jitterA = math.sin(i * 2.3 + 0.7) * 0.12;
      final jitterR = math.cos(i * 1.7 + 0.4) * (w * 0.014);
     final a2 = (i / n) * 2 * math.pi - math.pi / 2 + rot2 + jitterA;
      final a3 = baseA + math.pi / (n * 1.5);
      edgeNodes.add(Offset(center.dx + rEdge * math.cos(baseA), center.dy + rEdge * math.sin(baseA)));
      ring1Nodes.add(Offset(center.dx + r1 * math.cos(a1), center.dy + r1 * math.sin(a1)));
      ring2Nodes.add(Offset(center.dx + (r2 + jitterR) * math.cos(a2), center.dy + (r2 + jitterR) * math.sin(a2)));
      ring3Nodes.add(Offset(center.dx + r3 * math.cos(a3), center.dy + r3 * math.sin(a3)));
      outerDotNodes.add(Offset(center.dx + (r3 * 1.03) * math.cos(baseA), center.dy + (r3 * 1.03) * math.sin(baseA)));
    }
    canvas.drawCircle(center, r1, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.2..color = _palette[0].withValues(alpha: (0.16 + 0.08 * pulse) * intensity));
    canvas.drawCircle(center, r1, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = _palette[0].withValues(alpha: (0.48 + 0.14 * pulse) * intensity));
  
  void drawLine(Offset p1, Offset p2, Color c1, Color c2, double width, double alpha) {
final paint = Paint()
..style = PaintingStyle.stroke
..strokeWidth = width
..strokeCap = StrokeCap.round
..shader = ui.Gradient.linear(
p1,
p2,
[
c1.withValues(alpha: alpha * intensity),
c2.withValues(alpha: alpha * intensity),
],
);
canvas.drawLine(p1, p2, paint);
  }
    void drawNode(Offset pos, Color color, double radius, double alpha) {
final glowRadius = radius * 2.4;
final glowPaint = Paint()
..style = PaintingStyle.fill
..shader = ui.Gradient.radial(
pos,
glowRadius,
[
color.withValues(alpha: alpha * 0.65 * intensity),
color.withValues(alpha: 0.0),
],
);
canvas.drawCircle(pos, glowRadius, glowPaint);
final corePaint = Paint()
..style = PaintingStyle.fill
..color = color.withValues(alpha: alpha * intensity);
canvas.drawCircle(pos, radius, corePaint);
}
for (int i = 0; i < n; i++) {
final next = (i + 1) % n;
final prev = (i + n - 1) % n;
final c = _nodeColor(i, n);
final cNext = _nodeColor(next, n);
final cPrev = _nodeColor(prev, n);
final faintAlpha = 0.28 + 0.10 * pulse;
final boldAlpha = 0.62 + 0.18 * pulse;
drawLine(ring1Nodes[i], ring1Nodes[next], c, cNext, 0.85, faintAlpha);
drawLine(ring2Nodes[i], ring2Nodes[next], c, cNext, 1.35, boldAlpha);
drawLine(ring3Nodes[i], ring3Nodes[next], c, cNext, 1.35, boldAlpha);
drawLine(edgeNodes[i], ring1Nodes[i], c, c, 0.85, faintAlpha);
drawLine(edgeNodes[i], ring1Nodes[prev], c, cPrev, 0.85, faintAlpha);
drawLine(ring1Nodes[i], ring2Nodes[i], c, c, 0.85, faintAlpha);
drawLine(ring1Nodes[i], ring2Nodes[next], c, cNext, 0.85, faintAlpha);
drawLine(ring2Nodes[i], ring3Nodes[i], c, c, 1.35, boldAlpha);
drawLine(ring2Nodes[next], ring3Nodes[i], cNext, c, 0.85, faintAlpha);
}
for (int i = 0; i < n; i++) {
final c = _nodeColor(i, n);
drawNode(ring3Nodes[i], c, 2.8, 0.90 + 0.10 * pulse);
drawNode(ring2Nodes[i], c, 2.2, 0.72);
drawNode(ring1Nodes[i], c, 1.7, 0.55);
drawNode(outerDotNodes[i], c, 1.3, 0.65);
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

