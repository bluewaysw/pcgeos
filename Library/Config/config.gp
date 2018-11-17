##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Config
# FILE:		config.gp
#
# AUTHOR:	CDB, 4/92
#
#
# Parameters file for the config library
#
#	$Id: config.gp,v 1.2 98/04/24 01:21:40 gene Exp $
#
##############################################################################
#
# Permanent name
#
name config.lib
#
# Long filename
#
longname "Configuration Library"
#
# token information
#
tokenchars "CONF"
tokenid 0
#
# Specify geode type
#
type	library, single, discardable-dgroup

#
# Import library routine definitions
#
library	geos
library	ui

# resources
nosort
resource TocCode	code read-only shared
ifndef	TOC_ONLY
resource PrefClasses	fixed read-only shared
resource PrefCode	code read-only shared
resource Utils		code read-only shared
resource Strings	shared lmem read-only
endif

entry	ConfigEntry

# exported classes

ifdef	TOC_ONLY
skip 19
else
export PrefBooleanGroupClass	
export PrefClass
export PrefDialogClass
export PrefInteractionClass
export PrefItemGroupClass
export TitledGlyphClass
export PrefStringItemClass
export PrefValueClass

# Removed PrefMinuteValueClass -1/93
skip 1
export PrefDynamicListClass
export PrefTextClass
export PrefTocListClass
export PrefContainerClass
export PrefTriggerClass

# exported routines

export	ConfigBuildTitledMoniker
export	PREFSAVEVIDEO
export	PREFRESTOREVIDEO
export	PREFDISCARDSAVEDVIDEO
export	PrefTestVideoDevice
endif

# Toc routines

export	TocFindCategory
export	TocNameArrayFind
export	TocNameArrayGetElement
export	TocNameArrayAdd
export	TocUpdateCategory
export	TocDBLock
export	TocAddDisk
export	TocCreateNewFile

export	TocSortedNameArrayAdd
skip	1

# Prefmgr utilities

ifdef	TOC_ONLY
skip 2
else
skip 	1
export	ConfigBuildTitledMonikerUsingToken
endif

# C stubs

ifdef	TOC_ONLY
skip	1
else
export	CONFIGBUILDTITLEDMONIKER
endif
export	TOCFINDCATEGORY
export	TOCNAMEARRAYFIND
export	TOCNAMEARRAYGETELEMENT
export	TOCNAMEARRAYADD
export	TOCUPDATECATEGORY
export	TOCDBLOCK
export	TOCDBLOCKGETREF
export	TOCADDDISK
export	TOCCREATENEWFILE
ifdef	TOC_ONLY
skip	2
else
skip 	1
export	CONFIGBUILDTITLEDMONIKERUSINGTOKEN
endif

# New entry points-- added here to avoid upping the protocol

export	TocGetFileHandle

incminor

ifdef	TOC_ONLY
skip	2
else
export	PrefControlClass
export	PrefTimeDateControlClass
endif

incminor AttrPrefValueWrap

incminor

ifdef	TOC_ONLY
skip	1
else
export PrefPortItemClass
endif
incminor
ifdef	TOC_ONLY
skip	1
else
export PrefColorSelectorClass
endif

incminor

ifdef	TOC_ONLY
skip	1
else
export PrefIniDynamicListClass
endif

incminor

export TocSortedNameArrayFind
export TOCSORTEDNAMEARRAYFIND

incminor	NewPTDCMessagesForDove

ifdef	DO_DOVE
export PrefValueZeroPadClass
else
skip	1
endif
export PrefMonthListClass
export PrefDayPickerClass
export PrefBooleanClass

incminor	NewPTDCMessagesForGPC
incminor        NewForNDO2000
