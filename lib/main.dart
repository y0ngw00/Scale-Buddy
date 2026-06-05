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

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      setState(() {
        _isPlaying = false;
        _activeStep = null;
      });
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
                    const Icon(Icons.graphic_eq, size: 34),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: _ControlPanel(
                  root: _root,
                  scalePattern: _scalePattern,
                  bpm: _bpm,
                  isPlaying: _isPlaying,
                  onRootChanged: (value) => setState(() => _root = value),
                  onScaleChanged: (value) {
                    setState(() => _scalePattern = value);
                  },
                  onBpmChanged: (value) => setState(() => _bpm = value),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: SliverToBoxAdapter(
                child: _ScaleStrip(notes: scale, activeStep: _activeStep),
              ),
            ),
          ],
        ),
      ),
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

class _ScaleStrip extends StatelessWidget {
  const _ScaleStrip({required this.notes, required this.activeStep});

  final List<ScaleNote> notes;
  final int? activeStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = constraints.maxWidth >= 560 ? 68.0 : 56.0;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: notes.asMap().entries.map((entry) {
                final index = entry.key;
                final note = entry.value;
                final active = activeStep == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: tileWidth,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xff24745f) : Colors.white,
                    border: Border.all(
                      color: active
                          ? const Color(0xff24745f)
                          : const Color(0xffdde3d6),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    note.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: active ? Colors.white : const Color(0xff1f2925),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
