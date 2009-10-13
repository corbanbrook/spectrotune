// midi functions for midi octave segregation
// Output text and MIDI

void outputMIDI() {
  for ( int k = keyboardStart; k < keyboardEnd; k++ ) {
    int octave = k / 12 - 1; // MIDI notes start at octave -1 so we need to subtrack 1 to get the actual octave
    int semitone = k % 12;
    
    if ( pitch[frameNumber][k] ) {
      if ( frameNumber > 0 && !pitch[frameNumber-1][k] ) {
        midiOut.sendNoteOn(OCTAVE_CHANNEL[octave], k, 90);
      } else if ( frameNumber == 0 && pitch[0][k] ) {
        midiOut.sendNoteOn(OCTAVE_CHANNEL[octave], k, 90);
      }
    }
    if ( frameNumber > 0 && pitch[frameNumber -1][k] && !pitch[frameNumber][k] ) { // was on now its not
      midiOut.sendNoteOff(OCTAVE_CHANNEL[octave], k, 90);
    }
  }
}
