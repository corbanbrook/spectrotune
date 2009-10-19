class Note {
  float frequency;
  float amplitude;
  
  int octave;
  int semitone;
  
  int channel;
  
  int pitch;
  
  Note(float frequency, float amplitude) {
    this.frequency = frequency;   
    this.amplitude = amplitude;
    this.pitch = freqToPitch(frequency);
    this.octave = this.pitch / 12 - 1;
    this.semitone = this.pitch % 12;
    this.channel = OCTAVE_CHANNEL[this.octave];
  }
  
  public String label() {
    return semitones[this.semitone] + this.octave;
  }
  
  boolean isWhiteKey() {
    return keyboard[this.pitch % 12];
  }
  
  boolean isBlackKey() {
    return !keyboard[this.pitch % 12];
  }
}
