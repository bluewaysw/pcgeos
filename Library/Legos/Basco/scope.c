/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		scope.c

AUTHOR:		Jimmy Lefkowitz, Dec  7, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/ 7/94   	Initial version.

DESCRIPTION:
 	    code dealing with "scopes" which are used for code and functions
	    or variables and local scopes

	$Id: scope.c,v 1.1 98/10/13 21:43:27 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <Ansi/stdio.h>
#include <Ansi/ctype.h>
#include <Legos/edit.h>
#include "scope.h"
#include "ftab.h"
#include <char.h>


/*********************************************************************
 *			Scope_FindRange
 *********************************************************************
 * SYNOPSIS: 	find the last element in a scope
 * CALLED BY:	var_new
 * RETURN:  	element number of last element in the scope
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	8/24/94		Initial version			     
 * 
 *********************************************************************/
void
Scope_FindRange(TaskPtr task, word scope_num, dword *start, dword *end)
{
    FTabEntry	*ftab;
    
    ftab = FTabLock(task->funcTable, scope_num);
    *start = SELF_OFFSET(ftab->lineElement);
    *end = *start + ftab->numLines - 1;
    FTabUnlock(ftab);
}

/*********************************************************************
 *			Scope_NukeScope
 *********************************************************************
 * SYNOPSIS: 	nuke a scope from the HugeArray and list of scopes
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	8/29/94		Initial version			     
 * 
 *********************************************************************/
void
Scope_NukeScope(TaskPtr task, VMBlockHandle harray, word scope_num)
{
    FTabEntry	    	*ftab;

    ftab = FTabLock(task->funcTable, scope_num);
    HugeArrayDelete( task->vmHandle, harray, 
		     ftab->numLines, (word)ftab->lineElement);
#if ERROR_CHECK
    ECCheckHugeArray( task->vmHandle, harray );
#endif
    /* now update all the other scope pointers */
    Scope_UpdateAll(task, (word)ftab->lineElement, ftab->numLines);
    ftab->numLines = 0;
    FTabUnlock(ftab);
}


#if 0
/*********************************************************************
 *			Scope_CreateScope
 *********************************************************************
 * SYNOPSIS: 	create a new scope
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	8/24/94		Initial version			     
 * 
 *********************************************************************/
word
Scope_CreateScope(TaskPtr   	task, 
		  MemHandle 	scope_han, 
		  VMBlockHandle harray, 
		  ScopeStruct	*sc)
{
    ScopeStruct	    	    *scopes;
    struct scopes_header    *sh;
    word    		    num;
    dword   	 	    new;
    word    	    	    scopenum=0;

    sh = MemLock( scope_han );
    num = sh->num_scopes;
    scopes = &(sh->scopes);
    while (num) 
    {
	if (scopes[0].scope_start == NULL_SCOPE) {
	    break;
	}
	scopenum++;
	scopes++;
	num--;
    }

    new = HugeArrayGetCount( task->vmHandle, harray );

    /* we stopped on a NULL_SCOPE, then we are replacing an old scope
     * so need to worry about overflow
     */
    if (scopes[0].scope_start == NULL_SCOPE)
    {
	scopes[0].scope_start = new;
	scopes[0].scope_end = new;
    }
    else
    {
	if (!(sh->num_scopes & (INC_NUM_SCOPES-1)))
	{
	    MemReAlloc(scope_han, ((sh->num_scopes+INC_NUM_SCOPES)*
		       	    	    	sizeof(ScopeStruct))
		    	    	    	+ sizeof(word), 
		       	    	HAF_ZERO_INIT);
	    sh = MemDeref(scope_han );
	    scopes = &(sh->scopes) + sh->num_scopes;
#ifdef	DOS
	    /* zero out new memory */
	    memset(scopes, 0, INC_NUM_SCOPES * sizeof(ScopeStruct));
#endif
	}
	scopes[0].scope_start = new;
	scopes[0].scope_end = new;
    }
    sh->num_scopes++;
    if (sc != NULL)
    {
	memcpy(sc, scopes, sizeof(ScopeStruct));
    }
    MemUnlock(scope_han );
    return scopenum;
}
#endif

/*********************************************************************
 *			Scope_UpdateAll
 *********************************************************************
 * SYNOPSIS: 	update scope pointers
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	8/24/94		Initial version			     
 * 
 *********************************************************************/
void
Scope_UpdateAll(TaskPtr task, dword element, int numElements)
{
    FTabEntry	*ftab;
    word    	count, i;

    count = FTabGetCount(task->funcTable);
    for (i = 0; i < count; i++)
    {
	ftab = FTabLock(task->funcTable, i);
	if ((word)ftab->lineElement > element)
	{
	    ftab->lineElement -= numElements;
	}
	FTabUnlock(ftab);
    }
}

/*********************************************************************
 *			EC_ScopeCheck
 *********************************************************************
 * SYNOPSIS:	check for a legal scope count
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	10/10/94		Initial version			     
 * 
 *********************************************************************/
#if 0
void
EC_ScopeCheck(struct scopes_header *sh, MemHandle han, sword scope_num)
{
    ScopeStruct	    *scope;
    int	i;

    i = MemGetInfo(han, MGIT_SIZE);
    i /= sizeof(ScopeStruct);
    if ( i <= scope_num)
    {
	EC_ERROR(0);
    }

    scope = &(sh->scopes) + i - 1;
    while(i)
    {
	if (scope->scope_start != NULL_SCOPE)
	{
	    break;
	}
	scope--;
	i--;
    }

    if (scope_num > i) 
    {
	EC_ERROR(0);
    }
}
#endif


/*********************************************************************
 *			Line_Unlock
 *********************************************************************
 * SYNOPSIS:	unlock a line
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	9/27/94		Initial version			     
 * 
 *********************************************************************/
void
Line_Unlock(TaskPtr task)
{
    MemUnlock(task->lineBuffer);
}

/*********************************************************************
 *			Line_SelfToLine
 *********************************************************************
 * SYNOPSIS:	convert a self value to an actual line
 * CALLED BY:	various parse routines
 * RETURN:  	a line element
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	9/22/94		Initial version			     
 * 
 *********************************************************************/
TCHAR	*Line_SelfToLine(TaskPtr task, sdword self)
{
    dword	start;
    word	size;
    TCHAR	*lineBuffer, *cp;
    TCHAR	*curLine;
    int	    	offset;

    start = SELF_OFFSET(self);
    if (start >= HugeArrayGetCount(task->vmHandle, task->code_han))
    {
	return NULL;
    }

    /* lets see if this line ends in a backslash, if so tack on the next
     * line.
     */
    cp = lineBuffer = MemLock(task->lineBuffer);
    while (1)
    {
	HugeArrayLock(task->vmHandle, task->code_han, 
		      start, (void**)&(curLine), &size );
	size /= sizeof(TCHAR);

	if ((cp != lineBuffer) && IS_LINE_DESCRIPTOR(*curLine))
	{
	    /* Continued line -- don't copy the intial line descriptor */
	    strcpy(cp, curLine+1);
	    offset = 3;
	} else {
	    strcpy(cp, curLine);
	    offset = 2;
	}

	HugeArrayUnlock(curLine);
	if (size < 2 || cp[size-offset] != C_BACKSLASH)
	{
	    break;
	}
	start++;
	cp += strlen(cp);
 	*cp++ = C_ENTER;
    }
    return lineBuffer;
}

/*********************************************************************
 *			Line_FindNext
 *********************************************************************
 * SYNOPSIS:	find next line in code array
 * CALLED BY:	Parse routines
 * RETURN:  	dword pointer to next line
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 5/ 3/95	Initial version			     
 * 
 *********************************************************************/
dword Line_FindNext(TaskPtr task, sdword self)
{
    dword   start;
    TCHAR    *line;
    word    size;

    start = SELF_OFFSET(self);
    EC_ERROR_IF(start >= HugeArrayGetCount(task->vmHandle, task->code_han), -1);

    /* lets see if this line ends in a backslash, if so tack on the next
     * line
     */
    while (1)
    {
	HugeArrayLock(task->vmHandle, task->code_han, 
		      start, (void**)&line, &size );
    
	size /= sizeof(TCHAR);
	if (size < 2 || line[size-2] != C_BACKSLASH) {
	    break;
	}
	HugeArrayUnlock(line);
	start++;
    }

    HugeArrayUnlock(line);
    return start+1;
}

#if 0
/*********************************************************************
 *			Line_FindPrev
 *********************************************************************
 * SYNOPSIS:	find next line in code array
 * CALLED BY:	Parse routines
 * RETURN:  	dword pointer to next line
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 5/ 3/95	Initial version			     
 * 
 *********************************************************************/
dword Line_FindPrev(TaskPtr task, sdword self)
{
    dword   start, end, cur;
    TCHAR    *line;
    word    size;

    start = SELF_OFFSET(self);
    if (start < 2) {
	return 0;
    }
    EC_ERROR_IF(start >= HugeArrayGetCount(task->vmHandle, task->code_han), -1);

    /* go backwards while previous lines end in \n */
    start -= 2;
    while (cur > start)
    {
	HugeArrayLock(task->vmHandle, task->code_han, 
		      cur, (void**)&line, &size );
    
	size /= sizeof(TCHAR);
	if (size < 2 || line[size-2] != C_BACKSLASH) {
	    break;
	}
	HugeArrayUnlock(line);
	--start;
    }

    HugeArrayUnlock(line);
    return start+1;
}
#endif





/*********************************************************************
 *			Scope_InitCode
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/16/96  	Initial version
 * 
 *********************************************************************/
void
Scope_InitCode(TaskPtr task)
{
    /* The first code scope is in fact a stack which keeps track
       of interactive calls. This allows a component event handler,
       which gets activated with a direct call into the interpreter,
       to trigger another event, and so on... */

    if (task->code_han != NullHandle) {
	HugeArrayDestroy(task->vmHandle, task->code_han);
    }
    task->code_han = HugeArrayCreate(task->vmHandle, 0, 0);
}
