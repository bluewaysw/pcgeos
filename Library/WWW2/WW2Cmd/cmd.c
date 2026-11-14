/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1998.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	WWW2 Library
MODULE:		WW2Core
FILE:		cmd.c

AUTHOR:		Allen Yuen, Aug 17, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	allen   	8/17/98   	Initial version

DESCRIPTION:

	Command objects are callback in C++.
	//depot/liberty/project/ellery/980805/library/www/wwcore/cmd.cpp#1

	$Id: //depot/pcgeos/Library/WWW2/WW2Cmd/cmd.c#1 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <geos.h>
#include <heap.h>
#include <WWW2/wwMacro.h>
#include <WWW2/WW2Core/cmd.h>

//---------------------------------------------------------------------------
//		ExecuteCommand()
//---------------------------------------------------------------------------
// 
// SYNOPSIS: 	This is provided so that a thread->Start can execute a 
//              command object.
// SCOPE:	Public
// RETURN:	Nothing
// STRATEGY:	
// 
// REVISION HISTORY: 
//	Name		Date		Description 
//	----		----		----------- 
//	kkee    	1/19/98 	Initial version 
//	
//---------------------------------------------------------------------------
/*void 
ExecuteCommand(Command *cmd)*/
word
ExecuteCommand(MemHandle cmdPtrPtrHptr)
{    
    Command *cmdPtr;

    cmdPtr = *(Command **) MemLock(cmdPtrPtrHptr);
    MemFree(cmdPtrPtrHptr);
    EC_BOUNDS(cmdPtr);
    EC_BOUNDS((void *) (cmdPtr->Execute));
    cmdPtr->Execute(cmdPtr);
    return 0;				/* success (for ThreadDestroy) */
}	/* End of ExecuteCommand() */

//---------------------------------------------------------------------------
//		ExecuteCommandArg()
//---------------------------------------------------------------------------
// 
// SYNOPSIS: 	Execute a command object that takes and returns arguments.
// SCOPE:	Public
// RETURN:	Nothing
// STRATEGY:	
// 
// REVISION HISTORY: 
//	Name		Date		Description 
//	----		----		----------- 
//	kkee    	1/19/98 	Initial version 
//	
//---------------------------------------------------------------------------
int
ExecuteCommandArg(CommandArg *cmd, int arg, const char* argv[], 
                  int argr, char *argrv[])
{
    EC_BOUNDS(cmd);
    EC_BOUNDS((void *) (cmd->Execute));
    return cmd->Execute(arg, argv, argr, argrv);
}	/* End of ExecuteCommand() */
