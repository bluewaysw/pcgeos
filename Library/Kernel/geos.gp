##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		geos.gp
#
# AUTHOR:	Adam, 10/89
#
#
# Parameters file for the PC/GEOS kernel.
#
#	$Id: geos.gp,v 1.2 98/04/30 15:51:56 joon Exp $
#
##############################################################################
#
# Permanent name
#
name geos.kern
#
# Specify geode type
#
type	process, library, single, system
#
# Desktop-related things
#
longname	"GEOS Kernel"
tokenchars	"KERN"
tokenid		0
#
# Define the library entry point
#
entry KernelLibraryEntry
# Keep glue happy...besides, it's sort of true...
class ProcessClass
#
# Stack size
# 1/20/93: upped to 1124 to allow FileCreate of swap file on system with
# standard path merging enabled to succeed (needs to create intervening
# directories, which loads in a resource, which requires a bunch of stack space
# in addition to the buffer used for FileEnsureLocalPath) -- ardeb
#
ifdef DO_DBCS
stack 1360
else
stack 1124
endif
#
# define the order of the resources
# and flags for them as well (other than dgroup and kcode)
# tell glue not to sort things its own way

nosort

ifdef DONT_ALLOCATE_FIXED_STRINGS_AS_FIXED
# If running on a multi-language XIP platform, we don't want FixedStrings 
# to be used right out of the XIP image, since we'll be translating the
# strings in it.
resource FixedStrings shared lmem preload
else
resource FixedStrings fixed lmem read-only
endif

resource kcode fixed code read-only


ifdef	GP_SYS_HAS_BITMAPS
resource SysBitmapResource fixed lmem read-only
# resource SysBitmapResource lmem read-only shared 
endif

resource MovableStrings shared lmem read-only preload
resource GLoad code read-only shared preload
resource GCNListBlock lmem shared preload
ifdef	DO_DBCS
else
resource USMap read-only shared preload
endif

ifdef	GP_FULL_EXECUTE_IN_PLACE
resource InitfileRead code read-only shared fixed
else
resource InitfileRead code read-only shared preload
endif

resource Filemisc code read-only shared preload
resource FileCommon code read-only shared preload
resource Format code read-only shared preload
resource LocalStrings shared lmem preload
resource ChunkArray shared code read-only preload
resource StandardPathStrings shared lmem read-only preload
resource StringMod code read-only shared preload
ifdef DO_DBCS
else
resource StringCmpMod code read-only shared preload
endif
resource DOSConvert code read-only shared preload
resource kinit code read-only shared preload discard-only
resource FSInfoResource lmem shared preload no-swap
resource ObscureInitExit code read-only shared preload discard-only
resource InitStrings shared lmem read-only preload discard-only
resource WinMisc code read-only shared
resource Sort code read-only shared
resource ChunkCommon code read-only shared
resource WinMovable code read-only shared
resource DBaseCode code read-only shared
resource VMSaveRevertCode code read-only shared
resource GraphicsSemiCommon code read-only shared
resource VMHigh code read-only shared
resource VMHugeArray code read-only shared
resource C_File code read-only shared
resource C_Local code read-only shared
resource GraphicsLine code read-only shared
resource C_Graphics code read-only shared
resource GrWinBlt code read-only shared
resource VMOpenCode code read-only shared
resource BIOSSeg code read-only shared
resource C_Common code read-only shared
resource C_System code read-only shared
resource GraphicsObscure code read-only shared
resource GraphicsFonts code read-only shared
resource FileenumCode code read-only shared
resource GraphicsAllocBitmap code read-only shared
resource GraphicsStringStore code read-only shared
resource GraphicsCalcConic code read-only shared
resource GraphicsCalcEllipse code read-only shared
resource GraphicsPalette code read-only shared
resource GraphcisFontsEnum code read-only shared
resource GraphicsFatLine code read-only shared
resource FontDriverCode code read-only shared
resource GraphicsPath code read-only shared
resource GraphicsPattern code read-only shared
resource GraphicsPolygon code read-only shared
resource GraphicsDrawBitmapCommon code read-only shared
resource GraphicsDrawBitmap code read-only shared
resource GraphicsRotRaster code read-only shared
resource GraphicsScaleRaster code read-only shared
resource GraphicsRegionPaths code read-only shared
resource GraphicsRoundRect code read-only shared
resource GraphicsSpline code read-only shared
resource GraphicsString code read-only shared
resource GraphicsText code read-only shared
resource GraphicsTextObscure code read-only shared
resource GraphicsImage code read-only shared
resource IMMoveResize code read-only shared
resource IMMiscInput code read-only shared
ifndef	GP_NO_PEN_SUPPORT	
ifdef	GP_FULL_EXECUTE_IN_PLACE
resource IMPenCode fixed code read-only
else
resource IMPenCode code read-only shared
endif
endif
resource C_ChunkArray code read-only shared
resource C_GeneralChange code read-only shared
resource FileSemiCommon code read-only shared
ifdef	GP_FULL_EXECUTE_IN_PLACE
resource InitfileWrite code read-only shared fixed
else
resource InitfileWrite code read-only shared
endif
ifdef DO_DBCS
else
resource MultiMap code read-only shared
resource FrenchMap code read-only shared
resource NordicMap code read-only shared
resource PortugueseMap code read-only shared
resource Latin1Map code read-only shared
endif
resource MetaProcessClassCode code read-only shared
resource C_VarData code read-only shared
resource VMUtils code read-only shared
resource DosapplCode code read-only shared

# ObjectLoad fixed to allow the async writing of object blocks in VM Files 
# resource is 3112 bytes EC, 2741 bytes NEC on the Trunk as of 2/8/95

resource ObjectLoad code fixed read-only shared
resource GraphicsTransformUtils code read-only shared
resource GraphicsCommon code read-only shared
resource GraphicsPathRect code read-only shared
resource GraphicsArc code read-only shared
resource GraphicsDashedLine code read-only shared
resource SystemBitmapsAndHatches shared lmem data
resource ObjectFile code read-only shared
# ECCode fixed to allow heap-sensitive EC-code to be stored there, freeing 
# space in kcode.  Robertg - 2/18/95
resource ECCode code fixed read-only shared
ifdef DO_DBCS
resource GengoNameStrings shared lmem
endif
resource Patching code read-only shared
#
# Moved most of the filesystem into its own fixed resource to make room in kcode
#			-- ardeb 10/12/95
#
resource FSResident code fixed read-only shared
#
# These are the special-cased resources for XIP machines (basically, that
# code which must lie in fixed ROM, instead of paged ROM.
# If you change this here, you must also change kernelGeode.def
#
ifdef	GP_FULL_EXECUTE_IN_PLACE
resource VMHugeArrayResidentXIP	code fixed read-only shared
resource CopyStackCodeXIP	code fixed read-only shared
resource GeosCStubXIP 		code read-only shared fixed
else
resource CopyStackCodeXIP	code read-only shared
endif

resource ProfileLessCommonCode code read-only shared

resource ifdef SSProfile code fixed read-only shared
resource ifdef SSData data fixed shared 

resource UtilWindowCode		code read-only shared

#
# Memory routines
#
export MemAllocFar as MemAlloc
export MemReAlloc
export MemFree
export MemDiscard
export MEMDISCARD
export MemLock
export MemUnlock
export MemLockFixedOrMovable
export MemUnlockFixedOrMovable
export HandleP
export HandleV
export MemPLock
export MemUnlockV
export MemThreadGrabFar as MemThreadGrab
export MemThreadReleaseFar as MemThreadRelease
export MemLockShared
export MemLockExcl
export MemUnlockShared
export MemUpgradeSharedLock
export MemDowngradeExclLock
export ECMEMVERIFYHEAP
export MemDerefDS
export MemDerefES
export MemThreadGrabNB
export MemOwnerFar as MemOwner
export MemAllocSetOwnerFar as MemAllocSetOwner
export MemSegmentToHandle
export MemModifyFlags
export HandleModifyOwner
export MemModifyOtherInfo
export MemGetInfo
export ECCheckBounds
export MemInitRefCount
export MemIncRefCount
export MemDecRefCount
export MemAllocLMem

export MemExtendHeap		#this routine for swap driver use only!
export MemAddSwapDriver		#this routine for driver use only!
export FarPHeap as MemGrabHeap
export FarVHeap as MemReleaseHeap


#
# LMem routines
#
export LMemInitHeap
export LMemAlloc
export LMemFree
export LMemReAlloc
export ECLMemExists
export LMemInsertAt
export LMemDeleteAt
export LMemContract
export ECLMemValidateHeapFar as ECLMemValidateHeap
export ECLMemValidateHandle
export ChunkArrayCreate
export ChunkArrayElementToPtr
export ChunkArrayAppend
export ChunkArrayGetCount
export ChunkArrayEnum
export ChunkArrayDelete
export ChunkArrayPtrToElement
export ChunkArrayZero
export ChunkArrayInsertAt
export ChunkArraySort
export ArrayQuickSort
export ChunkArrayElementResize
export ECCheckChunkArray

export ElementArrayCreate
export ChunkArrayGetElement
export ElementArrayAddReference
export ElementArrayAddElement
export ElementArrayRemoveReference
export ElementArrayGetUsedCount
export ElementArrayUsedIndexToToken
export ElementArrayTokenToUsedIndex
export ElementArrayElementChanged
export ElementArrayDelete
export ChunkArrayEnumRange
export ChunkArrayDeleteRange

#
# File routines
#
export FileCreateDir
export FileDeleteDir
export FileSetCurrentPath
export FileOpen
export FileCreate
export FileCloseFar as FileClose
export FileCreateTempFile
export FileDelete
export FileRename
export FileReadFar as FileRead
export FileWriteFar as FileWrite
export FilePosFar as FilePos
export FileDuplicateHandle
export FileLockRecord
export FileUnlockRecord
export FileEnum
export FileEnumPtr
export FileEnumLocateAttr
export FileEnumWildcard
export FileGetAttributes
export FileSetAttributes
export FileGetHandleExtAttributes
export FileSetHandleExtAttributes
export FileGetPathExtAttributes
export FileSetPathExtAttributes
export FileCopyExtAttributes
export FileGetDateAndTime
export FileSetDateAndTime
export FILEPUSHDIR
export FILEPOPDIR
export FileGetCurrentPath
export FileGetCurrentPathIDs
export FileSetStandardPath
export FileTruncate
export FileCommit
export SysLocateFileInDosPath
export FileCopy
export FileMove
export FileSize
export FileGetDiskHandle
export FileParseStandardPath
export FileConstructFullPath
export ECCheckFileHandle
export FileResolveStandardPath
export	FileConstructActualPath
export FileComparePaths
export FileCreateLink
export FileGetLinkExtraData
export FileReadLink
export FileSetLinkExtraData
export FileStdPathCheckIfSubDir
#
# Routines used FS drivers only
#
export FileInt21
export FileForEach
export FileForEachPath
export FileGetDestinationDisk
#
# FSD support routines.
#
export FSDGenNameless
export FSDAllocDisk
export FSDAskForDisk
export FSDRegister
export FSDInitDrive
export FSDLockInfoShared
export FSDLockInfoExcl
export FSDLockInfoExclToES
export FSDUnlockInfoShared
export FSDUnlockInfoExcl
export FSDGetThreadPathDiskHandle
export FSDInformOldFSDOfPathNukage
export FSDCheckDestWritable
export FSDDerefInfo
export FSDRecordError
export AllocateFileHandle as FSDAllocFileHandle
export FSDDeleteDrive
export FSDDowngradeExclInfoLock
export FSDUpgradeSharedInfoLock
#
# Disk routines
#
export DiskFormat
export DiskCheckWritableFar as DiskCheckWritable
export DiskForEach
export DiskGetDrive
export DiskGetVolumeName
export DiskFind
export DiskRegisterDisk
export DiskRegisterDiskSilently
export DiskCopy
export DiskCheckInUse
export DiskCheckUnnamed
export DiskGetVolumeFreeSpace
export DiskGetVolumeInfo
export DiskSetVolumeName
export DiskLockFar as DiskLock
export DiskLockExcl
export DiskUnlockFar as DiskUnlock
export DiskSave
export DiskRestore

export DiskAllocAndInit		# For IFS Drivers ONLY

#
# Drive routines
#
export DriveGetStatusFar as DriveGetStatus
export DriveGetExtStatus
export DriveGetDefaultMedia
export DriveTestMediaSupport
export DriveLockExclGlobal as DriveLockExcl
export DriveUnlockExclGlobal as DriveUnlockExcl
export DriveGetName
export DriveLocateByNumber
export DriveLocateByName
#
# Geode routines
#
export GeodeLoad
export GeodeForEach
export GeodeFind
export GeodeGetInfo
export GeodeInfoDriver
export GeodeGetDefaultDriver
export GeodeUseLibrary
export GeodeUseDriver
export GeodeFreeLibrary
export GeodeFreeLibrary as GeodeFreeDriver
export GeodeDuplicateResource
export GeodeGetProcessHandle
export GeodeGetResourceHandle
export GeodeGetGeodeResourceHandle
export GeodeGetAppObject
export GeodeAllocQueue
export GeodeFreeQueue
export GeodeInfoQueue
export GeodeGetUIData
export GeodeSetUIData
export GeodeFlushQueue
export GeodeSetDefaultDriver
export GeodeGetDGroupDS
export GeodeGetDGroupES
export GeodeAddReference
export GeodeRemoveReference
export GeodeFindResource
#
# Message/Calling services
#
export ProcCallModuleRoutine
export ProcGetLibraryEntry
export ProcCallFixedOrMovable
export ProcInfo
export ObjProcBroadcastMessage
export ObjMessage
export ObjFreeMessage
export ObjGetMessageInfo
export MessageDispatch
export ObjDuplicateMessage
export MessageProcess
export QueueGetMessage
export QueuePostMessage
#
# Thread routines
#
export ThreadBlockOnQueue
export ThreadWakeUpQueue
export ThreadDestroy
export ThreadCreate
export ThreadGetInfo
export ThreadModify
export ThreadAttachToQueue
export ThreadPrivAlloc
export ThreadPrivFree
export ThreadGrabThreadLock
export ThreadReleaseThreadLock
export ThreadHandleException
export ThreadAllocSem
export ThreadFreeSem
export ThreadPSem
export ThreadVSem
export ThreadPTimedSem
export ThreadAllocThreadLock
export ThreadFreeSem as ThreadFreeThreadLock
export ThreadBorrowStackSpace
export ThreadReturnStackSpace

#
# Timer routines
#
export TimerStart
export TimerStop
export TimerSleep
export TimerBlockOnTimedQueue
export TimerGetCount
export TimerGetDateAndTime
export TimerSetDateAndTime
export TimerStartCount
export TimerEndCount
export	TimerStartSetOwner
#
# Graphics region routines
#
export GrChunkRegOp
export GrPtrRegOp
export GrMoveReg
export GrGetPtrRegBounds
export GrTestPointInReg
export GrTestRectInReg

#
# Graphics Path routines
#
export GrTestPointInPath
export GrGetPathPoints
export GrGetPathRegion
export GrGetClipRegion
export GrRegionPathInit
export GrRegionPathClean
export GrRegionPathMovePen
export GrRegionPathAddOnOffPoint
export GrRegionPathAddLineAtCP
export GrRegionPathAddBezierAtCP
export GrRegionPathAddPolygon
export GrRegionPathAddPolyline

#
# Miscellaneous graphics routines
#
export GrCopyDrawMask
export GrMapColorToGrey
export GrGetDefFontID
export GrFontMetrics
export GrCharWidth
export GrTextWidth
export GrGetBitmap
export GrSetWinClipRect
export GrCopyGString		
export GrCallFontDriverID
export GrSetClipRect
export GrCreateState
export GrDestroyState
export GrGrabExclusive
export GrReleaseExclusive
export GrTransformWWFixed
export GrUntransformWWFixed
export GrTransformDWFixed
export GrUntransformDWFixed
export GrTransformDWord
export GrUntransformDWord
export GrTransformByMatrix
export GrTransformByMatrixDWord
export GrUntransformByMatrix
export GrUntransformByMatrixDWord
export GrCharMetrics
export GrTextWidthWBFixed
export GrSetTextDrawOffset
export GrGetTextDrawOffset

#
# Graphics math routines
#
export GrMulWWFixedPtr
export GrMulWWFixed
export GrMulDWFixedPtr
export GrMulDWFixed
export GrSDivWWFixed
export GrUDivWWFixed
export GrSqrWWFixed
export GrSqrRootWWFixed
export GrQuickSine
export GrQuickCosine
export GrQuickArcSine
export GrQuickTangent
export GrPolarToCartesian
export GrSDivDWFbyWWF
#
export GrSetGStringPos
export GrBitBlt
export GrDrawRegion
export GrDrawRegionAtCP
export GrTransform
export GrUntransform
export GrDrawImage
export GrDrawHugeImage
#
export GrMapColorIndex
export GrMapColorRGB
export GrGetPalette
export GrCreateBitmap
export GrDestroyBitmap
export GrSetPrivateData
export GrGetMixMode
export GrGetLineColor
export GrGetAreaColor
export GrGetTextColor
export GrGetLineMask
export GrGetAreaMask
export GrGetTextMask
export GrGetLineColorMap
export GrGetAreaColorMap
export GrGetTextColorMap
export GrGetTextSpacePad
export GrGetTextStyle
export GrGetTextMode
export GrGetLineWidth
export GrGetLineEnd
export GrGetLineJoin
export GrGetMiterLimit
export GrGetCurPos
export GrGetInfo
export GrTextObjCalc
export GrDestroyGString
export GrLoadGString
export GrCreateGString
export GrGetGStringElement
export GrDrawGString
export GrDrawGStringAtCP
export GrTextPosition
export GrGetTransform
export GrSetBitmapRes
export GrGetBitmapRes
export GrClearBitmap
export GrGetFont
export GrGetLineStyle
export GrEnumFonts
export GrCheckFontAvail
export GrFindNearestPointsize
export GrTestPointInPolygon
export GrGetBitmapSize
export GrBrushPolyline
export GrSetBitmapMode
export GrGetBitmapMode
export GrCalcLuminance
export GrSetFontWeight
export GrSetFontWidth
export GrSetSuperscriptAttr
export GrSetSubscriptAttr
export GrGetFontWeight
export GrGetFontWidth
export GrGetSuperscriptAttr
export GrGetSubscriptAttr
export GrCallFontDriver
export	GrDeleteGStringElement

# Move to Graphics Path routines
export GrGetPathBounds

#
# START OF THE GSTRING CODES 
#
export GrEndGString
export GrComment
export GrNullOp
export GrEscape
export GrSaveState
export GrRestoreState
export GrNewPage
export GrApplyRotation
export GrApplyScale
export GrApplyTranslation
export GrSetTransform
export GrApplyTransform
export GrSetNullTransform
export GrDrawLine
export GrDrawLineTo
export GrDrawRect
export GrDrawRectTo
export GrDrawHLine
export GrDrawHLineTo
export GrDrawVLine
export GrDrawVLineTo
export GrDrawRoundRect
export GrDrawRoundRectTo
export GrDrawPoint
export GrDrawPointAtCP
export GrDrawBitmap
export GrDrawBitmapAtCP
export GrFillBitmap
export GrFillBitmapAtCP
export GrDrawChar
export GrDrawCharAtCP
export GrDrawText
export GrDrawTextAtCP
export GrDrawPolyline
export GrDrawEllipse
export GrDrawArc
export GrDrawSpline
export GrFillRect
export GrFillRectTo
export GrFillRoundRect
export GrFillRoundRectTo
export GrFillArc
export GrFillPolygon
export GrFillEllipse
export GrSetMixMode
export GrRelMoveTo
export GrMoveTo
export GrSetLineColor
export GrSetLineMask
export GrSetLineColorMap
export GrSetLineWidth
export GrSetLineJoin
export GrSetLineEnd
export GrSetLineAttr
export GrSetMiterLimit
export GrSetLineStyle
export GrSetAreaColor
export GrSetAreaMask
export GrSetAreaColorMap
export GrSetAreaAttr
export GrSetTextColor
export GrSetTextMask
export GrSetTextColorMap
export GrSetTextStyle
export GrSetTextMode
export GrSetTextSpacePad
export GrSetTextAttr
export GrSetFont
export GrGetFontName
export GrSetGStringBounds
export GrDrawTextField
export GrCreatePalette
export GrDestroyPalette
export GrSetPaletteEntry
export GrSetPalette
export GrDrawPolygon
export GrSetTrackKern
export GrGetTrackKern
export GrInitDefaultTransform
export GrSetDefaultTransform
export GrApplyTranslationDWord
export GrDrawArc3Point
export GrDrawArc3PointTo
export GrDrawRelArc3PointTo
export GrFillArc3Point
export GrFillArc3PointTo
export GrGetTextBounds
export GrSetAreaPattern
export GrSetTextPattern
export GrGetAreaPattern
export GrGetTextPattern
#
# Move to Graphics Path routines
#
export GrBeginPath
export GrEndPath
export GrCloseSubPath
export GrSetClipPath
export GrSetWinClipPath
export GrFillPath
export GrDrawPath
export GrSetStrokePath

export GrGetWinHandle
export GrDrawHugeBitmap
export GrDrawHugeBitmapAtCP
export GrDrawSplineTo
export GrDrawCurve
export GrDrawCurveTo

export	GrSaveTransform
export	GrRestoreTransform
export	GrDrawRelLineTo
export	GrDrawRelCurveTo
export  GrLabel
export	GrGetGStringBounds
export	GrTestRectInMask
export GrGetWinBounds
export GrGetMaskBounds
export	GrInvalRect
export	GrInvalRectDWord
export	GrGetWinBoundsDWord
export	GrGetMaskBoundsDWord
export	GrEditGString
export GrBeginUpdate
export GrEndUpdate
export GrCompactBitmap
export GrEditBitmap
export GrGetExclusive
export GrGetGStringHandle
export GrGetPath
export GrGetPoint
export GrParseGString
export GrUncompactBitmap

#
# Font driver helper routines
#
export FontDrDeleteLRUChar
export FontDrFindFontInfo
export FontDrFindOutlineData
export FontDrAddFont
export FontDrDeleteFont
export FontDrLockFont
export FontDrUnlockFont

#
# VMem routines
#
export VMOpen
export VMLock
export VMUnlock
export VMAlloc
export VMFind
export VMFree
export VMDirty
export VMGetMapBlock
export VMSetMapBlock
export VMUpdate
export VMClose
export VMModifyUserID
export VMGetAttributes
export VMSetAttributes
export VMGrabExclusive
export VMReleaseExclusive
export VMInfo
export VMSetReloc
export VMAttach
export VMDetach
export VMMemBlockToVMBlock
export VMSave
export VMSaveAs
export VMRevert
export VMVMBlockToMemBlock
export VMGetDirtyState
export VMCopyVMChain
export VMFreeVMChain
export VMCompareVMChains
export VMCopyVMBlock
export VMCheckForModifications
export VMPreserveBlocksHandle
export VMSetExecThread
export VMAllocLMem
#
# Miscellaneous System services
#
export AppFatalError as FatalError
export SysNotify
export SysShutdown
export SysStatistics
export SysGetECLevel
export SysSetECLevel
export SysEnterInterrupt
export SysEnterCritical
export SysExitInterrupt
export SysCatchInterrupt
export SysResetInterrupt
export SysCatchDeviceInterrupt
export SysResetDeviceInterrupt
export SYSGETCONFIG
export UtilHex32ToAscii
export UtilAsciiToHex32
export SysRegisterScreen
export SysSetExitFlags
export SysCountInterrupt
export SysGetInfo
export SysGetDosEnvironment
export SysLockBIOSFar as SysLockBIOS
export SysUnlockBIOSFar as SysUnlockBIOS
export SysAddIdleIntercept
export SysRemoveIdleIntercept
export WarningNotice
export CWARNINGNOTICE
#
# Localization routines
#
export LocalSetDateTimeFormat
export LocalGetDateTimeFormat
export LocalFormatDateTime
export LocalParseDateTime
export LocalUpcaseChar
export LocalDowncaseChar
export LocalUpcaseString
export LocalDowncaseString
export LocalCmpStrings
export LocalCmpStringsNoCase
export LocalIsUpper
export LocalIsLower
export LocalIsAlpha
export LocalIsPunctuation
export LocalIsSpace
export LocalIsSymbol
export LocalIsDateChar
export LocalIsTimeChar
export LocalIsNumChar
export LocalDosToGeos
export LocalGeosToDos
export LocalGetQuotes
export LocalSetQuotes
export LocalIsDosChar
export LocalCustomFormatDateTime
export LocalGetNumericFormat
export LocalSetNumericFormat
export LocalGetCurrencyFormat
export LocalSetCurrencyFormat
export LocalCmpStringsDosToGeos
export LocalCodePageToGeos
export LocalGeosToCodePage
export LocalCodePageToGeosChar
export LocalGeosToCodePageChar
export LocalDosToGeosChar
export LocalGeosToDosChar
export LocalGetCodePage
export LOCALGETMEASUREMENTTYPE
export LocalSetMeasurementType
export LocalLexicalValue
export LocalLexicalValueNoCase
export LocalCmpChars
export LocalCmpCharsNoCase
export LocalStringSize
export LocalStringLength
export LocalDistanceToAscii
export LocalDistanceFromAscii
export LocalFixedToAscii
export LocalAsciiToFixed
export LocalIsControl
export LocalIsDigit
export LocalIsHexDigit
export LocalIsAlphaNumeric
export LocalIsPrintable
export LocalIsGraphic
export LocalSetCodePage
export LocalCmpStringsNoSpace
export LocalCmpStringsNoSpaceCase
export LocalCustomParseDateTime
#
# Window routines
#
export WinOpen
export WinClose
export WinChangePriority
export WinScroll
export WinAckUpdate
export WinInvalReg
export WinValClipLine
export WinLocatePoint
export WinGenLineMask
export WinInvalTree
export WinMaskOutSaveUnder
export WinApplyRotation
export WinApplyScale
export WinTransform
export WinUntransform
export WinTransformDWord
export WinUntransformDWord
export WinSetTransform
export WinApplyTransform
export WinSetNullTransform
export WinGetInfo
export WinSetInfo
export WinGrabChange
export WinReleaseChange
export WinChangeAck
export WinMove
export WinResize
export WinDecRefCount
export WinGetWinScreenBounds
export WinApplyTranslation
export WinApplyTranslationDWord
export WinSetPtrImage
export WinEnsureChangeNotification
export WinGetTransform
export WinForEach
export WinSuspendUpdate
export WinUnSuspendUpdate
export WinGeodeSetPtrImage
export WinGeodeGetInputObj
export WinGeodeSetInputObj
export WinGeodeGetParentObj
export WinGeodeSetParentObj
export WinGeodeSetActiveWin
export WinSysSetActiveGeode
export WinGeodeGetFlags
export WinGeodeSetFlags

#
# Object routines/classes
#
export ObjCallInstanceNoLock
export ObjCallInstanceNoLockES
export ObjCallClassNoLock
export ObjCallSuperNoLock
export ObjInstantiate
export ObjLockObjBlock
export ObjDuplicateResource
export ObjFreeDuplicate
export ObjDoRelocation
export ObjResizeMaster
export ObjInitializeMaster
export ObjInitializePart
export ObjGetFlags
export ObjSetFlags
export ObjMarkDirty
export ObjDoUnRelocation
export ObjAssocVMFile
export ObjSaveExtraStateBlock
export ObjDisassocVMFile
export ObjCloseVMFile
export ObjLinkCallParent
export ObjLinkFindParent
export ObjLinkCallNextSibling
export ObjCompFindChild
export ObjCompAddChild
export ObjCompRemoveChild
export ObjCompMoveChild
export ObjCompProcessChildren
export ObjInitDetach
export ObjIncDetach
export ObjEnableDetach
export MetaClass
export ProcessClass
export ObjIncInUseCount
export ObjDecInUseCount
export ObjSwapLock
export ObjSwapUnlock
export ObjSwapLockParent
export ObjTestIfObjBlockRunByCurThread
export ObjSaveBlock
export ObjMapSavedToState
export ObjMapStateToSaved
export ObjIsObjectInClass
export ObjFreeChunk
export MessageSetDestination
export ObjFreeObjBlock
export ObjBlockSetOutput
export ObjBlockGetOutput
export ObjDecInteractibleCount
export ObjGotoInstanceTailRecurse
export ObjGotoSuperTailRecurse
export ObjIncInteractibleCount
export ObjIsClassADescendant
export ObjRelocOrUnRelocSuper
#
# Error-checking code
#
export ECCheckMemHandleFar as ECCheckMemHandle
export ECCheckMemHandleNSFar as ECCheckMemHandleNS
export ECCheckThreadHandleFar as ECCheckThreadHandle
export ECCheckProcessHandle
export ECCheckResourceHandle
export ECCheckGeodeHandle
export ECCheckDriverHandle
export ECCheckLibraryHandle
export ECCheckGStateHandle
export ECCheckWindowHandle
export ECCheckQueueHandle
export ECCheckClass
export ECCheckLMemHandle
export ECCheckLMemHandleNS

export ECCheckLMemChunk
export ECCheckObject
export ECCheckLMemObject
export ECCheckOD
export ECCheckLMemOD
export ECCheckSegment
export FarCheckDS_ES as ECCheckSegments
export ECCHECKSTACK

#
# Initfile/config file routines
#
export	InitFileWriteData
export	InitFileWriteString
export	InitFileWriteBoolean
export	InitFileReadData
export	InitFileReadString
export	InitFileReadInteger
export	InitFileReadBoolean
export	InitFileWriteInteger
export	InitFileGetTimeLastModified
export	InitFileSave
export	InitFileRevert
export	INITFILECOMMIT
export	InitFileDeleteEntry
export	InitFileDeleteCategory
export  InitFileReadStringSection
export InitFileWriteStringSection
export InitFileDeleteStringSection
export InitFileEnumStringSection


skip	1


#
# Input Manager routines
#
export ImAddMonitor
export ImRemoveMonitor
export ImInfoInputProcess
export ImGrabInput
export ImReleaseInput
export ImSetDoubleClick
export ImInfoDoubleClick
export ImForcePtrMethod
export ImSetPtrWin
export ImPtrJump
export ImStartMoveResize
export ImStopMoveResize
export ImConstrainMouse
export ImUnconstrainMouse
export ImBumpMouse
export ImGetMousePos
export ImGetPtrWin
export ImGetButtonState
export ImSetPtrImage

ifdef  GP_NO_PEN_SUPPORT
export NoPenSupportError as ImInkReply
export NoPenSupportError as ImStartPenMode
export NoPenSupportError as ImEndPenMode
else
export ImInkReply
export ImStartPenMode
export ImEndPenMode
endif

#
# DBase routines
#
export DBLock
export DBUnlock
export DBDirty
export DBAlloc
export DBReAlloc
export DBFree
export DBGroupAlloc
export DBGroupFree
export DBSetMap
export DBGetMap
export DBLockMap
export DBInsertAt
export DBDeleteAt
export DBCopyDBItem

#
# General Change Notification routines
#
export GCNListAdd
export GCNListRemove
export GCNListSend

export GCNListAddToList
export GCNListRemoveFromList
export GCNListFindItemInList
export GCNListSendToList
export GCNListCreateList

export GCNListAddToBlock
export GCNListRemoveFromBlock
export GCNListSendToBlock
export GCNListCreateBlock

export	GCNListFindListInBlock
export	GCNListDestroyBlock
export	GCNListDestroyList
export GCNListRecordAndSend
export GCNListRelocateBlock
export GCNListRelocateList
export GCNListUnRelocateBlock
export GCNListUnRelocateList
#
# Init-time logging routines
#
export LogWriteInitEntry
export LogWriteEntry

#
# DosExec/task-switching support
#
export DosExec
export DosExecLocateLoader
export DosExecSuspend
export DosExecUnsuspend

###############################################################
#
# C Interface routines
#

#
# geos.h routines
#
export THREADGETERROR

#
# heap.h routines
#
export MEMALLOCSETOWNER
export MEMREALLOC
export MEMGETINFO
export MEMMODIFYFLAGS
export HANDLEMODIFYOWNER
export MEMMODIFYOTHERINFO
export MEMPTRTOHANDLE
export MEMALLOC
export MEMFREE
export MEMDEREF
export MEMPLOCK
export MEMLOCK
export MEMUNLOCK
export MEMOWNER
export MEMUNLOCKV
export MEMTHREADGRAB
export MEMTHREADGRABNB
export MEMTHREADRELEASE
export HANDLEP
export HANDLEV
export MEMINITREFCOUNT
export MEMINCREFCOUNT
export MEMDECREFCOUNT
export MEMALLOCLMEM
export MEMLOCKFIXEDORMOVABLE
export MEMUNLOCKFIXEDORMOVABLE
export MEMLOCKSHARED
export MEMUNLOCKSHARED
export MEMLOCKEXCL
export MEMUPGRADESHAREDLOCK
export MEMDOWNGRADEEXCLLOCK

#
# file.h routines
#
export FILECREATEDIR
export FILEDELETEDIR
export FILEGETCURRENTPATH
export FILESETCURRENTPATH
export FILEOPEN
export FILECREATE
export FILECLOSE
export FILECOMMIT
export FILECREATETEMPFILE
export FILEDELETE
export FILERENAME
export FILEREAD
export FILEWRITE
export FILEPOS
export FILETRUNCATE
export FILESIZE
export FILEGETDATEANDTIME
export FILESETDATEANDTIME
export FILEDUPLICATEHANDLE
export FILELOCKRECORD
export FILEUNLOCKRECORD
export FILEGETDISKHANDLE
export FILEGETATTRIBUTES
export FILESETATTRIBUTES
export FILESETSTANDARDPATH
export FILECOPY
export FILEMOVE
export FILECONSTRUCTFULLPATH
export FILEPARSESTANDARDPATH
export FILEGETPATHEXTATTRIBUTES
export FILESETPATHEXTATTRIBUTES
export FILEGETHANDLEEXTATTRIBUTES
export FILESETHANDLEEXTATTRIBUTES
export FILEENUMLOCATEATTR
export FILEENUMWILDCARD
export FILERESOLVESTANDARDPATH
export	FILECONSTRUCTACTUALPATH
export FILECOMPAREPATHS
export FILECREATELINK
export FILEGETLINKEXTRADATA
export FILEREADLINK
export FILESETLINKEXTRADATA

#
# fileEnum.h routines
#
export FILEENUM as UPGRADE_FILEENUM

#
# resource.h routines
#
export GEODELOADDGROUP
export _ProcCallFixedOrMovable_cdecl
export PROCCALLFIXEDORMOVABLE_PASCAL
export GEODEDUPLICATERESOURCE
export GEODEGETOPTRNS
export ThreadGetDGroupDS
export PROCGETLIBRARYENTRY

#
# geode.h routines
#
export GEODEGETPROCESSHANDLE
export GEODELOAD
export GEODEFIND
export GEODEGETINFO
export GEODEGETAPPOBJECT
export GEODEGETUIDATA
export GEODESETUIDATA
export PROCINFO
export GEODEALLOCQUEUE
export GEODEFREEQUEUE
export GEODEINFOQUEUE
export GEODEFLUSHQUEUE
export GEODEFINDRESOURCE
export GEODEADDREFERENCE
export GEODEREMOVEREFERENCE

#
# driver.h routines
#
export GEODEUSEDRIVER_OLD
export GEODEFREELIBRARY as GEODEFREEDRIVER
export GEODEINFODRIVER
export GEODEGETDEFAULTDRIVER
export GEODESETDEFAULTDRIVER

#
# library.h routines
#
export GEODEUSELIBRARY_OLD
export GEODEFREELIBRARY

#
# sem.h routines
#
export THREADALLOCSEM
export THREADFREESEM
export THREADPSEM
export THREADVSEM
export THREADPTIMEDSEM
export THREADALLOCTHREADLOCK
export THREADFREESEM as THREADFREETHREADLOCK
export THREADGRABTHREADLOCK
export THREADRELEASETHREADLOCK

#
# thread.h routines
#
export THREADDESTROY
export THREADCREATE_OLD
export THREADGETINFO
export THREADMODIFY
export THREADATTACHTOQUEUE
export THREADPRIVALLOC
export THREADPRIVFREE
export THREADHANDLEEXCEPTION

#
# timer.h routines
#
export TIMERSTART
export TIMERSTOP
export TIMERSLEEP
export TIMERGETCOUNT

#
# timedate.h routines
#
export TIMERGETDATEANDTIME
publish TIMERSETDATEANDTIME

#
# system.h routines
#
export _DosExec
export SYSLOCATEFILEINDOSPATH
export SYSGETDOSENVIRONMENT
export SYSNOTIFY
export SYSREGISTERSCREEN
export _SysShutdown
export SYSSETEXITFLAGS
export SYSGETECLEVEL
export SYSSETECLEVEL
export UTILHEX32TOASCII
export UTILASCIITOHEX32
export SYSGETPENMODE
export SysLockBIOSFar as SYSLOCKBIOS
export SysUnlockBIOSFar as SYSUNLOCKBIOS

#
# sysstats.h routines
#
export SYSSTATISTICS
export SYSGETINFO

#
# drive.h routines
#
export DRIVEGETSTATUS
export DRIVEGETDEFAULTMEDIA
export DRIVETESTMEDIASUPPORT
export DRIVEGETEXTSTATUS
export DRIVEGETNAME

#
# disk.h routines
#
export DISKGETVOLUMEINFO
export DISKSETVOLUMENAME
export DISKGETVOLUMEFREESPACE
export DISKCOPY
export DISKFORMAT
export DISKREGISTERDISK
export DISKREGISTERDISKSILENTLY
export DISKFOREACH
export DISKGETDRIVE
export DISKGETVOLUMENAME
export DISKFIND
export DISKCHECKWRITABLE
export DISKCHECKINUSE
export DISKCHECKUNNAMED
export DISKSAVE
export DISKRESTORE

#
# initfile.h routines
#
export INITFILEWRITEDATA
export INITFILEWRITESTRING
export INITFILEWRITEINTEGER
export INITFILEWRITEBOOLEAN
export INITFILEREADDATABUFFER
export INITFILEREADDATABLOCK
export INITFILEREADSTRINGBUFFER
export INITFILEREADSTRINGBLOCK
export INITFILEREADSTRINGSECTIONBUFFER
export INITFILEREADSTRINGSECTIONBLOCK
export INITFILEREADINTEGER
export INITFILEREADBOOLEAN
export INITFILEGETTIMELASTMODIFIED
export INITFILESAVE
export INITFILEREVERT
export INITFILEDELETEENTRY
export INITFILEDELETECATEGORY
export INITFILEWRITESTRINGSECTION
export INITFILEDELETESTRINGSECTION
export INITFILEENUMSTRINGSECTION

skip	1

#
# localize.h routines
#
export LOCALGETDATETIMEFORMAT
export LOCALFORMATDATETIME
export LOCALPARSEDATETIME
export TOUPPER
export TOLOWER
export LOCALUPCASESTRING
export LOCALDOWNCASESTRING
export LOCALCMPSTRINGS
export LOCALCMPSTRINGSNOCASE
export ISUPPER
export ISLOWER
export ISALPHA
export ISPUNCT
export ISSPACE
export LOCALISSYMBOL
export LOCALISDATECHAR
export LOCALISTIMECHAR
export LOCALISNUMCHAR
export LOCALISDOSCHAR
export LOCALDOSTOGEOSCHAR
export LOCALGEOSTODOSCHAR
export LOCALGETCODEPAGE
export LOCALDOSTOGEOS
export LOCALGEOSTODOS
export LOCALGETQUOTES
export LOCALCUSTOMFORMATDATETIME
export LOCALGETNUMERICFORMAT
export LOCALGETCURRENCYFORMAT
export LOCALCMPSTRINGSDOSTOGEOS
export LOCALCODEPAGETOGEOS
export LOCALGEOSTOCODEPAGE
export LOCALCODEPAGETOGEOSCHAR
export LOCALGEOSTOCODEPAGECHAR
export LOCALLEXICALVALUE
export LOCALLEXICALVALUENOCASE
export LOCALSETDATETIMEFORMAT
export LOCALSETQUOTES
export LOCALSETNUMERICFORMAT
export LOCALSETCURRENCYFORMAT
export LOCALSETMEASUREMENTTYPE
export LOCALSTRINGSIZE
export LOCALSTRINGLENGTH
export LOCALDISTANCETOASCII
export LOCALDISTANCEFROMASCII
export LOCALFIXEDTOASCII
export LOCALASCIITOFIXED
export ISCNTRL
export ISDIGIT
export ISXDIGIT
export ISALNUM
export ISPRINT
export ISGRAPH
export LOCALCMPSTRINGSNOSPACE
export LOCALCMPSTRINGSNOSPACECASE
export LOCALCUSTOMPARSEDATETIME
export LOCALGETLANGUAGE

#
# localmem.h routines
#
export LMEMINITHEAP
export LMEMREALLOC
export LMEMINSERTAT
export LMEMDELETEAT
export	LMEMCONTRACT
export LMEMGETCHUNKSIZE
export LMEMALLOC
export LMEMFREE
export LMEMDEREF

#
# vm.h routines
#
export VMLOCK
export VMUNLOCK
export VMDIRTY
export VMALLOC
export VMFIND
export VMFREE
export VMMODIFYUSERID
export VMINFO
export VMGETDIRTYSTATE
export VMGETMAPBLOCK
export VMSETMAPBLOCK
export VMOPEN
export VMUPDATE
export VMCLOSE as UPGRADE_VMCLOSE
export VMGETATTRIBUTES
export VMSETATTRIBUTES
export VMGRABEXCLUSIVE
export VMRELEASEEXCLUSIVE
export VMSETRELOC
export VMATTACH
export VMDETACH
export VMMEMBLOCKTOVMBLOCK
export VMVMBLOCKTOMEMBLOCK
export VMSAVE
export VMSAVEAS
export VMREVERT
export VMCOPYVMCHAIN as VMCOPYVMCHAIN_OLD
export VMFREEVMCHAIN as VMFREEVMCHAIN_OLD
export VMCOMPAREVMCHAINS as VMCOMPAREVMCHAINS_OLD
export VMCOPYVMBLOCK
export VMCHECKFORMODIFICATIONS
export VMPRESERVEBLOCKSHANDLE
export VMSETEXECTHREAD
export VMALLOCLMEM

#
# dbase.h routines
#
export DBLOCKUNGROUPED
export DBUNLOCK
export DBDIRTY
export DBGETMAP
export DBLOCKGETREFUNGROUPED
export DBRAWALLOC
export DBREALLOCUNGROUPED
export DBFREEUNGROUPED
export DBGROUPALLOC
export DBGROUPFREE
export DBINSERTATUNGROUPED
export DBDELETEATUNGROUPED
export DBSETMAPUNGROUPED
export DBRAWCOPYDBITEM

#
# ec.h routines
#
export CFATALERROR
export ECCHECKMEMHANDLE
export ECCHECKMEMHANDLENS
export ECCHECKTHREADHANDLE
export ECCHECKPROCESSHANDLE
export ECCHECKRESOURCEHANDLE
export ECCHECKGEODEHANDLE
export ECCHECKDRIVERHANDLE
export ECCHECKLIBRARYHANDLE
export ECCHECKGSTATEHANDLE
export ECCHECKWINDOWHANDLE
export ECCHECKQUEUEHANDLE
export ECCHECKLMEMHANDLE
export ECCHECKLMEMHANDLENS
export ECLMEMVALIDATEHEAP
export ECLMEMVALIDATEHANDLE
export ECCHECKLMEMCHUNK
export ECLMEMEXISTS
export ECCHECKCLASS
export ECCHECKOBJECT
export ECCHECKLMEMOBJECT
export ECCHECKOD
export ECCHECKLMEMOD
export ECCHECKFILEHANDLE
export ECVMCheckVMFile
export ECVMCHECKVMFILE
export ECVMCheckVMBlockHandle
export ECVMCHECKVMBLOCKHANDLE
export ECVMCheckMemHandle
export ECVMCHECKMEMHANDLE
export ECCHECKBOUNDS

#
# object.h routines
#
export OBJLOCKOBJBLOCK
export OBJDUPLICATERESOURCE
export OBJFREEDUPLICATE
export OBJFREECHUNK
export OBJGETFLAGS
export OBJSETFLAGS
export OBJMARKDIRTY
export OBJISOBJECTINCLASS
export OBJINCINUSECOUNT
export OBJDECINUSECOUNT
export OBJDORELOCATION
export OBJDOUNRELOCATION
export OBJRESIZEMASTER
export OBJINITIALIZEMASTER
export OBJINITIALIZEPART
export OBJTESTIFOBJBLOCKRUNBYCURTHREAD
export OBJSAVEBLOCK
export OBJMAPSAVEDTOSTATE
export OBJMAPSTATETOSAVED
export OBJINITDETACH
export OBJINCDETACH
export OBJENABLEDETACH
export OBJLINKFINDPARENT
export OBJCOMPFINDCHILDBYOPTR
export OBJCOMPFINDCHILDBYNUMBER
export OBJCOMPADDCHILD
export OBJCOMPREMOVECHILD
export OBJCOMPMOVECHILD
export OBJCOMPPROCESSCHILDREN
export COBJMESSAGE
export COBJCALLSUPER
export OBJFREEMESSAGE
export OBJDUPLICATEMESSAGE
export OBJGETMESSAGEINFO
export CMESSAGEDISPATCH
export COBJSENDTOCHILDREN
export OBJDEREF
export OBJDEREF1
export OBJDEREF2
export GEODEGETCODEPROCESSHANDLE
export OBJINSTANTIATE
export OBJPROCBROADCASTMESSAGE
export MESSAGESETDESTINATION
export OBJFREEOBJBLOCK
export OBJBLOCKSETOUTPUT
export OBJBLOCKGETOUTPUT
export OBJDECINTERACTIBLECOUNT
export OBJINCINTERACTIBLECOUNT
export OBJISCLASSADESCENDANT
export OBJRELOCATEENTRYPOINT
export OBJRELOCORUNRELOCSUPER
export OBJUNRELOCATEENTRYPOINT
export QUEUEGETMESSAGE
export QUEUEPOSTMESSAGE

#
# chunkarr.h routines
#
export CHUNKARRAYCREATEAT_OLD
export CHUNKARRAYELEMENTTOPTR
export CHUNKARRAYPTRTOELEMENT
export CHUNKARRAYAPPEND
export CHUNKARRAYINSERTAT_OLD
export CHUNKARRAYDELETE
export CHUNKARRAYGETCOUNT
export CHUNKARRAYENUM
export CHUNKARRAYZERO
export CHUNKARRAYSORT
export ARRAYQUICKSORT
export CHUNKARRAYELEMENTRESIZE
export ECCHECKCHUNKARRAY

export ELEMENTARRAYCREATEAT_OLD
export CHUNKARRAYGETELEMENT
export ELEMENTARRAYADDREFERENCE
export ELEMENTARRAYADDELEMENT
export ELEMENTARRAYREMOVEREFERENCE
export ELEMENTARRAYGETUSEDCOUNT
export ELEMENTARRAYUSEDINDEXTOTOKEN
export ELEMENTARRAYTOKENTOUSEDINDEX
export ELEMENTARRAYELEMENTCHANGED
export ELEMENTARRAYDELETE
export CHUNKARRAYENUMRANGE
export CHUNKARRAYDELETERANGE

#
# graphics.h routines
#
export GRDRAWTEXT
export GRDRAWTEXTATCP
export GRFILLRECT
export GRFILLRECTTO as UPGRADE_GRFILLRECTTO
export GRDRAWRECTTO as UPGRADE_GRDRAWRECTTO
export GRENUMFONTS
export GRCHECKFONTAVAILID
export GRCHECKFONTAVAILNAME
export GRFINTNEARESTPOINTSIZE
export GRGETDEFFONTID
export GRGETBITMAP
export GRCREATEBITMAP
export GRDESTROYBITMAP
export GRSETBITMAPRES
export GRGETBITMAPRES
export GRCLEARBITMAP
export GRGETBITMAPSIZE
export GRBRUSHPOLYLINE
export GRMOVEREG
export GRGETPTRREGBOUNDS
export GRTESTPOINTINREG
export GRTESTRECTINREG
export GRSQRROOTWWFIXED
export GRQUICKSINE
export GRQUICKCOSINE
export GRQUICKARCSINE
export GRQUICKTANGENT
export GRGRABEXCLUSIVE
export GRRELEASEEXCLUSIVE
export GRTRANSFORMWWFIXED
export GRTRANSFORMDWFIXED
export GRUNTRANSFORMWWFIXED
export GRUNTRANSFORMDWFIXED
export GRBITBLT
export GRTRANSFORM
export GRTRANSFORMDWORD
export GRUNTRANSFORM
export GRUNTRANSFORMDWORD
export GRMAPCOLORINDEX
export GRMAPCOLORRGB
export GRGETPALETTE
export GRSETPRIVATEDATA
export GRGETMIXMODE
export GRGETLINECOLOR
export GRGETAREACOLOR
export GRGETTEXTCOLOR
export GRGETLINEMASK
export GRGETAREAMASK
export GRGETTEXTMASK
export GRGETLINECOLORMAP
export GRGETAREACOLORMAP
export GRGETTEXTCOLORMAP
export GRGETTEXTSPACEPAD
export GRGETTEXTSTYLE
export GRGETTEXTMODE
export GRGETLINEWIDTH
export GRGETLINEEND
export GRGETLINEJOIN
export GRGETLINESTYLE
export GRGETMITERLIMIT
export GRGETCURPOS
export GRGETINFO
export GRGETTRANSFORM
export GRGETFONT
export GRTESTPOINTINPOLYGON
export GRENDGSTRING
export GRCOMMENT
export GRNULLOP
export GRESCAPE
export GRNEWPAGE
export GRAPPLYROTATION
export GRAPPLYSCALE
export GRAPPLYTRANSLATION
export GRAPPLYTRANSLATIONDWORD
export GRSETTRANSFORM
export GRAPPLYTRANSFORM
export GRSETNULLTRANSFORM
export GRDRAWROUNDRECT
export GRDRAWROUNDRECTTO
export GRDRAWPOINT
export GRDRAWPOINTATCP
export GRDRAWCHAR
export GRDRAWCHARATCP
export GRDRAWPOLYLINE
export GRDRAWELLIPSE
export GRDRAWARC_OLD
export GRDRAWSPLINE
export GRDRAWPOLYGON
export GRFILLROUNDRECT
export GRFILLROUNDRECTTO
export GRFILLARC_OLD
export GRFILLPOLYGON
export GRFILLELLIPSE
export GRSETLINEATTR
export GRSETAREAATTR
export GRSETGSTRINGBOUNDS
export GRCREATEPALETTE
export GRDESTROYPALETTE
export GRSETPALETTEENTRY
export GRSETPALETTE
export GRSETTRACKKERN
export GRINITDEFAULTTRANSFORM
export GRSETDEFAULTTRANSFORM
export GRCHARMETRICS
export GRFONTMETRICS
export GRCHARWIDTH
export GRTEXTWIDTH
export GRTEXTWIDTHWWFIXED
export GRDRAWREGION
export GRDRAWREGIONATCP
export GRMULWWFIXED
export GRMULDWFIXED
export GRSDIVWWFIXED
export GRUDIVWWFIXED
export GRSDIVDWFBYWWF
export GRCREATESTATE
export GRDESTROYSTATE
export GRSAVESTATE
export GRRESTORESTATE
export GRDRAWLINE
export GRDRAWLINETO
export GRDRAWHLINE
export GRDRAWHLINETO
export GRDRAWVLINE
export GRDRAWVLINETO
export GRDRAWBITMAP
export GRDRAWBITMAPATCP
export GRFILLBITMAP
export GRFILLBITMAPATCP
export GRSETMIXMODE
export GRRELMOVETO
export GRMOVETO
export GRSETLINECOLOR
export GRSETLINEMASKSYS
export GRSETLINEMASKCUSTOM
export GRSETLINECOLORMAP
export GRSETLINEWIDTH
export GRSETLINEJOIN
export GRSETLINEEND
export GRSETMITERLIMIT
export GRSETLINESTYLE
export GRSETAREACOLOR
export GRSETAREAMASKSYS
export GRSETAREAMASKCUSTOM
export GRSETAREACOLORMAP
export GRSETTEXTCOLOR
export GRSETTEXTMASKSYS
export GRSETTEXTMASKCUSTOM
export GRSETTEXTCOLORMAP
export GRSETTEXTSTYLE
export GRSETTEXTMODE
export GRSETTEXTSPACEPAD
export GRSETTEXTATTR
export GRSETFONT
export GRSETCLIPRECT
export GRSETWINCLIPRECT
export GRDRAWRECT
export GRBEGINPATH
export GRENDPATH
export GRCLOSESUBPATH
export GRSETCLIPPATH
export GRSETWINCLIPPATH
export GRFILLPATH
export GRDRAWPATH
export GRSETSTROKEPATH
export GRGETPATHBOUNDS
export GRTESTPOINTINPATH
export GRGETPATHPOINTS
export GRGETPATHREGION
export GRGETCLIPREGION
export GRGETMASKBOUNDSDWORD
export GRGETWINHANDLE
export GRDRAWARC3POINT
export GRDRAWARC3POINTTO
export GRDRAWRELARC3POINTTO
export GRFILLARC3POINT
export GRFILLARC3POINTTO
export GRDRAWRELLINETO
export GRDRAWHUGEBITMAP
export GRDRAWHUGEBITMAPATCP
export GRDRAWSPLINETO
export GRDRAWCURVE
export GRDRAWCURVETO
export GRSETBITMAPMODE
export GRGETBITMAPMODE
export GRGETTRACKKERN
export GRGETFONTNAME
export GRSETFONTWEIGHT
export GRSETFONTWIDTH
export GRSETSUPERSCRIPTATTR
export GRSETSUBSCRIPTATTR
export GRGETFONTWEIGHT
export GRGETFONTWIDTH
export GRGETSUPERSCRIPTATTR
export GRGETSUBSCRIPTATTR
export GRSETAREAPATTERN
export GRSETCUSTOMAREAPATTERN
export GRSETTEXTPATTERN
export GRSETCUSTOMTEXTPATTERN
export GRGETAREAPATTERN
export GRGETTEXTPATTERN
export	GRINVALRECTDWORD	
export GRGETWINBOUNDS
export GRGETWINBOUNDSDWORD
export GRGETMASKBOUNDS
export GRBEGINUPDATE
export GRENDUPDATE
export GRINVALRECT
export	GRGETTEXTBOUNDS
export	GRGETGSTRINGBOUNDS
export	GRLABEL
export GRCOMPACTBITMAP
export GRDRAWHUGEIMAGE
export GRDRAWIMAGE
export GREDITBITMAP
export GRGETEXCLUSIVE
export GRGETGSTRINGHANDLE
export GRGETPATH
export GRGETPOINT
export GRPARSEGSTRING
export GRTESTRECTINMASK
export GRUNCOMPACTBITMAP


#
# gstring.h routines
#
export GRDRAWGSTRING
export GRDRAWGSTRINGATCP
export GRSETGSTRINGPOS
export GRCOPYGSTRING
export GRDESTROYGSTRING
export GRLOADGSTRING
export GRCREATEGSTRING
export GRGETGSTRINGELEMENT
export GREDITGSTRING
export GRDELETEGSTRINGELEMENT as GRDELETEGSTRINGELEMENT_OLD

#
# win.h routines
#
export WINOPEN
export WINCLOSE
export WINMOVE
export WINRESIZE
export WINDECREFCOUNT
export WINCHANGEPRIORITY
export WINSCROLL
export WINSUSPENDUPDATE
export WINUNSUSPENDUPDATE
export WINGETINFO
export WINSETINFO
export WINAPPLYROTATION
export WINAPPLYSCALE
export WINAPPLYTRANSLATION
export WINAPPLYTRANSLATIONDWORD
export WINTRANSFORM
export WINTRANSFORMDWORD
export WINUNTRANSFORM
export WINUNTRANSFORMDWORD
export WINSETTRANSFORM
export WINAPPLYTRANSFORM
export WINSETNULLTRANSFORM
export WINGETTRANSFORM
export WINGETWINSCREENBOUNDS
export WINACKUPDATE
export WININVALREG

export WINSETPTRIMAGE
export WINGEODESETPTRIMAGE
export WINGEODEGETINPUTOBJ
export WINGEODESETINPUTOBJ
export WINGEODEGETPARENTOBJ
export WINGEODESETPARENTOBJ
export WINGEODESETACTIVEWIN

#
# gcnlist.h routines
#
export GCNLISTADD
export GCNLISTREMOVE
export GCNLISTSEND

export GCNLISTADDTOBLOCK
export GCNLISTREMOVEFROMBLOCK
export GCNLISTSENDTOBLOCK
export GCNLISTCREATEBLOCK

export GCNLISTADDTOLIST
export GCNLISTREMOVEFROMLIST
export GCNLISTFINDITEMINLIST
export GCNLISTSENDTOLIST
export GCNLISTCREATELIST

export	GCNLISTFINDLISTINBLOCK
export	GCNLISTDESTROYBLOCK
export	GCNLISTDESTROYLIST
export GCNLISTRELOCATEBLOCK
export GCNLISTRELOCATELIST
export GCNLISTUNRELOCATEBLOCK
export GCNLISTUNRELOCATELIST
#
# Geode Private Data support routines
#
export GeodePrivAlloc
export GeodePrivFree
export GeodePrivRead
export GeodePrivWrite
export GEODEPRIVALLOC
export GEODEPRIVFREE
export GEODEPRIVREAD_OLD
export GEODEPRIVWRITE_OLD

#
# Name array routines
#
export NameArrayCreate
export NAMEARRAYCREATEAT_OLD
export NameArrayAdd
export NAMEARRAYADD
export NameArrayFind
export NAMEARRAYFIND
export NameArrayChangeName
export NAMEARRAYCHANGENAME

#
# ObjectVariableStorage mechanism
#
export ObjVarAddData
export ObjVarDeleteData
export ObjVarDeleteDataAt
export ObjVarScanData
export ObjVarFindData
export ObjVarDerefData
export ObjVarDeleteDataRange
export ObjVarCopyDataRange

export OBJVARADDDATA
export OBJVARDELETEDATA
export OBJVARDELETEDATAAT
export OBJVARSCANDATA
export OBJVARFINDDATA
export OBJVARDEREFDATA
export OBJVARDELETEDATARANGE
export OBJVARCOPYDATARANGE

#
# HugeArray routines
#
export	HugeArrayCreate
export	HugeArrayDestroy
export	HugeArrayLock
export	HugeArrayUnlock
export	HugeArrayAppend
export	HugeArrayInsert
export	HugeArrayReplace
export	HugeArrayDelete
export	HugeArrayGetCount
export	HugeArrayDirty
export	HugeArrayNext
export	HugeArrayPrev
export	HugeArrayExpand
export	HugeArrayContract
export HugeArrayEnum
export	HUGEARRAYCREATE as HUGEARRAYCREATE_OLD 
export	HUGEARRAYDESTROY
export	HUGEARRAYLOCK as HUGEARRAYLOCK_OLD
export	HUGEARRAYUNLOCK
export	HUGEARRAYAPPEND
export	HUGEARRAYINSERT
export	HUGEARRAYREPLACE
export	HUGEARRAYDELETE
export	HUGEARRAYGETCOUNT as HUGEARRAYGETCOUNT_OLD
export	HUGEARRAYDIRTY
export	HUGEARRAYNEXT as HUGEARRAYNEXT_OLD
export	HUGEARRAYPREV
export	HUGEARRAYEXPAND
export	HUGEARRAYCONTRACT
export	ECCheckHugeArrayFar as ECCheckHugeArray
export	ECCHECKHUGEARRAY
export HugeArrayResize
export HUGEARRAYRESIZE
export HugeArrayLockDir
export HUGEARRAYLOCKDIR
export HugeArrayUnlockDir
export HUGEARRAYUNLOCKDIR
export HUGEARRAYENUM


##############################################################################
# To be moved the correct place later
##############################################################################

export FileCopyPathExtAttributes
export FILECOPYPATHEXTATTRIBUTES

export LocalFormatFileDateTime
export LOCALFORMATFILEDATETIME

export DriveLockExclFar as FSDLockDriveExcl
export DriveUnlockExclFar as FSDUnlockDriveExcl

export FSDCheckOpenCloseNotifyEnabled
export FILEENABLEOPENCLOSENOTIFICATION
export FILEDISABLEOPENCLOSENOTIFICATION
export FILEBATCHCHANGENOTIFICATIONS
export FILEFLUSHCHANGENOTIFICATIONS
export FSDGenerateNotify
export FILEGETCURRENTPATHIDS

export	GrFillHugeBitmapAtCP
export	GrFillHugeBitmap
export	GRFILLHUGEBITMAPATCP
export	GRFILLHUGEBITMAP

export	WinRealizePalette

export GRSAVETRANSFORM
export GRRESTORETRANSFORM
export GrGetGStringBoundsDWord
export GRGETGSTRINGBOUNDSDWORD

export WINREALIZEPALETTE

export LocalCalcDaysInMonth
export LOCALCALCDAYSINMONTH

export GrGetCurPosWWFixed
export GRGETCURPOSWWFIXED

export GrGetPathBoundsDWord
export GRGETPATHBOUNDSDWORD

export LocalIsCodePageSupported
export LOCALISCODEPAGESUPPORTED

export HugeArrayCompressBlocks
export HUGEARRAYCOMPRESSBLOCKS

export FixupHugeArrayChain

export ImSetPtrFlags

export GrGetHugeBitmapSize
export GRGETHUGEBITMAPSIZE

export FontDrEnsureFontFileOpen

export ECCheckEventHandle
export ECCHECKEVENTHANDLE

export GrSetVMFile
export GrTestPath

export ImGetPtrFlags

export GrSetUpdateGState

export InitFilePushPrimaryFile
export InitFilePopPrimaryFile

export FilePushTopLevelPath
export FilePopTopLevelPath

incminor

export FileAddStandardPathDirectory
export FileDeleteStandardPathDirectory

incminor

export LocalInit

incminor KernelNewForZoomer

export	FSDUnregister

incminor DiscardObjBlock

incminor

publish GRSETTEXTDRAWOFFSET
publish GRGETTEXTDRAWOFFSET
publish CHUNKARRAYINSERTAT
publish GEODEPRIVREAD
publish GEODEPRIVWRITE

incminor

publish GEODEUSEDRIVER

incminor

export FileOpenAndRead
export FILEOPENANDREAD
export InitFileGrab
export INITFILEGRAB
export INITFILERELEASE

incminor

export	FarLockInfoBlock as FontDrLockInfoBlock
export	FarUnlockInfoBlock as FontDrUnlockInfoBlock

incminor

export	FileCopyLocal
export	THREADCREATE

incminor

publish	FILEENUM
publish VMCLOSE

incminor

publish GRFILLRECTTO
publish GRDRAWRECTTO

incminor

export	MemGetSwapDriverInfo
export	MemMigrateSwapData

incminor

publish  GEODEUSELIBRARY

incminor

publish GRDRAWARC
publish GRFILLARC

incminor

export DosExecInsertMovableVector
export DosExecRestoreMovableVector

incminor

publish CHUNKARRAYCREATEAT
publish ELEMENTARRAYCREATEAT
publish NAMEARRAYCREATEAT

incminor

export GrGetCharInfo
export GRGETCHARINFO

incminor

export	SysCopyToStackDSSIFar as SysCopyToStackDSSI
export	SysCopyToStackDSBXFar as SysCopyToStackDSBX
export	SysCopyToStackDSDXFar as SysCopyToStackDSDX
export	SysCopyToStackBXSIFar as SysCopyToStackBXSI
export	SysCopyToStackESDIFar as SysCopyToStackESDI
export	SysRemoveFromStackFar as SysRemoveFromStack
export	SysCopyToBlockFar as SysCopyToBlock

export	ECAssertValidFarPointerXIP

incminor

export FontDrAddFonts
export FontDrDeleteFonts
export FontDrFindFileName
export FontDrGetFontIDFromFile

incminor

publish	HUGEARRAYCREATE
publish	HUGEARRAYGETCOUNT
publish	HUGEARRAYLOCK
publish GRDELETEGSTRINGELEMENT

incminor

export SYSGETINKWIDTHANDHEIGHT
export SYSSETINKWIDTHANDHEIGHT
export SysSetInkWidthAndHeight

export SYSENABLEAPO
export SYSDISABLEAPO


incminor	KernelNewForMailbox

export	VMGetHeaderInfo
export	SysSendNotification
export	SysHookNotification
export	SysUnhookNotification
export	SysIgnoreNotification
export	SYSSENDNOTIFICATION
export	SYSHOOKNOTIFICATION
export	SYSUNHOOKNOTIFICATION
export	SYSIGNORENOTIFICATION
publish	TIMERGETFILEDATETIME
export	ThreadCreate as ThreadCreateVirtual

incminor

export	VMCOPYVMCHAIN as VMCOPYVMCHAIN_ALMOST_FIXED
publish	VMFREEVMCHAIN
publish	VMCOMPAREVMCHAINS

incminor

export	GeodeInstallPatch
export	GrMoveToWWFixed
export	GRMOVETOWWFIXED

ifdef DO_DBCS

incminor
export  FontDrLockCharSet
export	LocalAddGengoName
export	LocalRemoveGengoName
export	LOCALADDGENGONAME
export	LOCALREMOVEGENGONAME

export	LocalIsKana
export	LocalIsKanji
export	LOCALISKANA
export	LOCALISKANJI

export	InitFileReadAllInteger
export	INITFILEREADALLINTEGER
export	LocalGetGengoInfo
export	LOCALGETGENGOINFO

export	LocalSetKinsoku
export	LocalGetKinsoku

export	LocalGetWordPartType
export	LOCALGETWORDPARTTYPE

#
# Use only for DBCS
#
skip	10

endif

incminor

export VMGetDirtySize
export VMGetUsedSize

incminor

export VMGETHEADERINFO

incminor

publish	HUGEARRAYNEXT

incminor

export GRSETVMFILE

incminor

publish VMCOPYVMCHAIN

incminor

export GRTESTPATH

incminor

export	GeodeRequestSpace
export	GEODEREQUESTSPACE
export	GeodeReturnSpace
export	GEODERETURNSPACE

incminor

export	ObjGetMessageData
export	OBJGETMESSAGEDATA

incminor

export VMDiscardDirtyBlocks
export VMDISCARDDIRTYBLOCKS

incminor

export FileGetHandleAllExtAttributes
export FILEGETHANDLEALLEXTATTRIBUTES

incminor

export MemDerefStackDS
export MemDerefStackES

incminor

export FileMoveLocal

incminor

export ThreadSetError
export THREADSETERROR

incminor

export ProfileWriteLogEntry
export ProfileInit
export ProfileExit
export ProfileReset
export ProfileWriteGenericEntry
export ProfileWriteMessageEntry

incminor

export	DBInfo

incminor

export	VMInfoVMChain

incminor

export	VMINFOVMCHAIN

incminor KernelDR_INITWithGeodeHandle

export	DBINFOUNGROUPED

incminor

export VMSetDirtyLimit
export VMSETDIRTYLIMIT

incminor

export GeodeSetGeneralPatchPath
export GeodeSetLanguagePatchPath
export IsMultiLanguageModeOn
export InitFileBackupLanguage
export InitFileSwitchLanguages
export GeodeSnatchResource

export GEODESETGENERALPATCHPATH
export GEODESETLANGUAGEPATCHPATH
export ISMULTILANGUAGEMODEON
export GEODESNATCHRESOURCE

incminor DevicePowerSubsystem

incminor

export GeodeSetLanguageStandardPath
export GEODESETLANGUAGESTANDARDPATH

incminor

export FILECOPYLOCAL
export FILEMOVELOCAL

incminor DocumentIndicatorSubsystem

export FileSetStandardPath as FileSetRootPath
export FILESETSTANDARDPATH as FILESETROOTPATH

incminor

export LOCALSETCODEPAGE

incminor

export GEODEGETGEODERESOURCEHANDLE

incminor IrdaStatusSubsystem

incminor

export InitFileMakeCanonicKeyCategory
export INITFILEMAKECANONICKEYCATEGORY

incminor

export ObjInstantiateForThread
export OBJINSTANTIATEFORTHREAD

incminor SocketStatusSubsystem

incminor UtilMappingWindow

export SysGetUtilWindowInfo
export SysMapUtilWindow
export SYSUNMAPUTILWINDOW
export SYSGETUTILWINDOWINFO
export SYSMAPUTILWINDOW

incminor InkDigitizerCoords

ifdef  GP_NO_PEN_SUPPORT
export NoPenSupportError as ImSetMouseBuffer
else
export ImSetMouseBuffer
endif

incminor Compression

export LZGCompress
export LZGCOMPRESS
export LZGUncompress
export LZGUNCOMPRESS
export LZGGetUncompressedSize
export LZGGETUNCOMPRESSEDSIZE
export LZGAllocCompressStack
export LZGALLOCCOMPRESSSTACK
export MemFree as LZGFreeCompressStack
export MEMFREE as LZGFREECOMPRESSSTACK

incminor SSTPowerOff
incminor BasicComponentDir
incminor TimezoneSupport

export LocalSetTimezone
export LocalGetTimezone
export LOCALGETTIMEZONE
export LOCALSETTIMEZONE
export LocalCompareDateTimes
export LOCALCOMPAREDATETIMES
export LocalNormalizeDateTime
export LOCALNORMALIZEDATETIME
export LocalCalcDayOfWeek
export LOCALCALCDAYOFWEEK

incminor
export FileCreateDirWithNativeShortName
export FILECREATEDIRWITHNATIVESHORTNAME

incminor
export VMEnforceHandleLimits
export VMENFORCEHANDLELIMITS

incminor
export FileSetCurrentPathRaw
export FILESETCURRENTPATHRAW

incminor
export GeodeUseDriverPermName
export GeodeUseLibraryPermName
export GEODEUSEDRIVERPERMNAME
export GEODEUSELIBRARYPERMNAME

incminor RawBitmapCreation
export GrCreateBitmapRaw
export GRCREATEBITMAPRAW

incminor
ifdef SIMPLE_RTL_SUPPORT
export GrSetTextDirection
export GRSETTEXTDIRECTION
endif
