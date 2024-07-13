##############################################################################
#
#	(c) Copyright Geoworks 1995 -- All Rights Reserved
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	PC GEOS (Network Extensions)
# MODULE:	TELNET library
# FILE:		telnet.gp
#
# AUTHOR:	Simon Auyeung, Jul 19, 1995
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#	simon	7/19/95		Initial version.
#
# 
#
#	$Id: telnet.gp,v 1.1 97/04/07 11:16:17 newdeal Exp $
#
##############################################################################
#
# Specify the geode's permanent name
#
name	telnet.lib
#
# Specify the type of geode
#
type library, single, discardable-dgroup

#
# Define the library entry point
#
entry	TelnetEntry

#
# Import definitions from the kernel
#
library geos
library	ui
library	socket

#
# Desktop-related things
#
longname        "Telnet Library"
tokenchars      "TELN"
tokenid         0

#
# Code resources
#
resource	InitExitCode	code read-only shared
resource	ApiCode		code read-only shared
resource	UtilsCode	code read-only shared
resource	CommonCode	code read-only shared
resource	ECCode		code read-only shared

#
# Other resources
#
resource	TelnetControl	shared lmem
resource	Strings		shared lmem

#
# Exported routines
#
export	TelnetCreate
export	TelnetConnect
export	TelnetClose
export	TelnetSend
export	TelnetRecv
export	TelnetSendCommand
export	TelnetSetStatus
export	TelnetInterrupt
export	ECCheckTelnetError
