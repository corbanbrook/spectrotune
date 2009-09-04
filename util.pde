int freqToPitch(float f) {
  int p = round(69.0 + 12.0 *(log(f/440.0) / log(2.0)));
  if ( p > 0 && p < 128 ) {
    return p;
  } else {
    return 0;
  }
}

float pitchToFreq(int p) {
  return 440.0 * pow(2, (p - 69) / 12.0);
}

// Find the lowest frequency in an octave range
float octaveLowRange(int octave) {
  // find C - C0 is MIDI note 12
  return pitchToFreq(12 + octave * 12);
}

// Find the highest frequency in an octave range
float octaveHighRange(int octave) {
  // find B - B0 is MIDI note 23
  return pitchToFreq(23 + octave * 12);
}

// Types of FFT bin weighting algorithms 
public static final int UNIFORM = 0;
public static final int DISCRETE = 1;
public static final int LINEAR = 2;
public static final int QUADRATIC = 3;
public static final int EXPONENTIAL = 4;

int WEIGHT_TYPE = UNIFORM; // default

// Applies FFT bin weighting. x is the distance from a real semi-tone
float binWeight(int type, float x) {
  switch(type) {
    case DISCRETE:
      return (x <= 0.2) ? 1.0 : 0.0;
    case LINEAR:
      return 1 - x;
    case QUADRATIC:
      return 1.0 - pow(x, 2);
    case EXPONENTIAL: 
      return pow(exp(1.0), 1.0 - x)/exp(1.0);
    case UNIFORM:
    default: 
      return 1.0;
  }
}

/*
// Save an image of the spectrograph
void saveSpectrograph() {
  for ( int x = 0; x < frameNumber; x++ ) {
    // write spectrum array to PImage then save.
    for ( int y = 0; y < fftSize; y++ ) {
      color c = color(255.0 * spectrum[x][y] / 300, 255.0 * spectrum[x][y] * 10 / 300 , 255.0 * spectrum[x][y] * 20 / 300);

      spectrograph.set(x,spectrographHeight - y, c);
                
      switch ( peak[x][y] ) {
        case PEAK:
          spectrograph.set(x, spectrographHeight -y, color(255, 0, 100));
          break;  
        case VALLEY: 
          //img.set(x, imgHeight -y, color(0, 0, 0));
          break;
        case HARMONIC:
          spectrograph.set(x, spectrographHeight -y, color(255, 200, 0));
          break;
      }
    }
  }
    
  spectrograph.save("spectrograph.png");
  println("spectrograph saved.");
} */

void switchLabel(boolean toggle, String label, int pos) {
  pos *= 12;
  pos += 10;
  if (toggle) {
    fill(200, 255, 255);
  } else {
    fill(80, 200);
  }
  text(label, width - 120, pos);
  rect(width - 120 - 10, - 7 + pos, width - 120  - 5, pos);
}

void valLabel(int val, String label, int pos) {
  pos *= 12;
  pos += 10;

  fill(255, 255, 100);
  
  text(label, width - 120, pos);
  
  fill(255, 160, 60);
  text(val, width -50, pos);
}

void normalizePCP() {
  float pcpMax = max(pcp[frameNumber]);
  for ( int k = 0; k < 12; k++ ) {
    pcp[frameNumber][k] /= pcpMax;
  }
}

void precomputeOctaveRegions() {
  for ( int j = 0; j < 8; j++) {
    fftBinStart[j] = 0;
    fftBinEnd[j] = 0;
    for ( int k = 0; k < fftSize; k++) {
      float freq = k / (float)bufferSize * audio.sampleRate();
      if ( freq >= octaveLowRange(j) && fftBinStart[j] == 0 ) {
        fftBinStart[j] = k;
      } else if ( freq > octaveHighRange(j) && fftBinEnd[j] == 0 ) {
        fftBinEnd[j] = k;
        break;
      }
    }
  }
}

void precomputeScale() {
  float freqLowRange = octaveLowRange(0);
  float freqHighRange = octaveHighRange(8);
  float[] bins = new float[fftSize];
  

  
  for ( int i = hFrames/2; i < hFrames; i++ ) {
    int offset = (int)(i * audio.sampleRate() / framesPerSecond);
    if ( offset + bufferSize > samples.length ) { println(i + "/" + hFrames + " frames computed."); break; }
    
    arraycopy(samples, offset, buffer, 0, bufferSize);
    fft.forward(buffer);
    
    for ( int j = 0; j < 8; j++ ) {
      float octaveMax = 0;
      for ( int k = fftBinStart[j]; k < fftBinEnd[j]; k++ ) {
        float freq = k / (float)bufferSize * audio.sampleRate();
        if ( octaveMax < fft.getBand(k) ) {
          octaveMax = fft.getBand(k);
        }        
      }
      for ( int k = fftBinStart[j]; k < fftBinEnd[j]; k++ ) {
        float freq = k / (float)bufferSize * audio.sampleRate();
        scaleProfile[freqToPitch(freq) % 12] += (fft.getBand(k) / octaveMax);
      }
    }
    /*
    for ( int k = 0; k < fftSize; k++ ) {
              float freq = k / (float)bufferSize * audio.sampleRate();
        scaleProfile[freqToPitch(freq) % 12] += (fft.getBand(k));
    }
    */
  }
  
  // Normalize scaleProfile
  float scaleMax = max(scaleProfile);
  for ( int i = 0; i < 12; i++ ) {
    scaleProfile[i] /= scaleMax;
  }
  
  float[] weakest = sort(scaleProfile);
  for ( int i = 0; i < 12; i++ ) {
    boolean inScale = true;
    for ( int j = 0; j < 5; j++ ) {
      if (scaleProfile[i] == weakest[j]) {
        inScale = false;
        break;
      }
    }
    if ( inScale ) {
      scaleProfile[i] = 1.5;
      println(semitones[i]);
    }
  }  
  println("Done precomputing Scale");
}
