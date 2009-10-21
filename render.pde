void render() {
  image(bg, 0, 0); // Render the background
  
  // Render octave toggle buttons for active octaves
  for ( int i = 0; i < 8; i++ ) {
    if ( OCTAVE_TOGGLE[i] ) {
      image(octaveBtn, 0, height - (i * 36) - 36);
    }
  }
  
  String selectedTab = controlP5.window(this).currentTab().name();
  
  if ( selectedTab == "windowing") {
    renderWindowCurve();
  } else if ( selectedTab == "FFT" ) {
    renderFFT();
  } else {
    renderPeaks();
  }
  
  // Update progress bar
  if ( isLoaded() ) {
    if ( audio.isPlaying() ) {
      float percentComplete = audio.position() / (float)audio.length() * 100;
      sliderProgress.setValue(audio.position());
      sliderProgress.setValueLabel(nf(round(percentComplete), 2) + "%");
    } 
  } else {
    sliderProgress.setValueLabel("NO FILE LOADED");
  }
  
  // Render semi transparent UI background
  fill(0, 200);
  rect(width - 140, 0, width, height);
 
  // Render Buildingsky logo on top of it all
  image(logo, 25, 254);
}

void renderPeaks() {
  int keyHeight = height / (keyboardEnd - keyboardStart);
  
  if ( isLoaded() ) {
    // render key presses for detected peaks
    for ( int i = 0; i < notes[frameNumber].length; i++ ) {
      Note note = notes[frameNumber][i];
      if ( note.isWhiteKey() ) {
        image(whiteKey, 10, height - ((note.pitch - keyboardStart) * keyHeight + keyHeight));
      } else if ( note.isBlackKey() ) {
        image(blackKey, 10, height - ((note.pitch - keyboardStart) * keyHeight + keyHeight));
      }
    }
    
    // render detected peaks
    noStroke();
    int keyLength = 10;
    int scroll = (frameNumber * keyLength > width) ? frameNumber - width/keyLength: 0;

    for ( int x = frameNumber; x >= scroll; x-- ) {
      for ( int i = 0; i < notes[x].length; i++ ) {
        Note note = notes[x][i];
        
        color noteColor;
        
        if ( pcp[x][note.pitch % 12] == 1.0 ) {
          noteColor = color(255, 100 * note.amplitude / 400, 0);
        } else {
          noteColor = color(0, 255 * note.amplitude / 400, 200);
        }
        
        fill(red(noteColor)/4, green(noteColor)/4, blue(noteColor)/4);
        rect(abs(x - frameNumber) * keyLength + 24, height - ((note.pitch - keyboardStart) * keyHeight), abs(x - frameNumber) * keyLength + keyLength + 25 , height - ((note.pitch - keyboardStart) * keyHeight + keyHeight));
          
        fill(noteColor);
        rect(abs(x - frameNumber) * keyLength + 24, height - ((note.pitch - keyboardStart) * keyHeight) - 1, abs(x - frameNumber) * keyLength + keyLength + 24 , height - ((note.pitch - keyboardStart) * keyHeight + keyHeight));
      }
    }

    // output semitone text labels 
    textSize(10);
    
    for ( int i = 0; i < notes[frameNumber].length; i++ ) {
      Note note = notes[frameNumber][i];
      
      fill(20);
      text(note.label(), 24 + 1, height - ((note.pitch - keyboardStart) * keyHeight + keyHeight + 1));
        
      fill(140);
      text(note.label(), 24, height - ((note.pitch - keyboardStart) * keyHeight + keyHeight + 2));
    }
  }
}

void renderWindowCurve() {
  int windowX = 35;
  int windowY = 110;
  int windowHeight = 80;
  stroke(255, 255, 255, 250);

  float[] windowCurve = window.drawCurve();
  
  for (int i = 0; i < windowCurve.length - 1; i++) {
    line(i + windowX, windowY - windowCurve[i] * windowHeight, i+1 + windowX, windowY - windowCurve[i+1] * windowHeight);  
  }
  
  noStroke();
}

void renderFFT() {
  /*stroke(255);
  for ( int i = 0; i < spectrum.length; i+=5) {
    line(i/5, height, i/5, height - spectrum[i] * 2);
  }
  noStroke();*/
  
  noStroke();

  int keyHeight = height / (keyboardEnd - keyboardStart);
  color noteColor;
  float[] amp = new float[128];
  
  int previousPitch = -1;
  int currentPitch;
  float amplitudeTotal = 0f;
  
  if ( isLoaded() ) {
  for ( int k = 0; k < spectrum.length; k++ ) {
    float freq = k / (float)fftBufferSize * audio.sampleRate();
    
    currentPitch = freqToPitch(freq);
    
    if ( currentPitch == previousPitch ) {
      amp[currentPitch] = amp[currentPitch] > spectrum[k] ? amp[currentPitch] : spectrum[k]; 
    } else {
      amp[currentPitch] = spectrum[k]; 
      previousPitch = currentPitch;
    }
  }
  
  for ( int i = keyboardStart; i < keyboardEnd; i++) {
    noteColor = color(255, 100 * amp[i] / 400, 0);
    
    fill(red(noteColor)/4, green(noteColor)/4, blue(noteColor)/4);
    rect(24, height - ((i - keyboardStart) * keyHeight), 25 + amp[i], height - ((i - keyboardStart) * keyHeight + keyHeight)); // shadow
        
    fill(noteColor);
    rect(24, height - ((i - keyboardStart) * keyHeight) - 1, 24 + amp[i] , height - ((i - keyboardStart) * keyHeight + keyHeight));
  }
  }
  stroke(255);
  line(PEAK_THRESHOLD + 24, 0, PEAK_THRESHOLD + 24, height);
  noStroke();
}
