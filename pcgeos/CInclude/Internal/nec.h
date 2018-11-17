/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  DOVE
 * MODULE:	  DOVE
 * FILE:	  nec.h
 *
 * AUTHOR:  	  Brian Chin: Nov 13, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	brianc	11/13/96   	Initial version
 *
 * DESCRIPTION:
 *
 *	Definitions exclusively for use on Dove.
 *
 * 	$Id: nec.h,v 1.1 97/04/04 15:54:10 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _NEC_H_
#define _NEC_H_

/*
 * ManufacturerID for NEC Telecom Systems, Ltd. in Japan
 */
#define MANUFACTURER_ID_NEC 16467

/*
 * NEC System GCN Lists
 */

typedef enum /* word, increment by 2 */ {

    NECGCNSLT_NOTIFY_SECRET_MODE_CHANGE	= 0x0000,
	/*
	 *	A list for objects which care to know when the "secret
	 *	mode" status has changed.
	 *
	 *	Notification types:	NECNT_SECRET_MODE_CHANGE
	 */

} NECGCNStandardListType;


/*
 * Dove Notification types, send via MSG_META_NOTIFY and
 * MSG_META_NOTIFY_WITH_DATA_BLOCK.
 */

typedef enum /* word */ {

    NECNT_SECRET_MODE_CHANGE,
	/*
	 * 	Sent to the GCN list NECGCNLT_NOTIFY_SECRET_MODE_CHANGE
	 *	whenever the "secret mode" status changes.
	 *
	 *	Pass: TRUE/FALSE (on/off)
	 */

    NECNT_FLOATING_KBD_STATE_CHANGE,
	/*
	 * 	Sent to the GCN list NECGAGCNLT_FLOATING_KBD_STATE_CHANGE
	 *	when the floating kbd state for this application changes.
	 *
	 *	Pass: FloatingKbdFlags
	 */

    NECNT_TEXT_INK_MODE_CHANGE,
	/*
	 * 	Sent to the GCN list NECGCNALT_TEXT_INK_MODE_CHANGE
	 *	whenever the MemoDocumentClass object changes mode and
	 *	when it gains or loses the focus.
	 *
	 *	Pass: TextInkMode
	 */


/*
 * Notification to transfer DialInfo block between two objects.  It is
 * currently used by Telephone and MemoFax to retrieve dialing
 * information from Addressbook.
 */

    NECNT_DIAL_INFO_REQUEST,
	/*
	 *	The sender of this message requires a DialInfo block,
	 *	so the receiver of this message should respond with an
	 *	NECNT_DIAL_INFO_REPLY notification.
	 *
	 *	Besure that the block containing DialInfoRequest
	 *	is "sharable" and initialized with MemInitRefCount.
	 *	Read description of MSG_META_NOTIFY_WITH_DATA_BLOCK
	 *	for further details (metaC.def).
	 *
	 *	Pass: MemHandle of DialInfoRequest
	 */

    NECNT_DIAL_INFO_REPLY,
	/*
	 *	Sent as a response to NECNT_DIAL_INFO_REQUEST.  The
	 *	destiantion should be the optr passed in
	 *	DialInfoRequestParams.
	 *
	 *	Besure that the block containing DialInfoReply
	 *	is "sharable" and initialized with MemInitRefCount.
	 *	Read description of MSG_META_NOTIFY_WITH_DATA_BLOCK
	 *	for further details (metaC.def).
	 *
	 *	Pass: MemHandle of DialInfoReply
	 */


} NECNotificationType;


/*
 * Constants and types for DialInfo transfer.
 */

#define MAX_DIAL_INFO_NAME_LEN		20
	/*
	 * Length of the name, returned in DialInfoReply block.  
	 */

#define MAX_DIAL_INFO_COMPANY_LEN	60
	/*
	 * Length of the company name, returned in DialInfoReply block.  
	 */

#define MAX_DIAL_INFO_TELNUM_LEN	24
	/*
	 * Length of telephone number.  The numbers are returned as a
	 * string.
	 */

typedef ByteEnum VoiceNumberType;
/*
 *	Designates the voice number to retrieve.
 */
#define VNT_NONE	0x00
#define VNT_HOME	0x01
#define	VNT_WORK_ONE	0x02
#define	VNT_WORK_TWO	0x03
#define	VNT_CELLULAR	0x04

typedef ByteFlags DialNumberFlags;
#define DNF_DATA	0x80
	/*
	 * Set if want to retrieve the data (fax) number.
	 */
#define DNF_VOICE	0x7f	/* VoiceNumberType */
	/*
	 * Designate the voice number to retrieve.
	 */
#define DNF_VOICE_OFFSET	7

/*
 * Structure sent along with NECNT_DIAL_INFO_REQUEST notification.
 */
typedef struct {
        GeodeToken      DIR_recvToken;
	/*
	 *	Token of application which the reply should be sent
	 *	to.  This way, the calling application could be awoken
	 *	if necessary.
	 */
	DialNumberFlags	DIR_requestFlags;
	/*
	 *	Designate which number to retrieve.  This should
	 *	determine the value in DIR_number.
	 */
	optr 		DIR_recvOD;
	/*
	 *	Object to receive the DialInfoReply block sent via
	 *	NECNT_SEND_DIAL_REPLY.
	 */
} DialInfoRequest;

/*
 * Structure sent along with NECNT_DIAL_INFO_REPLY notification.
 */
typedef struct {
	DialNumberFlags	DIR_replyFlags;
	/*
	 *	Designate whether the DIR_data field is filled and
	 *	which number is stored in DIR_voice.
	 */
	TCHAR		DIR_name[MAX_DIAL_INFO_NAME_LEN+1];
	/*
	 *	This is always filled with the requested person's
	 *	name.
	 */
	TCHAR		DIR_company[MAX_DIAL_INFO_COMPANY_LEN+1];
	/*
	 *	This is always filled with the company name of the
	 *	requested person.
	 */
	TCHAR		DIR_data[MAX_DIAL_INFO_TELNUM_LEN+1];
	/*
	 *	Data-number string, usually fax.
	 */
	TCHAR		DIR_voice[MAX_DIAL_INFO_TELNUM_LEN+1];
	/*
	 *	Voice-number string.
	 */
} DialInfoReply;



/*
 * NEC GenApplication GCN Lists
 */

typedef enum /* word, increment by 2 */ {

    NECGAGCNLT_FLOATING_KBD_STATE_CHANGE = 0x0000,
	/*
	 * 	A list for objects which make and remove space for the
	 *	floating keyboard.
	 *
	 *	Notification types:	NECNT_FLOATING_KBD_STATE_CHANGE
	 */

    NECGACNLT_TEXT_INK_MODE_CHANGE = 0x0002,
	/*
	 *	A list for objects which care to know when a
	 *	MemoDocumentClass object changes mode.
	 *
	 *	Notification types:	NECNT_TEXT_INK_MODE_CHANGE
	 */

} NECGAGCNListType;

#endif /* _NEC_H_ */
