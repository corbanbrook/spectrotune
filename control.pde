void keyPressed() {
  switch(key) {
    case ' ': // save spectrograph and quit
      if ( TRACK_LOADED ) {
        PLAYING = !PLAYING;
        if ( !PLAYING ) {
          progressSlider.setValueLabel("PAUSED");
        }
      }
      break;
    
    /* case 's': // save spectrograph and quit
      saveSpectrograph();
      exit();
      break; */
    
    case 'e': // turn equalizer on/off
      EQUALIZER_TOGGLE = !EQUALIZER_TOGGLE;
      //fft.equalizer(EQUALIZER_TOGGLE);
      break;
    
    case 'p': // turn PCP on/off
      PCP_TOGGLE = !PCP_TOGGLE;
      break;
      
    case 'o': // turn smoothing on/off
      SMOOTH_TOGGLE = !SMOOTH_TOGGLE;
      if ( SMOOTH_TOGGLE ) {
        //fft.smooth(SMOOTH_TYPE, SMOOTH_POINTS);
      } else {
        //fft.noSmooth();
      }
      break;
    
    case 'v': // turn envelope on/off
      ENVELOPE_TOGGLE = !ENVELOPE_TOGGLE;
      if ( ENVELOPE_TOGGLE ) { 
        //fft.envelope(ENVELOPE_CURVE);
      } else {
        //fft.noEnvelope();
      }
      break;
    
    // Octave Toggles
    case '0':
      OCTAVE_TOGGLE[0] = !OCTAVE_TOGGLE[0];
      break;
    case '1':
      OCTAVE_TOGGLE[1] = !OCTAVE_TOGGLE[1];
      break;
    case '2':
      OCTAVE_TOGGLE[2] = !OCTAVE_TOGGLE[2];
      break;
    case '3':
      OCTAVE_TOGGLE[3] = !OCTAVE_TOGGLE[3];
      break;
    case '4':
      OCTAVE_TOGGLE[4] = !OCTAVE_TOGGLE[4];
      break;
    case '5':
      OCTAVE_TOGGLE[5] = !OCTAVE_TOGGLE[5];
      break;
    case '6':
      OCTAVE_TOGGLE[6] = !OCTAVE_TOGGLE[6];
      break;
    case '7':
      OCTAVE_TOGGLE[7] = !OCTAVE_TOGGLE[7];
      break;
  }
  
  switch(keyCode) {
    case UP:
      PEAK_THRESHOLD += 5;
      break;
      
    case DOWN:
      PEAK_THRESHOLD -= 5;
      break;
      
    case RIGHT:
      SMOOTH_POINTS++;
      if ( SMOOTH_TOGGLE ) {
        //fft.smooth(SMOOTH_TYPE, SMOOTH_POINTS);
      }
      break;
      
    case LEFT:
      if ( SMOOTH_POINTS > 3 ) {
        SMOOTH_POINTS--;
        if ( SMOOTH_TOGGLE ) {
          //fft.smooth(SMOOTH_TYPE, SMOOTH_POINTS);
        }
      }
      break;
  }
}

// ControlP5 events
void controlEvent(ControlEvent event) {
  switch(event.controller().id()) {
    case(1):
      PEAK_THRESHOLD = (int)(event.controller().value());
      break;
    case(2):
      break;
    case(3): // Progress Slider
      PLAYING = true;
      frameNumber = (int)(event.controller().value());
      break;
  }
  
  // File List IDs
  if ( event.controller().id() >= 100 ) {
    audioFile = files[(int)event.controller().value()];
    
    audio = minim.loadSample(sketchPath + "/music/" + audioFile, bufferSize);
    samples = audio.getChannel(BufferedAudio.LEFT);
    
    fft = new FFT(bufferSize, audio.sampleRate());
    fft.window(FFT.HAMMING);
  
    hFrames = int(audio.length() / 1000.0 * framesPerSecond);
  
    println("Audio source: " + audioFile + " " + audio.length() / 1000 + " seconds (" + hFrames + " frames)");
    println("Time size: " + bufferSize + " bytes / Sample rate: " + audio.sampleRate() / 1000.0 + "kHz");
    println("FFT bandwidth: " + (2.0 / bufferSize) * ((float)audio.sampleRate() / 2.0) + "Hz");
  
    // Setup Arrays
    spectrum = new float[hFrames][fftSize];
    peak = new int[hFrames][fftSize];
    pitch = new boolean[hFrames][128];
    level = new float[hFrames][128];
    pcp = new float[hFrames][12];
    
    precomputeOctaveRegions();
    precomputeScale();
    
    progressSlider.setMax(hFrames);
    
    frameNumber = 0;
    
    TRACK_LOADED = true;
    PLAYING = true;
  }
}

void radioWeight(int type) {
  WEIGHT_TYPE = type;
}

void radioMidiDevice(int device) {
  midiOut = RWMidi.getOutputDevices()[device].createOutput();
} 

void togglePCP(boolean flag) {
  PCP_TOGGLE = flag;
}

void toggleScaleLock(boolean flag) {
  SCALE_LOCK_TOGGLE = flag;
}

void toggleHarmonics(boolean flag) {
  HARMONICS_TOGGLE = flag;
}

void oct0(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[0] = channel -1;
  }
}
void oct1(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[1] = channel -1;
  }
}
void oct2(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[2] = channel -1;
  }
}
void oct3(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[3] = channel -1;
  }
}
void oct4(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[4] = channel -1;
  }
}
void oct5(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[5] = channel -1;
  }
}
void oct6(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[6] = channel -1;
  }
}
void oct7(int channel) {
  if (channel > 0) {
    OCTAVE_CHANNEL[7] = channel -1;
  }
}

