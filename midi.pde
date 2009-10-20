Note[] notesOpen = new Note[128];

void outputMIDINotes() {
  if ( MIDI_TOGGLE ) {
    // send NoteOns
    for ( int i = 0; i < notes[frameNumber].length; i++ ) {
      Note note = notes[frameNumber][i];
      if ( OCTAVE_TOGGLE[note.octave] && notesOpen[note.pitch] == null) {
        midiOut.sendNoteOn(note.channel, note.pitch, 90);
        notesOpen[note.pitch] = note;
      }
    }
    
    // send NoteOffs   
    for ( int i = 0; i < notesOpen.length; i++ ) {
      boolean isOpen = false;
      if ( notesOpen[i] != null ) {
        for ( int j = 0; j < notes[frameNumber].length; j++ ) {
          if ( notes[frameNumber][j].pitch == i ) {
            isOpen = true;
          }
        }
        if ( !isOpen ) {
          midiOut.sendNoteOff(notesOpen[i].channel, i, 90);
          notesOpen[i] = null;
        }
      }
    }
  }
}

void closeMIDINotes() {  
  for ( int i = 0; i < notesOpen.length; i++ ) {
    if ( notesOpen[i] != null ) {
      midiOut.sendNoteOff(notesOpen[i].channel, i, 90);
      notesOpen[i] = null;
    }
  }
}

