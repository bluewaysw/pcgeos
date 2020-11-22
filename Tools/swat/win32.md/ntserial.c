 /***********************************************************************
 *
 *     Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:        PC GEOS
 * MODULE:
 * FILE:	   ntserial.c
 *
 * AUTHOR:		Daniel Baumann, Jul 17, 1996
 *
 * ROUTINES:
 *	Name                    Description
 *     ----                    -----------
 *	Ntserial_Init           Initialize serial communication.
 *	Ntserial_Check          See if any data has come in
 *	Ntserial_Read           Read some bytes from the input ring buffer
 *	Ntserial_WriteV         Write data to the serial port given a scatter
 *				gather vector.
 *
 *    --- the IPX stuff hasn't been implemented yet ---
 *	Ipx_Check               see if IPX is loaded
 *	Ipx_Init                initialize Ipx stuff
 *	Ipx_Exit                clean up
 *	Ipx_CopyToSendBuffer    routine to copy data down to a real-mode
 *				buffer to be sent off to IPX
 *	Ipx_SendLow             send a packet to IPX
 *	Ipx_CheckPacket         see if a pakcet has been received
 *	Ipx_ReadLow             read data from a packet received
 *    --- the IPX stuff hasn't been implemented yet ---
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	7/17/96   	Initial version.
 *
 * DESCRIPTION:
 *	This is the WIN32 implementation of the serial port
 *     manipulation required by Swat.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: ntserial.c,v 1.1 97/04/18 17:42:24 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "serial.h"

#undef FIXED
#define LONG LONG_bogus
#define SID SID_bogus
#define timeval timeval_bogus
#define timercmp timercmp_bogus
#include <compat/windows.h>       /* for communications stuff */
#include <winsock2.h>
#undef timercmp
#undef timeval
#undef SID
#undef LONG
#define FIXED 0x80

#if defined(_WIN32) 

#define DEFAULT_SOCKET	    0x3f

#define IPX_MAX_PACKET	    546

typedef struct {
    WORD 	csum;	    /* 0xffff */
    WORD 	len;	    /* big-endian */
    BYTE  	xport;	    /* 0 */
    BYTE  	ptype;
#define PT_UNKNOWN  	0
#define PT_ROUTE    	1
#define PT_ECHO		2
#define PT_ERROR    	3
#define PT_DATA		4
#define PT_SPX		5 
#define PT_NCP		17
    BYTE  	dstNet[4];
    BYTE  	dstNode[6];
    WORD  	dstSocket;  /* big-endian */
    BYTE	srcNet[4];
    BYTE  	srcNode[6];
    WORD 	srcSocket;  /* big-endian */
} IPXHeader;

static struct sockaddr	ctrlPacket;

typedef struct {
    IPXHeader	    ihdr;
    BYTE   data[IPX_MAX_PACKET];
} IPXMaxPacket;

IPXMaxPacket 	ipxOutPacket;

void
parsehex(char *str, u_char *buf, unsigned ndigits, unsigned len);

#endif

#define IPX_VIA_UDP


void NtserialOutputLastError(char *where);

#include <stdio.h>
#include <winutil.h>

/***********************************************************************
 *		                    Ntserial_Init
 ***********************************************************************
 * SYNOPSIS:        Initialize the appropriate communications port
 * CALLED BY:	    Rpc_Init
 * RETURN:	    non-zero if initialization successful.
 * SIDE EFFECTS:    The open file is closed and all SrcLine structures
 *	    	    for it freed.
 *
 * PASS:            handle to communictions
 *		    const char *portDesc = "p#,b#[,i#]"
 *			p#      = port number (1-4)
 *			b#      = baud rate
 *			i#      = interrupt level
 *
 * RETURN:          non-zero if initialization successful.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	DB	7/17/96   	Initial version.
 *
 ***********************************************************************/
int
Ntserial_Init(HANDLE *comHandle, const char *portDesc, LPOVERLAPPED ovlpR,
	      LPOVERLAPPED ovlpW)
{
    BOOL success;
    DCB dcb;
    COMMTIMEOUTS timeouts;
    int portnum, baudrate, irlevel;
    char comportstr[5] = "";
    const char *pdesc = portDesc;

    portnum = 0;
    while ((*pdesc != '\0') && (*pdesc != ',')) {
	portnum = portnum * 10 + (*pdesc - '0');
	pdesc++;
    }

    if (*pdesc == '\0') {
#if 0
	MessageFlush("Ntserial_Init: No baud rate specified "
		     "for Serial port\r\n");
#endif
	return FALSE;
    }

    pdesc++;
    baudrate = 0;
    while (*pdesc != '\0' && *pdesc != ',') {
	baudrate = baudrate * 10 + (*pdesc - '0');
	pdesc++;
    }

    irlevel = 0;
    if (*pdesc == ',') {
	pdesc++;
	while (*pdesc != '\0') {
	    irlevel = irlevel * 10 + (*pdesc - '0');
	    pdesc++;
	}
    }

    sprintf(comportstr, "COM%d", portnum);

    /* Open the comm port.  Can open COM, LPT */
    *comHandle = CreateFile(comportstr,
			    GENERIC_READ | GENERIC_WRITE,
			    0,
			    0,
			    OPEN_EXISTING,
			    FILE_FLAG_OVERLAPPED,
			    0);
    if (*comHandle == INVALID_HANDLE_VALUE) {
	NtserialOutputLastError("Ntserial_Init: CreateFile:");
	return FALSE;
    }

    /* Get the current settings of the COMM port */

    success = GetCommState(*comHandle, &dcb);
    if (!success) {
	NtserialOutputLastError("Ntserial_Init: GetCommState:");
	return FALSE;
    }

    /* Modify the baud rate, etc.
     */
    dcb.BaudRate = baudrate;
    dcb.ByteSize = 8;
    dcb.Parity = NOPARITY;
    dcb.StopBits = ONESTOPBIT;

    /* Apply the new comm port settings
     */
    success = SetCommState(*comHandle, &dcb);
    if (!success) {
	NtserialOutputLastError("Ntserial_Init: SetCommState:");
	return FALSE;
    }

    /* XXXdan-q use the irlevel below somehow - if I understood it */
    timeouts.ReadIntervalTimeout = 0;
    timeouts.ReadTotalTimeoutMultiplier = 0;
    timeouts.ReadTotalTimeoutConstant = 0;
    timeouts.WriteTotalTimeoutMultiplier = 0;
    timeouts.WriteTotalTimeoutConstant = 0;
    success = SetCommTimeouts(*comHandle, &timeouts);
    if (!success) {
	return FALSE;
    }

    /* Set the Data Terminal Ready line
     */
    success = EscapeCommFunction(*comHandle, SETDTR);
    if (!success) {
	NtserialOutputLastError("Ntserial_Init: EscapeCommFunction:");
	return FALSE;
    }

    ovlpR->Offset = ovlpR->OffsetHigh = 0;
    ovlpR->hEvent = CreateEvent(0, TRUE, TRUE, 0);
    ovlpW->Offset = ovlpW->OffsetHigh = 0;
    ovlpW->hEvent = CreateEvent(0, TRUE, TRUE, 0);

    return TRUE;
}   /*    end of Ntserial_Init.    */


/***********************************************************************
 *				Ntserial_Read
 ***********************************************************************
 * SYNOPSIS:         read data from serial line
 * CALLED BY:	     RpcHandleStream, RpcSendFile, Rpc_ReadFromGeode,
 *                   RpcFindGeode
 * RETURN:	     length of data read (-1 if error) (0 if no data avail)
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *		7/23/96   	Initial Revision
 *
 ***********************************************************************/
int
Ntserial_Read(HANDLE comHandle, void *buffer, int bufSize, LPOVERLAPPED ovlp,
	      BOOL bBlock)
{
    DWORD bytesRead = 0;
    BOOL success;
    DWORD errors = 0;
    COMSTAT comStats;
    DWORD numRead;

    success = ReadFile(comHandle, buffer, bufSize, &bytesRead, ovlp);
    if (success == FALSE) {
	switch (GetLastError()) {
	case ERROR_IO_PENDING:
	    if (bBlock == TRUE) {
		WaitForSingleObject(ovlp->hEvent, INFINITE);
		GetOverlappedResult(comHandle, ovlp, &bytesRead, FALSE);
	    }
	    else
		bytesRead = 0;
	    break;
	case ERROR_MORE_DATA:
	    /*
	     * the message is longer than the buf size
	     */
	    break;
	default:
	    NtserialOutputLastError("Ntserial_Read: ReadFile:");
	    success = ClearCommError(comHandle, &errors, &comStats);
	    if (!success) {
		NtserialOutputLastError("Ntserial_Read: ClearCommError:");
	    } else if (errors) {
#if 0
		MessageFlush("Ntserial_Read: ClearCommError: error=%d\r\n",
			     errors);
#endif
	    }
	    return (-1);
	}
    }

    return bytesRead;
}	/* End of Ntserial_Read.	*/


/***********************************************************************
 *				Ntserial_WriteV
 ***********************************************************************
 * SYNOPSIS:       send all the data requested to the modem
 * CALLED BY:      RpcSendV, RpcResend
 * PASS:           struct iovec *iov   - vector of buffers to write
 *                 int len             - elements in the vector
 * RETURN:	   bytes written, -1 if bytes couldn't be sent
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *		7/23/96   	Initial Revision
 *
 ***********************************************************************/
int
Ntserial_WriteV(HANDLE comHandle, struct iovec *iov, int iov_len,
		LPOVERLAPPED ovlp)
{
    int iovIndex;
    DWORD iovLength, bytesWritten, iovBytesWritten, totalBytesWritten = 0;
    DWORD errors = 0;
    COMSTAT comStats;
    BOOL success;
    DWORD numWrite;
    int tries = 0;   /* number of times to allow errors before giving up */

    for (iovIndex = 0; iovIndex < iov_len; iovIndex++) {
	iovBytesWritten = 0;
	iovLength = iov[iovIndex].iov_len;
	while (iovBytesWritten < iovLength) {
	    success = WriteFile(comHandle,
				iov[iovIndex].iov_base + iovBytesWritten,
				iovLength - iovBytesWritten,
				&bytesWritten,
				ovlp);
	    if (success == FALSE) {
		switch (GetLastError()) {
		case ERROR_IO_PENDING:
		    WaitForSingleObject(ovlp->hEvent, INFINITE);
		    GetOverlappedResult(comHandle, ovlp, &numWrite, FALSE);
		    bytesWritten = numWrite;
		    break;
		default:
		    NtserialOutputLastError("Ntserial_WriteV: WriteFile:");
		    tries += 1;
		    if (tries > 10) {
			return -1;
		    }
		    success = ClearCommError(comHandle, &errors, &comStats);
		    if (success == FALSE) {
			NtserialOutputLastError("Ntserial_WriteV: "
						"ClearCommError:");
			return -1;
		    } else if (errors) {
			NtserialOutputLastError("Ntserial_WriteV: "
						"ClearCommError:");
			return -1;
		    }
		    break;
		}
	    }
	    iovBytesWritten += bytesWritten;
	    totalBytesWritten += bytesWritten;
	}
    }

    return totalBytesWritten;
}	/* End of Ntserial_WriteV.	*/


/***********************************************************************
 *				Ntserial_Check
 ***********************************************************************
 * SYNOPSIS:        see if any characters are available from the
 *                       serial port
 * CALLED BY:	    RpcWait
 * RETURN:	    number of characters available
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *		7/23/96   	Initial Revision
 *
 ***********************************************************************/
int
Ntserial_Check(HANDLE comHandle, LPOVERLAPPED ovlp)
{
    BOOL  success;
    DWORD errors = 0;
    COMSTAT comStats;

    success = ClearCommError(comHandle, &errors, &comStats);
    if (!success) {
	NtserialOutputLastError("Ntserial_Check: ClearCommError:");
	return 0;
    } else if (errors) {
	NtserialOutputLastError("Ntserial_Check: ClearCommError:");
	return 0;
    } else {
	return (int) comStats.cbInQue;
    }
}	/* End of Ntserial_Check.	*/


/***********************************************************************
 *		                    Ntserial_Exit
 ***********************************************************************
 * SYNOPSIS:        Close the appropriate communications port
 * CALLED BY:	    EXTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	DB	7/17/96   	Initial version.
 *
 ***********************************************************************/
void
Ntserial_Exit(HANDLE *comHandle, LPOVERLAPPED ovlpR, LPOVERLAPPED ovlpW)
{
    BOOL success = FALSE;

    /* Clear the DTR line */
    success = EscapeCommFunction(*comHandle, CLRDTR);
    if (!success) {
	NtserialOutputLastError("Ntserial_Exit: EscapeCommFunction: %d\r\n");
    }

    success = CloseHandle(*comHandle);
    if (!success) {
	NtserialOutputLastError("Ntserial_Exit: CloseHandle:");
    }

    CloseHandle(ovlpR->hEvent);
    CloseHandle(ovlpW->hEvent);

    return;
}	/* End of Ntserial_Exit.	*/

#if defined(_WIN32)
int cmdLineSocket = -1;
static BOOL winsockInitialized = FALSE;
static WSADATA wsaData;
#endif

/* empty Ipx funtion definitions.  Makes the Borland linker happy for now.
 * Novell will not be supported initially
 */
int Ipx_Check(void) {
    return 1;
}

void Ipx_Init(char *addr) {

#ifdef IPX_VIA_UDP
	char    	    *cp;    /* Random character pointer for parsing the
    				     * address of the PC */
        char    	    *node;  /* Start of the node address. Ends at
    				     * sock-1 or with null char */
        char    	    *sock;  /* Start of the socket number. Ends with
    				     * null char */
#endif
	struct sockaddr_in connectAddress;

	if(!winsockInitialized) {
		int iResult;
		
		// Initialize Winsock
		iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
		if (iResult != 0) {
		    printf("WSAStartup failed: %d\n", iResult);
		    return;
		}
		winsockInitialized = TRUE;
	}
#ifdef IPX_VIA_UDP
	/* open the socket here */
	if(cmdLineSocket != INVALID_SOCKET ) {
		Message("Error: command line socket already open");
	}
	
	/*
         * Break up the address string into its component parts.
         */
        cp = strchr(addr, ':');
        if (cp == NULL) {
    		Message("Missing node address in PC net address\n");
    		return;
        }
        node = cp+1;
        cp = strchr(node, ':');
        if (cp == NULL) {
    		sock = NULL;
        } else {
    		sock = cp+1;
        }	
        //ether_copy(&ifr.ifr_ifru.ifru_addr.sa_data, &ipxOutPacket.ihdr.srcNode);
	*((DWORD*)ipxOutPacket.ihdr.srcNode) = inet_addr("127.0.0.1");
	*((WORD*)&ipxOutPacket.ihdr.srcNode[4]) = 1234;
        /*
         * Always comes from the default socket #
         */
        ipxOutPacket.ihdr.srcSocket = htons(DEFAULT_SOCKET);
    
        /*
         * Figure out the destination socket #
         */
        if (sock == NULL) {
    		ipxOutPacket.ihdr.dstSocket = htons(DEFAULT_SOCKET);
        } else {
    		parsehex(sock, (u_char *)&ipxOutPacket.ihdr.dstSocket, 4, 0);
        }
    
        /*
         * Parse out the network number (same for both src and dest; we
         * assume the PC on which you're debugging is on the same net
         * as the workstation...)
         */
        parsehex(addr, (u_char *)&ipxOutPacket.ihdr.srcNet, 8, node-1-addr);
        parsehex(addr, (u_char *)&ipxOutPacket.ihdr.dstNet, 8, node-1-addr);
    
        /*
         * Parse out the destination node address. This goes in both the
         * IPX and the ethernet header.
         */
        parsehex(node, (u_char *)&ipxOutPacket.ihdr.dstNode, 12,
    	     sock ? sock-1-node : 0);
        /*ether_copy(&ipxOutPacket.ihdr.dstNode, &ehdr->ether_dhost);*/
    
        /*
         * Set up the parts of the IPX packet that never change.
         */
        ipxOutPacket.ihdr.csum = 0xffff;
        ipxOutPacket.ihdr.xport = 0;
        ipxOutPacket.ihdr.ptype = PT_DATA;
	
	cmdLineSocket = socket(AF_INET, SOCK_DGRAM, 0);    

	/* try connectiokn now */
        if(cmdLineSocket != INVALID_SOCKET ) {
	
		int rc;
		const char y = 1;
		struct sockaddr_in servAddr;	
		
		// start receiving on port
		Message("Start receiving on UDP port");
		
		/* Lokalen Server Port bind(en) */
	        servAddr.sin_family = AF_INET;
	        servAddr.sin_addr.s_addr = htonl (INADDR_ANY);
	        servAddr.sin_port = htons (1234);
	        setsockopt(cmdLineSocket, SOL_SOCKET, SO_REUSEADDR, &y, sizeof(int));
	        rc = bind ( cmdLineSocket, (struct sockaddr *) &servAddr, sizeof (servAddr));		
		if (rc >= 0) {
			
			char data [10];
			IPXMaxPacket initPacket;
			
			initPacket.ihdr.csum = 0xFFFF;
			initPacket.ihdr.len = htons(30);
			
			*((DWORD*)initPacket.ihdr.dstNet) = htonl(0);
			*((DWORD*)initPacket.ihdr.dstNode) = 0x0;
			*((WORD*)&initPacket.ihdr.dstNode[4]) = 0x0;
			initPacket.ihdr.dstSocket = htons(0x2);

			*((DWORD*)initPacket.ihdr.srcNet) = htonl(0);
			*((DWORD*)initPacket.ihdr.srcNode) = 0x0;
			*((WORD*)&initPacket.ihdr.srcNode[4]) = 0x0;
			initPacket.ihdr.srcSocket = htons(0x2);
			
			initPacket.ihdr.xport = 0;
			
			Message("success");
			
			connectAddress.sin_family = AF_INET;
		    	connectAddress.sin_port = htons(213);
		    	connectAddress.sin_addr.s_addr = inet_addr("127.0.0.1");
						// send registration package to basebox server
			rc = sendto (cmdLineSocket, 
					(BYTE*) &initPacket.ihdr, 
					sizeof(IPXHeader),
					0,
			                (struct sockaddr *) &connectAddress,
	                		sizeof (connectAddress));
			if(rc == 0) {
		    		Message("connect success");
		    		/*send(cmdLineSocket, "abcd", 4, 0);*/
		    	} else {
		    		Message("connect failed");
		    		
		    	}
								
	        }
	}
	else {
    	    
		Message("Error: socket connection failed");
        }
#else
        cmdLineSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);    
    
        /* try connectiokn now */
        if(cmdLineSocket != INVALID_SOCKET ) {
    	    
    	int result;
    	
    	memset(&connectAddress, 0, sizeof(connectAddress));
    	
    	connectAddress.sin_family = AF_INET;
    	connectAddress.sin_port = htons(8079);
    	connectAddress.sin_addr.s_addr = inet_addr("127.0.0.1");
    
    	result =  connect(cmdLineSocket,
    	              (struct sockaddr *) &connectAddress, 
    	              sizeof(connectAddress));
    	if(result == 0) {
    		Message("connect success");
    		/*send(cmdLineSocket, "abcd", 4, 0);*/
    	} else {
    		Message("connect failed");
    		
    	}
        }
        else {
    	    
    	Message("Error: socket connection failed");
        }
#endif
}

void Ipx_Exit(void) {

    /* close the socket here */
}

void Ipx_CopyToSendBuffer(caddr_t a, int b, int c) {

	//send(cmdLineSocket, a, b, 0);
}

void Ipx_SendLow(int a) {
}

int Ipx_CheckPacket(void) {
	DWORD count;
	ioctlsocket(cmdLineSocket, FIONREAD, &count);
	//MessageFlush("read count %d\n", count);
	    return count;
}

int Ipx_ReadLow(void *buf, int bufSize) {
    
    IPXMaxPacket ipkt;
        
	//MessageFlush("read1\n");
    if(cmdLineSocket != -1) {
	    int amount = recv(cmdLineSocket, (BYTE*) &ipkt, sizeof(ipkt), 0);

	    if (amount < 30) {
		/*
		 * Didn't even get a full IPX header, so packet is bogus.
		 */
		return -1;
	    }    

	    if (amount < ntohs(ipkt.ihdr.len)) {
		/*
		 * Didn't get all the data for the packet (?!)
		 */
		return -1;
	    }	    

	    amount = ntohs(ipkt.ihdr.len) - 30;
	    if (amount > bufSize) {
		amount = bufSize;
	    }
	    /*
	     * Copy in only as much data as will fit -- the rest are lost.
	     */
	    if(amount > 0) {
	    	bcopy(((BYTE*)&ipkt) + 30, buf, amount);
		}

	    /*MessageFlush("read %d\n", amount);*/
    	return amount;
    }
    return -1;
}

/***********************************************************************
 *				NtserialOutputLastError
 ***********************************************************************
 *
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	9/11/96   	Initial Revision
 *
 ***********************************************************************/
void
NtserialOutputLastError(char *where)
{
    LPVOID lpMsgBuf;
    char *end;
    char denied[] = "<couldn't get last error>";
    BOOL returnCode = FALSE;

#if 0
    char buf[1000];

    WinUtil_SprintError(buf, where);
    MessageFlush(buf);
#endif
    return;
}	/* End of NtserialOutputLastError.	*/
