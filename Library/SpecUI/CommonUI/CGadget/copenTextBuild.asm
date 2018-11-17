COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1995.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CGadget
FILE:		copenTextBuild.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_INITIALIZE     Initialize an OpenLook text display object.

    INT MapAndStoreEditableTextFont 
				Replaces the text object's font with the
				EditableFont stored in dgroup for the given
				object.

    INT SetCharParaAttrsFromHints 
				Sets character and paragraph attributes.
				Various hints cause storageFlags to be
				turned on or off, and all cause a word to
				be stored in VTI_paraAttrRuns or
				VTI_charAttrRuns.

    GLB SetTextMargins          Sets the text margins for editable text.

    INT TranslateGenericFonts   Translates generic font labels to actual
				fonts.  If a real font and size is
				specified, leaves it alone.

    MTD MSG_OL_PLACE_IN_VIEW    Causes text object to no longer appear on
				its visual parent, but instead, to appear
				inside of a view.  This operation is
				essentially a SPEC_BUILD operation.

    MTD MSG_SPEC_BUILD          Create the visual display of this specific
				object.

    INT TextMakeDefaultFocus    Create the visual display of this specific
				object.

    INT TextGeneralConsumerMode Create the visual display of this specific
				object.

    INT TextNeverMakeScrollable Create the visual display of this specific
				object.

    INT TextAlpha               Create the visual display of this specific
				object.

    INT TextUppercase           Create the visual display of this specific
				object.

    INT TextNumeric             Create the visual display of this specific
				object.

    INT TextSignedNumeric       Create the visual display of this specific
				object.

    INT TextSignedDecimal       Create the visual display of this specific
				object.

    INT TextFloatDecimal        Create the visual display of this specific
				object.

    INT TextAlphaNumeric        Create the visual display of this specific
				object.

    INT TextLegalFilenames      Create the visual display of this specific
				object.

    INT TextLegalDosFilenames   Create the visual display of this specific
				object.

    INT TextLegalDosVolumeNames Create the visual display of this specific
				object.

    INT TextLegalDosPath        Create the visual display of this specific
				object.

    INT TextDate                Create the visual display of this specific
				object.

    INT TextTime                Create the visual display of this specific
				object.

    INT TextDashedAlphaNumeric  Create the visual display of this specific
				object.

    INT TextAllowColumnBreaks   Create the visual display of this specific
				object.

    INT TextNoSpaces            Create the visual display of this specific
				object.

    INT TextAllowSpaces         Create the visual display of this specific
				object.

    INT TextNormalAscii         Create the visual display of this specific
				object.

    INT TextDosCharacterSet     Create the visual display of this specific
				object.

    INT TextWhiteWashColor      Create the visual display of this specific
				object.

    INT TextWashColor           Create the visual display of this specific
				object.

    INT TextRunsItemGroup       Create the visual display of this specific
				object.

    INT TextFrame               Create the visual display of this specific
				object.

    INT SetItemGroupDestAndStatusMsg 
				Sets up destination and status message of
				item group, so it will be sent back to us.

    INT ObjMsgCall              Sets up destination and status message of
				item group, so it will be sent back to us.

    INT SetupDelayedMode        Sets up delayed mode status for the object.

    INT TextProperty            Sets up delayed mode status for the object.

    INT TextNotProperty         Sets up delayed mode status for the object.

    INT TextAutoHyphenate       Allow auto hyphenation in the text object.

    INT TextSelectText          Select the text...

    INT TextCursorAtStart       Position the cursor at the start of the
				text.

    INT TextCursorAtEnd         Position the cursor at the end of the text.

    GLB TextAllowSmartQuotes    Allow smart quotes in this object

    GLB TextAllowUndo           Allow smart quotes in this object

    INT TextDoNotUseMoniker     Handles DO_NOT_USE_MONIKER hint for
				OLTextClass.

    INT SetDefaultBGColor       Set the default background color based on
				the position of the text object.

    MTD MSG_SPEC_SCAN_GEOMETRY_HINTS 
				Scans geometry hints.

    INT TextExpandWidth         Scans geometry hints.

    INT TextExpandHeight        Scans geometry hints.

    INT RemoveComposite         Removes composite from the picture before
				building a view.

    MTD MSG_SPEC_UNBUILD        Make sure text object releases focus &
				exclusive grabs, since text object is being
				visually unbuilt. Then do see if we need to
				set an associated view or composite as
				well.

    MTD MSG_SPEC_SET_NOT_USABLE Handles being set not usable.

    INT CreateView              If not already created, create a generic
				view & content object for text to appear
				in.  Initialize them.

    INT SetMinMaxSizeHints      Sets minimum and maximum size hints on the
				view, if needed.

    INT AddArgsToSizeHint       Adds arguments to size hint, if needed.
				Any non-zero width or height will be added
				as a size argument if there isn't something
				already specified in a hint.

    INT CreateComposite         If not already created, create a generic
				interaction for text to appear in.
				Initialize it.

    MTD MSG_SPEC_GET_SPECIFIC_VIS_OBJECT 
				Returns specific object used for this
				generic object.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of copenText.asm

DESCRIPTION:

	Implementation of the SPUI text display class (OLTextClass).

	$Id: copenTextBuild.asm,v 1.2 98/03/11 05:51:46 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetBuild segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize an OpenLook text display object.

CALLED BY:	via MSG_META_INITIALIZE.
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_META_INITIALIZE.
RETURN:		nothing
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
	Build the visual instance.
	    - Use the user specified state block, if one exists.
	    - Translate generic fonts into specific font ids and point sizes.
	    - Mark object as needing recalculation, so that when it is realized
	      it will get word-wrapped correctly.
	    - Copy flags from generic attributes into visual instance flags.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTextInitialize	method dynamic OLTextClass, MSG_META_INITIALIZE
						; Make sure vis built out

EC <	call	ECCheckGenTextObject				>

	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]			;
	mov	bx, di				;
	add	di, ds:[di].Gen_offset		; get ptr to Generic data
	add	bx, ds:[bx].Vis_offset		; get ptr to Vis, VisTextIns.

	; copy OD from Gen to Vis

	movdw	ds:[bx].VTI_output, ds:[di].GTXI_destination, ax
	;
	; Need a text chunk handle.
	;
	mov	ax, ds:[di].GTXI_text		; Get handle of text
	tst	ax				; See if null handle
	je	OLTDI_noTextSpecified		; if not, don't need to set up.
	push	ax				; Save users text.
	mov	ax, ds:[bx].VTI_text		; get allocated null chunk
	tst	ax				;
	jz	OLTDI_noTextAllocd		; skip if doesn't exist
	call	LMemFree			; else free it.
	mov	di, ds:[si]			;
	mov	bx, di				;
	add	di, ds:[di].Gen_offset		; get ptr to Generic data
	add	bx, ds:[bx].Vis_offset		; get ptr to Vis, VisTextIns.
OLTDI_noTextAllocd:				;
	pop	ax				; & replace:
	mov	ds:[bx].VTI_text, ax		; Store chunk of text
	jmp	common

OLTDI_noTextSpecified:				;
	call	ObjMarkDirty

common:
	mov	ax, ds:[bx].VTI_text		; Copy text handle into gen
	mov	ds:[di].GTXI_text, ax		;   instance, in case none was
						;   specified by the user.
	mov	di, ds:[si]			;
	mov	bx, di				;
	add	di, ds:[di].Gen_offset		; get ptr to Generic data
	add	bx, ds:[bx].Vis_offset		; get ptr to Vis, VisTextIns.

	;
	; Init the margins.   Non-editable text needs no margins.
	;
if DRAW_STYLES
	;
	; always have a gutter for draw styles
	;
	mov	ds:[bx].VTI_lrMargin, 1
	mov	ds:[bx].VTI_tbMargin, 1
else
	mov	ds:[bx].VTI_lrMargin, 0
	mov	ds:[bx].VTI_tbMargin, 0
endif

	;
	; Init the rest of the thing.
	;
	mov	ax, ds:[di].GTXI_maxLength	; Copy the max length
	mov	ds:[bx].VTI_maxLength, ax	;

	test	ds:[di].GI_attrs, mask GA_TARGETABLE
	jz	notTargetable
	ornf	ds:[bx].VTI_state, mask VTS_TARGETABLE
notTargetable:

	;
	; Now initialize the flags and attributes in the visual object.
	; Definitely not editable (this is a display object).
	; Default to not selectable, unless otherwise specified.
	; These will be set in the SpecBuild.
	;
	and	ds:[bx].VTI_state, not (mask VTS_EDITABLE or \
					mask VTS_SELECTABLE)
	;
	; Mark as using standard move/resize.
	;
	or	ds:[bx].VI_geoAttrs, mask VGA_USE_VIS_SET_POSITION

	;
	; Check for single line display, and if so, OR that bit into the
	; text-state flags for the vis instance.
	;
	mov	al, ds:[di].GTXI_attrs
	test	al, mask GTA_SINGLE_LINE_TEXT
	jz	notOneLine		;
	or	ds:[bx].VTI_state, mask VTS_ONE_LINE
	
notOneLine:

	;
	; Use 50% pattern if initially indeterminate.
	;
	test	ds:[di].GTXI_stateFlags, mask GTSF_INDETERMINATE
	jz	notIndeterminate
	or	ds:[bx].VTI_features, mask VTF_USE_50_PCT_TEXT_MASK	
notIndeterminate:

	;
	; Check for no word-wrap, and if so, OR that bit into the
	; text-state flags for the vis instance.
	;
	test	al, mask GTA_NO_WORD_WRAPPING
	jz	OLTDI_wordWrap
	ornf	ds:[bx].VTI_features, mask VTF_NO_WORD_WRAPPING
OLTDI_wordWrap:					;

if DRAW_STYLES
	;
	; default draw style - flat
	;
	andnf	ds:[bx].OLTDI_moreState, not mask TDSS_DRAW_STYLE
if (DS_FLAT ne 0)
	ornf	ds:[bx].OLTDI_moreState, DS_FLAT shl offset TDSS_DRAW_STYLE
endif
	;
	; default to framed if scrolling
	;
	test	ds:[di].GTXI_attrs, mask GTA_INIT_SCROLLING
	jz	notScrolling
	call	SetTextMargins
notScrolling:
endif
						
	; copy vardata stuff if it exists

	mov	ax, ATTR_GEN_TEXT_DOES_NOT_ACCEPT_INK
	mov	di, ATTR_VIS_TEXT_DOES_NOT_ACCEPT_INK
	call	copyVarData
	mov	ax, ATTR_GEN_TEXT_CUSTOM_FILTER
	mov	di, ATTR_VIS_TEXT_CUSTOM_FILTER
	call	copyVarData
	mov	ax,ATTR_GEN_TEXT_SEND_CONTEXT_NOTIFICATIONS_EVEN_IF_NOT_FOCUSED
	mov	di,ATTR_VIS_TEXT_SEND_CONTEXT_NOTIFICATIONS_EVEN_IF_NOT_FOCUSED
	call	copyVarData
	mov	ax, ATTR_GEN_TEXT_TYPE_RUNS
	mov	di, ATTR_VIS_TEXT_TYPE_RUNS
	call	copyVarData
	mov	ax, ATTR_GEN_TEXT_GRAPHIC_RUNS
	mov	di, ATTR_VIS_TEXT_GRAPHIC_RUNS
	call	copyVarData
	mov	ax, ATTR_GEN_TEXT_STYLE_ARRAY
	mov	di, ATTR_VIS_TEXT_STYLE_ARRAY
	call	copyVarData
	mov	ax, ATTR_GEN_TEXT_NAME_ARRAY
	mov	di, ATTR_VIS_TEXT_NAME_ARRAY
	call	copyVarData
	mov	ax, ATTR_GEN_TEXT_EXTENDED_FILTER
	mov	di, ATTR_VIS_TEXT_EXTENDED_FILTER
	call	copyVarData
	mov	ax, ATTR_GEN_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL
	mov	di, ATTR_VIS_TEXT_DO_NOT_INTERACT_WITH_SEARCH_CONTROL
	call	copyVarData
	
	mov	ax, ATTR_GEN_TEXT_DONT_BEEP_ON_INSERTION_ERROR
	mov	di, ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR
	call	copyVarData

	mov	ax, ATTR_GEN_TEXT_CURSOR_NO_FOCUS
	mov	di, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	copyVarData
if PZ_PCGEOS
	mov	ax, ATTR_GEN_TEXT_NO_FEP
	mov	di, ATTR_VIS_TEXT_NO_FEP
	call	copyVarData
endif

	mov	ax, ATTR_GEN_TEXT_NO_CURSOR
	mov	di, ATTR_VIS_TEXT_NO_CURSOR
	call	copyVarData

if DBCS_PCGEOS
	mov	ax, ATTR_GEN_TEXT_ALLOW_FULLWIDTH_DIGITS
	mov	di, ATTR_VIS_TEXT_ALLOW_FULLWIDTH_DIGITS
	call	copyVarData
endif

	mov	ax, ATTR_GEN_TEXT_TYPE_RUNS
	mov	di, offset VTI_storageFlags
	mov	cl, mask VTSF_TYPES
	call	setStorageFlag

	mov	ax, ATTR_GEN_TEXT_GRAPHIC_RUNS
	mov	cl, mask VTSF_GRAPHICS
	call	setStorageFlag

	mov	ax, ATTR_GEN_TEXT_STYLE_ARRAY
	mov	cl, mask VTSF_STYLES
	call	setStorageFlag

	call	SetCharParaAttrsFromHints
	; Returns cl = non-zero if char attrs modified by hints,
	;         ch = non-zero if para attrs modified by hints

OLTDI_handleEditable:
	;
	; If not read-only, let's set up all the editable stuff that needs
	; setting up. 
	;
	mov	di, ds:[si]		
	mov	bx, di	
	add	di, ds:[di].Gen_offset
	add	bx, ds:[bx].Vis_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jnz	exit				;is read only, done.

	;
	; See if we are supposed to change the font since this is an
	; editable instance of a text object (JimG - 3/8/94)
	;
	tst	cl				; Char attrs modified by hints?
	jnz	noEditableText			; Yes, skip this completely.
	
	mov	ax, segment dgroup
	mov	es, ax
	tst	es:[editableTextFontID]		; Editable font specified?
	jz	noEditableText			; No, skip this.
	
	call	MapAndStoreEditableTextFont
	
	; bx, di pointer MAY BE INVALID at this point, but
	; SetTextMargins will redereference these points first thing.
	
noEditableText:
	call	SetTextMargins

	;
	; Make editable and selectable.
	;
	or	ds:[bx].VTI_state, mask VTS_SELECTABLE or \
				    mask VTS_EDITABLE
	or	ds:[bx].OLTDI_moreState, mask TDSS_SELECTABLE

if DRAW_STYLES
	;
	; default draw style for editable - 3D lowered
	;
	andnf	ds:[bx].OLTDI_moreState, not mask TDSS_DRAW_STYLE
	ornf	ds:[bx].OLTDI_moreState, DS_LOWERED shl offset TDSS_DRAW_STYLE
endif

	mov	di, ds:[si]			
	add	di, ds:[di].OLText_offset	
	ornf	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	mov	di, ds:[si]			;
	add	di, ds:[di].Gen_offset		; ds:di <- ptr to gen instance.

	test	ds:[di].GTXI_attrs, mask GTA_USE_TAB_FOR_NAVIGATION
	jz	exit				; tabs don't navigate, branch
	;

; Else we'll filter TAB's.
	;
	or	ds:[bx].VTI_filters, mask VTF_NO_TABS

exit:
	ret					; <-- RETURN

	; very local subroutines.
copyVarData:

	call	ObjVarFindData
	jnc	doesNotExist
	mov	dx, ds:[bx]
	mov	cx, size word
	mov_tr	ax, di
	call	ObjVarAddData
	mov	ds:[bx], dx
doesNotExist:
	retn

setStorageFlag:
	; ax = hint, cl = VTSF_...bit to set, di = vis byte flag to set

	push	bx
	call	ObjVarFindData
	jnc	10$
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Vis_offset
	add	bx, di				; use bx instead of di to store
	or	{byte} ds:[bx], cl		;	(preserves di)
10$:
	pop	bx
	retn

OLTextInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapAndStoreEditableTextFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the text object's font with the EditableFont
		stored in dgroup for the given object.

CALLED BY:	OLTextInitialize
PASS:		*ds:si	- instance pointer
		ds:bx	- pointer to Vis instance data

RETURN:		nothing
DESTROYED:	es, di, ax, bx, cx, dx
SIDE EFFECTS:	
    
    WARNING:  This routine MAY resize LMem and/or object blocks, moving
	      them on the heap and invalidating stored segment pointers
	      to them.

PSEUDO CODE/STRATEGY:
	Get a default CharAttr, and then fill in our info.  Then
	attempt to map it back to a VisTextDefaultCharAttr if possible.
	It will then replace VTI_charAttrRuns for that object.  This
	may have to allocate storage if the font does not fit the
	profile of a VisTextDefaultCharAttr, or remove previously allocated
	storage if it is a default, but the previous font was not.
	All allocation/freeing is done within the object's memory block.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapAndStoreEditableTextFont	proc	near
	class	VisTextClass
charAttr	local	VisTextCharAttr
	uses	ds,si
	.enter
	
	; load segment of dgroup into es
	mov	ax, segment dgroup
	mov	es, ax
	
	; Get default char attrs
	push	bp
	mov	ax, VIS_TEXT_INITIAL_CHAR_ATTR
	lea	bp, ss:[charAttr]
	call	TextMapDefaultCharAttr
	pop	bp
	
	; Stuff in our data
	mov	cx, es:[editableTextFontsize]
	mov	ss:[charAttr].VTCA_pointSize.WBF_int, cx
	clr	ss:[charAttr].VTCA_pointSize.WBF_frac
	mov	cx, es:[editableTextFontID]
	mov	ss:[charAttr].VTCA_fontID, cx
	
	; Try to map to a DefaultCharAttr
	; If carry was set then the return value is a defaultcharattr.
	push	bp
	lea	bp, ss:[charAttr]
	call	TextFindDefaultCharAttr		; ax <- VisTextDefaultCharAttr
	pop	bp
	jnc	notDefaultCharAttr
	
	; This mapped to a DefaultCharAttr.  Store the new CharAttr
	xchg	ax, ds:[bx].VTI_charAttrRuns
	test	ds:[bx].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR
	jnz	done				; do not have to free anything
	
	; Free the old VisTextCharAttr
	ornf	ds:[bx].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR
	call	LMemFree			; ds = seg, ax = handle
	jmp	done

	; Okay, this did not map to a DefaultCharAttr, so we have to
	; store a VisTextCharAttr structure in the object.  If one
	; already existed, we'll just use it, otherwise, we'll
	; allocate our own.
notDefaultCharAttr:
	test	ds:[bx].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR
	jz	fillCharAttr
	
	; Allocate a new lmem
	mov	al, mask OCF_IGNORE_DIRTY
	mov	cx, size VisTextCharAttr
	call	LMemAlloc
	
	; Redereference VIS instance data
	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	mov	ds:[bx].VTI_charAttrRuns, ax
	andnf	ds:[bx].VTI_storageFlags, not mask VTSF_DEFAULT_CHAR_ATTR
	
	; Fill the char attr with our local copy
fillCharAttr:
	segmov	es, ds, cx
	mov	si, ds:[bx].VTI_charAttrRuns
	mov	di, ds:[si]			; es:di = destination
	segmov	ds, ss, cx
	lea	si, ss:[charAttr]		; ds:si = source
	
    CheckHack < ((size VisTextCharAttr) / 2) * 2 eq (size VisTextCharAttr)>>
	mov	cx, (size VisTextCharAttr)/2
	rep	movsw
	
done:
	.leave
	ret
MapAndStoreEditableTextFont	endp





COMMENT @----------------------------------------------------------------------

ROUTINE:	SetCharParaAttrsFromHints

SYNOPSIS:	Sets character and paragraph attributes.  Various hints
		cause storageFlags to be turned on or off, and all cause
		a word to be stored in VTI_paraAttrRuns or VTI_charAttrRuns.

CALLED BY:	OLTextInitialize

PASS:		*ds:si -- object

RETURN:		cl	- Non-zero if char attrs changed, zero otherwise
		ch	- Non-zero if para attrs changed, zero otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/ 8/92		Initial version
	JimG	3/14/94		Added return values, cl & ch.

------------------------------------------------------------------------------@

SetCharParaAttrsFromHints	proc	near		
	clr	cx				; clear char & para attr
						; changed flags
EC <	call	ECCheckGenTextObject				>

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	;
	; Multiple char attr runs, set multiple bit, clear default bit, and
	; store in VTI_charAttrRuns.
	;
	mov	ax, ATTR_GEN_TEXT_MULTIPLE_CHAR_ATTR_RUNS
	call	ObjVarFindData
	jnc	10$

	or	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS
	jmp	short notDefaultCharAttr
10$:
	;
	; Single char attr run, clear default bit, and 
	; store in VTI_charAttrRuns.
	;
	mov	ax, ATTR_GEN_TEXT_CHAR_ATTR
	call	ObjVarFindData
	jnc	20$

notDefaultCharAttr:
	and	ds:[di].VTI_storageFlags, not mask VTSF_DEFAULT_CHAR_ATTR
	jmp	short copyCharAttr

20$:
	;
	; Default char attr run, store in VTI_charAttrRuns.
	;
	mov	ax, ATTR_GEN_TEXT_DEFAULT_CHAR_ATTR
	call	ObjVarFindData
	jnc	30$

	;
	; Make as default in the event VisTextInitialize thought it wasn't
	;
	ornf	ds:[di].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR

copyCharAttr:
	mov	ax, {word} ds:[bx]
	mov	ds:[di].VTI_charAttrRuns, ax
	not	cl				; set flag - char attr changed

30$:
	;
	; Multiple para attr runs, set multiple bit, clear default bit, and
	; store in VTI_paraAttrRuns.
	;
	mov	ax, ATTR_GEN_TEXT_MULTIPLE_PARA_ATTR_RUNS
	call	ObjVarFindData
	jnc	40$
	or	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_PARA_ATTRS
	jmp	short notDefaultParaAttr
40$:
	;
	; Single para attr run, clear default bit, and 
	; store in VTI_paraAttrRuns.
	;
	mov	ax, ATTR_GEN_TEXT_PARA_ATTR
	call	ObjVarFindData
	jnc	50$

notDefaultParaAttr:
	and	ds:[di].VTI_storageFlags, not mask VTSF_DEFAULT_PARA_ATTR
	jmp	short copyParaAttr
50$:
	;
	; Single para attr run, clear default bit, and 
	; store in VTI_paraAttrRuns.
	;
	mov	ax, ATTR_GEN_TEXT_DEFAULT_PARA_ATTR
	call	ObjVarFindData
	jnc	60$

copyParaAttr:
	mov	ax, {word} ds:[bx]
	mov	ds:[di].VTI_paraAttrRuns, ax
	not	ch				; set flag - para attr changed
60$:
	ret
SetCharParaAttrsFromHints	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text margins for editable text.

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
RETURN:		ds:di -- Gen instance
		ds:bx -- Vis instance
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTextMargins	proc	far
	.enter


EC <	call	ECCheckGenTextObject				>

	mov	bx, ds:[si]			; ds:bx <- ptr to vis instance.
	mov	di, bx
	add	bx, ds:[bx].Vis_offset		;
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance

	;
	; In motif, editable text is always in a frame;  in open look, only if
	; it's not one-line text.  Open look one-line editable objects will
	; have a top/bottom margin, to make room for an underline.  
	;

if (not _DUI)				; don't make larger on DUI
	call	SysGetPenMode
	tst	ax
	jz	5$			;Use PEN_FRAME_TEXT_MARGIN if we are
					; in pen mode and this is a single
					; line text edit object.  May be 
					; overriden by code in SPEC_BUILD.

	test	ds:[di].GTXI_attrs, mask GTA_SINGLE_LINE_TEXT
	jz	5$
	mov	ax, HINT_TEXT_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS
	push	bx
	call	ObjVarFindData
	pop	bx
	mov	al, PEN_FRAME_TEXT_MARGIN
	jnc	7$
5$:
endif ; (not _DUI)
	mov	al, FRAME_TEXT_MARGIN		
	call	OpenCheckIfCGA			;smaller in CGA 11/18/92 cbh
	jnc	7$

if	((FRAME_TEXT_MARGIN - CGA_FRAME_TEXT_MARGIN) eq 1)
	dec	al
else
	mov	al, CGA_FRAME_TEXT_MARGIN
endif

7$:
	mov	ds:[bx].VTI_tbMargin, al
CUAS <	mov	ds:[bx].VTI_lrMargin, FRAME_TEXT_MARGIN			     >

OLS <	test	ds:[di].GTXI_attrs, mask GTA_SINGLE_LINE_TEXT		     >
OLS <	jnz	10$				; single line, no frame      >
OLS <	mov	ds:[bx].VTI_lrMargin, CHISELED_FRAME_TEXT_MARGIN	     >
OLS <	mov	ds:[bx].VTI_tbMargin, CHISELED_FRAME_TEXT_MARGIN	     >

	mov	di, ds:[si]			; ds:di <- ptr to specific.  
	add	di, ds:[di].OLText_offset
	ornf	ds:[di].OLTDI_specState, mask TDSS_IN_FRAME 

OLS < 10$:								     >
	.leave
	ret
SetTextMargins	endp



GadgetBuild ends
GadgetBuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextPlaceInView -- MSG_OL_PLACE_IN_VIEW
			for OLTextClass

DESCRIPTION:	Causes text object to no longer appear on its visual
		parent, but instead, to appear inside of a view.  This
		operation is essentially a SPEC_BUILD operation.

PASS:
	*ds:si - instance data
	es - segment of OLTextClass

	ax - MSG_OL_PLACE_IN_VIEW

	cx	- ?
	dx	- ?
	bp	- ?

RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Doug	9/89		Redone for new spec build methodology

------------------------------------------------------------------------------@

OLTextPlaceInView	method dynamic OLTextClass, \
				MSG_OL_PLACE_IN_VIEW

EC <	call	ECCheckGenTextObject				>
EC <	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW		>
EC <	ERROR_NZ	OL_ERROR					>

	;
	; First, remove the gadget exclusive until we can get the text object
	; into the view.
	;
	mov	dx, si				;pass OD
	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL	;release the gadget exclusive
	call	VisCallParent			;while parent comp is destroyed
	;
	; If we currently have the focus, we'll set a bit to tell us to 
	; restore the gadget exclusive to the text object when everything is
	; re-built.  Hopefully VTISF_IS_FOCUS will correspond to when we have
	; the focus.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- VisInstance
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS	
	jz	10$				;doesn't have focus, branch
	or	ds:[di].OLTDI_specState, mask TDSS_NEEDS_GADGET_EXCL	
	call	MetaReleaseFocusExclLow		;release the focus

10$:
	;
	; Next, visually close down the text object, if it is realized
	;
	call	VisSetNotRealized

	;	
	; And clear out the area behind it, as per MSG_SPEC_SET_NOT_USABLE
	; handler, so that invalidations happen correctly.
	;
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	
	; THEN, Tear out of visual tree...
	
	mov	cx, ds:[LMBH_handle]		;
	mov	dx, si				;
	clr	bp				; No need to make dirty
	mov	ax, MSG_VIS_REMOVE_CHILD	; (will be removed next time)
	call	VisCallParent			;
						;
	;
	; so that we can rebuild it inside the view.
	;
						; Request to be placed in view
	mov	di, ds:[si]			;
	add	di, ds:[di].Gen_offset		;
	or	ds:[di].GTXI_attrs, mask GTA_INIT_SCROLLING
						; DO VIS BUILD to get it there.
	clr	bp				; Not a tree build.
	call	VisSendSpecBuild		; set up enabled flag & do the 
						;   spec build
	;
	; Let's make the effort to do an update now. It didn't get done
	; elsewhere.
	;
	mov	cl, mask VOF_GEOMETRY_INVALID	; mark the thing invalid
	mov	dl, VUM_NOW			;
	mov	ax, MSG_VIS_MARK_INVALID		;
	call	GenCallParent			; should cause some ruckus
						;
	mov	ax, MSG_VIS_RECREATE_CACHED_GSTATES
						; Force text object to redefine
	call	ObjCallInstanceNoLock		;  it's gstate since it is now
						;  in a window.
OLTDPIV_Done:					;
	ret					;
OLTextPlaceInView	endm

GadgetBuild ends
Build segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the visual display of this specific object.

CALLED BY:	External.
PASS:		ds:*si = instance.
		ax = MSG_SPEC_BUILD.
		bp = VisBulidFlags
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:
	If not yet vis built {
		if currently IN_VIEW, or marked as INIT_SCROLLING {
			Build view, & spec build it;
		} else do standard spec build;
		Set colors for text object;
		Scan hints, to set focus stuff;
	}


	A few comments about the visual building of the text object:
First, if the text object is not in a view, the spec build proceeds in the
straight default fashion.  IF, however, the text object should appear in
a view,  then we do some gymnastics.  What we do is this:  We create a
GenView possessing a GenContent, & attach it generically (upward link only?)
alongside the gen text object.  We then create the visual tree for the text
object by visibly building the view & adding the text object to the content
object, visually.  This leaves the text object generically in the same place,
while yielding a visual tree in which the text object is in a view.  Since
all other visual methods beside SPEC_BUILD travel along the visible tree,
this arrangement should work, with geometry & image methods proceeding with
the new visible tree.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

NOTE:	The GenView is currently generically attached w/full linkage.  This
	makes it somewhat easier to spec build, although this may be considered
	somewhat unclean as far as the generic world goes.  We may want to
	change this.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/13/89		Initial version
	doug	9/22/89		New, revised spec build methodology

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLTextSpecBuild	method dynamic OLTextClass, MSG_SPEC_BUILD

EC <	call	ECCheckGenTextObject				>

	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jz	noKeyboard
	call	CheckIfKeyboardRequired
	jnc	noKeyboard

if _DUI
	;
	; set keyboard type before bringing it up
	;
	call	SetKeyboardType
endif
	push	bp
	mov	ax, MSG_SPEC_GUP_QUERY
	mov	cx, SGQT_BRING_UP_KEYBOARD
	call	GenCallParent
	pop	bp
noKeyboard:
	call	VisCheckIfSpecBuilt		; Check for already vis-built.
						;
	jnc	10$				;
	jmp	OLTDVB_Done			; quit if so.
10$:						;
	call	VisSpecBuildSetEnabledState	; make sure this happens.
	segmov	es, cs				; setup es:di to be ptr to
						; Hint handler table
	call	SetDefaultBGColor		; Set colors (pass cx)
	
	mov	di, offset cs:MkrVarDataHandler
	mov	ax, length (cs:MkrVarDataHandler)
	call	OpenScanVarData			; 

	;
	; Check for no-frame. (kept out of main hint handlers, so this will
	; take precedence over other hints)  -cbh 2/ 1/93
	;
if DRAW_STYLES
	;
	; disallow frame for 3d text displays (from PL96.380)
	;
	call	Build_DerefVisSpecDI
	mov	ax, ds:[di].OLTDI_moreState
	andnf	ax, mask TDSS_DRAW_STYLE
.assert (DS_FLAT eq 0)
	jz	allowFrame
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jz	frameOff			; 3d display, frame off
allowFrame:
endif
	mov	ax, HINT_TEXT_NO_FRAME
	call	ObjVarFindData
	jnc	12$
	call	Build_DerefVisSpecDI
frameOff::
	and	ds:[di].OLTDI_specState, not mask TDSS_IN_FRAME
if DRAW_STYLES
	;
	; undo frame margins also, ensuring we always have a gutter
	;
	mov	ds:[di].VTI_lrMargin, 1
	mov	ds:[di].VTI_tbMargin, 1
endif
12$:
	;
	; Setup geometry stuff.
	;	
	call	OLTextScanGeometryHints

	;
	; Check for already in a view.
	;
	call	Build_DerefVisSpecDI

if TEXT_DISPLAY_FOCUSABLE
	;
	; make room in margins for focus indicator, if non-editable
	; (editable shows focus with cursor) and focusable-text-display
	; hint present
	;
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jnz	notDisplay
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	notDisplay
	tst	ds:[di].VTI_lrMargin
	jnz	haveGutter1
	inc	ds:[di].VTI_lrMargin	; no gutter yet, make space btwn
	inc	ds:[di].VTI_tbMargin	;	focus ring and text
haveGutter1:
if TEXT_DISPLAY_FOCUS_WIDTH eq 1
	inc	ds:[di].VTI_lrMargin
	inc	ds:[di].VTI_tbMargin
else
	add	ds:[di].VTI_lrMargin, TEXT_DISPLAY_FOCUS_WIDTH
	add	ds:[di].VTI_tbMargin, TEXT_DISPLAY_FOCUS_WIDTH
endif
notDisplay:
endif ; TEXT_DISPLAY_FOCUSABLE

if DRAW_STYLES
	;
	; make room for draw style insets (only for raised and lowered)
	;
	mov	ax, ds:[di].OLTDI_moreState
	andnf	ax, mask TDSS_DRAW_STYLE
	cmp	ax, DS_LOWERED shl offset TDSS_DRAW_STYLE
	je	addInset
	cmp	ax, DS_RAISED shl offset TDSS_DRAW_STYLE
	jne	noInset
addInset:
	tst	ds:[di].VTI_lrMargin
	jnz	haveGutter2
	inc	ds:[di].VTI_lrMargin	; no gutter yet, make space btwn
	inc	ds:[di].VTI_tbMargin	;	focus ring and text
haveGutter2:
if DRAW_STYLE_INSET_WIDTH eq 1
	inc	ds:[di].VTI_lrMargin
	inc	ds:[di].VTI_tbMargin
else
	add	ds:[di].VTI_lrMargin, DRAW_STYLE_INSET_WIDTH
	add	ds:[di].VTI_tbMargin, DRAW_STYLE_INSET_WIDTH
endif
noInset:
endif ; DRAW_STYLES

	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jnz	OLTDVB_InView			; branch if already in a view.
						;
	mov	di, ds:[si]			;
	add	di, ds:[di].Gen_offset		;
	;
	; Check for scrollbar desired.
	;
	test	ds:[di].GTXI_attrs, mask GTA_INIT_SCROLLING
	jnz	OLTDVB_InView			; yes, go put in view.
	;
	; Not a view object; let's see if we need to be in a composite.
	;
 	tst	ds:[di].GI_visMoniker		; see if there's a vis moniker	
 	jz	CheckMarginsNeeded		; nope, don't need comp, branch
 	
 	mov	di, ds:[si]			; point to instance
 	add	di, ds:[di].Vis_offset		; ds:[di] -- SpecInstance
	test	ds:[di].OLTDI_specState, mask TDSS_NO_MONIKER
	jnz	CheckMarginsNeeded		; no moniker, branch
	
 	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
 	jnz	CheckMarginsNeeded		; already in view, don't need
 						; a comp to display moniker
 						
PopIntoComposite:
	call	CreateComposite			; create composite to be in
						;    and build it.
	jmp	short OLTDVB_Misc		; continue on our way.
	
CheckMarginsNeeded:
	;
	; Do the vis-build for the object.
	;
	mov	di, offset OLTextClass
	mov	ax, segment OLTextClass
	mov	es, ax
	mov	ax, MSG_SPEC_BUILD
	CallSuper	MSG_SPEC_BUILD	; build it please.
	jmp	short OLTDVB_Misc		; & skip to misc stuff to
						; finish up with.
OLTDVB_InView:					;
	call	RemoveComposite			; remove composite, if there
						; bl holds margin flags now
	call	CreateView			; Ensure we have GenView,
						; GenContent objects inited
						; Vis build the sucker.
OLTDVB_Misc:					;
	call	SetupDelayedMode

	;Check for default action behavior

	mov	ax, MSG_OL_WIN_IS_DEFAULT_ACTION_NAVIGATE_TO_NEXT_FIELD
	call	CallOLWin			; carry set if so
	jnc	notNavigateToNextField
	call	Build_DerefVisSpecDI
	ornf	ds:[di].OLTDI_moreState, \
			mask TDSS_DEFAULT_ACTION_IS_NAVIGATE_TO_NEXT_FIELD
notNavigateToNextField:
	
checkSelectable:
	;
	; Make selectable if editable or an attribute is present.
	;
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	jz	OLTDVB_selectable

	mov	ax, ATTR_GEN_TEXT_SELECTABLE
	call	ObjVarFindData
	jnc	OLTDVB_notSelectable

OLTDVB_selectable:
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	jz	OLTDVB_notSelectable		; not enabled, not selectable.
	
	or	ds:[di].VTI_state, mask VTS_SELECTABLE
	or	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
OLTDVB_notSelectable:				;

	;
	; FINALLY, PROCESS HINTS.  The hints requesting that the window be
	; made the default focus or target are processed here, by generating
	; generic methods that are sent to this object.  (But not if the
	; object isn't selectable! -cbh 12/ 8/92)
	;
	mov	di, ds:[si]			;(deference, added 9/11/95 cbh)
	add	di, ds:[di].Vis_offset

	test	ds:[di].OLTDI_moreState, mask TDSS_SELECTABLE
	jz	OLTDVB_Done
	call	ScanFocusTargetHintHandlers

OLTDVB_Done:					;
	;
	; Mark the dialog box applyable if we're coming up modified, via
	; the queue, to ensure the dialog box is all set up.
	; -cbh 2/ 9/93
	;
	call 	Build_DerefGenDI
	test	ds:[di].GTXI_stateFlags, mask GTSF_MODIFIED
	jz	makeNotOverlapping
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

makeNotOverlapping:
	;
	; Set a flag in the OLCtrl that we can't be overlapping objects.
	; -cbh 2/22/93
	;
	call	OpenCheckIfBW				;not B/W, don't sweat
	jnc	exit
	call	SpecSetFlagsOnAllCtrlParents		;sets CANT_OVERLAP_KIDS
exit:

if	 BUBBLE_DIALOGS and (not (_DUI))
	; Look for OLDialogWinClass vis parent
	;	
	mov	cx, segment OLDialogWinClass
	mov	dx, offset OLDialogWinClass
	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock
	jnc	notABubble
	
	; We have such a parent.  Lock it down and look at its private parts
	; and check if it is a POPUP.
	;   Hack not for the squeamish.
	;
	push	si
	movdw	bxsi, cxdx
	call	ObjSwapLock
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLPWI_flags, mask OLPWF_IS_POPUP
	pushf
	call	ObjSwapUnlock
	popf
	pop	si
	jz	notABubble
	
	; Hey, we're a bubble!  Set the bit so we can check later.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLTDI_moreState, mask TDSS_WIN_IS_POPUP
	
notABubble:	
endif	;BUBBLE_DIALOGS and (not (_DUI))

	ret

OLTextSpecBuild	endm

if _GCM	;----------------------------------------------------------------------

MkrVarDataHandler	VarDataHandler \
 <HINT_DO_NOT_USE_MONIKER, offset TextDoNotUseMoniker>,
 <HINT_TEXT_AUTO_HYPHENATE, offset TextAutoHyphenate>,
 <HINT_TEXT_SELECT_TEXT, offset TextSelectText>,
 <HINT_TEXT_CURSOR_AT_START, offset TextCursorAtStart>,
 <HINT_TEXT_CURSOR_AT_END, offset TextCursorAtEnd>,
 <HINT_TEXT_ALLOW_SMART_QUOTES, offset TextAllowSmartQuotes>,
 <HINT_TEXT_ALLOW_UNDO, offset TextAllowUndo>,
 <ATTR_GEN_TEXT_ALPHA, offset TextAlpha>,
 <ATTR_GEN_TEXT_NUMERIC, offset TextNumeric>,
 <ATTR_GEN_TEXT_SIGNED_NUMERIC, offset TextSignedNumeric>,
 <ATTR_GEN_TEXT_SIGNED_DECIMAL, offset TextSignedDecimal>,
 <ATTR_GEN_TEXT_FLOAT_DECIMAL, offset TextFloatDecimal>,
 <ATTR_GEN_TEXT_ALPHA_NUMERIC, offset TextAlphaNumeric>,
 <ATTR_GEN_TEXT_LEGAL_FILENAMES, offset TextLegalFilenames>,
 <ATTR_GEN_TEXT_LEGAL_DOS_FILENAMES, offset TextLegalDosFilenames>,
 <ATTR_GEN_TEXT_LEGAL_DOS_PATH, offset TextLegalDosPath>,
 <ATTR_GEN_TEXT_NO_SPACES, offset TextNoSpaces>,
 <ATTR_GEN_TEXT_ALLOW_SPACES, offset TextAllowSpaces>,
 <HINT_TEXT_WASH_COLOR, offset TextWashColor>,
 <HINT_TEXT_WHITE_WASH_COLOR, offset TextWhiteWashColor>,
 <ATTR_GEN_TEXT_DATE, offset TextDate>,
 <ATTR_GEN_TEXT_TIME, offset TextTime>,
 <ATTR_GEN_TEXT_DASHED_ALPHA_NUMERIC, offset TextDashedAlphaNumeric>,
 <ATTR_GEN_TEXT_NORMAL_ASCII, offset TextNormalAscii>,
 <HINT_DEFAULT_FOCUS, offset TextMakeDefaultFocus>,
 <HINT_GENERAL_CONSUMER_MODE, offset TextGeneralConsumerMode>,
 <ATTR_GEN_TEXT_LEGAL_DOS_VOLUME_NAMES, offset TextLegalDosVolumeNames>,
 <ATTR_GEN_TEXT_DOS_CHARACTER_SET, offset TextDosCharacterSet>,
 <ATTR_GEN_TEXT_RUNS_ITEM_GROUP, offset TextRunsItemGroup>,
 <ATTR_GEN_TEXT_MAKE_UPPERCASE, offset TextUppercase>,
 <ATTR_GEN_TEXT_ALLOW_COLUMN_BREAKS, offset TextAllowColumnBreaks>,
 <ATTR_GEN_TEXT_NEVER_MAKE_SCROLLABLE, offset TextNeverMakeScrollable>,
 <HINT_TEXT_FRAME, offset TextFrame>

else	; not _GCM ------------------------------------------------------------

MkrVarDataHandler	VarDataHandler \
 <HINT_DO_NOT_USE_MONIKER, offset TextDoNotUseMoniker>,
 <HINT_TEXT_AUTO_HYPHENATE, offset TextAutoHyphenate>,
 <HINT_TEXT_SELECT_TEXT, offset TextSelectText>,
 <HINT_TEXT_CURSOR_AT_START, offset TextCursorAtStart>,
 <HINT_TEXT_CURSOR_AT_END, offset TextCursorAtEnd>,
 <HINT_TEXT_ALLOW_SMART_QUOTES, offset TextAllowSmartQuotes>,
 <HINT_TEXT_ALLOW_UNDO, offset TextAllowUndo>,
 <ATTR_GEN_TEXT_ALPHA, offset TextAlpha>,
 <ATTR_GEN_TEXT_NUMERIC, offset TextNumeric>,
 <ATTR_GEN_TEXT_SIGNED_NUMERIC, offset TextSignedNumeric>,
 <ATTR_GEN_TEXT_SIGNED_DECIMAL, offset TextSignedDecimal>,
 <ATTR_GEN_TEXT_FLOAT_DECIMAL, offset TextFloatDecimal>,
 <ATTR_GEN_TEXT_ALPHA_NUMERIC, offset TextAlphaNumeric>,
 <ATTR_GEN_TEXT_LEGAL_FILENAMES, offset TextLegalFilenames>,
 <ATTR_GEN_TEXT_LEGAL_DOS_FILENAMES, offset TextLegalDosFilenames>,
 <ATTR_GEN_TEXT_LEGAL_DOS_PATH, offset TextLegalDosPath>,
 <ATTR_GEN_TEXT_NO_SPACES, offset TextNoSpaces>,
 <ATTR_GEN_TEXT_ALLOW_SPACES, offset TextAllowSpaces>,
 <HINT_TEXT_WASH_COLOR, offset TextWashColor>,
 <HINT_TEXT_WHITE_WASH_COLOR, offset TextWhiteWashColor>,
 <ATTR_GEN_TEXT_DATE, offset TextDate>,
 <ATTR_GEN_TEXT_TIME, offset TextTime>,
 <ATTR_GEN_TEXT_DASHED_ALPHA_NUMERIC, offset TextDashedAlphaNumeric>,
 <ATTR_GEN_TEXT_NORMAL_ASCII, offset TextNormalAscii>,
 <HINT_DEFAULT_FOCUS, offset TextMakeDefaultFocus>,
 <ATTR_GEN_TEXT_LEGAL_DOS_VOLUME_NAMES, offset TextLegalDosVolumeNames>,
 <ATTR_GEN_TEXT_DOS_CHARACTER_SET, offset TextDosCharacterSet>,
 <ATTR_GEN_TEXT_RUNS_ITEM_GROUP, offset TextRunsItemGroup>,
 <ATTR_GEN_TEXT_MAKE_UPPERCASE, offset TextUppercase>,
 <ATTR_GEN_TEXT_ALLOW_COLUMN_BREAKS, offset TextAllowColumnBreaks>,
 <ATTR_GEN_TEXT_NEVER_MAKE_SCROLLABLE, offset TextNeverMakeScrollable>,
if TEXT_DISPLAY_FOCUSABLE
 <HINT_TEXT_DISPLAY_FOCUSABLE, offset TextDisplayFocusable>,
endif
if DRAW_STYLES
 <HINT_DRAW_STYLE_FLAT, offset TextDrawStyleFlat>,
 <HINT_DRAW_STYLE_3D_LOWERED, offset TextDrawStyleLowered>,
 <HINT_DRAW_STYLE_3D_RAISED, offset TextDrawStyleRaised>,
endif
 <HINT_TEXT_FRAME, offset TextFrame>

endif	; if _GCM -------------------------------------------------------------

;--------

if TEXT_DISPLAY_FOCUSABLE
TextDisplayFocusable	proc	far
	call	Build_DerefVisSpecDI
	ORNF	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	ret
TextDisplayFocusable	endp
endif

if DRAW_STYLES
TextDrawStyleFlat	proc	far
	mov	ax, DS_FLAT shl offset TDSS_DRAW_STYLE
	GOTO	DrawStyleCommon
TextDrawStyleFlat	endp

TextDrawStyleLowered	proc	far
	mov	ax, DS_LOWERED shl offset TDSS_DRAW_STYLE
	GOTO	DrawStyleCommon
TextDrawStyleLowered	endp

TextDrawStyleRaised	proc	far
	mov	ax, DS_RAISED shl offset TDSS_DRAW_STYLE
	FALL_THRU	DrawStyleCommon
TextDrawStyleRaised	endp

DrawStyleCommon	proc	far
	call	Build_DerefVisSpecDI
	andnf	ds:[di].OLTDI_moreState, not mask TDSS_DRAW_STYLE
	ornf	ds:[di].OLTDI_moreState, ax
	ret
DrawStyleCommon	endp
endif

TextMakeDefaultFocus	proc	far
	call	Build_DerefVisSpecDI
	ORNF	ds:[di].OLTDI_moreState, mask TDSS_MAKE_DEFAULT_FOCUS
	ret
TextMakeDefaultFocus	endp

if _GCM
TextGeneralConsumerMode	proc	far
	call	Build_DerefVisSpecDI
	ORNF	ds:[di].OLTDI_moreState, mask TDSS_GENERAL_CONSUMER_MODE
	ret
TextGeneralConsumerMode	endp
endif

TextNeverMakeScrollable	proc	far
	call	Build_DerefVisSpecDI
	ORNF	ds:[di].OLTDI_moreState, mask TDSS_STAY_OUT_OF_VIEW
	ret
TextNeverMakeScrollable	endp

TextAlpha		proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	ANDNF	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	ORNF	ds:[di].VTI_filters, VTFC_ALPHA
	ret
TextAlpha		endp

TextUppercase	proc	far
	class	OLTextClass

	call	Build_DerefVisSpecDI
	ORNF	ds:[di].VTI_filters, mask VTF_UPCASE_CHARS
	ret
TextUppercase	endp

TextNumeric		proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_NUMERIC 
	ret
TextNumeric		endp
			
TextSignedNumeric	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_SIGNED_NUMERIC 
	ret
TextSignedNumeric	endp
			
TextSignedDecimal	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_SIGNED_DECIMAL 
	ret
TextSignedDecimal	endp
			
TextFloatDecimal	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_FLOAT_DECIMAL 
	ret
TextFloatDecimal	endp
			
TextAlphaNumeric	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_ALPHA_NUMERIC
	ret
TextAlphaNumeric	endp
			
TextLegalFilenames	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_FILENAMES
	ret
TextLegalFilenames	endp
			
TextLegalDosFilenames	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_DOS_FILENAMES or mask VTF_NO_SPACES
	ret
TextLegalDosFilenames	endp
			
TextLegalDosVolumeNames	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_DOS_VOLUME_NAMES or mask VTF_NO_SPACES
	ret
TextLegalDosVolumeNames	endp
			
TextLegalDosPath	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_DOS_PATH or mask VTF_NO_SPACES
	ret
TextLegalDosPath	endp
			
TextDate	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_DATE 
	ret
TextDate	endp
		
TextTime	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	;
	; VTF_NO_SPACES taken away, for cases like "8:00 AM"
	; -- kho, 11/15/95
	;
	; or	ds:[di].VTI_filters, VTFC_TIME or mask VTF_NO_SPACES
	or	ds:[di].VTI_filters, VTFC_TIME
	ret
TextTime	endp
			
TextDashedAlphaNumeric	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_DASHED_ALPHA_NUMERIC or \
				     mask VTF_NO_SPACES
	ret
TextDashedAlphaNumeric	endp

TextAllowColumnBreaks	proc	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_ALLOW_COLUMN_BREAKS
	ret
TextAllowColumnBreaks	endp

TextNoSpaces		proc	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	or	ds:[di].VTI_filters, mask VTF_NO_SPACES	
	ret
TextNoSpaces		endp
			
TextAllowSpaces		proc	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_NO_SPACES	
	ret
TextAllowSpaces		endp
			
TextNormalAscii	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_NORMAL_ASCII
	ret
TextNormalAscii	endp
			
TextDosCharacterSet	proc 	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	or	ds:[di].VTI_filters, VTFC_DOS_CHARACTER_SET
	ret
TextDosCharacterSet	endp
			
			
TextWhiteWashColor	proc	far
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VTI_washColor.CQ_redOrIndex, C_WHITE
if DRAW_STYLES
	;
	; for draw styles, we use TDSS_COLOR_SET to know to look for a
	; custom wash color
	;
	ornf	ds:[di].OLTDI_specState, mask TDSS_COLOR_SET
endif
	GOTO	setFrame
TextWhiteWashColor	endp
			
			
; ds:[bx] = ColorQuad to use
TextWashColor	proc 	far
	class	OLTextClass
	
EC <	push	ax							>
EC <	VarDataSizePtr	ds, bx, ax					>
EC <	cmp	ax, size ColorQuad					>
EC <	ERROR_NE	OL_BAD_HINT_DATA				>
EC <	pop	ax							>

	call	Build_DerefVisSpecDI
	ornf	ds:[di].OLTDI_specState, mask TDSS_COLOR_SET
	
	push	si
	add	di, offset VTI_washColor
	push	cx
	lea	si, ds:[bx]
	segmov	es, ds
	mov	cx, size ColorQuad
	rep	movsb
	pop	cx
	pop	si
	
setFrame	label	far
	;
	; Set some flags so draw the frame around text objects differently
	; (or at all) to reflect the difference between the text object and
	; its background.
	;
	call	Build_DerefVisSpecDI
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jnz	10$
	;
	; We'll always frame editable text objects if this flag is on.
	; For now, we won't frame non-editable text objects, nor leave a
	; margin around them.  The real reason we do this is for Ted's
	; text object, which he makes white via this method but really is 
	; still the same color as the background.
	;
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jz	10$
	ornf	ds:[di].OLTDI_specState, mask TDSS_IN_FRAME

	call	SetTextMargins
10$:
	ret
TextWashColor	endp

TextRunsItemGroup	proc	far
	call	Build_DerefVisSpecDI
	or	ds:[di].OLTDI_moreState, mask TDSS_RUNS_ITEM_GROUP

	mov	ax, MSG_SPEC_TEXT_SET_FROM_ITEM_GROUP
	call	SetItemGroupDestAndStatusMsg
	ret
TextRunsItemGroup	endp


TextFrame	proc	far
	call	Build_DerefVisSpecDI
	or	ds:[di].OLTDI_specState, mask TDSS_IN_FRAME
	call	SetTextMargins
	ret
TextFrame	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	SetItemGroupDestAndStatusMsg

SYNOPSIS:	Sets up destination and status message of item group, so 
		it will be sent back to us.

CALLED BY:	TextRunsItemGroup, RangeRunsItemGroup

PASS:		*ds:si -- object
		ds:bx -- hint instance data
		ax    -- status message to use

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/19/92		Initial version

------------------------------------------------------------------------------@

SetItemGroupDestAndStatusMsg	proc	far
	hintParams	local	AddVarDataParams
	hintData	local	word
	.enter
	push	bp
	push	ax
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle		;setup to talk to object

	mov	ax, MSG_GEN_ITEM_GROUP_SET_DESTINATION
	call	ObjMsgCall
	
	;
	; Set up a status message attribute in the list so it will talk to
	; us on user changes.
	;
	pop	ax				;restore status msg to use
	mov	hintParams.AVDP_dataType, ATTR_GEN_ITEM_GROUP_STATUS_MSG
	mov	hintParams.AVDP_dataSize, 2
	lea	cx, hintData
	mov	hintParams.AVDP_data.offset, cx
	mov	hintParams.AVDP_data.segment, ss
	mov	hintData, ax

	lea	bp, hintParams
	mov	ax, MSG_META_ADD_VAR_DATA
	call	ObjMsgCall
	pop	bp
	.leave
	ret
SetItemGroupDestAndStatusMsg	endp


ObjMsgCall	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ObjMsgCall	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupDelayedMode

SYNOPSIS:	Sets up delayed mode status for the object.

CALLED BY:	OLTextSpecBuild

PASS:		*ds:si -- text

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/14/92       	Initial version

------------------------------------------------------------------------------@

SetupDelayedMode	proc	near

	;Check for OLBF_DELAYED set in parent.  Set ourselves if so.

	; if in a View, ask the view for the build flags
	call	Build_DerefVisSpecDI
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	jz	notInView
	push	si
	mov	si, ds:[di].OLTDI_viewObj	;view chunk handle kept here
	mov	ax, MSG_VUP_GET_BUILD_FLAGS
	call	ObjCallInstanceNoLock
	pop	si
	jmp	short haveBuildFlag

notInView:
	call	OpenGetParentBuildFlagsIfCtrl	
haveBuildFlag:
	test	cx, mask OLBF_DELAYED_MODE
	jz	exit
	call	Build_DerefVisSpecDI
	or	ds:[di].OLTDI_moreState, mask TDSS_DELAYED
exit:

	segmov	es, cs				; setup es:di to be ptr to
	mov	di, offset cs:DelayedVarDataHandler
	mov	ax, length (cs:DelayedVarDataHandler)
	call	ObjVarScanData			; 
	ret
SetupDelayedMode	endp

DelayedVarDataHandler	VarDataHandler \
 <ATTR_GEN_PROPERTY, offset TextProperty>,
 <ATTR_GEN_NOT_PROPERTY, offset TextNotProperty>
		
TextProperty	proc	far
	call	Build_DerefVisSpecDI
	or	ds:[di].OLTDI_moreState, mask TDSS_DELAYED
	ret
TextProperty	endp

TextNotProperty	proc	far
	call	Build_DerefVisSpecDI
	and	ds:[di].OLTDI_moreState, not mask TDSS_DELAYED
	ret
TextNotProperty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextAutoHyphenate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow auto hyphenation in the text object.

CALLED BY:	Via ObjVarScanData
PASS:		ds:*si	= instance ptr.
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/ 2/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextAutoHyphenate	proc	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	ornf	ds:[di].VTI_features, mask VTF_AUTO_HYPHENATE
	ret				;
TextAutoHyphenate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSelectText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the text...

CALLED BY:	ObjVarScanData
PASS:		ds:*si	= instance ptr.
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSelectText	proc	far
	uses	cx, dx, bp
	.enter
	sub	sp, size VisTextRange		; Allocate stack frane
	mov	bp, sp				; ss:bp <- frame ptr

	clrdw	ss:[bp].VTR_start
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock		; Select the range
	
	add	sp, size VisTextRange		; Restore stack frame
	.leave
	ret
TextSelectText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCursorAtStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the cursor at the start of the text.

CALLED BY:	ObjVarScanData
PASS:		ds:*si	= instance ptr.
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/ 2/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCursorAtStart	proc	far
	uses	ax, cx, dx, bp
	.enter
	sub	sp, size VisTextRange		; Allocate stack frane
	mov	bp, sp				; ss:bp <- frame ptr

	clrdw	ss:[bp].VTR_start
	clrdw	ss:[bp].VTR_end

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock		; Select the range
	
	add	sp, size VisTextRange		; Restore stack frame
	.leave
	ret
TextCursorAtStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCursorAtEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the cursor at the end of the text.

CALLED BY:	ObjVarScanData
PASS:		ds:*si	= instance ptr.
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/ 2/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCursorAtEnd	proc	far
	uses	cx, dx, bp
	.enter
	sub	sp, size VisTextRange		; Allocate stack frane
	mov	bp, sp				; ss:bp <- frame ptr

	movdw	ss:[bp].VTR_start, TEXT_ADDRESS_PAST_END
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END

	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock		; Select the range
	
	add	sp, size VisTextRange		; Restore stack frame
	.leave
	ret
TextCursorAtEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextAllowSmartQuotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow smart quotes in this object

CALLED BY:	GLOBAL
PASS:		ds:*si = instance ptr
RETURN:		nada
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextAllowSmartQuotes	proc	far
	call	Build_DerefVisSpecDI
	ornf	ds:[di].VTI_features, mask VTF_ALLOW_SMART_QUOTES	
	ret
TextAllowSmartQuotes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextAllowUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow smart quotes in this object

CALLED BY:	GLOBAL
PASS:		ds:*si = instance ptr
RETURN:		nada
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextAllowUndo	proc	far
	call	Build_DerefVisSpecDI
	ornf	ds:[di].VTI_features, mask VTF_ALLOW_UNDO
	ret
TextAllowUndo	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	TextDoNotUseMoniker

SYNOPSIS:	Handles DO_NOT_USE_MONIKER hint for OLTextClass. 

CALLED BY:	hint handler

PASS:		*ds:si -- object

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 2/89	Initial version

------------------------------------------------------------------------------@

TextDoNotUseMoniker	proc	far
	class	OLTextClass
	
	call	Build_DerefVisSpecDI
	or	ds:[di].OLTDI_specState, mask TDSS_NO_MONIKER
	ret
TextDoNotUseMoniker	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDefaultBGColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default background color based on the position
		of the text object.

CALLED BY:	OLTextSpecBuild, CreateView
PASS:		ds:*si	= instance ptr.
RETURN:		background color set appropriately.
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDefaultBGColor	proc	near
	class	OLTextClass
	

	call	Build_DerefVisSpecDI
	mov	bx, di

	test	ds:[di].OLTDI_specState, mask TDSS_COLOR_SET
	jnz	done

	; set wash color

	mov	al, C_WHITE			; default to white.

if	_OL_STYLE or _MOTIF or _ISUI
	;
	; If we're not color specific (in motif and openlook), we will set the
	; text background color to the window color.
	;
	push	ds
	mov	ax, segment moCS_dsLightColor
	mov	ds, ax
	mov	al, ds:[moCS_dsLightColor]
	pop	ds
SDBGC_setColor:					;
endif

	mov	cl, al				; Red (or color) component.
	mov	ch, CF_INDEX
	clr	dx				; Green and blue

	mov	ax, MSG_VIS_TEXT_SET_WASH_COLOR	;
	call	ObjCallInstanceNoLock		;

done:
	ret					;
SetDefaultBGColor	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLTextScanGeometryHints -- 
		MSG_SPEC_SCAN_GEOMETRY_HINTS for OLTextClass

DESCRIPTION:	Scans geometry  hints.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SCAN_GEOMETRY_HINTS

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/ 5/92		Initial Version

------------------------------------------------------------------------------@

OLTextScanGeometryHints	method static OLTextClass, \
				MSG_SPEC_SCAN_GEOMETRY_HINTS

	uses	bx, di, es		; To comply w/static call requirements
	.enter				; that bx, si, di, & es are preserved.
					; NOTE that es is NOT segment of class
;	mov	di, segment OLTextClass
;	mov	es, di

	mov	di, ds:[si]			;must dereference for static
	add	di, ds:[di].Vis_offset		;   method!
	ANDNF	ds:[di].OLTDI_moreState, not \
			(mask TDSS_EXPAND_WIDTH_TO_FIT_PARENT or \
			 mask TDSS_EXPAND_HEIGHT_TO_FIT_PARENT)
	;
	; In multi-line text objects, editable or not editable, we'll want to
	; always expand the width to fit the available space.
	;
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jnz	scanHints
	or	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_WIDTH_TO_FIT_PARENT

scanHints:

	segmov	es, cs				; setup es:di to be ptr to
						; Hint handler table
	mov	di, offset cs:GeoVarDataHandler
	mov	ax, length (cs:GeoVarDataHandler)
	call	ObjVarScanData			; 

	;
	; New text optimization code goes here.
	;
	call	Build_DerefVisSpecDI
	test	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_WIDTH_TO_FIT_PARENT \
				      or mask TDSS_EXPAND_HEIGHT_TO_FIT_PARENT
	jnz	exit				;expanding forget optimization

	mov	ax, HINT_FIXED_SIZE
	call	ObjVarFindData
	jnc	exit				;did not find hint, no opts

	call	Build_DerefVisSpecDI
	or	ds:[di].VI_geoAttrs, mask VGA_ONLY_RECALC_SIZE_WHEN_INVALID
exit:
	.leave
	ret
OLTextScanGeometryHints	endm

GeoVarDataHandler	VarDataHandler \
 <HINT_EXPAND_WIDTH_TO_FIT_PARENT, offset TextExpandWidth>,
 <HINT_EXPAND_HEIGHT_TO_FIT_PARENT, offset TextExpandHeight>

TextExpandWidth		proc	far
	call	Build_DerefVisSpecDI
	ORNF	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_WIDTH_TO_FIT_PARENT
	ret
TextExpandWidth		endp
			
TextExpandHeight		proc	far
	call	Build_DerefVisSpecDI
	ORNF	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_HEIGHT_TO_FIT_PARENT
	ret
TextExpandHeight		endp
			


COMMENT @----------------------------------------------------------------------

ROUTINE:	RemoveComposite

SYNOPSIS:	Removes composite from the picture before building a view.

CALLED BY:	OLTextSpecBuild

PASS:		*ds:si -- handle of text object

RETURN:		bl -- old composite's margin flags (OLCtrlMarginFlags)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/ 3/89		Initial version

------------------------------------------------------------------------------@

RemoveComposite	proc	near
	class	OLTextClass
		
	clr	bl				;assume no composite, we'll
						;  start with no margin flags
	call	Build_DerefVisSpecDI
	test	ds:[di].OLTDI_specState, mask TDSS_IN_COMPOSITE
	jz	exit				;not in a composite, branch
	
	push	bp				;preserve bp
	push	si
	;
	; Remove composite from its parent, destroy it, but not before getting
	; the composite's margin flags to pass on to the view.
	;
	mov	si, ds:[di].OLTDI_viewObj	;composite handle kept here
;	mov	bl, ds:[di].OLCI_marginFlags	;get composite's margin flags
		
	mov	dl, VUM_MANUAL			; The parent will be updated
						; later, when the view is
						; added.
	call	VisRemove			; Close, remove & destroy
						; the composite.
	pop	si
	pop	bp				
	
exit:
	ret
RemoveComposite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLTextVisUnbuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure text object releases focus & exclusive
		grabs, since text object is being visually unbuilt.
		Then do see if we need to set an associated view or
		composite as well.

CALLED BY:	via MSG_SPEC_UNBUILD_BRANCH
PASS:		ds:*si	= instance ptr.
		es	= class segment.
		ax	= MSG_SPEC_UNBUILD
		bp	- SpecBuildFlags
				SBF_VIS_PARENT_UNBUILDING	- set if
				we're being called only because visible parent,
				not generic, is unbuilding.
RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version
	jcw	10/13/89	2d Initial version
	Doug	1/90		Converted from SPEC_SET_NOT_USABLE handler
	IP	8/94  		Free VTI_lines on UNBUILD

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
OLTextVisUnbuild	method dynamic OLTextClass, MSG_SPEC_UNBUILD

EC <	call	ECCheckGenTextObject				>

EC <	call	VisCheckIfVisGrown					>
EC <	ERROR_NC OL_TEXT_DISPLAY_VIS_UNBUILD_PASSED_NON_BUILT_OBJECT	>

	clr	di				;assume no visual parent
	mov	ax, di
	;
	; Free VTI_lines since when the vis text object gets
	; regenerated, it will allocate a new chunk for VTI_lines.
	;	
 	mov	bx, ds:[si]			;point to instance
 	add	bx, ds:[bx].Vis_offset		;ds:[bx] -- SpecInstance
	xchg	ax, ds:[bx].VTI_lines
	tst	ax
	jz 	noLines
	andnf	ds:[bx].VTI_intFlags, not (mask VTIF_HAS_LINES)
	call	LMemFree
noLines:

	;
	; The text object may have created a char attr run - if so, free it.
	;
	
	mov	bx, ds:[si]
	add	bx, ds:[bx].VisText_offset

	; If we just have a default char attr, nothing to free
	; If we have multiple char attrs, then they are set up by the user,
	; and we should not free them.

	test	ds:[bx].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR or mask VTSF_MULTIPLE_CHAR_ATTRS
	jnz	afterCharAttrFree

	; Free our single char attr, and tell the text object it now
	; just has a "default char attr".

	ornf	ds:[bx].VTI_storageFlags, mask VTSF_DEFAULT_CHAR_ATTR

	mov	cx, VIS_TEXT_INITIAL_CHAR_ATTR
	xchg	ds:[bx].VTI_charAttrRuns, cx

	mov	ax, ATTR_GEN_TEXT_CHAR_ATTR
	call	ObjVarFindData
	jnc	freeIt
	cmp	cx, ds:[bx]
	je	afterCharAttrFree

freeIt:
	mov_tr	ax, cx				;AX <- chunk to free
	call	LMemFree
	jmp	afterCharAttrFree

afterCharAttrFree:

	mov	ax, di				;assume parent is not a view
 	mov	bx, ds:[si]			;point to instance
 	add	bx, ds:[bx].Vis_offset		;ds:[bx] -- SpecInstance

 	test	ds:[bx].OLTDI_specState, mask TDSS_IN_VIEW or \
					 mask TDSS_IN_COMPOSITE
	jz	10$				;not in view or composite...
	mov	di, ds:[bx].OLTDI_viewObj	;else *ds:si <- parent

 	test	ds:[bx].OLTDI_specState, mask TDSS_IN_VIEW
	jz	10$				;not a view, branch
	dec	ax				;mark parent as a view
10$:
	mov	bl, al				;pass view flag in bl
	mov	ax, -1				;yes! destroy moniker here
	call	OpenUnbuildCreatedParent	; unbuild parent, then remove
						;  ourselves
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	and	ds:[di].OLTDI_specState, not (mask TDSS_IN_VIEW or \
					      mask TDSS_IN_COMPOSITE)
	clr	ds:[di].OLTDI_viewObj

	;
	; Update generic instance data.	
	; Not sure we're going to do this.  -cbh 9/ 2/92
	;
;	mov	ax, MSG_VIS_TEXT_UPDATE_GENERIC
;	call	ObjCallInstanceNoLock
	ret
	
OLTextVisUnbuild	endm

Build ends
Unbuild segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextSetNotUsable -- 
		MSG_SPEC_SET_NOT_USABLE for OLTextClass

DESCRIPTION:	Handles being set not usable.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_SET_NOT_USABLE

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	10/26/92	Initial Version

------------------------------------------------------------------------------@

OLTextSetNotUsable	method dynamic	OLTextClass, \
				MSG_SPEC_SET_NOT_USABLE

	call	OLTextNavigateIfHaveFocus	;get rid of focus if we have it

	mov		di, offset OLTextClass
	CallSuper	MSG_SPEC_SET_NOT_USABLE
	ret
OLTextSetNotUsable	endm


Unbuild ends
Build segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	CreateView

DESCRIPTION:	If not already created, create a generic view & content
		object for text to appear in.  Initialize them.

PASS:
	*ds:si  - instance data
	bp	- SpecBuildFlags
;	bl	- Margin flags to start with (OLCtrlMarginFlags)

RETURN:
	bp	- unchanged

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If not yet IN_VIEW {
		Create GenView, GenContent objects;
 		Add view generically after the text object;
		Initialize objects;
		Mark as IN_VIEW
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/89		Snagged from old PlaceInView routine
	atw	12/91		Changed to use ESP-style local vars, and
				to set GenViewInkType instance data.

------------------------------------------------------------------------------@


CreateView	proc	near	uses	si
	class	OLTextClass

EC <	call	ECCheckGenTextObject				>
						;
	view		local	lptr		; created object
	ourObj		local	lptr		; our object
	content		local	lptr		; content, if needed

	mov	ax, bp				; ax <- build flags
	.enter

	mov	di, ds:[si]			;
	add	di, ds:[di].Vis_offset		;
	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
	LONG	jnz	exit			; just quit if already in view

	push	ax
	mov	ourObj, si			; STORE handle of text object
						;   in local var

	call	VisGetSize			; increase width to account for
if DRAW_STYLES	;--------------------------------------------------------------
	;
	; we actually have to reduce the size of the text object as we'll
	; later (SetMinMaxHints) fetch its size and set a fixed size hint
	; on the view.  The view will take this size and add room for the
	; frame and insets. -- brianc 9/19/96
	;
	mov	ax, cx				; save current width
	mov	bx, dx				; save current height
	test	ds:[di].OLTDI_specState, mask TDSS_IN_FRAME
	jz	noFrame
	sub	cx, FRAME_TEXT_MARGIN*2
	sub	dx, FRAME_TEXT_MARGIN*2
noFrame:
if TEXT_DISPLAY_FOCUSABLE and 0
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	notFocusable
	cmp	cx, ax
	jne	haveFLRGutter
	sub	cx, 1+1				; add left/right gutters
haveFLRGutter:
	sub	cx, TEXT_DISPLAY_FOCUS_WIDTH*2	; add focus l/r width
	cmp	dx, bx
	jne	haveFTBGutter
	sub	dx, 1+1				; add top/bottom gutters
haveFTBGutter:
	sub	dx, TEXT_DISPLAY_FOCUS_WIDTH*2	; add focus t/b width
notFocusable:
endif
	mov	di, ds:[di].OLTDI_moreState
	andnf	di, mask TDSS_DRAW_STYLE
	cmp	di, DS_LOWERED shl offset TDSS_DRAW_STYLE
	je	addInset
	cmp	di, DS_RAISED shl offset TDSS_DRAW_STYLE
	jne	noInset
addInset:
	cmp	cx, ax
	jne	haveDSLRGutter
	sub	cx, 1+1				; add left/right gutters
haveDSLRGutter:
	add	cx, DRAW_STYLE_INSET_WIDTH*2	; add inset l/r width
	cmp	dx, bx
	jne	haveDSTBGutter
	sub	dx, 1+1				; add top/bottom gutters
haveDSTBGutter:
	sub	dx, DRAW_STYLE_INSET_WIDTH*2	; add inset t/b height
noInset:
	;
	; Prevent negative width/height
	;
	tst	cx
	jns	checkHeight
	clr	cx
checkHeight:
	tst	dx
	jns	heightOk
	clr	dx
heightOk:
else ;-------------------------------------------------------------------------
	add	cx, FRAME_TEXT_MARGIN*2		;   new frame margin so view 
if TEXT_DISPLAY_FOCUSABLE
	test	ds:[di].OLTDI_moreState, mask TDSS_FOCUSABLE
	jz	notFocusable
	add	cx, TEXT_DISPLAY_FOCUS_WIDTH*2
notFocusable:
endif
endif ; DRAW_STYLES -----------------------------------------------------------
	call	VisSetSize			;   will reflect it when created

	mov	di, segment GenViewClass
	mov	es, di
	mov	di, offset GenViewClass
	call	OpenCreateNewParentObject
	mov	view, di			; save view handle
	;
	; Copy ATTR_GEN_PROPERTY, ATTR_GEN_NOT_PROPERTY hints to view
	; *ds:si = text; *ds:di = view
	;
	push	es, bp				; save segment, locals
	segmov	es, ds				; *es:bp = view
	mov	bp, di
.assert (ATTR_GEN_PROPERTY eq ATTR_GEN_NOT_PROPERTY-4)
	mov	cx, ATTR_GEN_PROPERTY
	mov	dx, ATTR_GEN_NOT_PROPERTY
	call	ObjVarCopyDataRange
	pop	es, bp				; restore segment, locals

	;
	; Transfer text colors to view.  Also, if text is disabled, so should
	; the view be. *ds:si = text; *ds:di = view

	;
	; Pass current text colors
	;
	mov	bx, ds:[si]			
	add	bx, ds:[bx].Vis_offset
	movdw	dxcx, ds:[bx].VTI_washColor
if DRAW_STYLES
	;
	; transfer frame state and draw style
	;
	push	ds:[bx].OLTDI_moreState
	test	ds:[bx].OLTDI_specState, mask TDSS_IN_FRAME
	pushf
endif
	and	ch, mask WCF_RGB
	mov	bx, ds:[di]
	add	bx, ds:[bx].Gen_offset
	movdw	ds:[bx].GVI_color, dxcx
if DRAW_STYLES
	;
	; set frame state
	;
	popf
	jnz	leaveFrame
	ornf	ds:[bx].GVI_attrs, mask GVA_NO_WIN_FRAME
leaveFrame:
	;
	; set draw style (default for view is flat)
	;
	pop	cx				; OLTDI_moreState
	andnf	cx, mask TDSS_DRAW_STYLE
	mov	ax, HINT_DRAW_STYLE_3D_RAISED
	cmp	cx, DS_RAISED shl offset TDSS_DRAW_STYLE
	je	haveDrawStyle
	cmp	cx, DS_LOWERED shl offset TDSS_DRAW_STYLE
	jne	doneDrawStyle
	mov	ax, HINT_DRAW_STYLE_3D_LOWERED
haveDrawStyle:
	push	si
	mov	si, di				; *ds:si = view
	clr	cx				; no extra data
	call	ObjVarAddData
	pop	si
doneDrawStyle:
endif ; DRAW_STYLES

	mov	cx, di
	mov	di, ds:[si]			;
	add	di, ds:[di].Vis_offset		;
	mov	ds:[di].OLTDI_viewObj, cx	; Store view handle
						; Mark this object as in view
	ornf	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW
						; No longer in frame.
	andnf	ds:[di].OLTDI_specState, not (mask TDSS_IN_FRAME or \
					      mask TDSS_GOING_INTO_VIEW)
						;
if DRAW_STYLES
	;
	; no longer 3D draw style
	;
	andnf	ds:[di].OLTDI_moreState, not (mask TDSS_DRAW_STYLE)
if (DS_FLAT ne 0)
	ornf	ds:[bx].OLTDI_moreState, DS_FLAT shl offset TDSS_DRAW_STYLE
endif
endif
	;
	; Set the margins of the text object. Top/bottom margins don't really
	; make sense any more, and left/right margins only need to be one pixel
	; to prevent the text from touching the edges of the screen, since the
	; frame is not part of the text object.
	;
if DRAW_STYLES
	;
	; no need for margins here, as the view provides a nice gutter
	;
	mov	ds:[di].VTI_lrMargin, 1
else
	mov	ds:[di].VTI_lrMargin, FRAME_TEXT_MARGIN
endif
	clr	ds:[di].VTI_tbMargin


	mov	al, GVIT_QUERY_OUTPUT
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jne	isEditable


;	If this is not an editable object, make the view focusable only 
;	if the object is selectable, and not targetable on noKeyboard
;	systems. It has to be able to get the focus on other systems,
;	so the user can use PageUp/PageDown to scroll it.
;
;	WRONG! Even systems without keyboards may have buttons to scroll
; 	the view (like Zoomer). So, we still allow the view to get the
;	focus, but we add ATTR_GEN_VIEW_DOES_NOT_ACCEPT_TEXT_INPUT so the
;	view won't force the floating kbd onscreen  4/29/93 -atw.


	call	CheckIfKeyboardRequired
	jnc	noInk

	mov	si, view
	mov	ax, ATTR_GEN_VIEW_DOES_NOT_ACCEPT_TEXT_INPUT or mask VDF_SAVE_TO_STATE
	call	ObjVarAddData
	mov	si, ourObj
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

noInk:
	mov	al, GVIT_PRESSES_ARE_NOT_INK
isEditable:
	mov	bx, view
	mov	bx, ds:[bx]
	add	bx, ds:[bx].Gen_offset
	mov	ds:[bx].GVI_inkType, al

	mov	al, mask GVDA_SCROLLABLE 

if _GCM
	;
	;  Disallow scrollbar in GCM.
	;
	test	ds:[di].OLTDI_moreState, mask TDSS_GENERAL_CONSUMER_MODE
	jz	TDCV_checkViewMax
	andnf	al, not mask GVDA_SCROLLABLE	; no scrollbar in GCM

TDCV_checkViewMax:

endif	; _GCM
		
	mov	di, ourObj			; get desired width of text
	mov	di, ds:[di]			
	add	di, ds:[di].Gen_offset
 	test	ds:[di].GTXI_attrs, mask GTA_TAIL_ORIENTED
 	jnz	setTailOriented			; tail oriented, set flag
 	test	ds:[di].GTXI_attrs, mask GTA_DONT_SCROLL_TO_CHANGES
 	jnz	setVertAttrs			; not scrolling to changes, 
						;    branch
setTailOriented:
 	ornf	al, mask GVDA_TAIL_ORIENTED	; else tail oriented
setVertAttrs:
 	mov	ds:[bx].GVI_vertAttrs, al	; store view attributes

	ORNF	ds:[bx].GVI_attrs, mask GVA_TRACK_SCROLLING or \
				   mask GVA_DRAG_SCROLLING or \
				   mask GVA_DONT_SEND_KBD_RELEASES or \
				   mask GVA_GENERIC_CONTENTS

	call	SetMinMaxSizeHints		; if needed

if DRAW_STYLES
	;
	; tell view that it is for a text object
	;
	mov	si, view			; *ds:si = view
	mov	ax, ATTR_OL_PANE_SCROLLING_TEXT
	mov	cx, size lptr
	call	ObjVarAddData
	mov	ax, ourObj
	mov	ds:[bx], ax
endif
	;
	; Set the line height as the scroll increment.	
	;
	mov	si, ourObj			
	call	GetTextObjectLineHeight
	mov_tr	ax, bx
	mov	cx, ax				; ax, cx <- line height.
	
	mov	di, view
	mov	bx, ds:[di]			
	add	bx, ds:[bx].Gen_offset
	mov	ds:[bx].GVI_increment.PD_y.low, ax  

	pop	ax				; restore build flags
	mov	bl, 0ffh			; set view flag
	call	OpenBuildNewParentObject	; *ds:ax <- newly created obj

	;
	; See if we need to restore the gadget exclusive, which we may have
	; had to release in order to pop ourselves into a view.
	;
	mov	di, ds:[si]			; point to instance
	add	di, ds:[di].Vis_offset		; ds:[di] -- SpecInstance
	test	ds:[di].OLTDI_specState, mask TDSS_NEEDS_GADGET_EXCL
	jz	doFocusTarget			; don't need it, done
						;	(carry clear)
	and	ds:[di].OLTDI_specState, not (mask TDSS_NEEDS_GADGET_EXCL)
	
	push	bp
	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = object to grab for
	mov	dx, si
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParent
	pop	bp
	stc					; grab for view also
doFocusTarget:
	;
	; grab focus and target for text object within content
	;	carry set to also grab for view within its parent
	;	carry clear otherwise
	;
	pushf
	call	MetaGrabFocusExclLow		; now for the text object
	call	MetaGrabTargetExclLow
	popf
	jnc	exit				; no need to grab for view
	push	si				; grab the focus for the view
	mov	si, view			; 
	call	MetaGrabFocusExclLow
	call	MetaGrabTargetExclLow
	pop	si

exit:					
	.leave
	ret					;
CreateView	endp






COMMENT @----------------------------------------------------------------------

ROUTINE:	SetMinMaxSizeHints

SYNOPSIS:	Sets minimum and maximum size hints on the view, if needed.

CALLED BY:	CreateView

PASS:		*ds:si -- text

RETURN:		nothing

DESTROYED:	something

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/17/92		Initial version

------------------------------------------------------------------------------@

SetMinMaxSizeHints	proc	near
	view		local	lptr		; created object
	ourObj		local	lptr		; our object
	content		local	lptr		; content, if needed
	.enter	inherit	
	;
	; Stick appropriate minimum and maximum sizes on the view.  The 
	; maximum size is that text's current size (only if expand-to-fit
	; is clear in that direction); the minimum width is
	; the one returned by the text object.  -cbh 9/ 2/92
	;	
	mov	si, ourObj			; *ds:si <- text
	clr	cx
	mov	dx, cx
	call	VisCheckIfVisGrown		; see if grown...
	jnc	0$				; no, start with no size
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED
	jz	0$				; geo never been done, branch	
	call	VisGetSize			; get current size
0$:
	;
	; If the size isn't determined yet (initScrolling attribute on?), then
	; we'll use a standard size, if there isn't anything else.
	;
	tst	cx
	jnz	1$
	mov	cx, SpecWidth <SST_PIXELS, DEFAULT_TEXT_WIDTH>
1$:
	tst	dx
	jnz	2$
	mov	dx, SpecHeight <SST_LINES_OF_TEXT, DEFAULT_TEXT_HEIGHT>
2$:
	;
	; If the text is expanding to fit in one direction or the other,
	; forget this maximum size stuff in that direction.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_WIDTH_TO_FIT_PARENT
	jz	10$
	clr	cx
10$:
	test	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_HEIGHT_TO_FIT_PARENT
	jz	20$
	clr	dx
20$:
	mov	ax, HINT_FIXED_SIZE		;a preset fixed size, forget
	call	ObjVarFindData			;  this min/max size stuff
	jc	exit				;  (cbh 2/ 6/93)

	;
	; If we haven't done geometry yet, and there's an initial size 
	; specified, forget about putting a max size on the view.  -cbh 2/18/93
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_geoAttrs, mask VGA_GEOMETRY_CALCULATED
	jnz	doMax				
	mov	ax, HINT_INITIAL_SIZE		
	call	ObjVarFindData			
	jc	doMin				
doMax:
	mov	si, view			;add a maximum size
	mov	ax, HINT_MAXIMUM_SIZE
	call	AddArgsToSizeHint		
doMin:
	;
	; Do minimum size as well, as long as nothing's there.
	;
	mov	cx, DEFAULT_TEXT_MIN_WIDTH	
	mov	dx, SpecHeight <SST_LINES_OF_TEXT, 1>
	mov	ax, HINT_MINIMUM_SIZE
	call	AddArgsToSizeHint		
exit:
	.leave
	ret
SetMinMaxSizeHints	endp

	




COMMENT @----------------------------------------------------------------------

ROUTINE:	AddArgsToSizeHint

SYNOPSIS:	Adds arguments to size hint, if needed.   Any non-zero width
		or height will be added as a size argument if there isn't
		something already specified in a hint.

CALLED BY:	SetMinMaxSizeHints

PASS:		*ds:si -- view
		ax -- size hint to apply arguments to
		cx -- width to set (zero if none)
		dx -- height to set (zero if none)

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/26/92       	Initial version

------------------------------------------------------------------------------@

AddArgsToSizeHint	proc	near
	;
	; If a hint is already specified, we have to do the right thing (i.e.
	; not obliterate any arguments that are already there).
	;
	tst	cx				;nothing to add, exit
	jnz	doSize
	tst	dx
	jz	exit
doSize:

	call	ObjVarFindData
	jc	setSizeArgs			;exists, don't create

	push	cx
	mov	cx, size GadgetSizeHintArgs
	call	ObjVarAddData
	pop	cx
	clr	ds:[bx].GSHA_width
	clr	ds:[bx].GSHA_height

setSizeArgs:
	tst	ds:[bx].GSHA_width		;already specified, branch
	jnz	30$
	tst	cx				;nothing to set, leave alone
	jz	30$
	mov	ds:[bx].GSHA_width, cx
30$:
	tst	ds:[bx].GSHA_height
	jnz	exit
	tst	dx
	jz	exit
	mov	ds:[bx].GSHA_height, dx

exit:
	ret
AddArgsToSizeHint	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CreateComposite

DESCRIPTION:	If not already created, create a generic interaction for text
		to appear in.  Initialize it.

PASS:
	*ds:si  - instance data
	bp	- SpecBuildFlags

RETURN:
	bp	- unchanged

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	If not yet IN_VIEW {
		Create GenInteraction object
		Give GenInteraction an upward only link;
		Initialize objects;
		Mark as IN_COMPOSITE
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	11/89		Initial version

------------------------------------------------------------------------------@
;
; Put addresses of classes here, so we can reference them (imported from UI
; library)
;

OLTDCC_StackFrame	struct
	OLTDCC_comp		lptr	
	OLTDCC_text		lptr	
OLTDCC_StackFrame	ends

OLTDCC_Local	equ	<[bp - (size OLTDCC_StackFrame)]>

compHandle	equ	<OLTDCC_Local.OLTDCC_comp>
textHandle	equ	<OLTDCC_Local.OLTDCC_text>


CreateComposite	proc	near
	class	OLTextClass
	
	mov	ax, bp				; ax <- build flags
	mov	bp, sp				;
	sub	sp, size OLTDCC_StackFrame	;
	push	si				;
						;
	mov	di, ds:[si]			;
	add	di, ds:[di].Vis_offset		;
	test	ds:[di].OLTDI_specState, mask TDSS_IN_COMPOSITE
	jz	TDCC_DoIt			;
	jmp	Done			; just quit if already in comp
						;
TDCC_DoIt:					;
	mov	textHandle, si			; STORE handle of text object 
						;   in local var
	mov	di, segment GenInteractionClass
	mov	es,di
	mov	di, offset GenInteractionClass
	call	OpenCreateNewParentObject	
	mov	compHandle, di
	clr	bx				; no view flag
	call	OpenBuildNewParentObject	; create comp, place us under it
						;  returned in ax
	;
	; Set the enabled bit in the composite to match that of the text.
	;
	mov	si, ax
	mov	bx, ds:[si]			;point to composite instance
	add	bx, ds:[bx].Gen_offset		;ds:[di] -- GenInstance
	and	ds:[bx].GI_states, not mask GS_ENABLED
	
	mov	si, textHandle			;get handle of text
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GI_states, mask GS_ENABLED
	jz	10$				; text not enabled, branch
	or	ds:[bx].GI_states, mask GS_ENABLED
10$:
	;
	; Don't turn into a button!
	;
	mov	ds:[bx].GII_type, GIT_ORGANIZATIONAL
	mov	ds:[bx].GII_visibility, GIV_SUB_GROUP

;------------------------------------------------------------------------------
;	Set flag in text object (textHandle in si)
;------------------------------------------------------------------------------
						;
	mov	di, ds:[si]			;
	add	di, ds:[di].Vis_offset		;
	or	ds:[di].OLTDI_specState, mask TDSS_IN_COMPOSITE
	mov	si, compHandle			; save handle of composite
	mov	ds:[di].OLTDI_viewObj, si	; keep in this variable

	;
	; Ignore desired size hints in OLCtrl.  Also, let's ensure the OLCtrl
	; expands width to fit if the text object is doing so.  (Also, bottom
	; justify children, which should fix most font size problems, at 
	; least in single line text. -cbh 11/30/92)
	;
	test	ds:[di].OLTDI_moreState, mask TDSS_EXPAND_WIDTH_TO_FIT_PARENT
	pushf
	mov	di, ds:[si]			; tell OLCtrl to ignore these
	add	di, ds:[di].Vis_offset		;  (handled in text object)
	popf
	jz	20$
	or	ds:[di].VCI_geoDimensionAttrs, \
			mask VCGDA_EXPAND_WIDTH_TO_FIT_PARENT or \
			(HJ_BOTTOM_JUSTIFY_CHILDREN shl \
				offset VCGDA_HEIGHT_JUSTIFICATION)

20$:
	or	ds:[di].OLCI_optFlags, mask OLCOF_IGNORE_DESIRED_SIZE_HINTS
	;
	; since text object handles kbd mnemonic, and since we copied our
	; moniker and mnemonic to the OLCtrl, don't handle mnemonic on the
	; OLCtrl.
	;
	ornf	ds:[di].OLCI_moreFlags, mask OLCOF_IGNORE_MNEMONIC
Done:
	pop	si				;
	mov	sp, bp				;
	ret					;
CreateComposite	endp


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextGetSpecVisObj --
		MSG_SPEC_GET_SPECIFIC_VIS_OBJECT for OLTextClass

DESCRIPTION:	Returns specific object used for this generic object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_GET_SPECIFIC_VIS_OBJECT
		bp	- SpecBuildFlags

RETURN:		cx:dx	- the specific object (or null if caller is querying
			  for the win group part)
		carry set

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	10/25/89	Initial version  (did I write this code?  I
						  didn't write this. I didn't
						  know what it did until I
						  asked Doug.)

------------------------------------------------------------------------------@

OLTextGetSpecVisObj	method dynamic OLTextClass, \
				MSG_SPEC_GET_SPECIFIC_VIS_OBJECT
	clr	cx				;assume querying for win group
	clr	dx				;   part (we'll return null)
	test	bp, mask SBF_WIN_GROUP		;doing win group
	jnz	exit				;exit if so

	mov	cx, ds:[0]			;else assume we return ourselves
	mov	dx, si

	test	ds:[di].OLTDI_specState, mask TDSS_IN_VIEW or \
					 mask TDSS_IN_COMPOSITE
	jz	exit				;not in a view, we're done
	mov	dx, ds:[di].OLTDI_viewObj	;else return view object

exit:
	stc					;return carry set
	ret
OLTextGetSpecVisObj	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLTextVupCreateGState --
		MSG_VIS_VUP_CREATE_GSTATE for OLTextClass

DESCRIPTION:	Creates GState for this object.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_VUP_CREATE_GSTATE

RETURN:		bp	- GState
		carry set if handled

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/99	Initial revision

------------------------------------------------------------------------------@

OLTextVupCreateGState	method dynamic OLTextClass, \
				MSG_VIS_VUP_CREATE_GSTATE
	mov	di, offset OLTextClass
	call	ObjCallSuperNoLock
	jnc	exit
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLTDI_specState, mask TDSS_EDITABLE
	jz	done
	push	cx, ds
	segmov	ds, dgroup, di
	mov	cx, ds:[editableTextFontID]
	jcxz	donePop
	push	ax, dx
	mov	dx, ds:[editableTextFontsize]
	clr	ah
	mov	di, bp				; di = gstate
	call	GrSetFont
	pop	ax, dx
donePop:
	pop	cx, ds
done:
	stc
exit:
	ret
OLTextVupCreateGState	endm

Build ends
