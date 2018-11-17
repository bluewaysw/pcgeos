##############################################################################
#
#	Copyright (c) Geoworks 1997.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	GlobalPC MailLibrary
# FILE:		mailsmtp.gp
#
# AUTHOR:	Ian Porteous, October 10 1998
#
#
#
##############################################################################
#
name mailsmtp.lib

#
# Long filename: this name can displayed by GeoManager, and is used to identify
# the application for inter-application communication.
#
longname	"MailSMTP Library"
tokenchars	"masm"
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

export MAILOUTSENDMAIL
export MAILOUTOPEN
export MAILOUTLOADHEADER
export MAILOUTCLOSE
#export MAILOUTCLOSEFAST
export MAILOUTCLOSE as MAILOUTCLOSEFAST

