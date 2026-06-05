import 'dart:math' as math;

enum PitchClass {
  c(0, 'C'),
  cSharp(1, 'C#'),
  d(2, 'D'),
  eFlat(3, 'Eb'),
  e(4, 'E'),
  f(5, 'F'),
  fSharp(6, 'F#'),
  g(7, 'G'),
  aFlat(8, 'Ab'),
  a(9, 'A'),
  bFlat(10, 'Bb'),
  b(11, 'B');

  const PitchClass(this.semitone, this.label);

  final int semitone;
  final String label;
}

enum ScalePattern {
  major('Major', [0, 2, 4, 5, 7, 9, 11, 12]),
  naturalMinor('Minor', [0, 2, 3, 5, 7, 8, 10, 12]),
  pentatonic('Pentatonic', [0, 2, 4, 7, 9, 12]);

  const ScalePattern(this.label, this.intervals);

  final String label;
  final List<int> intervals;
}

class ScaleNote {
  const ScaleNote({
    required this.pitchClass,
    required this.name,
    required this.octave,
    required this.midiNote,
    required this.frequency,
  });

  final PitchClass pitchClass;
  final String name;
  final int octave;
  final int midiNote;
  final double frequency;

  String get label => '$name$octave';
}

List<ScaleNote> buildScale({
  required PitchClass root,
  required ScalePattern pattern,
  int octave = 4,
}) {
  final names = _usesFlatNames(root)
      ? const ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B']
      : const ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  return pattern.intervals
      .map((interval) {
        final index = pattern.intervals.indexOf(interval);
        final absoluteSemitone = root.semitone + interval;
        final pitchClass = PitchClass.values.firstWhere(
          (pitch) => pitch.semitone == absoluteSemitone % 12,
        );
        final noteOctave = octave + absoluteSemitone ~/ 12;
        final midiNote = 12 * (noteOctave + 1) + pitchClass.semitone;
        final noteName = _noteName(
          root,
          pattern,
          index,
          pitchClass.semitone,
          names,
        );
        return ScaleNote(
          pitchClass: pitchClass,
          name: noteName,
          octave: _displayOctave(noteName, pitchClass.semitone, noteOctave),
          midiNote: midiNote,
          frequency: midiNoteToFrequency(midiNote),
        );
      })
      .toList(growable: false);
}

double midiNoteToFrequency(int midiNote) {
  return (440 * math.pow(2, (midiNote - 69) / 12)).toDouble();
}

bool _usesFlatNames(PitchClass root) {
  return switch (root) {
    PitchClass.f ||
    PitchClass.eFlat ||
    PitchClass.aFlat ||
    PitchClass.bFlat => true,
    _ => false,
  };
}

String _noteName(
  PitchClass root,
  ScalePattern pattern,
  int degree,
  int semitone,
  List<String> fallbackNames,
) {
  if (pattern == ScalePattern.pentatonic) {
    return fallbackNames[semitone];
  }

  const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  const naturalSemitones = {
    'C': 0,
    'D': 2,
    'E': 4,
    'F': 5,
    'G': 7,
    'A': 9,
    'B': 11,
  };

  final rootLetter = root.label.substring(0, 1);
  final rootLetterIndex = letters.indexOf(rootLetter);
  final letter = letters[(rootLetterIndex + degree) % letters.length];
  final naturalSemitone = naturalSemitones[letter]!;
  final accidental = _signedSemitoneDistance(naturalSemitone, semitone);

  return switch (accidental) {
    -2 => '${letter}bb',
    -1 => '${letter}b',
    0 => letter,
    1 => '$letter#',
    2 => '$letter##',
    _ => fallbackNames[semitone],
  };
}

int _signedSemitoneDistance(int from, int to) {
  final raw = (to - from) % 12;
  return raw > 6 ? raw - 12 : raw;
}

int _displayOctave(String noteName, int semitone, int pitchOctave) {
  if (noteName.startsWith('C') && semitone == 11) {
    return pitchOctave + 1;
  }
  if (noteName.startsWith('B') && semitone == 0) {
    return pitchOctave - 1;
  }
  return pitchOctave;
}
