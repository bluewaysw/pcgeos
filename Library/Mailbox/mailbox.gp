##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	Geode Parameters
# FILE:		mailbox.gp
#
# AUTHOR:	Adam de Boor, Jun  1, 1994
#
#
# 
#
#	$Id: mailbox.gp,v 1.1 97/04/05 01:20:09 newdeal Exp $
#
##############################################################################
#
name       mailbox.lib
type       library, process, appl, single
longname   "Mailbox Library"
tokenchars "MBOX"
tokenid    0
class	   MailboxProcessClass
appobj	   MailboxApp
entry	   MailboxLibraryEntry
#
# Required heapspace
#

# This is a totally invalid heapspace figure that Don made up.

heapspace 2148

#
# Required libraries
#
library	geos
library	ui
library spool	# for PrintControlClass
#
# Resources
#
resource Resident fixed code read-only
resource ROStrings lmem data read-only shared
resource MailboxClassStructures fixed data shared read-only
resource C_Mailbox code read-only shared
resource MainThreads lmem data shared
resource ifdef OutboxFeedbackData lmem shared read-only
#
# Routines that are exported so their entry numbers can be placed in the admin
# file.
#
export	MediaNewTransport
export	InboxMessageAdded
export	MUCleanupDelayBodyDeleteCallback
export 	MUCleanupDelayedTransportNotify
export	MessageCleanup
export	OutboxMessageAdded
export	UtilNewDataDriver

#
# Object classes
#
export	MessageControlPanelClass	ifdef
export	MessageListClass		ifdef
export	MessageGlyphClass
export	MessageDetailsClass		ifdef
export	OutboxProgressClass		ifdef
export	OutboxMessageListClass		ifdef
export	OutboxSendableConfirmationClass	ifdef
export	OutboxTransportListClass	ifdef
export	OutboxControlPanelClass		ifdef
export	OutboxDetailsClass		ifdef
export	OutboxTransportMonikerSourceClass
export	OutboxTransportMenuClass
export	MailboxSendControlClass
export	MailboxSendDialogClass
export	MailboxAddressControlClass
export	MailboxApplicationClass
export	InboxMessageListClass		ifdef
export	InboxControlPanelClass		ifdef
export	InboxApplicationListClass	ifdef
export	InboxDetailsClass		ifdef
export	MailboxEMOMClass		ifdef
export	MailboxPanelTriggerClass	ifdef	# for EMOMI_classes array
export	OutboxPoofMenuClass		ifdef
export	PoofQuickMessageSendDialogClass	ifdef
export	PoofFileSendDialogClass		ifdef
export	PoofClipboardSendDialogClass	ifdef
export	MailboxSpoolAddressControlClass
export	MailboxProgressGaugeClass
export	MailboxProgressBoxClass
export	MailboxPagesClass
export	InboxTransWinCloseClass
export	OutboxConfirmationClass		ifdef
export	OutboxErrorRetryClass		ifdef

#
# Exported routines
#

# Admin module
export 	MailboxGetAdminFile

# Inbox module
export	MailboxRegisterReceiptThread
export	MailboxUnregisterReceiptThread
export	MailboxRetrieveMessages

# Main module
export	MailboxGetCancelFlag		# mainThread.asm
export	MailboxSetCancelAction		# mainThread.asm
export	MailboxReportProgress		# mainThread.asm

# Media module
export	MailboxGetFirstMediumUnit
export	MailboxCheckMediumAvailable
export	MailboxCheckMediumConnected

# Message module
export	MailboxRegisterMessage
export	MailboxGetStorageType
export	MailboxGetSubjectLMem
export	MailboxGetSubjectBlock
export	MailboxGetMessageFlags
export	MailboxGetBodyFormat
export	MailboxGetBodyRef
export	MailboxChangeBodyFormat
export	MailboxStealBody
export	MailboxDoneWithBody
export	MailboxAcknowledgeMessageReceipt
export	MailboxDeleteMessage
export	MailboxGetBodyMboxRefBlock
export	MailboxGetDestApp
export	MailboxGetStartBound
export	MailboxGetEndBound
export	MailboxGetTransData
export	MailboxSetTransData
export	MailboxGetTransOption
export	MailboxGetTransport
export	MailboxReplyToMessage

# Outbox module
export	MailboxGetTransAddr
export	MailboxSetTransAddr
export	MailboxGetNumTransAddrs
export	MailboxGetRemainingMessages
export	MailboxGetRemainingDestinations

# UI module
export	MailboxConvertToMailboxTransferItem
export	MailboxConvertToClipboardTransferItem

# Utils module
export	MAILBOXPUSHTOMAILBOXDIR
export	MAILBOXCHANGETOMAILBOXDIR
export	MailboxFreeDriver
export	MailboxLoadDataDriver
export	MailboxLoadDataDriverWithError
export	MailboxLoadTransportDriver

# VMStore module
export	MailboxGetVMFile
export	MailboxGetVMFileName
export  MailboxOpenVMFile
export 	MailboxDoneWithVMFile

#
# C Stubs
#
export	MAILBOXGETVMFILE
export  MAILBOXOPENVMFILE
export  MAILBOXGETVMFILENAME
export	MAILBOXDONEWITHVMFILE

export	MAILBOXREGISTERMESSAGE
export	MAILBOXCHANGEBODYFORMAT
export	MAILBOXGETBODYFORMAT
export	MAILBOXGETBODYREF
export	MAILBOXDONEWITHBODY
export	MAILBOXSTEALBODY
export	MAILBOXGETMESSAGEFLAGS
export	MAILBOXGETSUBJECTLMEM
export	MAILBOXGETSUBJECTBLOCK
export	MAILBOXACKNOWLEDGEMESSAGERECEIPT
export	MAILBOXGETDESTAPP
export	MAILBOXGETSTORAGETYPE
export	MAILBOXSETTRANSADDR
export	MAILBOXGETTRANSADDR
export	MAILBOXGETNUMTRANSADDRS
export	MAILBOXREPORTPROGRESS
export	MAILBOXGETCANCELFLAG
export 	MAILBOXGETTRANSDATA
export 	MAILBOXSETTRANSDATA
export 	MAILBOXGETBODYMBOXREFBLOCK
export MAILBOXGETSTARTBOUND
export MAILBOXGETENDBOUND
export MAILBOXDELETEMESSAGE

export	MAILBOXCHECKMEDIUMAVAILABLE
export	MAILBOXCHECKMEDIUMCONNECTED
export  MAILBOXGETFIRSTMEDIUMUNIT

export	MAILBOXSETCANCELACTION

export	MAILBOXLOADTRANSPORTDRIVER
export	MAILBOXLOADDATADRIVER
export	MAILBOXLOADDATADRIVERWITHERROR
export	MAILBOXFREEDRIVER

export	MAILBOXCONVERTTOMAILBOXTRANSFERITEM
export	MAILBOXCONVERTTOCLIPBOARDTRANSFERITEM

#
# Move when next we're willing to change the major number
#
export  MAILBOXGETADMINFILE
export	MailboxOutboxControlClass
export	OutboxControlMessageListClass
export	MailboxGetUserTransAddrLMem
export	OutboxFeedbackNoteClass 	ifdef
export	MAILBOXGETUSERTRANSADDRLMEM
export	OutboxFeedbackGlyphClass	ifdef

incminor

export	MailboxBodyReformatted
export	MAILBOXBODYREFORMATTED

incminor

export	MAILBOXGETREMAININGMESSAGES
export	MAILBOXGETREMAININGDESTINATIONS

export	OutboxControlHeaderViewClass	ifdef
export	OutboxControlHeaderGlyphClass	ifdef

export	MTNotifyFirstLoad
