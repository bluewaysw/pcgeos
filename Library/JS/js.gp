##############################################################################
#
#	Copyright (c) Global PC 1999 -- All Rights Reserved
#
#			GEOWORKS CONFIDENTIAL
#
# PROJECT:	Javascript interpreter
# MODULE:	Javascript
# FILE:		js.gp
#
# AUTHOR:	Chris Ruppel 24 Jan 1999
#
# NOTE:
#	This library cannot be used without a license.
# 
#	$Id: $
#
##############################################################################
#
# Geode's permanent name
#
name js.lib

#
# Type of geode
#
type c-api, library, single


#
# Filesystem information
#
longname        "Javascript Library"
tokenchars      "JSLB"
tokenid         0

usernotes	"ScriptEase Javascript Interpreter Copyright 1993-1998 Nombas Inc.  All rights reserved."
#
# Libraries used
#
library	geos
library ansic
library math
library borlandc

#
# Resources: list all resource blocks which are used by the application.
# (standard discardable code resources can be ommitted).
#


#
# Exported classes & routines
#
entry   JSENTRY

#
# C api routines.
#
export JSECREATEVARIABLE
export JSECREATESIBLINGVARIABLE
export JSECREATECONVERTEDVARIABLE
export JSEDESTROYVARIABLE 
export JSEFINDVARIABLE
export JSEGETVARIABLENAME
export JSEGETARRAYLENGTH
export JSESETATTRIBUTES
export JSEGETATTRIBUTES
export JSEGETTYPE 
export JSECONVERT
export JSEASSIGN
export JSEGETLONG 
export JSEPUTLONG
export JSEGETBOOLEAN 
export JSEPUTBOOLEAN 
export JSEPUTNUMBER

# Export either jseGetNumber or a dummy entry to allow us to reuse
# the .ldf file when switching between float and integer...
export jseGetNumber
#export	JSEGETLONG as _dummy

export JSEGETFLOATINDIRECT
export JSEGETSTRING
export JSEGETWRITEABLESTRING
export JSEPUTSTRING
export JSEPUTSTRINGLENGTH
export JSECOPYSTRING
export JSEEVALUATEBOOLEAN
export JSECOMPARE
export JSEMEMBERINTERNAL
export JSEINDEXMEMBEREX
export JSEGETNEXTMEMBER
export JSEDELETEMEMBER
export JSEGLOBALOBJECTEX
export JSESETGLOBALOBJECT 
export JSEACTIVATIONOBJECT
export JSEGETCURRENTTHISVARIABLE
export JSECREATESTACK 
export JSEDESTROYSTACK 
export JSEPUSH
export JSEPOP 
export JSEFUNCVARCOUNT 
export JSEFUNCVAR
export JSEFUNCVARNEED
export JSEVARNEED
export JSERETURNVAR
export JSERETURNLONG 
export JSERETURNNUMBER 
export JSEINITIALIZEENGINE 
export JSETERMINATEENGINE 
export JSEINITIALIZEEXTERNALLINK
export JSETERMINATEEXTERNALLINK
export JSEGETEXTERNALLINKPARAMETERS
export JSEAPPEXTERNALLINKREQUEST
export JSEADDLIBRARY
export JSEGETFUNCTION
export JSEISFUNCTION
export JSECALLFUNCTIONEX
export JSECURRENTCONTEXT 
export JSECREATEWRAPPERFUNCTION
export JSEMEMBERWRAPPERFUNCTION
export JSEISLIBRARYFUNCTION
export JSEINTERPRET
export JSEINTERPINIT
export JSEINTERPTERM 
export JSEINTERPEXEC 
export jseGetNameLength
export jseSetNameLength
export JSECALLATEXIT
export JSELIBSETERRORFLAG 
export jseLibErrorPrintf
export JSELIBSETEXITFLAG
export JSEQUITFLAGGED
export JSELOCATESOURCE
export jseUtilMustMalloc
export JSESETARRAYLENGTH

export CreateNewObject
export MyjseMember
export LoadLibrary_All

export JSEGARBAGECOLLECT

export jseEnter
export jseLeave
export jseAssert
export jseMappedMalloc
export jseMappedFree
export jseMappedRealloc

incminor

export JSEGETOBJECTCALLBACKS
export JSESETOBJECTCALLBACKS
export JSEINTERNALIZESTRING
export JSEGETINTERNALSTRING
export JSEFREEINTERNALSTRING
export JSEENABLEDYNAMICMETHOD

incminor

export JSEGETOBJECTDATA
export JSESETOBJECTDATA

resource jsemem_TEXT fixed
#resource CommonCode fixed
resource fpemul_TEXT fixed
resource ASM_TEXT fixed
incminor

export jseMemInfo
ifdef COMPILE_OPTION_PROFILING_ON
#library profpnt
endif

ifdef GEOS_MAPPED_MALLOC
#library mapheap
endif
