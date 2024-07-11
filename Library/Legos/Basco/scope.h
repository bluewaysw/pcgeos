/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           scope.h

AUTHOR:         Jimmy Lefkowitz, Dec  7, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	jimmy       12/ 7/94           Initial version.

DESCRIPTION:
	

	$Id: scope.h,v 1.1 98/10/13 21:43:29 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _SCOPE_H_
#define _SCOPE_H_


#include "bascoint.h"
#include <hugearr.h>

/* structure for FUNCTION-SUB loopup table element */

#define NULL_SCOPE (-1)
#define GLOBAL_SCOPE (0)

#define NULL_FUNC (-1)

#define NULL_STRING 0xffff

/* macros to get at func and offset values for a line structure
 */

#define SELF_FUNC(self) (self>>16)
#define SELF_OFFSET(self) ((self)&0xffff)
#define SELF_CONSTRUCT(func,off) ((dword)((dword)func<<16)+off)

#define NOT_FUNC 0
#define NEW_FUNC 1


void Scope_UpdateAll(TaskPtr	task,
		     dword  	element, 
		     int    	numElements);


extern void Scope_NukeScope(TaskPtr 	    	task, 
			    VMBlockHandle 	harray, 
			    word 	    	scope_num);


extern void Scope_FindRange(TaskPtr 	task,
			    word    	scope_num, 
			    dword   	*start, 
			    dword   	*end);


extern void Line_Unlock(TaskPtr task);

extern TCHAR	*Line_SelfToLine(TaskPtr 	task, 
				 sdword 	self);

extern dword Line_FindNext(TaskPtr  task, sdword self);
extern dword Line_FindPrev(TaskPtr  task, sdword self);

extern void Scope_InitCode(TaskPtr task);
#endif /* _SCOPE_H_ */
