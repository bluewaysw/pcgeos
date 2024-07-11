/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco
FILE:		rpc.c

AUTHOR:         Jon Witort, March 22, 1996

ROUTINES:
	Name			Description
	----			-----------
	----			-----------
	BascoRpcInit		Initialize the RPC system
	BascoRpcCall		Place a call to the host. Doesn't return until
				reply received.
	BascoRpcServe		Register a server for a procedure
	BascoRpcWait		Wait for something to happen, then return
	BascoRpcRun		Call RpcWait indefinitely
	BascoRpcReply		Respond to rpc
	BascoRpcError		Send error response
	BascoRpcExit		Exit the RPC system

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon     22 mar 96       initial revision

DESCRIPTION:
	RPC stuff related to Legos tethered debugging

	$Id: bascorpc.c,v 1.1 98/10/13 21:42:21 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#include <Ansi/string.h>	/* Standard C.	*/
#include <Ansi/ctype.h>
#include <Ansi/stdio.h>
#include <Ansi/stdlib.h>

#include <geos.h>
#include <resource.h>
#include <library.h>
#include <driver.h>
#include <heap.h>
#include <thread.h>
#include <char.h>
#include <file.h>
#include <timer.h>
#include <streamC.h>		/* Additional GEOS headers.	*/
#include <serialDr.h>

#include <Legos/rpc.h>
#include <Legos/bascobug.h>
#include <Legos/Internal/fformat.h>
#include "bascoint.h"

sword
BascoBugGetCurrentFrame(PTaskHan ptaskHan)
{
    word    frame;

    /*
     * This routine exists in order to divert requests over the serial
     * port to the PCV, if need be. "If need be" is evidenced by bHan
     * being equal to REMOTE_CONNECTION_ID + whichever COM port is connected
     * to the PCV.
     */
    if (IsRpcPTask(ptaskHan)) {
	    /*
	     * Do RPC stuff
	     */
	    BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT, RPC_GET_CURRENT_FRAME,
			 0, 0, sizeof(word), &frame);
	    return frame;
    } else {
	return BugGetCurrentFrame(ptaskHan);
    }
}

Boolean
BascoBugGetFrameInfo(PTaskHan ptaskHan, word frameNumber, word *funcNum)
{
    word	retval[2];
    /*dword	retval;*/

    if (IsRpcPTask(ptaskHan)) {
	    /*
	     * Do RPC stuff
	     */
	    BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT,
			  RPC_GET_FRAME_INFO,
			  sizeof(word), &frameNumber,
			  sizeof(dword), &retval);
	    *funcNum = retval[0];
	    return retval[1];
    }

    return BugGetFrameInfo(ptaskHan, frameNumber, funcNum);
}

word
BascoBugGetFrameLineNumber(PTaskHan ptaskHan, CTaskHan compileTask,
			   word frameNumber)
{
    sword    lineNum;

    if (IsRpcPTask(ptaskHan)) {
	/*
	 * Do RPC stuff
	 */
	BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT,
		      RPC_GET_FRAME_LINE_NUM,
		      sizeof(word), &frameNumber,
		      sizeof(word), &lineNum);
	if (lineNum < 0) {
	    /* Hack -- if < 0, then treat it as an offset */
	    Boolean	isDebugged;
	    MemHandle	bugHandle;
	    word	funcNum;
	    byte        dummy;
	    sword	offset;

	    /* Take advantage of the fact that we have debugging info
	     * right here, in the compile task */
	    
	    offset = -lineNum;
	    isDebugged = BascoBugGetFrameInfo(ptaskHan, frameNumber, &funcNum);
	    ASSERT(isDebugged);	/* otherwise lineNum would be == 0 */
	    bugHandle = BascoBugGetBugHandleFromCTask(compileTask);
	    lineNum = BugOffsetToLineNum(bugHandle, funcNum, offset, &dummy);
	}

	return lineNum;
    } else {
	return BugGetFrameLineNumber(ptaskHan, frameNumber);
    }
}

void
BascoDBCS2SBCS(wchar_t *dbcsString)
{
    char       *sbcsp;

    sbcsp = (char *)dbcsString;

    while (*dbcsString) {
	*sbcsp++ = *dbcsString++;
    }
    *sbcsp = 0;
}

void
BascoSBCS2DBCS(char *sbcsString)
{
    char       *sbcsp;
    wchar_t    *dbcsp;

    sbcsp = sbcsString;
    dbcsp = (wchar_t*) sbcsString;

    while (*sbcsp) {
	sbcsp++;
	dbcsp++;
    }

    while (sbcsp >= sbcsString) {
	*dbcsp-- = *sbcsp--;
    }
}
 
void
BascoBugGetFrameName(PTaskHan ptaskHan, word frameNumber, TCHAR *dest)
{
    /*
     * This routine exists in order to divert requests over the serial
     * port to the PCV, if need be. "If need be" is evidenced by bHan
     * being equal to REMOTE_CONNECTION_ID + whichever COM port is connected
     * to the PCV.
     */
    if (IsRpcPTask(ptaskHan)) {
	/*
	 * Do RPC stuff
	 */
	BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT,
		      RPC_GET_FRAME_NAME,
		      sizeof(word), &frameNumber,
		      MAX_FRAME_NAME_CHARS, dest);
#ifndef DO_DBCS
	BascoDBCS2SBCS((wchar_t*)dest);
#endif
    } else {
	BugGetFrameName(ptaskHan, frameNumber, dest);
    }
}

void
BascoBugSetBuilderRequest(PTaskHan ptaskHan, BugBuilderRequest bbr)
{
    if (IsRpcPTask(ptaskHan)) {
	BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT,
		      RPC_SET_BUILDER_REQUEST,
		      sizeof(BugBuilderRequest), &bbr,
		      0, 0);
    } else {
	BugSetBuilderRequest(ptaskHan, bbr);
    }
}

BugBuilderRequest
BascoBugGetBuilderRequest(PTaskHan ptaskHan)
{
    BugBuilderRequest bbr;

    /*
     * This routine exists in order to divert requests over the serial
     * port to the PCV, if need be. "If need be" is evidenced by ptaskHan
     * being equal to REMOTE_CONNECTION_ID + whichever COM port is connected
     * to the PCV.
     */
    if (IsRpcPTask(ptaskHan)) {
	    /*
	     * Do RPC stuff
	     */
	    BasrunRpcCall(RpcRTask2SerialUnit(ptaskHan), RPC_DEFAULT_TIMEOUT,
			  RPC_GET_BUILDER_REQUEST,
			  0, 0,
			  sizeof(BugBuilderRequest), &bbr);
	    return bbr;
    } else {
	return BugGetBuilderRequest(ptaskHan);
    }
}

void 
BascoBugSetBreakAtOffset(MemHandle bugHandle, word funcNumber, word offset,
			 word lineNumber, BugBreakFlags breakFlags) 
{
    RpcSetBreakArgs     rsba;

    /*
     * This routine exists in order to divert requests over the serial
     * port to the PCV, if need be. "If need be" is evidenced by bHan
     * being equal to REMOTE_CONNECTION_ID + whichever COM port is connected
     * to the PCV.
     */
    if (IsRpcPTask(bugHandle)) {
	    /*
	     * Do RPC stuff
	     */
	rsba.RSBA_offset = offset;
	rsba.RSBA_funcNum = funcNumber;
	rsba.RSBA_lineNum = lineNumber;
	rsba.RSBA_flags = breakFlags;

	BasrunRpcCall(RpcRTask2SerialUnit(bugHandle), RPC_DEFAULT_TIMEOUT, RPC_SET_BREAK_AT_OFFSET,
		     sizeof(RpcSetBreakArgs), &rsba, 0, 0);
    } else {
	BugSetBreakAtOffset(bugHandle, funcNumber,
			    offset, lineNumber, breakFlags);
    }
}

void 
BascoBugClearBreakAtOffset(MemHandle bugHandle, word funcNumber, word offset)
{
    RpcClearBreakArgs     rcba;

    /*
     * This routine exists in order to divert requests over the serial
     * port to the PCV, if need be. "If need be" is evidenced by bHan
     * being equal to REMOTE_CONNECTION_ID + whichever COM port is connected
     * to the PCV.
     */
    if (IsRpcPTask(bugHandle)) {
	    /*
	     * Do RPC stuff
	     */
	rcba.RCBA_offset = offset;
	rcba.RCBA_funcNum = funcNumber;

	BasrunRpcCall(RpcRTask2SerialUnit(bugHandle), RPC_DEFAULT_TIMEOUT, RPC_CLEAR_BREAK_AT_OFFSET,
		     sizeof(RpcClearBreakArgs), &rcba, 0, 0);
    } else {
	BugClearBreakAtOffset(bugHandle, funcNumber, offset);
    }
}

RpcError
BascoRpcSendFile(SerialPortNum port, TCHAR *path) {
    FileHandle    fh;
    byte          buffer[255];
    word          bytesRead;
    RpcError      err;

#if 0
    This routine has been changed so that the suffix should be passed in.
    /*
     * Let's see if we can open the file, ourselves. We tack on the '.bcl'
     * in this rather untoward fashion to avoid the whole setDStoDgroup crap.
     */
    strcpy((TCHAR *)buffer, path);
    moduleName = buffer + strlen((TCHAR *) buffer);
    *moduleName++ = '.';
    *moduleName++ = 'b';
    *moduleName++ = 'c';
    *moduleName++ = 'l';
    *moduleName++ = 0;
#endif

    if ((fh = FileOpen(path, FILE_ACCESS_R | FILE_DENY_RW)) == NullHandle) {
	return RPC_BADARGS;
    }

    /*
     * Tell the remote client to open up a file of the same name.
     */

#ifdef DO_DBCS
{
    TCHAR         *moduleName;
    moduleName = strrchr(path, '\\') + 1;
    err = BasrunRpcCall(port, RPC_DEFAULT_TIMEOUT, RPC_SEND_FILE,
			sizeof(TCHAR) * (strlen(moduleName) + 1),
			moduleName, 0, 0);
}   
#else
    strcpy((TCHAR *)buffer, strrchr(path, '\\') + 1);
    bytesRead = sizeof(wchar_t) * (strlen((char *)buffer) + 1);
    BascoSBCS2DBCS((char *)buffer);
    err = BasrunRpcCall(port, RPC_DEFAULT_TIMEOUT, RPC_SEND_FILE,
			bytesRead, buffer, 0, 0);
#endif

    /*
     * If that succeeded, send the file piece by piece.
     */
    while (err == RPC_SUCCESS) {
	bytesRead = FileRead(fh, buffer, 255, FALSE);
	err = BasrunRpcCall(port, RPC_DEFAULT_TIMEOUT, RPC_SEND_FILE_NEXT_BLOCK,
			    bytesRead, buffer, 0, 0);
	if (bytesRead == 0) {
	    break;
	}
    }

    FileClose(fh, FALSE);

    return err;
}

RpcError
BascoRpcLoadModule(SerialPortNum port, TCHAR *path) {
#ifdef DO_DBCS
    /*
     * Witch comptrace turned on, loading can take a *long* time.
     * Let's try 30 seconds.
     */
    return BasrunRpcCall(port, 1800, RPC_LOAD_MODULE,
			 sizeof(TCHAR) * (strlen(path) + 1), path, 0, 0);
#else
    char	buffer[127*sizeof(wchar_t)];
    word	bytesRead;

    strcpy(buffer, path);
    bytesRead = sizeof(wchar_t) * (strlen(buffer) + 1);
    BascoSBCS2DBCS(buffer);
    /*
     * Witch comptrace turned on, loading can take a *long* time.
     * Let's try 30 seconds.
     */
    return BasrunRpcCall(port, 1800, RPC_LOAD_MODULE,
			 bytesRead, (wchar_t*)buffer, 0, 0);
#endif
}

RpcError
BascoRpcHello(SerialPortNum port) {
    byte        pcvProto[2];
    RpcError    retval;

    retval = BasrunRpcCall(port, RPC_DEFAULT_TIMEOUT, RPC_HELLO,
			   0, 0, 2, pcvProto);

    if (retval == RPC_SUCCESS) {
	if ((pcvProto[0] != BC_MAJOR_REV) || (pcvProto[1] != BC_MINOR_REV)) {
	    retval = RPC_BAD_PROTO;
	}
    }

    return retval;
}


