COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/Main
FILE:		mainCode.asm

ROUTINES:
	Name			Description
	----			-----------
    GLB LibraryEntry		Entry point for this library.

    INT SpecInitWindowPreferences
				Fetches WindowOptions .ini settings,
				interprets, & stores results in
				olWindowOptions.

    INT GetDefaultWindowPreferences
				Returns default window option preferences,
				as determined by the specific UI (before
				user overrides)

    INT SpecGetWindowOptions	Get the window options

    INT SpecGetExpressOptions	Get the express options

    INT SpecInitExpressPreferences
				Fetches Express menu .ini settings,
				interprets

    INT SpecInitHelpPreferences Initialize help preferences for a field

    INT SpecInitDefaultDisplayScheme
				If the first UI screen has been set up yet,
				fetch its displayType, initialize
				DisplayScheme DisplayType, Font &
				PointSize.  NOTE: Current implementation is
				limited to supporting the first video
				screen only.

    INT GetFontFromInitFile	Returns the FontID and integer part of the
				FontSize from the init file from given key
				strings.

    INT CalcSystemAttrs		Calculates system attributes.

    INT SetLightColors		Sets a bunch of color variables to the
				user-chosen light color.

    INT SetDarkColors		Sets a bunch of color variables to the
				user-chosen dark color.

    INT AdjustForDisplayType	Set specific UI variables having to do with
				the color scheme to be used, based on
				whether on B&W display, or CGA.  This
				allows the code to work quicker by just
				using the colors & info stored in these
				tables.

    INT SpecInitGadgetPreferences
				If there is a default video driver, init
				the variable defaultDisplayScheme

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	9/26/89		Documentation update
	JimG	3/8/94		Added support for editable text size.

DESCRIPTION:
	This file contains misc code for the Open Look library


	$Id: cmainCode.asm,v 1.8 98/07/10 10:57:54 joon Exp $

------------------------------------------------------------------------------@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for this library.

CALLED BY:	GLOBAL
PASS:		di = LibraryCallType
RETURN:		carry set on error
DESTROYED:	everything
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	2/28/93    	Initial version
	dlitwin	4/14/94		Now this is defined for all SPUI's, not
				just WizardBA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


LibraryEntry	proc	far

		cmp	di, LCT_ATTACH
		jne	done

IKBD<	call	InitFloatingKbd		>

done:
		ret
LibraryEntry	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecInitWindowPreferences

DESCRIPTION:	Fetches WindowOptions .ini settings, interprets, & stores
		results in olWindowOptions.


CALLED BY:	INTERNAL
		OLFieldAttach

PASS:		ds:si - field specific category string

RETURN:		Boolean Variable olWindowOptions set appropriately

DESTROYED:
	ax, bx, cx, dx, bp

------------------------------------------------------------------------------@

SpecInitWindowPreferences	proc	near	uses ds
	.enter

	call	GetDefaultWindowPreferences	;Returns defaults in bl

;
;	Check to see if keyboards are required
;
	mov	cx, cs
	mov	dx, offset windowOptionsString
	call	InitFileReadInteger
	jc	haveDecision
	push	ax
	and	al, ah			; get "1's" to set
	or	bl, al			; or in "1's"
	pop	ax
	not	ah			; get "0's" to set
	or	al, ah
	and	bl, al			; and in "0's"
haveDecision:
	mov	cx, segment olWindowOptions
	mov	ds, cx
	mov	ds:[olWindowOptions], bl
	.leave
	ret

SpecInitWindowPreferences	endp

windowOptionsString	char	"windowOptions", 0


COMMENT @----------------------------------------------------------------------

FUNCTION:	GetDefaultWindowPreferences

DESCRIPTION:	Returns default window option preferences, as determined by
		the specific UI (before user overrides)

	UIWO_MAXIMIZE_ON_STARTUP:1

	Default TRUE if:

		running on a tiny display screen
		OR running in Keyboard-only mode
		OR InterfaceLevel < UIIL_INTERMEDIATE
		OR LaunchMode = UILM_TRANSPARENT

	This should be fine for the 2/92 demo disk set.  An interesting note
	regarding Eric's implementation of this for the V1.2 Intermediate
	room:  he decided to maximize EVERYTHING, even things
	not maximizable, such as the calculator, as it is a pain to lose
	these little apps when the larger, maximized app behind them is
	clicked on.   Because this was the Intermediate room, he at the
	same time disable the ability to restore or minimize.  I don't
	think we want to go that far in the professional room, though not
	doing so is awkard (you start maximized, but can restore, then not
	maximize again !?).   Some thoughts to pursue are:
			-> having non-maximizable apps always float on top
		   	(like dialog boxes)
	 - Doug 2/11/92

	UIWO_COMBINE_HEADER_AND_MENU_IN_MAXIMIZED_WINDOWS:1

	Default true if running on tiny display screen
	(temporary turned off - brianc 9/28/92)

	UIWO_PRIMARY_MIN_MAX_RESTORE_CONTROLS:1

	Default false if LaunchMode = UILM_TRANSPARENT else true if
		UIInterfaceLevel >= UIIL_INTERMEDIATE

	UIWO_DISPLAY_MIN_MAX_RESTORE_CONTROLS:1

	Default true if UIInterfaceLevel >= UIIL_INTERMEDIATE

	UIWO_WINDOW_MENU:1

;	Default TRUE if keyboardOnly = TRUE.
;
; new thinking: Default TRUE except if penBased = TRUE - brianc 3/23/93

	UIWO_PINNABLE_MENUS

	Default TRUE if UIInterfaceLevel >= UIIL_INTERMEDIATE

	UIWO_KBD_NAVIGATION

	Default TRUE if keyboard only or
		UIInterfaceLevel >= UIIL_INTERMEDIATE

	UIWO_POPOUT_MENU_BAR

	Default TRUE if running on tiny display screen

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		bl	- default UIWindowOptions

DESTROYED:	ax, cx, dx, bp, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version
------------------------------------------------------------------------------@

GetDefaultWindowPreferences	proc	near
	clr	bl			; start blank -- no preferences

	call	UserGetDisplayType	; Get display type in ah

; Determine default for UIWO_COMBINE_HEADER_AND_MENU_IN_MAXIMIZED_WINDOWS:1

	mov	al, ah
	andnf	al, mask DT_DISP_ASPECT_RATIO
	andnf	ah, mask DT_DISP_SIZE

;temporarily turned off - brianc 9/28/92
;	cmp	ah, DS_TINY shl offset DT_DISP_SIZE
;	jne	haveCombineHeaderAndMenu
;	or	bl, mask UIWO_COMBINE_HEADER_AND_MENU_IN_MAXIMIZED_WINDOWS
;haveCombineHeaderAndMenu:

; Determine default for UIWO_MAXIMIZE_ON_STARTUP:1

	cmp	ah, DS_TINY shl offset DT_DISP_SIZE
	je	initMaximized
	cmp	al, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
	je	initMaximized

	push	ax
	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	pop	ax
	jnz	initMaximized

	and	bl, not mask UIWO_MAXIMIZE_ON_STARTUP
	jmp	short	haveMaximizeOnStartup

initMaximized:
	or	bl, mask UIWO_MAXIMIZE_ON_STARTUP
haveMaximizeOnStartup:

; Determine default for UIWO_POPOUT_MENU_BAR:1

	cmp	al, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
	je	popoutMenuBar
	cmp	ah, DS_TINY shl offset DT_DISP_SIZE
	jne	havePopoutMenuBar

popoutMenuBar:
	or	bl, mask UIWO_POPOUT_MENU_BAR
havePopoutMenuBar:

; Determine default for UIWO_PRIMARY_MIN_MAX_RESTORE_CONTROLS:1,
; UIWO_DISPLAY_MIN_MAX_RESTORE_CONTROLS:1 and UIWO_PINNABLE_MENUS:1
; Set UIWO_KBD_NAVIGATION true if advanced intermediate.

	call	UserGetDefaultUILevel
	cmp	al, UIIL_BEGINNING
	jae	advancedIntermediate

	; If novice or beginning intermediate, default to maximize on startup
	;
	or	bl, mask UIWO_MAXIMIZE_ON_STARTUP
	jmp	short afterInterfaceLevel

advancedIntermediate:
	or	bl, mask UIWO_PRIMARY_MIN_MAX_RESTORE_CONTROLS or \
		    mask UIWO_PINNABLE_MENUS or \
		    mask UIWO_KBD_NAVIGATION

afterInterfaceLevel:

; Set UIWO_KBD_NAVIGATION true if keyboard only

	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	jz	haveKbdOnly
	or	bl, mask UIWO_KBD_NAVIGATION
haveKbdOnly:

; Clear UIWO_KBD_NAVIGATION if no keyboard

	test	al, mask UIBF_NO_KEYBOARD
	jz	haveKbdNav			; not no-keyboard, leave
	andnf	bl, not mask UIWO_KBD_NAVIGATION	; else, clear
haveKbdNav:

;
; new thinking - set UIWO_WINDOW_MENU except on penBased = TRUE - brianc 3/23/93
;
	call	SysGetPenMode			; ax = TRUE if penBased
	tst	ax
	jnz	haveWinMenu
	or	bl, mask UIWO_WINDOW_MENU
haveWinMenu:
ISU <	or	bl, mask UIWO_WINDOW_MENU	; default on for ISUI	>

	ret

GetDefaultWindowPreferences	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecGetWindowOptions

DESCRIPTION:	Get the window options

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	al - UIWindowOptions
	ah - 0

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/92		Initial version

------------------------------------------------------------------------------@
SpecGetWindowOptions	proc	far	uses ds
	.enter

	mov	ax, segment olWindowOptions
	mov	ds, ax
	clr	ax
	mov	al, ds:olWindowOptions

	.leave
	ret

SpecGetWindowOptions	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecGetExpressOptions

DESCRIPTION:	Get the express options

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ax - UIExpressOptions

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/92		Initial version

------------------------------------------------------------------------------@
SpecGetExpressOptions	proc	far	uses ds
	.enter

	mov	ax, segment olExpressOptions
	mov	ds, ax
	mov	ax, ds:olExpressOptions

	.leave
	ret

SpecGetExpressOptions	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecInitExpressPreferences

DESCRIPTION:	Fetches Express menu .ini settings, interprets


CALLED BY:	INTERNAL
		OLFieldAttach

PASS:		ds:si - field specific category string

RETURN:

DESTROYED:
	ax, bx, cx, dx, bp

------------------------------------------------------------------------------@

SpecInitExpressPreferences	proc	near	uses ds
	.enter
	;
	; default is based on user level
	;
	call	UserGetDefaultUILevel		; ax = UIInterfaceLevel
	mov	bx, mask UIEO_DESK_ACCESSORY_LIST or \
			mask UIEO_CONTROL_PANEL or \
			mask UIEO_DOS_TASKS_LIST or \
			mask UIEO_UTILITIES_PANEL or \
			mask UIEO_EXIT_TO_DOS or \
			mask UIEO_DOCUMENTS_LIST or \
			UIEP_TOP_PRIMARY shl offset UIEO_POSITION ;
	cmp	ax, UIIL_BEGINNING		; intro and beginning use this
	jbe	haveDefaultExpressPrefs
	mov	bx, mask UIEO_DESK_ACCESSORY_LIST or \
			mask UIEO_MAIN_APPS_LIST or \
			mask UIEO_OTHER_APPS_LIST or \
			mask UIEO_CONTROL_PANEL or \
			mask UIEO_DOS_TASKS_LIST or \
			mask UIEO_UTILITIES_PANEL or \
			mask UIEO_EXIT_TO_DOS or \
			mask UIEO_DOCUMENTS_LIST or \
			UIEP_TOP_PRIMARY shl offset UIEO_POSITION ; UIEP_TOP_PRIMARY

haveDefaultExpressPrefs:
	mov	cx, cs
	mov	dx, offset expressOptionsString
	call	InitFileReadInteger
	jc	haveDecision

	;
	; require some things for ISUI, don't allow others
	;
if _ISUI
	ornf	ax, mask UIEO_DOCUMENTS_LIST or \
			mask UIEO_EXIT_TO_DOS or \
			mask UIEO_CONTROL_PANEL or \
			mask UIEO_UTILITIES_PANEL
endif

if TOOL_AREA_IS_TASK_BAR
	;
	; if TaskBar == on, have no Task-List in E-Menu
	;
	push	ds					; save ds
	segmov	ds, dgroup				; load dgroup
	test	ds:[taskBarPrefs], mask TBF_ENABLED	; test if TB_ENABLED is set
	pop	ds					; restore ds
	jz	hasNoTaskbar				; skip if no taskbar

	andnf	ax, not (mask UIEO_GEOS_TASKS_LIST)

hasNoTaskbar:
endif

	mov	bx, ax			; just copy from .ini file

haveDecision:

	mov	cx, segment olExpressOptions
	mov	ds, cx
	mov	ds:[olExpressOptions], bx

	.leave
	ret

SpecInitExpressPreferences	endp

expressOptionsString	char	"expressOptions", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpecInitHelpPreferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize help preferences for a field

CALLED BY:	OLFieldLoadOptions()
PASS:		ds:si - field specific category string
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpecInitHelpPreferences		proc	far
	uses	ds
	.enter

if BUBBLE_HELP
	push	ds
endif
	clr	ax				;ax <- default UIHelpOptions
	mov	cx, cs
	mov	dx, offset helpOptionsString	;cx:dx <- ptr to key
	call	InitFileReadInteger
	mov	cx, segment olHelpOptions
	mov	ds, cx
	mov	ds:[olHelpOptions], ax

if BUBBLE_HELP
	pop	ds
	;
	; get bubble options
	;
	mov	bl, mask BO_HELP or mask BO_DISPLAY	; defaults
	mov	cx, cs
	mov	dx, offset bubbleHelpString
	call	InitFileReadBoolean
	jc	noBubbleHelpOption
	tst	ax					; false?
	jnz	noBubbleHelpOption			; nope
	andnf	bl, not mask BO_HELP			; false, turn if off
noBubbleHelpOption:
	mov	dx, offset bubbleDisplayString
	call	InitFileReadBoolean
	jc	noBubbleDisplayOption
	tst	ax					; false?
	jnz	noBubbleDisplayOption			; nope
	andnf	bl, not mask BO_DISPLAY			; false, turn it off
noBubbleDisplayOption:
	push	ds
	mov	cx, segment olBubbleOptions
	mov	ds, cx
	mov	ds:[olBubbleOptions], bl		; store options
	pop	ds
	;
	; set bubble help and bubble display times
	;
	push	bp, di
	mov	bx, BUBBLE_HELP_DEFAULT_TIME
	mov	cx, cs
	mov	dx, offset bubbleHelpTimeString
	call	InitFileReadInteger
	jc	noHelpTime
	mov	bx, ax					; bx = bubble help time
noHelpTime:
	mov	dx, offset bubbleHelpDelayString
	call	InitFileReadInteger
	mov	bp, ax
	jnc	haveDelayTime
	mov	bp, BUBBLE_HELP_DEFAULT_DELAY_TIME
haveDelayTime:
	mov	dx, offset bubbleHelpMinTimeString
	call	InitFileReadInteger
	mov	di, ax
	jnc	haveMinTime
	mov	di, BUBBLE_HELP_DEFAULT_MIN_TIME
haveMinTime:
	mov	dx, offset bubbleDisplayTimeString
	call	InitFileReadInteger
	jnc	haveDisplayTime
	mov	ax, BUBBLE_DISPLAY_DEFAULT_TIME
haveDisplayTime:
	mov	cx, segment olBubbleHelpTime
	mov	ds, cx
	mov	ds:[olBubbleHelpTime], bx
	mov	ds:[olBubbleHelpDelayTime], bp
	mov	ds:[olBubbleDisplayTime], ax
	mov	ds:[olBubbleHelpMinTime], di
	pop	bp, di
endif

	.leave
	ret
SpecInitHelpPreferences		endp

helpOptionsString	char	"helpOptions", 0
if BUBBLE_HELP
bubbleHelpString	char	"bubbleHelp", 0
bubbleHelpDelayString	char	"bubbleHelpDelay", 0
bubbleDisplayString	char	"bubbleDisplay", 0
bubbleHelpTimeString	char	"bubbleHelpTime", 0
bubbleDisplayTimeString	char	"bubbleDisplayTime", 0
bubbleHelpMinTimeString	char	"bubbleHelpMinTime",0
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecInitDefaultDisplayScheme

DESCRIPTION:	If the first UI screen has been set up yet, fetch its
		displayType, initialize DisplayScheme DisplayType, Font &
		PointSize.  NOTE:  Current implementation is limited to
		supporting the first video screen only.

CALLED BY:	INTERNAL
		OLFieldAttach
		OLFieldInitialize

PASS:
	none

RETURN:
	Set:
		specDisplayScheme

DESTROYED:
	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Doug	10/90		Revamp for "No ziphod" changes
	JimG	3/1/94		Uses GetFontFromInitFile. does EditableText
				fonts also.

------------------------------------------------------------------------------@
SpecInitDefaultDisplayScheme proc	near
	uses si, di, ds
	.enter

	clr	si				; Pass null object (in case EC)
	call	UserGetDisplayType		; Get display type for 1st
						; 	video screen
	tst	al				; see if initialized yet
	jz	done				; if not, skip out

if _ASSUME_BW_ONLY
	; Force B/W

	andnf	ah, not mask DT_DISP_CLASS
	ornf	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
endif

	mov	bp, ax				; save DisplayType

	call	GrGetDefFontID			; returns: cx = default FontID
						;     dx.ah = default pointsize
						;     bx = default data handle

	mov	ax, offset fontidString
	mov	bx, offset fontsizeString

	call	GetFontFromInitFile		; destroys ax, bx

	mov	ax, segment specDisplayScheme
	mov	ds, ax				;setup ds to be dgroup

						;store font & point size info
	mov	ds:[specDisplayScheme].DS_fontID, cx
	mov	ds:[specDisplayScheme].DS_pointSize, dx

	push	cx, dx				; preserve font info

	mov	ax, bp				;restore DisplayType in ah
	call	AdjustForDisplayType

	call	CalcSystemAttrs			;calculate system attributes


	; FINALLY, let the generic UI know what font we're going to be using,
	; so that it can cache it away & use it later in VisGetMonikerSize.
	;
	pop	cx, dx
	call	UserSetDefaultMonikerFont


	; Get font info for editableText

	push	cx, dx					; save font &
							; size for later
	mov	ax, offset editableTextFontIDString
	mov	bx, offset editableTextFontsizeString
	; cx, dx = fontid, fontsize of defaults
	call	GetFontFromInitFile			; destroy ax, bx

	pop	ax, bx					; UI font and size

	; Only bother to store the font & size if they are different than the
	; default font & size for the UI.

	mov	ds:[editableTextFontID], FID_INVALID

	cmp	ax, cx
	jne	storeEditableText
	cmp	bx, dx
	je	done

storeEditableText:
	; Store editableText font information in dgroup.
	; ds = dgroup, still
	mov	ds:[editableTextFontID], cx
	mov	ds:[editableTextFontsize], dx

done:

	.leave
	ret

SpecInitDefaultDisplayScheme	endp

fontidString		char	"fontid", 0
fontsizeString		char	"fontsize", 0

editableTextFontIDString	char	"editableTextFontID",0
editableTextFontsizeString	char	"editableTextFontsize",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFontFromInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the FontID and integer part of the FontSize
		from the init file from given key strings.

CALLED BY:	SpecInitDefaultDisplayScheme
PASS:		cs:ax	- fontID key string ptr
		cs:bx	- font size key string ptr
		cx	- default FontID
		dx	- default point size

RETURN:		cx	- FontID
		dx	- point size

DESTROYED:	ax, bx
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		Uses fixed category string, categoryString, defined below.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFontFromInitFile	proc	near
fontSizeOffset		local	word		push bx
defaultFontID		local	FontID		push cx
defaultPointSize	local	word		push dx
	uses	si,di,ds			; returns cx, dx
	.enter

	;
	; get font id
	;
	push	bp				; preserve bp for local vars
	mov	cx, cs
	mov	ds, cx
	mov	si, offset categoryString	; ds:si = category
	mov	dx, ax				; cx:dx = key
	clr	bp				; return memory block
	call	InitFileReadString
	pop	bp				; restore bp for locals
	LONG	jc	fontNotFound
	;
	; found string -- bx = handle
	;
	call	MemLock
	mov	ds, ax				; ds <- seg addr of string
	clr	si				; ds:si <- ptr to string
	mov	dl, mask FEF_BITMAPS \
		 or mask FEF_OUTLINES \
		 or mask FEF_DOWNCASE \
		 or mask FEF_STRING		; dl <- fonts to find
	call	GrCheckFontAvail		; see if available
						; Returns cx = FontID
	call	MemFree				; dispose font name buffer
	jcxz	fontNotFound			; jumps back to getPointSize

	;
	; get pointsize from .ini file
	;
getPointSize:
	push	cx				; save font ID
	mov	cx, cs
	mov	ds, cx
	mov	si, offset categoryString	; ds:si = category
	mov	dx, ss:[fontSizeOffset]		; cx:dx = key
	call	InitFileReadInteger
	mov_tr	dx, ax				; dx <- pointsize
	pop	cx				; cx <- font ID
	jc	sizeNotFound			; branch if not in .ini file

setPointSize:
						; cx = fontID
						; dx.ah = pointsize (WBFixed)
	clr	ax				; al = FontStyle

	call	GrFindNearestPointsize		; use nearest size
	jcxz	sizeNotFound			; branch if size/style N/A
done:
	.leave
	ret					; <-- RETURN

;
; Asking for a font or pointsize that is not availble is
; a bad thing. (in addition, the size check will fail if there
; is not a plaintext version of the font available, as with
; Eurostile Extended). If either of these things happen, we
; use the defaults as determined by the kernel at boot time.
;					-eca
;
fontNotFound:
	mov	cx, ss:[defaultFontID]		; use passed default fontID
	jmp	getPointSize
sizeNotFound:
	mov	cx, ss:[defaultFontID]		; use passed defaults
	mov	dx, ss:[defaultPointSize]
	jmp	done				; move on to next thing
GetFontFromInitFile	endp


categoryString		char	"ui",0



COMMENT @----------------------------------------------------------------------

ROUTINE:	CalcSystemAttrs

SYNOPSIS:	Calculates system attributes.

CALLED BY:	SpecInitDefaultDisplayScheme

PASS:		ds - dgroup

RETURN:		ax -- SystemAttrs

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Right now a display has to be CSF_VERY_SQUISHED to be horizontally tiny.
	We need OLScreen sizes to do this right.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/ 1/93       	Initial version

------------------------------------------------------------------------------@

CalcSystemAttrs	proc	near
	call	SysGetPenMode			;get pen mode
	tst	ax
	jz	10$				;no pen mode, branch
	mov	ax, mask SA_PEN_BASED		;else set this
10$:
	mov	dx, idata
	mov	ds, dx
	mov	bh, ds:[moCS_flags]

	test	bh, mask CSF_BW
	jnz	20$
	ORNF	ax, mask SA_COLOR		;set the color flag if needed
20$:
	test	bh, mask CSF_VERY_NARROW or mask CSF_VERY_SQUISHED or mask CSF_TINY
	jz	25$
	ORNF	ax, mask SA_TINY
25$:

;	BX <- SystemAttrs
;	(CSF_VERY_NARROW/SQUSHED map to the same positions as
;		SA_HORIZONTALLY_TINY and SA_VERTICALLY_TINY)
;

	ANDNF	bx, (mask CSF_VERY_NARROW or mask CSF_VERY_SQUISHED) shl 8
	ORNF	bx, ax

	call	FlowGetUIButtonFlags
	test	al, mask UIBF_KEYBOARD_ONLY
	jz	30$
	ORNF	bx, mask SA_KEYBOARD_ONLY
30$:
	test	al, mask UIBF_NO_KEYBOARD
	jz	40$				;noKeyboard set, branch, c=0
	ORNF	bx, mask SA_NO_KEYBOARD
40$:

	;
	; Set the orientation flags depending on the screen dimension.
	;
	call	GetFieldDimensions
	mov	ax, mask SA_PORTRAIT
	cmp	cx, dx
	jl	setOrientationFlag		; width < height
	cmp	dx, cx
	je	setOrientationFlag		; width = height
	clr	ax
setOrientationFlag:
	ORNF	bx, ax

	mov	ds:olSystemAttrs, bx
	mov_tr	ax, bx				; SystemAttrs flags

	ret

	CheckHack <((mask CSF_VERY_NARROW shl 8) eq mask SA_HORIZONTALLY_TINY)>
	CheckHack <((mask CSF_VERY_SQUISHED shl 8) eq mask SA_VERTICALLY_TINY)>
CalcSystemAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFieldDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the field width and height.

CALLED BY:	CalcSystemAttrs

PASS:		nothing

RETURN:		cx	- field width
		dx	- field height

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _DUI
GetFieldDimensionsFar	proc	far
	call	GetFieldDimensions
	ret
GetFieldDimensionsFar	endp
endif

GetFieldDimensions	proc	near
	uses	ax,ds
	.enter

	segmov	ds, idata, ax
	mov	cx, ds:[fieldWidth]
	mov	dx, ds:[fieldHeight]
	tst	dx
	jnz	done				; it's cached

	segmov	ds, ss
	call	OpenGetScreenDimensions		; cx=width, dx=height

if FAKE_SIZE_OPTIONS
	call	FakeFieldDimensions		; cx=newWidth, dx=newHeight
endif

	segmov	ds, idata, ax
	mov	ds:[fieldWidth], cx
	mov	ds:[fieldHeight], dx

done:
	.leave
	ret
GetFieldDimensions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FakeFieldDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check .ini file for fake field sizes to use.  If found,
		substitute here. If the continueSetup boolean equals true,
		we ignore any size.

CALLED BY:	(INTERNAL) GetFieldDimensions

PASS:		cx,dx	- width,height of field so far

RETURN:		cx,dx	- width,height of field (may have changed)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if FAKE_SIZE_OPTIONS

FakeFieldDimensions	proc	near
	uses	ax,bx,ds,si
	.enter

	mov_tr	ax, cx					; old width
	mov	bx, dx					; old height

	mov	cx, cs
	mov	ds, cx

	mov	si, offset screenSizeCategoryString	; ds:si = category str
	mov	dx, offset xFieldSizeString		; cx:dx = key str
	call	InitFileReadInteger			; ax = newHeight

	xchg	ax, bx					; old height,
							; new width

	mov	dx, offset yFieldSizeString		; cx:dx = key str
	call	InitFileReadInteger

	mov_tr	dx, ax					; new height
	mov	cx, bx					; new width

	.leave
	ret
FakeFieldDimensions	endp

screenSizeCategoryString	char	"ui", 0
xFieldSizeString		char	"xFieldSize", 0
yFieldSizeString		char	"yFieldSize", 0

endif ; FAKE_SIZE_OPTIONS



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetLightColors

SYNOPSIS:	Sets a bunch of color variables to the user-chosen light color.

CALLED BY:	SpecInitDefaultDisplayScheme

PASS:		al -- color

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/15/91		Initial version

------------------------------------------------------------------------------@

ifdef	USER_CAN_CHOOSE_COLORS
SetLightColors	proc	near
EC <	call	ECCheckESDGroup					>
	mov	es:[moCS_dsLightColor], al	;else store a bunch of values
	mov	es:[moCS_windowBG], al
	mov	es:[moCS_menuBar], al
	mov	es:[moCS_activeBorder], al
	mov	es:[moCS_inactiveBorder], al
	ret
SetLightColors	endp
endif

COMMENT @----------------------------------------------------------------------

ROUTINE:	SetDarkColors

SYNOPSIS:	Sets a bunch of color variables to the user-chosen dark color.

CALLED BY:	SpecInitDefaultDisplayScheme

PASS:		al -- color
		es -- dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/15/91		Initial version

------------------------------------------------------------------------------@

ifdef	USER_CAN_CHOOSE_COLORS
SetDarkColors	proc	near
EC <	call	ECCheckESDGroup					>
	mov	es:[moCS_dsDarkColor], al	;else store a bunch of values
	mov	es:[moCS_screenBG], al
	mov	es:[moCS_appWorkspace], al
;;	mov	es:[moCS_activeTitleBar], al	;don't want this for any SPUI
	mov	es:[moCS_windowFrame], al
	mov	es:[moCS_scrollBars], al
	mov	es:[moCS_menuSelection], al
	mov	es:[moCS_inactiveTitleBar], al
	ret
SetDarkColors	endp
endif




COMMENT @----------------------------------------------------------------------

FUNCTION:	AdjustForDisplayType

DESCRIPTION:	Set specific UI variables having to do with the color scheme
		to be used, based on whether on B&W display, or CGA.  This
		allows the code to work quicker by just using the colors & info
		stored in these tables.


CALLED BY:	INTERNAL
		SpecInitDefaultDisplayScheme

PASS:
		ah	- DisplayType

RETURN:
	moCS_flags			- set
	moCS_displayType		- set
	specDisplayScheme.DS_colorScheme	- set
	specDisplayScheme.DS_displayType	- set

DESTROYED:
	cx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/90		Initial version
------------------------------------------------------------------------------@
NARROW_WIDTH	equ	300		;Anything over 300 pixels wide is not
					; narrow (or so we say).

AdjustForDisplayType	proc	near	uses	ds, es
	.enter
	mov	cx, segment idata		;get segment of core blk
	mov	ds, cx				; in ds
	mov	es, cx				; & in es

	mov	ch, ah
	andnf	ch, mask DF_DISPLAY_TYPE
	cmp	ch, DC_GRAY_1			;is this black and white?
	jnz	afterBWAdjust			;no, branch

	; if on a monochrome monitor, copy Monochrome color value
	; table over Color Scheme vars
	push	ax
	mov	si, offset CUA_MonochromeColorTable
	mov	di, offset CUA_ColorSchemeVars
	mov	cl, ds:[moCS_numVars]		;cx = # of byte vars in table
	clr	ch
	rep movsb
	pop	ax

	or	ds:[moCS_flags], mask CSF_BW
afterBWAdjust:
	mov	ds:[moCS_displayType], ah	;store display type

	push	ax
	andnf	ah, mask DT_DISP_SIZE
						; But then check for tiny screen
	cmp	ah, DS_TINY shl offset DT_DISP_SIZE
	pop	ax
	jne	afterTinyAdjustments		; skip if not
	or	ds:[moCS_flags], mask CSF_TINY
afterTinyAdjustments:
	push	ax
	andnf	ah, mask DT_DISP_ASPECT_RATIO
	cmp	ah, DAR_TV shl offset DT_DISP_ASPECT_RATIO
	pop	ax
	jne	afterTV
	or	ds:[moCS_flags], mask CSF_TV
afterTV:

	push	ax
	andnf	ah, mask DT_DISP_ASPECT_RATIO
	cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
	pop	ax
	jne	afterVerySquishedAdjustments
	or	ds:[moCS_flags], mask CSF_VERY_SQUISHED

MO <	mov	ds:[olArrowSize], 10	     ;default to arrow size 10 in CGA>
	;
	; 1/26/98 ND-000319, et al: force CGA to 9 point, and editable
	; text to match. -- eca
	;
	mov	ds:[specDisplayScheme].DS_pointSize, 9
	mov	ds:[editableTextFontsize], 9

afterVerySquishedAdjustments:

	push	ax
	;
	; Check to see if the display is narrow - if so, set the "very narrow"
	; flag...
	; The way we get the screen size is via a total HACK - we get the
	; size of the UI's application object...
	clr	bx
	call	GeodeGetAppObject

	mov	ax, MSG_VIS_GET_SIZE
	mov	di, mask MF_CALL
	call	ObjMessage

	cmp	cx, NARROW_WIDTH
	ja	notNarrow
	ornf	ds:[moCS_flags], mask CSF_VERY_NARROW
notNarrow:
	pop	ax			;Restore display type in AH
	; Finally, get & store the default display type & color scheme
	;
	mov	al, ds:[moCS_dsDarkColor]
	mov	ds:[specDisplayScheme.DS_darkColor], al
	mov	al, ds:[moCS_dsLightColor]	;construct from light & dark
	mov	ds:[specDisplayScheme.DS_lightColor], al
	mov	cl, 4
	shl	al, cl
	or	al, ds:[moCS_dsDarkColor]
	mov	{word} ds:[specDisplayScheme.DS_colorScheme], ax
	.leave
	ret

AdjustForDisplayType	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecInitGadgetPreferences

DESCRIPTION:	If there is a default video driver, init the variable
		defaultDisplayScheme

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	Set:
		gadgetRepeatDelayString

DESTROYED:
	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Doug	10/90		Pulled out into separate routine

------------------------------------------------------------------------------@

SpecInitGadgetPreferences proc	near		uses si, di, ds, es
	.enter

	;
	; Set up some registers
	;
	mov	ax, segment dgroup
	mov	es, ax
	mov	cx, cs
	mov	ds, cx

	mov	si, offset inputCat
	mov	dx, offset floatingKbdKey
	clr	ax
	call	InitFileReadBoolean
	mov	es:[kbdRequired], al

	;
	; As long as we're pulling thinngs out of the .ini file, let's pull
	; out the gadget repeat delay and store it.
	;
	mov	dx, offset gadgetRepeatDelayString   ;cx:dx = key
	mov	si, offset optionsCatString	;ds:si = category
	mov	ax, DEFAULT_GADGET_REPEAT_DELAY ;in case not found
	call	InitFileReadInteger
	mov	es:[olGadgetRepeatDelay], ax	; Save gadget repeat delay

	;
	; Now find out if we want gadgets to accelerate.
	;
	mov	dx, offset gadgetAccelerateString    ;cx:dx = key
	clr	ax
	call	InitFileReadBoolean
	mov	es:[olGadgetAccelerate], al	; Save gadget accelerate flag.

	;
	; Setup custom gadget colors, if desired.
	;
ifdef	USER_CAN_CHOOSE_COLORS

	call	OpenCheckIfBW			;No special colors in B/W
	jc	afterActiveTitleBarColor
	mov	si, offset optionsCatString	;ds:si = category
	mov	dx, offset lightColorString	;cx:dx = key
	call	InitFileReadInteger
	jc	tryDarkColor			;branch if not in .ini file
	call	SetLightColors

tryDarkColor:
	mov	dx, offset darkColorString
	call	InitFileReadInteger
	jc	afterDarkColor
	call	SetDarkColors

afterDarkColor:
	mov	dx, offset activeTitleBarColorString
	call	InitFileReadInteger
	jc	afterActiveTitleBarColor
	mov	es:[moCS_activeTitleBar], al
	mov	es:[moCS_titleBar2], al
afterActiveTitleBarColor:
	mov	dx, offset titleBar2String
	call	InitFileReadInteger
	jc	afterTitleBar2Color
	mov	es:[moCS_titleBar2], al
afterTitleBar2Color:

	mov	dx, offset selectColorString
	call	InitFileReadInteger
	jc	afterSelectColor
	mov	es:[moCS_selBkgdColor], al
afterSelectColor:

endif

if	_MOTIF
	;
	; Set up scroller arrow widths and heights.
	;
	mov	dx, offset scrollerSizeString   ;cx:dx = key
	mov	si, offset optionsCatString	;ds:si = category
	call	InitFileReadInteger
	jc	noSize				;branch if not in .in file
	test	ax, 1				;make size is even
	jz	sizeEven
	inc	ax
sizeEven:
	cmp	ax, MIN_ARROW_SIZE		;make sure arrow not too small
	jae	20$
	mov	ax, MIN_ARROW_SIZE
20$:
	cmp	ax, MAX_ARROW_SIZE		;make sure arrow not too big
	jbe	30$
	mov	ax, MAX_ARROW_SIZE
30$:
	mov	es:[olArrowSize], ax		; Save arrow size
noSize:
endif

if	_MOTIF
	;
	; Set up resize border thicknesses.
	;
	mov	dx, offset tbResizeBorderThicknessString   ;cx:dx = key
	mov	si, offset optionsCatString	;ds:si = category
	call	InitFileReadInteger
	jc	noHeight			;branch if not in .in file
	mov	es:[resizeBarHeight], ax	;Save resize bar height
noHeight:
	mov	dx, offset lrResizeBorderThicknessString   ;cx:dx = key
	mov	si, offset optionsCatString	;ds:si = category
	call	InitFileReadInteger
	jc	noWidth				;branch if not in .in file
	mov	es:[resizeBarWidth], ax		;Save resize bar width
noWidth:
endif

	;
	; init olFileSelectorStaticDrivePopupMoniker
	;
	mov	dx, offset fsDriveMonikerString   ;cx:dx = key
	mov	si, offset optionsCatString	;ds:si = category
	mov	ax, FALSE			;in case not found
	call	InitFileReadBoolean		;ax = value
	mov	es:[olFileSelectorStaticDrivePopupMoniker], al

	;
	; Now find out if we want single clicks to be treated as double
	; clicks in single action file selectors.
	;
	mov	dx, offset fsSingleClickToOpenString	;cx:dx = key
	clr	ax
	call	InitFileReadBoolean
	mov	es:[olFileSelectorSingleClickToOpen], al

	;
	; init olNoDefaultRing, only if penBased = true.
	;
	call	SysGetPenMode			;get pen mode
	tst	ax
	jz	afterNoDefaultRing		;no pen mode, branch
	mov	dx, offset noDefaultRingString  ;cx:dx = key
	mov	si, offset optionsCatString	;ds:si = category
	mov	ax, FALSE			;in case not found
	call	InitFileReadBoolean		;ax = value
	mov	es:[olNoDefaultRing], al
afterNoDefaultRing:

	;
	; init specDoClickSound.
	;
	mov	dx, offset clickSoundsString    ;cx:dx = key
	mov	si, offset optionsCatString	;ds:si = category
	mov	ax, FALSE			;in case not found
	call	InitFileReadBoolean		;ax = value
	mov	es:[specDoClickSound], al

	;
	; init button invert delay
	;
	mov	dx, offset buttonInvertDelayString   ;cx:dx = key
	mov	si, offset optionsCatString	;ds:si = category
	mov	ax, DEFAULT_BUTTON_INVERT_DELAY ;in case not found
	call	InitFileReadInteger
	mov	es:[olButtonInvertDelay], ax	; Save button invert delay
	jc	afterInvertDelay
	mov	es:[olButtonActivateDelay], ax
afterInvertDelay:

	;
	; init olPDA.
	;
	mov	dx, offset pdaKeyString		;cx:dx = key
	mov	si, offset pdaCatString		;ds:si = category
	mov	ax, FALSE			;in case not found
	call	InitFileReadBoolean		;ax = value
	mov	es:[olPDA], ax

	;
	; init olExtWinAttrs
	;
	mov	dx, offset extWinAttrsString
	mov	si, offset optionsCatString
	mov	ax, ExtWinAttrs<1, 1>
	call	InitFileReadInteger
	mov	es:[olExtWinAttrs], ax

if TOOL_AREA_IS_TASK_BAR
	;
	; init taskBar
	;
	mov	dx, offset taskBarEnabledString
	mov	si, offset optionsCatString
	andnf	es:[taskBarPrefs], not (mask TBF_ENABLED)
	call	InitFileReadBoolean
	cmp	ax, FALSE
	jz	afterEnabled
	ornf	es:[taskBarPrefs], mask TBF_ENABLED
afterEnabled:

	;
	; init taskBarMovable
	;
	mov	dx, offset taskBarMovableString
	mov	si, offset optionsCatString
	andnf	es:[taskBarPrefs], not (mask TBF_MOVABLE)
	call	InitFileReadBoolean
	cmp	ax, FALSE
	jz	afterMovable
	ornf	es:[taskBarPrefs], mask TBF_MOVABLE
afterMovable:

	;
	; init taskBarAutoHide
	;
	mov	dx, offset taskBarAutoHideString
	mov	si, offset optionsCatString
	andnf	es:[taskBarPrefs], not (mask TBF_AUTO_HIDE)
	call	InitFileReadBoolean
	cmp	ax, FALSE
	jz	afterAutoHide
	ornf	es:[taskBarPrefs], mask TBF_AUTO_HIDE

afterAutoHide:

	;
	; init taskBarPosition
	;
	mov	dx, offset taskBarPositionString
	mov	si, offset optionsCatString
	call	InitFileReadInteger
	cmp	ax, 3						; we have 4 (zero-based) position values
	jbe	setTaskbarPosVal				; jump if below or equal
	mov	ax, TBP_BOTTOM					; if value is out of bounds, set to bottom
setTaskbarPosVal:
	andnf	es:[taskBarPrefs], not mask TBF_POSITION	; make sure bits are clear
	shl	ax, offset TBF_POSITION				; shift position bits to index of TBF_POSITION
	ornf	es:[taskBarPrefs], ax				; set position bits
endif

if _ISUI
	mov	si, offset optionsCatString
	mov	dx, offset rightClickHelpString
	mov	ax, TRUE
	call	InitFileReadBoolean
	mov	es:[olRightClickHelp], ax
	mov	dx, offset rightClickTimeString
	mov	ax, 15				; 15 ticks = 1/4 second
	call	InitFileReadInteger
	mov	es:[olRightClickTime], ax
endif

	.leave
	ret

SpecInitGadgetPreferences endp

if	_STYLUS		;Stylus also defines Motif.. this avoids redefinition.
optionsCatString	char	"stylus options",0
else
MO <optionsCatString	char	"motif options",0			>
ISU <optionsCatString	char	"motif options",0			>
endif	;_STYLUS

ifdef	USER_CAN_CHOOSE_COLORS
darkColorString			char	"darkColor",0
lightColorString		char	"lightColor",0
activeTitleBarColorString	char	"active title bar color",0
selectColorString		char	"selectColor",0
titleBar2String			char	"titleBarGradient",0
endif

gadgetRepeatDelayString 	char	"gadgetRepeatDelay",0
gadgetAccelerateString		char	"gadgetAccelerate",0
fsDriveMonikerString		char	"fsStaticDriveMoniker",0
fsSingleClickToOpenString	char	"fsSingleClickToOpen",0
noDefaultRingString		char	"noDefaultRing",0
clickSoundsString		char	"clickSounds",0
buttonInvertDelayString		char	"buttonInvertDelay",0
extWinAttrsString		char	"externalWinAttrs",0

if	_MOTIF
scrollerSizeString	char	"scroll arrow size",0
lrResizeBorderThicknessString	char	"lrResizeBorderThickness",0
tbResizeBorderThicknessString	char	"tbResizeBorderThickness",0
endif

pdaCatString	char	"system",0
pdaKeyString	char	"pda",0

inputCat		char	"input",0
floatingKbdKey		char	"floatingKbd",0

if TOOL_AREA_IS_TASK_BAR
taskBarEnabledString	char	"taskBarEnabled",0
taskBarPositionString	char	"taskBarPosition",0
taskBarAutoHideString	char	"taskBarAutoHide",0
taskBarMovableString	char	"taskBarMovable",0
endif

if _ISUI
rightClickHelpString	char	"rightClickHelp",0
rightClickTimeString	char	"rightClickHelpTime",0
endif

Init	ends
