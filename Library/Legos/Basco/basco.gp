##############################################################################
#
#       Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:      Legos
# MODULE:       Basco library
# FILE:         basco.gp
#
# AUTHOR:       Roy
#
# DESCRIPTION:
#       
#       General basco
#
#	$Id: basco.gp,v 1.1 98/10/13 21:44:55 martin Exp $
#
##############################################################################
#
#
#
name basco.lib

longname        "Basco Library"
tokenchars      "BSCO"
tokenid         0

#
# Specify geode type: is a library
#
type    library, single, c-api

entry   BASCOLIBRARYENTRY

#
# Make sure we run on GEOS 2.01
#

#ifdef DO_DBCS
#platform 	pizza
#else
#platform	geos201
#endif

#exempt		hash
#exempt		tree
#exempt		fido
#exempt		basrun
#exempt		ansic

#ifdef PROFILE
#exempt geos
#endif


#
# Libraries: list which libraries are used by the application.
#

library geos
library ui
library math
library ansic
library hash
library tree
#library fido
library basrun

resource DialogStrings lmem shared read-only
export CompileInterpClass

# Loading/compiling/saving

export BascoLineAdd
export BascoTerminateRoutine
export BascoAllocTask
export BascoDestroyTask
export BascoCompileCodeFromTask
export BascoReportError
export BascoLoadFile
skip 1
# use interp obj instead
# export BascoLoadModule
export BascoCompileModule
export BascoWriteCode
export BascoCompileFunction
export BascoGetCompileErrorForFunction
export BascoSetTaskErrorToFunction
export BascoSetCompileTaskBuildTime
export BascoCompileTaskSetFidoTask

#
# String table funcs
#
export StringTableCreate
export StringTableDestroy
export StringTableAdd
export StringTableLookupString
export StringTableLock

# Editor functions
# Which really have no business being in the compiler
# but that's what we're doing for now...

export EditGetNumRoutines
export EditGetRoutineName
export EditDeleteAllCode
export EditGetRoutineNumLines
export EditGetLineDebugStatus
export EditSetLineDebugStatus
export EditGetLineTextWithLock
export EditGetRoutineIndex


# Debugging routines

export BascoBugInit
export BascoBugGetNumVars
export BascoBugGetSetVar
export BascoBugNumVarToString
export BascoBugGetVarName
export BascoBugGetString
export BascoBugGetBugHandleFromCTask
export BascoBugGetSetStructFieldData
export BascoBugGetNumFields
export BascoBugGetArrayDims
export BascoBugGetSetArrayElement
export BascoBugCreateString

export BascoWriteResources
export BascoBlockAdd
export BascoDeleteRoutine
ifdef DO_DBCS
export fgets_dbcs
else
skip 1
endif
export BascoSetLiberty
export BascoSetCompileTaskOptimize
export BascoBugStringToNumber
export BascoIsKeyword

export BascoBugGetBuilderRequest
export BascoBugSetBuilderRequest
export BascoBugSetBreakAtOffset
export BascoBugGetCurrentFrame
export BascoBugGetFrameInfo
export BascoBugGetFrameLineNumber
export BascoBugGetFrameName

export BascoRpcSendFile
export BascoRpcLoadModule
export BascoBugClearBreakAtOffset

export BascoSBCS2DBCS
export BascoDBCS2SBCS

export BascoRpcHello
