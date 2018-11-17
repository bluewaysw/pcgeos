##############################################################################
#
#	Copyright (c) Designs in Light 2002.  All rights reserved.
#
# PROJECT:	Nail
# FILE:		bbxmail.gp
#

#
#
##############################################################################
#
name bbxmlib.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"BBX Mail Library"
tokenchars	"bbxm"
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
export MAILB64ENCODEPTR
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

export MAILINOPEN
export MAILINGETMESSAGECOUNT
export MAILINGETMESSAGESIZE
export MAILINGETMESSAGE
export MAILINMESSAGEDELETE
export MAILINCLOSE
export MAILINCLOSE as MAILINCLOSEFAST
export MAILINGETUIDL

export MAILOUTSENDMAIL
export MAILOUTOPEN
export MAILOUTLOADHEADER
export MAILOUTCLOSE
