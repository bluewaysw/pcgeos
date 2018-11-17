COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainKeyboard.asm

AUTHOR:		Andrew Wilson, Oct 12, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/12/92	Initial revision
	dlitwin	4/12/94		Moved to SPUI from UI, renamed from
				uiKeyboard.asm to cmainKeyboard.asm

DESCRIPTION:
	Contains code to implement the VisKeyboard object	

	$Id: cmainKeyboard.asm,v 1.1 97/04/07 10:52:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _GRAFFITI_UI

CommonUIClassStructures segment resource
	VisKeyboardClass
CommonUIClassStructures ends

endif


if INITFILE_KEYBOARD
udata	segment

floatingKbdSize		KeyboardSize

charTableRectWidth	word			; width of a single char rect
charTableRectHeight	word			; height of a single char rect
charTableWidth		word			; width of the whole table
charTableHeight		word			; height of the whole table

hwrGridWidth		word
hwrGridHeight		word
hwrGridVerticalMargin	word
hwrGridHorizontalMargin	word

udata	ends
endif			; if INITFILE_KEYBOARD



Init	segment resource

if INITFILE_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFloatingKbd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the floating keyboard constants

CALLED BY:	UserAttach()

PASS:		nothing

RETURN:		Nothing

DESTROYED:	ax, cx, dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/11/93		Initial version
	dlitwin	4/14/94		Moved to the SPUI, made it called on the 
				SPUI start up instead of the UI UserAttach

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

keyboardSizeString		char	"keyboardSize", 0
uiCategoryStr	char	"ui",0

InitFloatingKbd	proc	near
	uses	ds
	.enter
	
	mov	ax, dgroup
	mov	ds, ax
	push	ds
	mov	cx, cs
	mov	dx, offset cs:[keyboardSizeString]
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	clr	ax				; KS_STANDARD size is default
	call	InitFileReadInteger
	pop	ds

	mov	ds:[floatingKbdSize], ax
	tst	ax				; do we have STANDARD settings?
	jz	storeStandardSettings		

	mov	ds:[charTableRectWidth], ZOOMER_CHAR_TABLE_RECT_WIDTH
	mov	ds:[charTableRectHeight], ZOOMER_CHAR_TABLE_RECT_HEIGHT
	mov	ds:[charTableWidth], ZOOMER_CHAR_TABLE_WIDTH
	mov	ds:[charTableHeight], ZOOMER_CHAR_TABLE_HEIGHT

	mov	ds:[hwrGridWidth], ZOOMER_HWR_GRID_WIDTH
	mov	ds:[hwrGridHeight], ZOOMER_HWR_GRID_HEIGHT
	mov	ds:[hwrGridVerticalMargin], ZOOMER_HWR_GRID_VERTICAL_MARGIN
	mov	ds:[hwrGridHorizontalMargin], ZOOMER_HWR_GRID_HORIZONTAL_MARGIN
	jmp	done

storeStandardSettings:
	mov	ds:[charTableRectWidth], KEYBOARD_CHAR_TABLE_RECT_WIDTH
	mov	ds:[charTableRectHeight], KEYBOARD_CHAR_TABLE_RECT_HEIGHT
	mov	ds:[charTableWidth], KEYBOARD_CHAR_TABLE_WIDTH
	mov	ds:[charTableHeight], KEYBOARD_CHAR_TABLE_HEIGHT

	mov	ds:[hwrGridWidth], KEYBOARD_HWR_GRID_WIDTH
	mov	ds:[hwrGridHeight], KEYBOARD_HWR_GRID_HEIGHT
	mov	ds:[hwrGridVerticalMargin], KEYBOARD_HWR_GRID_VERTICAL_MARGIN
	mov	ds:[hwrGridHorizontalMargin], KEYBOARD_HWR_GRID_HORIZONTAL_MARGIN

done:

	.leave
	ret
InitFloatingKbd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisKeyboardSetToZoomerSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Configure our instance data for Zoomer keyboard size.

CALLED BY:	MSG_VIS_KEYBOARD_SET_TO_ZOOMER_SIZE
PASS:		*ds:si	= VisKeyboardClass object
		ds:di	= VisKeyboardClass instance data
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisKeyboardSetToZoomerSize	method dynamic VisKeyboardClass, 
					MSG_VIS_KEYBOARD_SET_TO_ZOOMER_SIZE
	.enter

	mov	ds:[di].VI_bounds.R_right, ZOOMER_KBD_WIDTH
	mov	ds:[di].VI_bounds.R_bottom, ZOOMER_KBD_HEIGHT+1

	mov	ds:[di].VKI_kbdLayoutOffset, offset ZoomerKeyboardLayout
	mov	ds:[di].VKI_kbdLayoutLength, length ZoomerKeyboardLayout

	mov	ds:[di].VKI_keyHeight, ZOOMER_KEY_HEIGHT

	mov	ds:[di].VKI_letterFontType, ZOOMER_FONT_TYPE
	mov	ds:[di].VKI_letterFontSize, ZOOMER_FONT_SIZE

	mov	ds:[di].VKI_wordFontType, ZOOMER_FONT_TYPE
	mov	ds:[di].VKI_wordFontSize, ZOOMER_FONT_SIZE

	.leave
	ret
VisKeyboardSetToZoomerSize	endm

endif			; if INITFILE_KEYBOARD



if ERROR_CHECK

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckESDGroup

DESCRIPTION:	Checks to see if ES contains DGroup.

CALLED BY:	EXTERNAL

PASS:
	ds or es - segment to check

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/93		Initial version
------------------------------------------------------------------------------@
ECCheckESDGroup	proc	far
ForceRef ECCheckESDGroup

	push	ax
	mov	ax, es
	cmp	ax, dgroup
	ERROR_NE UI_EXPECTED_DGROUP
	pop	ax
	ret
ECCheckESDGroup	endp
endif

Init	ends


if not _GRAFFITI_UI

VisKeyboardCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Code for VisKeyboardClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisKeyboardDeref_DSDI	proc	near
	.enter
EC <	call	ECCheckVisKbdObj			;>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	.leave
	ret
VisKeyboardDeref_DSDI	endp

VisKeyboardGetKBSHandle	proc	near	uses	di
	class	VisKeyboardClass
	.enter
	call	VisKeyboardDeref_DSDI
	mov	ax, ds:[di].VKI_kbsHandle
	.leave
	ret
VisKeyboardGetKBSHandle	endp

VisKeyboardSetKBSHandle	proc	near	uses	di
	class	VisKeyboardClass
	.enter
	call	VisKeyboardDeref_DSDI
	mov	ds:[di].VKI_kbsHandle, ax
	.leave
	ret
VisKeyboardSetKBSHandle	endp

VisKeyboardSetModState	proc	near	uses	di
	class	VisKeyboardClass
	.enter
	call	VisKeyboardDeref_DSDI
	mov	ds:[di].VKI_modState, al
	.leave
	ret
VisKeyboardSetModState	endp

KeyboardGetGState	proc	near
	class	VisKeyboardClass
	.enter
	call	VisKeyboardDeref_DSDI
	mov	di, ds:[di].VCGSI_gstate
	.leave
	ret
KeyboardGetGState	endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckVisKbdObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify *ds:si is pointing to VisKeyboard object

CALLED BY:	INTERNAL
PASS:		*ds:si - ptr to check
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckVisKbdObj	proc	near	uses	es, di
	.enter

	mov	di, segment VisKeyboardClass				
	mov	es, di							
	mov	di, offset VisKeyboardClass				
	call	ObjIsObjectInClass					
	ERROR_NC	ILLEGAL_OBJECT_PASSED_TO_VIS_KEYBOARD_ROUTINE	

	.leave
	ret
ECCheckVisKbdObj	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckKbdPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify a pointer is in the KeyboardStruct table

CALLED BY:	KeyboardPress()
PASS:		ds:bx - ptr to check
		*ds:si - VisKbdClass object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckKbdPtr	proc	near
	uses	ax, cx, si
	.enter

	push	si
	mov	si, bx				;ds:si <- ptr to check
	call	ECCheckBounds			;verify ptr is within block
	pop	si

	call	VisKeyboardGetKBSHandle
	mov	si, ax
	mov	si, ds:[si]			;ds:si <- ptr to table
	cmp	bx, si
	ERROR_B KBD_PTR_OUT_OF_BOUNDS
	ChunkSizePtr	ds, si, cx		;cx <- size of table
	add	si, cx				;ds:si <- ptr to end of table
	cmp	bx, si
	ERROR_AE KBD_PTR_OUT_OF_BOUNDS

	.leave
	ret
ECCheckKbdPtr	endp




endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardLayoutChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There was a change to the keyboard layout, so redraw with the
		new keyboard layout.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardLayoutChange	method	VisKeyboardClass,
					MSG_NOTIFY_KEYBOARD_LAYOUT_CHANGE
	.enter
	mov	ax, MSG_META_GET_OPTR
	call	VisCallParent
	tstdw	cxdx			;If we aren't on screen, exit
	jz	exit
	pushdw	cxdx

;	Remove the object from the screen, and re-add it, to force a
;	MSG_VIS_OPEN/CLOSE pair, so we will reload the kbd layout data

	mov	ax, MSG_VIS_REMOVE
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock

	mov	cx, ds:[LMBH_handle]		;^lCX:DX <- VisKeyboard object
	mov	dx, si
	popdw	bxsi				;^lBX:SI <- parent object

	mov	ax, MSG_VIS_ADD_CHILD
	mov	bp, CCO_FIRST shl offset CCF_REFERENCE
	call	KBD_ObjMessageFixupDS

	mov	ax, MSG_VIS_MARK_INVALID
	movdw	bxsi, cxdx
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_WINDOW_INVALID or \
				mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

exit:
	.leave
	ret
KeyboardLayoutChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message handler for MSG_VIS_OPEN for the VisKeyboardClass

CALLED BY:	GLOBAL

PASS:		*ds:si	= VisKeyboardClass object
		ds:di	= VisKeyboardClass instance data
		bp	= 0 if top window, else window for object to open on
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/16/92   	Initial version
	dlitwin	5/2/94		Modified to use instance data keyboard layout
				size instead of hardcoded constants

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardVisOpen	method dynamic VisKeyboardClass, MSG_VIS_OPEN
	.enter

	mov	di, offset VisKeyboardClass
	call	ObjCallSuperNoLock

	;
	; Get the size of the table to allocate in our lmem block
	;
	call	VisKeyboardDeref_DSDI
	tst	ds:[di].VKI_kbsHandle
	jnz	noAlloc

	mov	al, size KeyboardStruct
	mul	ds:[di].VKI_kbdLayoutLength
	mov	cx, ax
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc		;ax <- handle of the chunk
	call	VisKeyboardSetKBSHandle

	;
	; Check for the keyboardShiftRelStr and set or instance data 
	; appropriately.
	;
	push	ds, si
	mov	cx, cs
	mov	ds, cx
	mov	si, offset uiCategoryString
	mov	dx, offset keyboardShiftRelStr
	call	InitFileReadBoolean
	pop	ds, si
	jc	skipShiftRelStr
	tst	ax
	jz	skipShiftRelStr
	mov	di, ds:[si]
	add	di, ds:[di].VisKeyboard_offset
	mov	ds:[di].VKI_shiftRelease, -1
skipShiftRelStr:

if STYLUS_KEYBOARD
	push	ds, si
	mov	cx, cs
	mov	ds, cx				; both segments are cs
	mov	si, offset keyboardCategoryString
	mov	dx, offset keyboardAltGrString
	clr	ax				; assume no AltGr
	call	InitFileReadBoolean
	pop	ds, si

	mov	di, ds:[si]
	add	di, ds:[di].VisKeyboard_offset
	mov	ds:[di].VKI_hasAltGr, al
	tst	al
	jnz	noAlloc

	;
	; If there is no AltGr key (Right Alt), our table can stop after
	; Delete's scancode.  If there is, leave the length alone.
	;
	mov	ds:[di].VKI_kbdLayoutLength, DELETE_SCANCODE
endif		; if STYLUS_KEYBOARD

noAlloc:
	call	KeyboardGetCharacters

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_KEYBOARD_OBJECTS
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GCNListAdd

	.leave
	ret
KeyboardVisOpen	endm

uiCategoryString	char	"ui",0
keyboardShiftRelStr	char	"keyboardShiftRelStr",0

if STYLUS_KEYBOARD
keyboardCategoryString	char	"keyboard", 0
keyboardAltGrString	char	"keyboardAltGr", 0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Message handler for MSG_VIS_CLOSE for the VisKeyboardClass
CALLED BY:	GLOBAL
PASS:		*ds:si	= VisKeyboardClass object
		ds:di	= VisKeyboardClass instance data
		ds:bx	= VisKeyboardClass object (same as *ds:si)
		es 	= segment of VisKeyboardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardVisClose	method dynamic VisKeyboardClass, MSG_VIS_CLOSE

	mov	di, offset VisKeyboardClass
	call	ObjCallSuperNoLock

	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_KEYBOARD_OBJECTS
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GCNListRemove
	ret
KeyboardVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up extra kbd information before freeing itself.

CALLED BY:	GLOBAL
PASS:		*ds:si - VisKeyboard object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardObjFree	method	VisKeyboardClass, MSG_META_OBJ_FREE
	push	ax
	call	VisKeyboardGetKBSHandle
	tst	ax
	jz	exit
	call	LMemFree
exit:
	pop	ax
	mov	di, offset VisKeyboardClass
	GOTO	ObjCallSuperNoLock
KeyboardObjFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardGetCharacters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query the keyboard driver to get the characters on each key
		Fill in the KeyboardStruct in the LMem block table

CALLED BY:	KeyboardVisOpen

PASS:		*ds:si - VisKeyboardClass
RETURN:		nothing
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/16/90		Initial version
	JT	7/15/92		Modified
	dlitwin	4/30/94		Modified to use instance data keyboardlayouts
				instead of hardcoded sizes and offsets

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardGetCharacters	proc	near
	class	VisKeyboardClass
kbdDriver	local	fptr
layoutLength	local	byte
	uses	ds, si, bx, di, es
	.enter

EC <	call	ECCheckVisKbdObj			>
	call	VisKeyboardDeref_DSDI
	clr	ds:[di].VKI_modState		; clear out mod state
	mov	al, ds:[di].VKI_kbdLayoutLength
	mov	ss:[layoutLength], al

	;
	; get ptr to the keyboard driver routine
	;
	push	ds
	mov	ax, GDDT_KEYBOARD
	call	GeodeGetDefaultDriver
	mov_tr	bx, ax				; bx <- handle of kbd driver
	call	GeodeInfoDriver			; ds:si <- ptr to struct
	mov	ax, ds:[si][DIS_strategy.segment]
	mov	bx, ds:[si][DIS_strategy.offset]
	mov	ss:[kbdDriver].segment, ax
	mov	ss:[kbdDriver].offset, bx	; save strategy
	pop	ds

	mov	si, ds:[di].VKI_kbsHandle
	mov	si, ds:[si]			; deref kbsHandle lptr
	segmov	es, ds				; es:si = ptr to KeyMapStruct to
						; fill in by KbdMapKey routine
	mov	al, 1 				; al = scan code (1 based)
	mov	di, DR_KBD_MAP_KEY		; di = function to call

keyLoop:
	call	ss:[kbdDriver]			; find what chars on key
	clr	ds:[si].KS_state		; mark not pressed


	test	ds:[si].KS_keys.KMS_keyType, KD_STATE_KEY
	jz	afterState			; branch if not state key

	push	ax, di, es
	mov	cx, length StateKeys
SBCS <	mov	al, ds:[si].KS_keys.KMS_char				>
DBCS <	mov	ax, ds:[si].KS_keys.KMS_char				>
	segmov	es, cs
	mov	di, offset StateKeys
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	jnz	noMatch				; didn't find it?
SBCS <	sub	di, (offset StateKeys)+1				>
DBCS <	sub	di, (offset StateKeys)+2				>
	mov	al, cs:[StateBits][di]		; al = flags
	mov	ds:[si].KS_state, al
noMatch:
	pop	ax, di, es

afterState:
	;
	; copy accentable flag (ignore unreliable accent flag)
	;
	test	ds:[si].KS_keys.KMS_keyType, KD_ACCENTABLE
	jz	afterAccentable
	ornf	ds:[si].KS_state, mask MKS_ACCENTABLE
afterAccentable:
	add	si, size KeyboardStruct		; advance to next
	inc	al
	cmp	al, ss:[layoutLength]
	jbe	keyLoop				; loop while more

	.leave
	ret
KeyboardGetCharacters	endp

if DBCS_PCGEOS
StateKeys	Chars \
	C_SYS_LEFT_SHIFT,
	C_SYS_RIGHT_SHIFT,
	C_SYS_LEFT_CTRL,
	C_SYS_RIGHT_CTRL,
	C_SYS_LEFT_ALT,
	C_SYS_RIGHT_ALT,
	C_SYS_CAPS_LOCK,
	C_SYS_ALT_GR
else
StateKeys	VChar \
	VC_LSHIFT,
	VC_RSHIFT,
	VC_LCTRL,
	VC_RCTRL,
	VC_LALT,
	VC_RALT,
	VC_CAPSLOCK,
	VC_ALT_GR
endif
	
StateBits	MyKeyState \
	(mask MKS_SHIFT),
	(mask MKS_SHIFT),
	(mask MKS_CTRL),
	(mask MKS_CTRL),
	(mask MKS_ALT),
	(mask MKS_ALT),
	(mask MKS_CAPSLOCK),
	(mask MKS_CTRL or mask MKS_ALT)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Message handler for MSG_VIS_DRAW for VisKeyboardClass
CALLED BY:	GLOBAL
PASS:		cl - DrawFlags
		^hbp - GState handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	7/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardVisDraw		method	VisKeyboardClass, MSG_VIS_DRAW
	clr	al
	mov	di, bp
	call	KeyboardRedraw
	ret
KeyboardVisDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw the keyboard when the window is exposed.

CALLED BY:	KeyboardVisDraw

PASS:		*ds:si - VisKeyboardClass
		^hdi - GState
		al - non-zero if we just want to redraw the keys
		     (don't redraw the lines)
RETURN:		none
DESTROYED:	not di, ax, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/89		Initial version
	JT	7/15/92		Modified
	dlitwin	4/29/94		Generalized IKBD/SKBD/ZKBD to allow other KBDs
				Modified to deal with instance data keyboard
				layouts and sizes instead of hardcoded values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardRedraw	proc	near
	class	VisKeyboardClass
objChunk	local	lptr		push	si
justKeys	local	byte
accentInfo	local	word
	uses	di, ax
	.enter

EC <	call	ECCheckVisKbdObj			>
EC <	call	ECCheckGStateHandle			>

	call	GrSaveState
	mov	ss:[justKeys], al

	mov	al, MM_COPY			; al = draw mode
	call	GrSetMixMode

	tst	ss:[justKeys]
	LONG	jnz	drawKeys

;	Setup the GState with 50% patterns if not fully enabled

	call	CheckIfObjectFullyEnabled
	mov	al, SDM_100			; assume enabled
	jnz	gotMask
	mov	al, SDM_50			; if not, grey out
gotMask:
	call	GrSetAreaMask
	call	GrSetLineMask
	call	GrSetTextMask

	;
	; Initialize the GState to draw correctly
	;
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor

	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetLineColor

	;
	; Draw a rough keyboard layout into which the keys will be drawn
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisKeyboard_offset
	call	ds:[bx].VKI_kbdDrawOutlines

drawKeys:
	;
	; Set the key font and point size.
	; Pass:	cx - FontID, dx.ah - point size
	;
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisKeyboard_offset	; deref VisKeyboard to bx
	mov	cx, ds:[bx].VKI_letterFontType
	mov	dx, ds:[bx].VKI_letterFontSize
	clr	ax
	call	GrSetFont

	;
	; Set the area color to black, and the area mask to a 50%
	; pattern, to be used when drawing unavailable keys.
	;
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor			;

	push	di				; preserve GState
	call	VisKeyboardDeref_DSDI
	mov	bx, ds:[di].VKI_kbsHandle
	mov	bx, ds:[bx]			; deref kbsHandle lptr

	mov	ax, ds:[di].VKI_accentInfo
	mov	ss:[accentInfo], ax

	mov	al, ds:[di].VKI_modState

	mov	si, ds:[di].VKI_kbdLayoutOffset
	clr	cx
	mov	cl, ds:[di].VKI_kbdLayoutLength	; cx = # keys to draw
	pop	di				; restore GState

	push	si				; preserve KeyPic offset
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			; dx = font height in pixels
	pop	si				; restore KeyPic offset


	;
	; di		= GSTATE
	; cx		= # keys left to draw
	; al		= Mod State
	; bx		= offset into KeyboardStruct array
	; si		= offset into KeyPic array
	; dx		=  font height
	; ss:[accentInfo]	= accent info
	;
KR_loop:
	tst	cs:[si].KP_exists
	jz	nextKey

EC <	push	si				>
EC <	mov	si, ss:[objChunk]		>
EC <	call	ECCheckKbdPtr			>
EC <	pop	si				>

	push	cx, bp				; preserve stack frame
	mov	cx, ss:[accentInfo]
	mov	ah, ss:[justKeys]
	mov	bp, ss:[objChunk]		; pass VisKeyboard lptr in bp
	call	KeyboardDrawKey
	pop	cx, bp				; restore stack frame
	test	ds:[bx].KS_state, mask MKS_PRESSED
	jz	nextKey				; branch if not pressed

	;
	; Invert the key
	;
	push	bx
	mov	bx, ss:[objChunk]
	call	KeyboardInvertKey		; invert it if pressed
	pop	bx

nextKey:
	add	si, size KeyPic			; si = move to next
	add	bx, size KeyboardStruct		; bx = move to next
	loop	KR_loop

	call	GrRestoreState

	.leave
	ret
KeyboardRedraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfObjectFullyEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the view is fully enabled. If not, draw
		this object in a 50% pattern.

CALLED BY:	KeyboardRedraw

PASS:		ds	- segment of VisKeyboard
		ss:bp	- inherited stack frame from KeyboardRedraw
RETURN:		Zflag	- set if not fully enabled
DESTROYED:	ax

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfObjectFullyEnabled	proc	near
	uses	bx, cx, dx, si, bp, di
	.enter inherit KeyboardRedraw

	mov	ax, MSG_VIS_GET_ATTRS
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			;CX <- classed event
	
	mov	si, ss:[objChunk]
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent
	test	cl, mask VA_FULLY_ENABLED

	.leave
	ret
CheckIfObjectFullyEnabled	endp


if INITFILE_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardDrawInitFileKeyOutlines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outlines of the keys for the initfile keyboard.

CALLED BY:	KeyboardRedraw

PASS:		^hdi	= GState
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardDrawInitFileKeyOutlines	proc	near
	uses	bp, ds
	.enter

	LoadVarSeg	ds, ax
	mov	bp, ds:[floatingKbdSize]
	mov	cl, 4
.assert	(size KeyboardOutline) eq 16
	shl	bp, cl
	add	bp, offset KeyboardOutlines
	mov	ax, cs:[bp].KO_left
	mov	bx, cs:[bp].KO_top
	mov	cx, cs:[bp].KO_right
	mov	dx, cs:[bp].KO_bottom
	call	GrFillRect
	call	GrDrawRect
	mov	bx, cs:[bp].KO_row2Top
	call	GrDrawHLine
	mov	bx, cs:[bp].KO_row3Top
	call	GrDrawHLine
	mov	bx, cs:[bp].KO_row4Top
	call	GrDrawHLine
	mov	bx, cs:[bp].KO_row5Top
	call	GrDrawHLine

	.leave
	ret
KeyboardDrawInitFileKeyOutlines	endp

KeyboardOutline	struct
    KO_left	word
    KO_top	word
    KO_right	word
    KO_bottom	word
    KO_row2Top	word
    KO_row3Top	word
    KO_row4Top	word
    KO_row5Top	word
KeyboardOutline	ends

KeyboardOutlines	KeyboardOutline \
	<STD_LEFT_MARGIN, STD_ROW_1_T, STD_MAIN_RIGHT, STD_ROW_5_B, \
	 STD_ROW_2_T, STD_ROW_3_T, STD_ROW_4_T, STD_ROW_5_T>, \
	<ZOOMER_LEFT_MARGIN, ZOOMER_ROW_1_T, ZOOMER_MAIN_RIGHT, ZOOMER_ROW_5_B,\
	 ZOOMER_ROW_2_T, ZOOMER_ROW_3_T, ZOOMER_ROW_4_T, ZOOMER_ROW_5_T>
endif		; if INITFILE_KEYBOARD


if STANDARD_KEYBOARD or ZOOMER_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardDrawStdOrZmrKeyOutlines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outlines of the keys for the standard or
		Zoomer keyboard.

CALLED BY:	KeyboardRedraw

PASS:		^hdi	= GState
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardDrawStdOrZmrKeyOutlines	proc	near
	.enter

	mov	ax, KEYBOARD_LEFT_MARGIN
	mov	bx, STYLUS_ROW_1_T
	mov	cx, KEYBOARD_MAIN_RIGHT
	mov	dx, KEYBOARD_ROW_5_B
	call	GrFillRect
	call	GrDrawRect
	mov	bx, KEYBOARD_ROW_2_T
	call	GrDrawHLine
	mov	bx, KEYBOARD_ROW_3_T
	call	GrDrawHLine
	mov	bx, KEYBOARD_ROW_4_T
	call	GrDrawHLine
	mov	bx, KEYBOARD_ROW_5_T
	call	GrDrawHLine

	.leave
	ret
KeyboardDrawStdOrZmrKeyOutlines	endp
endif		; if STANDARD_KEYBOARD or ZOOMER_KEYBOARD

if STYLUS_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardDrawStylusKeyOutlines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the outlines of the keys for the stylus keyboard.

CALLED BY:	KeyboardRedraw

PASS:		*ds:si	= VisKeyboardClass object
		^hdi	= GState
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardDrawStylusKeyOutlines	proc	near
	.enter

	mov	ax, STYLUS_LEFT_MARGIN
	mov	bx, STYLUS_ROW_1_T
	mov	cx, STYLUS_RIGHT_MARGIN
	mov	dx, STYLUS_ROW_5_B
	call	GrFillRect
	mov	dx, STYLUS_ROW_1_B
	call	GrDrawRect
	mov	bx, STYLUS_ROW_2_T
	mov	dx, STYLUS_ROW_2_B
	call	GrDrawRect
	mov	bx, STYLUS_ROW_3_T
	mov	dx, STYLUS_ROW_3_B
	call	GrDrawRect
	mov	bx, STYLUS_ROW_4_T
	mov	dx, STYLUS_ROW_4_B
	call	GrDrawRect
	mov	ax, STYLUS_ROW_5_L
	mov	bx, STYLUS_ROW_5_T
	mov	dx, STYLUS_ROW_5_B
	call	GrDrawRect

	call	KeyboardDrawStylusPICGadgets

	.leave
	ret
KeyboardDrawStylusKeyOutlines	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardDrawStylusPICGadgets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the dismiss button and the PenInputControl item groups.

CALLED BY:	KeyboardDrawStylusKeyOutlines

PASS:		*ds:si	= VisKeyboardClass object
		^hdi	= GState
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardDrawStylusPICGadgets	proc	near
	uses	si, ds, bp
	.enter

	pushdw	dssi			 ; preserve our optr

	;
	; Prep by locking down our bitmap resource and setting up our gstate
	;
	mov	bx, handle VisKeymapData
	call	MemLock
	mov	ds, ax
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	mov	ax, STYLUS_LEFT_MARGIN
	mov	bx, STYLUS_ROW_5_B - STYLUS_DISMISS_HEIGHT + 1
	mov	si, offset DismissPict
	mov	cx, STYLUS_DISMISS_WIDTH		; width of key
	call	KeyboardDrawPICGadgetBitmap

	mov	ax, STYLUS_LEFT_MARGIN+STYLUS_PIC_KMP_L
	mov	cx, STYLUS_LEFT_MARGIN+STYLUS_PIC_KMP_L+STYLUS_PIC_KMP_WIDTH*5
	mov	bx, STYLUS_ROW_5_B - STYLUS_PIC_KMP_HEIGHT
	mov	dx, STYLUS_ROW_5_B
	call	GrDrawRect
	dec	ax
	inc	cx
	inc	bx
	dec	dx
	call	GrDrawRect

	dec	bx
	mov	cx, STYLUS_PIC_KMP_WIDTH		; our key width for all
							;   of the items
	mov	si, offset BigKeysPict
	call	KeyboardDrawPICGadgetBitmap

	add	ax, STYLUS_PIC_KMP_WIDTH
	call	GrDrawVLine
	mov	si, offset KeyboardPict
	call	KeyboardDrawPICGadgetBitmap

	add	ax, STYLUS_PIC_KMP_WIDTH
	call	GrDrawVLine
	mov	si, offset NumbersPict
	call	KeyboardDrawPICGadgetBitmap

	add	ax, STYLUS_PIC_KMP_WIDTH
	call	GrDrawVLine
	mov	si, offset PunctuationPict
	call	KeyboardDrawPICGadgetBitmap

	add	ax, STYLUS_PIC_KMP_WIDTH
	call	GrDrawVLine
	mov	bp, ds				; save gstring chunk's segment
	mov	dx, ax				; save our X coordinate

	;
	; Check our vardata to see if the HWRGrid should be drawn
	; greyed out or not.
	;
	mov	ax, ATTR_VIS_KEYBOARD_NO_HWR_GRID
	popdw	dssi				; restore our optr
	push	bx
	call	ObjVarFindData
	pop	bx
	pushf					; save this flag for after draw
	jnc	skipSetingGrey

	mov	al, SDM_50
	call	GrSetAreaMask
	call	GrSetLineMask
	call	GrSetTextMask

skipSetingGrey:
	mov	ax, dx				; restore our X coordinate
	mov	ds, bp				; restore gstring chunk's seg.
	mov	si, offset HWRGridPict
	call	KeyboardDrawPICGadgetBitmap

	popf
	jnc	skipUnsettingGrey

	mov	al, SDM_100
	call	GrSetAreaMask
	call	GrSetLineMask
	call	GrSetTextMask

	;
	; Invert our item group.
	;
skipUnsettingGrey:
	mov	al, MM_INVERT
	call	GrSetMixMode
	mov	ax, STYLUS_LEFT_MARGIN+STYLUS_PIC_KMP_L+STYLUS_PIC_KMP_WIDTH*1
	mov	bx, STYLUS_ROW_5_B - STYLUS_PIC_KMP_HEIGHT + 2
	mov	cx, STYLUS_LEFT_MARGIN+STYLUS_PIC_KMP_L+STYLUS_PIC_KMP_WIDTH*2
	mov	dx, STYLUS_ROW_5_B - 1
	call	GrFillRect
	mov	al, MM_COPY
	call	GrSetMixMode

	;
	; Clean up
	;
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	mov	bx, handle VisKeymapData
	call	MemUnlock

	.leave
	ret
KeyboardDrawStylusPICGadgets	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardDrawPICGadgetBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bitmap for one of the items or the dismiss trigger.

CALLED BY:	KeyboardDrawStylusPICGadgets

PASS:		ds:si	= chunk of bitmap to draw
		^hdi	= GState
		ax, bx	= coordinates of bitmap to draw
		cx	= width of key
RETURN:		nothing
DESTROYED:	si

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardDrawPICGadgetBitmap	proc	near
	uses	ax, bx, cx, dx
	.enter

	mov	si, ds:[si]			; dereference chunk

	sub	cx, ds:[si].B_width
	inc	cx				; round up
	sar	cx
	add	ax, cx

	mov	cx, STYLUS_PIC_KMP_HEIGHT
	sub	cx, ds:[si].B_height
	inc	cx				; round up
	sar	cx
	add	bx, cx

	clr	dx				; no callback needed
	call	GrFillBitmap

	.leave
	ret
KeyboardDrawPICGadgetBitmap	endp


endif		; if STYLUS_KEYBOARD



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardDrawKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	(re)draw one key

CALLED BY:	KeyboardRedraw

PASS:		di - handle of gstate
		si - offset into KeyPic array (KeyboardLayout)
		bx - offset into keyboard char table (KeyboardStruct)
		al - mod state
		ah - non-zero if we just want to draw the keys, not the lines
		dx - font height
		cx - accent info
		bp - VisKeyboard object lptr
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/89		Initial version
	JT	7/15/92		Modified
	dlitwin	4/29/94		Broke out ending to KeyboardDrawVirtualChar
				modified to pass in VisKeyboard lptr for
				KeyboardDrawVirtualChar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardDrawKey	proc	near
objChunk	local	lptr			push	bp
accentInfo	local	word			push	cx
fontHeight	local	word			push	dx
keyStructPtr	local	nptr.KeyboardStruct	push	bx
keyPicPtr	local	nptr.KeyPic		push	si
modState	local	MyKeyState
drawKeyOnly	local	byte
keyWidth	local	word
	ForceRef keyWidth		; used in KeyboardDrawVirtualChar
	uses	ax, bx, cx, dx, ds, si, es
	.enter

EC <	call	ECCheckGStateHandle			>

EC <	test	al, not (mask MyKeyState)		>
EC <	ERROR_NZ	ILLEGAL_KBD_MOD_STATE		>

	mov	ss:[modState], al
	mov	ss:[drawKeyOnly], ah
	mov	bx, ss:[objChunk]
	call	GetKeyBounds
	
	tst	ss:[drawKeyOnly]
	jz	drawNormal

	;
	; We are just drawing the insides of the keys (this happens
	; when the user clicks on the shift key). If so, white out
	; the key bounds first.
	;
	push	bp				; preserve our frame pointer
	xchg	ax, bp
	mov	ax, GMT_ENUM
	call	GrGetAreaMask
	push	ax				; preserve old area mask
	xchg	ax, bp

	push	ax				; preserve x value
	mov	al, SDM_100
	call	GrSetAreaMask
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	pop	ax				; restore x value

	inc	ax
	inc	bx
	call	GrFillRect

	pop	ax				; restore old area mask
	call	GrSetAreaMask			; BLACK/50% for use below.
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor
	pop	bp				; restore our frame pointer
	jmp	drawInsides

drawNormal:
	call	GrDrawVLine

drawInsides:
	mov	al, ss:[modState]
	mov	si, ss:[keyStructPtr]
	mov	dx, ss:[accentInfo]		; dx = accent info
	mov	cx, ss:[objChunk]
	call	FindCharWithMods		; find character based on mods
	jc	isVirtual			; ax = char, dx = CharFlags
						; branch if virtual char
	;
	; Check if this is a non-virtual character that we want to treat like
	; a virtual character by drawing a special char in it.
	;
	push	di
	mov	cx, length SpecialChars
	segmov	es, cs
	mov	di, offset SpecialChars
	repne	scasb
	pop	di
	je	isVirtual

	mov	si, ss:[keyPicPtr]

	push	ax, cx, di			; save char, accent, gstate
	call	GrCharWidth			; dx.ah <- width
	mov	di, dx				; di holds width
	mov	bx, ss:[objChunk]
	call	GetKeyBounds

	sub	cx, ax
	sub	cx, di
	inc	cx				; round up
	sar	cx, 1				; split the difference
	add	ax, cx				; centered width

	sub	dx, bx
	sub	dx, ss:[fontHeight]		; ex = left over
	inc	dx				; round up, not down
	sar	dx, 1				; split the difference
	add	bx, dx
	pop	dx, cx, di			; restore char, accent, gstate
	call	GrDrawChar

done: 	
	.leave 	
	ret				; <--- RETURN HERE

isVirtual:
	call	KeyboardDrawVirtualChar
	jmp	done
KeyboardDrawKey	endp 



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardDrawVirtualChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We have determined the key to be a virtual or special key,
		and will draw a string instead of a single letter.

CALLED BY:	KeyboardDrawKey

PASS:		ax	= char value
		^hdi	= GState
		ds	= objblock (locked down) of VisKeyboardClass object
		ss:bp	= stack frame inherited from KeyboardDrawKey
RETURN:		nothing
DESTROYED:	ax, bx,cx, dx, ds, si, es

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/29/94    	Broken out from KeyboardDrawKey, modified
				to handle different fonts for letter and
				word keys, defined in instance data.
	PT	06/20/96	Made DBCS changes.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardDrawVirtualChar	proc	near
	.enter inherit KeyboardDrawKey

	;
	; We can't clear the upper byte for DBCS in order for us to 
	; make valid comparisons.
	; 6/19/96 - ptrinh
	;
SBCS <	clr	ah				; get rid of the	>
						; CS_CONTROL part of
						; the char
	push	ax				; ax = char to draw
	mov	si, ss:[keyPicPtr]
	mov	bx, ss:[objChunk]
	call	GetKeyBounds
	pop	si				; si = char to draw

SBCS <	cmp	si, VC_NULL						>
DBCS <	cmp	si, C_SYS_NULL						>
	jne	invalidKeyCheck

noKeyMap:
	mov	si, ax				; preserve x value in si
	mov	ax, GMT_ENUM
	call	GrGetAreaMask
	push	ax				; preserve old area mask
	mov	al, SDM_50
	call	GrSetAreaMask
	mov	ax, si				; restore x value
	call	GrFillRect
	pop	ax				; restore old area mask
	call	GrSetAreaMask
	jmp	done

invalidKeyCheck:
SBCS <	cmp	si, VC_INVALID_KEY					>
DBCS <	cmp	si, C_SYS_INVALID_KEY					>
	jz	noKeyMap

if STYLUS_KEYBOARD
SBCS <	cmp	si, VC_BACKSPACE					>
DBCS <	cmp	si, C_SYS_BACKSPACE					>
	jne	notDel

	call	StylusKeyboardDrawDeleteBitmap
	jmp	done

notDel:
endif

	sub	dx, bx				; dx = height of key
	sub	cx, ax
	mov	ss:[keyWidth], cx

	push	ax, bx			; preserve upper corner of key
	push	di			; preserve GState

	;
	; If this is a virtual character, find out what string to use for it
	;
	mov_tr	ax, si				; ax = char to look for
 	mov	cx, length VirtualChars 	
	segmov	es, cs 	
	mov	di, offset VirtualChars
	repne	scasb 	
	jne	notVirtual
	sub	di, offset VirtualChars+1
	shl	di, 1 	
	mov	di, cs:[VirtualStringTable][di]	; di = chunk handle of string
	jmp	common

	;
	; If this is a special char (non-virtual) figure out what
	; string to use for it.
	;
notVirtual:
 	mov	cx, length SpecialChars
	segmov	es, cs 	
	mov	di, offset SpecialChars
	repne	scasb 	
EC <	ERROR_NZ	CHAR_NOT_SUPPORTED				>
   	sub	di, offset SpecialChars+1
	shl	di, 1
	mov	di, cs:[SpecialCharTable][di]

common:
	mov	bx, handle GenPenInputControlToolboxUI 	
	segmov	es, ds, ax			; save our objblock in es
	call	MemLock
	mov	ds, ax
	mov	si, ds:[di]			; ds:si = string to display
						;  in virtual key
	pop	di				; restore GState

	;
	; If the font or size of the letters drawn on the keyboard is
	; different than the size of the words draw on the keyboard, we
	; will want to switch to the word font and size and then
	; switch back when we are done drawing it.
	;
	mov	bx, ss:[objChunk]
	mov	bx, es:[bx]
	add	bx, es:[bx].VisKeyboard_offset	; deref VisKeyboard object
	mov	cx, es:[bx].VKI_wordFontType
	mov	dx, es:[bx].VKI_wordFontSize
	cmp	cx, es:[bx].VKI_letterFontType
	jne	setNewFontAndSize		; Different font, so set.
	cmp	dx, es:[bx].VKI_letterFontSize
	jne	setNewFontAndSize		; Different size, so set.
	clr	dx				; Same size and font, so we
	jmp	skipSet				;  don't have to change it
setNewFontAndSize:
	clr	ax				; dx.ah is font size
	call	GrSetFont

	;	
	; Center string in key, vertically and horizontally
	;
skipSet:
	mov	cx, es:[bx].VKI_keyHeight

	;
	; Get cached fontHeight if we haven't changed fonts, get new
	; fontHeight if we have
	;
	tst	dx				; clr if font didn't change
	mov	dx, ss:[fontHeight]
	jz	gotHeight			; default to same height

	push	si
	mov	si, GFMI_HEIGHT or GFMI_ROUNDED
	call	GrFontMetrics			; dx = font height in pixels
	pop	si

gotHeight:
	pop	ax, bx				; restore upper corner of key
	inc	ax
	sub	cx, dx
	js	doWidth

	inc	cx				; round up
	sar	cx, 1 	
	add	bx, cx 

doWidth:
	ChunkSizePtr	ds, si, cx		;CX <- length of string
	dec	cx
	call	GrTextWidth			;DX <- Width of string
	sub	ss:[keyWidth], dx
	js	doDrawVirtualKey

	sar	ss:[keyWidth], 1
	add	ax, ss:[keyWidth]
	
doDrawVirtualKey: 	
	call	GrDrawText
	mov	bx, handle GenPenInputControlToolboxUI 	
	call	MemUnlock

	;
	; restore the key font and size, if they were set
	;
	mov	bx, ss:[objChunk]
	mov	bx, es:[bx]
	add	bx, es:[bx].VisKeyboard_offset	; deref VisKeyboard object
	mov	cx, es:[bx].VKI_letterFontType
	mov	dx, es:[bx].VKI_letterFontSize
	cmp	cx, es:[bx].VKI_wordFontType
	jne	unsetNewFontAndSize		; different font, so set
	cmp	dx, es:[bx].VKI_wordFontSize
	je	done				;  don't have to change it
unsetNewFontAndSize:
	clr	ax				; dx.ah is font size
	call	GrSetFont

done:
	.leave
	ret
KeyboardDrawVirtualChar	endp

if DBCS_PCGEOS
VirtualChars	Chars \
		C_SYS_BACKSPACE,
		C_SYS_DELETE,
		C_SYS_TAB,
		C_SYS_ENTER,
		C_SYS_LEFT_SHIFT,
		C_SYS_RIGHT_SHIFT,
		C_SYS_LEFT_CTRL,
		C_SYS_RIGHT_CTRL,
		C_SYS_LEFT_ALT,
		C_SYS_RIGHT_ALT, 
		C_SYS_ALT_GR,
		C_SYS_CAPS_LOCK
else
VirtualChars	VChar	VC_BACKSPACE, VC_DEL, VC_TAB, VC_ENTER,
		VC_LSHIFT, VC_RSHIFT, VC_LCTRL, VC_RCTRL, VC_LALT, VC_RALT, 
		VC_ALT_GR, VC_CAPSLOCK
endif

VirtualStringTable	lptr \
	String_BS,
	String_DEL,
	String_TAB,
	String_ENTER,
	String_LSHIFT,
	String_RSHIFT,
	String_LCTRL,
	String_RCTRL,
	String_ALT,
	String_ALT,
	String_ALT_GR,
	String_CAPSLOCK

.assert	(length VirtualStringTable) eq (length VirtualChars)

if DBCS_PCGEOS
SpecialChars	Chars	C_SPACE, C_THIN_SPACE, C_EN_SPACE, C_EM_SPACE, 
			C_NON_BREAKING_SPACE, C_SOFT_HYPHEN
else
SpecialChars	Chars	C_SPACE, C_THINSPACE, C_ENSPACE, C_EMSPACE, 
			C_NONBRKSPACE, C_OPTHYPHEN
endif

SpecialCharTable	lptr	\
	String_SPACE,
	String_THINSPACE,
	String_ENSPACE,
	String_EMSPACE,
	String_NONBRKSPACE,
	String_OPTHYPHEN

.assert (length SpecialChars) eq (length SpecialCharTable)
		


if STYLUS_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StylusKeyboardDrawDeleteBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the delete bitmap defined for Stylus

CALLED BY:	KeyboardDrawVirtualChar

PASS:		^hdi	= GState
		ds	= objblock (locked down) of VisKeyboardClass object
		ss:bp	= stack frame inherited from KeyboardDrawKey
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StylusKeyboardDrawDeleteBitmap	proc	near
	uses	ax, bx, cx, dx, bp, si, ds, es
	.enter	inherit KeyboardDrawKey

	;
	; Make sure we will fill with the right color
	;
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	;
	; Lock down the VisKeymapData resource, where the bitmap resides
	;
	segmov	es, ds, ax
	mov	bx, handle VisKeymapData
	call	MemLock
	mov	ds, ax

	mov	bp, ss:[keyPicPtr]			; es:bp is our KeyPic

	mov	si, offset BackspaceBitmap
	mov	si, ds:[si]				; ds:si is our Bitmap

	;
	; Get starting height by centering our bitmap in our key
	;
	mov	bx, cs:[bp].KP_bottom		; bottom
	sub	bx, cs:[bp].KP_top		; bottom - top
	sub	bx, ds:[si].B_height		; bottom - top - height
	inc	bx				; round up
	sar	bx, 1				; (b - t - h)/2
	add	bx, cs:[bp].KP_top		; t + (b - t - h)/2

	;
	; Get starting width by centering our bitmap in our key
	; 
	mov	ax, cs:[bp].KP_right		; right
	sub	ax, cs:[bp].KP_left		; right - left
	sub	ax, ds:[si].B_width		; right - left - width
	inc	ax				; round up
	sar	ax, 1				; (r - l - w)/2
	add	ax, cs:[bp].KP_left		; l + (r - l - w)/2

	;
	; ax, bx, is our starting position, ds:si is our bitmap and
	; we won't be needing a call back
	;
	clr	dx
	call	GrFillBitmap

	mov	bx, handle VisKeymapData	; clean up after ourselves
	call	MemUnlock

	.leave
	ret
StylusKeyboardDrawDeleteBitmap	endp

endif		; if STYLUS_KEYBOARD



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardMouseStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a mouse press, converting to a key press.

CALLED BY:	InputMonitor()

PASS:		*ds:si	= VisKeyboard object
		es	= dgroup
		cx	= X position of mouse, in document coordinates of
			  receiving object
		dx	= X position of mouse, in document coordinates of
			  receiving object
RETURN:		if key was "pressed": 		
			di	= MSG_META_KBD_CHAR
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high	= scan code
DESTROYED:	none 
PSEUDO CODE/STRATEGY: 	
		To allow the Keycaps application to function as a keyboard,
	 	it intercepts mouse presses and converts them to key presses if
		they fall inside the window and on the image of a particular
	 	key. It does this by finding the scan code and current 
		modifiers and from that finding the character value that is 
		currently displayed on the key. This information together 
		comprises the data for a MSG_META_KBD_CHAR, which replaces 
		the mouse press data in the input stream, and the rest of the 
		system is none the wiser...  

KNOWN BUGS/SIDE EFFECTS/IDEAS: 
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		eca	7/16/90		Initial version
		JT	7/15/92		Modified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardMouseStartSelect	method	VisKeyboardClass,
				MSG_META_START_SELECT 	
	uses	bx, ds 	
	.enter 	

if STYLUS_KEYBOARD
	call	StylusKeyboardCheckForPICGadgetClick
	jc	done
endif
	mov_tr	ax, cx
	mov	bx, dx 				;find which key was "pressed"
	call	FindScancode			;branch if not a key
	jc	done

	;
	;  Keyboard key-click sound

if KEY_CLICK_SOUNDS
	mov	ax, SST_KEY_CLICK		;
	call	UserStandardSound		;
endif

	call	KeyboardGetGState

if STYLUS_KEYBOARD
	call	StylusCheckForSymIntScanCode
	jc	done
endif
	call	KeyboardPress 	

	test	dl, mask CF_STATE_KEY		;Don't output any keyboard
	jnz	done				; chars for state key changes

	push	si				; save self lptr
	clr	bx				; currect process
	call	GeodeGetAppObject		; ^lbx:si = app object
	mov	ax, MSG_META_KBD_CHAR
	call	KBD_ObjMessageFixupDS

	; check if there is any pending MSG_META_START_SELECT (for any object)
	;   in the event queue.  If so, don't sleep.
	push	es
	segmov	es, dgroup, ax
	clr	es:[foundStartSelectMsg]	; reset flag
	pop	es
	mov	ax, MSG_META_START_SELECT
	mov	di, offset KBD_CheckDuplicateCB
	pushdw	csdi
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE \
			or mask MF_CUSTOM or mask MF_DISCARD_IF_NO_MATCH \
			or mask MF_MATCH_ALL or mask MF_FIXUP_DS
	call	ObjMessage
	push	es
	segmov	es, dgroup, ax
	tst	es:[foundStartSelectMsg]
	pop	es
	jnz	noSleep

	mov	ax, 10				;Pause for 1/6 second
	call	TimerSleep 	

noSleep:
	ornf	dl, mask CF_RELEASE 	
	andnf	dl, not mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
						;Added 4/12/93 cbh

	mov	ax, MSG_META_KBD_CHAR 	
	call	KBD_ObjMessageFixupDS 	
	pop	si				; *ds:si = self

	call	KeyboardGetGState		;Uninvert the chars
	call	KeyboardPress 
done: 	
	mov	ax, mask MRF_PROCESSED 	
	.leave
	ret 
KeyboardMouseStartSelect	endp 

KBD_ObjMessageFixupDS	proc	near
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret		
KBD_ObjMessageFixupDS	endp


if STYLUS_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StylusCheckForSymIntScanCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we pressed either the Symbol or International keys,
		set our extraState bits appropriately and redraw.

CALLED BY:	KeyboardMouseStartSelect

PASS:		*ds:si	= VisKeyboardClass object
		^hdi	= GState
		bp high	= scan code
RETURN:		carry	= set if it was sym or int
				all regs destroyed
			= clear if not
				no regs destroyed
DESTROYED:	see "Return:"

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StylusCheckForSymIntScanCode	proc	near
	.enter

	mov	bx, ds:[si]
	add	bx, ds:[bx].VisKeyboard_offset

	mov	ax, bp
	cmp	ah, STYLUS_SYMBOL_SCANCODE
	jne	notSymbol

	;
	; Toggle Symbol and turn off Internat'l, because only one of
	; these can be on at once.
	;
	xor	ds:[bx].VKI_extraState, mask VKESB_SYMBOL
	andnf	ds:[bx].VKI_extraState, not (mask VKESB_INTERNATIONAL)
	mov	dx, (STYLUS_INTERNATIONAL_SCANCODE-1)*(size KeyboardStruct)
	jmp	commonStateChange

notSymbol:
	cmp	ah, STYLUS_INTERNATIONAL_SCANCODE
	clc
	jne	exit

	;
	; Toggle Internat'l and turn off Symbol, because only one of
	; these can be on at once.
	;
	xor	ds:[bx].VKI_extraState, mask VKESB_INTERNATIONAL
	andnf	ds:[bx].VKI_extraState, not (mask VKESB_SYMBOL)
	mov	dx, (STYLUS_SYMBOL_SCANCODE-1)*(size KeyboardStruct)

	;
	; ah is scancode to toggle (needs to be decremented to index into table)
	; dx is index to turn off (already multiplied by structure size)
	;
commonStateChange:
	dec	ah				; table is zero based
	mov	al, size KeyboardStruct
	mul	ah
	mov	bx, ds:[bx].VKI_kbsHandle
	mov	bx, ds:[bx]			; beginning of table
	mov	cx, bx				; save beginning of table
	add	bx, ax				;  add our offset
	xor	ds:[bx].KS_state, mask MKS_PRESSED

	mov	bx, cx				; beginning of table
	add	bx, dx				;  add precalculated offset
	andnf	ds:[bx].KS_state, not (mask MKS_PRESSED)

	mov	al, -1				; letters only
	call	KeyboardRedraw
	stc

exit:
	.leave
	ret
StylusCheckForSymIntScanCode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StylusKeyboardCheckForPICGadgetClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if this might be a click to dismiss the
		keyboard or to change to another of the keyboards.

CALLED BY:	KeyboardMouseStartSelect

PASS:		*ds:si	= VisKeyboardClass object
		(cx,dx)	= position of mouse in window
RETURN:		carry	= set if this was in our bounds
			= clear if out of our bounds

DESTROYED:	carry	= set:	All destroyed
			= clear: nothing destroyed

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StylusKeyboardCheckForPICGadgetClick	proc	near
	.enter

	;
	; If they aren't below the fourth row, they aren't close
	; If this click registered they must be above the bottom.
	;
	cmp	dx, STYLUS_ROW_5_B - STYLUS_DISMISS_HEIGHT
	jl	notInGadgetArea

	cmp	cx, STYLUS_LEFT_MARGIN + STYLUS_DISMISS_WIDTH
	jg	notDismiss

	;
	; They hit the dismiss key, so toggle the floating keyboard off
	;
	mov	ax, SST_KEY_CLICK
	call	UserStandardSound
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_APPLICATION_TOGGLE_FLOATING_KEYBOARD
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	stc
	jmp	exit

	;
	; If they aren't to the left of the last item, they aren't close
	;
notDismiss:
	cmp	cx, STYLUS_LEFT_MARGIN + STYLUS_PIC_KMP_L + \
						STYLUS_PIC_KMP_WIDTH*5
	jg	notInGadgetArea

	cmp	cx, STYLUS_LEFT_MARGIN + STYLUS_PIC_KMP_L + 1
	jl	notInGadgetArea

	;
	; OK, they are in the item group area, divide their x position
	; to get which one they clicked on
	;
	sub	cx, STYLUS_LEFT_MARGIN + STYLUS_PIC_KMP_L + 1
	mov	ax, cx
	mov	cx, STYLUS_PIC_KMP_WIDTH
	div	cl				; al is our PIDT
	clr	bx				; ensure that bh is zero
	mov	bl, al
	shl	bx, 1				; index into a word table

	mov	cx, cs:[checkForPIDTClick][bx]	; get our PIDT

	cmp	cx, PIDT_HWR_ENTRY_AREA
	jne	afterHWRCheck

	;
	; if we are to ignore the HWRGrid, pretend like they clicked out
	; of our bounds.
	;
	mov	ax, ATTR_VIS_KEYBOARD_NO_HWR_GRID
	call	ObjVarFindData
	jc	notInGadgetArea

afterHWRCheck:
	mov	ax, MSG_GEN_PEN_INPUT_CONTROL_SET_DISPLAY
	push	si
	mov	bx, segment GenPenInputControlClass
	mov	si, offset GenPenInputControlClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

if KEY_CLICK_SOUNDS
	mov	ax, SST_KEY_CLICK		;
	call	UserStandardSound		;
endif

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	cx, di
	mov	dx, TO_OBJ_BLOCK_OUTPUT
	call	ObjCallInstanceNoLock
	stc
	jmp	exit

notInGadgetArea:
	clc

exit:
	.leave
	ret
StylusKeyboardCheckForPICGadgetClick	endp

checkForPIDTClick	word	\
	PIDT_BIG_KEYS,
	PIDT_KEYBOARD,
	PIDT_NUMBERS,
	PIDT_PUNCTUATION,
	PIDT_HWR_ENTRY_AREA

endif		; if STYLUS_KEYBOARD




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KBD_CheckDuplicateCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to check for MSG_META_START_SELECT in queue.

CALLED BY:	INTERNAL, KeyboardMouseStartSelect (via ObjMessage)

	It looks like callback routines for MF_CUSTOM have the following
	parameters: (AY 5/24/94)

	PASS:	ds:bx	= HandleEvent of an event already on queue
		ax	= message of the new event
		cx,dx,bp = data in the new event
		si	= lptr of destination of new event
	RETURN:	bp	= new value to be passed in bp in new event
		di	= one of the PROC_SE_* values
	CAN DESTROY:	si

SIDE EFFECTS:	foundStartSelectMsg modified

PSEUDO CODE/STRATEGY:
	Speed is more important than code size.  Optimize the not-match case.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KBD_CheckDuplicateCB	proc	far
	.enter

	cmp	ds:[bx].HE_method, ax	; see if MSG_META_START_SELECT
	je	found
CheckHack <PROC_SE_CONTINUE eq 0>
	clr	di			; di = PROC_SE_CONTINUE
	ret
found:
	mov	si, es			; preserve es (faster than "uses es")
	segmov	es, dgroup, di
	mov	es:[foundStartSelectMsg], BB_TRUE
	mov	es, si			; restore es
	mov	di, PROC_SE_EXIT

	.leave
	ret
KBD_CheckDuplicateCB	endp

 
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindScancode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find key that mouse press is on, if any.

CALLED BY:	KeyboardMouseStartSelect

PASS:		(ax,bx) - position of mouse in window
		*ds:si - VisKeyboardClass
RETURN:		carry	= set if the mouse press wasn't on a key
			= clear:
			cx - character value
			dl - CharFlags
			dh - ShiftState
			bp low - ToggleState (always 0, as it happens...)
			bp high - scan code of key
DESTROYED:	ax, bx, di 

PSEUDO CODE/STRATEGY: 
KNOWN BUGS/SIDE EFFECTS/IDEAS: 
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/16/90		Initial version
	JT	7/15/92		Modified
	dlitwin	4/30/94		Fixed up to use VKI_layout... instead of 
				hardcoded offsets

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindScancode	proc	near
	class	VisKeyboardClass
mouseX		local	word		push	ax
mouseY		local	word		push	bx
objChunk	local	word		push	si
modState	local	byte
accentInfo	local	word
toggleAndScan	local	word
	.enter

EC <	call	ECCheckVisKbdObj			>

	push	si				; save VisKeyboard lptr
	call	VisKeyboardDeref_DSDI
	mov	al, ds:[di].VKI_modState
	mov	ss:[modState], al
	mov	ax, ds:[di].VKI_accentInfo
	mov	ss:[accentInfo], ax
	mov	si, ds:[di].VKI_kbsHandle
	mov	si, ds:[si]			; deref KeyboardStruct lptr
	mov	cl, ds:[di].VKI_kbdLayoutLength
	mov	di, ds:[di].VKI_kbdLayoutOffset

	mov	ch, 1				; ch <- scan code

scanLoop:
	push	cx, si
	tst	cs:[di].KP_exists
	jz	nextKey

	mov	si, di
	mov	bx, ss:[objChunk]
	call	GetKeyBounds

	cmp	ss:[mouseX], ax
	jl	nextKey
	cmp	ss:[mouseX], cx
	jg	nextKey
	cmp	ss:[mouseY], bx
	jl	nextKey
	cmp	ss:[mouseY], dx
	jle	foundKey

nextKey:
	pop	cx, si
	add	di, size KeyPic			; di = ptr to next KeyPic
	add	si, size KeyboardStruct		; si =ptr to next KeyboardStruct
	inc	ch				; ch = next scan code
	cmp	ch, cl				; checked everything?
	jle	scanLoop			; branch while more keys

	stc					; indicate not found
	pop	si				; fixup stack (VisKeyboard lptr)
	jmp	done

foundKey:
	pop	cx, si
	clr	cl
	mov	ss:[toggleAndScan], cx		; high byte is the scan code
	mov	al, ss:[modState]
	mov	dx, ss:[accentInfo]
	mov	cx, ss:[objChunk]
	call	FindCharWithMods		; find character
	xchg	ax, cx				; ax gets new accent info
						; cx gets character value
	ornf	dl, mask CF_FIRST_PRESS		; dl <- CharFlags

	pop	si				; restore VisKeyboard lptr
EC <	call	ECCheckVisKbdObj			>

	call	VisKeyboardDeref_DSDI
	cmp	ax, ds:[di].VKI_accentInfo
	je	noAccentChange			; no redraw needed

	mov	ds:[di].VKI_accentInfo, ax	; set new accent info
	ornf	ds:[di].VKI_modState, mask MKS_ACCENT_CHANGE

noAccentChange:
	clc					; indicate found

done:
	mov	ax, ss:[toggleAndScan]

	.leave
	mov	bp, ax				; pass out ToggleState and
	ret					;  scan code in bp
FindScancode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCharWithMods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find character on key, based on current modifiers

CALLED BY:	KeyboardDrawKey(), FindScancode()

PASS:
		al	= current modifiers
		ds:si	= ptr to KeyboardStruct for key
		dx	= accent info
		*ds:cx	= VisKeyboardClass object
RETURN:		carry	= set if virtual character, clear otherwise
		ax	= character
		cx	= new accent info
		dl	= CharFlags (CF_EXTENDED, CF_TEMP_ACCENT valid)
		dh	= ShiftState
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Need to deal with CF_EXTENDED when Keycaps supports extended
	keyboard maps.
	If the character with the specified modifiers does not exist,
	then the modifiers should be added to the ShiftState and
	removed from the internal state until a character is found.
	(eg. <ctrl>-<shift>-f should return <ctrl>-F, not nothing)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/16/90		Initial version
	JT	7/15/92		Modified
	dlitwin	5/21/94		added support for Stylus Symbol and
				 Internat'l keys
	PT	06/20/96	Made DBCS changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCharWithMods	proc	near
	uses	bx
accentInfo	local	word	push	dx
	.enter

if STYLUS_KEYBOARD
	call	StylusCheckSymbolOrInternational
	jnz	exit
endif

EC <	test	al, not (mask MyKeyState)		;>
EC <	ERROR_NZ	ILLEGAL_KBD_MOD_STATE		;>

	mov	bl, al
	andnf	bl, (mask MKS_SHIFT or mask MKS_CTRL or mask MKS_ALT)

	test	bl, (mask MKS_CTRL) or (mask MKS_ALT)
	jnz	noCapsLock			;don't flip extendeds
	mov	ah, ds:[si].KS_keys.KMS_keyType
	and	ah, (mask KDF_TYPE)		;keep only type bits

	test	al, mask MKS_CAPSLOCK
	jz	noCapsLock			;branch if no CAPSLOCK
	cmp	ah, KEY_ALPHA
	jne	noCapsLock			;not on alphabetic key
	xor	bl, mask MKS_SHIFT		;CAPSLOCK toggles shift
noCapsLock:

SBCS <	mov	ah, CS_BSW			;ah <- assume printable char >
	clr	bh				;bx <- modifiers
	mov	cl, cs:bitTable[bx]		;al <- corresponding mask
SBCS <	mov	al, ds:[si].KS_keys.KMS_char[bx]			>
DBCS <	mov	ax, ds:[si].KS_keys.KMS_char[bx]			>
	;
	; Set the CharFlags for the keypress, including
	; statehood, and extended/non-extended.
	;
;
;	Now, a hack - we don't want to allow any shifted, etc versions of
;	the del key, so ignore them.
;
	tst	bx
	jz	noModifiers
;	cmp	ds:[si].KS_keys.KMS_char, VC_DEL
;ack!, this will ignore C_LU_DIERESIS also -- brianc 9/9/93
SBCS <	cmp	ds:[si].KS_keys.KMS_ctrlAlt, VC_SYSTEMRESET		>
DBCS <	cmp	ds:[si].KS_keys.KMS_ctrlAlt, C_SYS_SYSTEM_RESET		>
	jne	noModifiers

SBCS <	clr	al							>
DBCS <	clr	ax							>
	clr	dx				;CharFlags, ShiftState
	jmp	isVirtual
	
noModifiers:
	clr	dx				;dl <- CharFlags
	test	ds:[si].KS_state, MKS_STATE_KEY
	jz	notStateKey
	ornf	dl, mask CF_STATE_KEY		;mark as a state key

	LocalIsNull ax				;Mark the key as virtual if
SBCS <	mov	al, ds:[si].KS_keys.KMS_char	; it used to be null. >
DBCS <	mov	ax, ds:[si].KS_keys.KMS_char	; it used to be null. >
	jz	isVirtual

	;
	; If the character is missing or is marked as
	; virtual, set the character set to CS_CONTROL.
	;
notStateKey:
	LocalIsNull ax				;see if character missing
	jz	isVirtual			;mark as virtual if missing
SBCS <	test	ds:[si].KS_keys.KMS_virtual, cl				>
SBCS <	jz	notVirtual			;branch if not virtual 	>
						; (carry clear)
isVirtual:
SBCS <	mov	ah, CS_CONTROL			;ah <- virtual character >
DBCS <	mov	ax, C_NOT_A_CHARACTER					>
	stc					;indicate virtual

	;
	; deal with accents and accentables
	;
notVirtual:
	mov	cx, ss:[accentInfo]
	call	AccentTranslation
exit::			; double colon b/c its not worth an "if STYLUS_KEYBOARD"
	.leave
	ret
FindCharWithMods	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AccentTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle accent

CALLED BY:	INTERNAL
			FindCharWithMods

PASS:		ds:si - KeyboardStruct for key
		ax - character
		dl - CharFlags (CF_EXTENDED, CF_TEMP_ACCENT valid)
		dh - ShiftState
		cx - accent info
		carry - set if virtual character

RETURN:		ax - character (updated)
		dl - CharFlags (CF_EXTENDED, CF_TEMP_ACCENT valid) (updated)
		dh - ShiftState
		cx - accent info (updated)
		carry - set if virtual character

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/18/93		adapted from keyboard driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AccentTranslation	proc	near
	uses	bx
	.enter
	;
	; al = char value
	; ah = CharSet
	; cl = pending accent
	; ch = accent table offset (if pending accent)
	; dl = CharFlags
	;
	pushf					;save "virtual" flag
	tst	cl				;see if pending accent
	jz	AT_SeeIfAccent			;branch if none pending
	;
	; XXX: bail if virtual char?
	;
	test	dl, mask CF_STATE_KEY		;state key?
	jnz	exit				;yes, exit w/o clearing
						;	pending accent
	test	ds:[si].KS_state, mask MKS_ACCENTABLE
	jz	AT_80				;branch if not accentable
	cmp	al, cl				;see if accent hit twice
	je	AT_80				;branch if two accents
	clr	bx
	mov	cl, NUM_ACCENTABLES		;cl <- # entries to check
AT_30:
SBCS <	cmp	cs:[KbdAccentables][bx], al				>
DBCS <	cmp	cs:[KbdAccentables][bx], ax				>
	je	AT_40				;branch if a match
	inc	bx
DBCS <	inc	bx							>
	dec	cl
	jnz	AT_30				;loop to check all entries
	jz	AT_80				;if not found, quit
AT_40:
	shl	bx, 1				;*8
	shl	bx, 1
	shl	bx, 1				;bx <- offset of entry
	mov	cl, al				;cl <- char value (save away)
	mov	al, ch				;al <- accent table offset
	mov	ch, ah				;ch <- CharSet (save away)
	clr	ah				;ax <- accent table offset
	add	bx, ax				;bx <- ptr to entry
	mov	ah, ch				;ah <- CharSet
SBCS <	mov	al, cs:[KbdAccentables][bx] + NUM_ACCENTABLES		>
DBCS <	mov	ax, cs:[KbdAccentables][bx] + NUM_ACCENTABLES		>
	LocalIsNull	ax
	jnz	AT_80				;have accented char
SBCS <	mov	al, cl				;restore unaccented char >
DBCS <	mov	ax, cx				;restore unaccented char >
AT_80:
	mov	cx, 0				;indicate no pending accent
exit:
	popf					;restore "virtual" flag
	.leave
	ret			; <-- EXIT HERE

AT_SeeIfAccent:
	;
	; al = char value
	;
	clr	bx
ATHA_10:
SBCS <	cmp	cs:[KbdAccentTable][bx], al	;see if char matches	>
DBCS <	cmp	{wchar}cs:[KbdAccentTable][bx], ax ;see if char matches	>
	je	ATHA_20				;branch if match
	inc	bx				;inc ptr into table
DBCS <	inc	bx							>
	cmp	bx, KBD_NUM_ACCENTS
	jb	ATHA_10
	jmp	short AT_80

ATHA_20:
	mov	cl, al				;indicate accent pending
	mov	ch, bl				;store offset in table
	or	dl, mask CF_TEMP_ACCENT
	jmp	short exit

AccentTranslation	endp



if STYLUS_KEYBOARD
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StylusCheckSymbolOrInternational
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the Symbol or International keys were
		pressed.  If so, we need to pass back a character from
		either of their tables.

CALLED BY:	FindCharWithMods


PASS:		*ds:cx	= VisKeyboardClass object
		ds:si	= ptr to KeyboardStruct for key

RETURN:		ZFlag	= clear if we are in Symbol or International states:
				carry = set for virtual character
				ax = character
				cx = new accent info
				dl = CharFlags(CF_EXTENDED,CF_TEMP_ACCENT valid)
				dh = ShiftState
			= set if we aren't in Symbol or International states
				ax, cx, dx unchanged
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/21/94    	Initial version
	PT	06/20/96	Made DBCS changes.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StylusCheckSymbolOrInternational	proc	near
	uses	bx, si, di, es
	.enter

	mov	bx, cx
	mov	bx, ds:[bx]
	add	bx, ds:[bx].VisKeyboard_offset

	test	ds:[bx].VKI_extraState, mask VKESB_SYMBOL or \
						mask VKESB_INTERNATIONAL
LONG	jz	exit

	;
	;	**** More hacks to make the Stylus Keyboard work ****
	; OK, so we know that we are in some kind of International,
	; Symbol and Shift combination state.  We are so far away from 
	; having our scancode (which we really want here) that we have
	; to generate it from our KeyboardStruct ptr (which we do by
	; subtracting the beginning of the table and dividing by the 
	; structure size).  I really hate this kind of stuff.
	;		dlitwin 5/21/93
	;
	push	ax					; save old mod state
	mov	ax, si
	mov	si, ds:[bx].VKI_kbsHandle		; dereference to get
	sub	ax, ds:[si]				;  get our real offset
	push	dx
	mov	dx, size KeyboardStruct
	div	dl					; al is our scancode
	pop	dx
	clr	ah					; ax is our scancode
	inc	ax					; convert back to 
							;  scancode (1 based)

	;
	; To make our table shorter, crop it after CAPS_LOCK (3a) and pass
	; through anything above this (as they will be the same anyway)
	;
	mov	si, ax
	pop	ax					; restore old mod state
	cmp	si, CAPS_LOCK_SCANCODE
	jle	withinBounds

	SetZFlag					; not sym or int so ret
	jmp	exit					;  with zflag set

	;
	; Check to see if it is a virtual or special char and set carry if so
	;
withinBounds:
	mov	ax, si
 	mov	cx, length SymIntVirtualScancodes
	segmov	es, cs 	
	mov	di, offset SymIntVirtualScancodes
	repne	scasb 	
	clc						; assume not virtual
	jne	gotVirtualCharIndicator
	stc
gotVirtualCharIndicator:
	pushf					; preserve carry (virtual char)
	

	;
	; Now that that is over with, determine which offset in out table
	; to grab our char from by the modState and extraState bits.  Symbol
	; has no shift counterpart, but International does, giving us three
	; possible offsets it can be.
	;
	dec	ax				; ...and back to table (0 based)
	mov	ah, size StylusSymIntStruct
	mul	ah				; ax is index to table struct
	mov	cx, offset SSITE_symbol
	test	ds:[bx].VKI_extraState, mask VKESB_SYMBOL
	jnz	gotOffset

	mov	cx, offset SSITE_lowerInt
	test	ds:[bx].VKI_modState, mask MKS_SHIFT or mask MKS_CAPSLOCK
	jz	gotOffset

	mov	cx, offset SSITE_upperInt

gotOffset:
	mov	si, ax					; structure beginning
	add	si, cx					;  add structure offset

	mov	bx, handle VisKeymapData
	call	MemLock
	mov	es, ax
assume es:VisKeymapData
	add	si, es:[StylusSymIntTables]		; add beginning of table
	mov	ax, es:[si]				; get our char
	call	MemUnlock
assume es:dgroup

	popf						; restore carry
	jc	itsVirtual				;    (virtual char)

SBCS <	mov	ah, CS_BSW						>
DBCS <	mov	ah, CS_LATIN_1						>
	LocalIsNull	ax
	jz	itsVirtual
	clr	cx					; no accent info
	ClearZFlag
	clc
	jmp	exit

itsVirtual:
SBCS <	mov	ah, CS_CONTROL						>
DBCS <	mov	ah, CS_CONTROL_HB					>
	clr	dx					; assume no CharFlags
	segmov	es, cs, di
	mov	di, offset SymIntStateKeys
	mov	cx, length SymIntStateKeys
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	jne	noCharFlags
	mov	dl, mask CF_STATE_KEY
noCharFlags:
	clr	cx					; no accent info
	ClearZFlag
	stc
exit:
	.leave
	ret
StylusCheckSymbolOrInternational	endp

SymIntVirtualScancodes	byte \
	BACKSPACE_SCANCODE,
	DELETE_SCANCODE,
	TAB_SCANCODE,
	ENTER_SCANCODE,
	LSHIFT_SCANCODE,
	RSHIFT_SCANCODE,
	LCTRL_SCANCODE,
	CAPS_LOCK_SCANCODE

if DBCS_PCGEOS
SymIntStateKeys	Chars \
	C_SYS_LEFT_SHIFT,
	C_SYS_RIGHT_SHIFT,
	C_SYS_LEFT_ALT,
	C_SYS_RIGHT_ALT,
	C_SYS_LEFT_CTRL,
	C_SYS_RIGHT_CTRL,
	C_SYS_CAPS_LOCK
else
SymIntStateKeys	VChar \
	VC_LSHIFT,
	VC_RSHIFT,
	VC_LALT,
	VC_RALT,
	VC_LCTRL,
	VC_RCTRL,
	VC_CAPSLOCK
endif

endif		; endif of if STYLUS_KEYBOARD



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a key when it's pressed...
CALLED BY:	KeyboardMouseStartSelect

PASS:		*ds:si - VisKeyboardClass object
		bp (high) - scan code of key
		bp (low) - ToggleState
		dl - CharFlags:
			CF_RELEASE - set if release
			CF_STATE - set if shift, ctrl, etc
			CF_TEMP_ACCENT - set if accent pending
		dh - shift state
		cx - character value
		di - ^hGState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Assumes: size KeyPic == 9

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/89		Initial version
	JT	7/15/92		Modified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardPress	proc	near
	class	VisKeyboardClass
objChunk	local	lptr		push	si
kbdModState	local	MyKeyState
kbdTable	local	word

	uses	ax, bx, cx, dx, si, di, bp, es, ds
	.enter

EC <	call	ECCheckVisKbdObj			>
EC <	call	ECCheckGStateHandle			>
EC <	test	dl, not (mask CharFlags)		>
EC <	ERROR_NZ	ILLEGAL_KBD_CHAR_FLAGS		>
EC <	test	dh, not (mask MyKeyState)		>
EC <	ERROR_NZ	ILLEGAL_KBD_SHIFT_STATE		>
EC <	mov	ax, ss:[bp].low				>
EC <	test	al, not (mask ToggleState)		>
EC <	ERROR_NZ	ILLEGAL_KBD_TOGGLE_STATE	>

	push	di				; preserve GState
	mov	di, ds:[si]
	add	di, ds:[di].VisKeyboard_offset	; deref VisKeyboard object
	mov	al, ds:[di].VKI_modState
	mov	ss:[kbdModState], al

EC <	test	al, not (mask MyKeyState)		>
EC <	ERROR_NZ	ILLEGAL_KBD_MOD_STATE		>

	mov	bx, ds:[di].VKI_kbsHandle
	mov	bx, ds:[bx]			; deref kbsHandle lptr
	mov	ss:[kbdTable], bx		; save start of table

EC <	call	ECCheckKbdPtr			>

	mov	ax, ss:[bp]			; passed in bp (high=scan code)
	mov	al, ah				;al <- scan code
	dec	al				;scan codes start at 1
	clr	ah

	;
	; ax is the scan code (0 based now).
	; get the offset into the keyboard layout table of KeyPics (si)
	; and the offset into the dynamic table of KeyboardStructures (bx)
	;
	; NOTE:  If there is any change in the calculating the
	; offset..., could you please look at
	; KeyboardGetOtherShiftKeyState also to check if changes is
	; necessary.  Thanks.  Lulu /11/14/94
	
		CheckHack< (size KeyPic) eq 9 >
	mov	si, ax
	shl	si, 1
	shl	si, 1				;*9 for each KeyPic
	shl	si, 1				;
	add	si, ax
	add	si, ds:[di].VKI_kbdLayoutOffset

	push	bx
	mov	bl, size KeyboardStruct
	mul	bl
	pop	bx				; bx = start of table
	add	bx, ax				; bx = offset of KeyboardStruct
	pop	di				; restore GState

	test	dl, mask CF_STATE_KEY
	jz	normal				; branch if not state key

	mov	al, ds:[bx].KS_state

	and	al, not (mask MKS_PRESSED)	; ignore pressed bit
	jz	normal				; no bits, we're done
	test	dl, mask CF_RELEASE		; a release?
	LONG jnz	done			; ignore releases on togggles

EC <	push	si				>
EC <	mov	si, ss:[objChunk]		>
EC <	call	ECCheckKbdPtr			>
EC <	pop	si				>

	xor	ds:[bx].KS_state, mask MKS_PRESSED

	xor	ss:[kbdModState], al		; toggle modifier bits

	call	KeyboardCheckForShiftReleaseCapsLock

	push	si, ax
	mov	al, ss:[kbdModState]
	mov	si, ss:[objChunk]
	call	VisKeyboardSetModState
	pop	si, ax

	jmp	redraw

normal:
EC <	push	si			>
EC <	mov	si, ss:[objChunk]	>
EC <	call	ECCheckKbdPtr		>
EC <	pop	si			>
	call	MarkState			; mark up or down

	mov	bx, ss:[objChunk]
	call	KeyboardInvertKey

	test	dl, mask CF_RELEASE
	jz	done				; branch if not release

;	This was a release on a "normal" key. UnPress all temporary state keys.

	mov	bx, ds:[bx]			; bx already objChunk
	add	bx, ds:[bx].VisKeyboard_offset	; deref VisKeyboard object

	test	ss:[kbdModState], MKS_TEMP_STATE_KEY
	jnz	undoStates

	test	ds:[bx].VKI_extraState, VKESB_TEMP_STATE_KEY
	jz	done

undoStates:
	mov	al, ss:[kbdModState]
	andnf	al, not (MKS_TEMP_STATE_KEY)
	mov	ds:[bx].VKI_modState, al	; set the modState
	andnf	ds:[bx].VKI_extraState, (not VKESB_TEMP_STATE_KEY)
	mov	bx, ss:[kbdTable]		; bx is beginning of lptr table
	ChunkSizePtr	ds, bx, ax		; size of table
	add	ax, bx				; ax is end of lptr table

loopTop:
EC <	push	si				>
EC <	mov	si, ss:[objChunk]		>
EC <	call	ECCheckKbdPtr			>
EC <	pop	si				>
	test	ds:[bx].KS_state, MKS_TEMP_STATE_KEY
	jz	next

	andnf	ds:[bx].KS_state, not mask MKS_PRESSED

next:
	add	bx, size KeyboardStruct
	cmp	bx, ax				; to end of table?
	jb	loopTop				; branch while not end

redraw:
	mov	al, TRUE
	mov	si, ss:[objChunk]		; *ds:si <- VisKeyboard object
	call	KeyboardRedraw

done:
	.leave
	ret
KeyboardPress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardCheckForShiftReleaseCapsLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check our instance data.   If the shiftRelease flag is
		true, implement this for this feature for the keyboard.

CALLED BY:	KeyboardPress

PASS:		inherited stack frame
		ds	= our VisKeyboardClass object block
		al	= flags of key pressed
		ds:bx	= KeyboardStruct of key pressed
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
		ss:[kbdModState] updated correctly
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardCheckForShiftReleaseCapsLock	proc	near
	uses	di
	.enter inherit KeyboardPress

	mov	di, ss:[objChunk]
	mov	di, ds:[di]
	add	di, ds:[di].Vis_offset

	;
	; If the "shift releases the capslock key" option isn't set, punt
	;
	tst	ds:[di].VKI_shiftRelease
	jz	exit

	;
	; If they didn't hit the shift key, punt
	;
	test	al, mask MKS_SHIFT
	jz	exit

	;
	; If the capslock key wasn't already down, punt
	;
	test	ss:[kbdModState], mask MKS_CAPSLOCK
	jz	exit

	;
	; OK, the capslock is down and they pressed shift, so clear
	; out Caps lock if shift was pressed.  'un-press' shift as
	; well, as it is only functioning to cancel the Caps lock in
	; this capacity.
	;
	and	ss:[kbdModState], not (mask MKS_CAPSLOCK or mask MKS_SHIFT)
	mov	di, ((CAPS_LOCK_SCANCODE - 1) * (size KeyboardStruct))
	add	di, ss:[kbdTable]
	andnf	ds:[di].KS_state, not (mask MKS_PRESSED)
	andnf	ds:[bx].KS_state, not (mask MKS_PRESSED)

exit:
	.leave
	ret
KeyboardCheckForShiftReleaseCapsLock	endp



;-------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the KeyboardStruct press state according to the
		CharFlags passed in dl.

CALLED BY:	KeyboardPress

PASS:		ds:bx	= KeyboardStruct ptr
		dl	= CharFlags
RETURN:		nothing
DESTROYED:	al

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/21/94    	Added this header, rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkState	proc	near
	uses	ax
	.enter

	test	dl, mask CF_RELEASE		; if release, mark as unpressed
	jnz	markAsUnpressed

	;
	; mark it as pressed otherwise
	;
	ornf	ds:[bx].KS_state, mask MKS_PRESSED
	jmp	exit

markAsUnpressed:
	andnf	ds:[bx].KS_state, not (mask MKS_PRESSED)
exit:

	.leave
	ret
MarkState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		KeyboardInvertKey
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert or white out one key.

CALLED BY:	KeyboardPress, KeyboardRedraw

PASS:		di - handle of gstate
		si - offset into table of key bounds
		*ds:bx	= VisKeyboard object

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/89		Initial version
	dlitwin	5/17/94		added passing in *ds:bx so we can check
				for the AltGr key in Stylus

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
KeyboardInvertKey	proc	near
	uses	ax, bx, cx, dx
	.enter

EC <	call	ECCheckGStateHandle			>
	call	GrSaveState
	mov	al, MM_INVERT
	call	GrSetMixMode
	call	GetKeyBounds
	inc	ax 
	inc	bx
	call	GrFillRect
	call	GrRestoreState

	.leave
	ret
KeyboardInvertKey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetKeyBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the bounds of the keys

CALLED BY:	GLOBAL

PASS:		si	= offset into table of key bounds
		*ds:bx	= VisKeyboardClass object
RETURN:		ax, bx, cx, dx - bounds of key
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/28/92		Initial version
	dlitwin	5/17/94		added passing in *ds:bx so we can check
				for the AltGr key in Stylus

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetKeyBounds	proc	near
	.enter

EC <	tst	cs:[si].KP_exists			>
EC <	ERROR_Z	KBD_KEY_DOES_NOT_EXIST			>

	mov	ax, cs:[si].KP_left
	mov	cx, cs:[si].KP_right			; assume normal
	;
	; *********** Here I do a big hack to save space ************
	; The Stylus keyboard has an extra key (AltGr) if the .ini file
	; indicates it, and so the space bar has to move its right border
	; to fit it.  I could have two keyboard layouts and choose the
	; correct one according to the .ini file, but the size of these
	; tables is about 1k, and so having an extra one hanging around
	; for no reason is expensive.  I would have liked to just edit the
	; damn thing if the .ini file indicates AltGr, but it is in the code
	; segment and that is a no-no.
	;	Instead the table is set up with the full length spacebar
	; *and* the AltGr key.  If we won't be using the AltGr key I just 
	; store a shorter length for the table in VKI_kbdLayoutLength, so
	; the AltGr key never gets hit (as if it didn't exist) and we are
	; happy.  If we will be using the AltGr key, I store the real length
	; of the table in VKI_kbdLayoutLength so we get the AltGr key, and
	; then here when we return the bounds of the spacebar key I just
	; fudge it to fit the AltGr key.
	;			dlitwin 5/17/94
	;
if STYLUS_KEYBOARD
	mov	bx, ds:[bx]
	add	bx, ds:[bx].VisKeyboard_offset	; dereference our instance data
	tst	ds:[bx].VKI_hasAltGr
	jz	skipAdjustment

	;	
	; The table is 0 based, so we have the scancode-1 structures
	;
	mov	bx, ds:[bx].VKI_kbdLayoutOffset
	add	bx, ((SPACE_SCANCODE-1) * (size KeyPic))
	cmp	bx, si
	jne	skipAdjustment

	sub	cx, STYLUS_ALT_GR_KEY_WIDTH	; make room for the AltGr key

skipAdjustment:
endif

	mov	bx, cs:[si].KP_top
	mov	dx, cs:[si].KP_bottom

	.leave
	ret
GetKeyBounds	endp






bitTable	ExtVirtualBits \
	EV_KEY,
	EV_SHIFT,
	EV_CTRL,
	EV_SHIFT_CTRL,
	EV_ALT,
	EV_SHIFT_ALT,
	EV_CTRL_ALT,
	EV_SHIFT_CTRL_ALT

if DBCS_PCGEOS
KbdAccentables	wchar \
	' ', 'a','A','c','C','e','E','i','I','o','O','u','U','n','N','y','Y'
else
KbdAccentables	label	Chars
	byte	' ','a','A','c','C','e','E','i','I','o','O','u','U','n','N','y','Y'
endif
						; Accentable chars
NUM_ACCENTABLES = ($-KbdAccentables)

; table must follow immediately:

if DBCS_PCGEOS

KbdAccentTable	AccentDef \
<<					;accents themselves
	C_NON_SPACING_DIAERESIS,		;..
	C_NON_SPACING_ACUTE,			;'
	C_NON_SPACING_TILDE,			;~
	C_NON_SPACING_GRAVE,			;`
	C_NON_SPACING_CIRCUMFLEX,		;^
	C_NON_SPACING_RING_ABOVE,		;o
	C_NON_SPACING_CEDILLA			;,
>>,<<						;accents for 'a'
	C_LATIN_SMALL_LETTER_A_DIAERESIS,
	C_LATIN_SMALL_LETTER_A_ACUTE,
	C_LATIN_SMALL_LETTER_A_TILDE,
	C_LATIN_SMALL_LETTER_A_GRAVE,
	C_LATIN_SMALL_LETTER_A_CIRCUMFLEX,
	C_LATIN_SMALL_LETTER_A_RING,
	0
>>,<<						;accents for 'A'
	C_LATIN_CAPITAL_LETTER_A_DIAERESIS,
	C_LATIN_CAPITAL_LETTER_A_ACUTE,
	C_LATIN_CAPITAL_LETTER_A_TILDE,
	C_LATIN_CAPITAL_LETTER_A_GRAVE,
	C_LATIN_CAPITAL_LETTER_A_CIRCUMFLEX,
	C_LATIN_CAPITAL_LETTER_A_RING,
	0
>>,<<						;accents for 'c'
	0,
	0,
	0,
	0,
	0,
	0,
	C_LATIN_SMALL_LETTER_C_CEDILLA
>>,<<						;accents for 'C'
	0,
	0,
	0,
	0,
	0,
	0,
	C_LATIN_CAPITAL_LETTER_C_CEDILLA
>>,<<						; accents for 'e'
	C_LATIN_SMALL_LETTER_E_DIAERESIS,
	C_LATIN_SMALL_LETTER_E_ACUTE,
	0,
	C_LATIN_SMALL_LETTER_E_GRAVE,
	C_LATIN_SMALL_LETTER_E_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'E'
	C_LATIN_CAPITAL_LETTER_E_DIAERESIS,
	C_LATIN_CAPITAL_LETTER_E_ACUTE,
	0,
	C_LATIN_CAPITAL_LETTER_E_GRAVE,
	C_LATIN_CAPITAL_LETTER_E_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'i'
	C_LATIN_SMALL_LETTER_I_DIAERESIS,
	C_LATIN_SMALL_LETTER_I_ACUTE,
	0,
	C_LATIN_SMALL_LETTER_I_GRAVE,
	C_LATIN_SMALL_LETTER_I_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'I'
	C_LATIN_CAPITAL_LETTER_I_DIAERESIS,
	C_LATIN_CAPITAL_LETTER_I_ACUTE,
	0,
	C_LATIN_CAPITAL_LETTER_I_GRAVE,
	C_LATIN_CAPITAL_LETTER_I_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'o'
	C_LATIN_SMALL_LETTER_O_DIAERESIS,
	C_LATIN_SMALL_LETTER_O_ACUTE,
	C_LATIN_SMALL_LETTER_O_TILDE,
	C_LATIN_SMALL_LETTER_O_GRAVE,
	C_LATIN_SMALL_LETTER_O_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'O'
	C_LATIN_CAPITAL_LETTER_O_DIAERESIS,
	C_LATIN_CAPITAL_LETTER_O_ACUTE,
	C_LATIN_CAPITAL_LETTER_O_TILDE,
	C_LATIN_CAPITAL_LETTER_O_GRAVE,
	C_LATIN_CAPITAL_LETTER_O_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'u'
	C_LATIN_SMALL_LETTER_U_DIAERESIS,
	C_LATIN_SMALL_LETTER_U_ACUTE,
	0,
	C_LATIN_SMALL_LETTER_U_GRAVE,
	C_LATIN_SMALL_LETTER_U_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'U'
	C_LATIN_CAPITAL_LETTER_U_DIAERESIS,
	C_LATIN_CAPITAL_LETTER_U_ACUTE,
	0,
	C_LATIN_CAPITAL_LETTER_U_GRAVE,
	C_LATIN_CAPITAL_LETTER_U_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'n'
	0,
	0,
	C_LATIN_SMALL_LETTER_N_TILDE,
	0,
	0,
	0,
	0
>>,<<						; accents for 'N'
	0,
	0,
	C_LATIN_CAPITAL_LETTER_N_TILDE,
	0,
	0,
	0,
	0
>>,<<						; accents for 'y'
	C_LATIN_SMALL_LETTER_Y_DIAERESIS,
	C_LATIN_SMALL_LETTER_Y_ACUTE,
	0,
	0,
	0,
	0,
	0
>>,<<						; accents for 'Y'
	C_LATIN_CAPITAL_LETTER_Y_DIAERESIS,
	C_LATIN_CAPITAL_LETTER_Y_ACUTE,
	0,
	0,
	0,
	0,
	0
>>

else

KbdAccentTable	label	byte
AccentDef <<					;accents themselves
	C_DIERESIS,				;..
	C_ACUTE,				;'
	C_TILDE,				;~
	C_GRAVE,				;`
	C_CIRCUMFLEX,				;^
	C_RING,					;o
	C_CEDILLA				;,
>>,<<						;accents for 'a'
	C_LA_DIERESIS,
	C_LA_ACUTE,
	C_LA_TILDE,
	C_LA_GRAVE,
	C_LA_CIRCUMFLEX,
	C_LA_RING,
	0
>>,<<						;accents for 'A'
	C_UA_DIERESIS,
	C_UA_ACUTE,
	C_UA_TILDE,
	C_UA_GRAVE,
	C_UA_CIRCUMFLEX,
	C_UA_RING,
	0
>>,<<						;accents for 'c'
	0,
	0,
	0,
	0,
	0,
	0,
	C_LC_CEDILLA
>>,<<						;accents for 'C'
	0,
	0,
	0,
	0,
	0,
	0,
	C_UC_CEDILLA
>>,<<						; accents for 'e'
	C_LE_DIERESIS,
	C_LE_ACUTE,
	0,
	C_LE_GRAVE,
	C_LE_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'E'
	C_UE_DIERESIS,
	C_UE_ACUTE,
	0,
	C_UE_GRAVE,
	C_UE_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'i'
	C_LI_DIERESIS,
	C_LI_ACUTE,
	0,
	C_LI_GRAVE,
	C_LI_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'I'
	C_UI_DIERESIS,
	C_UI_ACUTE,
	0,
	C_UI_GRAVE,
	C_UI_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'o'
	C_LO_DIERESIS,
	C_LO_ACUTE,
	C_LO_TILDE,
	C_LO_GRAVE,
	C_LO_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'O'
	C_UO_DIERESIS,
	C_UO_ACUTE,
	C_UO_TILDE,
	C_UO_GRAVE,
	C_UO_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'u'
	C_LU_DIERESIS,
	C_LU_ACUTE,
	0,
	C_LU_GRAVE,
	C_LU_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'U'
	C_UU_DIERESIS,
	C_UU_ACUTE,
	0,
	C_UU_GRAVE,
	C_UU_CIRCUMFLEX,
	0,
	0
>>,<<						; accents for 'n'
	0,
	0,
	C_LN_TILDE,
	0,
	0,
	0,
	0
>>,<<						; accents for 'N'
	0,
	0,
	C_UN_TILDE,
	0,
	0,
	0,
	0
>>,<<						; accents for 'y'
	C_LY_DIERESIS,
	C_LY_ACUTE,
	0,
	0,
	0,
	0,
	0
>>,<<						; accents for 'Y'
	C_UY_DIERESIS,
	C_UY_ACUTE,
	0,
	0,
	0,
	0,
	0
>>

endif

VisKeyboardCode ends

endif	; if (not _GRAFFITI_UI)
