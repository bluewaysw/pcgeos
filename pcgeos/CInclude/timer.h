/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	timer.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines timer structures and routines.
 *
 *	$Id: timer.h,v 1.1 97/04/04 15:58:45 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__TIMER_H
#define __TIMER_H

/***/

typedef enum /* word */ {
    TIMER_ROUTINE_ONE_SHOT=0,
    TIMER_ROUTINE_CONTINUAL=2,
    TIMER_EVENT_ONE_SHOT=4,
    TIMER_EVENT_CONTINUAL=6,
    TIMER_MS_ROUTINE_ONE_SHOT=8,
    TIMER_EVENT_REAL_TIME=10,
    TIMER_ROUTINE_REAL_TIME=12
} TimerType;

typedef WordFlags TimerCompressedDate;
#define TCD_YEAR    	    	0xfe00	/* years since 1980 */
#define TCD_MONTH   	    	0x01e0	/* months (1 - 12) (0 illegal) */
#define TCD_DAY	    	    	0x001f	/* days (1-31) (0 illegal) */

#define TCD_YEAR_OFFSET		9
#define TCD_MONTH_OFFSET	5
#define TCD_DAY_OFFSET		0

extern TimerHandle
    _pascal TimerStart(TimerType timerType,
	       optr destObject,word ticks,
	       Message msg,
	       word interval,
	       word *id);

/***/

extern Boolean		/* true if not found */
    _pascal TimerStop(TimerHandle th, word id);

/***/

extern void	/*XXX*/
    _pascal TimerSleep(word ticks);

/***/

extern dword	/*XXX*/
    _pascal TimerGetCount(void);

#ifdef __HIGHC__
pragma Alias(TimerStart, "TIMERSTART");
pragma Alias(TimerStop, "TIMERSTOP");
pragma Alias(TimerSleep, "TIMERSLEEP");
pragma Alias(TimerGetCount, "TIMERGETCOUNT");
#endif

#endif
