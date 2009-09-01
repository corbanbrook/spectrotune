void view() {
   background(255);
   arraycopy(samples, (int)(frameNumber * audio.sampleRate() / framesPerSecond), buffer, 0, bufferSize);
 
  //fft.noSmooth();
  fft.forward(buffer); 
  
  stroke(0);
  int start = 100;
  for( int i = start; i < 700; i++ ) {
    line(i * 5 - start * 5, height - fft.getBand(i) * 5, (i+1) * 5 - start * 5, height - fft.getBand(i+1) * 5); 
  }
  
  //fft.smooth(FFT.RECTANGLE, 50);
  fft.forward(buffer);
  stroke(255,0,100);
  for( int i = start; i < 700; i++ ) {
        line(i * 5 - start * 5, height - fft.getBand(i) * 5, (i+1) * 5 - start * 5, height - fft.getBand(i+1) * 5); 
  }
  
  frameNumber++;
}
