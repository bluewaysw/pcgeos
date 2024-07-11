##############################################################################
#
#       Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:      Legos
# MODULE:       Basru library
# FILE:         basrun.gp
#
# AUTHOR:       Roy
#
# DESCRIPTION:
#       
#       Basic runtime gp file
#
#       $Id: basrun.gp,v 1.2 98/10/05 12:25:11 martin Exp $
#
##############################################################################
#
#
#
name basrun.lib

longname        "Basic Runtime Library"
tokenchars      "BSRN"
tokenid         0

#
# Specify geode type: is a library
#
type    library, single, c-api

ifdef __HIGHC__
entry   BasrunLibraryEntry
else
entry   BASRUNLIBRARYENTRY
endif

#
# Make sure we run on GEOS 2.01
#

#ifdef DO_DBCS
#platform        pizza
#else
#platform        geos201
#endif

#exempt          ansic
#exempt          hash
#exempt          fido
#exempt          streamc

#ifdef PROFILE
#exempt geos
#endif


#
# Libraries: list which libraries are used by the application.
# ent is also used, but putting it here causes a circular dependency

library geos
library ui
library math
library ansic
library hash
#library fido
library streamc

resource RUNERRORSTRINGS lmem shared read-only

export InterpClass

#
# Prog task related
#

export ProgAllocTask
export ProgDestroyTask
export ProgResetTask
export ProgGetVMFile
#export ProgSetMainTask
#export ProgGetMainTask
skip 2
export ProgTurboChargeFido
export ProgAddRunTask

#
# RunTask related
#

export RunLoadModule
export RunFindFunction
export RunCallFunction
#export RunDestroyModuleVariables
skip 1
export RunTaskGetVMFile
export RunGetFidoTask
export RunSetBuildTime
export RunGetProgHandleFromRunTask
export RunSetTop
export RunTaskSetBugHandle
export RunCallFunctionWithKey
#export RunCopyComplex
skip 1
export RunTopLevel
export RunAllocTask

# Debugging routines. Here's the deal: 
# 
# When debugging, numerous bits of the runtime code (understandably)
# make calls to debugging-related functions.  This leaves a static
# dependency on these routines.  One could conceivably use ifdef's
# around these calls and have a non-debugging version of the library,
# but that means dealing with 2 separate libraries, and it's possible
# both would be needed on a single device. Yuck.
#
# So, one alternative is to only include debugging routines which
# are called (directly or indirectly) by runtime code. If you're really
# concerned about the size of this library, _any_ other debugging routine
# could go into the compiler. Yet this can be confusing because
# the distribution is a little bizarre. I've taken a less radical approach,
# leaving most debugging code here.  I have dumped all variable examination
# code into the compiler because it's quite unrelated to the other
# debugging code.

export BugGetSuspendStatus
export BugSetBuilderRequest
export BugGetBuilderRequest
export BugGetCurrentFrame
export BugGetFrameInfo
export BugGetFrameName
export BugGetFrameLineNumber
export BugSetBreakAtLine
export BugClearBreakAtLine
export BugToggleBreakAtLine
export BugSetOneTimeBreakAtLine
export BugGetBugHandleFromRTask
export BugDeleteBreaksForFunction
export BugSetBugHandleNotRunning
export BugUpdateBreaksForDeletedFunction
export BugSetAllBreaks
export BugDeleteAllBreaks

# Hack cause this didn't work when viewer app tried to call
# Psem directly..

skip 1
#export BugPSem

# RunHeap

export RunHeapDataSize
export RunHeapLockExternal as RunHeapLock
export RunHeapDerefExternal as RunHeapDeref
export RunHeapUnlockExternal as RunHeapUnlock
export RunHeapDecRefAndUnlockExternal as RunHeapDecRefAndUnlock



export RunHeapAlloc
export RunHeapIncRef
export RunHeapDecRef

# Bridge structures
# -----------------
# These are mostly defined in basrun. But some pieces are only
# needed by the compiler. To keep basrun smaller we put them
# in the compiler, but they still need access to some of the other
# routines in basrun.
#
# StrMap

export StrMapCreate
export StrMapGetCount
export StrMapAdd

# SST (Small string tables)

export SSTAlloc
export SSTDestroy
export SSTAdd
export SSTDeref

# FunTab

export FunTabCreate
export FunTabDestroy
export FunTabAppendRoutine
#export FunTabSlimFast
skip 1

# More heap stuff for components

export  RunComponentLockHeap
export  RunComponentUnlockHeap
export  RunComponentCopyString

export  ECRunHeapLockHeap
export  ECRunHeapUnlockHeap

export  RunHeapAlloc_asm
export  RunHeapLock_asm
export  RunHeapUnlock_asm
export  RunComponentLockHeap_asm
export  RunComponentUnlockHeap_asm

# Complex utils

export  RunAllocComplex
export  RunCreateComplex
export  RunHeapIncRef_asm
export  RunHeapDecRef_asm
export  VMCOPYVMCHAIN_FIX

export  BugGetBuilderState
export  BugSetBuilderState

export  RunSetURL
export  RunGetAggPropertyExt
export  RunSetAggPropertyExt


#math hack now used for constant expressions at compile
export  SmartTrunc

# needed in basco for link time errors
export  BugOffsetToLineNum

export  BugSetNumHiddenFuncs
export  RunUnloadModule
export  RunTaskSetFlags


#FIDO stuff
export FidoFindComponent

export FidoGetCompLibs
export FidoUnlockComponentInfoTable
export FidoLockComponentInfoTable
export FidoRegLoadedCompLibs
export FIDOREGLOADEDCOMPLIBS

# from Main

export FidoOpenModule
export FidoCloseModule
export FidoGetPage
export FidoGetHeader

export FIDOOPENMODULE
export FIDOCLOSEMODULE
export FIDOGETPAGE
export FIDOGETHEADER

export  FidoAllocTask
export  FIDOALLOCTASK
export  FidoDestroyTask
export  FIDODESTROYTASK

export  FIDOFINDCOMPONENT
export  FidoGetComplexData
export  FIDOGETCOMPLEXDATA

export  FidoRegisterAgg
export  FIDOREGISTERAGG
export  FIDOCLEANTASK
# remove this soon
export  FIDOFINDCOMPONENT as FIDOFINDCOMPONENT_NEW


export BugSetBreakAtOffset
export BugLineNumToOffset

export BasrunRpcInit
export BasrunRpcSetNotify
export BasrunRpcExit
export BasrunRpcCall
export BasrunRpcHandleCall
export BasrunRpcServe
export BasrunRpcReply

export BugGetSetVar
export BugGetString
export BugCreateString

export BugClearBreakAtOffset
export Fido_GetML

export ProgAddDebuggedRunTask
export BugGetNumVars
