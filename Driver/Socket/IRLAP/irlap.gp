##############################################################################
#
#	Copyright (c) GeoWorks 1994 -- All Rights Reserved
#
# PROJECT:	
# FILE:		irlap.gp
#
# AUTHOR:	Cody Kwok, Mar 21, 1994
#
#	$Id: irlap.gp,v 1.1 97/04/18 11:57:00 newdeal Exp $	
#
##############################################################################
#
# permanent name
#
name 	irlap.drv
#
# Specify geode type
#
ifdef GP_FULL_EXECUTE_IN_PLACE
type	driver, single, discardable-dgroup
else
type	driver, single
endif

#
# Import kernel routine definitions
#
library	geos 
library netutils
library ui

ifdef _SOCKET_INTERFACE
library socket 
endif

driver serial


#
# Desktop-related things
#
longname	"IRLAP Driver"
tokenchars	"SKDR"
tokenid		0


#
# Define resources other than standard discardable code
#
resource IrlapResidentCode		code read-only shared fixed
resource IrlapCommonCode		code read-only shared
resource IrlapActionCode		code read-only shared 
resource IrlapConnectionCode		code read-only shared 
resource IrlapTransferCode		code read-only shared 

resource IrlapStrings			lmem read-only shared
resource ifdef IrlapUI			object
resource ifdef IrlapAddrCtrlUI		object read-only shared
resource ifdef IrlapPrefCtrlUI		object read-only shared
resource IrlapClassStructures		fixed read-only shared
resource IrlapDriverTable		fixed code read-only shared

#
# Exported classes/routines
#
export IrlapAddressDialogClass		ifdef
export IrlapAddressControlClass		ifdef
export IrlapPreferenceControlClass	ifdef
