/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	timedate.h
 * AUTHOR:	Tony Requist: February 14, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines time and date structures and routines.
 *
 *	$Id: timedate.h,v 1.1 97/04/04 15:58:42 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__TIMEDATE_H
#define __TIMEDATE_H

typedef enum /* word */ {
    DOTW_SUNDAY,
    DOTW_MONDAY,
    DOTW_TUESAY,
    DOTW_WEDNESDAY,
    DOTW_THURSDAY,
    DOTW_FRIDAY,
    DOTW_SATURDAY
} DayOfTheWeek;

typedef struct {
    word		TDAT_year;
    word		TDAT_month;
    word		TDAT_day;
    DayOfTheWeek	TDAT_dayOfWeek;
    word		TDAT_hours;
    word		TDAT_minutes;
    word		TDAT_seconds;
} TimerDateAndTime;

extern void	/*XXX*/
    _pascal TimerGetDateAndTime(TimerDateAndTime *dateAndTime);

/***/

#define TIME_SET_DATE 0x80
#define TIME_SET_TIME 0x40

extern void	/*XXX*/
    _pascal TimerSetDateAndTime(word flags, const TimerDateAndTime *dateAndTime);

typedef struct {
    word	TFDT_fileDate;
    word	TFDT_fileTime;
} TimerFileDateTime;

extern TimerFileDateTime	/*XXX*/
    _pascal TimerGetFileDateTime(void);

#ifdef __HIGHC__
pragma Alias(TimerGetDateAndTime, "TIMERGETDATEANDTIME");
pragma Alias(TimerSetDateAndTime, "TIMERSETDATEANDTIME");
pragma Alias(TimerGetFileDateTime, "TIMERGETFILEDATETIME");
#endif

#endif
