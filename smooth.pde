public class Smooth {
  public static final int NONE = 0;
  public static final int RECTANGLE = 1;
  public static final int TRIANGLE = 2;
  public static final int ADJAVG = 3;


  private int mode = NONE;
  private int points = 3;

  void setMode(int smoothType, int smoothPoints) {
    this.mode = smoothType;
    this.points = smoothPoints;
  }

  void apply(FFT fft) {
    switch(mode) {
      case RECTANGLE:
      	rectangleSmooth(fft, points);
      	break;
      case TRIANGLE:
        triangleSmooth(fft, points);
        break;    
      case ADJAVG:
        adjacentAverageSmooth(fft, points);
        break;
    }
  }
  
  // basic sliding average non-weighted smooth 
  protected void rectangleSmooth(FFT fft, int points) {
    float smoothed;
    
    // points must be odd, ie. a 3 point smooth is centred on the point to be smoothed, 1 point on either side.
    if (points % 2 == 0) {
      points++;
    }
    
    int sidePoints = (points - 1) / 2;
    
    for(int i = sidePoints; i < fft.specSize() - sidePoints; i++) {
      smoothed = fft.getBand(i);
      for (int j = 0; j < sidePoints; j++) {
        smoothed += fft.getBand(i-j) + fft.getBand(i+j); 
      }
   
      fft.setBand(i, smoothed/(float)points);
    }
  }
  
  // triangle smooth - weighted average smoothing
  protected void triangleSmooth(FFT fft, int points) {
    float smoothed;
    
    if (points % 2 == 0) {
      points++;
    }
    
    int sidePoints = (points - 1) / 2;
    
    for(int i = sidePoints; i < fft.specSize() - sidePoints; i++) {
      int weight = points / 2 + 1;
      int divider = weight;
    
      smoothed = fft.getBand(i) * weight;
      
      for(int j = 0; j < sidePoints; j ++) {
	weight--;
        smoothed += (fft.getBand(i-j) * weight) + (fft.getBand(i+j) * weight);
        divider += (weight * 2);
      }
      
      fft.setBand(i, smoothed/(float)divider);
    }
  }
  
  
  // This smoother doesnt work well at all
  // adjacent average smoothing - takes the average of 2 adjacent points 
  protected void adjacentAverageSmooth(FFT fft, int points) {  ;
    if (points % 2 == 0) {
      points++;
    }
    
    int sidePoints = (points - 1) / 2;
      
    for(int i = sidePoints; i < fft.specSize() - sidePoints; i++) {
      fft.setBand(i, fft.getBand(i-sidePoints) + fft.getBand(i+sidePoints) / 2f);
    }
  }
}
