/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		alserver.h

AUTHOR:		Paul L. Du Bois, May 20, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/20/96  	Initial version.

DESCRIPTION:
	Minimal .h file to support alserver.goc

	$Id: alserver.h,v 1.1 98/03/11 04:30:51 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _ALSERVER_H_
#define _ALSERVER_H_

#include <geos.h>

#define USE_IT(_x) (void)(_x)
/* little-endian dword, reads "alrm" */
#define ALARM_MAGIC_DWORD 0x6d726c61

#define ASSERT(_cond) EC_ERROR_IF(!(_cond), -1)

#define YEAR_MIN	1980

#define YEAR_MAX	2099

extern optr theLauncherArray;

/* Change alserver.def if you change this */
typedef struct
{
    ChunkHandle	uniqueID;
    ChunkHandle	moduleLocator;
    ChunkHandle	moduleContext;
    Boolean	active;	/* only FALSE just after alarms are loaded */
    TimerHandle	timerHandle;
    word	timerID;

    Boolean	enabled;
    word	year;
    byte	month;
    byte	day;
    byte	hour;
    byte	minute;
    byte	second;
} AlarmEntry;

extern void _far _pascal
SLNotifyLaunchersOfAlarm(TCHAR);

#endif /* _ALSERVER_H_ */
