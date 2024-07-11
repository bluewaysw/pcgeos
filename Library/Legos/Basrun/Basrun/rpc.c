/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basrun
FILE:		rpc.c

AUTHOR:         Jon Witort, March 22, 1996

ROUTINES:
	Name			Description
	----			-----------
	----			-----------
	BasrunRpcInit		Initialize the RPC system
	BasrunRpcCall		Place a call to the host. Doesn't return until
				reply received.
	BasrunRpcServe		Register a server for a procedure
	BasrunRpcWait		Wait for something to happen, then return
	BasrunRpcRun		Call RpcWait indefinitely
	BasrunRpcReply		Respond to rpc
	BasrunRpcError		Send error response
	BasrunRpcExit		Exit the RPC system

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon     22 mar 96       initial revision

DESCRIPTION:
	RPC stuff related to Legos tethered debugging

	$Revision: 1.2 $
	$Id: rpc.c,v 1.2 98/10/05 12:29:15 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifdef LIBERTY

#include <Legos/rpc.h>
#include <streams/connect.h>

#else

#include <geos.h>
#include <library.h>
#include <resource.h>

#include <Ansi/string.h>	/* Standard C.	*/
#include <Ansi/ctype.h>
#include <Ansi/stdio.h>
#include <Ansi/stdlib.h> 

#include <serialDr.h>
#include <driver.h>
#include <heap.h>
#include <thread.h>
#include <char.h>
#include <file.h>
#include <timer.h>
#include <Legos/rpc.h>
#include <streamC.h>		/* Additional GEOS headers.	*/
#include "fixds.h"

#endif

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Global Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifdef LIBERTY
/*
 * stream.h already defines a global SerialDriver, theSerialDriver
 */
Boolean serialPortOpen[1];
byte msgId[1] = {0xa0};
#define unitOrConnection connection

#if defined(ARCH_r3900)
#define TD_SERIAL_PORT COM3
#else
#define TD_SERIAL_PORT COM1
#endif

#else
static Handle   serialDriver   = NullHandle;
static Boolean	serialPortOpen[4] = {FALSE,FALSE,FALSE,FALSE};
static optr     writeWatch[4] = {NullOptr,NullOptr,NullOptr,NullOptr};
static optr     readWatch[4] = {NullOptr,NullOptr,NullOptr,NullOptr};

/*
 * msgID keeps track of the various id numbers of the RPC requests sent over
 * whichever COM port.
 */
static byte	msgId[4] = {0xa0,0xb0,0xc0,0xd0};

#define unitOrConnection unit

#if	ERROR_CHECK
TCHAR driverName[] = _TEXT("serialec.geo");
#else
TCHAR driverName[] = _TEXT("serial.geo");
#endif


extern void _pascal DoSerialNotifyStuff(Handle driver, SerialUnit port, optr destObj, word destMsg);
#ifdef __HIGHC__
pragma Alias (DoSerialNotifyStuff,"DOSERIALNOTIFYSTUFF");
#endif



void
Notify(optr o, char *s)
{
    if (o != NullOptr) {
        ((void(*)(const char *,word,word,optr,Message,word))&CObjMessage)(s,0,  0x8000, o, (Message) 18512, 0x37e);
    }
}

#endif


/*********************************************************************
 *			BasrunRpcInit
 *********************************************************************
 * SYNOPSIS:        Initialize the RPC system
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jon     22 mar 96       initial revision
 * 
 *********************************************************************/
#ifdef LIBERTY

RpcServer    servers[RPC_LAST_RUNTIME];

Boolean
BasrunRpcInit(Connection **connection)
{
    /*
     * Open the passed port at the agreed upon parameters
     */
    serialPortOpen[0] = FALSE;

    if (theSerialDriver.Open(TD_SERIAL_PORT, connection,
			   RPC_STREAM_BUFFER_SIZE,
			   RPC_STREAM_BUFFER_SIZE) == SERIAL_OK) {
	if (theSerialDriver.SetFormat(TD_SERIAL_PORT, RPC_BAUD | RPC_PARITY |
				          RPC_DATA_BITS | RPC_STOP_BITS |
				    RPC_MODE) == SERIAL_OK) {
	    word i;
	    for (i=0; i < RPC_LAST_RUNTIME; i++) {
		servers[i] = 0;
	    }
	    serialPortOpen[0] = TRUE;
	} else {
	    theSerialDriver.Close(*connection);
	}
    }

    return serialPortOpen[0];
}


Boolean
BasrunRpcExit(Connection *connection)
{
    if (serialPortOpen[0]) {
	theSerialDriver.Close(connection);
	serialPortOpen[0] = FALSE;
	return TRUE;
    } else {
	return FALSE;
    }
}

#else

Boolean
BasrunRpcInit(SerialUnit unit, RpcInitFlags flags, MemHandle *serverBlock,
	      word maxServers, optr writeNotifyGuy, optr readNotifyGuy)
{
    GeodeLoadError    gle;
    word              oldDS;
    StreamError       se;
    Boolean           success;

    oldDS = setDSToDgroup();

    /*
     * Load the serial driver so that we can open a port.
     */
    if (serialDriver == NullHandle) {
	FilePushDir ();
	FileSetStandardPath (SP_SYSTEM);
	serialDriver = GeodeUseDriver(driverName, 0, 0, &gle);
	FilePopDir();
    }

    if (serialDriver == NullHandle) {
	restoreDS(oldDS);
	return FALSE;
    }

    /*
     * Open the passed port at the agreed upon parameters
     */
    serialPortOpen[unit/2] = FALSE;
    se = SerialOpen(serialDriver, unit, STREAM_OPEN_NO_BLOCK,
		    RPC_STREAM_BUFFER_SIZE, RPC_STREAM_BUFFER_SIZE, 0);

    if (se == SERIAL_OK) {
	se = SerialSetFormat(serialDriver, unit, 
		 (RPC_DATA_BITS << SERIAL_FORMAT_LENGTH_OFFSET) |
		 (RPC_PARITY << SERIAL_FORMAT_PARITY_OFFSET) |
		 (RPC_STOP_BITS << SERIAL_FORMAT_EXTRA_STOP_OFFSET),
		 RPC_MODE,  RPC_BAUD);
	if (se == SERIAL_OK) {
	    serialPortOpen[unit/2] = TRUE;
	    writeWatch[unit/2] = writeNotifyGuy;
	    readWatch[unit/2] = readNotifyGuy;
	    if (flags & RIF_ALLOC_SERVER_BLOCK) {
		*serverBlock = MemAlloc(sizeof(void *) * maxServers, 0, HAF_ZERO_INIT);
	    }
	} else {
	    SerialClose(serialDriver, unit, STREAM_DISCARD);
	}
    }

    success = serialPortOpen[unit/2];
    restoreDS(oldDS);
    return success;
}

Boolean
BasrunRpcExit(SerialUnit unit)
{
    word	oldDS;
    Boolean     retval;

    oldDS = setDSToDgroup();

    if (serialPortOpen[unit/2]) {
	SerialClose(serialDriver, unit, STREAM_DISCARD);
	serialPortOpen[unit/2] = FALSE;
	retval = TRUE;
    } else {
	retval = FALSE;
    }

    restoreDS(oldDS);
    return retval;
}

#endif

#ifdef LIBERTY
Boolean
BasrunRpcServe(RpcProc rpcNum, RpcServer callback)
{
#if 0
    EC_ERROR_IF(servers[rpcNum] != 0, RE_FAILED_ASSERTION);
#endif
    servers[rpcNum] = callback;
    return TRUE;
}
#else
Boolean
BasrunRpcServe(MemHandle serverBlock, RpcProc rpcNum, RpcServer callback)
/*
	      PCB(RpcError, callback, (RpcHeader h, byte *callData)))
*/
{
    RpcServer    *servers;

    servers = (RpcServer *)MemLock(serverBlock);
    servers[rpcNum] = callback;
    MemUnlock(serverBlock);

    return TRUE;
}
#endif

#ifdef LIBERTY
Boolean
BasrunRpcSetNotify(Connection *connection, VoidFuncOneArg *func)
{
    if (serialPortOpen) {
	connection->SetReaderNotify(func, connection, 1);
	return TRUE;
    }
    return FALSE;
}
#else
Boolean
BasrunRpcSetNotify(SerialUnit unit, optr destObj, word destMsg)
{
    word	oldDS;
    Boolean     retval;
    oldDS = setDSToDgroup();

    if (serialPortOpen[unit/2]) {
	DoSerialNotifyStuff(serialDriver, unit, destObj, destMsg);
	retval = TRUE;
    } else {
	retval = FALSE;
    }

    restoreDS(oldDS);
    return retval;
}
#endif

#ifdef LIBERTY
RpcError
RpcSerialRead(Connection *connection, word timeout, word buffSize, void *buffer, word *n)
{
    if ((connection->Read((byte *)buffer, buffSize, n, TRUE, timeout, FALSE)) == STREAM_OK) {
	return RPC_SUCCESS;
    } else {
	return RPC_CANTSEND;
    }
}

RpcError
RpcSerialWrite(Connection *connection, word timeout, word buffSize, void *buffer, word *n)
{
    if ((connection->Write((byte *)buffer, buffSize, n, TRUE, timeout)) == STREAM_OK) {
	return RPC_SUCCESS;
    } else {
	return RPC_CANTSEND;
    }
}
#else

RpcError
RpcSerialRead(SerialUnit unit, word timeout, word buffSize, byte *buffer, word *n)
{
    char msg[1000];
    char temp[10];
    word i;
    StreamError retval;

    /*
     * Apparently, the GEOS serial driver API doesn't support timeouts, so
     * we'll hack our own in here by sleeping for the timeout, waiting for
     * the data to show.
     */
    if (timeout) {
	SerialQuery(serialDriver, unit, STREAM_ROLES_READER, &i);
	while ((i < buffSize) && (timeout >= 10)) {
	    TimerSleep(10);
	    SerialQuery(serialDriver, unit, STREAM_ROLES_READER, &i);
	    timeout -= 10;
	}
	if (i < buffSize) {
	    return RPC_TIMED_OUT;
	} else {
	    retval = SerialRead(serialDriver,unit,STREAM_NO_BLOCK,buffSize,buffer,n);
	}
    } else {
	retval = SerialRead(serialDriver,unit,STREAM_BLOCK,buffSize,buffer,n);
    }

#if 0
    if (readWatch[unit/2] != NullOptr) {
	msg[0] = 0;
	for(i = 0; i < *n; i++) {
	    itoa(buffer[i], temp);
	    strcat(msg, temp);
	    strcat(msg, ",");
	}
	strcat(msg, "STOP\r");
	Notify(readWatch[unit/2],msg);
    }
#endif
    return retval;

}

RpcError
RpcSerialWrite(SerialUnit unit, word timeout, word buffSize, byte *buffer, word *n)
{
    char msg[1000];
    char temp[10];
    word i;

    StreamError retval;

    /*
     * Apparently, the GEOS serial driver API doesn't support timeouts, so
     * we'll hack our own in here by sleeping for the timeout, waiting for
     * the data to show.
     */
    if (timeout) {
	SerialQuery(serialDriver, unit, STREAM_ROLES_WRITER, &i);
	while ((i < buffSize) && (timeout >= 10)) {
	    TimerSleep(10);
	    SerialQuery(serialDriver, unit, STREAM_ROLES_WRITER, &i);
	    timeout -= 10;
	}
	if (i < buffSize) {
	    return RPC_TIMED_OUT;
	} else {
	    retval = SerialWrite(serialDriver,unit,STREAM_NO_BLOCK,buffSize,buffer,n);
	}
    } else {
	retval = SerialWrite(serialDriver,unit,STREAM_BLOCK,buffSize,buffer,n);
    }

#if 0
    if (writeWatch[unit/2] != NullOptr) {
	msg[0] = 0;
	for(i = 0; i < *n; i++) {
	    itoa(buffer[i], temp);
	    strcat(msg, temp);
	    strcat(msg, ",");
	}
	strcat(msg, "STOP\r");
	Notify(writeWatch[unit/2],msg);
    }
#endif
    return retval;
}
#endif

RpcError
#ifdef LIBERTY
BasrunRpcCall(Connection *connection, word timeout, RpcProc rpcNum,
	      word inLength, void *inData,
	      word outLength, void *outData)
#else
BasrunRpcCall(SerialPortNum unit, word timeout, RpcProc rpcNum,
		      word inLength, void *inData,
		      word outLength, void *outData)
#endif
{
    RpcHeader   header, replyHeader;
    word        foo;
    RpcError    retval;

#ifdef LIBERTY
    word  unit = 0;
#endif

#ifndef LIBERTY
    word	oldDS = setDSToDgroup();
#endif

    if (serialPortOpen[unit/2]) {
	header.rh_flags = RPC_CALL;
	header.rh_procNum = rpcNum;
	header.rh_length = inLength;
	header.rh_id = ++msgId[unit/2];

	/*
	 * Send the header for the packet we're about to send
	 */
	retval = RpcSerialWrite(unitOrConnection, timeout,
				sizeof(RpcHeader),
				(byte*)&header, &foo);

	if (retval == STREAM_OK) {

	    /*
	     * If that went well, send the data, too.
	     */
	    if (inLength) {
		
		retval = RpcSerialWrite(unitOrConnection, timeout,
				   inLength, inData, &foo);
	    }

	    /*
	     * If that went well, wait for the reply.
	     */
	    if (retval == RPC_SUCCESS) {
		retval = RpcSerialRead
		    (unitOrConnection, timeout, sizeof(RpcHeader),
		     (byte*)&replyHeader, &foo);

		if (retval == RPC_SUCCESS) {
		    /*
		     * Read in the data for this thing
		     */

		    if (replyHeader.rh_length > outLength) {
			/*
			 * Burn the reply and fail if we can't handle the
			 * size of the return.
			 */
#ifdef LIBERTY
			connection->FlushReader();
#else
			SerialFlush(serialDriver, unit, STREAM_ROLES_READER);
#endif
			retval = RPC_TOOBIG;
		    } else {

			/*
			 * If we think we've been successful to this point,
			 * make sure that the reply is really a RPC_REPLY,
			 * and make sure the ID numbers match.
			 */
			if ((!(replyHeader.rh_flags & RPC_REPLY)) ||
			    (header.rh_id != replyHeader.rh_id)) {
			    retval = RPC_CANTSEND;
			} else if (replyHeader.rh_length != 0) {
			    retval = RpcSerialRead(unitOrConnection, timeout,
					      replyHeader.rh_length, outData, &foo);
			}
		    }
		}
	    }
	}
    } else {
	retval = RPC_NOTATTACHED;
    }

#ifndef LIBERTY
    restoreDS(oldDS);
#endif
    return retval;
}

#ifdef LIBERTY
RpcError
BasrunRpcHandleCall(Connection *connection, word timeout)
#else
RpcError
BasrunRpcHandleCall(SerialPortNum unit, word timeout, MemHandle serverBlock)
#endif
{
    RpcHeader   header;
    word        foo;
    RpcError    retval;
    byte        inData[512];

#ifdef LIBERTY
    word  unit = 0;
#endif

#ifndef LIBERTY
    RpcServer   *servers;
    word	oldDS = setDSToDgroup();
#endif

    if (serialPortOpen[unit/2]) {

	/*
	 * If the caller's passed a timeout, then it should be because
	 * they've been notified that data is on the line. If the data isn't
	 * there, then it's prob'ly an invalid notification, and we should
	 * time out immediately
	 */
	if (timeout) {
#ifdef LIBERTY
	    connection->BytesFilled(&foo);
#else
	    SerialQuery(serialDriver, unit, STREAM_ROLES_READER, &foo);
#endif
	} else {
	    foo = 1;
	}

	if (foo == 0) {
	    /*
	     * Bogus call, presumably.
	     */
	    retval = RPC_TIMED_OUT;

	} else {

	    /*
	     * Read the header of the thing we're supposed to reply to.
	     */

	    retval = RpcSerialRead
		(unitOrConnection, timeout, sizeof(RpcHeader),
		 (byte*)&header, &foo);

	    /*
	     * If that went well, read the data, too.
	     */
	
	    if (retval == RPC_SUCCESS) {

		if (header.rh_length) {
		    retval = RpcSerialRead(unitOrConnection, timeout,
					   header.rh_length, inData, &foo);
		}

		/*
		 * If that went well, process the command.
		 */
		if (retval == RPC_SUCCESS) {

#ifndef LIBERTY
		    servers = MemLock(serverBlock);
#endif

		    if (servers[header.rh_procNum] == 0) {
			/*
			 * Send an error back over the line.
			 */
			header.rh_flags = RPC_ERROR;
			RpcSerialWrite
			    (unitOrConnection, timeout, sizeof(RpcHeader),
			     (byte*)&header, &foo);
		    
			retval = RPC_NOPROC;
		    } else {
			/*
			 * Call our server, which will in turn call RpcReply
			 */
			header.rh_flags = RPC_REPLY;
		    
			/*
			 * Need to restore caller's ds, our they'll us ours
			 * errantly!
			 */
#ifdef LIBERTY
			retval = servers[header.rh_procNum](connection, header, inData);
#else
			restoreDS(oldDS);
			retval = ProcCallFixedOrMovable_pascal(header, inData, servers[header.rh_procNum]);
			oldDS = setDSToDgroup();
#endif
		    }

#ifndef LIBERTY
		    MemUnlock(serverBlock);
#endif
		}
	    }
	}
    } else {
	retval = RPC_NOTATTACHED;
    }

#ifndef LIBERTY
    restoreDS(oldDS);
#endif
    return retval;
}

RpcError
#ifdef LIBERTY
BasrunRpcReply(Connection *connection, word timeout, RpcHeader header, void *outData)
#else
BasrunRpcReply(SerialUnit unit, word timeout, RpcHeader header, void *outData)
#endif
{
    word        foo;
    RpcError    retval;

#ifdef LIBERTY
    word  unit = 0;
#endif

#ifndef LIBERTY
    word	oldDS = setDSToDgroup();
#endif

    if (serialPortOpen[unit/2]) {

	retval = RpcSerialWrite
	    (unitOrConnection, timeout, sizeof(RpcHeader),
	     (byte*)&header, &foo);
	if (retval == RPC_SUCCESS) {
	    /*
	     * If there's no data associated with this reply (should that
	     * be legal), then we've succeeded.
	     */
	    if (header.rh_length != 0) {
		retval = RpcSerialWrite(unitOrConnection, timeout,
					header.rh_length, outData, &foo);
	    }
	}
    } else {
	retval = RPC_NOTATTACHED;
    }

#ifndef LIBERTY
    restoreDS(oldDS);
#endif
    return retval;
}
