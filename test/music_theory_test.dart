import 'package:flutter_test/flutter_test.dart';
import 'package:scale_buddy/src/music/music_theory.dart';

void main() {
  test('builds C major across one octave', () {
    final scale = buildScale(
      root: PitchClass.c,
      pattern: ScalePattern.major,
      octave: 4,
    );

    expect(scale.map((note) => note.label), [
      'C4',
      'D4',
      'E4',
      'F4',
      'G4',
      'A4',
      'B4',
      'C5',
    ]);
  });

  test('builds Eb natural minor with octave rollover', () {
    final scale = buildScale(
      root: PitchClass.eFlat,
      pattern: ScalePattern.naturalMinor,
      octave: 4,
    );

    expect(scale.map((note) => note.label), [
      'Eb4',
      'F4',
      'Gb4',
      'Ab4',
      'Bb4',
      'Cb5',
      'Db5',
      'Eb5',
    ]);
  });

  test('calculates A4 as 440 hertz', () {
    expect(midiNoteToFrequency(69), closeTo(440, 0.001));
  });
}
