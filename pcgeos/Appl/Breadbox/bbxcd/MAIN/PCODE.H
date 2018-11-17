/************************************************
 *						*
 *	Project:	BSW-CD			*
 *	Modul:		MAIN\PCODE.GOC		*
 *						*
 ************************************************/

#ifndef __MAIN_PCODE_H
#define __MAIN_PCODE_H

// ************** Funktionsprototypen *************
void _pascal Gen_Process_Open_Application(void) ;
// general initialisation
void _pascal Bcd_Trig_Rew (void) ;
// play previous track or restart track
void _pascal Change_Display_Mode (void) ;
// cyclic change of DisplayMode (0 to 3)
void _pascal Bcd_Trig_Eject (void) ;
// open or close drive door
void _pascal Bcd_Trig_Play(void) ;
// play disc
void _pascal Bcd_Trig_Stop (void) ;
// stop playing
void _pascal Bcd_Trig_Fwd(void) ;
// skip to next track
void _pascal Bcd_Trig_Scan(void) ;
// enter or leave title scan mode
void _pascal Reset_Application (byte drive) ;
// reset all application data after changing CD drive

#endif //__MAIN_PCODE_H

