##############################################################################
#
#	Copyright (c) Geoworks 1996.  All rights reserved.
#	GEOWORKS CONFIDENTIAL
#
# PROJECT:	Data Exchange Library
# FILE:		datax.gp
#
# AUTHOR:	Robert Greenwalt, Nov  5, 1996
#
#
# 
#
#	$Id: datax.gp,v 1.1 97/04/04 17:54:06 newdeal Exp $
#
##############################################################################
#
# Specify name of geode
#
name datax.lib

#
# Specify type of geode
#
type library, single, discardable-dgroup, process

class	DataXHelperClass

entry DataxEntry

#
# Import library routine definitions
#
library geos
library ui

#
# Desktop-related things
#
longname	"Data Exchange Library"
tokenchars	"DATX"
tokenid		0

#
# Override default resource flags
#
resource ExtCode		shared, read-only, code
resource DataXAppl		shared, read-only, code
resource DataXClassStructures	fixed, read-only, shared
resource DataXFixed		shared, read-only, code, fixed
resource DataXEC		shared, read-only, code

#
# Exported routines
#
export DXOPENPIPE
export DXCLOSEPIPE
export DXINTERNALCLOSEPIPE
export DXMANUALPIPECYCLE
export DXMANUALBEHAVIORCALL
export DXSETDXIDATABUFFERSIZE

export ECDXCHECKPEH
export ECDXCHECKDATAXINFO
export ECDXCHECKDATAXBEHAVIORARGUMENTS

export DataXApplicationClass
export DataXHelperClass
