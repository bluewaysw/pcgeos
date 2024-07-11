COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gadgettext.asm

AUTHOR:		Ronald Braunstein, Dec 12, 1994

ROUTINES:
	Name			Description
	----			-----------
 ?? INT GetMaxLines		Utility routine for getting max lines in
				text object

 ?? INT TextLimitToMaxLines	Make sure that the text doesn't go beyond
				maxLines. (requires the text to be visible)

 ?? INT GTLockToken		Locks down a the data for a RunHeapToken.

 ?? INT GTUnlockToken		Locks down a the data for a RunHeapToken.

    INT Get2Ints		Gets 2 ints from action args or returns an
				error if they are not there.

    INT GetSelectionRange	Get the selected range of a text object.

 ?? INT TextReplaceRange	Replaces a range of text. Used for replace,
				insert and delete

 ?? INT LimitTextStringToMaxChars
				Before doing an Insert or Replace,
				constrict the inserted text so it won't
				make the new text > maxChars.  (otherwise
				the end of the old text would have to be
				deleted).  By doing the work ourselves, we
				can find out how much text is added.

 ?? INT SetTextSize		Sets the size of the text component

 ?? INT SetFontStyleLow		Sets the font for the text object, but only
				if the text object is visible.

 ?? INT SetFullRange		Sets the text component's wash color

 ?? INT GadgetTextGetAttrCommon	Gets the text component's FontID

 ?? INT TextCountLines		Counts the number of lines of a text
				object.

 ?? INT TextIsInViewFar		Determines if the text is currently in a
				scrolling view.

 ?? INT TextIsInView		Determines if the text is currently in a
				scrolling view.

 ?? INT SetTextFilterCommon	Sets the text filter and needed vardata on
				the text object.

 ?? INT GetTextFilterCommon	Returns the filter on the text object

 ?? INT FilterTextCommon	

 ?? INT AllocStringFromReplaceParams
				Creates a basic string to represent the
				string about to be filtered

 ?? INT EnumTextFromHugeArray	Copy text from a huge-array into a buffer.

 ?? INT FilterViaCharCommon	Raises an event so the script writer can
				filter chars one at a time.

 ?? INT GadgetTextRaiseEvent	Send a basic event telling the user about
				new Text

 ?? INT FixupRange		Makes sure the passed range is valid for
				the text object or fixes it up if it isn't.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	12/12/94	Initial revision


DESCRIPTION:
	Code for dealing with the spreadsheet component.

	FIXME:	check that all the VisTextRanges have start <= end.
		If the users swaps them, then just swap them back
		before sending them on to the text object.		

	$Id: gdgtext.asm,v 1.1 98/03/11 04:30:13 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include font.def


GADGET_TEXT_MAX_CHARS equ 2000

;Class for dealing with properties that need to be set at spec build
;for both Text and Entry components
GadgetTextSpecClass	class	GenTextClass
	GTSI_filter		word		; filter to use
	GTSI_startSelect	word
	GTSI_endSelect		word
GadgetTextSpecClass	endc

idata segment
	GadgetTextClass
	GadgetTextSpecClass
idata	ends

GadgetTextCode segment resource

; Define new properties.
makePropEntry text, text, LT_TYPE_STRING,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_TEXT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_TEXT>

makePropEntry text, maxLines, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_MAX_LINES>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_MAX_LINES>

makePropEntry text, filter, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_FILTER>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_FILTER>

makePropEntry text, font, LT_TYPE_STRING,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_FONT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_FONT>

makePropEntry text, fontStyle, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_FONT_STYLE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_FONT_STYLE>

makePropEntry text, fontSize, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_FONT_SIZE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_FONT_SIZE>

makePropEntry text, startSelect, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_START>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_START>

makePropEntry text, endSelect, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_END>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_END>

makePropEntry text, color, LT_TYPE_LONG,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_COLOR>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_COLOR>

makePropEntry text, bgColor, LT_TYPE_LONG,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_BG_COLOR>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_BG_COLOR>

makePropEntry text, numLines, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_NUM_LINES>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_NUM_LINES>

makePropEntry text, numChars, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_NUM_CHARS>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_NUM_CHARS>

makePropEntry text, firstVisibleLine, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_FIRST_VISIBLE_LINE>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_FIRST_VISIBLE_LINE>

makePropEntry text, lastVisibleLine, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_LAST_VISIBLE_LINE>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_LAST_VISIBLE_LINE>

makePropEntry text, maxChars, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_GET_MAX_CHARS>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_TEXT_SET_MAX_CHARS>


; Get rid of the unsupported clipboardable API.
makeUndefinedPropEntry text, focusable
makeUndefinedPropEntry text, clipboardable
makeUndefinedPropEntry text, deletable
makeUndefinedPropEntry text, copyable

makeUndefinedPropEntry text, caption
makeUndefinedPropEntry text, graphic


;
; Too many entries for macro
textPropertyTable	label	nptr.PropertyEntryStruct
	word	offset texttextProp
	word	offset texttextProp
	word	offset textmaxLinesProp
	word	offset textfilterProp
	word	offset textfontProp
	word	offset textfontStyleProp
	word	offset textfontSizeProp
	word	offset textstartSelectProp
	word	offset textendSelectProp
	word	offset textcolorProp
	word	offset textbgColorProp
	word	offset textnumLinesProp
	word	offset textnumCharsProp
	word	offset textfirstVisibleLineProp
	word	offset textlastVisibleLineProp
	word	offset textmaxCharsProp
	word	offset textfocusableProp
	word	offset textclipboardableProp
	word	offset textdeletableProp
	word	offset textcopyableProp
	word	offset textcaptionProp
	word	offset textgraphicProp
	word	ENT_PROPERTY_TABLE_TERMINATOR



makeActionEntry text, DeleteRange, MSG_GADGET_TEXT_ACTION_DELETE_RANGE, \
		LT_TYPE_UNKNOWN, 2
makeActionEntry text, AppendString, MSG_GADGET_TEXT_ACTION_APPEND_STRING, \
		LT_TYPE_INTEGER, VAR_NUM_PARAMS
makeActionEntry text, InsertString, MSG_GADGET_TEXT_ACTION_INSERT_STRING, \
		LT_TYPE_INTEGER, 2
makeActionEntry text, GetString, MSG_GADGET_TEXT_ACTION_GET_STRING, \
		LT_TYPE_STRING, 2
makeActionEntry text, ReplaceString, MSG_GADGET_TEXT_ACTION_REPLACE_STRING, \
		LT_TYPE_UNKNOWN, 3
makeActionEntry text, GetLineNumber, MSG_GADGET_TEXT_ACTION_GET_LINE_NUMBER, LT_TYPE_INTEGER, 1
makeActionEntry text, SetSelectionRange, MSG_GADGET_TEXT_ACTION_SET_SELECTION_RANGE, LT_TYPE_UNKNOWN, 2
;makeActionEntry text, Cut, MSG_GADGET_TEXT_ACTION_CUT,	LT_TYPE_STRING
;makeActionEntry text, Copy, MSG_GADGET_TEXT_ACTION_COPY, LT_TYPE_STRING
;makeActionEntry text, Paste, MSG_GADGET_TEXT_ACTION_PASTE, LT_TYPE_UNKNOWN

;compMkActTable text, DeleteRange, AppendString, InsertString, GetPosition, GetString, ReplaceString, Cut, Copy, Paste
compMkActTable text, DeleteRange, AppendString, InsertString, GetString, ReplaceString, GetLineNumber, SetSelectionRange
; still need GetPosition, Cut, Copy, Paste
MakePropRoutines Text, text
MakeActionRoutines Text, text

method GadgetUtilReturnReadOnlyError, GadgetTextClass, MSG_GADGET_TEXT_SET_NUM_CHARS
method GadgetUtilReturnReadOnlyError, GadgetTextClass, MSG_GADGET_TEXT_SET_NUM_LINES

method GadgetUtilReturnReadOnlyError, GadgetTextClass, MSG_GADGET_TEXT_SET_START
method GadgetUtilReturnReadOnlyError, GadgetTextClass, MSG_GADGET_TEXT_SET_END

GadgetInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	12/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextMetaResolveVariantSuperclass	method dynamic GadgetTextClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		.enter
		cmp	cx, GadgetText_offset
		je	returnSuper
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
returnSuper:
		mov	cx, segment GadgetTextSpecClass
		mov	dx, offset GadgetTextSpecClass
		jmp	done

GadgetTextMetaResolveVariantSuperclass	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextEntGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the string associated with this class.

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es	= segment of GadgetTextClass
		ax	= message #
		cx:dx	= fptr.char
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	12/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextEntGetClass	method dynamic GadgetTextClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetTextString
		mov	dx, offset GadgetTextString
		ret
GadgetTextEntGetClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up all the UI for spreadsheet component.  This will
		create the view, content, rulers et al for the component.
		It will not Initialize the spreadsheet as we don't the desired
		size yet.  (The initial sizes on the UI objects will be wrong,
		but at least they will be constructed).

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The final layout will be:

		Interaction: (holds everything)
			Interaction:
				cornerview, horizrulerview
			Interaction:
				vertview, spreadsheetview

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	12/12/94	Initial version
	KALPESH	8/14/96		no word wrapping, initially.
				Added "or mask GTA_NO_WORD_WRAPPING".

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextEntInitialize	method dynamic GadgetTextClass, 
					MSG_ENT_INITIALIZE
		uses	ax, cx, dx, bp
		.enter
	;
	; GadgetClipboardableClass regulates focus/target behavior based
	; on CF_focusable and CF_clipboardable.  Set those here.  (Note
	; that the subset of the clipboardable API supported by text
	; excludes these properties.)
	;
		or	ds:[di].GCLI_flags, \
			mask CF_focusable or mask CF_clipboardable
		
	;
	; Now call superclass.
	;
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock

;; don't worry about pasting in multi-formatted text anymore :(
if 0
	;
	; Setup multiple para, char attrs
	;
		mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
		mov	cl, mask VTSF_MULTIPLE_CHAR_ATTRS or mask VTSF_MULTIPLE_PARA_ATTRS
		mov	ch, 1				; create regions
		call	ObjCallInstanceNoLock



		push	bp
		mov	ax, MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN
		sub	sp, size VisTextSetGrayScreenParams
		mov	bp, sp
		clr	cx
		mov	dx, VIS_TEXT_RANGE_SELECTION
		clrdw	ss:[bp].VTSGSP_range.VTR_start
		mov	ss:[bp].VTSGSP_range.VTR_end.high, TEXT_ADDRESS_PAST_END_HIGH
		mov	ss:[bp].VTSGSP_range.VTR_end.low, TEXT_ADDRESS_PAST_END_LOW
		mov	ss:[bp].VTSGSP_grayScreen, SDM_100
		call	ObjCallInstanceNoLock
		mov	ax, MSG_VIS_TEXT_SET_PARA_BG_GRAY_SCREEN
		call	ObjCallInstanceNoLock
		add	sp, size VisTextSetGrayScreenParams

		pop	bp

endif

		mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
		mov	cx, GADGET_TEXT_MAX_CHARS
		call	ObjCallInstanceNoLock
	;
	; Start it with a scrolbar so the sizing works.
	; Otherwise, SST_LINES_OF_TEXT doesn't give you the same text size
	; when you change from out-of-a-view to in-a-view.
		mov	ax, MSG_GEN_TEXT_SET_ATTRS
		clr	ch
		mov	cl, mask GTA_INIT_SCROLLING
		call	ObjCallInstanceNoLock
	;
	; Give it a starting size
	;

		mov	cx, SpecWidth <SST_PIXELS, 180>
		mov	dx, SpecHeight <SST_PIXELS, 72>
		call	SetTextSize
	;
	; Make it Targetable
	;
		mov	ax, MSG_GEN_SET_ATTRS
		clr	ch
		mov	cl, mask GA_TARGETABLE
		call	ObjCallInstanceNoLock
	;
	; don't show moniker
	;
		mov	ax, HINT_DO_NOT_USE_MONIKER
		clr	cx
		call	ObjVarAddData

	;
	; don't allow scrollbar
	;
		mov	ax, ATTR_GEN_TEXT_NEVER_MAKE_SCROLLABLE
		clr	cx
		call	ObjVarAddData

	;
	; Make it selectable, even if readOnly
	;
		mov	ax, ATTR_GEN_TEXT_SELECTABLE
		Assert	e, cx, 0
		call	ObjVarAddData

	;
	; inform ourself of geometry updates
	; so we can deal with positioning hints better.
	;
addNotification::
		mov	ax, MSG_VIS_SET_GEO_ATTRS
		clr	cx
		mov	cl, mask VGA_NOTIFY_GEOMETRY_VALID
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock

		.leave
		ret
GadgetTextEntInitialize	endm

GadgetInitCode	ends

if 0


	; SetCharForeground(integer index, integer start, integer end)
TextFGCHandler:
		mov	ax, MSG_VIS_TEXT_SET_COLOR
		jmp	colorCommon
TextBGCHandler:
		mov	ax, MSG_VIS_TEXT_SET_CHAR_BG_COLOR
		jmp	colorCommon
TextPCHandler:
		mov	ax, MSG_VIS_TEXT_SET_PARA_BG_COLOR
colorCommon:
	;==============
	;= Foreground color
	;= SetCharForegroundColor(int color)
	;=
	;= Set the text range to the designated color
	;	

	;
	; Make sure they passed in one argument
	;
		cmp	ss:[bp].EDAA_argc, 3
		jne	wrongNumberArgs
		les	di, ss:[bp].EDAA_argv

		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		cmp	es:[di][size ComponentData].CD_type, LT_TYPE_INTEGER
		jne	wrongType
		cmp	es:[di][(size ComponentData)*2].CD_type, LT_TYPE_INTEGER
		jne	wrongType

		mov	dx, es:[di].CD_data.LD_integer
		mov	dh, CF_INDEX
		push	dx			; VTSCP_color
		push	dx			; VTSCP_color
		clr	cx
		mov	dx, es:[di][(size ComponentData)*2].CD_data.LD_integer
		pushdw	cxdx			; VTSCP_range.VTR_end
		mov	dx, es:[di][(size ComponentData)*1].CD_data.LD_integer
		pushdw	cxdx			; VTSCP_range.VTR_start
		mov	bp, sp
		push	bp			; frame ptr

		call	ObjCallInstanceNoLock
		pop	bp			; frame ptr
		add	sp, size VisTextSetColorParams
		jmp	doneReturn0

;;=====================================================================
TextGetSelectionRangeHandler:
	;
	; GetSelectionRange(integer &start, integer &end)
	; This modifies &start and &end
	;
		cmp	ss:[bp].EDAA_argc, 2
		jne	wrongNumberArgs

		push	bp
		sub	sp, size VisTextRange
		mov	dx, ss
		mov	bp, sp
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		call	ObjCallInstanceNoLock
		mov	cx, ss:[bp].VTR_start.low
		mov	dx, ss:[bp].VTR_end.low
		add	sp, size VisTextRange
		pop	bp
		les	di, ss:[bp].EDAA_argv
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		add	di, size ComponentData

		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx

		jmp	doneReturn0
		

doneReturn0:	
	;
	; Return 0
	;
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_GENERIC
		movdw	es:[di].CD_data.LD_gen_dword, 0
done:		
		.leave
		Destroy	si
		ret


GadgetTextDoActionCommon	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextActionCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies selected text out to complex data.

CALLED BY:	MSG_GADGET_TEXT_ACTION_COPY
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextActionCopy	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_ACTION_COPY
	uses	bp
	.enter
TextCopyTextHandler::
	; Fixed for new args, 8 /15
	;
	; Grab the selected range of text as complex data
	;
	; ComplexData CopyText()
	;
		push	bp		; frame ptr
		
		clr	dx
		call	EntGetVMFile
		push	ax			; save vmFile

		push	dx			;CTP_vmBlock
		push	ax			;CTP_vmFile
		push	dx			;CTP_pasteFrame

		mov	ax, VIS_TEXT_RANGE_SELECTION
		pushdw	axax				; second arg, end
		pushdw	axax				; first arg, start
		mov	ax, MSG_VIS_TEXT_CREATE_TRANSFER_FORMAT
		mov	bp, sp
		call	ObjCallInstanceNoLock
		add	sp, size CommonTransferParams

		pop	bx		; vmFileHandle
		pop	bp		; frame ptr
		
	;
	; Return ax
	;
		push	bp			; frame ptr
		push	ax			; head of vmtree
		call	EntCreateComplexHeader
		mov	cx, ax			; header block
		call	VMLock
		mov	ds, ax
		mov	ds:[CIH_formatCount],1
		mov	ds:[CIH_formats.CIFI_format.CIFID_manufacturer], MANUFACTURER_ID_GEOWORKS
		mov	ds:[CIH_formats.CIFI_format.CIFID_type], CIF_TEXT
		pop	ax			; head of vmtree
		movdw	ds:[CIH_formats.CIFI_vmChain], bxax
		clrdw	ds:[CIH_reserved]
		call	VMUnlock
		pop	bp			;frame ptr
		
		
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_COMPLEX
PrintMessage <fix up LD_complex usage>
;;		movdw	es:[di].CD_data.LD_complex, bxcx
		mov	es:[di].CD_data.LD_complex, bx

done::
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextActionCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextActionPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Paste in the the complex data at the selection.

CALLED BY:	MSG_GADGET_TEXT_ACTION_PASTE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextActionPaste	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_ACTION_PASTE
	uses	bp
	.enter
	;
	; Insert the passed in text at the specified location
	;
	; void ReplaceText(Complex text)

	;
	; Make sure they passed in one arguments
	;
		mov	ax, CAE_WRONG_TYPE
		les	di, ss:[bp].EDAA_argv
		cmp	es:[di].CD_type, LT_TYPE_COMPLEX
		jne	returnAX

PrintMessage <fix up LD_complex usage>
;;		movdw	bxax, es:[di].CD_data.LD_complex
		mov	bx, es:[di].CD_data.LD_complex

		pushdw	esdi		; argv
		push	bp		; frame ptr
		call	VMLock
		mov	es, ax
		movdw	axcx, es:[CIH_formats.CIFI_vmChain]
		call	VMUnlock
		pop	bp		; frame ptr
		popdw	esdi		; argv

		push	bp		; frame ptr
		clr	dx
		push	cx			;CTP_vmBlock
		push	ax			;CTP_vmFile
		push	dx			;CTP_pasteFrame

		mov	ax, VIS_TEXT_RANGE_SELECTION
		pushdw	axax			;  end
		pushdw	axax			;  start
		mov	ax, MSG_VIS_TEXT_REPLACE_WITH_TEXT_TRANSFER_FORMAT
		mov	bp, sp
		call	ObjCallInstanceNoLock
		add	sp, size CommonTransferParams

		pop	bp		; frame ptr
		clr	ax		; return 0
		mov	bx, LT_TYPE_INTEGER
returnAX:
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
	;		Assert	e (offset LD_integer), (offset LD_error)
		mov	es:[di].CD_data.LD_integer, ax
		mov	es:[di].CD_type, bx

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextActionPaste	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextActionAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Action Handler

CALLED BY:	MSG_GADGET_TEXT_ACTION_APPEND_STRING
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextActionAppendString	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_ACTION_APPEND_STRING
	uses	bp
	.enter
TextAppendStringHandler::
	;
	; AppendString (String str, [String str] ...)
	;

		sub	sp, size RunHeapLockWithSpaceStruct
		mov	bx, sp
		movdw	cxdx, ss:[bp].EDAA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, cxdx
		lea	cx, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, sscx
		clr	ss:[bx].RHLWSS_tempAX

		les	di, ss:[bp].EDAA_argv
		mov	cx, ss:[bp].EDAA_argc
		
nextAppendArg:
		mov	ax, CAE_WRONG_TYPE
		mov	bx, LT_TYPE_ERROR
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	returnAX
		mov	bx, sp

		mov	dx, es:[di].CD_data.LD_string
		mov	ss:[bx].RHLS_token, dx

	; string token
		mov	ss:[bx].RHLWSS_tempCX, cx
		mov	ss:[bx].RHLWSS_tempES, es
		mov	ss:[bx].RHLWSS_tempDI, di
		call	RunHeapLock
		mov	bx, sp
		push	bp, cx			; frame ptr
		movdw	dxbp, ss:[bx].RHLS_eptr
		push	bx				; temp regs
		movdw	bxax, dxbp			; string
		call	LimitTextStringToMaxChars
		mov	cx, di				; chars
		pop	bx				; temp regs
		add	ss:[bx].RHLWSS_tempAX, di	; total chars added
		
		mov	ax, MSG_VIS_TEXT_APPEND_PTR
		call	ObjCallInstanceNoLock

		pop	bp, cx			; frame ptr
		call	RunHeapUnlock
		mov	bx, sp
		mov	cx, ss:[bx].RHLWSS_tempCX
		mov	es, ss:[bx].RHLWSS_tempES
		mov	di, ss:[bx].RHLWSS_tempDI

		add	di, size ComponentData
		dec	cx
		jnz	nextAppendArg
		mov	ax, ss:[bx].RHLWSS_tempAX
	;		add	sp, size RunHeapLockWithSpaceStruct
		mov	bx, LT_TYPE_INTEGER
		call	TextLimitToMaxLines
returnAX:
	; ax = value
	; bx = LegosType
		add	sp, size RunHeapLockWithSpaceStruct
		Assert	fptr	ssbp
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, bx
		mov	es:[di].CD_data.LD_integer, ax
		
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextActionAppendString	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextActionReplaceString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces a range of text other text.
		Can be used for insert by setting end = start.
		Can be used for delete by setting string = "".

CALLED BY:	MSG_GADGET_TEXT_ACTION_REPLACE_STRING
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextActionReplaceString	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_ACTION_REPLACE_STRING,
					MSG_GADGET_TEXT_ACTION_INSERT_STRING

	uses	bp, es
	.enter

	;
	; ReplaceString (String str, integer start, integer end)
	;
	; This can be used for Insert by passing start = end and
	; Delete by String = ""
	;
		mov	bx, 3		; expected number or args
		cmp	ax, MSG_GADGET_TEXT_ACTION_REPLACE_STRING
		je	cont
		Assert	e ax, MSG_GADGET_TEXT_ACTION_INSERT_STRING
		dec	bx		; only 2 args
cont:
		mov	ax, CAE_WRONG_TYPE
		les	di, ss:[bp].EDAA_argv
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	error
checkArg2::
		cmp	es:[di+size(ComponentData)].CD_type, LT_TYPE_INTEGER
		jne	error
		cmp	bx, 2
		je	okay
		cmp	es:[di][(size ComponentData)*2].CD_type, LT_TYPE_INTEGER
		je	okay
error:
	; pass ComponentActionError in ax.
	;
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done
		

okay:
	;
	; Lock down the string on the heap
	;
		mov	dx, bx		; number or args
		mov	ax, es:[di].CD_data.LD_string
		push	ax			; save heap token
		pushdw	esdi			; cdata
		call	RunHeapLock_asm
		movdw	bxax, esdi
		popdw	esdi			; cdata

	; Get start arg.
		mov	cx, es:[di][(size ComponentData)].CD_data.LD_integer

	;
	; if its a replace, then get the end arg from argv
	; else its an insert and the end arg equals the start arg
		cmp	dx, 3
		je	getReplaceArg
	; its an insert, get the start arg.
		Assert	e dx, 2
		mov	dx, cx

	;
	; Special Hack for InsertString
	;
	; TextReplaceRange calls FixupRange, but we need to call it
	; here to make InsertString work as spec'ed.  We need this
	; hack because InsertString rejects start values 
	; beyond numChars, but ReplaceString does not.
	;
		call	FixupRange
		mov	es, bx				; es:ax = string
		mov	bx, 0
		jc	noUpdate
		mov	bx, es
		jmp	doTextReplaceRange

getReplaceArg:
		mov	dx, es:[di][(size ComponentData)*2].CD_data.LD_integer
		
doTextReplaceRange:
		pushdw	bxax				; save string

		call	TextReplaceRange
		mov	bx, ax				; num chars entered

		popdw	esdi				; restore string

		tst	bx
		jz	noUpdate
		
	; *ds:si- text object
	; es:di	- string
	; cx 	- start of insert or replace
		call	UpdateCursor
noUpdate:
		pop	ax				; restore heap token
		call	RunHeapUnlock_asm
		les	di, ss:[bp].EDAA_retval
		Assert	fptr, esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, bx	; num chars entered
done:
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextActionReplaceString	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextGetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets all the text in the text object as a string

CALLED BY:	MSG_GADGET_TEXT_GET_TEXT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetText	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_GET_TEXT
		uses	bp
		.enter
	;
	; Determine size of text and allocate space in the heap for it
	;
		push	bp			; frame ptr
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		inc	ax			; add null
	; it returns length, not size, or so the docs say ...
DBCS <		shl	ax						>

		sub	sp, size RunHeapAllocStruct
		mov	bx, sp
		mov	ss:[bx].RHAS_size, ax
		clrdw	ss:[bx].RHAS_data
		mov	ss:[bx].RHAS_refCount, 0
		mov	ss:[bx].RHAS_type, RHT_STRING
		Assert	fptr	ssbp
		movdw	dxax, ss:[bp].GPA_runHeapInfoPtr
		movdw	ss:[bx].RHAS_rhi, dxax
		
		call	RunHeapAlloc
		add	sp, size RunHeapAllocStruct
		pop	bp			; frame ptr

	;
	; Now lock down the space and tell the text to copy in it.
	;
		push	ax			; new token
		push	bp			; frame ptr
		call	GTLockToken
		mov	bp, ax			; dx:bp = ^fdata
		
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock

		pop	bp			; frame ptr
		pop	ax			; new token

		call	GTUnlockToken
	;
	; Return the string
	;
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextGetText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces all the text in the text object with the passed in
		string.

CALLED BY:	MSG_GADGET_TEXT_SET_TEXT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetText	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_SET_TEXT
		uses	bp
		.enter
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	ax, es:[di].CD_data.LD_string
	;
	; Now lock down the space and tell the text to copy in it.
	;
		push	ax			; token
		push	bp			; frame ptr
		call	GTLockToken
		mov	bp, ax			; dx:bp = ^fdata

		clr	cx			; null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock

		pop	bp			; frame ptr
		pop	ax			; token

		call	GTUnlockToken
	;
	; Return the string
	;
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax

		call	TextLimitToMaxLines
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextSetText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMaxLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for getting max lines in text object

CALLED BY:	
PASS:		*ds:si		= Text Object
RETURN:		cx		= max lines
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	2/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMaxLines	proc	near
	uses	di
	class	GadgetTextClass
		.enter
		Assert	objectPtr, dssi, GadgetTextClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetText_offset
		mov	cx, ds:[di].GTI_maxLines
		.leave
		ret
GetMaxLines	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextRoomWithinMaxLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return number of characters that there is still room for
		within the maxLines limitation

CALLED BY:	INSERT_TEXT, REPLACE_TEXT
PASS:		*ds:si = text object
RETURN:		ax = number of characters that still can be added
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextRoomWithinMaxLines	proc	near
		class	GadgetTextClass
	uses	bx,cx,dx,si,di,bp
		.enter

	; assume no limit
		mov	ax, 0xffff
		
		Assert	objectPtr, dssi, GadgetTextClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetText_offset
		mov	dx, ds:[di].GTI_maxLines
	; if no limit, don't chop
		tst	dx
		je	done


	; NOTE: this code assumes a monowidth font
		
	; first get the total number of characters and divide by chars per
	; line to see how many empty lines remain
		push	dx
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		push	ax
	; ax = num characters
		
	; get the offset for the end of the first line.
		clr	cx
		mov	ax, MSG_VIS_TEXT_GET_LINE_OFFSET_AND_FLAGS
		sub	sp, size VisTextGetLineOffsetAndFlagsParameters
		mov	bp, sp
		clr	ss:[bp].VTGLOAFP_line.high
		mov	ss:[bp].VTGLOAFP_line.low, 1
		mov	dx, ss
		call	ObjCallInstanceNoLock
		mov	cx, ss:[bp].VTGLOAFP_offset.low
		add	sp, size VisTextGetLineOffsetAndFlagsParameters

		pop	ax
		pop	dx

	; cx = number of characters per line
	; dx = maxLines
	; ax = total number of characters
		
		xchg	ax, cx
	; total number of characters allowed within maxLines is ax * maxLines
	; ASSUMPTION: dx * ax < 65535
		mul	dx

		cmp	cx, ax
		jae	overLimit
		sub	ax, cx
done:
		.leave
		ret
overLimit:
		clr	ax
		jmp	done
TextRoomWithinMaxLines	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextLimitToMaxLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that the text doesn't go beyond maxLines.
		(requires the text to be visible)

CALLED BY:	VisOpen, SetText, ...
PASS:		*ds:si		- TextObject
RETURN:		ax		- num chars deleted from end.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	2/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextLimitToMaxLines	proc	near
		class	GadgetTextClass
	uses	bx,cx,dx,si,di,bp
		.enter
	;
	; Chop off extra text beyond max lines
	;
		Assert	objectPtr, dssi, GadgetTextClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetText_offset
		mov	dx, ds:[di].GTI_maxLines
	; if no limit, don't chop
		tst	dx
		je	done
	; are we above the limit?
		call	TextCountLines		; ax <- num lines
		cmp	ax, dx
		jle	done		; fewer than max, leave.

	; get the offset for the end of the max line.
		clr	cx
		mov	ax, MSG_VIS_TEXT_GET_LINE_OFFSET_AND_FLAGS
		sub	sp, size VisTextGetLineOffsetAndFlagsParameters
		mov	bp, sp
		mov	ss:[bp].VTGLOAFP_line.high, 0
		mov	ss:[bp].VTGLOAFP_line.low, dx
		mov	dx, ss
		
		call	ObjCallInstanceNoLock
		mov	cx, ss:[bp].VTGLOAFP_offset.low
		add	sp, size VisTextGetLineOffsetAndFlagsParameters

		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		
	; replace from here to end with nothing.
		mov	dx, ax			; end: replace will fixup
		mov	bx, cs
		mov	ax, offset nullString
		call	TextReplaceRange
done:
		.leave
		ret
TextLimitToMaxLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GTLockToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks down a the data for a RunHeapToken.

CALLED BY:	INT
PASS:		ax	= token
		ds 	= sptr.EntObjectBlock
		ss:bp	= Set/GetPropertyArgs
RETURN:		dx:ax	= buffer for data
DESTROYED:	cx, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GTLockToken	proc	near
		uses	bp, es, di
		.enter

		Assert	fptr	ssbp
		sub	sp, size RunHeapLockStruct
		mov	bx, sp
		mov	ss:[bx].RHLS_token, ax
		lea	ax, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, ssax
		movdw	dxax, ss:[bp].GPA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, dxax

		call	RunHeapLock
		mov	bx, sp
		movdw	dxax, ss:[bx].RHLS_eptr
		add	sp, size RunHeapLockStruct
		.leave
		ret
GTLockToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GTUnlockToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locks down a the data for a RunHeapToken.

CALLED BY:	INT
PASS:		ax	= token
		ds 	= sptr.EntObjectBlock
		ss:bp	= Set/GetPropertyArgs
RETURN:		
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GTUnlockToken	proc	near
		uses	bp, es, di, ax
		.enter

		Assert	fptr	ssbp
		sub	sp, size RunHeapLockStruct
		mov	bx, sp
		mov	ss:[bx].RHLS_token, ax
		movdw	dxax, ss:[bp].GPA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, dxax

		call	RunHeapUnlock
		add	sp, size RunHeapLockStruct
		.leave
		ret
GTUnlockToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextActionSetSelectionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler, sets the selection range of the text

CALLED BY:	MSG_GADGET_TEXT_ACTION_SET_SELECTION_RANGE
	
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		void SetSelectionRange(start as integer, end as integer)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	2/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextActionSetSelectionRange	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_ACTION_SET_SELECTION_RANGE
	uses	bp
		.enter
		mov	cx, 2			; really, get 2.
		call	Get2Ints		; sets cx, dx
		jc	done			; error filled in

	;
	; Make sure the range is not going to crash us.
		call	FixupRange
	;
	; Store them incase we are not visible yet.
.warn -private
		
		mov	di, ds:[si]
		add 	di, ds:[di].GadgetTextSpec_offset
		mov	ds:[di].GTSI_startSelect, cx
		mov	ds:[di].GTSI_endSelect, dx
.warn @private

		mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
		call	ObjCallInstanceNoLock
done:

		.leave
	Destroy	ax, cx, dx
	ret
GadgetTextActionSetSelectionRange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Get2Ints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets 2 ints from action args or returns an error
		if they are not there.

CALLED BY:	INTERNAL
PASS:		ss:bp		= ^fEntDoActionArgs
		cx		= 2 for 2 ints, 1 for 1
RETURN:		carry	iff	error
			error buffer filled in
		cx		= first arg
		dx		= second arg
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	2/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Get2Ints	proc	near
	uses	si,di, es
		.enter
		mov	dx, cx
	;
	; SetSelectionRange (integer start, integer end)
	;
	;
		mov	ax, CAE_WRONG_TYPE
		les	di, ss:[bp].EDAA_argv

		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		je 	int1
		cmp	es:[di].CD_type, LT_TYPE_LONG
		jne	error
		cmp	es:[di].CD_data.LD_long.high, 0
		jne	error
int1:
		cmp	dx, 1
		je	int2
		cmp	es:[di+size(ComponentData)].CD_type, LT_TYPE_INTEGER
		je	int2
		cmp	es:[di].CD_type, LT_TYPE_LONG
		jne	error
		cmp	es:[di].CD_data.LD_long.high, 0
		jne	error
int2:
	;
	; store the values
		mov	cx, es:[di].CD_data.LD_integer
		cmp	dx, 1
		je	done		; cf clear if equal
		mov	dx, es:[di+size(ComponentData)].CD_data.LD_integer
		clc
		jmp	done
error:
	; pass ComponentActionError in ax.
	;
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		stc		
done:
		
		.leave
		ret
Get2Ints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextGetStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the start or the end of the selection.

CALLED BY:	MSG_GADGET_TEXT_GET_START
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetStart	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_GET_START,
					MSG_GADGET_TEXT_GET_END
		uses	bp
		.enter
		call	GetSelectionRange
	; cx = start, dx = end
		cmp	ax, MSG_GADGET_TEXT_GET_START
		je	returnCX
		mov_tr	cx, dx
returnCX:
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextGetStart	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selected range of a text object.

CALLED BY:	INTERNAL
PASS:		*ds:si	= text object
RETURN:		cx	- start of range
		dx	- end of range
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectionRange	proc	near
		vtr	local	VisTextRange
		uses	ax,bx,bp
		.enter
		mov	bx, bp
		lea	bp, ss:[vtr]
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		call	ObjCallInstanceNoLock
		mov	bp, bx
		mov	cx, ss:[vtr].VTR_start.low
		mov	dx, ss:[vtr].VTR_end.low
		
		.leave
		ret
GetSelectionRange	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextActionDeleteRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes a range of text.

CALLED BY:	MSG_GADGET_TEXT_ACTION_DELETE_RANGE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- EntDoActionArgs
RETURN:		EDAA_retval filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
nullString	TCHAR	0
GadgetTextActionDeleteRange	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_ACTION_DELETE_RANGE
		uses	bp
		.enter
	;
	; Delete (integer start, integer end)
	;
	;
		mov	ax, CAE_WRONG_TYPE
		les	di, ss:[bp].EDAA_argv

		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error
		cmp	es:[di+size(ComponentData)].CD_type, LT_TYPE_INTEGER
		je	okay
error:
	; pass ComponentActionError in ax.
	;
		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, ax
		jmp	done		

okay:
		mov	cx, es:[di].CD_data.LD_integer
		mov	dx, es:[di][size ComponentData].CD_data.LD_integer
		mov	bx, cs
		mov	ax, offset nullString
		call	TextReplaceRange
done:
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextActionDeleteRange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextReplaceRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces a range of text. Used for replace, insert and delete

CALLED BY:	GadgetTextActionReplaceString, GadgetTextActionDeleteRange
PASS:		cx	- range start
		dx	- range end
		bxax	- fptr.char, string to add "" for delete
		*ds:si	- text object
RETURN:		ax	- num chars added
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If end < start, then swap them.
		if (no maxlines)
			

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/16/95    	Initial version
	KALPESH	8/13/96		took out ax from uses line

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextReplaceRange	proc	near
		vtr	local	VisTextReplaceParameters
		uses	bx,dx,bp,di
		.enter

		push	bp
		Assert	nullTerminatedAscii bxax
		call	FixupRange

		call	LimitTextStringToMaxChars	; di <- num chars
		push	di				; num chars added
	;
	; replace the range with the passed string.
		movdw	ss:[vtr].VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer, bxax

		clr	ax
		movdw	ss:[vtr].VTRP_range.VTR_start, axcx
		movdw	ss:[vtr].VTRP_range.VTR_end, axdx
		mov	ss:[vtr].VTRP_insCount.high, 0 ;INSERT_COMPUTE_TEXT_LENGTH
		mov	ss:[vtr].VTRP_insCount.low, di
		mov	ss:[vtr].VTRP_textReference.TR_type, TRT_POINTER

		clr	ss:[vtr].VTRP_flags
		mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
		lea	bp, ss:[vtr]
		call	ObjCallInstanceNoLock

		pop	ax				; num chars added
		pop	bp
	;
	;	FIXME: instead of deleting from the end, the spec says
	; 	to delete from the new string.  This would have to be done
	; 	with a loop for each character, ugh.
		
	; if we don't add any characters, we don't need to do this check
	; of going beyond max chars. this prevents an infinite loop as
	; TextLimitToMaxLines call TextReplaceRange with the nullString
		tst	ax
		jz	done
		push	ax
		call	TextLimitToMaxLines
		pop	ax
	; since we add all the new chars, this isn't needed.
	; actually TextLimitToMaxLines doesn't return dx yet.
	;	sub	ax, dx			; ax -= num chars removed
done:
		.leave
		ret
TextReplaceRange	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the cursor after doing InsertString(), ReplaceString(), or
		AppendString() to be after the string.

CALLED BY:	GadgetTextActionReplaceString
PASS:	 	*ds:si	- text object
	 	es:di	- string
	 	cx 	- start offset of string replacement.
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	KALPESH	8/14/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateCursor	proc	near
	uses	ax,cx,dx,bp
		.enter

		mov	dx, cx		; start of insert + string length
		call	LocalStringLength	; cx = string length
		add	dx, cx		

		mov	cx, dx
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
		call	ObjCallInstanceNoLock
		
		.leave
		ret
UpdateCursor	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LimitTextStringToMaxChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Before doing an Insert or Replace, constrict the inserted text
		so it won't make the new text > maxChars.  (otherwise the end
		of the old text would have to be deleted).  By doing the work
		ourselves, we can find out how much text is added.

CALLED BY:	TextReplaceRange
PASS:		bxax		; Null terminated string
		*ds:si		; text object
RETURN:		di		; num of chars to add
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	2/22/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LimitTextStringToMaxChars	proc	near
	uses	ax,bx,cx,dx,si,bp,es
		.enter
		movdw	esdi, bxax
		call	LocalStringLength

		mov	dx, cx		; string length
		push	dx		; string length
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		mov	bx, ax		; text length

		mov	ax, MSG_VIS_TEXT_GET_MAX_LENGTH
		call	ObjCallInstanceNoLock	; cx <-max length
		pop	dx		; string length

		sub	cx, bx		; cx <- space left
		cmp	cx, dx
		jge	done
		mov	dx, cx
done:
		mov	di, dx		; num chars to add
		
		
		.leave
		ret
LimitTextStringToMaxChars	endp




GadgetInitCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the size of the text component

CALLED BY:	GadgetTextSetWidthOfLine, GadgetTextSetNumVisibleLines,
		GadgetTextEntInitialize
PASS:		dx	= number of desired lines	; 
		cx	= number of chars
		*ds:si	= Text object
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTextSize	proc	near
	uses	bp
		.enter
		mov	ax, MSG_ENT_GET_FLAGS
		call	ObjCallInstanceNoLock
		push	ax			; save ent flags
	;
	; Set our fixed size
	;
		mov	al, VUM_DELAYED_VIA_APP_QUEUE
		call	GadgetUtilGenSetFixedSize

		pop	ax			; ent flags
		test	al, mask EF_VISIBLE
		jz	done
	;
	; Visibly unbuild and build the object so the new size takes
	; effect.
	;
		mov	ax, MSG_ENT_VIS_HIDE
		call	ObjCallInstanceNoLock
		mov	ax, MSG_ENT_VIS_SHOW
		call	ObjCallInstanceNoLock
		
		
done:
		
	.leave
	ret
SetTextSize	endp

GadgetInitCode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GadgetTextSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text component's FontID

CALLED BY:	MSG_GADGET_TEXT_SET_FONT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 nov 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetFont	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_SET_FONT
	uses	bp, es, di
	.enter

		les	di, ss:[bp].SPA_compDataPtr
	;
	; see if the font is available and get its id
		mov	ax, es:[di].CD_data.LD_string	; width
		call	RunHeapLock_asm
		segxchg	es, ds
		xchg	si, di				; ds:si <- font name

		mov	dl, mask FEF_STRING or mask FEF_BITMAPS or mask FEF_OUTLINES
		call	GrCheckFontAvail		; cx <- font id
		segxchg	es, ds
		xchg	si, di				; ds <- object block
		call	RunHeapUnlock_asm
		cmp	cx, FID_INVALID
		je	done


		sub	sp, size VisTextSetFontIDParams
		mov	bp, sp
		call	SetFullRange
		mov	ss:[bp].VTSFIDP_fontID, cx

		mov	ax, MSG_VIS_TEXT_SET_FONT_ID
		call	ObjCallInstanceNoLock
		add	sp, size VisTextSetFontIDParams
done:

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextSetFont	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GadgetTextSetFontSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text component's font size

CALLED BY:	MSG_GADGET_TEXT_SET_FONT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 nov 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GADGET_TEXT_MIN_POINT_SIZE equ 6
GADGET_TEXT_MAX_POINT_SIZE equ MAX_POINT_SIZE
GadgetTextSetFontSize	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_SET_FONT_SIZE
	uses	bp
	.enter

	les	di, ss:[bp].SPA_compDataPtr
	mov	ax, es:[di].CD_data.LD_integer	; width
		
	;
	; If the size < 4 or > 792 return an error or geos will crash
		cmp	ax, GADGET_TEXT_MIN_POINT_SIZE
		jl	errorDone
		cmp	ax, GADGET_TEXT_MAX_POINT_SIZE
		jg	errorDone
		
	sub	sp, size VisTextSetPointSizeParams
	mov	bp, sp
	call	SetFullRange
	mov	ss:[bp].VTSPSP_pointSize.WWF_int, ax
	mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0

	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	call	ObjCallInstanceNoLock
	add	sp, size VisTextSetPointSizeParams
done:

	.leave
	Destroy	ax, cx, dx
		ret

errorDone:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	done
GadgetTextSetFontSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GadgetTextSetFontStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text component's font style

CALLED BY:	MSG_GADGET_TEXT_SET_FONT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 nov 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetFontStyle	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_SET_FONT_STYLE
		.enter
		mov	bx, di

		les	di, ss:[bp].SPA_compDataPtr
		mov	ax, es:[di].CD_data.LD_integer	; width
		mov	ds:[bx].GTI_fontStyle, ax
		call	SetFontStyleLow
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextSetFontStyle	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFontStyleLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the font for the text object, but only if the
		text object is visible.

CALLED BY:	GadgetTextSetFontStyle, SpecBuild
PASS:		ax		= font id
		*ds:si		= TextObject
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/30/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFontStyleLow	proc	near
		uses	bp
		.enter
		Assert	objectPtr, dssi, GadgetTextClass
	;
	; If not visible, don't do anything
	;
		push	ax			; style
		mov	ax, MSG_VIS_GET_ATTRS
		call	ObjCallInstanceNoLock
		test	cl, mask VA_REALIZED
		pop	ax			; style
		je	done
		
		

		sub	sp, size VisTextSetTextStyleParams
		mov	bp, sp
		call	SetFullRange
		mov	ss:[bp].VTSTSP_styleBitsToSet, ax
		not	ax
		mov	ss:[bp].VTSTSP_styleBitsToClear, ax
		clr	ax
		mov	ss:[bp].VTSTSP_extendedBitsToSet, ax
		mov	ss:[bp].VTSTSP_extendedBitsToClear, ax

		mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
		call	ObjCallInstanceNoLock
		add	sp, size VisTextSetTextStyleParams
done:
		.leave
		ret
SetFontStyleLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GadgetTextSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text component's color

CALLED BY:	MSG_GADGET_TEXT_SET_FONT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 nov 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetColor	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_SET_COLOR
	uses	bp
	.enter

		mov	dx, di				; instance data
		les	di, ss:[bp].SPA_compDataPtr
		movdw	axbx, es:[di].CD_data.LD_long	; width
	;
	; FIXME: there should be common code for ensuring it is a long
	; or converting ints to long in Ent.
	; (at least don't duplicate code here and SET_BG_COLOR)

	; if we got an int, set ax to 0.
		cmp	es:[di].CD_type, LT_TYPE_LONG
		je	gotLong
		clr	ax
	; sign extend ax, don't 0 it.
		cmp	bx, 0
		jg	gotLong
		dec	ax		
		
gotLong:
		mov	di, dx				; instance data
		movdw	ds:[di].GTI_fgColor, axbx

	;
	; Create stack space for setting the color
	;
		sub	sp, size VisTextSetColorParams
		mov	bp, sp
		call	SetFullRange

		mov	ss:[bp].VTSCP_color.CQ_redOrIndex, al
		mov	ss:[bp].VTSCP_color.CQ_info, CF_RGB
		mov	ss:[bp].VTSCP_color.CQ_green, bh
		mov	ss:[bp].VTSCP_color.CQ_blue, bl

		mov	dl, ah			; opacity
		mov	ax, MSG_VIS_TEXT_SET_COLOR
		call	ObjCallInstanceNoLock
		mov	al, dl			; opacity
		call	ConvertByteToMask
		mov	ss:[bp].VTSGSP_grayScreen, al	; SystemDrawMask
		mov	ax, MSG_VIS_TEXT_SET_GRAY_SCREEN
		add	sp, size VisTextSetColorParams

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextSetColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GadgetTextSetBGColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text component's wash color

CALLED BY:	MSG_GADGET_TEXT_SET_FONT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 nov 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetBGColor	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_SET_BG_COLOR
	.enter

		mov	dx, di				; inst data
		les	di, ss:[bp].SPA_compDataPtr
		movdw	axbx, es:[di].CD_data.LD_long
		mov	ch, CF_RGB

	; if we got an int, set ax to 0.
		cmp	es:[di].CD_type, LT_TYPE_LONG
		je	gotLong
		clr	ax
	; sign extend ax, don't 0 it.
		cmp	bx, 0
		jg	gotLong
		dec	ax		
gotLong:
		xchg	di, dx				; inst data
		movdw	ds:[di].GTI_bgColor, axbx

		mov	cl, al			; red
		mov	dl, bh			; green
		mov	dh, bl			; blue
		mov	ax, MSG_VIS_TEXT_SET_WASH_COLOR
		call	ObjCallInstanceNoLock

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextSetBGColor	endm

GadgetTextGetBGColor	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_GET_BG_COLOR
	.enter

	movdw	cxdx, ds:[di].GTI_bgColor
	les	di, ss:[bp].GPA_compDataPtr
	Assert	fptr	esdi
	mov	es:[di].CD_type, LT_TYPE_LONG
	movdw	es:[di].CD_data.LD_long, cxdx

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextGetBGColor	endm

SetFullRange	proc	near
	.enter
	movdw	ss:[bp].VTR_start, 0
	movdw	ss:[bp].VTR_end, TEXT_ADDRESS_PAST_END
	.leave
	ret
SetFullRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GadgetTextGetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the text component's FontID

CALLED BY:	MSG_GADGET_TEXT_GET_FONT
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 nov 1995	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetFont	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_GET_FONT
	.enter

	;
	; Create a string on the run heap
	;
		mov	cx, FONT_NAME_LEN
		mov	bx, RHT_STRING
		mov	dl, 0
		clrdw	axdi				; no init data
		call	RunHeapAlloc_asm		; ax <- RunHeapToken
		push	ax				;token

		mov	di, offset VTCA_fontID
		call	GadgetTextGetAttrCommon
		mov	cx, ax				; FontID

		pop	ax				; token
		push	ax				; token
		call	RunHeapLock_asm
		segxchg	es, ds
		xchg	di, si
		Assert	fptr, dssi
		call	GrGetFontName			; store in RunHeap
		segxchg	es, ds
		xchg	si, di
		pop	ax				; token
		call	RunHeapUnlock_asm


		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextGetFont	endm

GadgetTextGetFontSize	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_GET_FONT_SIZE
	.enter

	mov	di, offset VTCA_pointSize + offset WBF_int
	call	GadgetTextGetAttrCommon

	les	di, ss:[bp].GPA_compDataPtr
	Assert	fptr	esdi
	mov	es:[di].CD_type, LT_TYPE_INTEGER
	mov	es:[di].CD_data.LD_integer, ax

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextGetFontSize	endm

GadgetTextGetFontStyle	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_GET_FONT_STYLE
	.enter

	mov	di, offset VTCA_textStyles
	call	GadgetTextGetAttrCommon

	les	di, ss:[bp].GPA_compDataPtr
	Assert	fptr	esdi
	mov	es:[di].CD_type, LT_TYPE_INTEGER
	clr	ah
	mov	es:[di].CD_data.LD_integer, ax

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextGetFontStyle	endm

GadgetTextGetFontColor	method dynamic GadgetTextClass, 
			MSG_GADGET_TEXT_GET_COLOR
	.enter
	;
	; Use stored value instead of asking the text for the
	; color so we can return opacity as passed in easier
	;

	movdw	axbx, ds:[di].GTI_fgColor
if 0		
	mov	di, offset VTCA_color + offset CQ_redOrIndex
	call	GadgetTextGetAttrCommon
endif
	les	di, ss:[bp].GPA_compDataPtr
	Assert	fptr	esdi
	mov	es:[di].CD_type, LT_TYPE_LONG
	movdw	es:[di].CD_data.LD_long, axbx

	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextGetFontColor	endm

GadgetTextGetAttrCommon	proc	near
params		local	VisTextGetAttrParams
attrs		local	VisTextCharAttr
diffs		local	VisTextCharAttrDiffs
	.enter

	push	di
	lea	di, ss:[attrs]
	movdw	ss:[params].VTGAP_attr, ssdi
	lea	di, ss:[diffs]
	movdw	ss:[params].VTGAP_return, ssdi
	mov	ss:[params].VTGAP_flags, 0

	;
	;  Since the text object should only have a single point
	;  size/color/whatever, we'll just ask for the properties
	;  at the very beginning.
	;
	clr	ax
	movdw	ss:[params].VTGAP_range.VTR_start, axax
	movdw	ss:[params].VTGAP_range.VTR_end, axax

	push	bp
	lea	bp, ss:[params]
	mov	ax, MSG_VIS_TEXT_GET_CHAR_ATTR
	call	ObjCallInstanceNoLock
	pop	bp

	pop	di
	mov	ax, {word} ss:[attrs][di]

	.leave
	ret
GadgetTextGetAttrCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextGetNumLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of visible lines

CALLED BY:	MSG_GADGET_TEXT_GET_NUM_LINES
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetNumLines	method dynamic GadgetTextClass, 
				MSG_GADGET_TEXT_GET_NUM_LINES
		.enter

		call	TextCountLines

		Assert	fptr ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax

		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextGetNumLines	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCountLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Counts the number of lines of a text object.

CALLED BY:	GadgetTextGetNumLines
PASS:		*ds:si		- Text object
RETURN:		ax		- number of displayable.
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	I don't know how to get the size of a non-visible,
	non-fixed-size text object.  But since Liberty only allows
	text objects to be of fixed size, we shouldn't have to worry
	about this for PCV.  The only caveat is that MSG_VIS_TEXT_CALC
	_HEIGHT won't work if the text object's VI_bounds are wrong.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/18/96    	Initial version
	jmagasin 9/26/96	Use HINT_FIXED_SIZE if possible.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCountLines	proc	near
		uses	cx,si,bp,dx
		.enter
	;
	; Grab the fixed size.  PCV apps will have the hint because
	; Liberty requires it.
	;
		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock
		mov	ax, MSG_SPEC_CONVERT_DESIRED_SIZE_HINT
		call	ObjCallInstanceNoLock	; cx <- width in pixels
		jcxz	notSizeAsSpecified

	;
	; Calculate the height for the desired width.
	;
getTextHeight:
		mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
		clr	dx			; don't cache result
		call	ObjCallInstanceNoLock	; dx <- height in pixels

	;
	; Divide total height by height per line.
	; (Ignore warning about not being able to use this message.
	;  All our lines are the same height and use the default gstate
	;  so it is ok.)
		push	dx			; total height
		mov	ax, MSG_VIS_TEXT_GET_LINE_HEIGHT
		call	ObjCallInstanceNoLock	; ax <- lineheight
		pop	dx			; total height

		xchg	dx, ax			; ax <- total height,
						; dl <- line height
		mov	cx, dx			; line height
		clr	dx			; high word of total height
		div	cx

		.leave
		ret

	;
	; Try to get our vis-height.  If we're not visible or we're
	; being built out, then this won't work.
	;
notSizeAsSpecified:
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock	; cx <- width (we hope)
		jmp	getTextHeight
TextCountLines	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextVisPositionBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't use positioning hints on VisText in the view.

CALLED BY:	MSG_VIS_POSITION_BRANCH
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextVisPositionBranch	method dynamic GadgetTextClass, 
					MSG_VIS_POSITION_BRANCH
		.enter

	;
	; If we are in a view, then don't indent us by the ATTR_GEN_POS
	; inside the view too.
	;
		call	TextIsInView
		jnc	setPos
		clrdw	cxdx
setPos:
		mov	ax, MSG_VIS_POSITION_BRANCH
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock
		.leave
		ret
GadgetTextVisPositionBranch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextIsInView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the text is currently in a scrolling view.

CALLED BY:	
PASS:		*ds:si		- text object
RETURN:		CF		- set if in view, clear if not
		ax		- nptr of view if it exists
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
		FIXME:  see if MSG_SPEC_GET_SPECIFIC_VIS_OBJECT will help
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextIsInViewFar	proc	far	textobj:optr
		uses	ds
		.enter
		movdw	bxsi, textobj
		call	MemDerefDS
		call	TextIsInView
		mov	dx, ds:[LMBH_handle]
		jc	done
		clr	dx
		clr	ax
done:
		.leave
		ret
TextIsInViewFar	endp

TextIsInView	proc	near
		uses	bx, cx, dx, si, es, di, bp
		.enter

		push	ds:[LMBH_handle]
		mov	ax, MSG_VIS_FIND_PARENT
		call	ObjCallInstanceNoLock
	; if no parent, take off
		jcxz	done

	; Check to see if the parent is a content.
		movdw	bxsi, cxdx
		call	ObjLockObjBlock
		mov	ds, ax		; *ds:si = content
		mov	ax, segment GenContentClass
		mov	es, ax
		mov	di, offset GenContentClass
		call	ObjIsObjectInClass
		jnc	unlockDone

	;
	; Now get the parent of the GenContent
	; If we just got added to it, then the parent of the VisContent is
	; 0.
	;
		mov	ax, MSG_VIS_FIND_PARENT
		call	ObjCallInstanceNoLock
		jcxz	unlockDone

		call	MemUnlock		; content
		movdw	bxsi, cxdx
		call	ObjLockObjBlock
		mov	ds, ax		; *ds:si = view

		mov	ax, segment GenViewClass
		mov	es, ax
		mov	di, offset GenViewClass
		call	ObjIsObjectInClass
		jnc	unlockDone

	;
	; Now, just make sure the view isn't an Ent thing.
	;
		mov	ax, segment EntClass
		mov	es, ax
		mov	di, offset EntClass
		call	ObjIsObjectInClass
		jc	unlockDone
		call	MemUnlock
	;
	; The text object is in a content and view. 
	; Make sure there are no ATTR_GEN_POS_*** on the text object.
	;
removeAttrs::
		mov	ax, si		; nptr of view
		stc
		jmp	done

unlockDone:
	;
	; unlock bx
		clc
		call	MemUnlock

done:
		pop	bx
		call	MemDerefDS
		.leave
		ret
TextIsInView	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetLeftTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the coordinate.

CALLED BY:	MSG_GADGET_GET_LEFT, MSG_GADGET_GET_TOP
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= EntGetPropertyArgs
RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_integer filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		FIXME, try to merge this with the GadgetMaster code

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/30/95	Initial version
	dloft	7/18/95		Fixed vis positioning
	jimmy   4/10/96		changed to call super if not visually built
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetLeftTop	method dynamic GadgetTextClass, 
					MSG_GADGET_GET_LEFT,
					MSG_GADGET_GET_TOP
	;
	; If we are in a view, then return its vis position, not our
		push	ax

		push	bp		
		mov	ax, MSG_VIS_GET_ATTRS
		call	ObjCallInstanceNoLock
		pop	bp
		test	cl, mask VA_REALIZED
		
		jz	useGen
				
		call	TextIsInView
		jnc	getPos
		mov	si, ax
getPos:

	;
	; If we've got to use the vis position, we must return the value
	; relative to our parent.... sigh.
	;
	;		push	bp, dx
		push	bp			; bp
		mov	ax, MSG_VIS_GET_POSITION
		call	ObjCallInstanceNoLock
		push	cx, dx			; save our position
		mov	ax, MSG_VIS_GET_POSITION
		call	VisCallParent
		pop	bp, ax			; restore our position
		neg	cx
		neg	dx
		add	cx, bp			; calculate position relative
		add	dx, ax			; to parent
		pop	bp 			; bp
		pop	ax			; message

		cmp	ax, MSG_GADGET_GET_LEFT
		je	getCommon
		mov_tr	cx, dx
getCommon:
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
done:		
		.leave
		Destroy	ax, cx, dx
		ret
useGen:
	; the gadget master code should do nicely
		pop	ax
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock
		jmp	done
GadgetTextGetLeftTop	endm

		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextSetFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the filter for the text object

CALLED BY:	MSG_GADGET_TEXT_SET_FILTER
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If it is a normal vis text filter add it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetFilter	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_SET_FILTER
		.enter
		call	SetTextFilterCommon

		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextSetFilter	endm


GEOS_TEXT_FILTER_OFFSET equ 30

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextFilterCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text filter and needed vardata on the text object.

CALLED BY:	SET_FILTER routines on entry and text
PASS:		ss:bp		- GetPropertyArgs
		*ds:si		- text object
RETURN:		nadan
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/ 5/95    	Initial version
	RON	2/ 15/96	Commented out string filters and rearranged
				numbers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTextFilterCommon	proc	near
		class	GadgetTextSpecClass
		uses	bp
	.enter
		
		Assert	fptr ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr esdi
		mov	ax, es:[di].CD_data.LD_integer
;;		cmp	ax, FILTER_CUSTOM_STRING
;;		jb	standardTextFilter
		cmp	ax, FILTER_CUSTOM_CHAR
		ja	standardTextFilter

;;		CheckHack <FILTER_CUSTOM_STRING + 1 eq FILTER_CUSTOM_CHAR >
		CheckHack <VTEFT_REPLACE_PARAMS + 1 eq VTEFT_CHARACTER_LEVELER_LEVEL>
	;
	; Store the filter in instance data
	;
		Assert	objectPtr, dssi, GadgetTextSpecClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetTextSpec_offset
		mov	ds:[di].GTSI_filter, ax

		push	ax		; filter
;;		mov_tr	dx, ax	
;;		sub	dx, FILTER_CUSTOM_STRING - VTEFT_REPLACE_PARAMS

		mov	ax, ATTR_VIS_TEXT_EXTENDED_FILTER
		mov	cx, size byte
		call	ObjVarAddData
		mov	{byte} ds:[bx], VTEFT_CHARACTER_LEVELER_LEVEL
		pop	ax		; filter

	;
	; If it is a string filter, then disable reject warnings
	;
if 0 ; not needed because string filters are gone
		cmp	ax, FILTER_CUSTOM_STRING
		jne	done
		mov	ax, ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR
		call	ObjVarAddData
endif	; string filters are gone
		jmp	doneNoRemove
			
standardTextFilter:
	;
	; If not valid, return an error
	;
		cmp	ax, GEOS_TEXT_FILTER_OFFSET
		jge	setFilter
		les	di, ss:[bp].SPA_compDataPtr
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	doneNoRemove
setFilter:
	;
	; Assume setting the filter clears other filters
		mov	cx, ax
		push	cx				; legos filter
		sub	cx, GEOS_TEXT_FILTER_OFFSET
		mov	ax, MSG_VIS_TEXT_SET_FILTER
		call	ObjCallInstanceNoLock
		pop	cx				; legos filter
	; set the instance data too.
	; store the basic filter number, not the VisText filter number so
	; it can be returned in Get() easier.
		Assert	objectPtr, dssi, GadgetTextSpecClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetTextSpec_offset
		mov	ds:[di].GTSI_filter, cx
done::
		mov	ax, ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR
		call	ObjVarDeleteData
doneNoRemove:
	.leave
	ret
SetTextFilterCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextGetFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_GET_FILTER
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/ 6/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetFilter	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_GET_FILTER
		.enter
		call	GetTextFilterCommon
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextGetFilter	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextFilterCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the filter on the text object

CALLED BY:	GET_FILTER messages for text and entry.
PASS:		*ds:si		- Text object
		ss:bp		- GetPropertyArgs
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextFilterCommon	proc	near
		class	GadgetTextSpecClass

		.enter
		Assert	objectPtr, dssi, GadgetTextSpecClass

		Assert	fptr	ssbp
		mov	di, ds:[si]
		add	di, ds:[di].GadgetTextSpec_offset
		mov	cx, ds:[di].GTSI_filter

		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr, esdi
		mov	es:[di].CD_data.LD_integer, cx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
	.leave
	ret
GetTextFilterCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextVisTextFilterViaReplaceParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent to filter characters because the user wants to.
		This will generate a basic event.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
		ss:bp	= VisTextReplaceParameters
RETURN:		Carry Set to reject replacement.  Will always be set as
		it expects the user to add the text at this point.
DESTROYED:	
SIDE EFFECTS:
		If there was a memory error creating the string for the event
		handler, then string will automatically be rejected.

PSEUDO CODE/STRATEGY:
		We expect the user to add text during the basic handler.
		If that happens we don't filter that text as it would cause
		an infinite loop.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
filterStringString	TCHAR "filterString", 0

GadgetTextVisTextFilterViaReplaceParams	method dynamic GadgetTextClass, 
					MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS
		uses	ax, cx, dx, bp
		.enter
		call	FilterTextCommon
	;
	;  Only the filterString event is allowed to add text, so
	;  we need to tell the internal text code to reject this thing
	;
		stc

		.leave
		ret
GadgetTextVisTextFilterViaReplaceParams	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilterTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_REPLACE_PARAMS for text and entry
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
		ss:bp	= VisTextReplaceParameters
RETURN:		Carry Set to reject replacement.  Will always be set as
		it expects the user to add the text at this point.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilterTextCommon	proc	near
	.enter

	;
	; Do what it takes to raise an event
	;
	; first make sure the string isn't too big to create a heap token for
	;
		Assert	fptr	ssbp
		cmpdw	ss:[bp].VTRP_insCount, MAX_TEXT_INSERTION_STRING
		ja	filterProcessed

		call	AllocStringFromReplaceParams
		jc	filterProcessed

	;	ax <- token, alread set
	;	bx <- start
	; 	cx <- end
	; 	dx <- 3 args
		Assert	fptr	ssbp
		mov	bx, ss:[bp].VTRP_range.VTR_start.low
		mov	cx, ss:[bp].VTRP_range.VTR_end.low
		mov	dx, 3
		mov	di, offset filterStringString
		call	GadgetTextRaiseEvent
filterProcessed:

done::
	.leave
	ret
FilterTextCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocStringFromReplaceParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a basic string to represent the string about to
		be filtered

CALLED BY:	Custom filter handler
PASS:		ss:bp		- VisTextReplaceParameters
RETURN:		ax		- RunHeapToken with lock count of 0
		CF		- set if couldn't allocate
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocStringFromReplaceParams	proc	near
		uses	si,ds,bp
		.enter
		mov	ax, ss:[bp].VTRP_textReference.TR_type
		cmp	ax, TRT_POINTER
		je	pointer
		Assert	e ax, TRT_HUGE_ARRAY
		cmp	ax, TRT_HUGE_ARRAY
		je	hugeArray
		stc
		jmp	done
pointer:
	; for now assume it is TRT_POINER, looking at the code for the
	; text library, the only other possibility it TRT_HUGE_ARRAY.

		mov	cx, ss:[bp].VTRP_insCount.low
		inc	cx				; add null
DBCS <		inc	cx						>
		mov	bx, RHT_STRING
		clr	dl
		movdw	axdi, ss:[bp].VTRP_textReference.TR_ref.TRU_pointer
		Assert	fptr	axdi
		call	RunHeapAlloc_asm
		jmp	done
hugeArray:
		mov	cx, ss:[bp].VTRP_insCount.low
		inc	cx				; add null
DBCS <		inc	cx						>
		mov	bx, RHT_STRING
		clr	dl
		clrdw	axdi			; don't initi with data
		call	RunHeapAlloc_asm
		jc	done

		call	RunHeapLock_asm		; es:di = block
		call	EnumTextFromHugeArray
		call	RunHeapUnlock_asm
		
		

done:
		.leave
		ret

AllocStringFromReplaceParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnumTextFromHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy text from a huge-array into a buffer.

CALLED BY:	EnumTextReference
		ss:bp	= TextReferenceHugeArray
		cs:di	= callback for filter
RETURN:		carry	= set if callback aborted
DESTROYED:	ax, bx, cx, dx, bp, es

PSEUDO CODE/STRATEGY:
	Lock first element of huge-array
    copyLoop:
	Copy as many bytes as we can (up to cx)
	If we aren't done yet
	    Release the huge-array and lock the next block of data
	    jmp copy loop

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnumTextFromHugeArray	proc	near

		uses	ax, bx, cx, dx, bp, es, ds, si
		.enter

	push	di				; Save callback
	mov	bx, ss:[bp].VTRP_textReference.TR_ref.TRU_hugeArray.TRHA_file
	mov	di, ss:[bp].VTRP_textReference.TR_ref.TRU_hugeArray.TRHA_array
	clrdw	dxax
	call	HugeArrayLock			; ds:si <- data to copy
	pop	di				; Restore callback

enumLoop:
	mov_tr	cx, ax				; cx <- # of valid bytes
	;
	; Override file = huge array file
	; ds:si = data
	; di	= callback
	; cx	= Number of bytes available
	;
	; Okay, this is really cheesy because each character is an element
	; in the huge array, but the code was copied from the text library
	; so it must work.
		
		Assert	okForRepMovsb
		rep	movsb
		dec	si
		call	HugeArrayNext
		tst_clc	ax
		jnz	enumLoop

done::
		pushf
		call	HugeArrayUnlock
		popf

		.leave
		ret

EnumTextFromHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextVisTextFilterViaCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used to filter new strings a char at a time.

CALLED BY:	MSG_VIS_TEXT_FILTER_VIA_CHARACTER
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
		cx	= character
RETURN:		cx 	- 0 to reject replacement, other the replacement char
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/31/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextVisTextFilterViaCharacter	method dynamic GadgetTextClass, 
					MSG_VIS_TEXT_FILTER_VIA_CHARACTER
		.enter
	;
	; If already filtered by KBD_CHAR, don't do it again.
	;
		mov	ax, ATTR_GADGET_TEXT_DONT_FILTER
		call	ObjVarFindData
		jc	done		; return char passed
		call	FilterViaCharCommon

done:
		.leave
		ret
GadgetTextVisTextFilterViaCharacter	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilterViaCharCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raises an event so the script writer can filter chars
		one at a time.

CALLED BY:	GadgetTextVisTextFilterViaChar, GadgetEntryVisTextFilterViaChar
PASS:		cx		- char
RETURN:		cx		- char user returned
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
filterCharString	TCHAR	"filterChar", 0
FilterViaCharCommon	proc	near
 		params		local	EntHandleEventStruct
		result		local	ComponentData
		uses	ax, dx, bp
		.enter
	;
	; The call should be:
	;  _filterChar(newChar as integer, replaceStart as integer,
	;		replaceEnd as integer, endOfGroup as integer)
	;		as integer
	;
	; The return value is used as the new char.
	; endOfGroup is sent if the last char in a group pasted in
	;
	;
	; FIXME: for now pass 0 for replaceStart, replaceEnd and endOfGroup.
	; We need to really handle this int FilterVia string to get the
	; correct values and send the event for each char ourselves.
	;
	; NOTE: replaceStart and replaceEnd should not change if there is
	; more than character being pasted in.
		
		push	cx			; char
		mov	di, offset filterCharString
		movdw	ss:[params].EHES_eventID.EID_eventName, csdi
		lea	di, ss:[result]
		movdw	ss:[params].EHES_result, ssdi
		mov	ss:[params].EHES_argc, 4

	; newchar
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[0].CD_data.LD_integer, cx

		call	GetSelectionRange ; cx:dx = range

	; replaceStart
		mov	ss:[params].EHES_argv[size ComponentData].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[size ComponentData].CD_data.LD_integer, cx

	; replaceEnd
		mov	ss:[params].EHES_argv[2*(size ComponentData)].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[2*(size ComponentData)].CD_data.LD_integer, dx

		clr	ax		; used in following arg
	; endOfGroup
		mov	ss:[params].EHES_argv[3*(size ComponentData)].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[3*(size ComponentData)].CD_data.LD_integer, ax
		

		lea	dx, ss:[params]
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock
		pop	cx				; orig char
		cmp	ax, 0
		je	done

		cmp	ss:[result].CD_type, LT_TYPE_INTEGER
		jne	done
		mov	cx, ss:[result].CD_data.LD_integer		

done:

		.leave
		ret
FilterViaCharCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextRaiseEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a basic event telling the user about new Text

CALLED BY:	
PASS:		ax		- arg1	, TYPE_STRING
		bx		- arg2	, TYPE_INTEGER
		cx		- arg3	, TYPE_INTEGER
		dx		- number of args
		di		- offset to string
		ds:si		- GadetText component
RETURN:		nada
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextRaiseEvent	proc	near
 		params		local	EntHandleEventStruct
		result		local	ComponentData
		ForceRef	result
		uses	ax, cx, dx, bp
		.enter
		movdw	ss:[params].EHES_eventID.EID_eventName, csdi
		lea	di, ss:[params]
		movdw	ss:[params].EHES_result, ssdi
		mov	ss:[params].EHES_argc, dx
		cmp	dx, 0
		je	send
		mov	ss:[params].EHES_argv[0].CD_type, LT_TYPE_STRING
		mov	ss:[params].EHES_argv[0].CD_data.LD_string, ax
		cmp	dx, 1
		je	send
		mov	ss:[params].EHES_argv[size ComponentData].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[size ComponentData].CD_data.LD_integer, bx
		cmp	dx, 2
		je	send
		Assert	e dx, 3
		mov	ss:[params].EHES_argv[2*(size ComponentData)].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[2*(size ComponentData)].CD_data.LD_integer, cx
		
send:
		mov	dx, di
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	cx, ss				; cx:dx = params
		call	ObjCallInstanceNoLock

		.leave
	ret
GadgetTextRaiseEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the passed range is valid for the text object
		or fixes it up if it isn't.

CALLED BY:	
PASS:		cx		- range start (signed)
		dx		- range end (signed)
		*ds:si		- text object
RETURN:		cx		- valid range start
		dx		- valid range end
		carry set if invalid range 

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/ 9/95    	Initial version
	KALPESH	8/14/96		Added checks for invalid range and set carry if
				errors.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupRange	proc	near
		uses	ax
		invalidRange	local	byte
		.enter

		clr	ss:[invalidRange]
	; make sure the start is before the end.
		cmp	cx, dx
		jle	okToSet
		xchg	cx, dx
		mov	ss:[invalidRange], 1
okToSet:
	; make sure start is not negative
		tst	cx
		jge	checkEnd
		clr	cx
		mov	ss:[invalidRange], 1
checkEnd:
	; make sure end is not negative
		tst	dx
		jge	checkEnd2
		clr	dx
		mov	ss:[invalidRange], 1
checkEnd2:
	; ensure start and end are before the end of the text
		push	dx
		Assert	objectPtr, dssi, VisTextClass
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock

		Assert	e dx, 0			; Legos text must be
 		Assert	srange ax, 0, 32767	; <= 32767

		pop	dx
		cmp	cx, ax			; make sure beginning not\
						; past end
		jle	ok1
		mov	cx, ax
		mov	ss:[invalidRange], 1
ok1:
		cmp	dx, ax
		jle	checkError
		mov_tr	dx, ax			; set dx to end
		mov	ss:[invalidRange], 1

checkError:
		tst	ss:[invalidRange]
		jnz	error

		clc
		jmp	ok
error:
		stc
ok:
		
		.leave
		ret
FixupRange	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextActionGetString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a range of text

CALLED BY:	MSG_GADGET_TEXT_ACTION_GET_STRING
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextActionGetString	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_ACTION_GET_STRING
		uses	bp
		.enter
		Assert	fptr	ssbp
		push	bp				; frame ptr
		les	di, ss:[bp].EDAA_argv

		mov	cx, es:[di].CD_data.LD_integer
		mov	dx, es:[di][size ComponentData].CD_data.LD_integer
		call	FixupRange

		push	cx, dx			;range
	; now calculate amount of space needed for the string
		sub	cx, dx
		neg	cx
		inc	cx			; length of string and null
DBCS <		shl	cx						>

	; create a runheap token and space in the runheap for the text
	; cx = size of space needed for string and NULL
		mov	bx, RHT_STRING
		mov	dl, 0
		clrdw	axdi
		
		call	RunHeapAlloc_asm	; ax <- new token
		call	RunHeapLock_asm
		pop	cx, dx			; range
		push	ax			; string token
		
		mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE
		sub	sp, size VisTextGetTextRangeParameters
		mov	bp, sp
		clr	bx
		movdw	ss:[bp].VTGTRP_range.VTR_start, bxcx
		movdw	ss:[bp].VTGTRP_range.VTR_end, bxdx
		mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_POINTER
		movdw	ss:[bp].VTGTRP_textReference.TR_ref.TRU_pointer, esdi
		mov	ss:[bp].VTGTRP_flags, 0
		call	ObjCallInstanceNoLock
		add	sp, size VisTextGetTextRangeParameters
		pop	ax			; string token
		call	RunHeapUnlock_asm
		mov	dx, LT_TYPE_STRING
		

		pop	bp			; frame ptr

return::
	; dx = type, ax = value
		Assert	fptr	ssbp
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, dx
		mov	es:[di].CD_data.LD_integer, ax

		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextActionGetString	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextGetNumChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_GET_NUM_CHARS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/18/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetNumChars	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_GET_NUM_CHARS
		.enter
		push	bp				; frame ptr
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		pop	bp				; frame ptr

		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		Assert	e, dx, 0
		mov	es:[di].CD_data.LD_integer, ax
		
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextGetNumChars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextGetFirstVisibleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_GET_FIRST_VISIBLE_LINE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Find the view origin and divide by line height.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/18/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetFirstVisibleLine	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_GET_FIRST_VISIBLE_LINE,
					MSG_GADGET_TEXT_GET_LAST_VISIBLE_LINE
		passedBP	local	word	push	bp
		message		local	word	push	ax
		textObject	local	nptr	push	si
		origin		local	PointDWord
		increment	local	PointDWord
		uses	bp
		.enter
	;
	; if its not in a view, then the first visible line = 0
	;
		clr	dx
		call	TextIsInView
		jnc	returnDX
		mov	si, ax		; GenView
	;
	; Get the origin of the view, then divide by line height
	;
		push	bp
		mov	ax, MSG_GEN_VIEW_GET_ORIGIN
		mov	cx, ss
		lea	dx, ss:[origin]
		call	ObjCallInstanceNoLock
		pop	bp
	;
	; The view increment is the same as the text line height
	;
		push	bp			; frame ptr
		mov	cx, ss
		lea	dx, ss:[increment]
		mov	ax, MSG_GEN_VIEW_GET_INCREMENT
		call	ObjCallInstanceNoLock
		pop	bp			; frame ptr
	;
	; If we are getting the last visible row, then
	; Add the view height to the origin and subtract one line
	;
		cmp	ss:[message], MSG_GADGET_TEXT_GET_FIRST_VISIBLE_LINE
		je	doTheMath
		Assert	e, ss:[message], MSG_GADGET_TEXT_GET_LAST_VISIBLE_LINE

	; Ask view for its visible size
	; If not visible or built out, this may not work, bummer.
		
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
		
		mov	ax, ss:[increment].PD_y.low
		sub	dx, ax			; subtract one line

		add	ss:[origin].PD_y.low, dx
		adc	ss:[origin].PD_y.high, 0
doTheMath:
	; divide the origin by the increment to get the line number.
	; Sometimes the origin is a pixel or two past the official line
	; boundary, but it doesn't hurt our calculations.
		movdw	dxcx, ss:[origin].PD_y
		movdw	bxax, ss:[increment].PD_y
		call	GrSDivWWFixed

	;
	; If we are getting the last visible line, make sure it
	; isn't more than the number of lines.
		cmp	ss:[message], MSG_GADGET_TEXT_GET_FIRST_VISIBLE_LINE
		je	returnDX
		mov	si, ss:[textObject]
		call	TextCountLines
		dec	ax	; last visible line is one less then number
		cmp	ax, dx
		jge	returnDX
		xchg	ax, dx
		
returnDX:
		mov	di, passedBP
		Assert	fptr	ssdi
		les	di, ss:[di].SPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextGetFirstVisibleLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextSetFirstVisibleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_SET_FIRST_VISIBLE_LINE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Compute what the origin for the view would be and scroll
		there.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/18/96   	Initial version
	KALPESH	8/14/96		Added check for negative input to
				firstVisibleLine.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetFirstVisibleLine	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_SET_FIRST_VISIBLE_LINE,
					MSG_GADGET_TEXT_SET_LAST_VISIBLE_LINE
		
		passedBP	local	word	push	bp
		increment	local	PointDWord
		origin		local	PointDWord
		msg		local	word
		view		local	hptr
		uses	bp
		.enter

		mov	msg, ax
		
		call	TextIsInView
		jnc	done

		mov	view, ax			; GenView
		mov	di, passedBP
		Assert	fptr	ssdi
		les	di, ss:[di].SPA_compDataPtr
		Assert	fptr	esdi
		mov	ax, es:[di].CD_data.LD_integer

		cmp	msg, MSG_GADGET_TEXT_SET_FIRST_VISIBLE_LINE
		je	gotLine

	; if we are setting the last visible line, just subtract the number
	; of visible lines and add one to get the first visible line
		push	bp, ax, es, di
		sub	sp, size GetPropertyArgs
		mov	bp, sp
		sub	sp, size ComponentData
		mov	ss:[bp].GPA_compDataPtr.segment, ss
		mov	ss:[bp].GPA_compDataPtr.offset, sp
		mov	ax, MSG_GADGET_TEXT_GET_LAST_VISIBLE_LINE
		call	ObjCallInstanceNoLock
		les	di, ss:[bp].GPA_compDataPtr
		mov	cx, es:[di].CD_data.LD_integer
		mov	ax, MSG_GADGET_TEXT_GET_FIRST_VISIBLE_LINE
		push	cx
		call	ObjCallInstanceNoLock
		pop	cx
		mov	ax, es:[di].CD_data.LD_integer
		sub	cx, ax
		add	sp,size GetPropertyArgs + size ComponentData
		pop	bp, ax, es, di
	; cx = number of visible lines - 1
	; if we subtract this value from the last line target value we can
	; a set fist line
		sub	ax, cx
gotLine:		
		cmp	ax, 0
		jge	fine

		mov	ax, 0
fine:

		mov	si, view
		push	ax			; line to scroll to
	;
	; Get the height of each line by asking the GenView for the increment
		push	bp			; frame ptr
		mov	cx, ss
		lea	dx, ss:[increment]
		mov	ax, MSG_GEN_VIEW_GET_INCREMENT
		call	ObjCallInstanceNoLock
		pop	bp			; frame ptr

		movdw	bxcx, ss:[increment].PD_y
	; multiply line height by line number
		pop	ax			; line number
		mul	cx
		pushdw	dxax			; new origin
	;
	; Now scroll there
	;
		push	bp
		mov	ax, MSG_GEN_VIEW_GET_ORIGIN
		mov	cx, ss
		lea	dx, ss:[origin]
		call	ObjCallInstanceNoLock
		pop	bp

		popdw	dxax			; new origin
		
		movdw	ss:[origin].PD_y, dxax
		push	bp			; frame ptr
		mov	cx, ss
		lea	bp, ss:[origin]
		mov	dx, size PointDWord
		mov	ax, MSG_GEN_VIEW_SET_ORIGIN
		call	ObjCallInstanceNoLock
		pop	bp			; frame ptr
done:
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextSetFirstVisibleLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextMetaKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send all keys as basic events if the user has specified
		a custom filter. Only send keys that wouldn't normally
		get caught by filter mechanism (i.e cursor keys, delete...)


CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
		cx	= character value
			SBCS: ch = CharacerSet, cl = Chars
			DBCS: cx = Chars
		dl	= CharFlags
		dh	= ShiftState
		bp low	= ToggleState
		bp high = scan code
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	2/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextMetaKbdChar	method dynamic GadgetTextSpecClass, 
					MSG_META_KBD_CHAR
		uses	es
		.enter
	;
	; Find out where we are inserting the character so we can
	; delete it if needed.
	;
		push	cx, dx			;args
		call	GetSelectionRange
		mov	ax, cx			; selection start
		pop	cx, dx			;args
		push	ax			; selection start

	;
	; If we don't care, pass to superclass and exit
		cmp	ds:[di].GTSI_filter, FILTER_CUSTOM_CHAR
		jne	callSuperAndExit

		test	dl, mask CF_RELEASE
		jnz	callSuperAndExit
		
		call	FilterViaCharCommon
	; if they don't want to add anything, just leave.
		jcxz	popAX
	;
	; FIXME: becareful not pass on chars that will kill the text
	; object!.  LocalIsDosChar?

callSuperAndExit:
	;
	; Add flag so we don't filter again when superclass handles it.
	;
		push	cx, bx
		mov	ax, ATTR_GADGET_TEXT_DONT_FILTER
		clr	cx
		call	ObjVarAddData
		pop	cx, bx

		mov	ax, MSG_META_KBD_CHAR
		
		mov	di, offset GadgetTextSpecClass
		call	ObjCallSuperNoLock


	;
	; FIXME: instead of deleting the char of the end, we
	; should erase the last char that was added.
	; but only on text, not entries
		pop	dx			; selection start
		mov	ax, segment GadgetTextClass
		mov	es, ax
		mov	di, offset GadgetTextClass
		call	ObjIsObjectInClass
		jnc	done

	; see if we have too many lines
		call	GetMaxLines
		jcxz	done			; no limit, leave
		call	TextCountLines
		cmp	ax, cx
		jle	done			; not past limit

	;
	; remove the last character added.
	;
	; Perhaps I should just use TextReplaceRange

		mov	cx, dx
		inc	dx		; delete char just added
		mov	bx, cs
		mov	ax, offset nullString
		call	TextReplaceRange
		call	TextLimitToMaxLines
		jmp	done
if 0
		mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
		mov	cx, VTKF_DELETE_BACKWARD_CHAR
		call	ObjCallSuperNoLock
endif
popAX:
		pop	ax
done:
		mov	ax, ATTR_GADGET_TEXT_DONT_FILTER
		call	ObjVarDeleteData
		

		.leave
		ret
GadgetTextMetaKbdChar	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextSpecSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize Vis properties.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= GadgetTextSpecClass object
		ds:di	= GadgetTextSpecClass instance data
		ds:bx	= GadgetTextSpecClass object (same as *ds:si)
		es 	= segment of GadgetTextSpecClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSpecSpecBuild	method dynamic GadgetTextSpecClass, 
					MSG_SPEC_BUILD
		.enter
		mov	di, offset GadgetTextSpecClass
		call	ObjCallSuperNoLock

	;
	; Now set the vis properties
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetTextSpec_offset

	;
	; If it is a custom filter, then the vardata will be set correctly
	; and we don't need to set the VisFilter. Actually it will crash if
	; you do.
	; Unfortunately, the vardata has disappeared.  I don't know at what
	; point it gets removed, but I'll add it back in here.
	;
		mov	cx, ds:[di].GTSI_filter
;;		cmp	cx, FILTER_CUSTOM_STRING
;;		jl	visFilter
		jcxz	range
		cmp	cx, FILTER_CUSTOM_CHAR
;;		jg	done
		jg	visFilter


;;		mov	dx, cx			; filter
;;		sub	dx, FILTER_CUSTOM_STRING - VTEFT_REPLACE_PARAMS

		mov	ax, ATTR_VIS_TEXT_EXTENDED_FILTER
		mov	cx, size byte
		call	ObjVarAddData
		mov	{byte}ds:[bx], VTEFT_CHARACTER_LEVELER_LEVEL


		jmp	range


visFilter:
		Assert	g, cx, GEOS_TEXT_FILTER_OFFSET
		mov	ax, MSG_VIS_TEXT_SET_FILTER
		mov	cx, ds:[di].GTSI_filter
		sub	cx, GEOS_TEXT_FILTER_OFFSET	; use vis numbers.
		call	ObjCallInstanceNoLock

range:
		Assert	objectPtr, dssi, GadgetTextSpecClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetTextSpec_offset
	;
	; Now set the selection
		mov	cx, ds:[di].GTSI_startSelect
		mov	dx, ds:[di].GTSI_endSelect
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
		call	ObjCallInstanceNoLock

	; I want the text component to act like it got the target so it shows
	; the selection property
	;
	; Don't do this for EC code as it causes a VIS_TEXT_GAINED_TARGET
	; _ALREADY_TARGET death in VisTextGainedTargetExcl.  The error
	; is abortable, but really annoying. -jmagasin 10/10
NEC <		mov	ax, MSG_META_GAINED_TARGET_EXCL			>
NEC <		call	ObjCallInstanceNoLock				>
done::
	
		.leave
		ret
GadgetTextSpecSpecBuild	endm

GadgetTextSpecSpecUnBuild	method dynamic GadgetTextSpecClass, 
					MSG_SPEC_UNBUILD
		.enter
		mov	di, offset GadgetTextSpecClass
		call	ObjCallSuperNoLock
	;
	; Get the current selection and save it.
	;
		call	GetSelectionRange
		mov	di, ds:[si]
		add	di, ds:[di].GadgetTextSpec_offset
		mov	ds:[di].GTSI_startSelect, cx
		mov	ds:[di].GTSI_endSelect, cx
		.leave
		ret

GadgetTextSpecSpecUnBuild	endm


GadgetTextSpecBuild	method dynamic GadgetTextClass, 
					MSG_SPEC_BUILD
		.enter
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock

	;
	; Now set the vis color properties
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetText_offset
		movdw	axbx, ds:[di].GTI_bgColor
	; we need to shift as opacity is in the wrong place
		mov	cl, al		;red
		mov	dl, bh		;green
		mov	dh, bl		; blue
		mov	ch, CF_RGB
		mov	ax, MSG_VIS_TEXT_SET_WASH_COLOR
		call	ObjCallInstanceNoLock

	;
	; Set the font
		mov	di, ds:[si]
		add	di, ds:[di].GadgetText_offset
		mov	ax, ds:[di].GTI_fontStyle
		call	SetFontStyleLow
		.leave
		ret
GadgetTextSpecBuild	endm

GadgetTextMetaInitialize	method dynamic GadgetTextClass, 
				MSG_META_INITIALIZE
	uses	ax, cx, dx, bp
	.enter

	mov	di, offset GadgetTextClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].GadgetText_offset
	movdw	ds:[di].GTI_bgColor, 0xFFFFFFFF	; white
		movdw	ds:[di].GTI_fgColor, 0xFF000000	; black
		mov	ds:[di].GTI_fontStyle, 0

	.leave
	ret
GadgetTextMetaInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the scrollbar from the view we are in.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextVisOpen	method dynamic GadgetTextClass, 
					MSG_VIS_OPEN
		.enter
		push	bp		; parent window
	;
	; If we are in a view, then set some attrs on it to
	; not display the scrollbar.
		push	si			; self
		call	TextIsInView
		jnc	done
		mov	si, ax
		Assert	objectPtr, dssi, GenViewClass
		mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
		clr	cx		; don't change horiz attrs
		mov	dl, mask GVDA_DONT_DISPLAY_SCROLLBAR
		clr	dh			; don't clear anything
		mov	bp, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjCallInstanceNoLock
done:
		pop	si			; self
		pop	bp		;parent window
		mov	ax, MSG_VIS_OPEN
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock
	;
	; Make sure the text does not violate the maxlines property
	;
		call	TextLimitToMaxLines

		.leave
		ret
GadgetTextVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextVisTextHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a Legos event to notify height change

CALLED BY:	MSG_VIS_TEXT_HEIGHT_NOTIFY
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
textHeightChangedString TCHAR "numLinesChanged", 0

GadgetTextVisTextHeightNotify	method dynamic GadgetTextClass, 
					MSG_VIS_TEXT_HEIGHT_NOTIFY
		.enter
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock

		clr	dx
		mov	di, offset textHeightChangedString
		call	GadgetTextRaiseEvent
		.leave
		ret
GadgetTextVisTextHeightNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextMetaContentTrackScrolling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a legos event whenever the text scrolls.

CALLED BY:	MSG_META_CONTENT_TRACK_SCROLLING
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
textScrolledString TCHAR "scrolled", 0

GadgetTextMetaContentTrackScrolling	method dynamic GadgetTextClass,
					MSG_META_CONTENT_VIEW_ORIGIN_CHANGED
		
	;					MSG_META_CONTENT_TRACK_SCROLLING
		.enter
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock

		clr	dx
		mov	di, offset textScrolledString
		call	GadgetTextRaiseEvent
		.leave
		ret
GadgetTextMetaContentTrackScrolling	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextVisTextShowSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When scrolling bring the next line just on screen
		instead of trying to center it.
		This matches pcv and gets rid of the problem of
		text being chopped at the top and bottom of the view when
		there is an even number of lines and text gets centered
		mid-line.

CALLED BY:	MSG_VIS_TEXT_SHOW_SELECTION
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextVisTextShowSelection	method dynamic GadgetTextClass, 
					MSG_VIS_TEXT_SHOW_SELECTION
		.enter
		mov	ss:[bp].VTSSA_params.MRVP_yMargin, MRVM_0_PERCENT
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock
		.leave
		ret
GadgetTextVisTextShowSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextGetMaxChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_GET_MAX_CHARS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetMaxChars	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_GET_MAX_CHARS
		.enter
		mov	ax, MSG_VIS_TEXT_GET_MAX_LENGTH
		call	ObjCallInstanceNoLock

		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_data.LD_integer, cx
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextGetMaxChars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextSetMaxChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_SET_MAX_CHARS
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetMaxChars	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_SET_MAX_CHARS
	uses	bp
		.enter
		Assert	fptr, ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr, esdi
		mov	cx, es:[di].CD_data.LD_integer
		cmp	cx, GADGET_TEXT_MAX_CHARS
		ja	done		; disallows negative numbs too

	;
	; if less than current size, don't set it
	;
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		cmp	cx, ax
		jl	done
		
		mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
		call	ObjCallInstanceNoLock

done:		
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextSetMaxChars	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextSetMaxLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_SET_MAX_LINES
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSetMaxLines	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_SET_MAX_LINES
		uses	es
		.enter
		mov	bx, di			; inst data
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	dx, es:[di].CD_data.LD_integer
		cmp	dx, 0
		je	set
		jl	done
	;
	; If less than current number of lines, then ignore
	;
		call	TextCountLines
		cmp	dx, ax
		jl	done
set:
		mov	ds:[bx].GTI_maxLines, dx
done:
		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextSetMaxLines	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextGetMaxLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_GET_MAX_LINES
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	1/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextGetMaxLines	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_GET_MAX_LINES
		uses	es
		.enter
		mov	ax, ds:[di].GTI_maxLines

		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_data.LD_integer, ax
		mov	es:[di].CD_type, LT_TYPE_INTEGER

		.leave
		Destroy	ax, cx, dx
		ret
GadgetTextGetMaxLines	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextActionGetLineNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Legos Property Handler

CALLED BY:	MSG_GADGET_TEXT_ACTION_GET_LINE_NUMBER
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	2/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextActionGetLineNumber	method dynamic GadgetTextClass, 
					MSG_GADGET_TEXT_ACTION_GET_LINE_NUMBER
	uses	es
		.enter
		mov	cx, 1			; get 1 int
		call	Get2Ints
		jc	done
		clr	dx
		xchg	cx, dx			; dx <- offset, cx <- 0

		push	bp			; frame ptr
		mov	ax, MSG_VIS_TEXT_GET_LINE_FROM_OFFSET
		call	ObjCallInstanceNoLock
		pop	bp			; frame ptr

		les	di, ss:[bp].EDAA_retval
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, ax
done:
	.leave
	Destroy	ax, cx, dx
	ret
GadgetTextActionGetLineNumber	endm



;************************************************************************
;
; The following section contains methods that GadgetTextClass intercepts
; to skip the default GadgetClipboardableClass behavior.
;
;************************************************************************


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextSkipClipboardableBehavior
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some clipboardable messages should be intercepted
		and dropped because the text component and clipboard
		take care of things internally.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_RAISE_ACCEPT_PASTE_EVENT
		MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextSkipClipboardableBehavior	method dynamic GadgetTextClass, 
			MSG_GADGET_CLIPBOARDABLE_RAISE_ACCEPT_PASTE_EVENT,
			MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
		.enter
		.leave
		ret
GadgetTextSkipClipboardableBehavior	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextClipboardItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Text components should not raise an acceptPaste
		event when the clipboard changes (as do other
		clipboardables).

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
		cx:dx	= optr of clipboard component that sent us this
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextClipboardItemChanged	method dynamic GadgetTextClass, 
				MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED
		.enter

		mov	ax, MSG_SCB_RAISE_CLIPBOARD_CHANGED_EVENT
		mov	bx, cx
		mov	si, dx
		clr	di
		call	ObjMessage
		
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetTextClipboardItemChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetTextMetaClipboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The text object in us knows how to handle clipboard events.
		So have the superclass handle the received clipboard message,
		but skip the clipboardable handler because it will raise
		an event.

CALLED BY:	MSG_META_CLIPBOARD_CUT
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 5/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetTextMetaClipboard	method dynamic GadgetTextClass, 
					MSG_META_CLIPBOARD_CUT,
					MSG_META_CLIPBOARD_COPY,
					MSG_META_CLIPBOARD_PASTE,
					MSG_META_DELETE
		.enter

		mov	di, offset GadgetClipboardableClass
		call	ObjCallSuperNoLock
		
		.leave
		ret
GadgetTextMetaClipboard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GTMetaLargeEndOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hack to unset DOING_SELECTION bit in vis instance data

CALLED BY:	MSG_META_LARGE_END_OTHER
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/16/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GTMetaLargeEndOther	method dynamic GadgetTextClass, 
					MSG_META_LARGE_END_OTHER
		.enter
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock

EC <		call	VisCheckVisAssumption				>
		mov	di, ds:[si]
		add	di, ds:[di].VisText_offset
		andnf	ds:[di].VTI_intSelFlags, not mask VTISF_DOING_SELECTION

		.leave
		ret
GTMetaLargeEndOther	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GTEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/24/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GTEntDestroy	method dynamic GadgetTextClass, 
					MSG_ENT_DESTROY
		uses	ax, cx, dx, bp
		.enter
		mov	ax, MSG_VIS_RELEASE_MOUSE
		call	ObjCallInstanceNoLock

		mov	di, offset GadgetTextClass
		mov	ax, MSG_ENT_DESTROY
		call	ObjCallSuperNoLock
		.leave
		ret
GTEntDestroy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GTGadgetSetLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_SET_LEFT
PASS:		*ds:si	= GadgetTextClass object
		ds:di	= GadgetTextClass instance data
		ds:bx	= GadgetTextClass object (same as *ds:si)
		es 	= segment of GadgetTextClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GTGadgetSetLeft	method dynamic GadgetTextClass, 
					MSG_GADGET_SET_LEFT,
					MSG_GADGET_SET_TOP
	uses	ax, cx, dx, bp
		.enter

		push	ax, bp
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
		pop	ax, bp
		mov	di, offset GadgetTextClass
		call	ObjCallSuperNoLock

	; NOTE: because the SET_LEFT handler in GadgetClass does a
	; ENT_HIDE/ENT_SHOW we don't need to do anything else here
		
		.leave
		ret
GTGadgetSetLeft	endm

GadgetTextCode ends

