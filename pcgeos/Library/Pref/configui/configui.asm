COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Designs in Light 2002 -- All Rights Reserved

FILE:		configui.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;	Common GEODE stuff
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def
include	library.def
include system.def

include object.def
include	graphics.def
include gstring.def
include	win.def

include char.def
include initfile.def

include Internal/specUI.def

;-----------------------------------------------------------------------------
;	Libraries used		
;-----------------------------------------------------------------------------
 
UseLib	ui.def
UseLib	config.def
UseLib  Objects/vTextC.def
UseLib	Objects/colorC.def

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include configui.def
include configui.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment

idata ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------

include configuiProgList.asm
include configuiFileAssoc.asm
include prefMinuteValue.asm
 
ConfigUICode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		none
RETURN:		dx:ax - OD of root of tree
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConfigUIGetPrefUITree	proc far
	mov	dx, handle ConfigUIRoot
	mov	ax, offset ConfigUIRoot
	ret
ConfigUIGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIGetModuleInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the PrefModuleInfo buffer so that PrefMgr
		can decide whether to show this button

CALLED BY:	PrefMgr
PASS:		ds:si - PrefModuleInfo structure to be filled in
RETURN:		ds:si - buffer filled in

DESTROYED:	ax,bx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECSnd/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConfigUIGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_SYSTEM
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, 1
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  ConfigUIMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset ConfigUIMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'T' or ('w' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
ConfigUIGetModuleInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIDialogInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The dialog has opened, do some setup

CALLED BY:	MSG_GEN_INTERACTION_INITIATE

PASS:		none
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ConfigUIDialogInitiate	method	dynamic	ConfigUIDialogClass,
						MSG_GEN_INTERACTION_INITIATE
		.enter

	;
	; Check what ui we're using, and configure the UI for it.
	;
		call	DisableSpecificUIItems
	
	;
	; if on 16 color, disable the 256 color selector
	;
		push	ax, si
		call	UserGetDisplayType
		and	ah, mask DT_DISP_CLASS
		cmp	ah, DC_COLOR_4 shl (offset DT_DISP_CLASS)
		ja	not16color
		mov	si, offset ColorList
		mov	ax, ATTR_GEN_CONTROL_PROHIBIT_UI
		call	ObjVarFindData
		mov	{word}ds:[bx], not (mask CSF_INDEX)	;16 color only
not16color:
		pop	ax, si
	;
	; Do the normal superclass stuff, including loading our
	; initial state from the .INI file.
	;
		mov	di, offset ConfigUIDialogClass
		call	ObjCallSuperNoLock
	;
	; Manually load the not usable stuff from the .INI file --
	; it doesn't happen automatically since it is not usable.
	;
		mov	si, offset ExpressSettings
		call	loadOptions
		mov	si, offset InterfaceSettings
		call	loadOptions
		mov	si, offset AdvancedSettings
		call	loadOptions
		mov	si, offset DriveSettings
		call	loadOptions
		mov	si, offset AppearanceSettings
		call	loadOptions
		mov	si, offset AppSettings
		call	loadOptions
	;
	; set up the font area
	;
		mov	si, offset FontSizeArea
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		call	ObjCallInstanceNoLock
	;
	; set up the file association / icon stuff
	;
		mov	si, offset ChangeTokenList
		mov	ax, MSG_ITL_INIT_LIST
		call	ObjCallInstanceNoLock
	;
	; indicate no changes between sections
	;
		mov	si, offset SectionList
		mov	ax, MSG_GEN_RESET
		call	ObjCallInstanceNoLock

		.leave
		ret

loadOptions:
		mov	ax, MSG_META_LOAD_OPTIONS
		call	ObjCallInstanceNoLock
		retn
ConfigUIDialogInitiate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunningISUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we're running ISUI or not

CALLED BY:	PrefMgr

PASS:		ds - seg addr of ConfigUIUI
RETURN:		z flag - set (jz) if running ISUI
DESTROYED:	es

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RunningISUI	proc	near
		uses	ax, bx, cx, dx, bp, di, si, ds, es
spuiBuf		local	FileLongName
		.enter
	;
	; See which UI we're running
	;
		push	bp
		segmov	ds, cs, cx
		mov	si, offset uiCategory
		mov	dx, offset specificKey
		segmov	es, ss
		lea	di, ss:spuiBuf
		mov	bp, InitFileReadFlags <IFCC_INTACT, 0, 0,
						(size spuiBuf)>
		call	InitFileReadString
		pop	bp
		clr	cx				;cx <- NULL-terminated
		mov	bx, handle ISUIName
		call	MemLock
		mov	ds, ax
		mov	si, offset ISUIName
		mov	si, ds:[si]			;ds:si <- ISUI name
		call	LocalCmpStrings
		call	MemUnlock

		je	yesISUI				;check long filename 
		push	ds
		segmov	ds, cs
		mov	si, offset ISUIGeode		;check DOS filename 
		call	LocalCmpStringsNoCase
		pop	ds
yesISUI:
		.leave
		ret
RunningISUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableSpecificUIItems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable UI not applicable to the current specific UI

CALLED BY:	PrefMgr

PASS:		ds - object block
RETURN:		ds - fixed up
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

specificKey	char "specific",0

ISUIDisableList	lptr \
	EOGotoGeoManager,
	EORunningApps,
	EOExitToDOS,
	EOWorldApps,
	EOWorldSubdirs,
	EOControlPanel,
	EOUtilities,
	ESORunningApps,
	ESOWorldAppsSubmenu,
	ESOOtherSubmenu,
	AOLConfirmShutdown,
	UIO1WinMenu,
	ScrollbarSizeGroup,
	UIO3Blinky,
	EODocumentsList

motifDisableList	lptr \
	EO2SmallIcons,
	UIO3AutohideTaskbar,
	UIO3RightClickHelp

EC < LocalDefNLString ISUIGeode <"isuiec.geo", 0>
NEC < LocalDefNLString ISUIGeode <"isui.geo", 0>

DisableSpecificUIItems	proc	near
		uses	es
isISUI		local	byte
		.enter
		pusha

		mov	ss:isISUI, FALSE
		mov	cx, length motifDisableList
		mov	bx, offset motifDisableList
		call	RunningISUI
		jnz	notISUI
		mov	ss:isISUI, TRUE
		mov	cx, length ISUIDisableList
		mov	bx, offset ISUIDisableList
notISUI:
	;
	; Disable the items
	;
		push	bp
		clr	di
disableLoop:
		push	cx
		mov	si, cs:[bx][di]
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
		pop	cx
		add	di, (size lptr)
		loop	disableLoop
		pop	bp
done::
	;
	; set the ini category for objects that need to	store settings
	; in different sections for different SpUIs
	;
		mov	ax, MSG_PREF_SET_INIT_FILE_CATEGORY
		mov	cx, cs
		mov	dx, offset uiFeaturesCat
		mov	si, offset UIOptionsLists
		call	ObjCallInstanceNoLock
		mov	si, offset ExpressOptions
		call	ObjCallInstanceNoLock
		mov	si, offset AppOptions1
		call	ObjCallInstanceNoLock

		popa
		.leave
		ret
DisableSpecificUIItems	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISUIDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply has been pressed

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ConfigUIDialogApply	method	dynamic	ConfigUIDialogClass,
						MSG_GEN_APPLY
		uses	si
		.enter
	;
	; See if the UI has changed
	;
		mov	ax, MSG_GEN_ITEM_GROUP_IS_MODIFIED
		mov	si, offset UIList
		call	ObjCallInstanceNoLock
		jnc	checkReset2			;branch if no mod.
	;
	; set the various options for the UI combo
	;
		mov	si, offset UIList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	noUISelected
		call	SetUIOptions
noUISelected:
		jmp	doReset


	;
	; See if the file manager options have changed, and force a
	; reboot if so
	;
checkReset2:
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_MODIFIED_BOOLEANS
		mov	si, offset FileMgrOptions
		call	ObjCallInstanceNoLock
		tst	ax				;any changes?
		jz	noReset				;branch if mod.
	;
	; If so, force the state files to be deleted when we restart so
	; that the correct launcher will be launched.
	;
doReset:
		push	ds
		segmov	ds, cs, cx
		mov	si, offset uiCategory		;ds:si <- category
		mov	dx, offset forceResetKey	;cx:dx <- key
		mov	ax, TRUE			;ax <- set to TRUE
		call	InitFileWriteBoolean
		pop	ds

noReset:
	;
	; Manually apply to each section.  It doesn't happen automatically
	; since some of them are not usable.
	;
		mov	si, offset AppSettings
		call	saveOptions
		mov	si, offset ExpressSettings
		call	saveOptions
		mov	si, offset InterfaceSettings
		call	saveOptions
		mov	si, offset AdvancedSettings
		call	saveOptions
		mov	si, offset DriveSettings
		call	saveOptions
		mov	si, offset AppearanceSettings
		call	saveOptions
	;
	; Handle keyboard accelerator mode -- it has two flags, one
	; to turn it on/off, and another to show/hide the accelerators
	;
		mov	si, offset UIOptions1
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjCallInstanceNoLock
		xornf	ax, mask UIWO_KBD_NAVIGATION shl 8
		andnf	ax, mask UIWO_KBD_NAVIGATION shl 8
		push	ds
		segmov	ds, cs, cx
		mov	si, offset uiCategory
		mov	dx, offset kbdAccModeKey
		call	InitFileWriteBoolean
		pop	ds
	;
	; Handle automatically reset after crash -- it has two flags,
	; one to bypass the 'bad shutdown' message, and one to reset.
	;
		mov	si, offset AdvancedOptionsList
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjCallInstanceNoLock
		andnf	ax, mask CUIA_AUTO_RESET
		push	ds
		segmov	ds, cs, cx
		mov	si, offset uiCategory
		mov	dx, offset resetKey
		call	InitFileWriteBoolean
		pop	ds

	;
	; Do the superclass thing last
	;
		.leave
		mov	di, offset ConfigUIDialogClass
		mov	ax, MSG_GEN_APPLY
		GOTO	ObjCallSuperNoLock

saveOptions:
		mov	ax, MSG_GEN_APPLY
		call	ObjCallInstanceNoLock
		retn
ConfigUIDialogApply	endm

uiCategory	char "ui",0
kbdAccModeKey	char "kbdAcceleratorMode",0
resetKey	char "deleteStateFilesAfterCrash",0
forceResetKey	char "forceDeleteStateFilesOnceOnly",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIDialogPostApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an apply for the dialog box

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICDialogPostApply	method dynamic ConfigUIDialogClass,
						MSG_GEN_POST_APPLY
	;
	; Write out any of the colors that have changed
	;
		push	ds
		mov	si, offset motifOptsCategory	;ds:si <- category
		mov	cx, length colorKeys		;cx <- # entries
		clr	di				;di <- offset
colorLoop:
		segmov	ds, idata, ax			;ds <- idata
		cmp	ds:titleBarColor[di], C_UNUSED_0
		je	notChanged
	;
	; Get the color from the .INI file or the default, and see
	; if the user value has actually changed anything.
	;
		call	GetINIColor
		cmp	ds:titleBarColor[di], al	;unchanged?
		je	notChanged			;branch if not changed
	;
	; The value has changed -- write it out to the .INI file
	;
		clr	ax
		mov	al, ds:titleBarColor[di]	;ax <- Color
		push	cx, di
		segmov	ds, cs, cx			;ds:si <- category
		mov	cx, cs
		shl	di, 1
		mov	dx, cs:colorKeys[di]		;cx:dx <- key
		mov	bp, ax				;bp <- value
		call	InitFileWriteInteger
		pop	cx, di
notChanged:
		inc	di
		loop	colorLoop			;loop while more
		pop	ds
	;
	; Call our superclass last
	;
		mov	ax, MSG_GEN_POST_APPLY
		mov	si, offset ConfigUIRoot
		mov	di, offset ConfigUIDialogClass
		GOTO	ObjCallSuperNoLock

PrefUICDialogPostApply	endm

colorKeys	nptr \
	titleBarKey,
	titleBar2Key,
	darkColorKey,
	lightColorKey,
	fileMgrKey,
	helpbgKey,
	selectKey

CheckHack <length colorKeys eq ConfigUIColor>

defaultMotifColors	Color \
	C_DARK_GRAY,			;title bar
	C_DARK_GRAY,			;title bar gradient
	C_DARK_GRAY,			;dark color
	C_LIGHT_GRAY,			;light color
	C_WHITE,			;file folder
	C_WHITE,			;help BG color
	C_DARK_GRAY			;selection

CheckHack <length defaultMotifColors eq ConfigUIColor>

motifOptsCategory	char "motif options",0

titleBarKey		char "activeTitleBarColor",0
titleBar2Key		char "titleBarGradient", 0
darkColorKey		char "darkColor",0
lightColorKey		char "lightColor",0
fileMgrKey		char "fileMgrColor",0
helpbgKey		char "helpbgColor", 0
selectKey		char "selectColor", 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICDialogAreaChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the color list to reflect the selected area

CALLED BY:	PrefMgr

PASS:		cx - current selection (PrefUIColor)
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICDialogAreaChanged	method	dynamic	ConfigUIDialogClass,
						MSG_CUID_AREA_CHANGED
		.enter

		mov	di, cx				;di <- selection
		call	GetCurrentColor			;al <- current color
		call	UpdateColor

		.leave
		ret
PrefUICDialogAreaChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICDialogSPUIChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the sample to reflect the SPUI

CALLED BY:	PrefMgr

PASS:		cx - current selection (PrefUICombo)
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICDialogSPUIChanged	method	dynamic	ConfigUIDialogClass,
						MSG_CUID_SPUI_CHANGED
		.enter

	;
	; redraw the sample
	;
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		mov	si, offset ColorSample
		call	ObjCallInstanceNoLock
	;
	; update the sample font
	;
		call	UpdateSampleFont

		.leave
		ret
PrefUICDialogSPUIChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICSetDefaultColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the colors to the defaults

CALLED BY:	PrefMgr

PASS:		cx - PrefUIDefaultColorScheme
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

defaultColorLists nptr \
	defaultMotifColors,
	defaultISUIColors,
	defaultCyanColors,
	defaultEarthColors,
	defaultMerlotColors,
	defaultCorporateColors,
	defaultForestColors,
	defaultSedonaColors,
	defaultStainlessColors,
	defaultContrastColors,
	defaultOceanColors,
	defaultBlueSkyColors,
	defaultEmeraldColors,
	defaultTealColors,
	defSwimmingPoolColors,
	defGreySkyColors,
	defCuppaJoeColors,
	defGreyAndRedColors,
	defGreyAndGreenColors

CheckHack <length defaultColorLists eq ConfigUIDefaultColorScheme>

defaultISUIColors	Color \
	C_BLUE,				;title bar
	C_BLUE,				;title bar gradient
	C_DARK_GRAY,			;dark color
	C_LIGHT_GRAY,			;light color
	C_WHITE,			;file folder
	C_LIGHT_GRAY,			;help BG color
	C_BLUE				;selection

defaultCyanColors	Color \
	C_BLACK,			;title bar
	C_BLACK,			;title bar gradient
	C_BLACK,			;dark color
	C_CYAN,				;light color
	C_WHITE,			;file folder
	C_WHITE,			;help BG color
	C_DARK_GRAY			;selection

defaultEarthColors	Color \
	C_R2_G3_B2,			;title bar
	C_R2_G3_B2,			;title bar gradient
	C_DARK_GRAY,			;dark color
	C_LIGHT_GRAY,			;light color
	C_R2_G3_B3,			;file folder
	C_R5_G5_B4,			;help BG color
	C_DARK_GRAY			;selection

defaultMerlotColors	Color \
	113,				;title bar
	194,				;title bar gradient
	114,				;dark color
	163,				;light color
	162,				;file folder
	248,				;help BG color
	114				;selection

defaultCorporateColors	Color \
	43,				;title bar
	41,				;title bar gradient
	8,				;dark color
	27,				;light color
	15,				;file folder
	253,				;help BG color
	43				;selection

defaultForestColors Color \
	46,				;title bar
	95,				;title bar gradient
	47,				;dark color
	132,				;light color
	30,				;file folder
	254,				;help BG color
	47				;selection

defaultSedonaColors Color \
	191,				;title bar
	112,				;title bar gradient
	154,				;dark color
	247,				;light color
	240,				;file folder
	254,				;help BG color
	154				;selection

defaultStainlessColors Color \
	24,				;title bar
	20,				;title bar gradient
	19,				;dark color
	27,				;light color
	7,				;file folder
	25,				;help BG color
	20				;selection

defaultContrastColors Color \
	0,				;title bar
	0,				;title bar gradient
	0,				;dark color
	30,				;light color
	15,				;file folder
	15,				;help BG color
	0				;selection

defaultOceanColors Color \
	48,				;title bar
	41,				;title bar gradient
	46,				;dark color
	140,				;light color
	183,				;file folder
	146,				;help BG color
	78				;selection

defaultBlueSkyColors Color \
	9,				;title bar
	11,				;title bar gradient
	8,				;dark color
	69,				;light color
	177,				;file folder
	146,				;help BG color
	87				;selection

defaultEmeraldColors Color \
	0,				;title bar
	2,				;title bar gradient
	8,				;dark color
	60,				;light color
	133,				;file folder
	254,				;help BG color
	24				;selection

defaultTealColors Color \
	3,				;title bar
	10,				;title bar gradient
	8,				;dark color
	61,				;light color
	133,				;file folder
	254,				;help BG color
	25				;selection

defSwimmingPoolColors Color \
	0,				;title bar
	99,				;title bar gradient
	8,				;dark color
	62,				;light color
	134,				;file folder
	254,				;help BG color
	51				;selection

defGreySkyColors Color \
	48,				;title bar
	15,				;title bar gradient
	19,				;dark color
	28,				;light color
	27,				;file folder
	7,				;help BG color
	99				;selection

defCuppaJoeColors Color \
	160,				;title bar
	211,				;title bar gradient
	24,				;dark color
	211,				;light color
	203,				;file folder
	254,				;help BG color
	155				;selection

defGreyAndRedColors Color \
	185,				;title bar
	7,				;title bar gradient
	24,				;dark color
	27,				;light color
	205,				;file folder
	254,				;help BG color
	192				;selection

defGreyAndGreenColors Color \
	67,				;title bar
	8,				;title bar gradient
	8,				;dark color
	25,				;light color
	27,				;file folder
	254,				;help BG color
	60				;selection

PrefUICSetDefaultColor	method dynamic ConfigUIDialogClass,
					MSG_CUID_SET_DEFAULT_COLORS
		cmp	cx, GIGS_NONE
		je	done
	;
	; Get the default list to use
	;
		mov	di, cx
		shl	di
		mov	bx, cs:defaultColorLists[di]
	;
	; Set the variables to the defaults
	;
		clr	di
		mov	cx, ConfigUIColor
colorLoop:
		mov	al, cs:[bx][di]
		mov	es:titleBarColor[di], al
		inc	di
		loop	colorLoop
	;
	; Update the UI
	;
		push	si
		mov	si, offset AreaList
		clr	cx, dx				;cx <- 1st, dx <- det.
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
		pop	si

		clr	cx				;cx <- 1st list
		mov	ax, MSG_CUID_AREA_CHANGED
		call	ObjCallInstanceNoLock
done:
		ret
PrefUICSetDefaultColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICDialogInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the dialog

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICDialogInit	method	dynamic	ConfigUIDialogClass, MSG_PREF_INIT

		uses	ax, si

		.enter
	;
	; See if the is B&W -- if so, we'll remove the Color section
	;
		call	UserGetDisplayType
		and	ah, mask DT_DISP_CLASS
		cmp	ah, DC_GRAY_1 shl (offset DT_DISP_CLASS)
		ja	notBW				;branch if not B&W
	;
	; Set the Color stuff not usable
	;
		mov	si, offset ColorGroup
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
notBW:
	;
	; see if a large screen -- if not, disable 18 point
	;
		mov	cx, GUQT_FIELD
		mov	ax, MSG_GEN_GUP_QUERY
		call	UserCallApplication
		mov	di, bp
		call	WinGetWinScreenBounds
		sub	dx, bx
		inc	dx
		cmp	dx, 600
		jae	sizeOK
		mov	si, offset FSL18
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
sizeOK:
		.leave
		mov	ax, MSG_PREF_INIT
		mov	di, offset ConfigUIDialogClass
		GOTO	ObjCallSuperNoLock
PrefUICDialogInit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUIOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the options for our CUI combo

CALLED BY:	PrefUICDialogApply

PASS:		ax - PrefUICombo
RETURN:		none
DESTROYED:	ax, dx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UICombo	struct
	UIC_specific	nptr.TCHAR
	UIC_launcher	nptr.TCHAR
	UIC_font	FontID
UICombo ends

uicombos UICombo <
	offset MotifStr,
	offset GeoManagerStr,
	offset BerkeleyStr
>,<
	offset ISUIStr,
	offset ISDeskStr,
	offset EsquireStr
>

defaultLauncherKey char "defaultLauncher", 0
uiFeaturesCat char "uiFeatures", 0
fontIDKey char "fontid", 0
systemCat char "system", 0
editableTextFontIDKey char "editableTextFontID", 0

if ERROR_CHECK
LocalDefNLString MotifStr <"motifec.geo", 0>
LocalDefNLString ISUIStr <"isuiec.geo", 0>
LocalDefNLString GeoManagerStr <"EC GeoManager", 0>
LocalDefNLString ISDeskStr <"EC ISDesk", 0>
else
LocalDefNLString MotifStr <"motif.geo", 0>
LocalDefNLString ISUIStr <"isui.geo", 0>
LocalDefNLString GeoManagerStr <"GeoManager", 0>
LocalDefNLString ISDeskStr <"ISDesk", 0>
endif

LocalDefNLString BerkeleyStr <"Berkeley", 0>
LocalDefNLString EsquireStr <"Esquire", 0>

SetUIOptions	proc	near
		uses	ds, si, es
		.enter

	;
	; get the table entry
	;
		mov	di, (size UICombo)
		mul	di
		mov	di, ax				;di <- offset

		segmov	ds, cs, cx
		mov	es, cx
	;
	; handle [ui] specific = key
	;
		push	di
		mov	si, offset uiCategory
		mov	dx, offset specificKey
		mov	di, cs:uicombos[di].UIC_specific
		call	InitFileWriteString
		pop	di
	;
	; handle [uiFeatures] defaultLauncher = key
	;
		push	di
		mov	si, offset uiFeaturesCat
		mov	dx, offset defaultLauncherKey
		mov	di, cs:uicombos[di].UIC_launcher
		call	InitFileWriteString
		pop	di
	;
	; handle [ui] fontid = key and [system] fontid = key
	;
		push	di
		mov	si, offset uiCategory
		mov	dx, offset fontIDKey
		mov	di, cs:uicombos[di].UIC_font
		call	InitFileWriteString
		mov	dx, offset editableTextFontIDKey
		call	InitFileWriteString
		mov	si, offset systemCat
		call	InitFileWriteString
		pop	di

		.leave
		ret
SetUIOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetINIColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the color value set in the .INI file or the default

CALLED BY:	PrefMgr

PASS:		di - PrefUIColor for which color to get
RETURN:		al - Color
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GetINIColor	proc	near
		uses	ds, si, di, dx, cx
		.enter
	;
	; Get the current setting, using the default if necessary
	;
		mov	al, cs:defaultMotifColors[di]	;ax <- default color
		shl	di, 1				;di <- table index
		segmov	ds, cs, cx
		mov	dx, cs:colorKeys[di]		;cx:dx <- key
		mov	si, offset motifOptsCategory	;ds:si <- category
		call	InitFileReadInteger

		.leave
		ret
GetINIColor	endp

GetCurrentColor	proc	near
		uses	ds
		.enter

	;
	; See if the user has set anything already
	;
		segmov	ds, idata, ax
		clr	ax
		mov	al, ds:titleBarColor[di]	;al <- Color
		cmp	al, C_UNUSED_0			;color set?
		jne	gotColor			;branch if color set
	;
	; If not, get the .INI value or default
	;
		call	GetINIColor			;al <- Color
gotColor:
		clr	ah
CheckHack <CF_INDEX eq 0>

		.leave
		ret
GetCurrentColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUICColorSelectorStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return whether the color list has changed

CALLED BY:	PrefMgr

PASS:		none
RETURN:		carry - set if the state has changed
DESTROYED:	di, ax

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ConfigUICColorSelectorStateChanged method dynamic ConfigUICColorSelectorClass,
					MSG_PREF_HAS_STATE_CHANGED
		uses	cx
		.enter

		segmov	ds, idata, ax

		clr	di				;di <- PrefUIColor
		mov	cx, ConfigUIColor
colorLoop:
		call	GetINIColor
		cmp	ds:titleBarColor[di], C_UNUSED_0
		je	colorNotChanged			;branch if not changed
		cmp	ds:titleBarColor[di], al
		jne	colorChanged			;exit if changed
colorNotChanged:
		inc	di
		loop	colorLoop			;loop while more
		clc					;carry <- no change
		jmp	done

colorChanged:
		stc					;carry <- state changed
done:
		.leave
		ret
ConfigUICColorSelectorStateChanged endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUICColorSelectorReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a reset

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ConfigUICColorSelectorReset method dynamic ConfigUICColorSelectorClass,
					MSG_GEN_RESET
	;
	; Reset the user colors to indicate no change
	;
		push	ax, ds
		clr	di
		mov	cx, ConfigUIColor
		segmov	ds, idata, ax
		mov	al, C_UNUSED_0
colorLoop:
		mov	ds:titleBarColor[di], al
		inc	di
		loop	colorLoop
		pop	ax, ds
	;
	; Call our superclass to do the work
	;
		mov	di, offset ConfigUICColorSelectorClass
		call	ObjCallSuperNoLock
	;
	; Reset our color to match what it should be
	;
		call	GetSelectedArea
		jc	noneSelected
		mov	di, cx				;di <- ConfigUIColor
		call	GetINIColor
		call	UpdateColor
noneSelected:
		ret
ConfigUICColorSelectorReset endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUICColorChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a note of the color list being changed

CALLED BY:	PrefMgr

PASS:		dxcx - ColorQuad (dx = high, cx = low)
		bp - non-zero if indeterminate
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUICColorChanged	method dynamic ConfigUICColorSelectorClass,
					MSG_COLOR_SELECTOR_SET_COLOR

	;
	; Call our superclass first to update the UI
	;
		mov	di, offset ConfigUICColorSelectorClass
		call	ObjCallSuperNoLock
	;
	; See if it is something we can't handle
	;
		tst	bp				;indeterminate?
		jnz	resetScheme			;branch if so
		cmp	ch, CF_INDEX			;indexed color?
		jne	resetScheme			;branch if not
	;
	; See which area is selected
	;
		call	GetSelectedArea
		jc	done			;branch if none
	;
	; Save the new color for that area
	;
		push	ds
		mov	di, ax				;di <- ConfigUIColor
		segmov	ds, idata, ax
		mov	ds:titleBarColor[di], cl	;save color
		pop	ds
	;
	; Update the sample
	;
		push	cx
		mov	si, offset ColorSample
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		call	ObjCallInstanceNoLock
	;
	; See if the color has really changed
	;
		mov	si, offset SchemesList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pop	cx
		jc	done				;branch if no scheme
		mov	di, ax				;di <- scheme
		shl	di, 1
		mov	di, cs:defaultColorLists[di]	;cs:di <- ptr to colors
		call	GetSelectedArea
		jc	done				;branch if none
		add	di, ax				;adjust offset
		cmp	cl, {Color}cs:[di]
		jne	resetScheme			;branch if changed
done:
		ret

	;
	; Deselect the scheme list if not the default
	;
resetScheme:
		mov	si, offset SchemesList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		mov	dx, 1				;dx <- indeterminate
		call	ObjCallInstanceNoLock
		jmp	done
ConfigUICColorChanged	endm

GetSelectedArea	proc	near
		uses	cx, si, bp
		.enter

		mov	si, offset AreaList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock

		.leave
		ret
GetSelectedArea	endp

UpdateColor	proc	near
		uses	si
		.enter

CheckHack <CF_INDEX eq 0>
		clr	ah				;ax <- Color
		mov	cx, ax
		clr	dx, bp				;dx:cx <- ColorQuad
		mov	bx, handle ColorList
		mov	si, offset ColorList
		mov	ax, MSG_COLOR_SELECTOR_UPDATE_COLOR
		call	ObjCallInstanceNoLock

		.leave
		ret
UpdateColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorsSampleDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the color sample

CALLED BY:	MSG_VIS_DRAW

PASS:		bp - GState
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TITLE_BAR_POINTSIZE	equ	10
TITLE_BAR_INSET		equ	2
TITLE_BAR_HEIGHT	equ	16
TITLE_BAR_TEXT_Y_OFFSET	equ	TITLE_BAR_INSET+2
TITLE_BAR_RIGHT_INSET	equ	0

BUTTON_WIDTH		equ	10
BUTTON_HEIGHT		equ	10
BUTTON_INSET		equ	3

WINDOW_TOP		equ	TITLE_BAR_HEIGHT+TITLE_BAR_INSET+2
WINDOW_INSET		equ	3

HELP_TOP		equ	12
HELP_WIDTH		equ	50
HELP_RIGHT		equ	BUTTON_WIDTH+BUTTON_INSET+5

SELECTION_INSET		equ	WINDOW_INSET+5
SELECTION_HEIGHT	equ	TITLE_BAR_HEIGHT
SELECTION_ADDED_WIDTH	equ	6

CurAndStep	struct
    CAS_cur	WBFixed
    CAS_step	WBFixed
CurAndStep	ends

PrefColorsSampleDraw	method dynamic PrefColorsSampleClass,
					MSG_VIS_DRAW
bounds	local	Rectangle
red	local	CurAndStep
green	local	CurAndStep
blue	local	CurAndStep
curX	local	word

ForceRef red
ForceRef green
ForceRef blue
ForceRef curX

		mov	di, bp
		.enter

		call	GrSaveState

		call	VisGetBounds
		mov	ss:bounds.R_left, ax
		mov	ss:bounds.R_top, bx
		mov	ss:bounds.R_right, cx
		mov	ss:bounds.R_bottom, dx
	;
	; Fill with the light color to start
	;
		mov	si, CUIC_LIGHT_ITEMS
		call	getColor
		call	GrSetAreaColor
		call	getBounds
		call	GrFillRect
	;
	; Draw the title bar
	;
		mov	si, CUIC_TITLE_BARS
		call	getColor
		call	GrSetAreaColor

		mov_tr	dh, al				;dh <- title bar 1
		mov	si, CUIC_TITLE_BAR_GRADIENT
		call	getColor			;al <- title bar 2
		cmp	al, dh				;same color?
		LONG jne drawGradientTitle		;branch if diff. colors

		call	getBounds
		add	ax, TITLE_BAR_INSET
		add	bx, TITLE_BAR_INSET
		sub	cx, TITLE_BAR_RIGHT_INSET
		mov	dx, bx
		add	dx, TITLE_BAR_HEIGHT

		call	GrFillRect

finishTitleBar:
		mov	ax, C_WHITE
		call	GrSetTextColor

		call	GetSPUIFont			;cx <- FontID
		mov	dx, TITLE_BAR_POINTSIZE		;dx.ah <- pointsize
		clr	ah
		call	GrSetFont
		mov	si, offset SampleText
		mov	si, ds:[si]
		clr	cx
		call	GrTextWidth
		push	dx
		call	getBounds
		pop	dx
	;
	; if running ISUI, put the text on the left else center it
	;
		add	ax, TITLE_BAR_INSET*2
		call	ISUISelected
		jz	notCentered
		sub	cx, ax				;cx <- width
		sub	cx, BUTTON_WIDTH
		sub	cx, dx				;cx <- diff.
		shr	cx, 1				;cx <- center me
		add	ax, cx
notCentered:
		add	bx, TITLE_BAR_TEXT_Y_OFFSET
	;
	; if running ISUI, put the title bar text in bold
	;
		call	ISUISelected
		jnz	noBold
		push	ax
		mov	ax, mask TS_BOLD		;al <- set bold
		call	GrSetTextStyle
		pop	ax
noBold:
		call	GrDrawText
		push	ax
		mov	ax, (mask TS_BOLD) shl 8	;ah <- reset bold
		call	GrSetTextStyle
		pop	ax
	;
	; Draw a partial bevel, and a button, too.
	;
		mov	ax, C_WHITE
		call	GrSetLineColor
		call	getBounds
		call	GrDrawHLine
		call	GrDrawVLine			;draw white bevel

		mov	ax, C_LIGHT_GRAY
		call	GrSetAreaColor

		call	getBounds
		sub	cx, BUTTON_INSET
		mov	ax, cx
		sub	ax, BUTTON_WIDTH
		add	bx, BUTTON_INSET
		mov	dx, bx
		add	dx, BUTTON_HEIGHT
		call	GrFillRect			;draw button background

		call	GrDrawHLine
		call	GrDrawVLine			;draw white button

		push	ax
		mov	si, CUIC_DARK_ITEMS
		call	getColor
		call	GrSetLineColor
		pop	ax

		xchg	ax, cx
		call	GrDrawVLine
		xchg	ax, cx
		mov	bx, dx
		call	GrDrawHLine			;draw dark button

		call	getBounds
		mov	ax, cx
		call	GrDrawVLine			;draw dark bevel
	;
	; Draw a window view
	;
		mov	si, CUIC_FILE_MGR
		call	getColor
		call	GrSetAreaColor
		call	getBounds
		add	bx, WINDOW_TOP
		add	ax, WINDOW_INSET
		sub	cx, WINDOW_INSET
		call	GrFillRect
	;
	; draw a mini help window
	;
		mov	si, CUIC_LIGHT_ITEMS
		call	getColor
		call	GrSetLineColor
		mov	si, CUIC_HELP_BG
		call	getColor
		call	GrSetAreaColor
		call	getBounds
		sub	cx, HELP_RIGHT
		mov	ax, cx
		sub	ax, HELP_WIDTH
		add	bx, HELP_TOP
		call	GrFillRect
		call	GrDrawRect
	;
	; draw a selection sample
	;
		mov	si, CUIC_SELECTIONS
		call	getColor
		call	GrSetAreaColor
		call	getBounds
		clr	cx				;cx <- NULL terminated
		mov	si, offset SelectionSampleText
		mov	si, ds:[si]			;ds:si <- text
		call	GrTextWidth
		add	dx, SELECTION_ADDED_WIDTH
		mov	cx, dx				;cx <- width
		add	bx, WINDOW_TOP+4
		mov	dx, bx
		add	dx, SELECTION_HEIGHT		;dx <- bottom
		add	ax, SELECTION_INSET		;ax <- left
		add	cx, ax				;cx <- right
		call	GrFillRect
		add	ax, SELECTION_ADDED_WIDTH/2
		add	bx, 2
		clr	cx
		call	GrDrawText

		call	GrRestoreState

		.leave
		ret

getColor:
		push	di
		mov	di, si				;di <- ConfigUIColor
		call	GetCurrentColor
		pop	di
		retn

getBounds:
		mov	ax, ss:bounds.R_left
		mov	bx, ss:bounds.R_top
		mov	cx, ss:bounds.R_right
		mov	dx, ss:bounds.R_bottom
		retn

drawGradientTitle:
		xchg	al, dh
		call	DrawGradient
		jmp	finishTitleBar
		
PrefColorsSampleDraw	endm

ISUISelected	proc	near
		uses	ax, cx, dx, bp, si
		.enter

		mov	si, offset UIList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		cmp	ax, CUIC_ISUI

		.leave
		ret
ISUISelected	endp

GetSPUIFont	proc	near
		mov	cx, FID_BERKELEY
		call	ISUISelected
		jnz	gotFont
		mov	cx, 555
gotFont:
		ret
GetSPUIFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawGradient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a gradient filled rectangle

CALLED BY:	PrefColorsSampleDraw

PASS:		ss:bp - inherited locals
		di - GState
		al - start color
		dh - end color
RETURN:		none
		none
DESTROYED:	ax, bx, cx, dx, si

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawGradient	proc	near
		.enter	inherit PrefColorsSampleDraw

		mov	ah, al				;ah <- start index
		call	GrMapColorIndex
		push	ax
		push	bx
		mov	ah, dh				;ah <- end index
		call	GrMapColorIndex
		pop	cx				;cl <- stG, ch <- stB
		pop	dx
	;
	; start color: dl=R, cl=G, ch=B
	; end color: al=R, bl=G, bh=B
	;

		mov	dh, al				;dh <- end R
		lea	si, ss:red
		call	CalcStep
		mov	dl, cl				;dl <- start G
		mov	dh, bl				;dh <- end G
		lea	si, ss:green
		call	CalcStep
		mov	dl, ch				;dl <- start B
		mov	dh, bh				;dh <- end B
		lea	si, ss:blue
		call	CalcStep
	;
	; set up the starting X pos
	;
		mov	ax, ss:bounds.R_left
		add	ax, TITLE_BAR_INSET
		mov	ss:curX, ax

drawLoop:
		mov	al, ss:red.CAS_cur.WBF_int.low
		mov	bl, ss:green.CAS_cur.WBF_int.low
		mov	bh, ss:blue.CAS_cur.WBF_int.low
		mov	ah, CF_RGB
		call	GrSetAreaColor

		mov	ax, ss:curX
		mov	cx, ax
		add	cx, 2

		mov	bx, ss:bounds.R_top
		mov	dx, ss:bounds.R_bottom
		add	bx, TITLE_BAR_INSET
		mov	dx, bx
		add	dx, TITLE_BAR_HEIGHT

		call	GrFillRect
	;
	; advance to next color and position
	;
		inc	ss:curX
		addwbf	ss:red.CAS_cur, ss:red.CAS_step, ax
		addwbf	ss:green.CAS_cur, ss:green.CAS_step, ax
		addwbf	ss:blue.CAS_cur, ss:blue.CAS_step, ax
	;
	; reached right edge?
	;
		mov	cx, ss:bounds.R_right
		sub	cx, TITLE_BAR_RIGHT_INSET
		cmp	ss:curX, cx
		jbe	drawLoop

		.leave
		ret

DrawGradient	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcStep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a gradient filled rectangle

CALLED BY:	DrawGradient

PASS:		ss:bp - inherited locals
		dl - start color value (R,G or B)
		dh - end color value (R, G, or B)
RETURN:		none
		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcStep	proc	near
		uses	ax, bx, cx, dx
		.enter	inherit DrawGradient

		clr	bx, ax
		mov	ss:[si].CAS_cur.WBF_frac, al
		mov	ss:[si].CAS_cur.WBF_int, ax
		mov	ss:[si].CAS_cur.WBF_int.low, dl	;store start color
		mov	al, dh				;al <- end color
		clr	ah				;ax <- end color
		clr	dh				;dx <- start color
		sub	ax, dx				;ax <- color 'width'
		jz	zeroStep			;branch if no step
		mov_tr	dx, ax
		clr	ax, cx				;dx.cx <- color width
		mov	bx, ss:bounds.R_right
		sub	bx, ss:bounds.R_left		;bx.ax <- rect. width
		call	GrSDivWWFixed
		jnc	gotValue
zeroStep:
		clr	dx, cx
gotValue:
		rndwwbf dxcx				;round to dx.ch
		mov	ss:[si].CAS_step.WBF_frac, ch
		mov	ss:[si].CAS_step.WBF_int, dx

		.leave
		ret
CalcStep	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorsSampleRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the color sample

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorsSampleRecalcSize	method dynamic PrefColorsSampleClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, PREF_COLORS_SAMPLE_WIDTH
		mov	dx, PREF_COLORS_SAMPLE_HEIGHT
		ret
PrefColorsSampleRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIDialogFontAreaChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The font area has been changed

CALLED BY:	MSG_CUIFA_FONT_AREA_CHANGED

PASS:		none
RETURN:		cx - ConfigUIFontArea
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontArea	struct
	FA_category	nptr.char
	FA_key		nptr.char
	FA_default	word
	FA_font		FontID
FontArea	ends

editableTextKey char "editableTextFontsize", 0
fontSizeKey char "fontsize", 0
fileMgrCategory char "file manager", 0

fontAreas	FontArea \
	<uiCategory, fontSizeKey, 10, 0>,
	<uiCategory, editableTextKey, 10, 0>,
	<fileMgrCategory, fontSizeKey, 9, FID_UNIVERSITY>

ConfigUIFontAreaFontAreaChanged	method dynamic ConfigUIFontAreaClass,
					MSG_CUIFA_FONT_AREA_CHANGED
	;
	; get the font size
	;
		mov	di, cx
		shl	di, 1
		push	ds
		segmov	ds, idata, ax			;ds <- idata
		mov	ax, ds:menuFont[di]
		pop	ds
		tst	ax
		jnz	gotFontSize
		call	GetINIFontSize
gotFontSize:
	;
	; set our size list to match
	;
		push	ax, cx
		mov_tr	cx, ax
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	si, offset FontSizeList
		call	ObjCallInstanceNoLock
		pop	ax, cx
	;
	; set the font to appropriately
	;
		call	UpdateSampleFont
	;
	; set the pointsize of the sample to match
	;
		call	UpdateSampleSize
		ret
ConfigUIFontAreaFontAreaChanged	endm

UpdateSampleFont	proc	near
		uses	ax, cx, dx, bp, si
		.enter

	;
	; figure out which font to use
	;
		mov	si, offset FontSizeArea
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		mov_tr	cx, ax				;cx <- ConfigUIFontArea

		call	GetFontAreaEntry		;di <- FontArea
		mov	cx, cs:fontAreas[di].FA_font
		tst	cx
		jnz	gotFont
		call	GetSPUIFont
gotFont:
	;
	; set the font
	;
		mov	dx, (size VisTextSetFontIDParams)
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].VTSFIDP_fontID, cx
		mov	ax, MSG_VIS_TEXT_SET_FONT_ID
		mov	si, offset FontSample
		call	ObjCallInstanceNoLock
		add	sp, (size VisTextSetFontIDParams)

		.leave
		ret
UpdateSampleFont	endp

UpdateSampleSize	proc	near
		uses	ax, cx, dx, bp, si
		.enter

	;
	; set the pointsize
	;
		mov	dx, (size VisTextSetPointSizeParams)
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0
		mov	ss:[bp].VTSPSP_pointSize.WWF_int, ax
		mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
		mov	si, offset FontSample
		call	ObjCallInstanceNoLock
		add	sp, (size VisTextSetPointSizeParams)

		.leave
		ret
UpdateSampleSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIFontAreaFontSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The font area has been changed

CALLED BY:	MSG_CUIFA_FONT_SIZE_CHANGED

PASS:		none
RETURN:		cx - fontsize
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUIFontAreaFontSizeChanged	method dynamic ConfigUIFontAreaClass,
					MSG_CUIFA_FONT_SIZE_CHANGED
	;
	; save the font size in the appropriate slot
	;
		mov	di, ds:[si]
		add	di, ds:[di].GenItemGroup_offset
		mov	di, ds:[di].GIGI_selection
		shl	di, 1
		push	ds
		segmov	ds, idata, ax			;ds <- idata
		mov_tr	ax, cx				;ax <- font size
		mov	ds:menuFont[di], ax
		pop	ds
	;
	; update the sample
	;
		call	UpdateSampleSize
		ret
ConfigUIFontAreaFontSizeChanged	endm

GetFontAreaEntry	proc	near
		uses	ax, cx
		.enter

		mov	ax, (size FontArea)
		mul	cx
		mov_tr	di, ax

		.leave
		ret
GetFontAreaEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetINIFontSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the specified font size from the INI file

CALLED BY:	utility

PASS:		cx - ConfigUIFontArea
RETURN:		ax - font size
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetINIFontSize	proc	near
		uses	cx, dx, ds, si
		.enter

		call	GetFontAreaEntry
	;
	; get the value for the category and key
	;
		push	ds
		segmov	ds, cs, cx
		mov	si, cs:fontAreas[di].FA_category
		mov	dx, cs:fontAreas[di].FA_key
		mov	ax, cs:fontAreas[di].FA_default
		call	InitFileReadInteger
		pop	ds

		.leave
		ret
GetINIFontSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIFontAreaReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a reset

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ConfigUIFontAreaReset	method dynamic ConfigUIFontAreaClass,
						MSG_GEN_RESET
	;
	; call our superclass to do most of the work
	;
		mov	di, offset ConfigUIFontAreaClass
		call	ObjCallSuperNoLock
	;
	; reset the font sizes
	;
		push	ds
		segmov	ds, idata, ax
		clr	ax
		mov	ds:menuFont, ax
		mov	ds:editableFont, ax
		mov	ds:folderFont, ax
		pop	ds
		
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		GOTO	ObjCallInstanceNoLock
ConfigUIFontAreaReset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIFontAreaApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an apply

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ConfigUIFontAreaApply	method dynamic ConfigUIFontAreaClass,
						MSG_GEN_APPLY
	;
	; call our superclass to do most of the work
	;
		mov	di, offset ConfigUIFontAreaClass
		call	ObjCallSuperNoLock
	;
	; save the font sizes
	;
		segmov	ds, idata, ax
		clr	di
		call	saveSize
		call	saveSize
		call	saveSize
		ret


saveSize:
		mov	cx, di
		push	di, ds, bp
		shl	di, 1
		mov	bp, ds:menuFont[di]		;bp <- font size
		tst	bp				;any size set?
		jz	noWrite				;branch if not
		call	GetFontAreaEntry		;di <- FontArea entry
		segmov	ds, cs, cx
		mov	si, cs:fontAreas[di].FA_category
		mov	dx, cs:fontAreas[di].FA_key
		call	InitFileWriteInteger
noWrite:
		pop	di, ds, bp
		inc	di
		retn
ConfigUIFontAreaApply	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUIFontAreaGetRebootInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if reboot needed

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ConfigUIFontAreaGetRebootInfo	method dynamic ConfigUIFontAreaClass,
						MSG_PREF_GET_REBOOT_INFO

	;
	; if any changes, signal reboot
	;
		segmov	ds, idata, ax
		mov	cx, ds:menuFont
		ornf	cx, ds:editableFont
		ornf	cx, ds:folderFont
		jcxz	done				;branch if no changes
		mov	cx, handle ConfigUIFontRebootString
		mov	dx, offset ConfigUIFontRebootString
done:
		ret
ConfigUIFontAreaGetRebootInfo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUICInitSchemeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize our dynamic list

CALLED BY:	MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY

PASS:		none
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUICInitSchemeList	method dynamic ConfigUICSchemeListClass,
					MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
	;
	; don't include 256 color schemes if on 16 color system
	;
		mov	cx, ConfigUIDefaultColorScheme
		call	UserGetDisplayType
		and	ah, mask DT_DISP_CLASS
		cmp	ah, DC_COLOR_4 shl (offset DT_DISP_CLASS)
		ja	gotNumItems
		mov	cx, 3				;cx <-
gotNumItems:
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		GOTO	ObjCallInstanceNoLock
ConfigUICInitSchemeList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUICFindSchemeItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find our entry in the dynamic list

CALLED BY:	MSG_PREF_DYNAMIC_LIST_FIND_ITEM

PASS:		cx:dx - ptr to NULL terminated string
		bp - non-zero to find best fit, else exact
RETURN:		if found:
			carry - clear
			ax - item #
		else:
			carry - set
			ax - item after requested item
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUICFindSchemeItem	method dynamic ConfigUICSchemeListClass,
					MSG_PREF_DYNAMIC_LIST_FIND_ITEM
		movdw	esdi, cxdx			;es:di <- match
		clr	dx				;dx <- assume exact
		tst	bp				;best fit?
		jz	gotStrLen			;branch if not
		call	LocalStringLength
		mov	dx, cx				;dx <- length to match
gotStrLen:
		mov	bx, handle SchemeStrings
		call	MemLock
		mov	ds, ax
		mov	bx, offset SLDI1		;*ds:bx <- 1st string
		clr	ax
findLoop:
		push	cx
		mov	si, ds:[bx]			;ds:si <- string
		mov	cx, dx				;cx <- length
		call	LocalCmpStringsNoCase
		pop	cx
		clc					;carry <- in case match
		je	foundString			;branch if match
		add	bx, (size lptr)			;*ds:bx <- next string
		inc	ax				;ax <- next item #
		loop	findLoop
		clr	ax				;ax <- no match
		stc					;carry <- no match
foundString:
		mov	bx, handle SchemeStrings
		GOTO	MemUnlock
ConfigUICFindSchemeItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUICGetSchemeMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the requested moniker for our scheme list

CALLED BY:	MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER

PASS:		ss:bp - GetItemMonikerParams
RETURN:		bp - # of characters in moniker
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ForceRef SLDI2
ForceRef SLDI3
ForceRef SLDI4
ForceRef SLDI5
ForceRef SLDI6
ForceRef SLDI7
ForceRef SLDI8
ForceRef SLDI9
ForceRef SLDI10
ForceRef SLDI11
ForceRef SLDI12
ForceRef SLDI13
ForceRef SLDI14
ForceRef SLDI15
ForceRef SLDI16
ForceRef SLDI17
ForceRef SLDI18
ForceRef SLDI19

ConfigUICGetSchemeMoniker	method dynamic ConfigUICSchemeListClass,
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
		mov	bx, handle SchemeStrings
		call	MemLock
		mov	ds, ax
		mov	si, ss:[bp].GIMP_identifier	;si <- identififer
		shl	si, 1				;si <- offset
		add	si, offset SLDI1		;si <- handle
		mov	si, ds:[si]			;ds:si <- string
		ChunkSizePtr ds, si, cx			;cx <- # bytes
		movdw	esdi, ss:[bp].GIMP_buffer	;es:di <- dest
		mov	bp, cx
DBCS <		shr	cx, 1				;>
		LocalCopyNString
		GOTO	MemUnlock
ConfigUICGetSchemeMoniker	endm

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConfigUICSchemeListSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save a color scheme

CALLED BY:	MSG_CUIC_SCHEME_LIST_SAVE

PASS:		none
RETURN:		none
DESTROYED:	none

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConfigUICSchemeListSave	method dynamic ConfigUICSchemeListClass,
					MSG_CUIC_SCHEME_LIST_SAVE
nameBuf		local	COLOR_SCHEME_MAX_NAME_LENGTH dup (TCHAR)
		.enter

	;
	; get the name for the scheme
	;
		push	bp
		mov	si, offset STSADName
		mov	dx, ss
		lea	bp, ss:nameBuf
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock
		pop	bp
		jcxz	noText
	;
	; get the schemes file
	;
		call	OpenCreateSchemesFile
	;
	; close the schemes file
	;
		call	CloseSchemesFile
noText:
		.leave
		ret
ConfigUICSchemeListSave	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenCreateSchemesFile, CloseSchemesFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the schemes file, creating if necessary

CALLED BY:	ConfigUICSchemeListSave()

PASS:		none
RETURN:		carry - set if error
		bx - handle of schemes file
		*ds:si - name array

DESTROYED:	ax, dx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDefNLString schemeFileName, <"Color Schemes", 0>

OpenCreateSchemesFile	proc	near
		uses	bp

		.enter
	;
	; go to PRIVDATA
	;
		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath
	;
	; try to open the file
	;
		mov	ah, VMO_CREATE			;ah <- VMOpenType
		mov	al, mask VMAF_FORCE_READ_WRITE	;al <- VMAccessFlags
		clr	cx				;cx <- default compr.
		segmov	ds, cs
		mov	dx, offset schemeFileName	;ds:dx <- filename
		call	VMOpen
		cmp	ax, VM_CREATE_OK		;created?
		je	initFile			;branch if so
	;
	; lock the map block
	;
		call	VMGetMapBlock
		call	VMLock
		mov	ds, ax				;ds <- seg addr of blk
		mov	si, (size LMemBlockHeader)
done:
		call	FilePopDir

		.leave
		ret

initFile:
	;
	; create a name array block
	;
		push	bx
		mov	ax, LMEM_TYPE_GENERAL		;ax <- LMemType
		clr	cx				;cx <- default header
		call	MemAllocLMem
		push	bx
		call	MemLock
		mov	ds, ax				;ds <- block
		mov	bx, (size ColorSchemeStruct)	;bx <- element size
		clr	ax, cx, si			;cx <- default header
							;al <- ObjChunkFlags
							;si <- alloc chunk
		call	NameArrayCreate
		pop	cx				;cx <- mem block
		pop	bx				;bx <- VM file handle
	;
	; attach it to the VM file
	;
		clr	ax				;ax <- alloc VM block
		call	VMAttach
	;
	; make it the map block
	;
		call	VMSetMapBlock
		clc					;carry <- no error
		jmp	done
OpenCreateSchemesFile	endp

CloseSchemesFile	proc	near
		uses	bp

		.enter
	;
	; unlock the name array
	;
		mov	bp, ds:[LMBH_handle]
		call	VMUnlock
	;
	; close the file
	;
		clr	al
		call	VMClose

		.leave
		ret
CloseSchemesFile	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SectionsPrefChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return whether more than one section has changed

CALLED BY:	PrefMgr

PASS:		none
RETURN:		carry - set if the state has changed
DESTROYED:	di, ax

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SectionsPrefChanged method dynamic SectionsPrefClass,
					MSG_PREF_HAS_STATE_CHANGED
		tst	ds:[di].SPI_changed		;changed?
		jz	done				;branch (carry clear)
		stc					;carry <- changed
done:
		ret
SectionsPrefChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SectionsPrefSectionChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The section list changed

CALLED BY:	PrefMgr

PASS:		cx - current selection (ConfigUISection)
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SectionsPrefSectionChanged	method	dynamic	SectionsPrefClass,
						MSG_SP_SECTION_CHANGED
		.enter

		mov	dx, cx				;dx <- current
		clr	di, cx
sectionLoop:
	;
	; has state changed?
	;
		push	cx, dx, si
		mov	si, cs:sectionInteractions[di]
		mov	ax, MSG_PREF_HAS_STATE_CHANGED
		call	ObjCallInstanceNoLock
		pop	cx, dx, si
		jnc	noChange
	;
	; record change
	;
		push	di
		mov	di, ds:[si]
		add	di, ds:[di].SectionsPref_offset
		mov	ds:[di].SPI_changed, TRUE
		pop	di
noChange:
	;
	; If the current section, set usable otherwise not usable
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		cmp	cx, dx
		jne	gotMsg
		mov	ax, MSG_GEN_SET_USABLE
gotMsg:
		push	cx, dx, si
		mov	si, cs:sectionInteractions[di]
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
		pop	cx, dx, si
		add	di, (size lptr)
		inc	cx
		cmp	cx, length sectionInteractions
		jb	sectionLoop

		.leave
		ret
SectionsPrefSectionChanged	endm

sectionInteractions lptr \
	AppSettings,
	ExpressSettings,
	InterfaceSettings,
	AdvancedSettings,
	DriveSettings,
	AppearanceSettings

CheckHack <length sectionInteractions eq ConfigUISection>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SectionsPrefReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a reset

CALLED BY:	MSG_GEN_RESET

PASS:		ds:di - SectionsPref instance
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SectionsPrefReset	method	dynamic	SectionsPrefClass,
						MSG_GEN_RESET
	;
	; mark as not changed
	;
		mov	ds:[di].SPI_changed, FALSE
		ret
SectionsPrefReset	endm

ConfigUICode	ends
