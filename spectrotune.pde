import processing.opengl.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import rwmidi.*;
import controlP5.*;

String audioFile = "sanitarium.wav";

Minim minim;
AudioSample audio;
ControlP5 controlP5;
Slider progressSlider;

FFT fft;

MidiOutput midiOut;

float framesPerSecond = 25.0;
int frameNumber = 0;

int bufferSize = 16384; // needs to be high for fft accuracy at lower octaves
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
PImage logo;

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
int[] OCTAVE_CHANNEL = {0,0,0,0,0,0,0,0}; // set all octaves to channel 0 (0-indexed channel 1)


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
  
  // Initialize Minim
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
  logo = loadImage("buildingsky.png");
  
  // ControlP5 UI
  controlP5 = new ControlP5(this);
  
  // Pitch class profile toggle
  Toggle togglePCP = controlP5.addToggle("togglePCP", true, 380,5, 10,10);
  togglePCP.setLabel("Pitch Class Profile");
  togglePCP.setColorForeground(0x8000ffc8);
  togglePCP.setColorActive(0xff00ffc8);
  
  // FFT bin distance weighting radios
  controlP5.addTextlabel("labelWeight", "FFT WEIGHT", 380, 70);
  Radio radioWeight = controlP5.addRadio("radioWeight", 380, 80);
  radioWeight.add("UNIFORM", UNIFORM); // default
  radioWeight.add("DISCRETE", DISCRETE);
  radioWeight.add("LINERAR", LINEAR);
  radioWeight.add("QUADRATIC", QUADRATIC);
  radioWeight.add("EXPONENTIAL", EXPONENTIAL);
  
  // Peak detect threshold slider
  Slider thresholdSlider = controlP5.addSlider("Threshold", 0, 255, PEAK_THRESHOLD, 380, 160, 75, 10);
  thresholdSlider.setId(9);
  
  // Smoothing points slider
  Slider smoothingSlider = controlP5.addSlider("Smoothing", 1, 10, SMOOTH_POINTS, 380, 180, 75, 10);
  smoothingSlider.setId(10);
  
  controlP5.addTextlabel("labelMIDI", "MIDI CHANNELS", 380, 200);
  
  Numberbox oct0 = controlP5.addNumberbox("oct0", 1, 380, 210, 20, 14);
  Numberbox oct1 = controlP5.addNumberbox("oct1", 1, 410, 210, 20, 14); 
  Numberbox oct2 = controlP5.addNumberbox("oct2", 1, 440, 210, 20, 14);
  Numberbox oct3 = controlP5.addNumberbox("oct3", 1, 470, 210, 20, 14);
  
  Numberbox oct4 = controlP5.addNumberbox("oct4", 1, 380, 240, 20, 14);
  Numberbox oct5 = controlP5.addNumberbox("oct5", 1, 410, 240, 20, 14); 
  Numberbox oct6 = controlP5.addNumberbox("oct6", 1, 440, 240, 20, 14);
  Numberbox oct7 = controlP5.addNumberbox("oct7", 1, 470, 240, 20, 14);
  
  progressSlider = controlP5.addSlider("Progress", 0, 100, 0, 380, 272, 75, 10);
  
  textFont(createFont("Arial", 10, true));
  
  rectMode(CORNERS);
  smooth();
}

void draw() {
  //view(); // displays a ociliscope
  analyze();
  render();
}

void stop() {
  minim.stop();
  super.stop();
}
