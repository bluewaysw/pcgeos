/***********************************************************************
 *
 *	Copyright (c) Geoworks 1995 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Socket
 * MODULE:	  
 * FILE:	  sockmisc.h
 *
 * AUTHOR:  	  Jennifer Wu: Dec  7, 1995
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/ 7/95	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	Miscellaneous socket definitions.
 *
 * 	$Id: sockmisc.h,v 1.1 97/04/04 15:59:54 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _SOCKMISC_H_
#define _SOCKMISC_H_

/*
 * Specific Socket Driver Errors
 *
 * These go in the high byte of SocketDrError for the application to 
 * interpret. 
 *
 */
typedef enum /*word*/ {
    SSDE_DEVICE_BUSY = 0x0100,	    /* serial port or modem driver in use */
    SSDE_DIAL_ERROR = 0x0200,
    SSDE_LINE_BUSY = 0x0300,   	    /* modem got a busy signal */
    SSDE_NO_DIALTONE = 0x0400,	    	    
    SSDE_NO_ANSWER = 0x0500,
    SSDE_NO_CARRIER = 0x0600,
    SSDE_BLACKLISTED = 0x0700,	    /* used in GSM network */
    SSDE_DELAYED = 0x0800,  	    /* used in GSM network */
    SSDE_CALL_FAILED = 0x0900, 	    /* couldn't dial for some strange reason */
    SSDE_NEG_FAILED = 0x0a00,
    SSDE_AUTH_REFUSED = 0x0b00,
    SSDE_AUTH_FAILED = 0x0c00,
    SSDE_LQM_FAILURE = 0x0d00,
    SSDE_LOOPED_BACK = 0x0e00,
    SSDE_IDLE_TIMEOUT = 0x0f00,
    SSDE_DEVICE_NOT_FOUND = 0x1000,
    SSDE_DEVICE_TIMEOUT = 0x1100,
    SSDE_DEVICE_ERROR = 0x1200,
    SSDE_NO_USERNAME = 0x1300,	    /* no username and password prompting used */
    SSDE_CANCEL = 0x1400,    	    /* user cancelled */
    SSDE_INVALID_ACCPNT = 0x1500,   /* invalid access point */
    SSDE_LOGIN_FAILED = 0x1600,	    /* manual login application */
                                    /* not configured correctly */
    SSDE_LOGIN_FAILED_NO_NOTIFY = 0x1700,
				    /* manual login application
				     * encountered an error, but doesn't
				     * wish the client app to inform
				     * the user */
    SSDE_DIAL_ABORTED = 0x1800,     /* Happens if MRC_DIAL_ABORTED
				     * returned from modem drvr.
				     * DR_MODEM_ABORT_DIAL was sent. */
} SpecSocketDrError;

/*--------------------------------------------------------------------------
 *
 *	Socket Exceptions
 *
 ------------------------------------------------------------------------- */

typedef enum /*word*/ {	    	    
    SDX_NO_ERROR,   	    	    /* must be first */
    SDX_SOURCE_QUENCH,  	
    SDX_PARAM_PROBLEM,
    SDX_TIME_EXCEEDED,
    SDX_UNREACHABLE
} SocketDrException;


/*--------------------------------
 *
 * 	    IP Constants
 *
 ------------------------------- */

#define IP_ADDR_SIZE	4

/*
 * Maximum size of IP address in dotted-decimal notation: 255.255.255.255
 */
#define MAX_IP_DECIMAL_ADDR_LENGTH  	15
#define MAX_IP_DECIMAL_ADDR_LENGTH_ZT	16

/*
 * Maximum size of a domain name is 255.  (RFC 1034, section 3.1)
 *  "To simplify implementations, the total number of octets that represent
 *  a domain name is limited to 255."
 */
#define MAX_IP_ADDR_STRING_LENGTH   	255
#define	MAX_IP_ADDR_STRING_LENGTH_ZT	256



#define LOOPBACK_NET 	127


/* -------------------------------------------------------------------
 	    Extended Socket Address Control Address

  The opaque part of the Socket Address Control Address structure 
  contains an extended address with the following information:
   1) size of link parameters, including link type
   2) link type	    	    	    (optional)
   3) link parameters	    	    (optional)
   4) connection address
  where the nature of the link parameters depends on the link type.

  In the ExtendedSACAddress structure, the connection address 
  immediately follows the opaque link parameters.

  The user readable link and connection addresses follow the 
  opaque connection address.  The link address will be appended
  to the user readable connection address string, surrounded by
  parenthesis.  (This assumes the connection address has no
  parenthesis, which is true for IP.)

  For more information about the SocketAddressControlClass, and
  the context in which it will use an ExtendedSACAddress, see
  the file sac.goh

 ------------------------------------------------------------------- */

typedef word	LinkID;   	   /* permanent identifier for a link 
				      in the link database */

typedef byte	LinkType;
#define LT_ADDR	    0x00	   /* link params = link address */
#define	LT_ID	    0x01    	   /* link params = LinkID */

typedef struct {
    LinkType        LP_type;
 /* label byte	    LP_params;  */
} LinkParams;

typedef struct {
    word    	    ESACA_linkSize;
 /* label byte	    ESACA_opaque;   Start of LinkParams, immediately followed 
    	    	    	    	    by the connection address */
} ExtendedSACAddress;

/* -------------------------------------------------------------------------
 * 
 *	    TCP Extended Address Structures
 *
 *	These structures are defined here to give an example of the
 *	different forms a TCP address may take.  While the
 *	ExtendedSACAddress given above is common to all drivers, these
 *	declarations are specific to TCP.  The resolved forms assume
 *	the link driver will not change the link paramters during
 *	resolution, which is true of PPP and SLIP, but not necessarily
 *	of future drivers.
 *
 ------------------------------------------------------------------------ */


/*
 * A TCP extended address using an access point ID as the link address.
 */

typedef struct {
    word    TAPEA_linkSize; 	    	/* 3 */
    byte    TAPEA_linkType; 	    	/* LinkType (LT_ID) */
    word    TAPEA_accPntID; 	    	
} TcpAccPntExtendedAddress;


/*
 * A TCP extended address with no link address.
 */

typedef struct {
    word    TOEA_linkSize;  	    	/* 0 */
/*  label byte TOEA_ipAddr; 	    	IP address  */
} TcpOnlyExtendedAddress;



/*
 * The resolved form of the previous two structures.  A resolved
 * IP address is always 4 bytes.
 */
typedef struct {
    word    TAPRA_linkSize; 	    	/* 3 */
    byte    TAPRA_linkType; 	    	/* LinkType (LT_ID) */
    word    TAPRA_accPntID; 	    	
    byte    TAPRA_ipAddr[4];     	/*  IP address */
} TcpAccPntResolvedAddress;

typedef struct {
    word    TORA_linkSize;  	    	/* 0 */
    byte    TORA_ipAddr[4]; 	    	/* IP address  */
} TcpOnlyResolvedAddress;


/*
 * A TCP extended address with a non-accpnt link address.
 */

typedef struct {
    word    TNAPEA_linkSize;	    
    byte    TNAPEA_linkType;	    	/* LinkType (LT_ADDR) */
/*  label byte TNAPEA_addr;    	link address immed. followed by IP addr */
} TcpNonAccPntExtendedAddress;


/*---------------------------------------------------------------------------
 *	    
 *	    PPP server and client IP addresses
 *
 * Server and client addresses for use when our PPP is called by another.
 * We will be the server and the peer will be assigned the client address.
 *
 * From rfc1597:
 *	The Internet Assigned Numbers Authority (IANA) has reserved the 
 *	following three blocks of the IP address space for private networks:
 *
 *	10.0.0.0    	-   10.255.255.255
 * 	172.16.0.0  	-   172.31.255.255
 *	192.168.0.0 	-   192.168.255.255
 *
 * We're using two addresses from this range, chosen completely at random. ;)  
 ------------------------------------------------------------------------- */

# define CLIENT_IP_ADDR     0x0a455057	/* 10.69.80.87 in host byte order */
# define SERVER_IP_ADDR	    0x0a4a5755	/* 10.74.87.85 in host byte order */

#define DEFAULT_SERVER_IP_ADDR	0x55574a0a  /* 10.74.87.85 in network order */
#define DEFAULT_CLIENT_IP_ADDR	0x5750450a  /* 10.69.80.87 in network order */


/*---------------------------------------------------------------------------
 *
 *	    	UDP/TCP assigned ports 
 *
 -------------------------------------------------------------------------- */

#define	    ECHO    	    7   	    	    /* TCP/UDP */
#define	    DISCARD 	    9   	    	    /* TCP/UDP */
#define	    FTP_DATA	    20  	    	    /* TCP */
#define	    FTP	    	    21  	    	    /* TCP */
#define     SMTP            25                      /* TCP */
#define	    TELNET_SERVER   23  	    	    /* TCP */
#define	    NAME_SERVER     42  	    	    /* UDP */
#define	    WHOIS   	    43  	    	    /* TCP */
#define	    DOMAIN_SERVER   53  	    	    /* TCP/UDP */
#define	    FINGER  	    79  	    	    /* TCP */
#define     POP3            110                     /* TCP */

/*--------------------------------------------------------------------------
 *
 * 	SocketSubsystemNotification types
 *
 -------------------------------------------------------------------------- */
typedef enum {
    SSN_LINK_CONNECTED = 0x0,
    SSN_LINK_NOT_CONNECTED,
} SocketSubsystemNotification;

#endif /* _SOCKMISC_H_ */


