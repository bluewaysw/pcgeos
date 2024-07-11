/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		bugext.h

AUTHOR:		Roy Goldman, Feb 11, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 2/11/95	Initial version.

DESCRIPTION:
	Debugging functionality exported to runtime engine alone.

	$Revision: 1.1 $

	Liberty version control
	$Id: bugext.h,v 1.1 98/10/05 12:35:33 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BUGEXT_H_
#define _BUGEXT_H_

#ifdef LIBERTY
#include "Legos/basrun.h"
#include "Legos/bug.h"
#include "Legos/progtask.h"
#include "Legos/runint.h"
#else
#include <Legos/basrun.h>
#include <Legos/bug.h>
#include <Legos/Internal/progtask.h>
#include "runint.h"
#include <sem.h>
#endif

Boolean BugSetOneTimeBreakAtOffset(MemHandle bugHan, word funcNumber,
				   word lineNum, word offset);

/* Set the run tasks's suspension status to one of the
   BugSuspendStatus values above...  Should be done
   right before quitting RunMainLoop..
*/

void BugSetSuspendStatus(MemHandle bugHandle, BugSuspendStatus bss);


/* Translates the absolute segment of a module into the
   function number which corresponds to it...
*/

word BugGetFuncFromContext(FrameContext *fc);

/* Checks to see if a breakpoint exists at the given offset.

   If so, returns the actual breakpoint.
   Otherwise, it returns a breakpoint whose BBP_insn is set
   to OP_ILLEGAL
*/
BugBreakPoint BugDoesBreakAtOffset(MemHandle bugHan,
				   word funcNumber, word offset,
				   BugBreakFlags compareFlags);

word BugGetCurrentFrameFromRML(RMLPtr rms);

void BugThreadPSem(SemaphoreHandle  sem);
extern void BugSitAndSpin(word destMessage);
#endif /* _BUGEXT_H_ */
