##############################################################################
#
#	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	Socket access point database
# FILE:		accpnt.gp
#
# AUTHOR:	Eric Weber, Apr 24, 1995
#
#	$Id: accpnt.gp,v 1.1 97/04/04 17:41:24 newdeal Exp $
#
##############################################################################

#
# Specify the geode's permanent name
#
name    accpnt.lib

#
# Specify the type of geode
#
type library, single, discardable-dgroup

#
# Define the library entry point
#
entry   AccessPointEntry

#
# Import definitions from the kernel
#
library geos

#
# Desktop-related things
#
longname        "Access point database"
tokenchars      "APNT"
tokenid         0

#
# Code resources
#
nosort
resource ApiCode                code read-only shared
resource ControlCode          	code read-only shared

# other resources
resource AccessPointClassStructures	fixed  shared read-only
resource AccessPointTemplate		object shared read-only
resource AccessPointStrings		lmem   shared read-only
resource AccessPointBlock		lmem   shared
resource	Strings			shared lmem
#
# exported routines
#
export	AccessPointCreateEntry
export	AccessPointDestroyEntry
export	AccessPointGetType
export	AccessPointSetStringProperty
export	AccessPointSetIntegerProperty
export	AccessPointGetStringProperty
export	AccessPointGetIntegerProperty
export	AccessPointDestroyProperty
export	AccessPointGetEntries
export	AccessPointCompareStandardProperty
export	AccessPointCommit

#
# exported classes
#
export	AccessPointControlClass
export	AccessPointSelectorClass
skip	1

#
# C stubs
#
export ACCESSPOINTCREATEENTRY
export ACCESSPOINTDESTROYENTRY
export ACCESSPOINTGETTYPE
export ACCESSPOINTSETSTRINGPROPERTY
export ACCESSPOINTSETINTEGERPROPERTY
export ACCESSPOINTGETSTRINGPROPERTYBLOCK
export ACCESSPOINTGETSTRINGPROPERTYBUFFER
export ACCESSPOINTGETINTEGERPROPERTY
export ACCESSPOINTDESTROYPROPERTY
export ACCESSPOINTGETENTRIES
export ACCESSPOINTCOMPARESTANDARDPROPERTY
export AccessPointCommit as ACCESSPOINTCOMMIT

incminor
export AccessPointIsEntryValid
export ACCESSPOINTISENTRYVALID

incminor 

export AccessPointLock
export AccessPointUnlock

export ACCESSPOINTLOCK
export ACCESSPOINTUNLOCK

export AccessPointInUse
export ACCESSPOINTINUSE

incminor AccessNewForMultiselection

incminor AccessNewDirectFunctions
export	AccessPointDestroyEntryDirect
export	AccessPointSetStringPropertyDirect
export	AccessPointSetIntegerPropertyDirect
export	AccessPointGetStringPropertyDirect
export	AccessPointGetIntegerPropertyDirect
export	AccessPointDestroyPropertyDirect

export  AccessPointGetActivePoint
export  AccessPointSetActivePoint

export ACCESSPOINTDESTROYENTRYDIRECT
export ACCESSPOINTSETSTRINGPROPERTYDIRECT
export ACCESSPOINTSETINTEGERPROPERTYDIRECT
export ACCESSPOINTGETSTRINGPROPERTYBLOCKDIRECT
export ACCESSPOINTGETSTRINGPROPERTYBUFFERDIRECT
export ACCESSPOINTGETINTEGERPROPERTYDIRECT
export ACCESSPOINTDESTROYPROPERTYDIRECT

export ACCESSPOINTGETACTIVEPOINT
export ACCESSPOINTSETACTIVEPOINT

incminor AccessPointDialingOptions

export	AccessPointSetDialingOptions
export	AccessPointGetDialingOptions
export	AccessPointGetPhoneStringWithOptions
export	ACCESSPOINTSETDIALINGOPTIONS
export	ACCESSPOINTGETDIALINGOPTIONS
export	ACCESSPOINTGETPHONESTRINGWITHOPTIONS
