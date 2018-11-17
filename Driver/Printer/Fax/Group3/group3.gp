##############################################################################
#
#	Copyright (c) Geoworks 1994.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Pasta
# FILE:		group3.gp
#
# AUTHOR:	Jacob Gabrielson, Mar 10, 1993
#
#	$Id: group3.gp,v 1.1 97/04/18 11:52:52 newdeal Exp $
#
##############################################################################
#
# Specify permanent name first
#
name    group3.drvr
#
# Long name
#
longname "Group3 Fax Driver"
#
# DB Token
#
tokenchars "FXDR"
tokenid 0
#
#
# Specify geode type
#
type    driver, single
#
#  Heapspace.  Set low to get around a system bug in calculating
#  the heapspace for libraries.
#
heapspace 1
#
# Imported libraries
#
library geos
library spool
library	faxfile

ifdef GP_USE_PALM_ADDR_BOOK
library pabapi
endif

#
# Make this module fixed so we can put the strategy routine there
#
resource Entry fixed code read-only shared
#
# Make driver info resource accessible from user-level processes
#
resource DriverInfo     lmem, data, shared, read-only, conforming
resource DeviceInfo     data, shared, read-only, conforming
#
# UI resources
#
resource 	Group3UI	ui-object read-only
resource 	StringBlock	lmem data read-only

export	CoverPageTextClass
export	CoverPageReceiverTextClass
export	CoverPageSenderInteractionClass
export	FaxInfoClass
export	QuickNumbersListClass
export	Group3OptionsTriggerClass
export  Group3ClearTriggerClass

ifdef GP_PEN_BASED
export	InkDeleteTriggerClass
endif

export	QuickRetrieveListClass
export	DeleteTriggerClass

ifdef GP_USE_PALM_ADDR_BOOK
export  AddressBookListClass
export	AddressBookListItemClass
export	AddrBookTriggerClass
endif

export	DialAssistInteractionClass

ifdef GP_USE_PALM_ADDR_BOOK
export  AddressBookFileSelectorClass
endif










