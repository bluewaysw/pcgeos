##############################################################################
#
#	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	Socket project
# FILE:		resolver.gp
#
# AUTHOR:	Steve Jang, Dec 14, 1994
#
#	Resolver that provides DNS services.
#
#	$Id: resolver.gp,v 1.1 97/04/07 10:42:19 newdeal Exp $
#
##############################################################################
#
# permanent name
#
name 	resolver.lib
#
# Specify geode type
#
type	library, single 
#
# Import kernel routine definitions
#
library	geos 
library netutils
library ui noload
library socket
library accpnt
#library	dhcp     never worked, can't work, so removing - ed 6/13/00

#
# Desktop-related things
#
longname	"Resolver"
tokenchars	"RSLV"
tokenid		0

#
# Initial entry point
#
entry	ResolverEntryRoutine

#
# Define resources other than standard discardable code
#
# ResolverResidentCode	: fixed code
# ResolverCommonCode	: codes executed by foreign thread or server thread
# ResolverActionCode	: codes executed by event thread(utilities included)
# ResolverRequestBlock	: contains requests, slists
# ResolverCacheBlock	: contains DNS tree structure
#
nosort
resource ResolverResidentCode	code read-only shared fixed
resource ResolverCommonCode	code read-only shared
resource ResolverActionCode	code read-only shared
resource ResolverCApiCode	code read-only shared
resource ResolverRequestBlock	lmem shared
resource ResolverCacheBlock	lmem shared
resource ResolverQueueBlock	lmem shared
resource ResolverAnswerBlock	lmem shared

#
# Exported routines
#
nosort
export ResolverResolveAddress
export ResolverGetHostByName
export ResolverGetHostInfo

incminor
export ResolverDeleteCache

export RESOLVERRESOLVEADDRESS
export RESOLVERDELETECACHE

export ResolverStopResolve

incminor
export RESOLVERSTOPRESOLVE

incminor
export ResolverAddDhcpDnsServers

incminor
export ResolverRemoveDhcpDnsServers
