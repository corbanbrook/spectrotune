class Sampler implements AudioListener
{
  private float[] left;
  private float[] right;
  
  Sampler() {
    left = null; 
    right = null;
  }
  
  synchronized void samples(float[] samp) {
    left = samp;
    
    process();
  }
  
  synchronized void samples(float[] sampL, float[] sampR) {
    left = sampL;
    right = sampR;
    
    // Apply balance to sample buffer storing in left mono buffer
    for ( int i = 0; i < bufferSize; i++ ) {
      int balanceValue = (int)balanceSlider.value();
      if ( balanceValue > 0 ) {
        float balancePercent = (100 - balanceValue) / 100.0; 
        left[i] = (left[i] * balancePercent) + right[i];
      } else if ( balanceValue < 0 ) {
        float balancePercent = (100 - balanceValue * -1) / 100.0; 
        left[i] = left[i] + (right[i] * balancePercent);
      } else {
        left[i] = left[i] + right[i];
      }
    }
    
    process();
  }
  
  synchronized void process() {
    // need to apply the window transform before we zeropad
    window.transform(left); // add window to samples
    
    arrayCopy(left, 0, buffer, 0, left.length);
    
    analyze();
    
    frameNumber++;
  }
}
