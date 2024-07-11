/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		prog.h

AUTHOR:		Jimmy Lefkowitz, Jan 26, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 1/26/95	Initial version.

DESCRIPTION:
	description of a program

	$Revision: 1.1 $

	Liberty version control
	$Id: prog.h,v 1.1 98/10/05 12:35:15 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _PROG_H_
#define _PROG_H_

#ifdef LIBERTY
#include <Legos/progtask.h>
#else
#include <Legos/Internal/progtask.h>
#endif

extern MemHandle GetSystemModule(PTaskPtr ptask);

extern void
ProgDestroyZombieRTasks(PTaskPtr ptask);

extern Boolean
ProgDestroyRunTask(MemHandle ptaskHan, RTaskHan rtaskHan);

#endif /* _PROG_H_ */


