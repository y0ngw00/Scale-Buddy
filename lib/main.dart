import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'src/audio/scale_audio_player.dart';
import 'src/music/music_theory.dart';

void main() {
  runApp(const ScaleBuddyApp());
}

class ScaleBuddyApp extends StatelessWidget {
  const ScaleBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scale Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff24745f),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7f8f3),
        useMaterial3: true,
      ),
      home: const ScalePlayerScreen(),
    );
  }
}

class ScalePlayerScreen extends StatefulWidget {
  const ScalePlayerScreen({super.key});

  @override
  State<ScalePlayerScreen> createState() => _ScalePlayerScreenState();
}

class _ScalePlayerScreenState extends State<ScalePlayerScreen> {
  final _audioPlayer = ScaleAudioPlayer();

  PitchClass _root = PitchClass.c;
  ScalePattern _scalePattern = ScalePattern.major;
  int _bpm = 96;
  bool _isPlaying = false;
  int? _activeStep;

  List<ScaleNote> get _scale =>
      buildScale(root: _root, pattern: _scalePattern, octave: 4);

  int get _stepDurationMs => (60000 / _bpm).round();

  void _openControls() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateRoot(PitchClass value) {
              setState(() => _root = value);
              setModalState(() {});
            }

            void updateScale(ScalePattern value) {
              setState(() => _scalePattern = value);
              setModalState(() {});
            }

            void updateBpm(int value) {
              setState(() => _bpm = value);
              setModalState(() {});
            }

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: _ControlPanel(
                  root: _root,
                  scalePattern: _scalePattern,
                  bpm: _bpm,
                  isPlaying: _isPlaying,
                  onRootChanged: updateRoot,
                  onScaleChanged: updateScale,
                  onBpmChanged: updateBpm,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
        _activeStep = null;
      });
      await _audioPlayer.stop();
      return;
    }

    setState(() {
      _isPlaying = true;
      _activeStep = 0;
    });

    final notes = _scale;
    for (var index = 0; index < notes.length && _isPlaying; index += 1) {
      setState(() => _activeStep = index);
      await _audioPlayer.playTone(
        frequency: notes[index].frequency,
        duration: Duration(milliseconds: (_stepDurationMs * 0.82).round()),
      );
      await Future<void>.delayed(Duration(milliseconds: _stepDurationMs));
    }

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _activeStep = null;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: _openControls,
                      icon: const Icon(Icons.menu),
                      tooltip: 'Controls',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scale Buddy',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _togglePlayback,
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Stop' : 'Play'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              sliver: SliverToBoxAdapter(
                child: _ScaleSummary(
                  root: _root,
                  scalePattern: _scalePattern,
                  bpm: _bpm,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverToBoxAdapter(
                child: _StaffNotation(
                  root: _root,
                  scalePattern: _scalePattern,
                  notes: scale,
                  activeStep: _activeStep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleSummary extends StatelessWidget {
  const _ScaleSummary({
    required this.root,
    required this.scalePattern,
    required this.bpm,
  });

  final PitchClass root;
  final ScalePattern scalePattern;
  final int bpm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.tune, size: 18, color: Color(0xff768078)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${root.label} ${scalePattern.label} · $bpm BPM',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xff46524c),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.root,
    required this.scalePattern,
    required this.bpm,
    required this.isPlaying,
    required this.onRootChanged,
    required this.onScaleChanged,
    required this.onBpmChanged,
  });

  final PitchClass root;
  final ScalePattern scalePattern;
  final int bpm;
  final bool isPlaying;
  final ValueChanged<PitchClass> onRootChanged;
  final ValueChanged<ScalePattern> onScaleChanged;
  final ValueChanged<int> onBpmChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffdde3d6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controls',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Text('Key', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PitchClass.values.map((pitch) {
                return ChoiceChip(
                  label: Text(pitch.label),
                  selected: root == pitch,
                  onSelected: isPlaying ? null : (_) => onRootChanged(pitch),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            Text('Scale', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SegmentedButton<ScalePattern>(
              segments: ScalePattern.values
                  .map(
                    (pattern) => ButtonSegment(
                      value: pattern,
                      label: Text(pattern.label),
                    ),
                  )
                  .toList(),
              selected: {scalePattern},
              onSelectionChanged: isPlaying
                  ? null
                  : (selection) => onScaleChanged(selection.single),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Text('BPM', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$bpm',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Slider(
              value: bpm.toDouble(),
              min: 40,
              max: 220,
              divisions: 180,
              label: '$bpm BPM',
              onChanged: isPlaying
                  ? null
                  : (value) => onBpmChanged(value.round()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffNotation extends StatelessWidget {
  const _StaffNotation({
    required this.root,
    required this.scalePattern,
    required this.notes,
    required this.activeStep,
  });

  final PitchClass root;
  final ScalePattern scalePattern;
  final List<ScaleNote> notes;
  final int? activeStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffdde3d6)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: _StaffPainter(
                root: root,
                scalePattern: scalePattern,
                notes: notes,
                activeStep: activeStep,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeySignature {
  const _KeySignature(this.count);

  final int count;
}

class _StaffPainter extends CustomPainter {
  const _StaffPainter({
    required this.root,
    required this.scalePattern,
    required this.notes,
    required this.activeStep,
  });

  final PitchClass root;
  final ScalePattern scalePattern;
  final List<ScaleNote> notes;
  final int? activeStep;

  static const _staffColor = Color(0xff1f2925);
  static const _mutedColor = Color(0xff768078);
  static const _activeColor = Color(0xff24745f);

  @override
  void paint(Canvas canvas, Size size) {
    final keySignature = _keySignature(root, scalePattern);
    final keySignatureWidth = keySignature.count == 0
        ? 0.0
        : keySignature.count.abs() * 13.0 + 8.0;
    final staffLeft = math.min(
      82.0 + keySignatureWidth,
      math.max(82.0, size.width * 0.32),
    );
    final staffRight = size.width - 18;
    final staffWidth = staffRight - staffLeft;
    final lineSpacing = math.min(13.0, size.width / 34);
    final halfStep = lineSpacing / 2;
    final topLineY = 48.0;
    final bottomLineY = topLineY + lineSpacing * 4;
    final noteAreaWidth = staffWidth - 20;
    final stepX = notes.length <= 1 ? 0.0 : noteAreaWidth / (notes.length - 1);
    final clefX = staffLeft - keySignatureWidth - 54;
    final staffLineLeft = keySignature.count == 0 ? staffLeft : clefX + 42;

    _drawStaff(canvas, staffLineLeft, staffRight, topLineY, lineSpacing);
    _drawClef(canvas, clefX, topLineY - 17);
    _drawKeySignature(canvas, keySignature, clefX + 44, bottomLineY, halfStep);

    for (var index = 0; index < notes.length; index += 1) {
      final note = notes[index];
      final active = activeStep == index;
      final x = staffLeft + 10 + stepX * index;
      final staffStep = _staffStep(note);
      final y = bottomLineY - staffStep * halfStep;

      _drawLedgerLines(canvas, x, y, staffStep, bottomLineY, halfStep);
      _drawNote(canvas, x, y, note, active, bottomLineY, keySignature);
      _drawNoteLabel(canvas, note.label, x, bottomLineY + 48, active);
    }
  }

  void _drawStaff(
    Canvas canvas,
    double left,
    double right,
    double top,
    double spacing,
  ) {
    final paint = Paint()
      ..color = _staffColor
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (var line = 0; line < 5; line += 1) {
      final y = top + spacing * line;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  void _drawClef(Canvas canvas, double x, double y) {
    final painter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: _staffColor,
          fontSize: 42,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x, y));
  }

  void _drawKeySignature(
    Canvas canvas,
    _KeySignature keySignature,
    double x,
    double bottomLineY,
    double halfStep,
  ) {
    if (keySignature.count == 0) {
      return;
    }

    final steps = keySignature.count > 0
        ? const [8, 5, 9, 6, 3, 7, 4]
        : const [4, 7, 3, 6, 2, 5, 1];
    final symbol = keySignature.count > 0 ? '#' : 'b';
    final count = keySignature.count.abs();

    for (var index = 0; index < count; index += 1) {
      final center = Offset(
        x + index * 13,
        bottomLineY - steps[index] * halfStep,
      );
      _drawKeySignatureSymbol(canvas, symbol, center);
    }
  }

  void _drawKeySignatureSymbol(Canvas canvas, String symbol, Offset center) {
    if (symbol == '#') {
      _drawSharpSymbol(canvas, center);
    } else {
      _drawFlatSymbol(canvas, center);
    }
  }

  void _drawSharpSymbol(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = _staffColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 3.5, center.dy - 12),
      Offset(center.dx - 3.5, center.dy + 12),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + 3.5, center.dy - 12),
      Offset(center.dx + 3.5, center.dy + 12),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - 9, center.dy - 4),
      Offset(center.dx + 9, center.dy - 7),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - 9, center.dy + 6),
      Offset(center.dx + 9, center.dy + 3),
      paint,
    );
  }

  void _drawFlatSymbol(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = _staffColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx - 2, center.dy - 15),
      Offset(center.dx - 2, center.dy + 8),
      paint,
    );

    final path = Path()
      ..moveTo(center.dx - 2, center.dy - 1)
      ..quadraticBezierTo(
        center.dx + 10,
        center.dy - 5,
        center.dx + 8,
        center.dy + 4,
      )
      ..quadraticBezierTo(
        center.dx + 6,
        center.dy + 12,
        center.dx - 2,
        center.dy + 8,
      );
    canvas.drawPath(path, paint);
  }

  void _drawLedgerLines(
    Canvas canvas,
    double x,
    double y,
    int staffStep,
    double bottomLineY,
    double halfStep,
  ) {
    final paint = Paint()
      ..color = _staffColor
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final ledgerSteps = <int>[];
    if (staffStep < 0) {
      for (var step = 0; step >= staffStep; step -= 2) {
        if (step < 0) {
          ledgerSteps.add(step);
        }
      }
    } else if (staffStep > 8) {
      for (var step = 10; step <= staffStep; step += 2) {
        ledgerSteps.add(step);
      }
    }

    for (final step in ledgerSteps) {
      final ledgerY = bottomLineY - step * halfStep;
      canvas.drawLine(Offset(x - 13, ledgerY), Offset(x + 13, ledgerY), paint);
    }

    if (staffStep < -1 || staffStep > 9) {
      final markerPaint = Paint()
        ..color = _mutedColor.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 16, markerPaint);
    }
  }

  void _drawNote(
    Canvas canvas,
    double x,
    double y,
    ScaleNote note,
    bool active,
    double bottomLineY,
    _KeySignature keySignature,
  ) {
    final noteColor = active ? _activeColor : _staffColor;
    final notePaint = Paint()
      ..color = noteColor
      ..style = PaintingStyle.fill;
    final stemPaint = Paint()
      ..color = noteColor
      ..strokeWidth = active ? 2.8 : 2.1
      ..strokeCap = StrokeCap.round;
    final radiusX = active ? 10.0 : 8.6;
    final radiusY = active ? 7.2 : 6.2;

    if (active) {
      canvas.drawCircle(
        Offset(x, y),
        17,
        Paint()
          ..color = _activeColor.withValues(alpha: 0.13)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(-0.22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radiusX * 2,
        height: radiusY * 2,
      ),
      notePaint,
    );
    canvas.restore();

    final stemUp = y >= bottomLineY - 4 * (13.0 / 2);
    final stemX = stemUp ? x + radiusX - 1 : x - radiusX + 1;
    final stemEndY = stemUp ? y - 44 : y + 44;
    canvas.drawLine(Offset(stemX, y), Offset(stemX, stemEndY), stemPaint);

    final accidental = _writtenAccidental(note.name, keySignature);
    if (accidental != null) {
      _drawAccidental(canvas, accidental, x - 27, y - 14, active);
    }
  }

  void _drawAccidental(
    Canvas canvas,
    String accidental,
    double x,
    double y,
    bool active,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: accidental,
        style: TextStyle(
          color: active ? _activeColor : _staffColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x, y));
  }

  void _drawNoteLabel(
    Canvas canvas,
    String label,
    double centerX,
    double y,
    bool active,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: active ? _activeColor : _mutedColor,
          fontSize: 12,
          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(centerX - painter.width / 2, y));
  }

  int _staffStep(ScaleNote note) {
    const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final letter = note.name.substring(0, 1);
    final letterIndex = letters.indexOf(letter);
    final e4Index = 4 * 7 + letters.indexOf('E');
    return note.octave * 7 + letterIndex - e4Index;
  }

  String? _accidental(String noteName) {
    if (noteName.contains('bb')) {
      return 'bb';
    }
    if (noteName.contains('##')) {
      return '##';
    }
    if (noteName.contains('b')) {
      return 'b';
    }
    if (noteName.contains('#')) {
      return '#';
    }
    return null;
  }

  String? _writtenAccidental(String noteName, _KeySignature keySignature) {
    final accidental = _accidental(noteName);
    if (accidental == null) {
      return null;
    }

    final letter = noteName.substring(0, 1);
    if (keySignature.count > 0 && accidental == '#') {
      const sharpLetters = ['F', 'C', 'G', 'D', 'A', 'E', 'B'];
      if (sharpLetters.take(keySignature.count).contains(letter)) {
        return null;
      }
    }

    if (keySignature.count < 0 && accidental == 'b') {
      const flatLetters = ['B', 'E', 'A', 'D', 'G', 'C', 'F'];
      if (flatLetters.take(keySignature.count.abs()).contains(letter)) {
        return null;
      }
    }

    return accidental;
  }

  @override
  bool shouldRepaint(covariant _StaffPainter oldDelegate) {
    return oldDelegate.root != root ||
        oldDelegate.scalePattern != scalePattern ||
        oldDelegate.notes != notes ||
        oldDelegate.activeStep != activeStep;
  }
}

_KeySignature _keySignature(PitchClass root, ScalePattern scalePattern) {
  final signatures = scalePattern == ScalePattern.naturalMinor
      ? _minorKeySignatures
      : _majorKeySignatures;
  return _KeySignature(signatures[root] ?? 0);
}

const _majorKeySignatures = {
  PitchClass.c: 0,
  PitchClass.cSharp: 7,
  PitchClass.d: 2,
  PitchClass.eFlat: -3,
  PitchClass.e: 4,
  PitchClass.f: -1,
  PitchClass.fSharp: 6,
  PitchClass.g: 1,
  PitchClass.aFlat: -4,
  PitchClass.a: 3,
  PitchClass.bFlat: -2,
  PitchClass.b: 5,
};

const _minorKeySignatures = {
  PitchClass.c: -3,
  PitchClass.cSharp: 4,
  PitchClass.d: -1,
  PitchClass.eFlat: -6,
  PitchClass.e: 1,
  PitchClass.f: -4,
  PitchClass.fSharp: 3,
  PitchClass.g: -2,
  PitchClass.aFlat: -7,
  PitchClass.a: 0,
  PitchClass.bFlat: -5,
  PitchClass.b: 2,
};
