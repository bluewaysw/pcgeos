/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basco Debugger
FILE:		rpc.h

AUTHOR:		Jon Witort, March 22, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon     22 mar 96       Initial version.

DESCRIPTION:
	
        Header for calls Legos RPC module

	$Revision: 1.1 $

	Liberty version control
	$Id: rpc.h,v 1.1 1999/02/18 22:49:01 (c)turon Exp martin $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _LEGOSRPC_H_
#define _LEGOSRPC_H_

#ifdef LIBERTY

#include <Legos/interp.h>       // for basic types
#include <Legos/basrun.h>       // for basic types
#include <driver/serial.h>

typedef SerialPort SerialUnit;
typedef SerialPort SerialPortNum;
typedef StreamResultCode StreamError;
#define STREAM_NOBLOCK FALSE
#define STREAM_BLOCK TRUE

#define SERIAL_OK SERIAL_RETURN_OK
#define STREAM_OK STREAM_RETURN_OK

#if ARCH_BIG_ENDIAN
#define ByteSwap(x) (((x >> 8) & 0x00ff) | ((x << 8) & 0xff00))
/*
#define ByteSwapDword(x) (((x >> 8) & 0x00ff00ff) | ((x << 8) & 0xff00ff00))
*/
#define ByteSwapDword(x)			\
   (((x >> 24) & 0x000000ff) |			\
    ((x >> 8)  & 0x0000ff00) |			\
    ((x << 8)  & 0x00ff0000) |			\
    ((x << 24) & 0xff000000))
#else
#define ByteSwap(x) x
#define ByteSwapDword(x) x
#endif

#else

#include <file.h>
#include <serialDr.h>

#define SERIAL_OK STREAM_NO_ERROR
#define STREAM_OK STREAM_NO_ERROR

#endif

#include <Legos/bug.h>

#ifdef LIBERTY
#define RPC_DATA_BITS    DATA_LENGTH_8
#define RPC_STOP_BITS    STOP_LENGTH_1
#define RPC_PARITY       NO_PARITY
#define RPC_MODE         NO_CONTROL
#define RPC_BAUD         BAUD_RATE_9600

#define RPC_DEFAULT_TIMEOUT       10000   /* 10 seconds is the default, for no
					   * good reason.
					   */
#else
#define RPC_DATA_BITS    SERIAL_LENGTH_8
#define RPC_STOP_BITS    SERIAL_XSTOP_ONE
#define RPC_PARITY       SERIAL_PARITY_NONE
#define RPC_MODE         SM_RAW
#define RPC_BAUD         SB_9600

#define RPC_DEFAULT_TIMEOUT       600   /* 10 seconds is the default, for no
					 * good reason.
					 */
#endif

#define RPC_STREAM_BUFFER_SIZE    512

typedef unsigned short 	RpcError;
#define RPC_SUCCESS	0	    	/* Call succeeded, here's reply data */
#define RPC_CANTSEND	1	    	/* Couldn't send message, for some
					 * reason */
#define RPC_TIMED_OUT	2  	    	/* Message timed out */
#define RPC_TOOBIG	3  	    	/* Results (or message) too big */
#define RPC_NOPROC	4	  	/* No such procedure on remote
					 * machine */
#define RPC_ACCESS	5	  	/* Permission denied */
#define RPC_BADARGS	6  	    	/* Arguments were improper */
#define RPC_SYSTEMERR	7	    	/* Undefined system error */
#define RPC_SWAPPED 	8   	    	/* Data are swapped and can't be
					 * brought in */
#define RPC_NOHANDLE	9   	    	/* No such handle */
#define RPC_NOTATTACHED	10  	    	/* Not attached to PC */
#define RPC_BAD_PROTO	11  	    	/* Not attached to PC */

/*
 * Each RPC call and reply consists of a header and data.
 *
 * The header contains bookkeeping info along with the number of bytes of data
 * that follow. The data are padded to a word boundary to make access of
 * parameters as efficient as possible. 
 *
 * All data are sent in the PC's byte-order (little endian)
 */
#define RPC_CALL  0xca    	    	/* Message is a call */
#define RPC_REPLY 0x6e    	    	/* Message is a reply */
#define RPC_ERROR 0xe6    	    	/* Message is an error reply. reply data is
				 * status code */
#define RPC_ACK	  0xac    	    	/* Message is an explicit acknowledge */

typedef struct {
    unsigned char rh_flags;	    /* Flags for the message */
    unsigned char rh_procNum;	    /* Procedure called */
    unsigned char rh_length;	    /* Number of bytes of parameters */
    unsigned char rh_id;  	    /* Sequence number */
} RpcHeader;

typedef unsigned short 	RpcProc;
#define RPC_INIT_BASE 0

#define RPC_BEEP      (RPC_INIT_BASE)

typedef struct {
    unsigned char ba_arg1[20];    /* blah */
} RpcBeepArgs;

typedef struct {
    unsigned char br_reply1[20];    /* blah */
} RpcBeepReply;

#define RPC_HELLO     (RPC_INIT_BASE+1)
typedef struct {
    unsigned char ha_arg1;    /* blah */
} RpcHelloArgs;

typedef struct {
    unsigned char hr_reply1;    /* blah */
} RpcHelloReply;

#define RPC_GOODBYE   (RPC_INIT_BASE+2)
typedef struct {
    unsigned char ga_arg1;    /* blah */
} RpcGoodbyeArgs;

typedef struct {
    unsigned char gr_reply1;    /* blah */
} RpcGoodbyeReply;

#define RPC_EXIT      (RPC_INIT_BASE+3)
typedef struct {
    unsigned char ea_arg1;    /* blah */
} RpcExitArgs;

typedef struct {
    unsigned char er_reply1;    /* blah */
} RpcExitReply;

#define RPC_LOAD_MODULE      (RPC_INIT_BASE+4)

#define RPC_UPCASE      (RPC_INIT_BASE+5)

typedef struct {
    unsigned char ua_arg1[20];    /* blah */
} RpcUpcaseArgs;

typedef struct {
    unsigned char ur_reply1[20];    /* blah */
} RpcUpcaseReply;

#define RPC_SET_BREAK_AT_OFFSET      (RPC_INIT_BASE+6)
typedef struct {
    word             RSBA_offset;
    word             RSBA_funcNum;
    word             RSBA_lineNum;
    BugBreakFlags    RSBA_flags;
} RpcSetBreakArgs;

#define RPC_CLEAR_BREAK_AT_OFFSET      (RPC_INIT_BASE+7)
typedef struct {
    word             RCBA_offset;
    word             RCBA_funcNum;
} RpcClearBreakArgs;


#define RPC_SEND_FILE                 (RPC_INIT_BASE+8)
#define RPC_SEND_FILE_NEXT_BLOCK      (RPC_INIT_BASE+9)
#define RPC_STOP_SITTING_AND_SPINNING      (RPC_INIT_BASE+10)

/* this completes the rest of RPC_LOAD_MODULE - which has been broken
 * into two pieces so breakpoint can be set betweem loading a module and
 * running module_init
 */
#define RPC_RUN_TOP_LEVEL	(RPC_INIT_BASE+11)


/*
 * RPC_CNT
 */
#define RPC_CNT_BASE  16

#define RPC_GET_BUILDER_REQUEST	(RPC_CNT_BASE)
/* PASS:   nothing
 * RETURN: BugBuilderRequest
 */

#define RPC_SET_BUILDER_REQUEST	(RPC_CNT_BASE+1)
/* PASS:   BugBuilderRequest
 * RETURN: nothing
 */

#define RPC_GET_CURRENT_FRAME	(RPC_CNT_BASE+2)
#define RPC_GET_FRAME_INFO	(RPC_CNT_BASE+3)
/* Pass		word (frame)
 * Return	dword (Boolean | funcIndex)
 */

#define RPC_GET_FRAME_LINE_NUM	(RPC_CNT_BASE+4)
#define RPC_GET_FRAME_NAME	(RPC_CNT_BASE+5)

#define RPC_GET_VAR		(RPC_CNT_BASE+6)
typedef struct {
    word    rgva_frame;
    word    rgva_varIndex;
} RpcGetVarArgs;

#define RPC_SET_VAR		(RPC_CNT_BASE+7)
typedef struct {
    word    rsva_frame;
    word    rsva_varIndex;
    BugVar  rsva_bugVar;
} RpcSetVarArgs;

#define RPC_GET_STRING		(RPC_CNT_BASE+8)
#define RPC_CREATE_STRING	(RPC_CNT_BASE+9)
#define RPC_GET_NUM_VARS	(RPC_CNT_BASE+10)
#define RPC_LAST_RUNTIME	RPC_GET_NUM_VARS+1

/*
 * Runtime->debugger
 */

#define RPC_RUNTIME_TO_DEBUGGER    0

#define RPC_START		(RPC_RUNTIME_TO_DEBUGGER)
#define RPC_DONE		(RPC_RUNTIME_TO_DEBUGGER+1)
#define RPC_OFFSET_TO_LINE_NUM	(RPC_RUNTIME_TO_DEBUGGER+2)
typedef struct {
    word    ro2lna_funcNumber;
    word    ro2lna_offset;
} RpcOffset2LineNumArgs;

typedef struct {
    word    ro2lnr_lineNum;
    byte    ro2lnr_start;
} RpcOffset2LineNumReply;

#define RPC_ABOUT_TO_BREAK	(RPC_RUNTIME_TO_DEBUGGER+3)
#define RPC_LAST_DEBUGGER	RPC_ABOUT_TO_BREAK



typedef byte RpcInitFlags;
#define RIF_ALLOC_SERVER_BLOCK 0x01

#ifdef LIBERTY
Boolean BasrunRpcInit(Connection **connection);
Boolean BasrunRpcSetNotify(Connection *connection, VoidFuncOneArg *func);
Boolean BasrunRpcExit(Connection *connection);
#else
Boolean BasrunRpcInit(SerialPortNum port, RpcInitFlags flags, MemHandle *servers, word maxServers, optr writeWatch, optr readWatch);
Boolean BasrunRpcSetNotify(SerialPortNum unit, optr destObj, word destMsg);
Boolean BasrunRpcExit(SerialPortNum port);
#endif

#ifdef LIBERTY
RpcError BasrunRpcCall(Connection *connection, word timeout, RpcProc rpcNum,
		       word inLength, void *inData,
		       word outLength, void *outData);

RpcError BasrunRpcHandleCall(Connection *connection, word timeout);
RpcError BasrunRpcReply(Connection *connection, word timeout, RpcHeader header, void *outData);
#else
RpcError BasrunRpcCall(SerialPortNum unit, word timeout, RpcProc rpcNum,
		      word inLength, void *inData,
		      word outLength, void *outData);

RpcError BasrunRpcHandleCall(SerialPortNum unit, word timeout, MemHandle serverBlock);
RpcError BasrunRpcReply(SerialPortNum unit, word timeout, RpcHeader header, void *outData);
#endif

#ifdef LIBERTY
typedef RpcError (*RpcServer)(Connection *connection, RpcHeader h, byte *callData);
Boolean BasrunRpcServe(RpcProc rpcNum, RpcServer callback);
#else
#ifdef __BORLANDC__
typedef RpcError (_pascal *RpcServer)(RpcHeader h, byte *callData);
#else /* __HIGHC__ */
typedef RpcError (*RpcServer)(RpcHeader h, byte *callData);
#endif
Boolean BasrunRpcServe(MemHandle serverBlock, RpcProc rpcNum, RpcServer callback);
#endif

#endif /* _LEGOSRPC_H_ */
