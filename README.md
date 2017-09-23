# Spectrotune

Spectrotune is a [Processing](http://www.processing.org) application which scans a
polyphonic audio source (in wav, mp3, etc formats), performs pitch detection and
outputs to MIDI.

Spectrotune offers adjustable options to help improve pitch detection, including:

  * Pitch Class Profiling (PCP)

  * FFT Bin Distance Weighting
  
  * FFT Windowing - rectangular, hamming, hann, triangular, cosine, and blackman windows.
  
  * FFT Linear Equalization - attenuate low freqencies and amplify high freqencies.
  
  * Harmonic Filter - filters peak harmonics.

  * Noise Smoothing - rectangle, triangle, and adjacent average smoothers.
  
  * Parabolic Peak Interpolation.

  * Adjustable Peak Threshold.
  
  * Octave toggles - narrow the spectrum to the octaves you are interested in recording.
  
  * MIDI octave channel segmenting - route each octave to its own MIDI channel.


## Install and Basic Usage (Max OS X Standalone Application):

  Spectrotune is now available in a standalone application for Mac OSX which you can download 
  at http://github.com/corbanbrook/spectrotune/downloads

  * Open DMG file.

  * Put audio files(wav, mp3, etc) in the music folder. 
    (Note: music folder *must* be relative to the spectrotune.app path)

  * Launch application.

  * Click 'Files' tab and select the audio file you wish to open.

  * Record with MIDI sequencer.

  Currently only exported as an application for Max OS X as I dont have any other platforms to
  test on. If you want a standalone application for Windows or Linux please send me a request or 
  install processing and export the application yourself.

  If you wish to play with the source code you can follow the instructions below to install 
  processing and the required libraries.


## Processing Install (all platforms):

  * Install [processing](http://www.processing.org)
  
  * Install [rwmidi](http://ruinwesen.com/support-files/rwmidi-0.1c.zip) 

  * Install [ControlP5](http://www.sojamo.de/libraries/controlP5/)

  * Clone Spectrotune and place inside your Processing Sketchbook directory
  
  ```
    cd ~/Documents/Processing (this is where I keep mine)
    git clone git://github.com/corbanbrook/spectrotune.git
  ```
  
  * Make sure your operating systems MIDI interface is configured properly.

  * Put audio files (wav, mp3, etc) you wish to open in the 'music' folder within the route of the sketch.

  * Open MIDI enabled sequencer software, ie Reason, Cubase, Fruityloops, etc.

  * Open processing.

  * Run.

  If you are using a MIDI enabled sequencer software you should be able to record
  the input and pass on to any soft synth, or hardware synth.


## Keyboard Commands:
| Command | Result |
|-------|---------------------------------------------|
| 0-7   | Octave filter: toggle octaves 0 to 7 On/Off |
| p     | Pitch Class Profile (PCP) toggle On/Off     |
| e     | Linear EQ toggle On/Off                     |
| h     | Harmonic Filter toggle On/Off               |
| m     | Mute audio toggle On/Off                    |
| n     | MIDI output toggle On/Off                   |
| SPACE | Pause/Play toggle                           |
| RIGHT/LEFT | Peak Threshold Increase/decrease       |
| ESC   | Quit                                        |
