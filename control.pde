void keyPressed() {
  switch(key) {
    case 's': // save spectrograph and quit
      saveSpectrograph();
      exit();
      break;
    
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
    
    case 'u': // turn uniform on
      WEIGHT_TYPE = UNIFORM;
      UNIFORM_TOGGLE = true;
      DISCRETE_TOGGLE = false;
      LINEAR_TOGGLE = false;
      QUADRATIC_TOGGLE = false;
      EXPONENTIAL_TOGGLE = false;      
      break;
    
    case 'd': // turn discrete on
      WEIGHT_TYPE = DISCRETE;
      UNIFORM_TOGGLE = false;
      DISCRETE_TOGGLE = true;
      LINEAR_TOGGLE = false;
      QUADRATIC_TOGGLE = false;
      EXPONENTIAL_TOGGLE = false;      
      break;
      
    case 'l': // turn linear on
      WEIGHT_TYPE = LINEAR;
      UNIFORM_TOGGLE = false;
      DISCRETE_TOGGLE = false;
      LINEAR_TOGGLE = true;
      QUADRATIC_TOGGLE = false;
      EXPONENTIAL_TOGGLE = false;      
      break;
      
    case 'q': // turn quadratic on
      WEIGHT_TYPE = QUADRATIC;
      UNIFORM_TOGGLE = false;
      DISCRETE_TOGGLE = false;
      LINEAR_TOGGLE = false;
      QUADRATIC_TOGGLE = true;
      EXPONENTIAL_TOGGLE = false;      
      break;
      
    case 'x': // turn exponential on
      WEIGHT_TYPE = EXPONENTIAL;
      UNIFORM_TOGGLE = false;
      DISCRETE_TOGGLE = false;
      LINEAR_TOGGLE = false;
      QUADRATIC_TOGGLE = false;
      EXPONENTIAL_TOGGLE = true;      
      break;
    

      
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


