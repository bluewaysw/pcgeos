/******************************************************************************

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mbTrnsDr.def

AUTHOR:		Adam de Boor, Mar 28, 1994

MACROS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/28/94		Initial revision


DESCRIPTION:
	Interface definition for Mailbox Transport drivers.
		
	$Id: mbTrnsDr.h,v 1.1 97/04/04 15:53:59 newdeal Exp $

******************************************************************************/

#ifndef __MBTRNSDR
#define __MBTRNSDR

#include "medium.h"

typedef WordFlags MailboxTransportCapabilities;		/* CHECKME */
#define MBTC_REPORTS_PROGRESS	    	(0x8000)
/*
 *  Driver is capable of reporting the progress for a message that's being
 *  transmitted (via MailboxReportProgress). Mailbox library will add
 *  percentage to the UI components of the progress box for the transmission.
 */
    
#define MBTC_MESSAGE_RETRIEVE	    	(0x4000)
/*  Driver can handle a call to DR_MBTD_RETRIEVE_MESSAGES */
    
#define MBTC_PREPARATION_NEEDS_FEEDBACK	(0x2000)
/*
 *  Driver needs time to prepare each message, so the user should be alerted
 *  to it for each message. If MBTC_PERCENT_TRANSMITTED is set, driver may
 *  also periodically provide feedback on the percent of the message that's
 *  been prepared.
 */

#define MBTC_CAN_SEND_QUICK_MESSAGE	(0x1000)
/*
 *  Indicates the driver can transmit a message body in TEXT_CHAIN or INK
 *  format, which are the two formats used to send a Quick Message. This bit
 *  is used to decide what transports show up in the Send Quick Message
 *  dialog box.
 */
    
#define MBTC_CAN_SEND_FILE	    	(0x0800)
/*
 *  Indicates the driver can send an arbitrary file. This bit is used to
 *  decide what transports show up in the Send File dialog.
 */
    
#define MBTC_CAN_SEND_CLIPBOARD	    	(0x0400)
/*
 *  Indicates the driver can send a clipboard transfer item. This bit is
 *  used to decide what transports show up in the Send Clipboard dialog.
 */
    
#define MBTC_REQUIRES_TRANSPORT_HINT	(0x0200)
/*
 *  Set if driver's address control requires the MailboxSendControl to have
 *  an ATTR_MAILBOX_SEND_CONTROL_TRANSPORT_HINT for any transport option
 *  for this driver.
 */

#define MBTC_SINGLE_MESSAGE	    	(0x0100)
/*
 *  Set if the driver sends only a single message for each connection. The
 *  Mailbox library will only issue one DR_MBTD_TRANSMIT_MESSAGE for each
 *  DR_MBTD_CONNECT call.
 */

#define MBTC_PICKY	    	    	(0x0080)
/*
 *  Set if the driver accepts only messages in a particular format or limited
 *  number of formats. The list of acceptable formats is obtained by calling
 *  DR_MBTD_GET_FORMATS
 */
    
#define MBTC_CAN_PREPARE_WHILE_CONNECTED (0x0040)
/*
 *  Set if the driver doesn't mind remaining connected while preparing
 *  messages. Causes the Mailbox library to look for other messages that
 *  might have been added that can be sent using the current connection.
 */
    
#define MBTC_NEED_MESSAGE_BODY	    	(0x0020)
/*
 *  Set if the address control wishes to be given the message body as soon
 *  as possible. If the system supports it, the call will go out to the
 *  application to create the message body and the address control will
 *  receive a MSG_MAILBOX_ADDRESS_CONTROL_BODY_AVAILABLE call once the
 *  body has been created. Refer to that message for more info.
 */

/* 5 bits unused */

typedef struct {		/* CHECKME */
    DriverInfoStruct 	MBTDI_common;
    
    MailboxTransport	MBTDI_transport;
/*  32-bit token that identifies the driver */
    
    MailboxTransportCapabilities	MBTDI_capabilities;
/*  What optional services the transport driver provides. */

    word	MBTDI_maxAddressSize;
/*
 *  The largest address the driver uses. This allows the Mailbox library to
 *  allocate enough room for receiving the address when checking whether a
 *  connection-by-medium notification means this transport driver.
 */
    

} MBTDInfo;

#define MBTD_PROTO_MAJOR	(DRIVER_PROTO_MAJOR+2)
#define MBTD_PROTO_MINOR	(DRIVER_PROTO_MINOR+0)

typedef enum {
    MBTDPE_OK,
/*  the message is ready for transmission. */

    MBTDPE_UNSENDABLE,
/*
 *  the message cannot be prepared, due to a flaw in the message itself (e.g.
 *  part of the body is missing). The user will be notified of the problem and
 *  the message will be deleted.
 */

    MBTDPE_TRY_LATER,
/*
 *  the message cannot be prepared, due to a lack of resources that may
 *  become available later. The Mailbox library will retry the send at its
 *  discretion. The current connection *will* be severed before the new
 *  transmission is attempted.
 */

    MBTDPE_USER_CANCELED
/*
 *  the user canceled while the message was being prepared.  The Mailbox
 *  library will retry the send at its discretion.
 */
} MBTDPrepareError;

typedef struct {		/* CHECKME */
    MediumType	    	    MBTDMMA_medium;
    word	    	    MBTDMMA_unit;
    MediumUnitType	    MBTDMMA_unitType;
    MailboxTransportOption  MBTDMMA_transOption;
    word		    MBTDMMA_transAddrLen;
    void		    *MBTDMMA_transAddr;
} MBTDMediumMapArgs;

typedef struct {		/* CHECKME */
    MediumType	MBTDGMPA_medium;
    optr	MBTDGMPA_monikers;
    optr	MBTDGMPA_verb;
    optr	MBTDGMPA_abbrev;
    word	MBTDGMPA_significantAddrBytes;
/*
 *  The number of bytes of a message's transport address that should be
 *  compared when checking to see if a message can be sent via an established
 *  connection, or if two messages have the same address, or things like that.
 */

#define MBTD_ALL_BYTES_SIGNIFICANT	0xffff
/*
 * use in MBTDGMPA_significantAddressBytes if all bytes of an address are
 * significant
 */

} MBTDGetMediumParamsArgs;


/* enum MailboxTransportDriverFunction */
typedef enum {		/* CHECKME */

    DR_MBTD_GET_ADDRESS_CONTROLLER = 8,
/*
 * 	Desc:	Retrieves the object class of the controller object by means
 * 		of which the user selects the destination for a message.
 * 		The driver is told the medium by means of which the message
 * 		will travel. If the different media require different address
 * 		controllers, the driver can use this token to determine which
 * 		controller to return.
 * 
 * 	Pass:	cxdx	= MediumType
 * 		ax	= MailboxTransportOption
 * 	Return:	cx:dx	= Class pointer for subclass of MailboxAddressControl
 * 			= 0 if no address needed for selected medium.
 */

    DR_MBTD_PREPARE_FOR_TRANSPORT = 10,
/*
 * 	Desc:	Signals the driver that a message is going to be sent. The
 * 		driver should take whatever action is necessary to prepare
 * 		the message to be sent out. This function exists for the Fax
 * 		transport driver to convert the fax from a graphics string to
 * 		the appropriately-encoded fax image file.
 * 
 * 		The Mailbox library will call the driver on a thread dedicated
 * 		to sending the batch of messages that it is attempting to
 * 		send, so the driver need have no worries about blocking
 * 		for extended periods of time.
 * 
 * 		The driver can record the results of its preparation either
 * 		using the message's transData or using MailboxSetTransAddr to
 * 		adjust the non-significant bytes of the indicated transport
 * 		address.
 * 
 * 		This function will always be called once for each address
 * 		about to be transmitted to before DR_MBTD_CONNECT.
 * 
 * 	Pass:	cxdx	= MailboxMessage
 * 		ax	= address #
 * 	Return:	ax	= MBTDPrepareError
 * 		carry clear if it's ok for the message to be sent
 * 		carry set if the message cannot be sent now.
 */

    DR_MBTD_DONE_WITH_TRANSPORT = 12,
/*
 * 	Desc:	Signals the driver that a message is done being sent for
 * 		now. If the driver allocated any resources for transmitting
 * 		the thing, it can free them now, safe in the knowledge that the
 * 		message won't be transmitted again unless it gets re-queued.
 * 
 * 		NOTE: It is possible to receive this call for a message for
 * 		which you've never received a PREPARE_FOR_TRANSPORT. You
 * 		must be able to handle this.
 * 
 * 		NOTE: None of the following functions may be called from this
 * 		routine: MailboxGetRemainingMessages, MailboxGetRemaining-
 * 		Destinations, MailboxGetCancelFlag, MailboxReportProgress,
 * 		MailboxSetCancelAction, MailboxRegisterReceiptThread,
 * 		MailboxUnregisterReceiptThread. Calling any of them will
 * 		yield internal deadlock.
 * 
 * 	Pass:	cxdx	= MailboxMessage
 * 	Return:	nothing
 */

    DR_MBTD_CONNECT = 14,
/*
 * 	Desc:	Asks the driver to create a connection to the indicated address.
 * 		The address is taken from a message in the outbox. The Mailbox
 * 		library will call the driver on a thread dedicated to sending
 * 		the batch of messages that it is attempting to send, so the
 * 		driver need have no worries about blocking for extended
 * 		periods of time.
 * 
 * 		Upon successful connection, the driver is expected to allocate
 * 		state information for the connection and return a suitable
 * 		16-bit token that can be used in future calls to refer to the
 * 		connection.
 * 
 * 		Before returning success, the driver is expected to notify
 * 		the Mailbox library that the connection is viable. The one
 * 		exception to this is when the transport driver knows that
 * 		some other entity that it is using to establish the connection
 * 		will be notifying the library.
 * 
 * 		Note: if the medium required for the transmission is not
 * 		available, the driver is responsible for prompting the user
 * 		to make it available.
 * 
 * 	Pass:	cx:dx	= pointer to transport address
 * 		bx	= address size
 * 		ax	= MailboxTransportOption
 * 	Return:	carry set if connection couldn't be established:
 * 			^lax:si	= reason for failure
 * 		carry clear if connection established:
 * 			si	= connection handle
 */

    DR_MBTD_TRANSMIT_MESSAGE = 16,
/*
 * 	Desc:	Transmit a message. The Mailbox library will call the driver
 * 		on a thread dedicated to sending the batch of messages that it
 * 		is attempting to send, so the driver need have no worries about
 * 		blocking for extended periods of time.
 * 
 * 		If a message has duplicate addresses, when compared up to the
 * 		number of significant bytes specified by the driver, the
 * 		Mailbox library will issue one DR_MBTD_TRANSMIT_MESSAGE call
 * 		for each such address.
 * 
 * 	Pass:	cxdx	= MailboxMessage
 * 		ax	= address number
 * 		si	= connection handle returned by DR_MBTD_CONNECT
 * 	Return:	carry set if message could not be sent:
 * 			^lcx:dx	= reason for failure
 * 			ax[14..0] = MailboxError (ME_USER_CANCELED,
 * 				  ME_LOST_CONNECTION)
 * 			ax[15] set if error is a permanent error.
 * 		carry clear if message sent
 * 			ax, cx, dx = destroyed
 */

    DR_MBTD_END_CONNECT = 18,
/*
 * 	Desc:	Close down a connection. If the driver is also receiving
 * 		messages, it will need to have established a reference to itself
 * 		(usually by spawning a thread) as the driver may be unloaded
 * 		at any time after this call returns. (The unloading is done
 * 		via GeodeFreeDriver, which unloads something only if there are
 * 		no more references to it.)
 * 
 * 	Pass:	si	= connection handle returned by DR_MBTD_CONNECT
 * 	Return:	nothing
 */

    DR_MBTD_CHOOSE_FORMAT = 20,
/*
 * 	Desc:	For those transport drivers that wish only to send certain
 * 		data formats, this function gives them a say in how the
 * 		application produces the body of a message. Those drivers
 * 		that use the generic read/write interface of the data
 * 		driver should simply select the first format from the
 * 		passed array.
 * 
 * 	Pass:	cx:dx	= pointer to array of MailboxDataFormat tokens
 * 		bx	= number of formats from which to choose
 * 	Return:	ax	= index of format to use, or -1 if none of the formats
 * 			  is acceptable. (Use zero-origin index.)
 */

#define MBTD_NO_ACCEPTABLE_FORMAT   (-1)

    DR_MBTD_CHECK_MEDIUM = 22,
/*
 * 	Desc:	Determine if the transport driver uses the passed medium to
 * 		transmit messages.
 * 
 * 	Pass:	cxdx	= MediumType
 * 		ax	= MailboxTransportOption (zero-based index).
 * 	Return:	carry set if the transport option of this driver employs 
 * 			the passed medium
 * 		carry clear if the transport option does *not* support
 * 			the passed medium
 */

    DR_MBTD_GET_MAX_ADDRESS_SIZE = 24,
/*
 * 	Desc:	Fetch the number of bytes in the largest address used by
 * 		the transport driver for the given medium.
 * 
 * 	Pass:	cxdx	= MediumType
 * 		ax	= MailboxTransportOption
 * 	Return:	ax	= # bytes
 */

    DR_MBTD_CHECK_MEDIUM_CONNECTION = 26,
/*
 * 	Desc:	Determine if a connection over a particular medium can be used
 * 		by the transport driver, and if so, what the address of the
 * 		connected machine is (for purposes of comparison with
 * 		registered messages in the outbox destined for this driver)
 * 
 * 	Pass:	cx:dx	= pointer to MBTDMediumMapArgs
 * 			  MBTDMMA_medium, MBTDMMA_unit, MBTDMMA_unitType
 * 			  	set for the medium
 * 			  MBTDMMA_transAddr pointing to as many bytes as
 * 				were indicated as necessary by previous call
 * 				to DR_MBTD_GET_MAX_ADDRESS_SIZE
 * 				(MBTDMMA_transAddrLen set to this value)
 * 	Return:	carry set if the transport driver can use the connection:
 * 			*cx:dx.MBTDMMA_transAddr filled in
 * 			cx:dx.MBTDMMA_transAddrLen set to actual address length
 * 		carry clear if transport driver can *not* use the connection.
 */

    DR_MBTD_GET_ADDRESS_MEDIUM = 28,
/*
 * 	Desc:	Determine the medium and unit encoded in a particular address.
 * 
 * 	Pass:	cx:dx	= pointer to MBTDMediumMapArgs
 * 			  MBTDMMA_transAddr points to address from a message
 * 			  MBTDMMA_transAddrLen holds the size of the address
 * 			  MBTDMMA_transOption holds the transport option
 * 	Return:	carry set if the address is invalid
 * 		carry clear if address is valid:
 * 			cx:dx.MBTDMMA_medium, MBTDMMA_unit, and
 * 			MBTDMMA_unitType filled in. unitType may be MMUT_ANY
 * 			to indicate any unit of the medium can be used to
 * 			transmit the message
 */

    DR_MBTD_GET_MEDIUM_PARAMS = 30,
/*
 * 	Desc:	Fetches the monikers and verb for how a message is transmitted
 * 		to a particular medium through this transport driver.
 * 
 * 		The monikers are in a moniker list and are used for a variety
 * 		of lists, both in the creation and the display of queued
 * 		messages. The moniker list must have at least a VMS_TEXT
 * 		moniker, and should also contain one or more VMS_TOOL monikers
 * 		(for various display classes) for use by the MailboxSendControl
 * 		when building its tool UI (on some systems).
 * 
 * 		The verb is mixed-case and implies a message will be sent via
 * 		this transport driver using this medium. For example, a Fax
 * 		transport driver would return "Fax", while an America OnLine
 * 		Email transport driver would return "Mail".
 * 
 * 		The mixed-case form is placed within various UI gadget monikers
 * 		(for example "<Verb> All" or "<Verb> Now"). It is completely
 * 		downcased to be used in sentences ("is ready to <verb>.
 * 		Would you like to <verb> it now or later?").
 * 
 * 	Pass:	cx:dx	= MBTDGetMediumParamsArgs
 * 		ax	= MailboxTransportOption (zero-based index)
 * 	Return:	carry set on error.
 * 		carry clear if ok:
 * 			MBTDGMPA_monikers, MBTDGMPA_verb, and
 * 			MBTDGMPA_significantAddrBytes filled in
 */

    DR_MBTD_DELETE = 32,
/*
 * 	Desc:	Notifies the driver that the message is being deleted. This
 * 		allows the transport driver to clean up after itself, if it
 * 		created anything for the message during its DR_MBTD_PREPARE_-
 * 		FOR_TRANSPORT call.
 * 
 * 	Pass:	cxdx	= 32-bit transData for the message
 * 	Return:	nothing
 */

    DR_MBTD_RETRIEVE_MESSAGES = 34,
/*
 * 	Desc:	Asks the driver to do whatever it needs to connect to the
 * 		service it uses for receiving (and usually transmitting)
 * 		messages. If the driver requires additional information (like
 * 		a login name and password), it will have to prompt the user
 * 		for the information itself.
 * 
 * 		If it is capable of sending messages over the same connection,
 * 		it should notify the Mailbox library the connection exists,
 * 		when it exists. This will allow the library to piggyback
 * 		sending messages on the connection.
 * 
 * 		The call is made on a thread dedicated to the receive, so
 * 		the driver need have no worries about blocking.
 * 
 * 	Pass:	cxdx	= MediumType
 * 		ax	= MailboxTransportOption (zero-based index)
 * 	Return:	nothing
 */

    DR_MBTD_GET_TRANSPORT_OPTIONS_INFO = 36,
/*
 * 	Desc:	Returns the number of transport options available for
 * 		this transport driver.  When referring to a transport
 * 		option, use a zero-based index.
 * 	Pass:	nothing
 * 	Return: cx	= number of transport options available for this
 * 			  driver.
 */
} MailboxTransportDriverFunction;


/*------------------------------------------------------------------------------
 * 
 * 			     ESCAPE CODES
 * 
 *----------------------------------------------------------------------------*/
typedef enum {

    DR_MBTD_ESC_GET_TRANSPORT_OPTION = 0x8100,
/*
 * 	Desc:	Maps a string that has meaning to the driver into a transport
 * 		option for the driver. Originally implemented to map from
 * 		socket domains to transport options for the socket transport
 * 		driver when a connection comes in.
 * 
 * 	Pass:	cx:dx	= null-terminated string to map
 * 	Return:	carry set if string is invalid or escape isn't supported:
 * 			ax	= destroyed
 * 		carry clear if string mapped:
 * 			ax	= MailboxTransportOption
 */

    DR_MBTD_ESC_GET_FORMATS,
/*
 * 	Desc:	Fetches the array of message body formats that are acceptable
 * 		to the driver.
 * 
 * 	Pass:	cx:dx	= buffer for MailboxDataFormat descriptors
 * 		ax	= number of MailboxDataFormat descriptors that will
 * 			  fit in the buffer
 * 	Return:	carry set if escape not supported
 * 		carry clear if escape supported:
 * 			cx:dx	= filled in as much as possible
 * 			ax	= number of formats supported. This may be
 * 				  larger than the number passed in. It's
 * 				  up to the caller to detect this and reissue
 * 				  the call with a larger buffer if it wishes
 * 				  to have a complete list.
 */

    DR_MBTD_ESC_GET_DEADLINE_EXTENSION,
/*
 * 	Desc:	Gets the deadline extension for a message after when a
 * 		transmission has just failed or been cancelled by the user.
 * 
 * 		If this escape is not supported, some system default will be
 * 		used.
 * 
 * 	Pass:	cl	= number of failures
 * 	Return:	carry set if escape not supported
 * 		carry clear if escape supported:
 * 			cl	= # minutes extension
 * 			ch	= # hours extension
 */
} MailboxTransportEscape;

#endif	/* __MBTRNSDR */
