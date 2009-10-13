void render() {
  image(bg, 0, 0); // render the background
  
  int keyHeight = height / (keyboardEnd - keyboardStart);
  
  strokeWeight(1);
  stroke(0);
  
  // Render octave toggle buttons for active octaves
  for ( int i = 0; i < 8; i++ ) {
    if (OCTAVE_TOGGLE[i]) {
      image(octaveBtn, 0, height - (i * 36) - 36);
    }
  }
  
  if ( TRACK_LOADED ) {
    // Render key presses for detected peaks
    for ( int k = keyboardStart; k < keyboardEnd; k++ ) {
      if ( pitch[frameNumber][k] && keyboard[k%12]) {
        image(whiteKey, 10, height - ((k - keyboardStart) * keyHeight + keyHeight));
      }
      if ( pitch[frameNumber][k] && !keyboard[k%12]) {
        image(blackKey, 10, height - ((k - keyboardStart) * keyHeight + keyHeight));
      }
    }
    
    // Render detected peaks
    noStroke();
    int keyLength = 10;
    int scroll = (frameNumber * keyLength > width) ? frameNumber - width/keyLength: 0;
    for (int x = frameNumber; x >= scroll; x--) {
      for (int k = keyboardStart; k < keyboardEnd; k++) {
        if ( pitch[x][k] ) {
          color noteColor;
          if ( pcp[x][k % 12] == 1.0 ) {
            noteColor = color(255, 100 * level[x][k]/400, 0);
          } else {
            noteColor = color(0, 255 * level[x][k]/400, 200);
          }
          fill(red(noteColor)/4, green(noteColor)/4, blue(noteColor)/4);
          rect(abs(x - frameNumber) * keyLength + 24, height - ((k - keyboardStart) * keyHeight),abs(x - frameNumber) * keyLength + keyLength + 25 , height - ((k - keyboardStart) * keyHeight + keyHeight));
          
          fill(noteColor);
          rect(abs(x - frameNumber) * keyLength + 24, height - ((k - keyboardStart) * keyHeight) - 1,abs(x - frameNumber) * keyLength + keyLength + 24 , height - ((k - keyboardStart) * keyHeight + keyHeight));
        }
      }
    }

    if ( audio.isPlaying() ) {
      // Output text and MIDI
      for ( int k = keyboardStart; k < keyboardEnd; k++ ) {
        int octave = k / 12 - 1; // MIDI notes start at octave -1 so we need to subtrack 1 to get the actual octave
        int semitone = k % 12;
        
        if ( pitch[frameNumber][k] ) {
          textSize(10);
          
          fill(20);
          text(semitones[semitone] + "" + octave, 24 + 1, height - ((k - keyboardStart) * keyHeight + keyHeight + 1));
          
          fill(140);
          text(semitones[semitone] + "" + octave, 24, height - ((k - keyboardStart) * keyHeight + keyHeight + 2));
        }
      }
      
      // Update Progress bar
      float percentComplete = audio.position() / (float)audio.length() * 100;
      progressSlider.setValue(audio.position());
      progressSlider.setValueLabel(nf(round(percentComplete), 2) + "%");
      
      // Log FPS and % complete
      if (frameNumber % 100 == 0 && audio.isPlaying() ) {
        println("  " + round(percentComplete) + "% complete (" + round(frameRate) + " fps)" + " frame #: " + frameNumber);
      }
    } // end if audio.isPlaying
  } else {
    progressSlider.setValueLabel("NO FILE LOADED");
  } // end if TRACK_LOADED
  
  // Render GUI pane
  fill(0, 200);
  rect(width - 140, 0, width, height);
 
  // Render Windowing curve
  if ( controlP5.window(this).currentTab().name() == "windowing" ) {
    int windowX = 35;
    int windowY = 110;
    int windowHeight = 80;
    stroke(100, 255, 240, 250);

    float[] windowCurve = window.drawCurve();
    for (int i = 0; i < windowCurve.length - 1; i++) {
      line(i + windowX, windowY - windowCurve[i] * windowHeight, i+1 + windowX, windowY - windowCurve[i+1] * windowHeight);  
    }
    noStroke();
  }
 
  // Render Buildingsky logo on top of it all
  image(logo, 25, 254);
}
