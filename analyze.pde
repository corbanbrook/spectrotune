void analyze() {
  int offset = (int)(frameNumber * audio.sampleRate() / framesPerSecond);
    
  if ( offset + bufferSize > audio.getChannel(BufferedAudio.LEFT).length ) { // Reached the end of the audio track
    PLAYING = false;
  } else {
    if ( audio.type() == Minim.STEREO ) {
      arraycopy(audio.getChannel(BufferedAudio.LEFT), offset, bufferLeft, 0, bufferSize);
      arraycopy(audio.getChannel(BufferedAudio.RIGHT), offset, bufferRight, 0, bufferSize);
    
      // Apply Balance to buffer
      for ( int i = 0; i < bufferSize; i++ ) {
        int balanceValue = (int)balanceSlider.value();
        if ( balanceValue > 0 ) {
          float balancePercent = (100 - balanceValue) / 100.0; 
          buffer[i] = (bufferLeft[i] * balancePercent) + bufferRight[i];
        } else if ( balanceValue < 0 ) {
          float balancePercent = (100 - balanceValue * -1) / 100.0; 
          buffer[i] = bufferLeft[i] + (bufferRight[i] * balancePercent);
        } else {
          buffer[i] = bufferLeft[i] + bufferRight[i];
        }
      }
      /*for ( int i = bufferSize/2; i < bufferSize; i++ ) {
        buffer[i] = 0;
      }*/
    } else {
      arraycopy(audio.getChannel(BufferedAudio.LEFT), offset, buffer, 0, bufferSize); 
    }
    
    window.transform(buffer); // add window to buffer
    
    fft.forward(buffer); // run fft on the buffer
    
    smoother.apply(fft); // run the smoother on the fft spectra
    
    float[] binDistance = new float[fftSize];
    float[] freq = new float[fftSize];
      
    
    float freqLowRange = octaveLowRange(0);
    float freqHighRange = octaveHighRange(8);
    
    boolean peakset = false;
    
    for (int k = 0; k < fftSize; k++) {
      freq[k] = k / (float)bufferSize * audio.sampleRate();
      
      // skip FFT bins that lay outside of octaves 0-9 
      if ( freq[k] < freqLowRange || freq[k] > freqHighRange ) { continue; }
   
      // Calculate fft bin distance and apply weighting to spectrum
      float closestFreq = pitchToFreq(freqToPitch(freq[k])); // Rounds FFT frequency to closest semitone frequency
      boolean filterFreq = false;
  
      // Clear arrays that may have been pre populated before rewinding
      spectrum[frameNumber][k] = 0;
      level[frameNumber][freqToPitch(freq[k])] = 0;
      pitch[frameNumber][freqToPitch(freq[k])] = false;
  
      // Filter out frequncies from disabled octaves    
      for ( int i = 0; i < 8; i ++ ) {
        if ( !OCTAVE_TOGGLE[i] ) {
          if ( closestFreq >= octaveLowRange(i) && closestFreq <= octaveHighRange(i) ) {
            filterFreq = true;
          }
        }
      }
      
      // Set spectrum 
      if ( !filterFreq ) {
        binDistance[k] = 2 * abs((12 * log(freq[k]/440.0) / log(2)) - (12 * log(closestFreq/440.0) / log(2)));
        float linearEQ = linearEQIntercept + k * linearEQSlope;
        
        spectrum[frameNumber][k] = fft.getBand(k) * binWeight(WEIGHT_TYPE, binDistance[k]) * linearEQ;
      
        // Sum PCP bins
        pcp[frameNumber][freqToPitch(freq[k]) % 12] += pow(fft.getBand(k), 2) * binWeight(WEIGHT_TYPE, binDistance[k]);
      }
    }
    
    normalizePCP();
    
    if ( SCALE_LOCK_TOGGLE || PCP_TOGGLE ) {
      for ( int k = 0; k < fftSize; k++ ) {
        if ( freq[k] < freqLowRange || freq[k] > freqHighRange ) { continue; }
        
        if ( SCALE_LOCK_TOGGLE ) { // Apply SCALE LOCKING to spectrum
          spectrum[frameNumber][k] *= scaleProfile[freqToPitch(freq[k]) % 12];
        }
        if ( PCP_TOGGLE ) { // Apply PCP to spectrum
          spectrum[frameNumber][k] *= pcp[frameNumber][freqToPitch(freq[k]) % 12];  
        }
      }
    }
    
    float sprev = 0;
    float scurr = 0;
    float snext = 0;
    float maximum = max(spectrum[frameNumber]);
    
    float[] foundPeak = new float[0];
    float[] foundLevel = new float[0];
    
    // find the peaks and valleys
    for (int k = 1; k < fftSize -1; k++) {
      if ( freq[k] < freqLowRange || freq[k] > freqHighRange ) { continue; }
      
      sprev = spectrum[frameNumber][k-1];
      scurr = spectrum[frameNumber][k];
      snext = spectrum[frameNumber][k+1];
        
      //TODO: This is not the best way of doing this.
      // Instead compute the slope of each bin 
      if ( scurr > sprev && scurr < snext ) { 
        peak[frameNumber][k] = SLOPEUP;
      } else if ( scurr < sprev && scurr > snext ) {
        peak[frameNumber][k] = SLOPEDOWN;
      } else if ( scurr < sprev && scurr < snext && peakset ) {
        peak[frameNumber][k] = VALLEY;
        peakset = false;
      } else if ( scurr > sprev && scurr > snext && (scurr > PEAK_THRESHOLD) ) { // peak
        boolean isHarmonic = false;
        
        // filter harmonics from peaks
        if ( HARMONICS_TOGGLE ) {
          for ( int f = 0; f < foundPeak.length; f++ ) {
            //TODO: Cant remember why this is here
            if (foundPeak.length > 2 ) {
              isHarmonic = true;
              break;
            }
            // If the current frequencies note has already peaked in a lower octave check to see if its level is lower probably a harmonic
            if ( freqToPitch(freq[k]) % 12 == freqToPitch(foundPeak[f]) % 12 && spectrum[frameNumber][k] < foundLevel[f] ) {
              isHarmonic = true;
              break;
            }
          }
        }
  
        if ( isHarmonic ) {        
          peak[frameNumber][k] = HARMONIC;
        } else {
          peak[frameNumber][k] = PEAK;
          pitch[frameNumber][freqToPitch(freq[k])] = true;
          level[frameNumber][freqToPitch(freq[k])] = spectrum[frameNumber][k];
          
          // Track Peaks and Levels in this pass so we can detect harmonics 
          foundPeak = append(foundPeak, freq[k]);
          foundLevel = append(foundLevel, spectrum[frameNumber][k]);
          peakset = true;     
        }
      }
    }
  }
}


