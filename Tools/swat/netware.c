/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1994 -- All Rights Reserved
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  netware.c
 *
 * AUTHOR:  	  Adam de Boor: Feb 27, 1994
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Name	  Date	    Description
 *	----	  ----	    -----------
 *	ardeb	  2/27/94	    Initial version
 *
 * DESCRIPTION:
 *	Functions for sending & receiving IPX packets under UNIX
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: netware.c,v 1.7 97/04/18 16:18:31 dbaumann Exp $";
#endif lint

#include <config.h>

#if defined(unix)
#include <sys/types.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <stropts.h>
#include <sys/time.h>
#include <net/if.h>
#include <net/nit_if.h>
#include <net/nit_pf.h>
#include <net/packetfilt.h>
#include <netinet/in.h>
#include <netinet/if_ether.h>
#include <sys/uio.h>
#include <sys/errno.h>
#endif
#ifdef _LINUX
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#endif
#ifdef _WIN32
#include <compat/windows.h>       /* for communications stuff */
#include <winsock2.h>
#endif

#include <stddef.h>
#include <compat/string.h>
extern int errno;

#include "swat.h"
#include "netware.h"
#include "cmd.h"

#if !defined(unix)
#include "serial.h" /* contains iovec structure definition */
#include <compat/stdlib.h>
#endif

#define IPX_MAX_PACKET	    546

#define ETHERTYPE_IPX	    0x8137

#define DEFAULT_SOCKET	    0x3f

#if !defined(unix) && !defined(_LINUX)
typedef unsigned short 	u_short;
#ifndef _WIN32
typedef char	u_char;
#endif
#endif

#if defined(unix) 
typedef struct {
    u_short 	csum;	    /* 0xffff */
    u_short 	len;	    /* big-endian */
    u_char  	xport;	    /* 0 */
    u_char  	ptype;
#define PT_UNKNOWN  	0
#define PT_ROUTE    	1
#define PT_ECHO		2
#define PT_ERROR    	3
#define PT_DATA		4
#define PT_SPX		5 
#define PT_NCP		17
    u_char  	dstNet[4];
    u_char  	dstNode[6];
    u_short  	dstSocket;  /* big-endian */
    u_char  	srcNet[4];
    u_char  	srcNode[6];
    u_short 	srcSocket;  /* big-endian */
} IPXHeader;

static struct sockaddr	ctrlPacket;

typedef struct {
    IPXHeader	    ihdr;
    unsigned char   data[IPX_MAX_PACKET];
} IPXMaxPacket;

extern IPXMaxPacket 	ipxOutPacket;

#else
#if defined(_WIN32)

#define IPX_MAX_PACKET	    546

typedef struct {
    word 	csum;	    /* 0xffff */
    word 	len;	    /* big-endian */
    byte  	xport;	    /* 0 */
    byte  	ptype;
#define PT_UNKNOWN  	0
#define PT_ROUTE    	1
#define PT_ECHO		2
#define PT_ERROR    	3
#define PT_DATA		4
#define PT_SPX		5 
#define PT_NCP		17
    byte  	dstNet[4];
    byte  	dstNode[6];
    word  	dstSocket;  /* big-endian */
    byte  	srcNet[4];
    byte  	srcNode[6];
    word 	srcSocket;  /* big-endian */
} IPXHeader;


typedef struct {
    IPXHeader	    ihdr;
    byte   data[IPX_MAX_PACKET];
} IPXMaxPacket;

extern IPXMaxPacket 	ipxOutPacket;

#endif
#endif

#if defined(_LINUX)
static int cmdLineSocket = -1;
#endif
#if defined(_WIN32)
extern int cmdLineSocket;
#endif

#define IPX_VIA_UDP

/*********************************************************************
 *			parsehex
 *********************************************************************
 * SYNOPSIS: 	a routine to parse the adderss into numeric format
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/23/94		Initial version			     
 * 
 *********************************************************************/

void
parsehex(char *str, u_char *buf, unsigned ndigits, unsigned len)
{
    u_char  b=0;		/* initialized to keep GCC from whining */
    unsigned toggle;

    if (len == 0) {
	len = strlen(str);
    }

    if (len > ndigits) {
	Message("too many digits in %s (%d max)\n", str, ndigits);
	len = ndigits;
    }

    for (toggle = 0; ndigits > 0; ndigits--) {
	unsigned n;
	
	if (ndigits > len) {
	    n = 0;
	} else if (*str >= '0' && *str <= '9') {
	    n = *str++ - '0';
	} else if (*str >= 'A' && *str <= 'F') {
	    n = *str++ - 'A' + 10;
	} else if (*str >= 'a' && *str <= 'f') {
	    n = *str++ - 'a' + 10;
	} else {
	    Message("Invalid hex digit %c\n", *str++);
	    n = 0;
	}
	b <<= 4;
	b |= n;
	if ((toggle = ~toggle) == 0) {
	    *buf++ = b;
	}
    }
}

#if !defined(unix)
/*********************************************************************
 *			parsehexaddress
 *********************************************************************
 * SYNOPSIS: 	utility routine to make my life easier
 * CALLED BY:	Ipx_Init (in serial.asm)
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:	parse the whole address by calling parsehex on each section
 *	    	of the address
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/23/94		Initial version			     
 * 
 *********************************************************************/
void parsehexaddress(u_char   *addr, u_char *buffer)
{
    u_char    *node;
    u_char    *sock;

    node = (u_char *)strchr(addr, ':') + 1;
    sock = (u_char *)strchr(node, ':') + 1;

    parsehex(addr, buffer, 8, node-1-addr);
    parsehex(node, buffer+4, 12, sock-1-node);
    parsehex(sock, buffer+10, 4, strlen(sock));
}
#endif



/***********************************************************************
 *				NetWare_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize the netware IPX connection.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    the file descriptor of the NIT connection
 * SIDE EFFECTS:    ipxOutPacket and ctrlPacket are as initialized as
 *		    possible
 *
 * STRATEGY:	    our ability to send and receive IPX packets rests on
 *		    the SunOS NIT device. We open it and push on the
 *	    	    packet-filter NIT module, so we don't get every
 *		    ethernet packet addressed to this machine (or broadcast).
 *		    We're looking instead only for IPX packets to socket
 *		    DEFAULT_SOCKET.
 *
 *	    	    The "addr" string is formatted as 2 or 3 hex numbers,
 *		    separated by colons. The first one is the network number
 *		    (up to 8 hex digits). The second is the node number
 *		    (up to 12 hex digits; it's the ethernet address). The
 *		    optional third is the socket number (up to 4 hex digits).
 *		    If the socket number isn't given, we assume DEFAULT_SOCKET.
 *		    Any missing digits are assumed to be leading 0's
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/27/94		Initial Revision
 *
 ***********************************************************************/
#if defined(unix)
int
NetWare_Init(char *addr)
{
    int	    	    nit;    	    /* Stream open to the NIT */
    struct ifreq    ifr;    	    /* interface request structure to allow
				     * us to bind to le0 */
    struct strioctl si;	    	    /* Ioctl msg for sending down the stream
				     * to one of the modules. */
    struct ether_header *ehdr;	    /* Shorthand way of referring to the sa_data
				     * portion of the ctrlPacket sockaddr, where
				     * the link-level header is placed before
				     * calling putmsg() to put a packet out
				     * on the wire */
    struct packetfilt	filter;	    /* Filter definition to make sure we get
				     * only IPX packets to socket 0x3f */
    u_short 	    *filtop;	    /* Pointer for initializing the filter */
    char    	    *cp;    	    /* Random character pointer for parsing the
				     * address of the PC */
    char    	    *node;  	    /* Start of the node address. Ends at
				     * sock-1 or with null char */
    char    	    *sock;  	    /* Start of the socket number. Ends with
				     * null char */
    int	    	    socket_num;	    /* socket number to use (process id) */



    ehdr = (struct ether_header *)&ctrlPacket.sa_data[0];

    /*
     * Break up the address string into its component parts.
     */
    cp = strchr(addr, ':');
    if (cp == NULL) {
	Message("Missing node address in PC net address\n");
	return (-1);
    }
    node = cp+1;
    cp = strchr(node, ':');
    if (cp == NULL) {
	sock = NULL;
    } else {
	sock = cp+1;
    }
    
    /*
     * Open the NIT device. Must be root to do this (to avoid being root,
     * we might consider having a daemon that could be talked to via UNIX
     * sockets and have it open the device with the appropriate settings and
     * return the ether_hdr et al along with the stream open to the NIT [sent
     * as access rights with the message...])
     */
    nit = open("/usr/share/swat_tap", O_RDWR, 0);
    if (nit < 0) {
	perror("open NIT");
	return(-1);
    }
    /*
     * Stop being root
     */
    setuid(getuid());
    

    /*
     * We want only whole packets when we read. If we don't get it all, the rest
     * gets dropped.
     */
    ioctl(nit, I_SRDOPT, (char *)RMSGD);

    /*
     * Push on the filtering module, so we don't waste space in the kernel
     */
    ioctl(nit, I_PUSH, "pf");

    /*
     * Filter out all but IPX packets to socket DEFAULT_SOCKET, which is what
     * we always use for a source. We use ENF_AND at the end, as ENF_CAND
     * doesn't appear to do what we want (we don't get every packet, but
     * we get a strange assortment of them, which isn't what we're after...)
     */

    /* try using process id, rather than DEFAULT_SOCKET so multiple swats
     * can be running on the same machine
     */
    socket_num = getpid();

    filter.Pf_Priority = 0;
    filtop = &filter.Pf_Filter[0];

    *filtop++ = ENF_PUSHWORD + (offsetof(struct ether_header, ether_type)/2);
    *filtop++ = ENF_PUSHLIT | ENF_EQ;
    *filtop++ = htons(ETHERTYPE_IPX);
    *filtop++ = ENF_PUSHWORD +
	((offsetof(IPXHeader, dstSocket) +
	  sizeof(struct ether_header)) / 2);
    *filtop++ = ENF_PUSHLIT | ENF_EQ;
    *filtop++ = htons(socket_num);
    *filtop++ = ENF_NOPUSH | ENF_AND;
    
    filter.Pf_FilterLen = filtop - &filter.Pf_Filter[0];

    si.ic_cmd = NIOCSETF;
    si.ic_len = sizeof(filter);
    si.ic_dp = (char *)&filter;
    si.ic_timout = INFTIM;
    if (ioctl(nit, I_STR, (char *)&si) < 0) {
	perror("NIOCSETF");
	(void)close(nit);
	return(-1);
    }
    
    /*
     * Tell our NIT to use the le0 interface. This indirect ioctl will make
     * its way down the stream to a module that cares about it...
     *
     * At some point we'll want to allow the interface to be specified, or
     * we'll go look for non lo0 interfaces, but...
     */
    strncpy(ifr.ifr_name, "le0", sizeof(ifr.ifr_name));
    si.ic_cmd = NIOCBIND;
    si.ic_len = sizeof(ifr);
    si.ic_dp = (char *)&ifr;
    si.ic_timout = INFTIM;	/* No time-out on handling the ioctl */
    if (ioctl(nit, I_STR, (char *)&si) < 0) {
	perror("NIOCBIND");
	(void)close(nit);
	return(-1);
    }

    /*
     * Fetch our own ethernet address for use in the IPX and ethernet headers
     */
    ifr.ifr_ifru.ifru_addr.sa_family = AF_UNSPEC;
    if (ioctl(nit, SIOCGIFADDR, &ifr) < 0) {
	perror("GIFADDR");
	(void)close(nit);
	return(-1);
    }

    ether_copy(&ifr.ifr_ifru.ifru_addr.sa_data, &ehdr->ether_shost);
    ether_copy(&ifr.ifr_ifru.ifru_addr.sa_data, &ipxOutPacket.ihdr.srcNode);

    /*
     * Set the ethernet packet type to IPX.
     */
    ehdr->ether_type = htons(ETHERTYPE_IPX);

    /*
     * Always comes from the default socket #
     */
    ipxOutPacket.ihdr.srcSocket = htons(socket_num);

    /*
     * Figure out the destination socket #
     */
    if (sock == NULL) {
	ipxOutPacket.ihdr.dstSocket = htons(socket_num);
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
    ether_copy(&ipxOutPacket.ihdr.dstNode, &ehdr->ether_dhost);

    /*
     * Set up the parts of the IPX packet that never change.
     */
    ipxOutPacket.ihdr.csum = 0xffff;
    ipxOutPacket.ihdr.xport = 0;
    ipxOutPacket.ihdr.ptype = PT_DATA;

    /*
     * The sockaddr passed in the control message must be of the UNSPEC family.
     */
    ctrlPacket.sa_family = AF_UNSPEC;

    return(nit);
}
#else

#define IPX_MAX_PACKET 546

extern void Ipx_Exit(void);

/*********************************************************************
 *			NetWare_Init
 *********************************************************************
 * SYNOPSIS: PC veriosn of NetWare_Init, just calls assembly routines
 * 	    	see above header for other more info
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/25/94		Initial version			     
 * 
 *********************************************************************/
int
NetWare_Init(char *addr)
{
    short   ipx;

    Message("Checking for IPX...");
    ipx = Ipx_Check();
    if (ipx == 0)
    {
	MessageFlush("Ipx not found.\n");
	return -1;
    }
    Ipx_Init(addr);
    MessageFlush("Ipx found: %d.\n", ipx);

    /* we need to clean up when we exit if we are using the network */
    atexit(Ipx_Exit);

    return 1;
}
#endif


/***********************************************************************
 *				NetWare_Read
 ***********************************************************************
 * SYNOPSIS:	    Read the next packet from the NIT
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    number of data bytes in the packet
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/27/94		Initial Revision
 *
 ***********************************************************************/
#if defined(unix)
int
NetWare_Read(int    fd, void *buf, int bufSize)
{
    struct {
	struct ether_header ehdr;
	IPXMaxPacket	    ipckt;
    }	    pckt;
    int	    cc;

    /*
     * Read the largest datagram an IPX packet could possibly be.
     */
    cc = read(fd, &pckt, sizeof(pckt));

    /*
     * The thing has been completely filtered. We know the packet is IPX and
     * for our socket, so we should just have to copy the data in.
     */
    if (cc < sizeof (struct ether_header) + sizeof(IPXHeader)) {
	/*
	 * Didn't even get a full IPX header, so packet is bogus.
	 */
	return -1;
    }
	    
    if (cc - sizeof(struct ether_header) < ntohs(pckt.ipckt.ihdr.len)) {
	/*
	 * Didn't get all the data for the packet (?!)
	 */
	return -1;
    }
    cc = ntohs(pckt.ipckt.ihdr.len) - sizeof(IPXHeader);
    if (cc > bufSize) {
	cc = bufSize;
    }
    /*
     * Copy in only as much data as will fit -- the rest are lost.
     */
    bcopy(&pckt.ipckt.data, buf, cc);
    return (cc);
}
#else
int
NetWare_Read(int    fd, void *buf, int bufSize)
{
    return(Ipx_ReadLow(buf, bufSize));
}
#endif


/***********************************************************************
 *				NetWare_WriteV
 ***********************************************************************
 * SYNOPSIS:	    Put a packet out on the wire.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    number of bytes written
 * SIDE EFFECTS:    ipxOutPacket is overwritten
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/27/94		Initial Revision
 *
 ***********************************************************************/
#if defined(unix)
int
NetWare_WriteV(int fd, struct iovec *iov, int iov_len)
{
    unsigned char   *bp;
    int	    	    i;
    struct strbuf   pctrl;
    struct strbuf   pdata;

    /*
     * First copy the data into the data portion of ipxOutPacket.
     * Unfortunately, putmsg doesn't take a gather vector...
     */
    for (i = 0, bp = &ipxOutPacket.data[0]; i < iov_len; i++) {
	if (bp - &ipxOutPacket.data[0] + iov[i].iov_len >
	    sizeof(ipxOutPacket.data))
	{
	    errno = EMSGSIZE;
	    return(-1);
	}
	
	bcopy(iov[i].iov_base, bp, iov[i].iov_len);
	bp += iov[i].iov_len;
    }

    ipxOutPacket.ihdr.len =
	htons(sizeof(IPXHeader) + (bp - &ipxOutPacket.data[0]));

    pctrl.buf = (char *)&ctrlPacket;
    pctrl.len = sizeof(ctrlPacket);

    pdata.buf = (char *)&ipxOutPacket;
    pdata.len = bp - (unsigned char *)&ipxOutPacket;

    if (putmsg(fd, &pctrl, &pdata, 0) < 0) {
	return(-1);
    }

    return (bp - &ipxOutPacket.data[0]);
}
#else
int
NetWare_WriteV(int fd, struct iovec *iov, int iov_len)
{
#if !defined(_LINUX) 
#ifdef IPX_VIA_UDP
	unsigned char   *bp;
	int	    	    i;	
	int 			len;
	BYTE*			dataStart;
	int rc;
	struct sockaddr_in connectAddress;

	/*
 	* First copy the data into the data portion of ipxOutPacket.
 	* Unfortunately, putmsg doesn't take a gather vector...
 	*/
	dataStart = ((BYTE*) &ipxOutPacket) + 30;
	for (i = 0, bp = dataStart; i < iov_len; i++) {
    		if (bp - dataStart + iov[i].iov_len >
			IPX_MAX_PACKET)
    		{
			/*errno = EMSGSIZE;*/
			return(-1);
    		}
    
    		bcopy(iov[i].iov_base, bp, iov[i].iov_len);
    		bp += iov[i].iov_len;
	}

	len = sizeof(IPXHeader) + (bp - dataStart);
	ipxOutPacket.ihdr.len = htons(len);

	/*printf("LEN %d\n", len); fflush(stdout);*/
	connectAddress.sin_family = AF_INET;
	connectAddress.sin_port = htons(213);
	connectAddress.sin_addr.s_addr = inet_addr("127.0.0.1");
	
	*((DWORD*)ipxOutPacket.ihdr.srcNode) = inet_addr("127.0.0.1");
	*((WORD*)&ipxOutPacket.ihdr.srcNode[4]) =  htons(1234);
	/*
	i=0;
	while(i < len) {
		printf("%x ",((BYTE*) (&ipxOutPacket))[i] );
		i++;
	}
	printf("\n"); fflush(stdout);
*/
	ipxOutPacket.ihdr.csum = 0xFFFF;
	//ipxOutPacket.ihdr.len = htons(30);
	/*
	*((DWORD*)ipxOutPacket.ihdr.dstNet) = htonl(0);
	*((DWORD*)ipxOutPacket.ihdr.dstNode) = 0x0;
	*((WORD*)&ipxOutPacket.ihdr.dstNode[4]) = 0x0;
	ipxOutPacket.ihdr.dstSocket = htons(0x2);

	*((DWORD*)ipxOutPacket.ihdr.srcNet) = htonl(0);
	*((DWORD*)ipxOutPacket.ihdr.srcNode) = 0x0;
	*((WORD*)&ipxOutPacket.ihdr.srcNode[4]) = 0x0;
	ipxOutPacket.ihdr.srcSocket = htons(0x2);
*/
	ipxOutPacket.ihdr.xport = 0;	
				// send registration package to basebox server
	rc = sendto (cmdLineSocket, 
			(BYTE*) &ipxOutPacket, 
			len,
			0,
			(struct sockaddr *) &connectAddress,
			sizeof (connectAddress));
	if(rc>=0) {
		//Message("send success");
	}	
	return (bp - &ipxOutPacket.data[0]);

#else
    int	    	    i, size;
    
    /*
     * First copy the data into sendData to be sent out
     * since these data structures are not defined in assembly I just
     * did the copying to read-mode inside the loop to make life easy
     */
    for (i = 0, size = 0; i < iov_len; i++) {
	if (size + iov[i].iov_len > IPX_MAX_PACKET)
	{
	    return(-1);
	}

	Ipx_CopyToSendBuffer(iov[i].iov_base, iov[i].iov_len, size);
	size += iov[i].iov_len;
    }

    /* call the assembly routine to do the dirty work */
    Ipx_SendLow(size);
    return size;
#endif
#else
	int	    	    i, size;

	/*
	MessageFlush("NetWare_WriteV");
	 * First copy the data into sendData to be sent out
	 * since these data structures are not defined in assembly I just
	 * did the copying to read-mode inside the loop to make life easy
	 */
	for (i = 0, size = 0; i < iov_len; i++) {
		
	    int res;
	    
	    if (size + iov[i].iov_len > IPX_MAX_PACKET)
	    {
		return(-1);
	    }

	    res = send(cmdLineSocket, iov[i].iov_base, iov[i].iov_len, 0);
	    
	    //{
	//	    int loop=0;
	//	    while(loop < iov[i].iov_len) {
	//		    MessageFlush("%x ", iov[i].iov_base[loop]);
	//		    loop++;
	//	    }
	  //  }
	    
	    size += iov[i].iov_len;
	}

	/* call the assembly routine to do the dirty work */
	//Ipx_SendLow(size);
	return size;
#endif
}
#endif

    
/* empty Ipx funtion definitions.  Makes the Borland linker happy for now.
 * Novell will not be supported initially
 */

#if defined(_LINUX) 
int Ipx_Check(void) {
    return 1;
}

void Ipx_Init(char *addr) {

    /* open the socket here */
    if(cmdLineSocket != -1) {
	Message("Error: command line socket already open");
    }
    cmdLineSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);    

    /* try connectiokn now */
    if(cmdLineSocket != -1) {
	    
	struct sockaddr_in connectAddress;
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
		send(cmdLineSocket, "abcd", 4, 0);
	} else {
		Message("connect failed");
		
	}
    }
    else {
	    
	Message("Error: socket connection failed");
    }
}

void Ipx_Exit(void) {

    /* close the socket here */
}

void Ipx_CopyToSendBuffer(caddr_t a, int b, int c) {
}

void Ipx_SendLow(int a) {
}

int Ipx_CheckPacket(void) {
	int count;
	ioctl(cmdLineSocket, FIONREAD, &count);
	//MessageFlush("read count %d\n", count);
	    return count;
}

int Ipx_ReadLow(void *buf, int bufSize) {
    
	//MessageFlush("read1\n");
    if(cmdLineSocket != -1) {
	    int amount = recv(cmdLineSocket, buf, bufSize, 0);
	    //MessageFlush("read %d\n", amount);
    	return amount;
    }
    return -1;
}

#endif
