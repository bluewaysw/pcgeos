COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefsnd.asm

AUTHOR:		Gene Anderson, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/25/92		Initial revision


DESCRIPTION:
	Code for keyboard module of Preferences

	$Id: prefuic.asm,v 1.4 98/05/05 21:34:03 gene Exp $

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

;-----------------------------------------------------------------------------
;	DEF FILES		
;-----------------------------------------------------------------------------
 
include prefuic.def
include prefuic.rdef

;-----------------------------------------------------------------------------
;	VARIABLES		
;-----------------------------------------------------------------------------

idata segment

idata ends

;-----------------------------------------------------------------------------
;	CODE		
;-----------------------------------------------------------------------------
 
PrefUICCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICGetPrefUITree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the root of the UI tree for "Preferences"

CALLED BY:	PrefMgr

PASS:		none
RETURN:		dx:ax - OD of root of tree
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefUICGetPrefUITree	proc far
	mov	dx, handle PrefUICRoot
	mov	ax, offset PrefUICRoot
	ret
PrefUICGetPrefUITree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICGetModuleInfo
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
PrefUICGetModuleInfo	proc far
	.enter

	clr	ax

	mov	ds:[si].PMI_requiredFeatures, mask PMF_USER
	mov	ds:[si].PMI_prohibitedFeatures, ax
	mov	ds:[si].PMI_minLevel, ax
	mov	ds:[si].PMI_maxLevel, UIInterfaceLevel-1
	mov	ds:[si].PMI_monikerList.handle, handle  PrefUICMonikerList
	mov	ds:[si].PMI_monikerList.offset, offset PrefUICMonikerList
	mov	{word} ds:[si].PMI_monikerToken,  'P' or ('F' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+2, 'P' or ('U' shl 8)
	mov	{word} ds:[si].PMI_monikerToken+4, MANUFACTURER_ID_APP_LOCAL 

	.leave
	ret
PrefUICGetModuleInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteCUILink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the CUI link ("NewDeal Desktop")

CALLED BY:	SetUIOptions

PASS:		none
RETURN:		none
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/00   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

LocalDefNLString cuiLink <"DESKTOP\\\\NewDeal Desktop",0>

DeleteCUILink	proc	near
		uses	ds
		.enter
	;
	; delete the "NewDeal Desktop" (i.e., CUI) link
	;
		call	FilePushDir
		mov	ax, SP_TOP
		call	FileSetStandardPath
		segmov	ds, cs, ax
		mov	dx, offset cuiLink		;ds:dx <- filename
		call	FileDelete
		call	FilePopDir

		.leave
		ret
DeleteCUILink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUIOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the options for our CUI combo

CALLED BY:	PrefUICDialogApply

PASS:		ax - PrefUICombo
RETURN:		none
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/00   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UICombo	struct
	UIC_environment	BooleanByte
	UIC_specific	nptr.TCHAR
	UIC_launcher	nptr.TCHAR
	UIC_advLauncher	nptr.TCHAR
UICombo ends

uicombos UICombo <
	BB_FALSE,
	offset MotifStr,
	offset NewManagerStr,
	0
>,<
	BB_FALSE,
	offset NewUIStr,
	offset NewDeskStr,
	0
>,<
	BB_TRUE,
	offset NewUIStr,
	offset WelcomeStr,
	offset NewDeskStr
>

haveEnvAppKey char "haveEnvironmentApp", 0
specificKey char "specific", 0
defaultLauncherKey char "defaultLauncher", 0
uiFeaturesCat char "uiFeatures", 0
uiAdvFeaturesCat char "uiFeatures - advanced", 0

if ERROR_CHECK
LocalDefNLString MotifStr <"motifec.geo", 0>
LocalDefNLString NewUIStr <"newuiec.geo", 0>
LocalDefNLString NewManagerStr <"managere.geo", 0>
LocalDefNLString NewDeskStr <"newdeske.geo", 0>
LocalDefNLString WelcomeStr <"welcomee.geo", 0>
else
LocalDefNLString MotifStr <"motif.geo", 0>
LocalDefNLString NewUIStr <"newui.geo", 0>
LocalDefNLString NewManagerStr <"manager.geo", 0>
LocalDefNLString NewDeskStr <"newdesk.geo", 0>
LocalDefNLString WelcomeStr <"welcome.geo", 0>
endif

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
	; handle haveEnvironmentApp key
	;
		mov	si, offset uiCategory
		mov	dx, offset haveEnvAppKey
		mov	al, cs:uicombos[di].UIC_environment
		clr	ah
		call	InitFileWriteBoolean
		tst	ax
		jnz	keepLink
		call	DeleteCUILink
keepLink:
	;
	; handle [ui] specific = key
	;
		push	di
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
	; handle [uiFeatures - advanced] defaultLauncher = key
	;
		push	di
		mov	si, offset uiAdvFeaturesCat
		mov	di, cs:uicombos[di].UIC_advLauncher
		tst	di
		jz	noAdvLauncher
		call	InitFileWriteString
noAdvLauncher:
		pop	di

		.leave
		ret
SetUIOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an apply for the dialog box

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/24/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICDialogApply	method	dynamic	PrefUICDialogClass, MSG_GEN_APPLY
	;
	; See if the UI has changed
	;
		mov	ax, MSG_GEN_ITEM_GROUP_IS_MODIFIED
		mov	si, offset UIList
		call	ObjCallInstanceNoLock
		jnc	noReset				;branch if not mod.
	;
	; If so, force the state files to be deleted when we restart so
	; that the correct launcher will be launched.
	;
		push	ds
		segmov	ds, cs, cx
		mov	si, offset uiCategory		;ds:si <- category
		mov	dx, offset resetKey		;cx:dx <- key
		mov	ax, TRUE			;ax <- set to TRUE
		call	InitFileWriteBoolean
		pop	ds
	;
	; set the various options for the UI combo
	;
		mov	si, offset UIList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		jc	noReset
		call	SetUIOptions
noReset:
	;
	; Call our superclass after above, so we have time to deal with stuff
	; before any suggested shutdown.
	;
		mov	ax, MSG_GEN_APPLY
		mov	si, offset PrefUICRoot
		mov	di, offset PrefUICDialogClass
		GOTO	ObjCallSuperNoLock
PrefUICDialogApply	endm

PrefUICDialogPostApply	method dynamic PrefUICDialogClass,
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
		mov	si, offset PrefUICRoot
		mov	di, offset PrefUICDialogClass
		GOTO	ObjCallSuperNoLock

PrefUICDialogPostApply	endm

uiCategory		char "ui",0
resetKey		char "forceDeleteStateFilesOnceOnly",0

colorKeys	nptr \
	titleBarKey,
	darkColorKey,
	lightColorKey,
	fileMgrKey

CheckHack <length colorKeys eq PrefUIColor>

defaultMotifColors	Color \
	C_DARK_GRAY,
	C_DARK_GRAY,
	C_LIGHT_GRAY,
	C_WHITE

CheckHack <length defaultMotifColors eq PrefUIColor>

motifOptsCategory	char "motif options",0

titleBarKey		char "activeTitleBarColor",0
darkColorKey		char "darkColor",0
lightColorKey		char "lightColor",0
fileMgrKey		char "fileMgrColor",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICDialogAreaChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the color list to reflect the selected area

CALLED BY:	PrefMgr

PASS:		cx - current selection (PrefUIColor)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/24/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICDialogAreaChanged	method	dynamic	PrefUICDialogClass,
						MSG_PREF_UICD_AREA_CHANGED
		.enter

		mov	di, cx				;di <- selection
		call	GetCurrentColor			;al <- current color
		call	UpdateColor

		.leave
		ret
PrefUICDialogAreaChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetINIColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the color value set in the .INI file or the default

CALLED BY:	PrefMgr

PASS:		di - PrefUIColor for which color to get
RETURN:		al - Color
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/24/98   	Initial version.

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
		PrefColorSelectorHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return whether the color list has changed

CALLED BY:	PrefMgr

PASS:		none
RETURN:		carry - set if the state has changed
DESTROYED:	di, ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/24/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICColorSelectorHasStateChanged method dynamic PrefUICColorSelectorClass,
					MSG_PREF_HAS_STATE_CHANGED
		uses	cx
		.enter

		segmov	ds, idata, ax

		clr	di				;di <- PrefUIColor
		mov	cx, PrefUIColor
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
PrefUICColorSelectorHasStateChanged endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorSelectorReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a reset

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/24/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICColorSelectorReset method dynamic PrefUICColorSelectorClass,
					MSG_GEN_RESET
	;
	; Reset the user colors to indicate no change
	;
		push	ax, ds
		clr	di
		mov	cx, PrefUIColor
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
		mov	di, offset PrefUICColorSelectorClass
		call	ObjCallSuperNoLock
	;
	; Reset our color to match what it should be
	;
		call	GetSelectedArea
		jc	noneSelected
		mov	di, cx				;di <- PrefUIColor
		call	GetINIColor
		call	UpdateColor
noneSelected:
		ret
PrefUICColorSelectorReset endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICColorChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a note of the color list being changed

CALLED BY:	PrefMgr

PASS:		dxcx - ColorQuad (dx = high, cx = low)
		bp - non-zero if indeterminate
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/24/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefUICColorChanged	method dynamic PrefUICColorSelectorClass,
					MSG_COLOR_SELECTOR_SET_COLOR

	;
	; Call our superclass first to update the UI
	;
		mov	di, offset PrefUICColorSelectorClass
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
		mov	di, ax				;di <- PrefUIColor
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
PrefUICColorChanged	endm

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
		PrefUICSetDefaultColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the colors to the defaults

CALLED BY:	PrefMgr

PASS:		cx - PrefUIDefaultColorScheme
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/14/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

defaultColorLists nptr \
	defaultMotifColors,
	defaultNewUIColors,
	defaultCyanColors,
	defaultEarthColors

defaultNewUIColors	Color \
	C_BLUE,				;title bar
	C_DARK_GRAY,			;dark color
	C_LIGHT_GRAY,			;light color
	C_WHITE				;file folder

defaultCyanColors	Color \
	C_BLACK,			;title bar
	C_BLACK,			;dark color
	C_CYAN,				;light color
	C_WHITE				;file folder

defaultEarthColors	Color \
	C_R2_G3_B2,			;title bar
	C_DARK_GRAY,			;dark color
	C_LIGHT_GRAY,			;light color
	C_R2_G3_B3			;file folder

CheckHack <length defaultColorLists eq PrefUIDefaultColorScheme>


PrefUICSetDefaultColor	method dynamic PrefUICDialogClass,
					MSG_PREF_UICD_SET_DEFAULT_COLORS
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
		mov	cx, PrefUIColor
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
		mov	ax, MSG_PREF_UICD_AREA_CHANGED
		call	ObjCallInstanceNoLock
done:
		ret
PrefUICSetDefaultColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorsSampleDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the color sample

CALLED BY:	MSG_VIS_DRAW

PASS:		bp - GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/15/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TITLE_BAR_POINTSIZE	equ	9
TITLE_BAR_INSET		equ	2
TITLE_BAR_HEIGHT	equ	13
TITLE_BAR_TEXT_Y_OFFSET	equ	TITLE_BAR_INSET+1
TITLE_BAR_RIGHT_INSET	equ	15

BUTTON_WIDTH		equ	10
BUTTON_HEIGHT		equ	10
BUTTON_INSET		equ	3

WINDOW_TOP		equ	TITLE_BAR_HEIGHT+TITLE_BAR_INSET+2
WINDOW_INSET		equ	3

PrefColorsSampleDraw	method dynamic PrefColorsSampleClass,
					MSG_VIS_DRAW
bounds	local	Rectangle

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
		mov	si, PUIC_LIGHT_ITEMS
		call	getColor
		call	GrSetAreaColor
		call	getBounds
		call	GrFillRect
	;
	; Draw the title bar
	;
		mov	si, PUIC_TITLE_BARS
		call	getColor
		call	GrSetAreaColor

		call	getBounds
		add	ax, TITLE_BAR_INSET
		add	bx, TITLE_BAR_INSET
		sub	cx, TITLE_BAR_RIGHT_INSET
		mov	dx, bx
		add	dx, TITLE_BAR_HEIGHT
		call	GrFillRect

		mov	ax, C_WHITE
		call	GrSetTextColor

		clr	cx				;cx <- no ID
		clr	ah	
		mov	dx, TITLE_BAR_POINTSIZE		;dx.ah <- pointsize
		call	GrSetFont
		mov	si, offset SampleText
		mov	si, ds:[si]
		clr	cx
		call	GrTextWidth
		push	dx
		call	getBounds
		pop	dx
		sub	cx, ax				;cx <- width
		sub	cx, BUTTON_WIDTH+2*TITLE_BAR_INSET
		sub	cx, dx				;cx <- diff.
		shr	cx, 1				;cx <- center me
		add	ax, cx
		add	bx, TITLE_BAR_TEXT_Y_OFFSET
		call	GrDrawText
	;
	; Draw a partial bevel, and a button, too.
	;
		mov	ax, C_WHITE
		call	GrSetLineColor
		call	getBounds
		call	GrDrawHLine
		call	GrDrawVLine			;draw white bevel

		sub	cx, BUTTON_INSET
		mov	ax, cx
		sub	ax, BUTTON_WIDTH
		add	bx, BUTTON_INSET
		mov	dx, bx
		add	dx, BUTTON_HEIGHT
		call	GrDrawHLine
		call	GrDrawVLine			;draw white button

		push	ax
		mov	si, PUIC_DARK_ITEMS
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
		mov	si, PUIC_FILE_MGR
		call	getColor
		call	GrSetAreaColor
		call	getBounds
		add	bx, WINDOW_TOP
		add	ax, WINDOW_INSET
		sub	cx, WINDOW_INSET
		call	GrFillRect

		call	GrRestoreState

		.leave
		ret

getColor:
		push	di
		mov	di, si				;di <- PrefUIColor
		call	GetCurrentColor
		pop	di
		retn

getBounds:
		mov	ax, ss:bounds.R_left
		mov	bx, ss:bounds.R_top
		mov	cx, ss:bounds.R_right
		mov	dx, ss:bounds.R_bottom
		retn
PrefColorsSampleDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorsSampleRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the color sample

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/15/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorsSampleRecalcSize	method dynamic PrefColorsSampleClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, PREF_COLORS_SAMPLE_WIDTH
		mov	dx, PREF_COLORS_SAMPLE_HEIGHT
		ret
PrefColorsSampleRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefUICDialogInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the dialog

CALLED BY:	PrefMgr

PASS:		none
RETURN:		none
DESTROYED:	bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/15/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefUICDialogInit	method	dynamic	PrefUICDialogClass, MSG_PREF_INIT

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
		.leave
		mov	di, offset PrefUICDialogClass
		GOTO	ObjCallSuperNoLock
PrefUICDialogInit	endm

PrefUICCode	ends
