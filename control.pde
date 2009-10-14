void keyPressed() {
  switch(key) {
    case ' ': // pause/play toggle
      if ( TRACK_LOADED ) {
        if ( audio.isPlaying() ) {
          progressSlider.setValueLabel("PAUSED");
          audio.pause();
        } else {
          progressSlider.setValueLabel("PLAYING");
          audio.play();
        }
      }
      break;
      
    case 'm': // mute toggle
      if ( audio.isMuted() ) {
        audio.unmute();
      } else {
        audio.mute();
      }
      break;
    
    case 'e': // turn equalizer on/off
      EQUALIZER_TOGGLE = !EQUALIZER_TOGGLE;
      break;
    
    case 'p': // turn PCP on/off
      PCP_TOGGLE = !PCP_TOGGLE;
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
  if ( event.isController() ) {
    switch(event.controller().id()) {
      case(1):
        PEAK_THRESHOLD = (int)(event.controller().value());
        break;
      case(2):
        break;
      case(3): // Progress Slider
        // This event is triggered whenever the slider is updated. It is a progress bar updated every buffer iteration.
        cuePosition = (int)(event.controller().value());
        
        if ( cuePosition < lastPosition || cuePosition - lastPosition > 2000 ) { // seeked backwards or forwards
          audio.pause();
          audio.cue(cuePosition);
          frameNumber = round((float)cuePosition / 1000f * (float)audio.sampleRate() / (float)bufferSize);
          audio.play();
          println("seeked");
        }
        
        lastPosition = cuePosition;

        break;
    }
    
    // File List IDs
    if ( event.controller().id() >= 100 ) {
      openAudioFile(audioFiles[(int)event.controller().value()]);
    }
  }
}

void radioWeight(int type) {
  WEIGHT_TYPE = type;
}

void radioMidiDevice(int device) {
  midiOut = RWMidi.getOutputDevices()[device].createOutput();
}

void radioWindow(int mode) {
  window.setMode(mode);
}

void radioSmooth(int mode) {
  smoother.setMode(mode, SMOOTH_POINTS);
}

void togglePCP(boolean flag) {
  PCP_TOGGLE = flag;
}

void toggleMIDI(boolean flag) {
  MIDI_TOGGLE = flag;
  if ( ! MIDI_TOGGLE ) {
    closeNotes();
  }
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

void balance(int value) {
  balanceSlider.setValueLabel(value + "%");
  if ( value == 0 ) {
    balanceSlider.setValueLabel("  CENTER");
  } else if ( value < 0 ) {
    balanceSlider.setValueLabel(value * -1 + "% LEFT");
  } else if ( value > 0 ) {
    balanceSlider.setValueLabel(value + "% RIGHT");
  }
}


