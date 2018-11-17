/************************************************
 *						*
 *	project:	BSW-CD			*
 *	module:		MAIN\KEY.GOC            *
 *						*
 ************************************************/

#ifndef __MAIN_KEY_H
#define __MAIN_KEY_H

extern unsigned char kbdChar ;
// contains VC_F4 - VC_F8 when pressed globally with SHIFT.

void _pascal InstallMonitor ( void );
// installs the KeyboardIntercept Monitor
// Par1 must be 293, par2 must be 21
void _pascal KillMonitor ( void );
// removes the KeyboardIntercept Monitor
// Par1 must be 293, par2 must be 64

#endif //__MAIN_KEY_H

