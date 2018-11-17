COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		strings
FILE:		uiStrings.asm

AUTHOR:		Adam de Boor, Apr 11, 1994

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/11/94		Initial revision


DESCRIPTION:
	Random strings used throughout the library.

	$Id: uiStrings.asm,v 1.1 97/04/05 01:19:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ROStrings	segment	lmem, LMEM_TYPE_GENERAL

;----------------------------------------
;
;	Driver tokens & directories
;
;----------------------------------------
LocalDefString	uiDataDriverDir, <"MBDATA", 0>
	localize	"The name of the directory under SYSTEM that holds data drivers for the Mailbox library to use", 1, FILE_LONGNAME_LENGTH

uiDataDriverToken	chunk.GeodeToken <
	<'MBDD'>,
	MANUFACTURER_ID_GEOWORKS
>
	localize	not


LocalDefString	uiTransDriverDir, <"MBTRANS", 0>
	localize	"The name of the directory under SYSTEM that holds transport drivers for the Mailbox library to use", 1, FILE_LONGNAME_LENGTH

uiTransDriverToken	chunk.GeodeToken <
	<'MBTD'>,
	MANUFACTURER_ID_GEOWORKS
>
	localize	not

;----------------------------------------
;
;	Spool directory stuff
;
;----------------------------------------
LocalDefString	uiMailboxDir, <"MAILBOX", 0>
	localize	"The name of the directory under PRIVDATA\SPOOL that holds message bodies and the administrative file.", 1, FILE_LONGNAME_LENGTH

LocalDefString	uiAdminFileName, <"Mbox Admin File", 0>
	localize	"The name of the administrative file that holds all the message descriptors for the inbox and the outbox, along with various maps and data structures describing the communication environment of the machine.", 1, FILE_LONGNAME_LENGTH

LocalDefString	uiMessagesNameTemplate, <"Messages \1", 0>
	localize	"The template for the files that hold message bodies. @1 is where a number is placed.", 1, FILE_LONGNAME_LENGTH-1 ; assume no more than 2 digits...

;----------------------------------------
;
;	Message moniker creation
;
;----------------------------------------
LocalDefString	uiTransportSeparatorString, <": ", 0>
	localize	"This is placed between the transport mechanism (e.g. 'Fax' or 'Beam') and the subject of an outgoing message when the outbox control panel is displaying all messages in the outbox"

SBCS <	LocalDefString	uiConnectingString, <"Connecting", C_ELLIPSIS, 0>>
DBCS <	LocalDefString	uiConnectingString, <"Connecting", C_MIDLINE_HORIZONTAL_ELLIPSIS, 0>>
	localize	"The string used in an outbox progress box when the transmit thread is attempting to connect to an address after files have been prepared."

LocalDefString	uiPreparingString, <"Preparing:", 0>
	localize	"The string used in an outbox progress box when the transmit thread is preparing a message for transmission. The string appears in the subject field of a message moniker, with the subject itself following in the destination field on the next line."

LocalDefString	uiQueuedString, <"Queued", 0>

LocalDefString	uiPreparingStateString, <"Preparing", 0>

LocalDefString	uiReadyString, <"Ready", 0>

LocalDefString	uiSendingString, <"Sending", 0>

;
; MMDrawStatus makes these assumptions for optimizations.
;
	ForceRef	uiPreparingStateString
	ForceRef	uiReadyString
	ForceRef	uiSendingString
.assert	offset uiPreparingStateString eq offset uiQueuedString + \
		(MAS_PREPARING - MAS_QUEUED) * size lptr
.assert	offset uiReadyString eq offset uiQueuedString + \
		(MAS_READY - MAS_QUEUED) * size lptr
.assert	offset uiSendingString eq offset uiQueuedString + \
		(MAS_SENDING - MAS_QUEUED) * size lptr

SBCS <	LocalDefString	uiLostConnectionString, <"Lost Connection To", C_ELLIPSIS, 0>>
DBCS <	LocalDefString	uiLostConnectionString, <"Lost Connection To", C_MIDLINE_HORIZONTAL_ELLIPSIS, 0>>
	localize	"The string used in the box that asks the user whether the connection should be retried if it is lost during transmission. The string appears in the subject field of a message moniker, with a single address following in the destination field on the next line."

LocalDefString 	uiShortDateSeparator, <" ", 0>
	localize	"The string placed between the short date and the time for places that use short dates. For example, in a message list, the typical timestamp will be '4/21 2:51 pm'", 0, MAILBOX_MAX_DATE_SEPARATOR

LocalDefString 	uiLongDateSeparator, <" at ", 0>
	localize	"The string placed between the long date and the time for places that use long dates. For example, in a message detail box, the typical timestamp will be 'April 21st, 1994 at 2:51 pm'", 0, MAILBOX_MAX_DATE_SEPARATOR

LocalDefString	uiNow, <"Now", 0>
	localize	"The string used when no starting time bound is set for a message.", 0, DATE_TIME_BUFFER_SIZE/(size TCHAR)

LocalDefString uiAnd, <" and ", 0>
	localize	"The string placed between the starting time bound and the ending time bound of a message."

LocalDefString	uiEternity, <"Eternity", 0>
	localize	"The string used when no ending time bound is set for a message.", 0, DATE_TIME_BUFFER_SIZE/(size TCHAR)

LocalDefString	uiRetry, <"Retry", 0>
	localize	"The string preceding the 24-hour retry time of a message in the responder outbox control.", 0, DATE_TIME_BUFFER_SIZE

LocalDefString	uiSend, <"At", 0>
	localize	"The string preceding the 24-hour send time of a message in the responder outbox control.", 0, DATE_TIME_BUFFER_SIZE

LocalDefString	uiUponRequest, <"Upon request", 0>
	localize	"The string used when a message is not scheduled for automatic retry, but instead the user must do something to cause it to be sent. Always used when email is sent with the 'on demand' setting.", 0, DATE_TIME_BUFFER_SIZE

LocalDefString	uiWaitingString, <"Waiting", 0>
	localize	"The string used when a message isn't waiting for a specific time to be sent, but can go whenever the medium becomes available.", 0, DATE_TIME_BUFFER_SIZE

uiAllMoniker	chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		0			; VMT_mnemonicOffset
	>
	LocalDefNLString <"All", 0>
uiAllMoniker	endc
	localize	"The string used as the last entry in the popup list for the system inbox and outbox panels. The entry allows the user to view all the messages in the respective box."

LocalDefString	uiToDestinationStr, <"To: ", 0>
	localize	"The string that precedes an address in the destination field of a message moniker for a message that's in the outbox."

;----------------------------------------
;
;	Reason strings
;
;----------------------------------------
LocalDefString	uiNoReasonString, <"Not Attempted", 0>
	localize	"The string used in the Reason for Last Failure detail for an outgoing message when it's never tried to be sent."


LocalDefString	uiMessageUnsendable, <"The message cannot be sent because its body is either corrupt or cannot be found.", 0>

LocalDefString	uiNotEnoughDiskSpace, <"There is not enough storage space to prepare the message for transmission. Please free up space and try the transmission again.", 0>

LocalDefString	uiConnectErrorNoMem, <"There is not enough memory to make the connection. Please try again later.", 0>

LocalDefString	uiUserCanceled, <"Canceled", 0>

LocalDefString uiCouldntPrepareReason, <"Unable to prepare message", 0>
	localize	"Reason string bound to messages when the transport driver is unable to prepare them for transmission."

LocalDefString uiCannotLoadDriverStr, <"Unable to load transport driver", 0>
	localize	"Reason string bound to messages when the transport driver could not be loaded."

if	_CONFIRM_AFTER_FIRST_FAILURE or _OUTBOX_FEEDBACK
LocalDefString uiOutboxSendingAnotherDocument, <"Outbox sending another document", 0>
	localize	"Reason string bound to a message when the message is queued for the first time and the transmission thread already has a message queued for it, meaning the message just queued may have to wait a bit."
endif	; _CONFIRM_AFTER_FIRST_FAILURE or _OUTBOX_FEEDBACK

if	_OUTBOX_SEND_WITHOUT_QUERY
LocalDefString uiSentUponRequestStr, <"Message will be sent upon request", 0>
	localize	"Reason string bound to a message when the message has been queued with priority 3d class, meaning it shouldn't be sent right away but should wait until the user asks that all such messages be sent. In Responder, this is effected by changing the setting in the Mail settings box available when selecting the recipients."
endif	; _OUTBOX_SEND_WITHOUT_QUERY

LocalDefString uiMediumNotAvailableStr, <"Transmission medium not available", 0>
	localize	"Reason string bound to a message when the message cannot be immediately sent because the medium needed to transmit the thing isn't available"


LocalDefString uiMediumBusyStr, <"Transmission medium in use", 0>
	localize	"Reason string bound to a message when the message cannot be immediately sent because the medium needed to transmit the thing is being used for some other purpose"

LocalDefString uiNotTimeForTransmissionStr, <"Transmit time not reached", 0>
	localize	"Reason string bound to a message when the message cannot be immediately sent because the first time at which it could be sent has not yet arrived."


;----------------------------------------
;
;	Application list strings
;
;----------------------------------------
LocalDefString	uiUnknownApp, <"Unknown Application", 0>
LocalDefString	uiMboxApp, <"System", 0>

;----------------------------------------
;
;	Express menu moniker components
;
;----------------------------------------

if	_CONTROL_PANELS
uiEmptyOutGraphic       chunk
	Bitmap	<BOX_GRAPHIC_WIDTH, BOX_GRAPHIC_HEIGHT>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000001b, 10000000b
	byte	00000011b, 11000000b
	byte	00000001b, 10000000b
	byte	00100001b, 10000100b
	byte	00100000b, 00000100b
	byte	00100000b, 00000100b
	byte	00100000b, 00000100b
	byte	00111111b, 11111100b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
uiEmptyOutGraphic       endc

uiFullOutGraphic        chunk
	Bitmap	<BOX_GRAPHIC_WIDTH, BOX_GRAPHIC_HEIGHT>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
        byte    00000001b, 10000000b
	byte	00000011b, 11000000b
	byte	00000001b, 10000000b
	byte	00000001b, 10000000b
	byte	00000000b, 00000000b
	byte	00100111b, 11110100b
	byte	00100000b, 00000100b
	byte	00101111b, 11100100b
	byte	00100000b, 00000100b
	byte	00111111b, 11111100b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
uiFullOutGraphic	endc

if	_MAILBOX_FOR_FAX_SEND_ONLY
LocalDefString 	uiOutboxControl, <"Fax Control Panel", 0>
else
LocalDefString 	uiOutboxControl, <"Outbox", 0>
endif
	localize "The string that is combined with an amusing little graphic to form the moniker for the trigger in the express menu that brings up the control panel for the system outbox"

; this thing goes in the fixed header of the block. I didn't just forget the
; "chunk" directive...
uiOutboxParts	BoxMonikerParts <
	uiOutboxControl, uiEmptyOutGraphic, uiFullOutGraphic
>

uiEmptyInGraphic       chunk
	Bitmap	<BOX_GRAPHIC_WIDTH, BOX_GRAPHIC_HEIGHT>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000001b, 10000000b
	byte	00000001b, 10000000b
	byte	00000011b, 11000000b
	byte	00100001b, 10000100b
	byte	00100000b, 00000100b
	byte	00100000b, 00000100b
	byte	00100000b, 00000100b
	byte	00111111b, 11111100b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
uiEmptyInGraphic       endc

uiFullInGraphic        chunk
	Bitmap	<BOX_GRAPHIC_WIDTH, BOX_GRAPHIC_HEIGHT>
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
        byte    00000001b, 10000000b
	byte	00000001b, 10000000b
	byte	00000011b, 11000000b
	byte	00000001b, 10000000b
	byte	00000000b, 00000000b
	byte	00100111b, 11110100b
	byte	00100000b, 00000100b
	byte	00101111b, 11100100b
	byte	00100000b, 00000100b
	byte	00111111b, 11111100b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
	byte	00000000b, 00000000b
uiFullInGraphic	endc

LocalDefString 	uiInboxControl, <"Inbox", 0>
	localize "The string that is combined with an amusing little graphic to form the moniker for the trigger in the express menu that brings up the control panel for the system inbox"

; this thing goes in the fixed header of the block. I didn't just forget the
; "chunk" directive...
uiInboxParts	BoxMonikerParts <
	uiInboxControl, uiEmptyInGraphic, uiFullInGraphic
>
endif	; _CONTROL_PANELS

;----------------------------------------
;
;	Message priorities
;
;----------------------------------------
LocalDefString	uiPriorityEmergency, <"Emergency", 0>
	.warn -unref
LocalDefString	uiPriorityUrgent, <"Urgent", 0>
LocalDefString	uiPriorityFirstClass, <"First Class", 0>
LocalDefString	uiPriorityThirdClass, <"Third Class", 0>
	.warn @unref

;
; IDShowPriority makes these assumptions for optimizations.
;
.assert MMP_EMERGENCY eq 0
.assert offset uiPriorityUrgent eq offset uiPriorityEmergency \
						+ MMP_URGENT * size lptr
.assert offset uiPriorityFirstClass eq offset uiPriorityEmergency \
						+ MMP_FIRST_CLASS * size lptr
.assert offset uiPriorityThirdClass eq offset uiPriorityEmergency \
						+ MMP_THIRD_CLASS * size lptr

;----------------------------------------
;
;	Delivery verbs
;
;----------------------------------------

LocalDefString	uiVerbActiveDeliver, <"Deliver", 0>
	.warn -unref
LocalDefString	uiVerbActiveView, <"View", 0>
LocalDefString	uiVerbActivePlay, <"Play", 0>
LocalDefString	uiVerbActiveAccept, <"Accept", 0>
LocalDefString	uiVerbActiveRead, <"Read", 0>
LocalDefString	uiVerbActiveFile, <"File", 0>
	.warn @unref
LocalDefString	uiVerbPassiveDeliver, <"delivered", 0>
	.warn -unref
LocalDefString	uiVerbPassiveView, <"viewed", 0>
LocalDefString	uiVerbPassivePlay, <"played", 0>
LocalDefString	uiVerbPassiveAccept, <"accepted", 0>
LocalDefString	uiVerbPassiveRead, <"read", 0>
LocalDefString	uiVerbPassiveFile, <"filed", 0>
	.warn @unref

;
; IDGetDeliveryVerbInMessage makes these assumptions for optimizations.
;
.assert MDV_DELIVER eq 0
.assert offset uiVerbActiveView eq \
			offset uiVerbActiveDeliver + MDV_VIEW * size lptr
.assert offset uiVerbActivePlay eq \
			offset uiVerbActiveDeliver + MDV_PLAY * size lptr
.assert offset uiVerbActiveAccept eq \
			offset uiVerbActiveDeliver + MDV_ACCEPT * size lptr
.assert offset uiVerbActiveRead eq \
			offset uiVerbActiveDeliver + MDV_READ * size lptr
.assert offset uiVerbActiveFile eq \
			offset uiVerbActiveDeliver + MDV_FILE * size lptr
.assert offset uiVerbPassiveView eq \
			offset uiVerbPassiveDeliver + MDV_VIEW * size lptr
.assert offset uiVerbPassivePlay eq \
			offset uiVerbPassiveDeliver + MDV_PLAY * size lptr
.assert offset uiVerbPassiveAccept eq \
			offset uiVerbPassiveDeliver + MDV_ACCEPT * size lptr
.assert offset uiVerbPassiveRead eq \
			offset uiVerbPassiveDeliver + MDV_READ * size lptr
.assert offset uiVerbPassiveFile eq \
			offset uiVerbPassiveDeliver + MDV_FILE * size lptr


LocalDefString	uiUnavailable, <"Unavailable", 0>
	localize	"The string used whenever an application's name is unavailable. Also used in the InboxDetails box if the data driver is unable to return the size of the message body."

LocalDefString	uiMessageInvalid, <"Message invalid", 0>
	localize	"The string used in the Size field of the inbox details dialog if the data driver returns an error."

LocalDefString	uiSomeoneElse, <"Someone Else", 0>
	localize	"The default user-readable address to use if a transport driver provides no address controller."

;----------------------------------------
;
;	Error strings
;
;----------------------------------------
LocalDefString	uiNoFormatAcceptableStr, <"This application cannot create a message that is acceptable to the transport means you selected.", 0>

LocalDefString	uiCannotLoadTransportStr, <"Unable to load the transporter you selected.", 0>

;----------------------------------------
;
;	Poof message strings
;
;----------------------------------------
if	_POOF_MESSAGE_CREATION

LocalDefString	uiPoofMenuQuickMessage, <"Quick Message", 0>
	localize	"The string used in the menu item in the Poof menu for sending quick message."

LocalDefString	uiPoofMenuFile, <"File", 0>
	localize	"The string used in the menu item in the Poof menu for sending file."

LocalDefString	uiPoofMenuClipboard, <"Clipboard", 0>
	localize	"The string used in the menu item in the Poof menu for sending clipboard transfer item."

LocalDefString	uiPoofSubjectQuickMessage, <"Quick Message", 0>
	localize	"The string used in the subject line for quick messages."

LocalDefString	uiPoofSendSendError, <"An error occured while sending to Outbox.", 0>
	localize	"The error string used when there's an error in sending a poof message."

endif	; _POOF_MESSAGE_CREATION

LocalDefString	uiPoofReceiveFileConfirmOverwrite, <"The file already exists, do you want to overwrite it?", 0>
	localize	"The string used when the file being received already exists in the destination directory."

LocalDefString	uiPoofReceiveFilePatchExists, <"The patch file already exists.", 0>
	localize	"The error string used when a patch file received already exists in the system."

LocalDefString	uiPoofReceiveFilePatchError, <"An error occured while applying the patch.", 0>

LocalDefString	uiPoofReceiveFileFontError, <"An error occured while adding the new font file.", 0>
	localize	"The error string displayed when there's an error addint the new font file."

LocalDefString	uiPoofReceiveFileCopyError, <"An error occured while copying the file.", 0>
	localize	"Error string displayed when there is a file error while copying a received file."

LocalDefString	uiPoofReceiveFileRemoteOrLocal, <"The file already exists remotely.  Do you want to overwrite remote file or place it in the local tree?", 0>
	localize	"The question asking the user what to do when a newly received file exists remotely."

;----------------------------------------
;
;	Custom driver-load error strings
;
;----------------------------------------
uiDoneThatMoniker	chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		0			; VMT_mnemonicOffset
	>
	LocalDefNLString <"Done That", 0>
uiDoneThatMoniker	endc
	localize	"The moniker used for the retry trigger in the retry/abort dialog when attempting to load a storage or transport driver that's on a pcmcia card, or something similar, when the pcmcia card isn't inserted. The assumption is that the string provided by the driver asks the user to perform some action so the driver can be loaded."

uiGiveItUpMoniker	chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		0			; VMT_mnemonicOffset
	>
	LocalDefNLString <"Give It Up", 0>
uiGiveItUpMoniker	endc
	localize	"The moniker used for the abort trigger in the retry/abort dialog when attempting to load a storage or transport driver that's on a pcmcia card, or something similar, when the pcmcia card isn't inserted. The assumption is that the string provided by the driver asks the user to perform some action so the driver can be loaded."

;----------------------------------------
;
;	Progress gauge strings
;
;----------------------------------------
if 	MAILBOX_PERSISTENT_PROGRESS_BOXES
LocalDefString uiPageNTemplate, <"Page \1", 0>
	localize	"The string used in progress boxes when something is just reporting the current page, but doesn't know how many pages there are total. @1 is replaced by the page number."

LocalDefString uiPageNOfMTemplate, <"Page \1 of \2", 0>
	localize	"The string used in progress boxes when something is reporting the current page and the total number of pages. @1 is replaced by the page number, while @2 becomes the number of pages."

LocalDefString uiOneByteTemplate, <"1 byte", 0>
	localize	"The string used in progress boxes when a single byte has been received."

LocalDefString uiBytesTemplate, <"\1 bytes", 0>
	localize	"The string used in progress boxes when some number of bytes other than 1 have been received. @1 is replaced by the decimal number of bytes."
endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

;----------------------------------------
;
;	Shutdown confirmation
;
;----------------------------------------
LocalDefString uiConfirmShutdownStr, <"You are currently sending or receiving messages. Shutting the system down will abort the transmission or reception, possibly in mid-message. You should be able to restart it from the beginning later, but any work already done will have been wasted.\r\rAre you sure you still want to shut down?", 0>
	localize	"Shows up when the user attempts to exit to DOS while something is being transmitted or received."

;----------------------------------------
;
;	Responder Outbox Titles
;
;----------------------------------------
if	_RESPONDER_OUTBOX_CONTROL

LocalDefString uiRespSubjTitle, <"Doc.", 0>
	localize	"The heading for the subject of a message in the Document outbox. The subject is usually the name of the document being sent", 0, 23
	; the 23-character limit derives from the MM_RESP_SUBJECT_LENGTH
	; constant in messageConstant.def

LocalDefString uiRespDestTitle, <"To", 0>
	localize	"The heading for the destination of a message in the Document outbox.", 0, 15
	; the 15-character limit derives from the MM_DESTINATION_LENGTH
	; constant in messageConstant.def

LocalDefString uiRespTransTitle, <"By", 0>
	localize	"The heading for the transport of a message in the Document outbox.", 0, 9
	; the 9-character limit derives from the MM_TRANS_MEDIUM_ABBREV_LENGTH
	; constant in messageConstant.def

LocalDefString uiRespStateTitle, <"Status", 0>
	localize	"The heading for the status of a message in the Document outbox.", 0, 17
	; the 17-character limit derives from the MM_ADDR_STATE_LENGTH constant
	; in messageConstant.def


;
; String templates used in the Status field if progress is reported
;
LocalDefString uiRespStatusPageNTemplate, <"Sending \1", 0>
	localize	"The string used for outbox status when something is just reporting the current page, but doesn't know how many pages there are total. @1 is replaced by the page number."

LocalDefString uiRespStatusPageNOfMTemplate, <"Sending \1/\2", 0>
	localize	"The string used for outbox status when something is reporting the current page and the total number of pages. @1 is replaced by the page number, while @2 becomes the number of pages."

LocalDefString uiRespStatusOneByteTemplate, <"1 byte sent", 0>
	localize	"The string used for outbox status when a single byte has been received."

LocalDefString uiRespStatusBytesTemplate, <"\1 bytes sent", 0>
	localize	"The string used for outbox status when some number of bytes other than 1 have been received. @1 is replaced by the decimal number of bytes."

LocalDefString uiRespStatusPercentTemplate, <"\1% sent", 0>
	localize	"The string used for outbox status when some number of bytes other than 1 have been received. @1 is replaced by the percentage."
;

endif	; _RESPONDER_OUTBOX_CONTROL

LocalDefString uiConfirmDeleteStr, <"About to cancel sending operation. Are you sure?", 0>
	localize	"The string used to make sure the user wants to delete the message she has asked to delete from the outbox control."

;LocalDefString uiCannotStartString, <"\1. Send operation can't be started", 0>
LocalDefString uiCannotStartString, <"Cannot start transmission. \1.", 0>
	localize	"The template string used in telling the user why we are unable to start sending a message when she hits the Start button of the document outbox. @1 is replaced with the reason the medium isn't available."

;----------------------------------------
;
;	Responder Indicator Strings
;
;----------------------------------------

;----------------------------------------
;
;	Medium-removed honks
;
;----------------------------------------
if	_HONK_IF_MEDIUM_REMOVED
LocalDefString uiMediumRemovedHonk, <"There are messages pending for what you just removed. They cannot be sent until you put it back.", 0>
	localize	"The string that appears when you remove a pcmcia card (e.g. a fax modem) for which there are messages pending in the outbox."

endif	; _HONK_IF_MEDIUM_REMOVED

ROStrings	ends
