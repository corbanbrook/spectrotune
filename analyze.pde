void analyze() {
  arraycopy(samples, (int)(frameNumber * audio.sampleRate() / framesPerSecond), buffer, 0, bufferSize);
  
  fft.forward(buffer);
  
  float[] binDistance = new float[fftSize];
  float[] freq = new float[fftSize];
    
  boolean peakset = false;
  float freqLowRange = octaveLowRange(0);
  float freqHighRange = octaveHighRange(9);
    
  for (int k = 0; k < fftSize; k++) {
    freq[k] = k / (float)bufferSize * audio.sampleRate();
    // skip FFT bins that lay outside of octaves 0-9 
    if ( freq[k] < freqLowRange || freq[k] > freqHighRange ) { continue; }
 
    // Calculate fft bin distance and apply weighting to spectrum
    float closestFreq = pitchToFreq(freqToPitch(freq[k])); // Rounds FFT frequency to closest semitone frequency
    boolean filterFreq = false;

    // filter out frequncies from disabled octaves    
    for ( int i = 0; i < 8; i ++ ) {
      if ( !OCTAVE_TOGGLE[i] ) {
        if ( closestFreq >= octaveLowRange(i) && closestFreq <= octaveHighRange(i) ) {
          filterFreq = true;
        }
      }
    }
    
    if ( !filterFreq ) {
      binDistance[k] = 2 * abs((12 * log(freq[k]/440.0) / log(2)) - (12 * log(closestFreq/440.0) / log(2)));
      spectrum[frameNumber][k] = fft.getBand(k) * binWeight(WEIGHT_TYPE, binDistance[k]);
    
      // Sum PCP bins
      pcp[frameNumber][freqToPitch(freq[k]) % 12] += pow(fft.getBand(k), 2) * binWeight(WEIGHT_TYPE, binDistance[k]);
    }
  }
  
  // Pitch Class Profile
  normalizePCP();
  
  if ( PCP_TOGGLE ) { 
    // Apply PCP to spectrum
    for ( int k = 0; k < fftSize; k++ ) {
      if ( freq[k] < freqLowRange || freq[k] > freqHighRange ) { continue; }
      spectrum[frameNumber][k] *= pcp[frameNumber][freqToPitch(freq[k]) % 12];   
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
      // filter harmonics from peaks
      boolean harmonic = false;
      for ( int f = 0; f < foundPeak.length; f++ ) {
        if (foundPeak.length > 2 ) {
          harmonic = true;
          break;
        }
        if ( freqToPitch(freq[k]) % 12 == freqToPitch(foundPeak[f]) % 12 && spectrum[frameNumber][k] < foundLevel[f] ) {
          harmonic = true;
          break;
        }
      }

      if ( harmonic ) {        
        peak[frameNumber][k] = HARMONIC;
      } else {
        peak[frameNumber][k] = PEAK;
        pitch[frameNumber][freqToPitch(freq[k])] = true;
        level[frameNumber][freqToPitch(freq[k])] = spectrum[frameNumber][k];
        foundPeak = append(foundPeak, freq[k]);
        foundLevel = append(foundLevel, spectrum[frameNumber][k]);
        peakset = true;     
      }
    }
  }
}


