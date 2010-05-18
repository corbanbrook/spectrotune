import processing.opengl.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import rwmidi.*;
import controlP5.*;
import java.lang.reflect.InvocationTargetException;

//int bufferSize = 32768;
//int bufferSize = 16384;
//int bufferSize = 8192;
//int bufferSize = 4096;
int bufferSize = 2048;
//int bufferSize = 1024;
//int bufferSize = 512;

// since we are dealing with small buffer sizes (1024) but are trying to detect peaks at low frequency ranges
// octaves 0 .. 2 for example, zero padding is nessessary to improve the interpolation resolution of the FFT
// otherwise FFT bins will be quite large making it impossible to distinguish between low octave notes which
// are seperated by only a few Hz in these ranges.

int ZERO_PAD_MULTIPLIER = 4; // zero padding adds interpolation resolution to the FFT, it also dilutes the magnitude of the bins

int fftBufferSize = bufferSize * ZERO_PAD_MULTIPLIER;
int fftSize = fftBufferSize/2;

int PEAK_THRESHOLD = 50; // default peak threshold

//float framesPerSecond = 25.0;

// MIDI notes span from 0 - 128, octaves -1 -> 9. Specify start and end for piano
int keyboardStart = 12; // 12 is octave C0
int keyboardEnd = 108;

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
Tab tabFFT;

Toggle toggleLinearEQ;
Toggle togglePCP;
Toggle toggleMIDI;
Toggle toggleHarmonics;

Slider sliderProgress;
Slider sliderBalance;
Slider sliderThreshold;

Textlabel labelThreshold;

FFT fft;

MidiOutput midiOut;

int frames; // total horizontal audio frames
int frameNumber = -1; // current audio frame

int cuePosition; // cue position in miliseconds
int lastPosition = 0;

PImage bg;
PImage whiteKey;
PImage blackKey;
PImage octaveBtn;
PImage logo;

float[] buffer = new float[fftBufferSize];
float[] spectrum = new float[fftSize];
int[] peak = new int[fftSize];

float[][] pcp;

Note[][] notes;

int[] fftBinStart = new int[8]; 
int[] fftBinEnd = new int[8];

float[] scaleProfile = new float[12];

float linearEQIntercept = 1f; // default no eq boost
float linearEQSlope = 0f; // default no slope boost

// Toggles and their defaults
boolean LINEAR_EQ_TOGGLE = false;
boolean PCP_TOGGLE = true;
boolean HARMONICS_TOGGLE = true;
boolean MIDI_TOGGLE = true;
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

//public static final int NONE = 0;

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
  
  sampler = new Sampler();
  
  window = new Window();
  smoother = new Smooth();
  
  // zero pad the buffer
  zeroPadBuffer();
  
  // Equalizer settings. Need a tab for this.
  linearEQIntercept = 1f;
  linearEQSlope = 0.01f;
  
  // UI Images
  bg = loadImage("background.png");
  whiteKey = loadImage("whitekey.png");
  blackKey = loadImage("blackkey.png");
  octaveBtn = loadImage("octavebutton.png");
  logo = loadImage("buildingsky.png");
   
  // ControlP5 UI
  controlP5 = new ControlP5(this);
  
  tabDefault = controlP5.addTab("default").activateEvent(true);
  tabFFT = controlP5.addTab("FFT").activateEvent(true);
  tabWindowing = controlP5.addTab("windowing").activateEvent(true);
  tabSmoothing = controlP5.addTab("smoothing").activateEvent(true);
  tabMIDI = controlP5.addTab("midi").activateEvent(true);
  tabFiles = controlP5.addTab("files").activateEvent(true);

  // GENERAL TAB
  tabDefault.setLabel("GENERAL");
  controlP5.addTextlabel("labelGeneral", "GENERAL", 380, 10).moveTo("default");
  
  // Pitch class profile toggle
  togglePCP = controlP5.addToggle("togglePCP", PCP_TOGGLE, 380, 30, 10,10);
  togglePCP.setLabel("Pitch Class Profile");
  togglePCP.setColorForeground(0x8000ffc8);
  togglePCP.setColorActive(0xff00ffc8);
  
   // Pitch class profile toggle
  toggleLinearEQ = controlP5.addToggle("toggleLinearEQ", LINEAR_EQ_TOGGLE, 380,60, 10,10);
  toggleLinearEQ.setLabel("Linear EQ");
  toggleLinearEQ.setColorForeground(0x8000ffc8);
  toggleLinearEQ.setColorActive(0xff00ffc8);
  
  toggleHarmonics = controlP5.addToggle("toggleHarmonics", HARMONICS_TOGGLE, 380, 90, 10, 10);
  toggleHarmonics.setLabel("Harmonics Filter");
  toggleHarmonics.setColorForeground(0x9000ffc8);
  toggleHarmonics.setColorActive(0xff00ffc8);
  
  sliderBalance = controlP5.addSlider("balance", -100, 100, 0, 380, 120, 50, 10);
  sliderBalance.setValueLabel(" CENTER");
    
  // Peak detect threshold slider
  sliderThreshold = controlP5.addSlider("Threshold", 0, 255, PEAK_THRESHOLD, 380, 140, 75, 10);
  sliderThreshold.setId(1);
  
  // MIDI TAB
  controlP5.addTextlabel("labelMIDI", "MIDI", 380, 10).moveTo(tabMIDI);
  
  // MIDI output toggle
  toggleMIDI = controlP5.addToggle("toggleMIDI", MIDI_TOGGLE, 380, 30, 10,10);
  toggleMIDI.setLabel("MIDI OUTPUT");
  toggleMIDI.moveTo(tabMIDI);
  
  Numberbox oct0 = controlP5.addNumberbox("oct0", 1, 380, 60, 20, 14);
  Numberbox oct1 = controlP5.addNumberbox("oct1", 1, 410, 60, 20, 14); 
  Numberbox oct2 = controlP5.addNumberbox("oct2", 1, 440, 60, 20, 14);
  Numberbox oct3 = controlP5.addNumberbox("oct3", 1, 470, 60, 20, 14);
  
  Numberbox oct4 = controlP5.addNumberbox("oct4", 1, 380, 90, 20, 14);
  Numberbox oct5 = controlP5.addNumberbox("oct5", 1, 410, 90, 20, 14); 
  Numberbox oct6 = controlP5.addNumberbox("oct6", 1, 440, 90, 20, 14);
  Numberbox oct7 = controlP5.addNumberbox("oct7", 1, 470, 90, 20, 14);
  
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
  radioWindow.add("GAUSS", Window.GAUSS);
  radioWindow.moveTo(tabWindowing);
  //radioWindow.activate("HAMMING"); // set default
  
  controlP5.addTextlabel("labelSmoothing", "SMOOTHING", 380, 10).moveTo(tabSmoothing);
  
  Radio radioSmooth = controlP5.addRadio("radioSmooth", 380, 30);
  radioSmooth.add("NONE", Smooth.NONE);
  radioSmooth.add("RECTANGLE", Smooth.RECTANGLE);
  radioSmooth.add("TRIANGLE", Smooth.TRIANGLE);
  radioSmooth.add("AJACENT AVERAGE", Smooth.ADJAVG);
  radioSmooth.moveTo(tabSmoothing);
  
  // Smoothing points slider
  Slider sliderSmoothing = controlP5.addSlider("Points", 1, 10, SMOOTH_POINTS, 380, 100, 75, 10);
  sliderSmoothing.setId(2);
  sliderSmoothing.moveTo(tabSmoothing);

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
  
  controlP5.addTextlabel("labelFFT", "FFT", 380, 10).moveTo(tabFFT);
  
  // FFT bin distance weighting radios
  //controlP5.addTextlabel("labelWeight", "FFT WEIGHT", 380, 30);
  Radio radioWeight = controlP5.addRadio("radioWeight", 380, 30);
  radioWeight.add("UNIFORM (OFF)", UNIFORM); // default
  radioWeight.add("DISCRETE", DISCRETE);
  radioWeight.add("LINERAR", LINEAR);
  radioWeight.add("QUADRATIC", QUADRATIC);
  radioWeight.add("EXPONENTIAL", EXPONENTIAL);
  radioWeight.moveTo(tabFFT);
  
  labelThreshold = controlP5.addTextlabel("labelThreshold", "THRESHOLD", PEAK_THRESHOLD + 26, 60);
  labelThreshold.moveTo(tabFFT);
  
  // GLOBAL UI
  
  // Progress bar 
  sliderProgress = controlP5.addSlider("Progress", 0, 0, 0, 380, height - 20, 75, 10);
  sliderProgress.setId(3);
  sliderProgress.moveTo("global"); // always show no matter what tab is selected
      
  textFont(createFont("Arial", 10, true));
  
  rectMode(CORNERS);
  
  smooth();
}

void draw() {
  sampler.draw(); // synchronized
}

void stop() {
  if ( audio != null ) {
    audio.pause();
    TRACK_LOADED = false;
    audio.close();
  }
  
  closeMIDINotes(); // close any open MIDI notes
  
  minim.stop();
  super.stop();
}
