/************************************************
 *						*
 *	Project:	BSW-CD			*
 *	Modul:		MAIN\SUBCODE.GOC  	*
 *						*
 ************************************************/

#ifndef __MAIN_SUBCODE_H
#define __MAIN_SUBCODE_H

/************** Funktionsprototypen *************/
void _pascal StartPlaying (byte track);
// start or continue playing with given track
byte _pascal GetNextTrack (void) ;
// return number of the next track to play or 0 if no more tracks
byte _pascal GetPreviousTrack (void) ;
// return number of previous track to skip back
void _pascal ReadCDData (void) ;
// read track info and database info of changed CD
void _pascal CalendarKlick ( byte track ) ;
// code for clicks into the calendar field
char * _pascal StateText ( void ) ;
// returns text for current state (stop, play, pause, disc)
void _pascal SetProgramMode ( byte newmode ) ;
// set a new program mode and reset/redraw modus and calendar
void _pascal SetABPositions( void ) ;
// displays start and endposition in AB setup box
void _pascal ResetABPosition( void ) ;
// resets AB start and end to disc start and end
void pascal DialogWindow (char * text);
// displays a notofication window
void _pascal ErrorSound(byte message);
// give an error beep
void _pascal CalendarFrame (byte index, byte color);
byte _pascal TracksToPlay (byte index, byte value);
byte _pascal ValidTracks (byte index, byte value);
// these functions set or read the array values if the index is lower than MaxTracks

#endif // __MAIN_SUBCODE_H
