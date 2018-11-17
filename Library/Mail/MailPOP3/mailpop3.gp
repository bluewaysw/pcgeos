##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	GlobalPC MailLibrary
# FILE:		mailpop3.gp
#
# AUTHOR:	Ian Porteous, October 10 1998
#
#
#
##############################################################################
#
name mailpop3.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"MailPOP3 Library"
tokenchars	"map3"
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
library ansic
library socket
library mailhub

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources do not need to be mentioned).
#

#
# Export classes. For all protocol classes, the first thing to export *MUST*
# be the protocol classname.
#

export MAILINOPEN
export MAILINGETMESSAGECOUNT
export MAILINGETMESSAGESIZE
export MAILINGETMESSAGE
export MAILINMESSAGEDELETE
export MAILINCLOSE
export MAILINCLOSE as MAILINCLOSEFAST
export MAILINGETUIDL
