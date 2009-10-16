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

void normalizePCP() {
  float pcpMax = max(pcp[frameNumber]);
  for ( int k = 0; k < 12; k++ ) {
    pcp[frameNumber][k] /= pcpMax;
  }
}

void zeroPadBuffer() {
  for (int i = 0; i < fftBufferSize; i++) {
    buffer[i] = 0f;
  }  
}

void precomputeOctaveRegions() {
  for ( int j = 0; j < 8; j++) {
    fftBinStart[j] = 0;
    fftBinEnd[j] = 0;
    for ( int k = 0; k < fftSize; k++) {
      float freq = k / (float)fftBufferSize * audio.sampleRate();
      if ( freq >= octaveLowRange(j) && fftBinStart[j] == 0 ) {
        fftBinStart[j] = k;
      } else if ( freq > octaveHighRange(j) && fftBinEnd[j] == 0 ) {
        fftBinEnd[j] = k;
        break;
      }
    }
  }
  println("Start: " + fftBinStart[0] + " End: " + fftBinEnd[7] + " (" + fftSize + " total)");
}

// TODO: Not sure how to precompute the scale with an AudioPlayer. Might need to load up peices of the audio file in a buffer first.
void precomputeScale() {
  float freqLowRange = octaveLowRange(0);
  float freqHighRange = octaveHighRange(8);
  float[] bins = new float[fftSize];
  int computedFrames = 0;
  for ( int i = frames/2; i < frames; i++ ) {
    if ( i > frames * 0.75 ) { break; } 
    
    int offset = (int)(i * audio.sampleRate() / framesPerSecond);
    //arraycopy(audio.getChannel(BufferedAudio.LEFT), offset, buffer, 0, bufferSize);
    
    fft.forward(buffer);
    
    /* 
    // Normalize each octave before adding to ScaleProfile semitone bin
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
    */
    
    // Un-normalized method -- think it works better
    for ( int k = 0; k < fftSize; k++ ) {
      float freq = k / (float)bufferSize * audio.sampleRate();
      scaleProfile[freqToPitch(freq) % 12] += (fft.getBand(k));
    }
    
    computedFrames++;
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
      scaleProfile[i] = 1.2; // boost by 20%
      print(semitones[i] + " ");
    }
  } 
  println("\nDone computing scale. " + computedFrames + "/" + frames);
}

void openAudioFile(String audioFile) {
    if ( TRACK_LOADED ) {
      audio.pause();
      audio.close();
      
      loadedAudioFile = "";
      
      progressSlider.setValue(0);
      progressSlider.setMax(0);
     
      TRACK_LOADED = false; 
    }
   
    audio = minim.loadFile(sketchPath + "/music/" + audioFile, bufferSize);
    
    
    
    audio.addListener(sampler);
    
    frames = round((float)audio.length() / 1000f * (float)audio.sampleRate() / (float)bufferSize);
    
    println("\nAudio source: " + audioFile + " " + audio.length() / 1000 + " seconds (" + frames + " frames)");
    println("Time size: " + bufferSize + " bytes / Sample rate: " + audio.sampleRate() / 1000f + "kHz");
    println("FFT bandwidth: " + (2.0 / bufferSize) * ((float)audio.sampleRate() / 2.0) + "Hz");
    
    if (audio.type() == Minim.STEREO) {      
      println("Channels: 2 (STEREO)\n");
    } else {
      println("Channels: 1 (MONO)\n");
    }
    
    fft = new FFT(fftBufferSize, audio.sampleRate());
    
    // Setup Arrays
    pitch = new boolean[frames][128];  // MIDI note was detected at this position
    level = new float[frames][128];    // level of MIDI note at this position
    pcp = new float[frames][12];       // PitchClassProfile at this frame
    
    precomputeOctaveRegions();
    //precomputeScale(); // disabled for now.
    
    progressSlider.setMax(audio.length());
    cuePosition = audio.position();
    
    // Switch back to general tab
    controlP5.window(this).activateTab("default");
    
    frameNumber = -1;
    
    loadedAudioFile = audioFile;
    TRACK_LOADED = true;
    audio.play();
}

boolean isLoaded() {
  if ( TRACK_LOADED && frameNumber > -1 ) {
    return true;
  } else {
    return false;
  }
}
