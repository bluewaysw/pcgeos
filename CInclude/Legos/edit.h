/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S !
MODULE:		Basco
FILE:		edit.h

AUTHOR:		Roy Goldman, Jan 26, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 1/26/95	Initial version.

DESCRIPTION:
	
        Header file for the code access functionality
	that currently (and wrongly!) exists in the compiler.

	$Id: edit.h,v 1.1 1999/02/18 22:48:32 (c)turon Exp martin $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _EDIT_H_
#define _EDIT_H_
#include <geos.h>

/* Lame shitty way to mark breakpoints in source code for now, just
   the first byte of the line
*/

#define IS_LINE_DESCRIPTOR(x) ((byte)(x)>=DBG_NORMAL && (byte)(x)<=DBG_BREAK_AND_PC)

typedef enum {DBG_NORMAL=250, DBG_BREAK, DBG_PC, DBG_BREAK_AND_PC} DebugStatus;

/* Grabs the number of active routines (from source code storage) */

int EditGetNumRoutines(MemHandle taskHan);


/* Given a routine name, return its index into our code store (>=0),
   or -1 if none exists... */

int EditGetRoutineIndex(MemHandle taskHandle, TCHAR *name);

/* Given an index into the (source code) function table,
   write the name of the function into dest. Assume dest has
   been preallocated and big enough.

   Don't confuse this with BugGetRoutineName... This routine
   here deals only with the source code huge array which unfortunately
   is still in the compiler. This whole file will soon disappear...
*/

void EditGetRoutineName(MemHandle taskHandle, int index, TCHAR *dest);

/* Wipe out all routines (source code!) for a given compiler task */

void EditDeleteAllCode(MemHandle taskHandle);

/* Get the number of lines in a function at the given index.
   Fill in codeOffset with data which will optimized lookup of
   the actual lines of this routine.
*/

int EditGetRoutineNumLines(MemHandle taskHandle, int index,
			   dword *codeOffset);

/* Given a line number and an offset code used to identify
   a routine (generated by EditGetRoutineNumLines), returns
   the break flag for that line.
*/

Boolean EditGetLineDebugStatus(MemHandle taskHandle, dword codeOffset,
			    int index);

/* Like above, but for setting the breakflag */

void EditSetLineDebugStatus(MemHandle taskHandle, dword codeOffset,
			    int index, DebugStatus value);

/* Given a line number and a codeOffset (generated by EditGetRoutineNumLines)
   use this to return a char *pointer to the actual line text.
   Client must unlock.
*/

TCHAR *EditGetLineTextWithLock(MemHandle taskHandle, dword codeOffset,
			      int index);

#endif /* _EDIT_H_ */
