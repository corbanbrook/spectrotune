import processing.opengl.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import rwmidi.*;
import controlP5.*;

String[] audioFiles;
String loadedAudioFile;

Minim minim;
AudioPlayer audio;
Sampler sampler;
ControlP5 controlP5;
Window window;
Smooth smoother;

Tab tabDefault;
Tab tabWindowing;
Tab tabSmoothing;
Tab tabMIDI;
Tab tabFiles;

Slider progressSlider;
Slider balanceSlider;

FFT fft;

MidiOutput midiOut;

float framesPerSecond = 25.0;
int frameNumber = 0;

int cuePosition; // cue position in miliseconds

//int bufferSize = 32768;
//int bufferSize = 16384; // needs to be high for fft accuracy at lower octaves
//int bufferSize = 8192;
//int bufferSize = 4096;
int bufferSize = 1024;
//int bufferSize = 512;

int ZERO_PAD_MULTIPLIER = 4;

int fftBufferSize = bufferSize * ZERO_PAD_MULTIPLIER;
int fftSize = fftBufferSize/2;

int PEAK_THRESHOLD = 75;

// MIDI notes span from 0 - 128, octaves -1 -> 9. Specify start and end for piano
int keyboardStart = 12; // 12 is octave C0
int keyboardEnd = 108;

int hFrames; // horizontal frames

PImage bg;
PImage whiteKey;
PImage blackKey;
PImage octaveBtn;
PImage logo;

String[] semitones = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" };
boolean[] keyboard = { true, false, true, false, true, true, false, true, false, true, false, true };
color[] toneColor = { color(0, 200, 50), color(0, 100, 200), color(200, 100, 0), color(255, 0, 100), color(50, 150, 200), color(100, 0, 200), color(0, 255, 50), color(255, 80, 200), color(20, 100, 255), color(50, 200, 150), color(50, 160, 20), color(100, 255, 50) };

float[] buffer = new float[fftBufferSize];

float[][] spectrum;
int[][] peak;
boolean[][] pitch;
float[][] level;
float[][] pcp;

int[] fftBinStart = new int[8];
int[] fftBinEnd = new int[8];

float[] scaleProfile = new float[12];

float linearEQIntercept = 1f; // default no eq boost
float linearEQSlope = 0f; // default no slope boost

// Toggles
boolean SCALE_LOCK_TOGGLE = false;
boolean PCP_TOGGLE = true;
boolean EQUALIZER_TOGGLE = false;
boolean HARMONICS_TOGGLE = true;
boolean SMOOTH_TOGGLE = true;
int SMOOTH_POINTS = 3;

boolean UNIFORM_TOGGLE = true;
boolean DISCRETE_TOGGLE = false;
boolean LINEAR_TOGGLE = false;
boolean QUADRATIC_TOGGLE = false;
boolean EXPONENTIAL_TOGGLE = false;

boolean TRACK_LOADED = false;

boolean[] OCTAVE_TOGGLE = {false, true, true, true, true, true, true, true};
int[] OCTAVE_CHANNEL = {0,0,0,0,0,0,0,0}; // set all octaves to channel 0 (0-indexed channel 1)

public static final int NONE = 0;

public static final int PEAK = 1;
public static final int VALLEY = 2;
public static final int HARMONIC = 3;
public static final int SLOPEUP = 4;
public static final int SLOPEDOWN = 5;

void setup() {
  size(510, 288, OPENGL);
  
  //frameRate(framesPerSecond); // lock framerate
  
  // Create MIDI output interface - select the first found device by default
  midiOut = RWMidi.getOutputDevices()[0].createOutput();
  
  // Initialize Minim
  minim = new Minim(this);
  
  window = new Window();
  smoother = new Smooth();
  
  // Equalizer settings. Need a tab for this.
  //linearEQIntercept = 1f;
  //linearEQSlope = 0.001f;
  
  // Logo UI Images
  bg = loadImage("background.png");
  whiteKey = loadImage("whitekey.png");
  blackKey = loadImage("blackkey.png");
  octaveBtn = loadImage("octavebutton.png");
  logo = loadImage("buildingsky.png");
  
   
  // ControlP5 UI
  controlP5 = new ControlP5(this);
  
  tabDefault = controlP5.addTab("default").activateEvent(true);
  tabWindowing = controlP5.addTab("windowing").activateEvent(true);
  tabSmoothing = controlP5.addTab("smoothing").activateEvent(true);
  tabMIDI = controlP5.addTab("midi").activateEvent(true);
  tabFiles = controlP5.addTab("files").activateEvent(true);
  
  // GENERAL TAB
  tabDefault.setLabel("GENERAL");
  controlP5.addTextlabel("labelGeneral", "GENERAL", 380, 10).moveTo("default");
  
  // Pitch class profile toggle
  Toggle togglePCP = controlP5.addToggle("togglePCP", PCP_TOGGLE, 380, 30, 10,10);
  togglePCP.setLabel("Pitch Class Profile");
  togglePCP.setColorForeground(0x8000ffc8);
  togglePCP.setColorActive(0xff00ffc8);
  
   // Pitch class profile toggle
  Toggle toggleScaleLock = controlP5.addToggle("toggleScaleLock", SCALE_LOCK_TOGGLE, 380,60, 10,10);
  toggleScaleLock.setLabel("Scale Lock");
  toggleScaleLock.setColorForeground(0x8000ffc8);
  toggleScaleLock.setColorActive(0xff00ffc8);
  
  Toggle toggleHarmonics = controlP5.addToggle("toggleHarmonics", HARMONICS_TOGGLE, 380, 90, 10, 10);
  toggleHarmonics.setLabel("Harmonics Filter");
  toggleHarmonics.setColorForeground(0x9000ffc8);
  toggleHarmonics.setColorActive(0xff00ffc8);
  
  // FFT bin distance weighting radios
  //controlP5.addTextlabel("labelWeight", "FFT WEIGHT", 380, 130);
  Radio radioWeight = controlP5.addRadio("radioWeight", 380, 160);
  radioWeight.add("UNIFORM", UNIFORM); // default
  radioWeight.add("DISCRETE", DISCRETE);
  radioWeight.add("LINERAR", LINEAR);
  radioWeight.add("QUADRATIC", QUADRATIC);
  radioWeight.add("EXPONENTIAL", EXPONENTIAL);
  
  balanceSlider = controlP5.addSlider("balance", -100, 100, 0, 380, 120, 50, 10);
  balanceSlider.setValueLabel(" CENTER");
    
  // Peak detect threshold slider
  Slider thresholdSlider = controlP5.addSlider("Threshold", 0, 255, PEAK_THRESHOLD, 380, 140, 75, 10);
  thresholdSlider.setId(1);
  
  // Smoothing points slider
  Slider smoothingSlider = controlP5.addSlider("Smoothing", 1, 10, SMOOTH_POINTS, 380, height - 40, 75, 10);
  smoothingSlider.setId(2);
  
  // MIDI TAB
  controlP5.addTextlabel("labelMIDI", "MIDI", 380, 10).moveTo(tabMIDI);
  
  Numberbox oct0 = controlP5.addNumberbox("oct0", 1, 380, 30, 20, 14);
  Numberbox oct1 = controlP5.addNumberbox("oct1", 1, 410, 30, 20, 14); 
  Numberbox oct2 = controlP5.addNumberbox("oct2", 1, 440, 30, 20, 14);
  Numberbox oct3 = controlP5.addNumberbox("oct3", 1, 470, 30, 20, 14);
  
  Numberbox oct4 = controlP5.addNumberbox("oct4", 1, 380, 60, 20, 14);
  Numberbox oct5 = controlP5.addNumberbox("oct5", 1, 410, 60, 20, 14); 
  Numberbox oct6 = controlP5.addNumberbox("oct6", 1, 440, 60, 20, 14);
  Numberbox oct7 = controlP5.addNumberbox("oct7", 1, 470, 60, 20, 14);
  
  // move MIDI Channels to midi tab
  oct0.moveTo(tabMIDI);
  oct1.moveTo(tabMIDI);
  oct2.moveTo(tabMIDI);
  oct3.moveTo(tabMIDI);
  oct4.moveTo(tabMIDI);
  oct5.moveTo(tabMIDI);
  oct6.moveTo(tabMIDI);
  oct7.moveTo(tabMIDI);
  
  Radio radioMidiDevice = controlP5.addRadio("radioMidiDevice", 36, 30);
  for(int i = 0; i < RWMidi.getOutputDevices().length; i++) {
    radioMidiDevice.add(RWMidi.getOutputDevices()[i] + "", i);
  }
  radioMidiDevice.moveTo(tabMIDI);
  
  // WINDOWING TAB
  controlP5.addTextlabel("labelWindowing", "WINDOWING", 380, 10).moveTo(tabWindowing);

  Radio radioWindow = controlP5.addRadio("radioWindow", 380, 30);
  radioWindow.add("RECTANGULAR", Window.RECTANGULAR);
  radioWindow.add("HAMMING", Window.HAMMING);
  radioWindow.add("HANN", Window.HANN);
  radioWindow.add("COSINE", Window.COSINE);
  radioWindow.add("TRIANGULAR", Window.TRIANGULAR);
  radioWindow.add("BLACKMAN", Window.BLACKMAN);
  radioWindow.moveTo(tabWindowing);
  radioWindow.activate("HAMMING");
  
  controlP5.addTextlabel("labelSmoothing", "SMOOTHING", 380, 10).moveTo(tabSmoothing);
  
  Radio radioSmooth = controlP5.addRadio("radioSmooth", 380, 30);
  radioSmooth.add("NONE", Smooth.NONE);
  radioSmooth.add("RECTANGLE", Smooth.RECTANGLE);
  radioSmooth.add("TRIANGLE", Smooth.TRIANGLE);
  radioSmooth.add("AJACENT AVERAGE", Smooth.ADJAVG);
  radioSmooth.moveTo(tabSmoothing);

  // FILE TAB -- think about adding sDrop support.. may be better

  // File list
  ScrollList listFiles = controlP5.addScrollList("listFiles", 36, 40, 280, 280);  
  listFiles.moveTo(tabFiles);
  listFiles.setLabel("Open File");
  File file = new File(sketchPath + "/music");
 
  if ( file.isDirectory() ) {
    audioFiles = file.list();
    
    for (int i = 0; i < audioFiles.length; i++) {
      controlP5.Button b = listFiles.addItem(audioFiles[i], i);
      b.setId(100 + i);
    }
  }
  
  // GLOBAL
  
  // Progress bar 
  progressSlider = controlP5.addSlider("Progress", 0, 0, 0, 380, height - 20, 75, 10);
  progressSlider.setId(3);
  progressSlider.moveTo("global"); // always show no matter what tab is selected
    
  // zero pad buffer
  zeroPadBuffer();
    
  textFont(createFont("Arial", 10, true));
  
  rectMode(CORNERS);
  smooth();
}

void draw() {
  render();
}

void stop() {
  if ( audio != null ) {
    audio.close();
  }
  minim.stop();
  super.stop();
}
