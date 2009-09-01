import processing.opengl.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import rwmidi.*;

String audioFile = "sanitarium.wav";

Minim minim;
AudioSample audio;

FFT fft;

MidiOutput midiOut;

float framesPerSecond = 25.0;
int frameNumber = 0;

int bufferSize = 16384;
//int bufferSize = 8192;
int fftSize = bufferSize/2;

int PEAK_THRESHOLD = 75;

int hFrames; // horizontal frames

// High resolution spectrograph image
PImage spectrograph;
int spectrographHeight;
int spectrographWidth;

PImage bg;
PImage whiteKey;
PImage blackKey;
PImage octaveBtn;

String[] semitones = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" };
boolean[] keyboard = { true, false, true, false, true, true, false, true, false, true, false, true };
color[] toneColor = { color(0, 200, 50), color(0, 100, 200), color(200, 100, 0), color(255, 0, 100), color(50, 150, 200), color(100, 0, 200), color(0, 255, 50), color(255, 80, 200), color(20, 100, 255), color(50, 200, 150), color(50, 160, 20), color(100, 255, 50) };

float[] samples;
float[] buffer = new float[bufferSize];

float[][] spectrum;
int[][] peak;
boolean[][] pitch;
float[][] level;
float[][] pcp;


// Toggles
boolean PCP_TOGGLE = true;
boolean EQUALIZER_TOGGLE = false;
boolean SMOOTH_TOGGLE = true;
//int SMOOTH_TYPE = FFT.TRIANGLE;
int SMOOTH_POINTS = 3;

boolean ENVELOPE_TOGGLE = true;
float ENVELOPE_CURVE = 2.0;

boolean UNIFORM_TOGGLE = true;
boolean DISCRETE_TOGGLE = false;
boolean LINEAR_TOGGLE = false;
boolean QUADRATIC_TOGGLE = false;
boolean EXPONENTIAL_TOGGLE = false;

boolean[] OCTAVE_TOGGLE = {false, true, true, true, true, true, true, true};


public static final int PEAK = 1;
public static final int VALLEY = 2;
public static final int HARMONIC = 3;
public static final int SLOPEUP = 4;
public static final int SLOPEDOWN = 5;

void setup() {
  size(510, 288, OPENGL);
  frameRate(framesPerSecond); // lock framerate
  
  // Create MIDI output interface
  midiOut = RWMidi.getOutputDevices()[0].createOutput();
  
  
  minim = new Minim(this);
  
  audio = minim.loadSample(dataPath(audioFile), bufferSize);
  samples = audio.getChannel(BufferedAudio.LEFT);
  // lowering the sampling rate increases FFT accuracy. but introduces aliasing into the signal since its now below the Nyquist freq. 
  //audio.sampleRate(audio.sampleRate()/4, true);
  
  fft = new FFT(bufferSize, audio.sampleRate());
  //fft.window(FFT.HANN);
  //fft.smooth(SMOOTH_TYPE, SMOOTH_POINTS);
  
  hFrames = int(audio.length() / 1000.0 * framesPerSecond);
  
  println("Audio source: " + audioFile + " " + audio.length() / 1000 + " seconds (" + hFrames + " frames)");
  println("Time size: " + bufferSize + " bytes / Sample rate: " + audio.sampleRate() / 1000.0 + "kHz");
  println("FFT bandwidth: " + (2.0 / bufferSize) * ((float)audio.sampleRate() / 2.0) + "Hz");
  
  // Setup Arrays
  spectrum = new float[hFrames][fftSize];
  peak = new int[hFrames][fftSize];
  pitch = new boolean[hFrames][128];
  level = new float[hFrames][128];
  pcp = new float[hFrames][12];

  // Create spectrograph image
  spectrographWidth = hFrames;
  spectrographHeight = 1024; // or fftSize
  spectrograph = createImage(spectrographWidth, spectrographHeight, RGB);

  bg = loadImage("background.png");
  whiteKey = loadImage("whitekey.png");
  blackKey = loadImage("blackkey.png");
  octaveBtn = loadImage("octavebutton.png");
    
  textFont(createFont("Arial", 10, true));
  
  rectMode(CORNERS);
  smooth();
}

void draw() {
  //view();
  analyze();
  render();
}

void stop() {
  minim.stop();
  super.stop();
}
