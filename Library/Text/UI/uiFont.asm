COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiFontControl.asm

ROUTINES:
	Name			Description
	----			-----------
	GetFeaturesAndChildBlock Generate UI for this controller

	SetFontCommon		Handle a font set via the short list

	SendMeta_AX_CX_Common Handle a font set via the short list

	UpdateFontSample	Update the font sample in the more fonts
				list

    INT FontCreateList		Build a list of fonts based on what's
				actually available.

    INT CreateFontListEntry	Create a GenListEntry for a fonts list

    INT CreateCustomFontMenu	Create custom font menu from geos.ini file

    INT CheckFontKey		Check for a custom font menu specified in
				the geos.ini file

    INT GetValueFromHexString	Convert an ASCII string of hex digits to a
				value

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement FontControlClass

	$Id: uiFont.asm,v 1.1 97/04/07 11:16:38 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	FontControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	FontControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for FontControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of FontControlClass

	ax - The message

RETURN:
	cx:dx - list of children

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
FontControlGetInfo	method dynamic	FontControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset FC_dupInfo
	GOTO	CopyDupInfoCommon

FontControlGetInfo	endm

FC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	FC_IniFileKey,			; GCBI_initFileKey
	FC_gcnList,			; GCBI_gcnList
	length FC_gcnList,		; GCBI_gcnCount
	FC_notifyTypeList,		; GCBI_notificationList
	length FC_notifyTypeList,	; GCBI_notificationCount
	FCName,				; GCBI_controllerName

	handle FontControlUI,		; GCBI_dupBlock
	FC_childList,			; GCBI_childList
	length FC_childList,		; GCBI_childCount
	FC_featuresList,		; GCBI_featuresList
	length FC_featuresList,		; GCBI_featuresCount
	FC_DEFAULT_FEATURES,		; GCBI_features

	handle FontControlToolboxUI,	; GCBI_toolBlock
	FC_toolList,			; GCBI_toolList
	length FC_toolList,		; GCBI_toolCount
	FC_toolFeaturesList,		; GCBI_toolFeaturesList
	length FC_toolFeaturesList,	; GCBI_toolFeaturesCount
	FC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

FC_IniFileKey	char	"font", 0

FC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_FONT_CHANGE>

FC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_FONT_CHANGE>

;---

FC_childList	GenControlChildInfo	\
	<offset ShortFontsList, mask FCF_SHORT_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset MoreFontsBox, mask FCF_LONG_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

FC_featuresList	GenControlFeaturesInfo	\
	<offset MoreFontsBox, LongFontsName, 0>,
	<offset ShortFontsList, ShortFontsName, 0>

;---

FC_toolList	GenControlChildInfo	\
	<offset FontToolList, mask FCTF_TOOL_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

FC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset FontToolList, PopupFontsName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	FontControlUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for FontControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of FontControlClass

	ax - The message

	cx.dx - change type ID
	bp - handle of block with NotifyTextChange structure

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91		Initial version

------------------------------------------------------------------------------@
FID_FAMILY_MASK	equ	0FFFh

FontControlUpdateUI	method dynamic FontControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	cmp	ss:[bp].GCUUIP_changeType, GWNT_TEXT_CHAR_ATTR_CHANGE
	jz	textNotify
	mov	cx, ds:NFC_fontID
	clr	dx
	mov	dl, ds:NFC_diffs
	jmp	common
textNotify:
	mov	cx, ds:VTNCAC_charAttr.VTCA_fontID
	mov	dx, ds:VTNCAC_charAttrDiffs.VTCAD_diffs
	and	dx, mask VTCAF_MULTIPLE_FONT_IDS
common:
	call	MemUnlock
	pop	ds

	; map non existing font id's, it it is one
	; check for given font id availability first
	mov	ax, cx
	push	dx		; keep indeterminate flag
	mov	dl, mask FEF_OUTLINES; match exact font id in cx
	call	GrCheckFontAvail
	pop	dx
	cmp	cx, FID_INVALID
	jne	fontResolved

	; find a mapped font id
	and	ax, FID_FAMILY_MASK
tryNext:
	push	ax
	push	dx		; keep indeterminate flag
	mov	dl, mask FEF_OUTLINES 	; match exact font id in cx
	mov	cx, ax
	call	GrCheckFontAvail
	pop	dx
	pop	ax
	cmp	cx, FID_INVALID
	jne	fontResolved

	add	ax, FID_MAKER_DIVISIONS
	jnc	tryNext
	mov	cx, -1		; signal invalid FID, no selection

	; set toolbox list
fontResolved:
	test	ss:[bp].GCUUIP_toolboxFeatures,	mask FCTF_TOOL_LIST
	jz	noToolboxList
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset FontToolList
	call	SendListSetExcl
noToolboxList:

	; set short list

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask FCF_SHORT_LIST
	jz	noShortList
	mov	si, offset ShortFontsList
	call	SendListSetExcl
noShortList:

	; set long list

	test	ax, mask FCF_LONG_LIST
	jz	noLongList
	mov	si, offset LongFontsList
	call	SendListSetExcl
	clr	di
	call	UpdateFontSample
noLongList:

	ret

FontControlUpdateUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	FontControlSetFont -- MSG_FC_SET_FONT
						for FontControlClass

DESCRIPTION:	Handle a font set via the short list

PASS:
	*ds:si - instance data
	es - segment of FontControlClass

	ax - The message

	cx - font id

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
FontControlSetFont	method dynamic	FontControlClass, MSG_FC_SET_FONT

	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	FALL_THRU	SendMeta_AX_CX_Common

FontControlSetFont	endm

;---

SendMeta_AX_CX_Common	proc	far
	push	bp

	clr	dx
	push	cx			;font id
	push	dx			;range.end.high
	push	dx			;range.end.low
	mov	bx, VIS_TEXT_RANGE_SELECTION
	push	bx			;range.start.high
	push	dx			;range.start.low
	mov	bp, sp
	mov	dx, size VisTextSetFontIDParams
	clr	bx
	clr	di
	call	GenControlOutputActionStack
	add	sp, size VisTextSetFontIDParams

	pop	bp
	ret

SendMeta_AX_CX_Common	endp


TextControlCommon ends

;---

TextControlCode segment resource


GetFeaturesAndChildBlock	proc	near
EC <	push	es, di							>
EC <	mov	di, segment GenControlClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenControlClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	CONTROLLER_OBJECT_INTERNAL_ERROR		>
EC <	pop	es, di							>
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
GetFeaturesAndChildBlock	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	FontControlTweakDuplicatedUI

DESCRIPTION:	Augment duplicated UI

PASS:
	*ds:si - instance data
	es - segment of FontControlClass

	ax - The message
	cx - Duplicated block
	dx - features

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Inital version, scammed from old GENERATE_UI

------------------------------------------------------------------------------@

if PZ_PCGEOS
MAX_SHORT_LIST_FONTS	=	11
else
ifdef GPC_TEXT_STYLE
MAX_SHORT_LIST_FONTS	=	MAX_FONTS
else
MAX_SHORT_LIST_FONTS	=	MAX_MENU_FONTS
endif
endif
MAX_LONG_LIST_FONTS	=	MAX_FONTS

FontControlTweakDuplicatedUI	method dynamic	FontControlClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI

	; now build out the font lists if needed

	mov	ax, dx			;ax = features, bx = child block
	mov	bx, cx
	;
	; Check for ATTR_FONT_CONTROL_INCLUDE_UI_FONT
	;
	push	ax, bx
	clr	dh				;dh <- no UI font
	mov	ax, ATTR_FONT_CONTROL_INCLUDE_UI_FONT
	call	ObjVarFindData
	jnc	noUIFont
	dec	dh				;dh <- include UI font
noUIFont:
	pop	ax, bx
	;
	; Deal with the short list (aka "Fonts" menu)
	;
	test	ax, mask FCF_SHORT_LIST
	jz	noShortList
	;
	; Any hint to override the default font type?
	;
	push	si
	push	ax, bx
	mov	dl, mask FEF_OUTLINES or \
		    mask FEF_USEFUL or \
		    mask FEF_ALPHABETIZE
	mov	ax, ATTR_FONT_CONTROL_SHORT_LIST_FONT_TYPE
	call	ObjVarFindData
	jnc	noShortFontTypeHint
	mov	dl, ds:[bx]
EC <	test	dl, mask FEF_STRING or \
		    mask FEF_FAMILY >
EC <	ERROR_NZ FID_CONTROLLER_BAD_FONT_HINT >
noShortFontTypeHint:
	pop	ax, bx
	pop	si
	;
	; Any option in the geos.ini file to specify the short list?
	;
	mov	di, offset fontmenuKey		;cs:di <- name of key
	mov	bp, offset ShortFontsList	;^lbx:bp <- parent list
	call	CreateCustomFontMenu		;custom font menu?
	jnc	noShortList			;branch if built
	;
	; Build the short list
	;
	push	si
	mov	si, offset ShortFontsList
	mov	cx, MAX_SHORT_LIST_FONTS
	call	FontCreateList
	pop	si
noShortList:
	;
	; Deal with the long list (aka "More Fonts" DB)
	;
	test	ax, mask FCF_LONG_LIST
	jz	noLongList
	;
	; Any hint to override the default font type?
	;
	push	bx
	mov	dl, mask FEF_OUTLINES or \
		    mask FEF_ALPHABETIZE		;dl <- default type
	mov	ax, ATTR_FONT_CONTROL_LONG_LIST_FONT_TYPE
	call	ObjVarFindData
	jnc	noLongFontTypeHint
	mov	dl, ds:[bx]
EC <	test	dl, mask FEF_STRING or \
		    mask FEF_FAMILY >
EC <	ERROR_NZ FID_CONTROLLER_BAD_FONT_HINT >
noLongFontTypeHint:
	pop	bx
	;
	; Build the long list
	;
	push	si
	mov	si, offset LongFontsList
	mov	cx, MAX_LONG_LIST_FONTS
	call	FontCreateList
	pop	si
noLongList:

	ret

FontControlTweakDuplicatedUI	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	FontControlSetFontFromList -- MSG_FC_SET_FONT_FROM_LIST
						for FontControlClass

DESCRIPTION:	Handle a font set via the long list

PASS:
	*ds:si - instance data
	es - segment of FontControlClass

	ax - The message

	cx - font id
	bp low - ListEntryState
	bp high - ListUpdateFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
FontControlSetFontFromList	method dynamic	FontControlClass,
						MSG_FC_SET_FONT_FROM_LIST
	FALL_THRU	SetFontCommon

FontControlSetFontFromList	endm


SetFontCommon	proc	far	
	;Font ID in cx
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	call	SendMeta_AX_CX_Common
	ret

SetFontCommon	endp

FontControlUserChangedFontFromList	method dynamic	FontControlClass,
					MSG_FC_USER_CHANGED_FONT_FROM_LIST
	clr	bx
	mov	di, mask MF_FIXUP_DS
	call	UpdateFontSample
	ret
FontControlUserChangedFontFromList	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateFontSample

DESCRIPTION:	Update the font sample in the more fonts list

CALLED BY:	INTERNAL

PASS:
	bx - handle of child block
	-OR- *ds:si - FontControlClass object
	cx - font ID
	di - flags (0 for MF_FIXUP_DS)

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/91		Initial version

------------------------------------------------------------------------------@
UpdateFontSample	proc	far	uses ax, dx, si, di, bp
	.enter

	; get OD of font sample object

	tst	bx
	jnz	gotBlock
	call	GetFeaturesAndChildBlock	;ax = features, bx = child block
gotBlock:

	; send the message

	mov	si, offset FontSampleTextDisplay
	clr	ax
	push	cx			;font id
	push	ax			;range.end.high
	push	ax			;range.end.low
	mov	dx, VIS_TEXT_RANGE_SELECTION
	push	dx			;range.start.high
	push	ax			;range.start.low
	mov	bp, sp
	mov	dx, size VisTextSetFontIDParams
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	ornf	di, mask MF_STACK
	call	ObjMessage
	add	sp, size VisTextSetFontIDParams

	.leave
	ret

UpdateFontSample	endp

TextControlCode ends

;---

TextControlInit segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontCreateList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a list of fonts based on what's actually available.
CALLED BY:	OpenApplication

PASS:		^lbx:si - parent list
		cx - maximum number of fonts to add
		dl - FontEnumFlags of font types to use (see GrEnumFonts)
		dh - non-zero if ATTR_FONT_CONTROL_INCLUDE_UI_FONT
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FontCreateList	proc	far
	uses	ax, bx, cx, dx, es, ds, di
	.enter
	;
	; Allocate a block and get the list of fonts available
	;
	push	bx, cx, dx
	mov	ax, size FontEnumStruct		;ax <- size of structure
	mul	cx				;ax <- size in bytes
EC <	ERROR_C	FID_CONTROLLER_TOO_MANY_FONTS	;>
	mov	cx, ALLOC_DYNAMIC_LOCK		;cl, ch <- HeapAllocFlags
	call	MemAlloc			;bx <- memory block
	pop	di, cx, dx			;di <- handle of parent block
	jc	error				;bail out if alloc failed

	push	bx				;save handle of buffer
	mov	bx, di				;bx <- handle of UI stuff
	mov	es, ax
	clr	di				;es:di <- ptr to buffer
	call	GrEnumFonts			;cx == # of fonts found
	jcxz	noFonts				;branch if none found
	;
	; lock the parent block
	;
	call	ObjLockObjBlock
	mov	ds, ax				;*ds:si <- parent list
	;
	; Deal with ATTR_FONT_CONTROL_INCLUDE_UI_FONT
	;
	tst	dh				;UI font?
	jz	noUIFont			;branch if not
	call	AddUIFont
noUIFont:

	;
	; For each font found, create a list entry and add it to the list
	;
fontLoop:
	call	CreateFontListEntry
	add	di, size FontEnumStruct		;es:di <- next entry
	loop	fontLoop			;branch while more fonts
	;
	; Unlock parent list
	;
	call	MemUnlock
	;
	; We're done with the font enum buffer, so free it
	;
noFonts:
	pop	bx				;bx <- handle of buffer
	call	MemFree				;free the buffer
error:
	.leave
	ret
FontCreateList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddUIFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GenListEntry for a fonts list
CALLED BY:	FontCreateList(), CreateCustomFontMenu()

PASS:		bx - handle of parent block
		*ds:si - parent list
RETURN:		none
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ds may change
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddUIFont	proc	near
	uses	es, di, cx
	.enter

	sub	sp, size FontEnumStruct
	segmov	es, ss
	mov	di, sp				;es:di <- FontEnumStruct
	;
	; get the UI font
	;
	call	UserGetDefaultMonikerFont	;cx <- font ID
	mov	es:[di].FES_ID, cx		;save ID
	;
	; get the name of the font
	;
	push	ds, si
	segmov	ds, ss
	lea	si, es:[di].FES_name		;ds:si <- FES_name
	call	GrGetFontName
	pop	ds, si
	jcxz	noFont				;branch if not there
	;
	; create the list entry
	;
	call	CreateFontListEntry
noFont:
	add	sp, size FontEnumStruct

	.leave
	ret
AddUIFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateFontListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GenListEntry for a fonts list
CALLED BY:	FontCreateList(), CreateCustomFontMenu()

PASS:		es:di - ptr to FontEnumStruct
		bx - block of parent
		*ds:si - parent list
RETURN:		none
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ds may change
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateFontListEntry	proc	near
	uses	cx, di
	.enter

	mov	cx, es:[di].FES_ID		;cx <- action = font ID
	add	di, offset FES_name		;es:di <- ptr to name string

	mov	dx, mask OCF_IGNORE_DIRTY	;entries s/b ignore-dirty
	call	UserCreateItem			;create an item
	call	UserAddItemToGroup		;add it to the group

	.leave
	ret
CreateFontListEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateCustomFontMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create custom font menu from geos.ini file
CALLED BY:	FontControlGenerateUI()

PASS:		*ds:si - font controller object
		^lbx:bp - OD of parent list
		cs:di - ptr to geos.ini file key
RETURN:		carry - clear if custom menu built
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

fonttoolKey	char "fonttool", 0
fontmenuKey	char "fontmenu", 0
systemKey	char "system", 0

CreateCustomFontMenu	proc	far
	uses	ax, bx, cx, dx, es, ds, si, di
fontMenuOff	local	word	push	bp
fontMenuHan	local	hptr	push	bx
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
fontEntry	local	FontEnumStruct
	.enter

	;
	; Get the application category, if any
	;
	mov	cx, ss
	lea	dx, ss:categoryBuffer
	call	UserGetInitFileCategory

	tst	ss:categoryBuffer[0]		;any category?
	jz	checkSystem			;branch if no category
	;
	; Get the application 'fontmenu' or 'fonttool' key, if any
	;
	push	ds, si
	lea	si, ss:categoryBuffer
	segmov	ds, ss				;ds:si <- category string
	call	CheckFontKey			;any key?
	pop	ds, si
	jnc	buildMenu			;branch if key found
	;
	; Get the system 'fontmenu' or 'fonttool' key, if any
	;
checkSystem:
	push	ds, si
	mov	si, offset systemKey
	segmov	ds, cs				;ds:si <- category string
	call	CheckFontKey
	pop	ds, si
	jc	noMenu				;branch if no key found
	;
	; We have a string -- let's build a menu
	;
buildMenu:
	push	bx
	call	MemLock
	mov	es, ax
	clr	di				;es:di <- ptr to ini string
	;
	; Make sure the string isn't empty
	;
SBCS <	tst	{char}es:[0]			;empty string?		>
DBCS <	tst	{wchar}es:[0]			;empty string?		>
	stc					;carry <- menu not built
	jz	emptyStringExit			;branch if empty string
	;
	; The string should be a series of 4-digit hex numbers
	;
EC <	test	cx, 00000011b			;correct size? >
EC <	ERROR_NZ FID_CONTROLLER_CUSTOM_FONT_ENTRY_BAD_LENGTH >
	shr	cx, 1
	shr	cx, 1				;cx <- # of entries in string
	;
	; lock the parent block
	;
	mov	bx, ss:fontMenuHan		;bx <- mommy's handle
	call	ObjLockObjBlock
	mov	ds, ax
fontLoop:
	;
	; For each entry in the string...
	;
	push	cx, ds
	call	GetValueFromHexString		;ax <- hex value
	mov	ss:fontEntry.FES_ID, ax		;store ID
	;
	; ...see if the font is available and get the name
	;
	mov	cx, ax				;cx <- FontID value
	segmov	ds, ss
	lea	si, ss:fontEntry.FES_name	;ds:si <- ptr to buffer
	call	GrGetFontName
	pop	cx, ds
	jnc	skipFont			;branch if not available
	;
	; ...and if it is available, create a list entry for it
	;
	push	es, di
	segmov	es, ss
	lea	di, ss:fontEntry		;es:di <- ptr to FontEnumStruct
	mov	si, ss:fontMenuOff		;*ds:si <- parent list
	call	CreateFontListEntry
	pop	es, di
skipFont:
	loop	fontLoop
	clc					;carry <- menu built
	;
	; Unlock the parent list
	;
	call	MemUnlock
	;
	; all done!
	;
emptyStringExit:
	pop	bx				;bx <- handle of ini string
	pushf
	call	MemFree
	popf
noMenu:
	.leave
	ret
CreateCustomFontMenu	endp

CheckFontKey	proc	near
	uses	bp, di
	.enter

	mov	cx, cs
	mov	dx, di				;cx:dx <- key string
	mov	bp, IFCC_DOWNCASE shl offset IFRF_CHAR_CONVERT
						;bp <- InitFileReadFlags
						;-> alloc buffer
						;-> downcase string
	call	InitFileReadString		;cx = data size, bx = buffer
						;carry = set if found
	.leave
	ret
CheckFontKey	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHexString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an ASCII string of hex digits to a value
CALLED BY:	CreateCustomFontMenu()

PASS:		es:di - ptr to string of #### (4 hex digits)
RETURN:		ax - hex value
		es:di - ptr past string
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <'9' lt 'a'>
CheckHack <'0' lt '9'>
CheckHack <'a' lt 'f'>

GetValueFromHexString	proc	near
	uses	cx, dx
	.enter

	clr	dx				;dx <- value
	mov	cx, 4				;cx <- # of digits
digitLoop:
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1
	shl	dx, 1				;dx <- value*16
SBCS <	mov	al, es:[di]			;al <- character of string >
DBCS <	mov	ax, es:[di]			;al <- character of string >
SBCS <	cmp	al, '9'							>
DBCS <	cmp	ax, '9'							>
	ja	isChar				;branch if not digit
EC <	cmp	al, '0'				;>
EC <	ERROR_B	FID_CONTROLLER_CUSTOM_FONT_ENTRY_BAD_CHAR ;>
	sub	al, '0'				;al <- value (0-9)
	jmp	gotDigit

isChar:
SBCS <EC <	cmp	al, 'f'				;>		>
DBCS <EC <	cmp	ax, 'f'				;>		>
EC <	ERROR_A	FID_CONTROLLER_CUSTOM_FONT_ENTRY_BAD_CHAR ;>
SBCS <EC <	cmp	al, 'a'				;>		>
DBCS <EC <	cmp	ax, 'a'				;>		>
EC <	ERROR_B FID_CONTROLLER_CUSTOM_FONT_ENTRY_BAD_CHAR ;>
	sub	al, 'a'-10			;al <- value (10-15)
gotDigit:
	ornf	dl, al				;dx <- new value
	inc	di
DBCS <	inc	di							>
	loop	digitLoop			;loop while more

	mov	ax, dx				;ax <- value

	.leave
	ret
GetValueFromHexString	endp

;---


COMMENT @----------------------------------------------------------------------

MESSAGE:	FontControlTweakDuplicatedToolboxUI

DESCRIPTION:	Augment duplicated UI

PASS:
	*ds:si - instance data
	es - segment of FontControlClass

	ax - The message
	cx - Duplicated block
	dx - features

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/93		Inital version, scammed from old GENERATE_UI

------------------------------------------------------------------------------@

FontControlTweakDuplicatedToolboxUI	method	FontControlClass,
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI

	; Build the toolbox list
	;
	mov	bx, cx				; bx = block,
	mov	ax, dx				; ax = features

	test	ax, mask FCTF_TOOL_LIST
	jz	noToolboxList
	;
	; deal with ATTR_FONT_CONTROL_INCLUDE_UI_FONT
	;
	push	ax, bx
	mov	ax, ATTR_FONT_CONTROL_INCLUDE_UI_FONT
	clr	dh				;dh <- no UI font
	call	ObjVarFindData
	jnc	noUIFont
	dec	dh				;dh <- include UI font
noUIFont:
	pop	ax, bx

	;
	; Any option in the geos.ini file to specify the toolbox list?
	;
	mov	di, offset fonttoolKey		;cs:di <- name of key
	mov	bp, offset FontToolList		;^lbx:bp <- OD of parent list
	call	CreateCustomFontMenu		;custom font menu?
	jnc	noToolboxList			;branch if built

	mov	dl, mask FEF_OUTLINES or \
		    mask FEF_USEFUL or \
		    mask FEF_ALPHABETIZE
	mov	cx, MAX_LONG_LIST_FONTS
	mov	si, offset FontToolList		;^lbx:si <- OD of list
	call	FontCreateList
noToolboxList:
	ret

FontControlTweakDuplicatedToolboxUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontControlAddToGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add this object to the GCNSLT_FONT_CHANGES list
	

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
PASS:		*ds:si	= FontControlClass object
		ds:di	= FontControlClass instance data
		ds:bx	= FontControlClass object (same as *ds:si)
		es 	= segment of FontControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:
	Add obj to GCNSLT_FONT_CONTROL_CHANGES so it will
		update when fonts are added or removed.


PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontControlAddToGCNLists	method dynamic FontControlClass, 
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		.enter
	;	
	; First call our superclass
	;
		mov	di, offset FontControlClass
		call	ObjCallSuperNoLock
	;
	; Add ourselves to the global GCN list
	;
		mov	ax, GCNSLT_FONT_CHANGES
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	GCNListAdd

		.leave
		ret
FontControlAddToGCNLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontControlRemoveFromGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove self from font change notification list

CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
PASS:		*ds:si	= FontControlClass object
		ds:di	= FontControlClass instance data
		ds:bx	= FontControlClass object (same as *ds:si)
		es 	= segment of FontControlClass
		ax	= message #
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontControlRemoveFromGCNLists	method dynamic FontControlClass, 
				MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS,
				MSG_META_DETACH

		mov	di, offset FontControlClass
		call	ObjCallSuperNoLock
	;
	; Remove ourselves from the font GCN list
	;
		mov	ax, GCNSLT_FONT_CHANGES
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	GCNListRemove
		ret
		
FontControlRemoveFromGCNLists	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontControlHandleNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In general to deal with
		MSG_META_NOTIFY_WITH_DATA_BLOCK
		In particular to rebuild the ui when GWNT_FONTS_ADDED,
		GWNT_FONTS_DELETED messages are sent

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK
PASS:		*ds:si	= FontControlClass object
		ds:di	= FontControlClass instance data
		ds:bx	= FontControlClass object (same as *ds:si)
		es 	= segment of FontControlClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FontControlHandleNotify	method dynamic FontControlClass, 
					MSG_META_NOTIFY_WITH_DATA_BLOCK
	uses	ax, cx, dx, bp
	.enter

	; first see if it is a mesage we want to deal with
	;
	cmp	dx,GWNT_FONTS_ADDED
	je	testManufacturer
	cmp	dx,GWNT_FONTS_DELETED
	je	testManufacturer
	jmp 	cont
testManufacturer:
	cmp	cx,MANUFACTURER_ID_GEOWORKS
	jne	cont
	
	; for now if a font was added or removed just update the
	; entire list
	;
	mov	ax,MSG_GEN_CONTROL_REBUILD_NORMAL_UI
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GEN_CONTROL_REBUILD_TOOLBOX_UI
	call	ObjCallInstanceNoLock
cont:
	;
	; last call superclass
	;
	mov	di, offset FontControlClass
	call	ObjCallSuperNoLock
	.leave
	ret
FontControlHandleNotify	endm


TextControlInit ends


endif		; not NO_CONTROLLERS





















