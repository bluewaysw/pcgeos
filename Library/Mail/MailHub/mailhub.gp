##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	GlobalPC MailLibrary
# FILE:		mailhub.gp
#
# AUTHOR:	Ian Porteous, October 10 1998
#
#
#
##############################################################################
#
name mailhub.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"MailHub Library"
tokenchars	"mahl"
tokenid		0

#
# Specify geode type: is a library
#
type	library, single, c-api

#
# Define the library entry point
#

#
# Libraries: list which libraries are used by the application.
#
library	geos
library socket
library ansic

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#
resource STRINGS   lmem shared read-only

#
# Export classes. For all protocol classes, the first thing to export *MUST*
# be the protocol classname.
#

export MAILSOCKETCONNECT
export MAILQPENCODEPTR
export MAILQPDECODEPTR
export MAILPUTBASE64ENCODED
export MAILGETRETURNDATA
export MAILMESSAGEINIT
export MAILGETHDRVALUE
export MAILGETHDRVALUE822
export MAILMESSAGECLOSE
export MAILMESSAGEGETHDRVALUE
export MAILB64DECODEPTR
export MAILUUDECODEPTR
export MAILPARSEADDRESSSTRING
export MAILADDACCOUNT
export MAILLOCKSTDSTRING
export MAILUNLOCKSTDSTRING
export MAILDELETEACCOUNT
export MAILSENDNOTIFICATION
export MAILDELETEACCOUNTWITHPASSWORD
export MAILCHANGEACCOUNTPASSWORD
export MAILVERIFYACCOUNTPASSWORD
export MAILCHANGEACCOUNTINFO
