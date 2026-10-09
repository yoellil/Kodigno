import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'motion.dart';
import 'theme.dart';

/// Landing screen: a low-poly paper brain that assembles itself, breathes,
/// ripples away from the cursor, with shards orbiting it. Clicking it floods
/// the facets with color from the click point, then calls [onOpen].
/// Always drawn on white, also in dark mode.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _sim = _Sim();
  Ticker? _ticker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = reduceMotion(context);
    _sim.still = still;
    if (still) {
      _ticker?.stop();
      _sim.t = 6; // settled pose
    } else {
      _ticker ??= createTicker((e) => _sim.tick(e.inMicroseconds / 1e6));
      if (!_ticker!.isActive) _ticker!.start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _sim.dispose();
    super.dispose();
  }

  Future<void> _open(Offset at) async {
    if (_sim.bloomAt != null) return;
    _sim.bloom(at);
    if (!_sim.still) await Future<void>.delayed(_Sim.bloomTime);
    if (mounted) widget.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    final caption = Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Kodigno', style: display(34, color: K.ink)),
      const SizedBox(height: 8),
      Text('Click the brain to begin.', style: body(14, color: const Color(0xFF8A8290))),
    ]);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Expanded(child: RepaintBoundary(child: _BrainCanvas(sim: _sim, onTap: _open))),
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: reduceMotion(context)
                ? caption
                : caption
                    .animate(delay: 1600.ms)
                    .fadeIn(duration: 600.ms, curve: Motion.curve)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Motion.curve),
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simulation state for the brain.

class _Sim extends ChangeNotifier {
  double t = 0;
  bool still = false;

  Offset pointer = Offset.zero; // brain units, see _frameOf
  bool pointerIn = false;
  double presence = 0;

  /// Click-to-open color wave: where and when it started.
  Offset bloomOrigin = Offset.zero;
  double? bloomAt;
  static const bloomTime = Duration(milliseconds: 1150);

  final pulses = <(Offset, double)>[];

  /// Radius the color wave has reached, in brain units.
  double get bloomRadius => bloomAt == null ? -1 : (still ? 9 : (t - bloomAt!) * 1.15);

  void bloom(Offset at) {
    bloomOrigin = at;
    bloomAt = t;
    pulse(at);
    if (still) notifyListeners();
  }

  void tick(double now) {
    final dt = (now - t).clamp(0.0, 0.1);
    t = now;
    double ease(double v, bool on, double rate) => v + ((on ? 1 : 0) - v) * math.min(1, dt * rate);
    presence = ease(presence, pointerIn, 5);
    pulses.removeWhere((p) => t - p.$2 > 3);
    notifyListeners();
  }

  void pulse(Offset at) {
    if (still) return;
    pulses.add((at, t));
    if (pulses.length > 5) pulses.removeAt(0);
  }
}

/// Center and unit size of the brain inside a canvas of [s].
(Offset, double) _frameOf(Size s) {
  final unit = math.min(s.width / 1.5, s.height / 1.2);
  return (Offset(s.width / 2, s.height / 2 - unit * 0.04), unit);
}

class _BrainCanvas extends StatelessWidget {
  const _BrainCanvas({required this.sim, required this.onTap});
  final _Sim sim;
  final void Function(Offset at) onTap; // brain units

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final size = box.biggest;
        Offset toUnit(Offset local) {
          final (c, unit) = _frameOf(size);
          return (local - c) / unit;
        }

        return Semantics(
          button: true,
          label: 'Open Kodigno',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (e) => sim
              ..pointer = toUnit(e.localPosition)
              ..pointerIn = true,
            onExit: (_) => sim.pointerIn = false,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (e) => onTap(toUnit(e.localPosition)),
              child: CustomPaint(size: size, painter: _BrainPainter(sim)),
            ),
          ),
        );
      });
}

// ---------------------------------------------------------------------------
// Palette and helpers.

const _line = Color(0xFF2B2228);
const _maroon = Color(0xFF3D0E1E);
/// Colors the facets take on when the brain is clicked.
const _bloom = [
  K.pink,
  K.yellow,
  K.mint,
  K.lavender,
  Color(0xFF7FB2FF),
  Color(0xFFFFB37A),
  Color(0xFFE88BD0),
];
const _paper = [
  Color(0xFFFFFFFF),
  Color(0xFFF4F1F3),
  Color(0xFFE6E0E4),
  Color(0xFFD3CAD0),
  _maroon,
];

double _ss(double a, double b, double x) {
  final v = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return v * v * (3 - 2 * v);
}

void _addTri(Path path, Offset a, Offset b, Offset c) => path
  ..moveTo(a.dx, a.dy)
  ..lineTo(b.dx, b.dy)
  ..lineTo(c.dx, c.dy)
  ..close();

/// Adds hatch lines clipped to triangle [p] to [out], analytically (no
/// canvas clip), so a whole frame of hatching is one drawPath.
void _addHatch(Path out, List<Offset> p, double angle, double spacing) {
  final cen = (p[0] + p[1] + p[2]) / 3;
  final r = math.max((p[0] - cen).distance, math.max((p[1] - cen).distance, (p[2] - cen).distance));
  final dir = Offset(math.cos(angle), math.sin(angle));
  final nrm = Offset(-dir.dy, dir.dx);
  final e1 = p[1] - p[0], e2 = p[2] - p[0];
  final orient = e1.dx * e2.dy - e1.dy * e2.dx >= 0 ? 1.0 : -1.0;
  for (var s = -r + spacing / 2; s < r; s += spacing) {
    final o = cen + nrm * s;
    var lo = -r, hi = r;
    for (var k = 0; k < 3 && lo < hi; k++) {
      final a = p[k], b = p[(k + 1) % 3];
      final inward = Offset(-(b.dy - a.dy), b.dx - a.dx) * orient;
      final f0 = (o.dx - a.dx) * inward.dx + (o.dy - a.dy) * inward.dy;
      final fd = dir.dx * inward.dx + dir.dy * inward.dy;
      if (fd.abs() < 1e-9) {
        if (f0 < 0) hi = lo;
      } else if (fd > 0) {
        lo = math.max(lo, -f0 / fd);
      } else {
        hi = math.min(hi, -f0 / fd);
      }
    }
    if (lo < hi) {
      final a = o + dir * lo, b = o + dir * hi;
      out
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
  }
}

/// One frame's worth of facets, batched into a few paths.
class _Batch {
  final fills = List.generate(_paper.length, (_) => Path());
  final tints = List.generate(_bloom.length, (_) => Path());
  final hatch = Path();
  final edges = Path();

  void add(List<Offset> p, _Facet f, {bool tint = false}) {
    _addTri(fills[f.kind], p[0], p[1], p[2]);
    if (tint) _addTri(tints[(f.seed * _bloom.length).floor() % _bloom.length], p[0], p[1], p[2]);
    if (f.spacing > 0) _addHatch(hatch, p, f.hatch, f.spacing);
    _addTri(edges, p[0], p[1], p[2]);
  }

  void draw(Canvas canvas) {
    for (var k = 0; k < fills.length; k++) {
      canvas.drawPath(fills[k], Paint()..color = _paper[k]);
    }
    for (var k = 0; k < tints.length; k++) {
      canvas.drawPath(tints[k], Paint()..color = _bloom[k]);
    }
    canvas.drawPath(
        hatch,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.55
          ..color = _line.withValues(alpha: 0.7));
    canvas.drawPath(
        edges,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..strokeJoin = StrokeJoin.round
          ..color = _line);
  }
}

// ---------------------------------------------------------------------------
// Brain mesh: points inside a union of "lobe" ellipses, Delaunay-triangulated
// once, then shaded from a fake height field so it reads as folded paper.

class _Ell {
  const _Ell(this.cx, this.cy, this.rx, this.ry, [this.rot = 0]);
  final double cx, cy, rx, ry, rot;

  double h(Offset p) {
    final dx = p.dx - cx, dy = p.dy - cy;
    final c = math.cos(rot), s = math.sin(rot);
    final x = dx * c + dy * s, y = -dx * s + dy * c;
    return 1 - (x / rx) * (x / rx) - (y / ry) * (y / ry);
  }
}

// Facing left, like the reference: frontal lobe on the left.
const _lobes = [
  _Ell(0.0, -0.06, 0.44, 0.27), // cerebrum
  _Ell(-0.27, 0.02, 0.21, 0.22), // frontal
  _Ell(0.27, 0.0, 0.21, 0.23), // parietal / occipital
  _Ell(-0.02, 0.12, 0.27, 0.13, -0.12), // temporal
  _Ell(0.25, 0.2, 0.15, 0.09, 0.15), // cerebellum
  _Ell(0.1, 0.3, 0.045, 0.12, -0.35), // brainstem
];

double _h(Offset p) => _lobes.map((e) => e.h(p)).reduce(math.max);

class _Facet {
  _Facet(this.kind, this.spacing, this.hatch, this.seed);
  final int kind; // index into _paper
  final double spacing; // hatch spacing in px, 0 = none
  final double hatch; // hatch angle
  final double seed; // 0..1
}

class _Face extends _Facet {
  _Face(this.a, this.b, this.c, int kind, double spacing, double hatch, double seed, this.delay,
      this.fly, this.spin)
      : super(kind, spacing, hatch, seed);
  final int a, b, c;
  final double delay; // intro start, in intro units
  final Offset fly; // intro offset, brain units
  final double spin;
}

class _Shard extends _Facet {
  _Shard(this.theta, this.speed, this.rad, this.size, this.rot, this.rotSpeed, this.shape,
      int kind, double spacing, double hatch, double seed)
      : super(kind, spacing, hatch, seed);
  final double theta, speed, rad, size, rot, rotSpeed;
  final List<Offset> shape;
}

class _Mesh {
  _Mesh(this.rest, this.jitter, this.faces, this.shards);
  final List<Offset> rest;
  final List<double> jitter;
  final List<_Face> faces;
  final List<_Shard> shards;

  static final brain = _build();

  static double _spacingFor(int kind) => const [0.0, 5.0, 3.6, 2.8, 0.0][kind];

  static _Mesh _build() {
    final rnd = math.Random(7);
    final pts = <Offset>[];

    // Outline: walk rays inward until they hit the shape.
    const c0 = Offset(0, 0.04);
    for (var k = 0; k < 44; k++) {
      final a = 2 * math.pi * k / 44;
      final dir = Offset(math.cos(a), math.sin(a));
      var r = 0.8;
      while (r > 0 && _h(c0 + dir * r) <= 0) {
        r -= 0.003;
      }
      final p = c0 + dir * (r - 0.002);
      if (pts.every((q) => (q - p).distance > 0.035)) pts.add(p);
    }
    // Interior: blue-noise-ish scatter.
    for (var i = 0; i < 5000 && pts.length < 120; i++) {
      final p = Offset(rnd.nextDouble() - 0.5, rnd.nextDouble() * 0.84 - 0.38);
      if (_h(p) < 0.07) continue;
      if (pts.any((q) => (q - p).distance < 0.078)) continue;
      pts.add(p);
    }

    final tris = _delaunay(pts).where((t) {
      final a = pts[t[0]], b = pts[t[1]], c = pts[t[2]];
      return _h((a + b + c) / 3) > 0 &&
          _h((a + b) / 2) > -0.03 &&
          _h((b + c) / 2) > -0.03 &&
          _h((c + a) / 2) > -0.03;
    }).toList();

    // Fake height for shading.
    final z = [
      for (final p in pts)
        _lobes
                .map((e) => math.sqrt(math.max(0, e.h(p))) * math.min(e.rx, e.ry) * 1.2)
                .reduce(math.max) +
            (rnd.nextDouble() - 0.5) * 0.025
    ];
    const lx = -0.35, ly = -0.5, lz = 0.8;
    final ll = math.sqrt(lx * lx + ly * ly + lz * lz);

    double segDist(Offset p, Offset a, Offset b) {
      final ab = b - a;
      final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / ab.distanceSquared).clamp(0.0, 1.0);
      return (p - (a + ab * t)).distance;
    }

    final faces = <_Face>[];
    for (final t in tris) {
      final a = pts[t[0]], b = pts[t[1]], c = pts[t[2]];
      final e1 = [b.dx - a.dx, b.dy - a.dy, z[t[1]] - z[t[0]]];
      final e2 = [c.dx - a.dx, c.dy - a.dy, z[t[2]] - z[t[0]]];
      var nx = e1[1] * e2[2] - e1[2] * e2[1];
      var ny = e1[2] * e2[0] - e1[0] * e2[2];
      var nz = e1[0] * e2[1] - e1[1] * e2[0];
      if (nz < 0) {
        nx = -nx;
        ny = -ny;
        nz = -nz;
      }
      final nl = math.sqrt(nx * nx + ny * ny + nz * nz);
      final lam = (nx * lx + ny * ly + nz * lz) / (nl * ll);
      var kind = lam > 0.86 ? 0 : (lam > 0.7 ? 1 : (lam > 0.5 ? 2 : 3));
      final cen = (a + b + c) / 3;
      if (segDist(cen, const Offset(-0.26, 0.09), const Offset(0.16, 0.0)) < 0.02 && lam < 0.75) {
        kind = 4; // the lateral fissure
      }
      if (cen.dy > 0.22 && lam < 0.35) kind = 4; // underside

      final away = cen.distance < 1e-3 ? const Offset(0, -1) : cen / cen.distance;
      faces.add(_Face(
        t[0],
        t[1],
        t[2],
        kind,
        _spacingFor(kind),
        rnd.nextDouble() * math.pi,
        rnd.nextDouble(),
        cen.distance / 0.5 * 0.45 + rnd.nextDouble() * 0.12,
        away * (0.35 + rnd.nextDouble() * 0.45),
        (rnd.nextDouble() - 0.5) * 3,
      ));
    }

    final srnd = math.Random(3);
    final shards = <_Shard>[];
    for (var i = 0; i < 12; i++) {
      final kind = [0, 1, 2, 4, 0, 2][srnd.nextInt(6)];
      shards.add(_Shard(
        i / 12 * 2 * math.pi + srnd.nextDouble() * 0.3,
        (0.02 + srnd.nextDouble() * 0.04) * (i.isEven ? 1 : -1),
        0.52 + srnd.nextDouble() * 0.16,
        0.018 + srnd.nextDouble() * 0.028,
        srnd.nextDouble() * math.pi * 2,
        (srnd.nextDouble() - 0.5) * 0.8,
        [
          for (final a in [0.0, 2.1 + srnd.nextDouble() * 0.6, 4.2 + srnd.nextDouble() * 0.6])
            Offset(math.cos(a), math.sin(a)) * (0.6 + srnd.nextDouble() * 0.4)
        ],
        kind,
        _spacingFor(kind),
        srnd.nextDouble() * math.pi,
        srnd.nextDouble(),
      ));
    }
    return _Mesh(pts, [for (var i = 0; i < pts.length; i++) rnd.nextDouble()], faces, shards);
  }
}

/// Bowyer-Watson. Small point counts only (runs once).
List<List<int>> _delaunay(List<Offset> pts) {
  final n = pts.length;
  final p = [...pts, const Offset(-10, -10), const Offset(10, -10), const Offset(0, 10)];
  var tris = <List<int>>[
    [n, n + 1, n + 2]
  ];

  bool inCircle(List<int> t, Offset q) {
    final a = p[t[0]], b = p[t[1]], c = p[t[2]];
    final d = 2 * (a.dx * (b.dy - c.dy) + b.dx * (c.dy - a.dy) + c.dx * (a.dy - b.dy));
    if (d.abs() < 1e-12) return false;
    final a2 = a.distanceSquared, b2 = b.distanceSquared, c2 = c.distanceSquared;
    final ux = (a2 * (b.dy - c.dy) + b2 * (c.dy - a.dy) + c2 * (a.dy - b.dy)) / d;
    final uy = (a2 * (c.dx - b.dx) + b2 * (a.dx - c.dx) + c2 * (b.dx - a.dx)) / d;
    final u = Offset(ux, uy);
    return (q - u).distanceSquared < (a - u).distanceSquared;
  }

  for (var i = 0; i < n; i++) {
    final bad = tris.where((t) => inCircle(t, p[i])).toList();
    final edges = <(int, int)>[];
    for (final t in bad) {
      for (final e in [(t[0], t[1]), (t[1], t[2]), (t[2], t[0])]) {
        final shared =
            bad.any((o) => !identical(o, t) && o.contains(e.$1) && o.contains(e.$2));
        if (!shared) edges.add(e);
      }
    }
    final badSet = bad.toSet();
    tris = [
      ...tris.where((t) => !badSet.contains(t)),
      for (final e in edges) [e.$1, e.$2, i]
    ];
  }
  return tris.where((t) => t.every((v) => v < n)).toList();
}

// ---------------------------------------------------------------------------

class _BrainPainter extends CustomPainter {
  _BrainPainter(this.sim) : super(repaint: sim);
  final _Sim sim;
  final _Mesh mesh = _Mesh.brain;

  /// Push from the cursor and from click pulses, in brain units.
  Offset _push(Offset v, double radius, double strength) {
    var d = Offset.zero;
    if (sim.presence > 0.001) {
      final dv = v - sim.pointer;
      final dist = dv.distance;
      if (dist < radius && dist > 1e-4) {
        final f = 1 - dist / radius;
        d += dv / dist * (strength * f * f * sim.presence);
      }
    }
    for (final (o, t0) in sim.pulses) {
      final age = sim.t - t0;
      final dv = v - o;
      final dist = dv.distance;
      if (dist < 1e-4) continue;
      final wave = math.exp(-math.pow(dist - age * 0.85, 2) / 0.003) * math.exp(-age * 1.6);
      d += dv / dist * (strength * 1.2 * wave);
    }
    return d;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = sim.t;
    final (c, unit) = _frameOf(size);
    Offset px(Offset v) => c + v * unit;
    final introT = t / 1.9;

    // Two faint pastel washes behind, still mostly white.
    for (final (at, col, r) in [
      (const Offset(-0.2, -0.12), K.mint, 0.75),
      (const Offset(0.22, 0.2), K.pink, 0.7),
    ]) {
      final center = px(at);
      canvas.drawCircle(
          center,
          unit * r,
          Paint()
            ..shader = ui.Gradient.radial(center, unit * r, [
              col.withValues(alpha: 0.22 * _ss(0, 1, t / 1.5)),
              col.withValues(alpha: 0),
            ]));
    }

    // Vertex positions.
    final n = mesh.rest.length;
    final pos = List<Offset>.filled(n, Offset.zero);
    final breathe = 1 + 0.012 * math.sin(t * 1.2);
    for (var i = 0; i < n; i++) {
      final v = mesh.rest[i];
      final j = mesh.jitter[i] * 6;
      pos[i] = px(v * breathe +
          Offset(math.sin(t * 0.9 + v.dy * 9 + j), math.cos(t * 0.8 + v.dx * 8 + j)) * 0.005 +
          _push(v, 0.26, 0.035));
    }

    final batch = _Batch();
    final bloomR = sim.bloomRadius;

    /// Colors a facet once the wave has passed its center, with a quick
    /// pop in size as it turns.
    List<Offset> bloomPop(List<Offset> pts, Offset restCenter, void Function(bool) tint) {
      final behind = bloomR - (restCenter - sim.bloomOrigin).distance;
      tint(behind > 0);
      if (behind <= 0 || behind > 0.14) return pts;
      final k = 1 + 0.18 * math.sin(math.pi * behind / 0.14);
      final cen = (pts[0] + pts[1] + pts[2]) / 3;
      return [for (final q in pts) cen + (q - cen) * k];
    }

    for (final s in mesh.shards) {
      final th = s.theta + t * s.speed;
      final pIn =
          Curves.easeOutCubic.transform(((introT - 0.2 - s.seed * 0.3) / 0.8).clamp(0.0, 1.0));
      if (pIn <= 0) continue;
      var v = (Offset(math.cos(th) * s.rad * 1.08, math.sin(th) * s.rad * 0.8) +
              Offset(0, math.sin(t * 0.9 + s.seed * 6) * 0.012)) *
          (0.3 + 0.7 * pIn);
      v += _push(v, 0.2, 0.06);
      final rot = s.rot + t * s.rotSpeed;
      final cr = math.cos(rot), sr = math.sin(rot);
      var tinted = false;
      final pts = bloomPop([
        for (final l in s.shape)
          px(v + Offset(l.dx * cr - l.dy * sr, l.dx * sr + l.dy * cr) * (s.size * pIn))
      ], v, (b) => tinted = b);
      batch.add(pts, s, tint: tinted);
    }

    for (final f in mesh.faces) {
      final p = Curves.easeOutCubic.transform(((introT - f.delay) / 0.55).clamp(0.0, 1.0));
      if (p <= 0) continue;
      var pts = [pos[f.a], pos[f.b], pos[f.c]];
      if (p < 1) {
        // Fly in from outside, spinning into place.
        final cen = (pts[0] + pts[1] + pts[2]) / 3;
        final shift = f.fly * (unit * (1 - p));
        final ang = f.spin * (1 - p);
        final ca = math.cos(ang), sa = math.sin(ang);
        pts = [
          for (final q in pts)
            cen +
                shift +
                Offset((q - cen).dx * ca - (q - cen).dy * sa, (q - cen).dx * sa + (q - cen).dy * ca) *
                    (0.4 + 0.6 * p)
        ];
      }
      var tinted = false;
      pts = bloomPop(pts, (mesh.rest[f.a] + mesh.rest[f.b] + mesh.rest[f.c]) / 3, (b) => tinted = b);
      batch.add(pts, f, tint: tinted);
    }

    batch.draw(canvas);
  }

  @override
  bool shouldRepaint(_BrainPainter old) => old.sim != sim;
}
