/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        Legos	
MODULE:		Basic runtime
FILE:		bugint.h

AUTHOR:		Roy Goldman, Jan 16, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 1/16/95	Initial version.

DESCRIPTION:
	
        Debugging headers for internal stuff.

	$Revision: 1.1 $
	Liberty version control
	$Id: bugint.h,v 1.1 98/10/05 12:35:35 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BUGINT_H_
#define _BUGINT_H_

#include "bugext.h"

/* -- Internal Interface ------------------------------------- */

typedef struct
{
    dword*		dataStack;
    byte*		typeStack;
    FrameContext*	context;	/* pointer into data stack */
} BugFrameContext;


/* Internal.................... */

/* Take a source line number for a given function and map
   it into the virtual offset of the first instruction
   corresponding to that source line.

   Should use line number label information generated
   at compile time.
*/

word BugLineNumToOffset(MemHandle bugHandle, word funcNumber, word lineNum);


/* These routines are the low level breakpoint facilities */



/* Clears a breakpoint at the given offset.  If there isn't a break
   here, it does nothing.  Otherwise, it will remove the breakpoint
   from the break list and restore the code which was displaced.
*/

void BugClearBreakAtOffset(MemHandle bugHan, word funcNumber, word offset);

/* Given a pointer to a framecontext on the stack, return a pointer
   to the previous framecontext on the stack. Useful for counting frames.
*/

void	Bug_FindScope(PTaskHan, sword frame,
		      MemHandle* toUnlock, word* sizeP,
		      byte** typePP, dword** dataPP);

void	Bug_GetPreviousContext(BugFrameContext* bfc);

FrameContext Bug_GetNthContext(PTaskHan, word frame);

#endif /* _BUGINT_H_ */
