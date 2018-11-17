/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright NewDeal 1998 -- All Rights Reserved
	NEWDEAL CONFIDENTIAL

PROJECT:	PC GEOS (Network Extensions)
MODULE:		TELNET
FILE:		telnet.h

AUTHOR:		Martin Turon, April 25, 1998

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	4/25/98   	Initial revision


DESCRIPTION:
	This file contains constants, definitions and API function
	descriptions for TELNET library.
		
	$Id: telnet.h,v 1.1 98/07/09 16:03:08 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */

#ifndef _TELNET_H_
#define _TELNET_H_

/* @include <Internal/socketDr.h> */

/*-------------------------------------------------------*/
/* 		Constants				 */
/*-------------------------------------------------------*/

#define TELNET_DEFAULT_PORT	23
#define TELNET_NO_TIMEOUT	SOCKET_NO_TIMEOUT
		/* 
		 * If you need to pass a timeout value to a routine 
		 * but you do not want to really time out, you can 
		 * pass this value instead.
		 */

/*-------------------------------------------------------*/
/* 		 	Structures			 */
/*-------------------------------------------------------*/

/*
 * To indicate whether the option is enabled remotely or locally
 */
typedef ByteFlags TelnetOptFlags;
#define TOF_LOCAL    0x02
#define TOF_REMOTE   0x01

#define TELNET_OPT_LOCAL_ONLY	     TOF_LOCAL
#define TELNET_OPT_REMOTE_ONLY	     TOF_REMOTE
#define TELNET_OPT_LOCAL_AND_REMOTE  TOF_LOCAL | TOF_REMOTE


/*----------------------------------------------------------------------------
 *			Types
 *---------------------------------------------------------------------------*/

/*
 * Mode of operation to determine when data should be sent out or buffered.
 */
typedef enum {
  TOM_HALF_DUPLEX,	
  TOM_CHAR_AT_A_TIME,	
  TOM_LINE_AT_A_TIME,	
  TOM_LINEMODE,		
} TelnetOperationMode; /*	etype	2, 0, 1 */


/**************

;
; Explicitly assign the numbers so that it is easier to tell the which
; command from the value.
;
TelnetCommand	etype	byte
TC_EOF		enum	TelnetCommand, 236	; end-of-file
TC_SUSP		enum	TelnetCommand, 237	; suspend current process
TC_ABORT	enum	TelnetCommand, 238	; abort process
TC_EOR		enum	TelnetCommand, 239	; end of record
TC_SE		enum	TelnetCommand, 240	; suboption end
TC_NOP		enum	TelnetCommand, 241	; no operation
TC_DM		enum	TelnetCommand, 242	; data mark
TC_BRK		enum	TelnetCommand, 243	; break
TC_IP		enum	TelnetCommand, 244	; inerrupt process
TC_AO		enum	TelnetCommand, 245	; abort output
TC_AYT		enum	TelnetCommand, 246	; are you there?
TC_EC		enum	TelnetCommand, 247	; erase character
TC_EL		enum	TelnetCommand, 248	; erase line
TC_GA		enum	TelnetCommand, 249	; go ahead
TC_SB		enum	TelnetCommand, 250	; suboption begin
TC_WILL		enum	TelnetCommand, 251	; option negotiation
TC_WONT		enum	TelnetCommand, 252	; option negotiation
TC_DO		enum	TelnetCommand, 253	; option negotiation
TC_DONT		enum	TelnetCommand, 254	; option negotiation
TC_IAC		enum	TelnetCommand, 255	; data byte 255

TelnetOptionRequest	etype	byte
TOR_WILL	enum	TelnetOptionRequest, TC_WILL
TOR_WONT	enum	TelnetOptionRequest, TC_WONT
TOR_DO		enum	TelnetOptionRequest, TC_DO
TOR_DONT	enum	TelnetOptionRequest, TC_DONT

***/

/*
 * Supported telnet options
 */
typedef ByteEnum TelnetOptionID;
#define  TOID_TRANSMIT_BINARY	 0
#define  TOID_ECHO		 1
#define  TOID_SUPPRESS_GO_AHEAD  3
#define  TOID_STATUS		 5
#define  TOID_TIMING_MARK	 6
#define  TOID_TERMINAL_TYPE	 24


/****

;
; Data types returned
;
TelnetDataType		etype	word,	0, 1
TDT_DATA		enum	TelnetDataType	; normal data stream
TDT_NOTIFICATION	enum	TelnetDataType	; special notification by
						; system 
TDT_OPTION		enum	TelnetDataType	; option data returned
TDT_SUBOPTION		enum	TelnetDataType	; suboption data returned

;
; Notification that the library or remote connection sends out
;
TelnetNotificationType	etype	word,	0, 1
TNT_NO_NOTIFICATION	enum	TelnetNotificationType
TNT_REMOTE_ECHO_ENABLE	enum	TelnetNotificationType
TNT_REMOTE_ECHO_DISABLE enum	TelnetNotificationType
TNT_BINARY_MODE_ENABLE	enum	TelnetNotificationType
TNT_BINARY_MODE_DISABLE	enum	TelnetNotificationType

;
; Command to change the behavior or status of a telnet command
;
TelnetSetStatusCommand	etype	word,	0, 1
TSSC_RESET_SYNCH	enum	TelnetSetStatusCommand
; Reset Synch signal and resume output				

**********/

/*
 * Identify each Telnet connection
 */
typedef word TelnetConnectionID;

typedef enum WordEnum {
  TE_NORMAL,
  TE_TIMED_OUT,
  TE_INTERNAL_ERROR,
  TE_INSUFFICIENT_MEMORY,
  TE_PORT_IN_USE,
  TE_CONNECTION_REFUSED,
  TE_CONNECTION_FAILED,
  TE_CONNECTION_CLOSED,
  TE_CONNECTION_ERROR,
  TE_CONNECTION_IDLE_TIMEOUT,
  TE_SYSTEM_SHUTDOWN,
  TE_DESTINATION_UNREACHABLE,
  TE_OPTION_DISABLED,
  TE_OPERATION_MODE_FAIL,
  TE_LINK_FAILED,
  TE_INTERRUPT,
  TE_NOT_INTERRUPTIBLE
} TelnetError;

/*----------------------------------------------------------------------------
 *			Structures
 *---------------------------------------------------------------------------*/

/*
 * Descriptor of an option. Generally, an array of such a descriptor is
 * passed. No specific order of descriptors of the options is required.
 */
typedef struct {
	TelnetOptionID TOD_option;	/* option to describe */
	TelnetOptFlags TOD_flags;	/* enable locally? remotely? */
} TelnetOptionDesc;
/*	TOD_data	label	byte		; any specific data to option
 */
/*********************************


;
; ***** TelnetOptionDesc of different options *****
;
; * If the local part of the option is not supported, enabling the flag in
; TOD_flags will have no effect. Same for remote.
;
; * There should be no option repetitively inserted in the array. 
;
; TOID_TRANSMIT_BINARY:
;	No additional data required.
;	Local and remote options can be enabled.
;
; TOID_ECHO:
; 	No additional data required.
;	Only remote local option is supported.
;
; TOID_SUPPRESS_GO_AHEAD:
;	No additional data required.
;	Local and remote options can be enabled.
;
; TOID_STATUS:
;	No additional data required.
;	Only local option is supported.
;
; TOID_TIMING_MARK:
;	No additional data required.
;	Local and remote options can be enabled.
;
; TOID_TERMINAL_TYPE:
; 	If TOD_flags's TOF_LOCAL flag is enabled, TOD_data should contain
; 	null-terminated terminal type string.
;	Only local option is supported.
;

TelnetOptionDescArray	struct
	TODA_numOpt	word			; number of options in the
						; array 
	TODA_optDesc	label	TelnetOptionDesc
TelnetOptionDescArray	ends

;-----------------------------------------------------------------------------
;			Exported routines
;-----------------------------------------------------------------------------

global	TelnetCreate:far
; 
; SYNOPSIS:       Create telnet control information
; 
; PASS:           nothing
; RETURN:         carry set if error
; 			  ax      = TE_INSUFFICIENT_MEMORY
; 		  carry clear if no error
; 			  ax      = TE_NORMAL
; 			  bx      = TelnetConnectionID            
; DESTROYED:      nothing
; 

global	TelnetConnect:far
; 
; SYNOPSIS:       Make a telnet connection
; 
; CALLED BY:      EXTERNAL
; PASS:           bx      = TelnetConnectionID
; 		  dl      = TelnetOperationMode
; 		  bp      = timeout (in ticks) to wait for response from
; 			  connection
; 		  ds:si   = fptr to SocketAddress
; 			  SA_port         = can be specified to
; 					  TELNET_DEFAULT_PORT if default TELNET
; 					  port should be used. 
; 			  SA_domain       = "TCPIP"
; 			  SA_domainSize   = 5 for SBCS
; 					    10 for DBCS
; 			  SA_addressSize and SA_address filled with target IP
; 			  address information.
; 
; 		  es:di   = fptr to array of TelnetOptionDescArray
; 		  
; RETURN:         carry set if error
; 			  ax      = TelnetError
; 	  
; 		  carry clear if no error
; 			  ax      = TE_NORMAL
; 			  bx      = TelnetConnectionID
; 			  dl      = TelnetOperationMode -- the mode of
; 				  operation that has been negotiated
; 			  es:di   = fptr to same array of TelnetOptionDescArray.
; 				  TOD_flags will indicate whether the options
; 				  are enabled or disabled
; 
; DESTROYED:      nothing
; 
; 	  *** Notes ***
; 
; 	  * TelnetOperationMode overrides TelnetOptionStatus. In order to set
; 	  the operation mode, some options specified by TelnetOptionStatus may
; 	  be enabled or disabled, especially SUPPRESS_GO_AHEAD option.
; 
; 	  * If the caller is not satisfied with the negotiation result, it
; 	  should actively all TelnetClose to terminate the connection.
;
;         * Telnet connections cannot be re-used. That means once you have
;         called TelnetConnect on a TelnetConnectionID, regardless of
;         connection success or failure, it should be restarted by calling
;         TelnetClose and then TelnetCreate again for subsequent
;         connections. 
;

global	TelnetClose:far
;
; SYNOPSIS:	Close and clean up a telnet connection
; 
; PASS:		bx	= TelnetConnectionID (created by TelnetCreate)
; RETURN:	carry set if error
; 			ax      = TelnetError
; 		carry clear if no error
; 			ax      = TE_NORMAL
; DESTROYED:	nothing
;
 
global	TelnetSend:far
; 
; SYNOPSIS:	Send a stream of data to TELNET connection
; 
; PASS:		bx	= TelnetConnectionID
; 		ds:si	= fptr to data to send
; 		cx	= size of data (in bytes)
; RETURN:	carry set if error
; 		  ax	= TE_INSUFFICIENT_MEMORY
; 		    	  TE_CONNECTION_FAILED
; 		carry clear if no error
; 		  ax	= TE_NORMAL
; DESTROYED:	nothing
;

global	TelnetRecv:far
; 
; SYNOPSIS:	Receive input data from a TELNET connection. If the
; 		  function returns with no error, the data returned can be
; 		  interpreted differently. All data returned is of one type
; 		  even though more data have been received. So, the caller
; 		  should not assume if all data have been arrived.
; 
; PASS:		bx	= TelnetConnectionID
; 		es:di	= fptr to buffer storing the data read
; 		cx	= size of buffer (in bytes) or number of bytes needed
; 			  to read
; 		bp	= timeout for returning if no data available for
; 			  reading. 
; 			  
; RETURN:	carry set if error
; 		  ax	= TE_TIMED_OUT
; 			  TE_CONNECTION_FAILED
; 			  TE_CONNECTION_CLOSED
; 
; 			  When there is no data, TelnetError = TE_TIMEOUT
; 
; 		carry set if no error
; 		  ax	= TE_NORMAL
; 		  bx	= TelnetDataType
; 			  
; 			  TelnetDataType =
; 
; 			  TDT_DATA:			
; 			  
; 				  A stream of data should be interpreted as
; 				  part of the normal data stream.
; 	  
; 				  es:di	= fptr to passed buffer filled with
; 					  data (if cx is non-zero) 
; 				  cx	= size of data returned (in bytes)
; 
; 			  TDT_NOTIFICATION:
; 
; 				  Notification about any change of behavior
; 				  that application should be aware of:
; 
; 				  dx	= TelnetNotificationType
; 				  es:di	= fptr to data associated with
; 					  notification 
; 				  cx	= size of data returned (in bytes)
; 
; 			  TDT_OPTION:
; 
; 				  dx	= TelnetOptionID
; 				  bp	= TelnetOptionRequest
; 
; 			  TDT_SUBOPTION:
; 
; 				  dx	= TelnetOptionID
; 				  es:di	= fptr to data contained in
; 					  suboption. 
; 				  cx	= size of data returned (in bytes)
; 
; DESTROYED:	nothing
; 

global	TelnetSendCommand:far
; 
; SYNOPSIS:	Send a command and associated data/negotiation to an
; 		  established TELNET connection.
; 
; 		  It will block until it successfully handles the command. 
; 
; PASS:		bx	= TelnetConnectionID
; 		ax	= TelnetCommand
; 
; RETURN:	carry set if error
; 			ax	= TelnetError
; 		carry clear if no error
; 			ax	= TE_NORMAL
; DESTROYED:	nothing
; 
; 	  *** Note ***
; 
; 	  * Some commands may require system option negotitation.
;

global	TelnetSetStatus:far
; 
; SYNOPSIS:       Set the status or behavior of a telnet connection.
; 
; PASS:		  bx	= TelnetConnectionID
;		  ax	= TelnetSetStatusCommand
; RETURN:	  nothing
; DESTROYED:      nothing
;

global	TelnetInterrupt:far
;
; SYNOPSIS:       Interrupt a telnet connection operation
; 
; PASS:           bx      = TelnetConnectionID
; RETURN:         carry set if error
; 			  ax      = TelnetError
; 		  carry clear if no error
; 			  ax      = TE_NORMAL
; DESTROYED:      nothing
; 

;############################################################################
;#			Error Checking
;############################################################################

global	ECCheckTelnetError:far
; 
; SYNOPSIS:       Assert the argument is TelnetError and carry is set if it
; 		  is not TE_NORMAL
; 
; PASS:           ax      = TelnetError
; RETURN:         nothing
; DESTROYED:      nothing (flags preserved)
;

EndLibrary	telnet


****************/

#endif
