##############################################################################
#
#	Copyright (c) GeoWorks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Kernel
# FILE:		ui.gp
#
# AUTHOR:	Tony, 10/89
#
#
# Parameters file for: ui.geo
#
#	$Id: ui.gp,v 1.2 98/05/04 05:43:26 joon Exp $
#
##############################################################################
#
# Permanent name..
#
name ui.lib
#
# Specify geode type
#
type	appl, library, process, single
#
# Specify stack size
#
stack   2000
#
# Heapspace requirement (64560 bytes /16)
#
heapspace 4035
#
# Specify class name for process
#
class	UserClass
#
# Specify application object
#
appobj	UIApp
#
# Import kernel routine definitions
#
library	geos
library compress noload
library net noload
#library	pcmcia noload
library	sound
library	wav

#
# Desktop-related things
#
longname	"Generic User Interface"
tokenchars	"UI00"
tokenid		0
#
# Define resources other than standard discardable code
nosort
resource Resident 		fixed code read-only shared
resource Common 		code read-only preload shared
resource VisUpdate 		code read-only preload shared
resource VisConstruct 		code read-only preload shared
resource VisCommon 		code read-only preload shared
resource Build 			code read-only preload shared
resource AppAttach 		code read-only preload shared
resource Init 			code read-only preload shared discard-only
resource ViewCommon		code read-only shared
resource TokenCommon		code read-only shared
resource Transfer		code read-only shared
resource GenPath		code read-only shared
resource ControlObject		code read-only shared
resource AppGCN			code read-only shared
resource FlowCommon		code read-only shared
resource TransferCommon		code read-only shared
resource Navigation		code read-only shared
resource GetUncommon		code read-only shared
resource IniFile		code read-only shared
resource GCCommon		code read-only shared
resource JustECCode		code read-only shared
resource GenUtils		code read-only shared
resource AppDetach		code read-only shared
resource IACPCommon		code read-only shared
resource IACPCode		code read-only shared
resource ItemCommon		code read-only shared
resource Ink			code read-only shared
resource TokenUncommon		code read-only shared
resource Exit			code read-only shared
resource BuildUncommon		code read-only shared
resource HelpControlCode	code read-only shared
resource DestroyCommon		code read-only shared
resource Text			code read-only shared
resource UtilityUncommon	code read-only shared
resource WindowFiddle		code read-only shared
resource RemoveDisk		code read-only shared
resource Activation		code read-only shared
resource FileSelectorCommon	code read-only shared
resource GCBuild		code read-only shared
resource ItemExtended		code read-only shared
resource DynaCommon		code read-only shared
resource Value			code read-only shared
resource C_Gen			code read-only shared
resource HelpControlInitCode	code read-only shared
resource C_Token		code read-only shared

ifndef GP_NO_CONTROLLERS
resource ControlCommon		code read-only shared
resource ControlCode		code read-only shared
resource GenToolControlCode	code read-only shared
endif

resource ExpressMenuControlCode code read-only shared
resource ExpressMenuCommon	code read-only shared
resource Password		code read-only shared
resource StdSoundErrorBeep 	data shared
resource StdSoundWarningBeep 	data shared
resource StdSoundNotifyBeep 	data shared
resource StdSoundNoInputBeep 	data shared
resource StdSoundKeyClick 	data shared
resource StdSoundAlarm 		data shared
resource StdSoundNoHelpBeep 	data shared

ifdef GP_HAS_EXTRA_SOUND_RESOURCES
# for resp only
resource RespSoundKeyClickLoud	data shared
resource RespSoundAlarmSound2	data shared
resource RespSoundAlarmSound3	data shared
endif

resource UserSound		code read-only shared
resource ListUtils		code read-only shared
resource C_User			code read-only shared
resource VisOpenClose		code read-only shared
resource VisUncommon		code read-only shared
resource ApplicationUI 		object
ifdef	GP_FAKE_SIZE_OPTIONS
resource HardIconUI 		object
endif
resource AppSCMonikerResource  	lmem
resource AppSMMonikerResource  	lmem
resource AppSCGAMonikerResource lmem
resource AppYCMonikerResource  	lmem
resource AppYMMonikerResource  	lmem
resource SystemFieldUI 		object
resource DeleteStateUI 		object
resource ShutdownStatusUI 	object
resource HelpObjectUI 		object
resource ActivatingUI 		object
resource Strings 		lmem shared read-only
resource ControlStrings 	lmem read-only shared
resource HelpControlUI 		object read-only shared
resource HelpControlStrings 	lmem read-only shared
resource PointerImages 		lmem read-only shared
resource IACPListBlock 		lmem shared

ifndef GP_NO_CONTROLLERS
resource AppTCMonikerResource  	lmem shared read-only
resource GenEditControlUI 	object read-only shared
resource GenEditControlToolboxUI 	object read-only shared
resource GenViewControlUI 		object read-only shared
resource GenViewControlToolboxUI 	object read-only shared
resource GenToolControlNormalUI 	object read-only shared
resource GenPageControlUI 		object read-only shared
resource GenPageControlToolboxUI 	object read-only shared
resource GenDisplayControlUI 		lmem object
resource GenDisplayControlToolboxUI	lmem object
endif

resource ExpressMenuControlUI 		object read-only shared
resource UserPasswordUI			object
resource TransferRemote			code read-only shared
resource LessCommon			code read-only shared
resource RemoteTransferStatusUI 	object
resource Undo				code read-only shared
resource UserClassStructures		fixed read-only shared
ifdef GP_FULL_EXECUTE_IN_PLACE
resource ResidentXIP			code fixed read-only shared
resource UserCStubXIP			code fixed read-only shared
resource UIControlInfoXIP		read-only shared
endif
resource EMOMCommon			code read-only shared
resource EMTriggerCommon		code read-only shared 
resource UserSaveDocName		code read-only shared


#
# Export routines
#

#Classes
export GenProcessClass
export FlowClass
export GenTriggerClass
export GenDisplayClass
export GenApplicationClass
export GenFieldClass
export GenScreenClass
export GenSystemClass
export GenViewClass
export GenContentClass
export GenInteractionClass
export GenGlyphClass
export GenTextClass
export GenDisplayGroupClass
export GenPrimaryClass
export GenGadgetClass
skip 1

export GenDocumentGroupClass
export GenDocumentClass
export GenFileSelectorClass
export GenBooleanGroupClass
export GenItemGroupClass
export GenDynamicListClass
export GenItemClass
export GenBooleanClass
export GenControlClass
export GenValueClass
export GenEditControlClass
export GenToolControlClass
export GenViewControlClass
export GenPageControlClass
export GenDisplayControlClass
skip 3

#
#	Classes used in the GenPenInputControl object
#	VisCachedGStateClass, VisKeyboardClass, VisCharTableClass
# and VisHWRGridClass have been moved the SPUI, as GenPenInputControlClass
# now has a specific UI implementation.  Skip the exports where these used
# to be defined in the UI
#
export GenPenInputControlClass
skip 4


export VisSpecNotifyEnabled
export VisSpecNotifyNotEnabled
skip 1

# Flow messages
export FlowTranslatePassiveButton
export FlowGetUIButtonFlags
export FlowForceGrab
export FlowRequestGrab
export FlowReleaseGrab
export ClipboardStartQuickTransfer
export ClipboardEndQuickTransfer
export FlowCheckKbdShortcut
export FlowAlterHierarchicalGrab
export FlowUpdateHierarchicalGrab
skip 1
export FlowGetTargetAtTargetLevel
export ClipboardAbortQuickTransfer

skip 1

export FlowDispatchSendOnOrDestroyClassedEvent

# Generic routines
export GenClass
export GenDocumentControlClass
export GenFindMoniker
export GenDrawMoniker
export GenGetMonikerSize
export UserCallSystem
export GenCallParent
export UserCallApplication as GenCallApplication
export UserSendToApplicationViaProcess
export GenFindParent
export GenSwapLockParent
export GenSendToChildren
export GenCallNextSibling
export GenInsertChild
export GenCopyChunk
export GenAddChildUpwardLinkOnly
export GenSetUpwardLink
export GenRemoveDownwardLink
export GenProcessGenAttrsBeforeAction
export GenControlOutputActionRegs
export GenControlOutputActionStack
export GenSpecShrink
export GenFindObjectInTree
export GenCheckIfFullyUsable
export GenCheckIfFullyEnabled
export GenCheckIfSpecGrown
export GenCheckKbdAccelerator
export GenInstantiateIgnoreDirty
export GenProcessGenAttrsAfterAction
export GenProcessAction
export GenRelocMonikerList
export UserGetInitFileCategory
export USERGETINITFILECATEGORY
export GenGotoParentTailRecurse
skip 2

ifdef GP_FULL_EXECUTE_IN_PLACE
export GenPathSetObjectPathXIP as GenPathSetObjectPath
else
export GenPathSetObjectPath
endif
export GenPathGetObjectPath
export GenPathSetCurrentPathFromObjectPath
export GenPathUnrelocObjectPath
export GenPathFetchDiskHandleAndDerefPath
export GenPathConstructFullObjectPath

# GenView routines
export GenViewSetSimpleBounds
export GenSetupTrackingArgs
export GenReturnTrackingArgs
export GenViewSendToLinksIfNeeded

#GenItemGroup/GenBooleanGroup routines
export GenBooleanSendMsg
export GenItemSendMsg

#GenControl routines
export GenControlSendToOutputRegs
export GenControlSendToOutputStack

# token DB routines
export TokenDefineToken
export TokenGetTokenInfo
export TokenLookupMoniker
export TokenLoadMoniker
export TokenRemoveToken
export TokenGetTokenStats
export TokenLoadToken
export TokenLockTokenMoniker
export TokenUnlockTokenMoniker
export TokenListTokens

# User routines
export UserAllocObjBlock
export UserCallFlow
export UserCopyChunkOut
export UserDoDialog
export UserLoadApplication
export ClipboardRegisterItem
export ClipboardQueryItem
export ClipboardRequestItemFormat
export ClipboardDoneWithItem
export ClipboardUnregisterItem
export ClipboardGetNormalItemInfo
export ClipboardGetQuickItemInfo
export ClipboardGetUndoItemInfo
export ClipboardGetClipboardFile
export ClipboardAddToNotificationList
export ClipboardRemoveFromNotificationList
export UserHaveProcessCopyChunkIn
export UserHaveProcessCopyChunkOut
export UserHaveProcessCopyChunkOver
export UserScreenRegister
ifdef GP_FULL_EXECUTE_IN_PLACE
export UserAddAutoExecXIP as UserAddAutoExec
export UserRemoveAutoExecXIP as UserRemoveAutoExec
else
export UserAddAutoExec
export UserRemoveAutoExec
endif
export UserCheckAcceleratorChar
export UserCallApplication
export UserCheckInsertableCtrlChar
export UserCreateItem
export UserAddItemToGroup
export UserStandardSound
export UserSetDefaultMonikerFont
export UserGetDisplayType
ifdef GP_FULL_EXECUTE_IN_PLACE
export UserLoadExtendedDriverXIP as UserLoadExtendedDriver
else
export UserLoadExtendedDriver
endif
export UserGetOverstrikeMode
export UserSetOverstrikeMode
export UserMessageIM
export ClipboardGetQuickTransferStatus
export ClipboardSetQuickTransferFeedback
export ClipboardGetItemInfo
export ClipboardClearQuickTransferNotification
export ClipboardHandleEndMoveCopy
export ClipboardTestItemFormat
export ClipboardEnumItemFormats
export ClipboardFreeItem
export UserGetSpecUIProtocolRequirement
export USERGETHWRLIBRARYHANDLE
export UserCreateInkDestinationInfo
export USERGETDEFAULTLAUNCHLEVEL
export USERGETINTERFACEOPTIONS

export GenValueSendMsg

# Visual routines
export VisEmptyClass
export VisClass
export VisCompClass
export VisContentClass
export VisInitialize
export VisCompInitialize
export VisGetSize
export VisGetBounds
export VisGetCenter
export VisCallParent
export VisFindParent
export VisSwapLockParent
export VisSendToChildren
export VisCallChildUnderPoint
export VisCallFirstChild
export VisRecalcSizeAndInvalIfNeeded
export VisSendPositionAndInvalIfNeeded
export VisTestPointInBounds
export VisQueryWindow
export VisQueryParentWin
export VisGetParentGeometry
export VisMarkInvalid
export VisSetSize
export VisSetPosition
export VisFindMoniker
export VisGetMonikerSize
export VisGetMonikerPos
export VisDrawMoniker
export VisInsertChild
export VisConvertSpecVisSize
export VisConvertCoordsToRatio
export VisConvertRatioToCoords
export VisGetVisParent
export VisAddChildRelativeToGen
export VisGetSpecificVisObject
export VisMarkFullyInvalid
export VisCheckIfSpecBuilt
export VisCheckIfVisGrown
export VisGrabMouse
export VisForceGrabMouse
export VisGrabLargeMouse
export VisForceGrabLargeMouse
export VisReleaseMouse
export VisAddButtonPrePassive
export VisRemoveButtonPrePassive
export VisAddButtonPostPassive
export VisRemoveButtonPostPassive
export VisTakeGadgetExclAndGrab
export VisGrabKbd
export VisForceGrabKbd
export VisReleaseKbd
export VisGetParentCenter
export VisSendCenter
export VisCallNextSibling
export VisNavigateCommon
export VisCheckOptFlags
export VisRemove
export VisIfFlagSetCallVisChildren
export VisIfFlagSetCallGenChildren
export VisMarkInvalidOnParent
export VisSpecBuild
export VisCompGetCenter
export VisCompRecalcSize
export VisCheckMnemonic
export VisSpecBuildSetEnabledState
export VisSendSpecBuild
export VisSendSpecBuildBranch
export VisCompPosition
export VisSetNotRealized
export VisApplySizeHints
export VisSetupSizeArgs
export VisApplySizeArgsToWidth
export VisApplySizeArgsToHeight
export VisApplyInitialSizeArgs
export VisGetBoundsInsideMargins
export VisCompMakePressesInk
export VisCompMakePressesNotInk
export VisCallChildrenInBounds
export VisObjectHandlesInkReply
export VisCompDraw
export VisCallCommon
export VisGotoParentTailRecurse

# Meta routines
export MetaGrabFocusExclLow
export MetaReleaseFocusExclLow
export MetaGrabTargetExclLow
export MetaReleaseTargetExclLow
export MetaGrabModelExclLow
export MetaReleaseModelExclLow
export MetaReleaseFTExclLow


# EC routines
export ECCheckUILMemOD
export ECCheckODCXDX
export ECCheckLMemODCXDX
export ECCheckUILMemODCXDX
export ECEnsureInGenTree
export ECVisStartNavigation
export ECVisEndNavigation
export ECCheckVisFlags
export ECCheckVisCoords
export GenEnsureNotUsable
export VisCheckVisAssumption
export CheckForDamagedES
export GenCheckGenAssumption

#C Stuff
export CLIPBOARDREGISTERITEM
export CLIPBOARDUNREGISTERITEM
export CLIPBOARDQUERYITEM
export CLIPBOARDTESTITEMFORMAT
export CLIPBOARDENUMITEMFORMATS
export CLIPBOARDGETITEMINFO
export CLIPBOARDREQUESTITEMFORMAT
export CLIPBOARDDONEWITHITEM
export CLIPBOARDGETNORMALITEMINFO
export CLIPBOARDGETQUICKITEMINFO
export CLIPBOARDGETUNDOITEMINFO
export CLIPBOARDGETCLIPBOARDFILE
export CLIPBOARDADDTONOTIFICATIONLIST
export CLIPBOARDREMOVEFROMNOTIFICATIONLIST
export CLIPBOARDSTARTQUICKTRANSFER
export CLIPBOARDGETQUICKTRANSFERSTATUS
export CLIPBOARDSETQUICKTRANSFERFEEDBACK
export CLIPBOARDENDQUICKTRANSFER
export CLIPBOARDABORTQUICKTRANSFER
export CLIPBOARDCLEARQUICKTRANSFERNOTIFICATION
export CLIPBOARDHANDLEENDMOVECOPY
export USERDODIALOG

export GENCOPYCHUNK
export GENINSERTCHILD
export GENSETUPWARDLINK
export GENREMOVEDOWNWARDLINK
export GENSPECSHRINK
export GENPROCESSGENATTRSBEFOREACTION
export GENPROCESSGENATTRSAFTERACTION
export GENFINDOBJECTINTREE

export FLOWALTERHIERARCHICALGRAB
export FLOWUPDATEHIERARCHICALGRAB
skip 1
export FLOWDISPATCHSENDONORDESTROYCLASSEDEVENT

export TOKENDEFINETOKEN
export TOKENGETTOKENINFO
export TOKENLOOKUPMONIKER
export TOKENLOADMONIKERBLOCK
export TOKENLOADMONIKERCHUNK
export TOKENLOADMONIKERBUFFER
export TOKENREMOVETOKEN
export TOKENGETTOKENSTATS
export TOKENLOADTOKENBLOCK
export TOKENLOADTOKENCHUNK
export TOKENLOADTOKENBUFFER
export TOKENLOCKTOKENMONIKER
export TOKENUNLOCKTOKENMONIKER
export TOKENLISTTOKENS

export _UserStandardSound as _UserStandardSound_Old

export USERADDAUTOEXEC
export USERREMOVEAUTOEXEC
export USERSTANDARDDIALOG
export USERSTANDARDDIALOGOPTR

export GenToolGroupClass

export GENPROCESSUNDOGETFILE
export GENPROCESSUNDOCHECKIFIGNORING
skip 1

export UserCreateDialog
export UserDestroyDialog

export USERCREATEDIALOG
export USERDESTROYDIALOG

ifdef GP_FULL_EXECUTE_IN_PLACE
export IACPRegisterServerXIP as IACPRegisterServer
export IACPUnregisterServerXIP as IACPUnregisterServer
export IACPConnectXIP as IACPConnect
else
export IACPRegisterServer
export IACPUnregisterServer
export IACPConnect
endif
export IACPSendMessage
export IACPSendMessageToServer
export IACPShutdown
export IACPShutdownAll
export IACPProcessMessage
export IACPLostConnection
export IACPShutdownConnection
export IACPCreateDefaultLaunchBlock
export IACPGetServerNumber
export IACPREGISTERSERVER
export IACPUNREGISTERSERVER
export IACPCONNECT
export IACPSENDMESSAGE
export IACPSENDMESSAGETOSERVER
export IACPSHUTDOWN
export IACPSHUTDOWNALL
export IACPPROCESSMESSAGE
export IACPLOSTCONNECTION
skip 1	# was IACPSHUTDOWNCONNECTION
export IACPCREATEDEFAULTLAUNCHBLOCK
export IACPGETSERVERNUMBER

export UserRegisterForTextContext
export UserUnregisterForTextContext

export USERREGISTERFORTEXTCONTEXT
export USERUNREGISTERFORTEXTCONTEXT
export USERCHECKIFCONTEXTUPDATEDESIRED

export UserGetDefaultMonikerFont
export USERGETDEFAULTUILEVEL

#
#	Classes used in HelpControl object
#
export HelpControlClass
export HelpTextClass
#
#	Routines used for help
#
ifdef GP_FULL_EXECUTE_IN_PLACE
export HelpSendHelpNotificationXIP as HelpSendHelpNotification
else
export HelpSendHelpNotification
endif
export HelpSendFocusNotification

export VISOBJECTHANDLESINKREPLY

export ExpressMenuControlClass

export UserDiskRestore
export USERDISKRESTORE

export USERGETLAUNCHMODEL

export UserGetKbdAcceleratorMode

export VisCallParentEnsureStack

export UIApplicationClass

export USERGETLAUNCHOPTIONS

export ClipboardRemoteSend
export ClipboardRemoteReceive
export CLIPBOARDREMOTESEND
export CLIPBOARDREMOTERECEIVE
export USERCREATEINKDESTINATIONINFO
# HWRGridContextTextClass has been moved to the SPUI
skip 1
export GenCallParentEnsureStack
export EMCInteractionClass

# added at the end to avoid upping major protocol
export USERLOADAPPLICATION
export FLOWCHECKKBDSHORTCUT
export HELPSENDHELPNOTIFICATION

export EMCPanelInteractionClass

export IACPRegisterDocument
export IACPUnregisterDocument
export IACPFinishConnect
export IACPREGISTERDOCUMENT
export IACPUNREGISTERDOCUMENT
export IACPFINISHCONNECT
ifdef GP_FULL_EXECUTE_IN_PLACE
export IACPGetDocumentIDXIP as IACPGetDocumentID
else
export IACPGetDocumentID
endif
export USERALLOCOBJBLOCK
export TOKENOPENLOCALTOKENDB
export TOKENCLOSELOCALTOKENDB
export CLIPBOARDOPENCLIPBOARDFILE
export CLIPBOARDCLOSECLIPBOARDFILE
# NotifyEnabledStateGenViewClass has been moved to the SPUI
skip 1
export UserEncryptPassword
export USERENCRYPTPASSWORD
incminor UINewForZoomer
export GENAPPCLOSEKEYBOARD
incminor UINewFor21
export UserGetFloatingKbdEnabledStatus
ifdef GP_FULL_EXECUTE_IN_PLACE
export IACPLocateServerXIP as IACPLocateServer
export IACPBindTokenXIP as IACPBindToken
export IACPUnbindTokenXIP as IACPUnbindToken
else
export IACPLocateServer
export IACPBindToken
export IACPUnbindToken
endif
export IACPLOCATESERVER
export IACPBINDTOKEN
export IACPUNBINDTOKEN
incminor
export EMObjectManagerClass
export EMTriggerClass
incminor
export ClipboardFreeItemsNotInUse
incminor GenValuePercentageFormat
incminor
export GenViewSendToLinksIfNeededDirection
incminor IACPNewForJedi
export IACPConnectToDocumentServer
export IACPCONNECTTODOCUMENTSERVER
export IACPSendMessageAndWait
export IACPSENDMESSAGEANDWAIT
export IACPGETDOCUMENTID
#export IACPGetDocumentConnectionFileID
#export IACPGETDOCUMENTCONNECTIONFILEID
incminor NewForJediAndBeyond
incminor UINewForResponder
incminor UINewForDove
incminor UINewForNike
incminor PCVWindowHints
incminor UINewForResponder_2
incminor LegosLooksSupport
incminor UINewForResponder_3
incminor UINewForResponder_4
incminor NewForOmniGo200
incminor
publish _UserStandardSound
incminor PCVLooks_2
incminor
export UserStopStandardSound
export USERSTOPSTANDARDSOUND
incminor UINewForPenelope
incminor PCVLooks_3
incminor UINewForPenelope_2
incminor UINewForDove_2
incminor UINewInteractionCommands
incminor UINewForFloatingKbd
incminor UINoFileList
incminor userExclAPI
incminor IACPForDataExchange
incminor UINewForShortLongTouch
incminor NewForLizzy
incminor UIFullWidthTextFilters
export EMCTriggerClass

#
# code used to restore and retrieve most recently opened documents
#
export UserStoreDocFileName
export USERGETRECENTDOCFILENAME
export UserGetRecentDocFileName

incminor UITemplateWizard
incminor UIFocusDisabledHelp
incminor UIGlyphSeparator
incminor UIIconTextMoniker

export UserCreateIconTextMoniker
export USERCREATEICONTEXTMONIKER

incminor UINoHelpButton
incminor UINewOptions
incminor UIDoneDialog
incminor UIExtraKbdAccelerators
incminor UIDocumentTemplateWizard

export UserConfirmFieldChange
export _UserConfirmFieldChange

incminor UIMinimizeReplacesClose

incminor UINewForGPC

incminor UINoInputDestination

incminor UINewDocWarning

export USERGETSYSTEMSHUTDOWNSTATUS

incminor UISetTemplateUserLevel

incminor UIHideMinimize

incminor TriggerRGB

incminor UIStandardTimedDialog
