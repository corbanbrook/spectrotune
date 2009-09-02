void render() {
  image(bg, 0, 0); // render the background
  
  // MIDI notes span from 0 - 128, octaves -1 -> 9. Specify start and end for piano
  int keyboardStart = 12; // 12 is octave C0
  int keyboardEnd = 108;
  int keyHeight = height / (keyboardEnd - keyboardStart);
  
  strokeWeight(1);
  stroke(0);
  
  // Render octave toggle buttons for active octaves
  for ( int i = 0; i < 8; i++ ) {
    if (OCTAVE_TOGGLE[i]) {
      image(octaveBtn, 0, height - (i * 36) - 36);
    }
  }
  
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
  
  // Output text and MIDI
  for ( int k = keyboardStart; k < keyboardEnd; k++ ) {
    if ( pitch[frameNumber][k] ) {
      int octave = k / 12 - 1; // MIDI notes start at octave -1 so we need to subtrack 1 to get the actual octave
      int semitone = k % 12;
      
      int fontSize = 10;
      textSize(fontSize);
      
      fill(20);
      text(semitones[semitone] + "" + octave, 24 + 1, height - ((k - keyboardStart) * keyHeight + keyHeight + 1));
      
      fill(140);
      text(semitones[semitone] + "" + octave, 24, height - ((k - keyboardStart) * keyHeight + keyHeight + 2));
      
      if ( frameNumber > 0 && !pitch[frameNumber-1][k] ) {
        midiOut.sendNoteOn(OCTAVE_CHANNEL[octave], k, 90);
      } else if ( frameNumber == 0 && pitch[0][k] ) {
        midiOut.sendNoteOn(OCTAVE_CHANNEL[octave], k, 90);
      }
    }
    
    for ( int p = keyboardStart; p < keyboardEnd; p ++ ) {
      if ( frameNumber > 0 && !pitch[frameNumber][p] && pitch[frameNumber -1][p] ) { // was on now its not
        //midiOut.sendNoteOff(0, p, 90);
      }
    }
  }
   
  // Render GUI pane
  fill(0, 200);
  rect(width - 140, 0, width, height);
  
  // Render Pitch Class Profile
  if ( PCP_TOGGLE ) {
    for ( int k = 0; k < 12; k++ ) {
      float colorWeight = pcp[frameNumber][k];
      fill(0, 255 * colorWeight, 200, 255 * colorWeight);
      rect((width - 130) + k * 10, 30, (width - 130) + k * 10 + 10, 40); 
      fill(0);
      textSize(7);
      text(semitones[k], (width - 130) + k * 10 + 1, 38);
    }
  }
  textSize(10);
  
  // Update Progress bar
  float percentComplete = frameNumber / (float)hFrames * 100;
  progressSlider.setValue(percentComplete);
  progressSlider.setValueLabel(nf(round(percentComplete), 2) + "%");
  
  // Log FPS and % complete
  if (frameNumber % 100 == 0) {
    println("  " + round(percentComplete) + "% complete (" + round(frameRate) + " fps)");
  }
  
  if ( percentComplete >= 98 ) {
    println("spectrum analysis complete.");
    exit();
  }
   
  // Render Buildingsky logo on top of it all
  image(logo, 25, 254);
   
  // Save spectrograph to PNG
  //saveFrame(dataPath("frames/frame-"+ nf(frameNumber,6) + ".png"));
  frameNumber++; 
}
