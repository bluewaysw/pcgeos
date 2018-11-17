##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Term
# FILE:		term.gp
#
# AUTHOR:	Dennis, 11/89
#
#
# Parameters file for: term.geo
#
#	$Id: term.gp,v 1.2 97/07/02 12:33:08 newdeal Exp $
#
##############################################################################
#
# Permanent name
#
#
# DOVE note:  The app names may have to be localized 
#
#
ifdef	TELNET
	name	gtelnet.app
else
	name 	term.app
endif	# TELNET

#
# Long name
#

ifdef	TELNET
	longname "Telnet"
else
			longname "GeoComm"
endif	# TELNET


#
# Token information
#
ifdef	TELNET
	tokenchars "TELT"
else
	tokenchars "TERM"
endif	# TELNET
	
tokenid 0
#
# Specify geode type
#
type	appl, process

#
# Specify class name for process
#
class	TermClass
#
# Specify application object
#
appobj	MyApp
#
# Import kernel routine definitions
#
library	geos
library	ui
library text



heapspace 15368		#Includes 22K scroll buffer
#
# Define resources other than standard discardable code
#
resource TermClassStructures read-only fixed shared

resource Fixed fixed code read-only shared
resource InterfaceAppl ui-object
resource PrimaryInterface ui-object
resource MenuInterface ui-object
resource Interface ui-object
ifndef	TELNET
resource ModemUI ui-object
endif	# !TELNET

resource LineStatUI ui-object
resource RecvXModemStatusUI ui-object
resource RecvAsciiStatusUI ui-object
resource SendStatusUI ui-object
resource ProtocolUI ui-object
resource TermTypeUI ui-object
resource TransferUI ui-object
resource CaptureUI ui-object
resource ScriptUI ui-object

resource TermUI object
resource Strings lmem shared read-only

resource AppLCMonikerResource lmem shared read-only
resource AppLMMonikerResource lmem shared read-only
resource AppSCMonikerResource lmem shared read-only
resource AppSMMonikerResource lmem shared read-only
resource AppYCMonikerResource lmem shared read-only
resource AppYMMonikerResource lmem shared read-only
resource AppSCGAMonikerResource lmem shared read-only



#
# Define exported routines
#
export	ScreenClass
export  TermApplicationClass


	export	ProtocolInteractionClass


export	TermTimedDialogClass

#
# this class is used whenever _ACCESS_POINT is true, but we don't have
# that variable here, and currently it is only true for responder.
#




