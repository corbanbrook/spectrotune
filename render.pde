void render() {
  image(bg, 0, 0); // render the background
  
  int keyHeight = height / (keyboardEnd - keyboardStart);
  
  strokeWeight(1);
  stroke(0);
  
  // Render octave toggle buttons for active octaves
  for ( int i = 0; i < 8; i++ ) {
    if ( OCTAVE_TOGGLE[i] ) {
      image(octaveBtn, 0, height - (i * 36) - 36);
    }
  }
  
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
      
    if ( audio.isPlaying() ) {
      // Update Progress bar
      float percentComplete = audio.position() / (float)audio.length() * 100;
      progressSlider.setValue(audio.position());
      progressSlider.setValueLabel(nf(round(percentComplete), 2) + "%");
      
      // Log FPS and % complete
      if ( frameNumber % 100 == 0 ) {
        println("  " + round(percentComplete) + "% complete (" + round(frameRate) + " fps)" + " frame #: " + frameNumber);
      }
    } // end if audio.isPlaying 
  } else {
    progressSlider.setValueLabel("NO FILE LOADED");
  }
  
  // Render GUI pane
  fill(0, 200);
  rect(width - 140, 0, width, height);
 
  // Render Windowing curve
  if ( controlP5.window(this).currentTab().name() == "windowing" ) {
    renderWindowCurve();
  }
 
  // Render Buildingsky logo on top of it all
  image(logo, 25, 254);
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
