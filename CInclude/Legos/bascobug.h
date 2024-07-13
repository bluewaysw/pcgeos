/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco Debugger
FILE:		bascobug.h

AUTHOR:		Roy Goldman, Jan 11, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 1/11/95	Initial version.

DESCRIPTION:
	
	Basco-only bug related stuff
	$Id: bascobug.h,v 1.1 1999/02/18 22:48:14 (c)turon Exp martin $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BASCOBUG_H_
#define _BASCOBUG_H_
#include <geos.h>
#include <Legos/basco.h>
#include <Legos/basrun.h> 
#include <Legos/bug.h> 
#include <Legos/rpc.h> 

void BascoSBCS2DBCS(char *sbcsString);
void BascoDBCS2SBCS(wchar_t *dbcsString);

/*
 * Tethered debugging related stuff
 */

#define REMOTE_CONNECTION_ID 0xcdb0
/*
 * Whichever serial port (1,2,3,4 = COM1, COM2, COM3, COM4) is connected
 * to the PCV is OR'd in to this constant in place of a PTaskHan.
 * "cdb" means Cabled DeBugging, COM DeBugging, or Christopher David Boyke,
 * take your pick.
 */
#define RpcRTask2SerialUnit(x) (((x & 0x000f) - 1) << 1)
#define IsRpcPTask(x) ((x & 0x000f) && ((x & 0xfff0) == REMOTE_CONNECTION_ID))

/* Initialize the debugger with line label information (given in
   compileLineArray), set up an empty break list, etc. Compilation must
   be complete before you make this call.  */

void	BascoBugInit(CTaskHan, BugBuilderInfo* bbh);
word	BascoBugGetNumVars(PTaskHan, sword frame);
BugVar	BascoBugGetSetVar
    (PTaskHan, sword frame, word varIndex, BugVar bv, Boolean set);
void BascoBugNumVarToString(BugVar bv, TCHAR *dest);
TCHAR*	BascoBugGetVarName
    (PTaskHan, CTaskHan, sword frame, word varNum, TCHAR *dest);
void BascoBugGetString(PTaskHan, dword stringIndex, TCHAR *dest, word maxLen);
MemHandle BascoBugGetBugHandleFromCTask(CTaskHan);

BugVar BascoBugGetSetStructFieldData(MemHandle rtaskHan,
				     sword frameNumber, word varNum,
				     word fieldNum, TCHAR *dest,
				     word  arrayElement, BugVar sVar, 
				     Boolean set);
word BascoBugGetNumFields(PTaskHan, sword frame, word varNum);
word BascoBugGetArrayDims(PTaskHan, sword frame, word varNum, word dims[]);

#define GET_VAR FALSE
#define SET_VAR TRUE
BugVar BascoBugGetSetArrayElement
    (PTaskHan, sword frame, word varNum,
     word element, BugVar sVar, Boolean set);

BugVar BascoBugCreateString(PTaskHan, TCHAR *src, BugVar oldString);

/* Given a BugVar, return a char pointer to the string
   representation of its value. Don't forget to unlock it.
   Only for numbers (OP_INTEGER, OP_LONG, OP_FLOAT)
*/
BugVar BascoBugStringToNumber(TCHAR *dest, LegosType type);

BugBuilderRequest BascoBugGetBuilderRequest(MemHandle bHan);
void BascoBugSetBuilderRequest(MemHandle bHan, BugBuilderRequest bbr);

void BascoBugSetBreakAtOffset(MemHandle bugHandle, word funcNumber, word offset, word lineNumber, BugBreakFlags breakFlags);
void BascoBugClearBreakAtOffset(MemHandle bugHandle, word funcNumber, word offset);
sword BascoBugGetCurrentFrame(PTaskHan);
Boolean BascoBugGetFrameInfo(PTaskHan, word frame, word *funcNum);
word BascoBugGetFrameLineNumber(PTaskHan, CTaskHan, word frame);
void BascoBugGetFrameName(PTaskHan, word frame, TCHAR *dest);

RpcError BascoRpcSendFile(SerialPortNum port, TCHAR *path);
RpcError BascoRpcLoadModule(SerialPortNum port, TCHAR *path);

RpcError BascoRpcHello(SerialPortNum port);

#endif /*_BASCOBUG_H_ */
