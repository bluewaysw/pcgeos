##############################################################################

# 	Copyright (c) GeoWorks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	appcache.tcl
# AUTHOR: 	Doug Fults, May 13, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	pappcache	    	Print out different "app-cache" info
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	5/13/93		Initial Revision
#
# DESCRIPTION:
#	App Cache commands
#
#	$Id: appcache.tcl,v 1.2.14.1 97/03/29 11:26:52 canavese Exp $
#
###############################################################################

[defcmd pappcache {} system.misc
{Usage:
    pappcache

Examples:
    "pappcache"	    print out current state of the app-cache

Synopsis:
    Prints out the current state of the system application cache, for systems
    operating in transparent launch mode.  Specifically, prints out:

	Applications in the cache (First choice for detaching)
	Top full-screen App (Not detached except by another full screen app)
	Desk accessories (detached only as last resort)
	Application geodes in the process of detaching

See also:
}
{	
	echo Applications in the cache (First choice for detaching):
	echo ------------------------------------------------------
	print-gcn-if-there GCNSLT_TRANSPARENT_DETACH

	echo Top full-screen App (Not detached except by another full screen app):
	echo ---------------------------------------------------------------------
	print-gcn-if-there GCNSLT_TRANSPARENT_DETACH_FULL_SCREEN_EXCL

	echo Desk accessories (detached only as last resort):
	echo ------------------------------------------------
	print-gcn-if-there GCNSLT_TRANSPARENT_DETACH_DA

	echo Application geodes in the process of detaching:
	echo -----------------------------------------------
	print-gcn-if-there GCNSLT_TRANSPARENT_DETACH_IN_PROGRESS
}]

[defsubr print-gcn-if-there {list {manuf MANUFACTURER_ID_GEOWORKS}}
{
    require pgcnlist-find-list-callback gcn
    var id [getvalue $list]
    var mid [getvalue $manuf]
    var lol *geos::GCNListBlock:GCNLBH_listOfLists

    require carray-enum chunkarr

    var found [carray-enum $lol pgcnlist-find-list-callback [list $mid $id l]]
    if {$found} {
	pgcnlist $list
	echo
    } else {
	echo NONE
	echo
    }
}]

