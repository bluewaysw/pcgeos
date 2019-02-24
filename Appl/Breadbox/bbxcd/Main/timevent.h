/************************************************
 *						*
 *	project:	BSW-CD			*
 *	module:		MAIN\TIMEVENT.GOC 	*
 *						*
 ************************************************/


#ifndef __MAIN_TIMEVENT_H
#define __MAIN_TIMEVENT_H


long RedbookCal (long rbTime, byte addition);
// correct Redbook time after calculation)
void _pascal BC_Timer_Event(unsigned char cdTurnPhase ) ;
// all funtions and subfunctions for the timer event

#endif // __MAIN_TIMEVENT_H

