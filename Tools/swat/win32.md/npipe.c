/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  npipe.c
 *
 * AUTHOR:  	  Dan Baumann: Sep 10, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial version
 *
 * DESCRIPTION:
 *
 *	Functions for sending & receiving Named Pipe data
 *     
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: npipe.c,v 1.1 97/04/18 17:48:38 dbaumann Exp $";
#endif lint

#if defined(ISSWAT)
# include <config.h>
#endif

#include <compat/file.h>
#include <compat/windows.h>
# include "npipe.h"
#if defined(ISSWAT)
# if !defined(unix)
#  include "serial.h" /* contains iovec structure definition */
# endif
# include "swat.h"
#endif
#define NPIPE_MAX_INST       100               /* max instances for pipe. */
#define NPIPE_OUT_BUF_SIZE   4096            /* out buffer size */
#define NPIPE_IN_BUF_SIZE    4096            /* in buffer size */
#define NPIPE_CREATE_TIMEOUT 1000            /* default timeout in millisec */
#define NPIPE_MAX_MSG_SIZE   546             /* max length of msg for pipe */
#define NPIPE_DEFAULT_NAME   "\\\\.\\pipe\\swatpipe"  /* default pipe name */

void NPipeOutputLastError(char *where);


#if !defined(ISSWAT)    /* stub is the server */
/***********************************************************************
 *				NPipe_ServerInit
 ***********************************************************************
 *
 * SYNOPSIS:	    Initialize the Named Pipe Stuff for Server side (stub)
 * CALLED BY:	    (stub's wincom dll)
 * RETURN:	    TRUE - no errors, FALSE - problems encountered
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial Revision
 *
 ***********************************************************************/
int
NPipe_ServerInit(char *name, HANDLE *pipe, LPOVERLAPPED ovlpR, 
		 LPOVERLAPPED ovlpW)
{
    BOOL returnCode;
    char *pipeName;
    char defaultName[] = NPIPE_DEFAULT_NAME;

    if ((name == NULL) || (*name == '\0')) {
	pipeName = defaultName;
    } else {
	pipeName = name;
    }

    *pipe = CreateNamedPipe(pipeName,
			   PIPE_ACCESS_DUPLEX | WRITE_OWNER 
			     | FILE_FLAG_OVERLAPPED,
			   PIPE_TYPE_MESSAGE 
			     | PIPE_NOWAIT 
			     | PIPE_READMODE_MESSAGE,
			   NPIPE_MAX_INST,       /* max instances of pipe. */
			   NPIPE_OUT_BUF_SIZE,   /* out buffer size        */
			   NPIPE_IN_BUF_SIZE,    /* in buffer size         */
			   NPIPE_CREATE_TIMEOUT, /* timeout in mills 	   */
			   NULL);                /* security stuff         */

    if (*pipe == INVALID_HANDLE_VALUE) {
	NPipeOutputLastError("NPipe_ServerInit: "
				 "CreateNamedPipe:");
	*pipe = NULL;
	return FALSE;
    }

    ovlpR->Offset = ovlpR->OffsetHigh = 0;
    ovlpR->hEvent = CreateEvent(0, TRUE, TRUE, 0);
    ovlpW->Offset = ovlpW->OffsetHigh = 0;
    ovlpW->hEvent = CreateEvent(0, TRUE, TRUE, 0);

    return TRUE;

}	/* End of NPipe_ServerInit.	*/


/***********************************************************************
 *				NPipe_ServerConnect
 ***********************************************************************
 *
 * SYNOPSIS:	    Connect the server to the named pipe after client 
 *                  initializes the Named Pipe
 * CALLED BY:	    (stub's wincom dll), NPipe_ServerTestNConnect
 * RETURN:	    TRUE - no errors, FALSE - problems encountered
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/17/96   	Initial Revision
 *
 ***********************************************************************/
int
NPipe_ServerConnect(HANDLE pipe, int *madeConnection, LPOVERLAPPED ovlp)
{
    BOOL returnCode;
    
    returnCode = ConnectNamedPipe(pipe, NULL);

    if (returnCode != TRUE) {
	switch (GetLastError()) {
	case ERROR_PIPE_CONNECTED:
	    *madeConnection = TRUE;
	    break;
	case ERROR_PIPE_LISTENING:
	    *madeConnection = FALSE;
	    break;
	default:
	    NPipeOutputLastError("NPipe_ServerConnect: "
				     "ConnectNamedPipe:");
	    *madeConnection = FALSE;
	    return FALSE;
	    break;
	}
    } else {
	*madeConnection = TRUE;
    }

    return TRUE;

}	/* End of NPipe_ServerConnect.	*/

#else    /* else swat which is the client */
/***********************************************************************
 *				NPipe_ClientInit
 ***********************************************************************
 *
 * SYNOPSIS:	    Initialize the Named Pipe Stuff
 * CALLED BY:	    Rpc_Init
 * RETURN:	    TRUE - no errors, FALSE - problems encountered
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial Revision
 *
 ***********************************************************************/
int
NPipe_ClientInit(char *name, HANDLE *pipe, LPOVERLAPPED ovlpR, 
		 LPOVERLAPPED ovlpW)
{
    DWORD newPipeMode;
    BOOL returnCode;
    char * pipeName;
    char defaultName[] = NPIPE_DEFAULT_NAME;

    if ((name == NULL) || (*name == '\0')) {
	pipeName = defaultName;
    } else {
	pipeName = name;
    }

    *pipe = CreateFile(pipeName,                /* pipe name */
		       GENERIC_READ 	  	/* access */
		         | GENERIC_WRITE,
		       FILE_SHARE_READ 		/* sharing  */
		         | FILE_SHARE_WRITE,
		       NULL,            	/* no security */
		       OPEN_EXISTING, 		/* how to create */
		       FILE_FLAG_OVERLAPPED,	/* file attributes */
		       NULL);                   /* handle of attr */

    if (*pipe == INVALID_HANDLE_VALUE) {
	NPipeOutputLastError("NPipe_ClientInit: CreateFile:");
	*pipe = NULL;
	return FALSE;
    }

    newPipeMode = PIPE_READMODE_MESSAGE | PIPE_WAIT;
    
    returnCode = SetNamedPipeHandleState(*pipe, &newPipeMode, NULL, NULL);

    if (returnCode != TRUE) {
	NPipeOutputLastError("NPipe_ClientInit: "
				 "SetNamedPipeHandleState:");
	CloseHandle(*pipe);
	*pipe = NULL;
	return FALSE;
    }

    ovlpR->Offset = ovlpR->OffsetHigh = 0;
    ovlpR->hEvent = CreateEvent(0, TRUE, TRUE, 0);
    ovlpW->Offset = ovlpW->OffsetHigh = 0;
    ovlpW->hEvent = CreateEvent(0, TRUE, TRUE, 0);

    return TRUE;
}	/* End of NPipe_ClientInit.	*/
#endif    /* !defined(ISSWAT) */


/***********************************************************************
 *				NPipe_Read
 ***********************************************************************
 *
 * SYNOPSIS:	    Read the next chunk from the Named Pipe
 * CALLED BY:	    Rpc_HandleStream
 * RETURN:	    number of data bytes in the chunk (-1 means error)
 * SIDE EFFECTS:    if justPeeking then pointer isn't actually moved and
 *                  
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial Revision
 *
 ***********************************************************************/
int
NPipe_Read(HANDLE pipe, void *buf, int bufSize, LPOVERLAPPED ovlp, 
	   BOOL bBlock)
{
    DWORD bytesRead;
    BOOL returnCode;

    /* 
     * clear last error so that ERROR_IO_PENDING can only be
     * from the following ReadFile() call
     */ 

    if (bBlock == FALSE) {
	SetLastError(0);
    }

    returnCode = ReadFile(pipe, buf, bufSize, &bytesRead, ovlp);
   
    if (returnCode == FALSE) {
	switch (GetLastError()) {
	case ERROR_IO_PENDING:
	    if (bBlock == TRUE) {
		WaitForSingleObject(ovlp->hEvent, INFINITE);
		GetOverlappedResult(pipe, ovlp, &bytesRead, FALSE);
	    }
	    else
		bytesRead = 0;
	    break;
	case ERROR_MORE_DATA:
	    /* 
	     * the message is longer than the buf size ==> problem 
	     * rest of message is truncated in the style of netWare
	     * XXXdan-q - will we get the rest later?
	     */
#if 0
	    if (MessageFlush) {
		MessageFlush("NPipe_Read: ReadFile: couldn't"
			     " read all\r\n");
	    } else {
		fprintf(stderr, "NPipe_Read: ReadFile: couldn't"
			" read all\r\n");
	    }
#endif
	    return (-1);
	default:
	    NPipeOutputLastError("NPipe_Read: ReadFile:");
	    return (-1);
	}
    }

    return bytesRead;
}	/* End of NPipe_Read */


#if !defined(ISSWAT)   /* stub dll only writes buffers */
/***********************************************************************
 *				NPipe_Write
 ***********************************************************************
 * SYNOPSIS:	    Put a chunk out on the Named Pipe.
 * CALLED BY:	    (stub's wincom dll)
 * RETURN:	    number of bytes written (-1 means error)
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial Revision
 *
 ***********************************************************************/
int 
NPipe_Write(HANDLE pipe, void *buf, int bufSize, LPOVERLAPPED ovlp)
{
    BOOL returnCode;
    DWORD bytesWritten;

    returnCode = WriteFile(pipe,
			   buf,
			   bufSize,
			   &bytesWritten,
			   ovlp);

    if (returnCode == FALSE) {
	switch (GetLastError()) {
	case ERROR_IO_PENDING:
	    WaitForSingleObject(ovlp->hEvent, INFINITE);
	    GetOverlappedResult(pipe, ovlp, &bytesWritten, FALSE);
	    break;
	default:
	    NPipeOutputLastError("NPipe_Write: WriteFile:");
	    return (-1);
	    break;
	}
    }

    if (bytesWritten != bufSize) {
	return (-1);
    }

    return bytesWritten;
}	/* End of NPipe_Write */

#else /* must be swat then, which writes iov structures */

/***********************************************************************
 *				NPipe_WriteV
 ***********************************************************************
 * SYNOPSIS:	    Put a chunk out on the Named Pipe.
 * CALLED BY:	    Rpc_WriteV
 * RETURN:	    number of bytes written (-1 means error)
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial Revision
 *
 ***********************************************************************/
int
NPipe_WriteV(HANDLE pipe, struct iovec *iov, int iov_len, LPOVERLAPPED ovlp)
{
    char msgBuf[NPIPE_MAX_MSG_SIZE];
    char *pMsgBuf = msgBuf;
    int i, size;
    BOOL returnCode;
    DWORD bytesWritten;
    DWORD numWrite;

    for (i = 0, size = 0; i < iov_len; i++) {
	if (size + iov[i].iov_len > NPIPE_MAX_MSG_SIZE)
	{
	    return (-1);
	}
	
	bcopy(iov[i].iov_base, pMsgBuf, iov[i].iov_len);
	pMsgBuf += iov[i].iov_len;
	size += iov[i].iov_len;
    }

    returnCode = WriteFile(pipe,
			   msgBuf,
			   size,
			   &bytesWritten,
			   ovlp);

    if (returnCode == FALSE) {
	switch (GetLastError()) {
	case ERROR_IO_PENDING:
	    GetOverlappedResult(pipe, ovlp, &numWrite, TRUE);
	    bytesWritten = numWrite;
	    break;
	default:
	    NPipeOutputLastError("NPipe_WriteV: WriteFile:");
	    return (-1);
	    break;
	}
    }
    if (bytesWritten != size) {   
	if (win32dbg == TRUE) {
	    if (MessageFlush) {
		MessageFlush("NPipe_WriteV: WriteFile: couldn't"
			     " write all: %d of %d\r\n", bytesWritten, size);
	    } else {
		fprintf(stderr, "NPipe_WriteV: WriteFile: couldn't"
			" write all %d of %d\r\n", bytesWritten, size);
	    }
	}
	/* 
	 * XXXdan 
	 *   only reports a problem if no data is sent, otherwise I believe
	 *   the whole message is sent, it just isn't reporting back to us
	 *   the right amt.
	 */
	if (bytesWritten <= 0) {
	    return (-1);
	}
    }

    return size;
}	/* End of NPipe_WriteV */
#endif  /* !defined(ISSWAT) */


/***********************************************************************
 *				NPipe_Check
 ***********************************************************************
 * SYNOPSIS:	    Checks if data is waiting on Named Pipe
 * CALLED BY:	    Rpc_Wait
 * RETURN:	    number of bytes waiting (-1 means error)
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial Revision
 *
 ***********************************************************************/
int
NPipe_Check(HANDLE pipe, LPOVERLAPPED ovlp)
{
    DWORD bytesRead;
    BOOL returnCode;
    DWORD dataLeftInMessage;
    DWORD dataAvail = 0;

    /* determine data in the next message, note - not all messages */
    returnCode = PeekNamedPipe(pipe,
			       NULL,
			       0,
			       &bytesRead,
			       &dataAvail,
			       &dataLeftInMessage);

    if (returnCode != TRUE) {
	if (GetLastError() != ERROR_MORE_DATA) {
	    /*
	     * don't display if handle is invalid, could just be detached
	     */	     
	    if (GetLastError() != ERROR_INVALID_HANDLE) {
		NPipeOutputLastError("NPipe_Check: PeekNamedPipe:");
	    }
	    return (-1);
	}
    }
    
    return dataAvail;
}	/* End of NPipe_Check */



#if !defined(ISSWAT)
/***********************************************************************
 *				NPipe_ServerExit
 ***********************************************************************
 * SYNOPSIS:	    Close the server's Named Pipe.
 * CALLED BY:	    ??
 * RETURN:	    none
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial Revision
 *
 ***********************************************************************/
void
NPipe_ServerExit(HANDLE *pipe, LPOVERLAPPED ovlpR, LPOVERLAPPED ovlpW)
{
    BOOL returnCode;
    
    returnCode = DisconnectNamedPipe(*pipe);
    
    if (returnCode != TRUE) {
	NPipeOutputLastError("NPipe_ServerExit: DisconnectNamedPipe:");
	return;
    }

    returnCode = CloseHandle(*pipe);
    
    if (returnCode != TRUE) {
	/* 
	 * don't do anything special yet, since stub probably doesn't care 
	 */
	NPipeOutputLastError("NPipe_ServerExit: CloseHandle:");
	return;
    }

    *pipe = NULL;

    CloseHandle(ovlpR->hEvent);
    CloseHandle(ovlpW->hEvent);

    return;
}	/* End of NPipe_ServerExit */


#else   /* else case: swat is the client */
/***********************************************************************
 *				NPipe_ClientExit
 ***********************************************************************
 * SYNOPSIS:	    Close the client's Named Pipe.
 * CALLED BY:	    (EXTERNAL - set up using atexit function)
 * RETURN:	    none
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/10/96   	Initial Revision
 *
 ***********************************************************************/
void
NPipe_ClientExit(HANDLE *pipe, LPOVERLAPPED ovlpR, LPOVERLAPPED ovlpW)
{
    BOOL returnCode;

    returnCode = CloseHandle(*pipe);
    
    if (returnCode != TRUE) {
	NPipeOutputLastError("NPipe_ClientExit: CloseHandle:");
	return;
    }
    
    *pipe = NULL;

    CloseHandle(ovlpR->hEvent);
    CloseHandle(ovlpW->hEvent);

    return;
}	/* End of NPipe_ClientExit */
#endif    /* !defined(ISSWAT) */



/***********************************************************************
 *				NPipeOutputLastError
 ***********************************************************************
 *
 * SYNOPSIS:	    Displays error from GetLastError()
 * CALLED BY:	    (all INTERNAL functions)
 * RETURN:	    none
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/11/96   	Initial Revision
 *
 ***********************************************************************/
void NPipeOutputLastError(char *where)
{
    LPVOID lpMsgBuf;
    char denied[] = "<couldn't get last error>";
    BOOL returnCode = FALSE;

#if defined(ISSWAT)
    return;
#endif

    returnCode = FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM
			       | FORMAT_MESSAGE_ALLOCATE_BUFFER,
			       NULL,
			       GetLastError(),
			       MAKELANGID(LANG_NEUTRAL,SUBLANG_DEFAULT),
			       (LPTSTR) &lpMsgBuf,
			       0,
			       NULL);
    
    if (returnCode == FALSE) {
	lpMsgBuf = denied;
    }

#if !defined(ISSWAT)   /* must be stub */
    /* 
     * stub can't printf or anything, so make a message box
     */
    {
	MessageBox(NULL, lpMsgBuf, where, MB_OK);
    }
#else  
    /* 
     * gotta be swat 
     */
# if 0	
     if (MessageFlush) {
    	MessageFlush("%s %s", where, lpMsgBuf);
     } else {
    	fprintf(stderr, "\r\n%s %s\r\n", where, lpMsgBuf);
        }
# endif
#endif

    return;
}	/* End of NPipeOutputLastError.	*/


    
