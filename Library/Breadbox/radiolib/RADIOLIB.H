typedef MemHandle RadioHandle ;

RadioHandle FMRadioInit(void) ;
void FMRadioDeinit(RadioHandle radioMem) ;
int FMRadioTuneStation(RadioHandle radioMem, word tuneFreq, int mute, Boolean slow) ;
word FMRadioVolumeControl(RadioHandle radioMem, word style) ;
word FMRadioMuteAudio(RadioHandle radioMem, word mute) ;

