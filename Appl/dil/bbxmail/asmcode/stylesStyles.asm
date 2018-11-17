COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Designs in Light 2002 -- All Rights Reserved

PROJECT:	Mail
FILE:		stylesStyles.asm

AUTHOR:		Gene Anderson

DESCRIPTION:
	Code for styles support that was a hell of a lot easier, smaller,
	faster, and kept in code segments in assembly than in C.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AsmCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushPosCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common code to save the start of a tag position

CALLED BY:	Utility

PASS:		^lbx:di - text object
		al - StyleStackTag, ah - size
		dx - extra data if needed
RETURN:		none
DESTROYED:	ax, cx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	
PushPosCommon	proc	near
		uses	bx, dx, di
		.enter

		push	ax				;save StyleStackTag
		push	dx				;save extra data
		sub	sp, (size VisTextRange)
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		call	CallTextCommon
		movdw	bxcx, ss:[bp].VTR_start
		add	sp, (size VisTextRange)
		pop	dx				;dx <- extra data
		pop	ax				;ax <- StyleStackTag
		call	StyleStackPush

		.leave
		ret
PushPosCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallTextStackCommon, CallTextSelectionCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call the text object

CALLED BY:	Utility

PASS:		^lbx:di - text object
		ss:bp - ptr to structure with VisTextRange at start
		dx - size of structure
RETURN:		none
DESTROYED:	ax, bx, cx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

CallTextRangeToCommon	proc	near
		push	ax, cx, dx
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_START
		call	CallTextCommon
		decdw	dxcx
		movdw	ss:[bp].VTR_end, dxcx
		pop	ax, cx, dx
		jmp	CallTextStackCommon
CallTextRangeToCommon	endp

CallTextSelectionCommon	proc	near
		mov	ss:[bp].VTR_start.low, 0
		mov	ss:[bp].VTR_start.high, VIS_TEXT_RANGE_SELECTION
		FALL_THRU CallTextStackCommon
CallTextSelectionCommon	endp

CallTextStackCommon	proc	near
		uses	dx, di
		.enter

		mov	si, di
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage

		.leave
		ret
CallTextStackCommon	endp

CallTextCommon	proc	near
		uses	di
		.enter

		mov	si, di
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave

		ret
CallTextCommon	endp

AppendTextCommon	proc	near
		uses	ax, dx, di
		.enter

		mov	dx, cs				;dx:bp <- ptr to text
		mov	ax, MSG_VIS_TEXT_APPEND_PTR
		mov	si, di				;^lbx:si <- object
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
AppendTextCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindEqual, FindSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip past an equal sign or spaces

CALLED BY:	Utility

PASS:		es:di - ptr to text
RETURN:		es:di - ptr after space or equal
DESTROYED:	ax

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FindCommon	proc	near
		uses	ax
		.enter

equalLoop:
		LocalGetChar ax, esdi			;ax <- char?
SBCS <		cmp	al, dl				;match?>
DBCS <		cmp	ax, dx				;match?>
		je	found				;branch if match
		LocalCmpChar ax, '>'			;end of tag?
		jne	equalLoop			;branch if not
notFound::
		stc					;carry <- not found
done:
		.leave
		ret

found:
		clc					;carry <- found
		jmp	done
FindCommon	endp

FindEqual	proc	near
		uses	dx
		.enter

		LocalLoadChar dx, '='
		call	FindCommon

		.leave
		ret
FindEqual	endp

FindSpace	proc	near
		uses	dx
		.enter

		LocalLoadChar dx, ' '
		call	FindCommon

		.leave
		ret
FindSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LookupString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up a string in a table

CALLED BY:	Utility

PASS:		es:di - ptr to tag
		cs:si - ptr to table (-1 terminated)
RETURN:		ax - index (0 if not found)
		carry - set if not found
DESTROYED:	ds, si

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

LookupString	proc	near
		uses	cx
		.enter

		segmov	ds, cs
		clr	ax				;ax <- 1st element
searchLoop:
		push	si
		mov	si, ds:[si]			;ds:si <- ptr to string
		cmp	si, -1				;end of table?
		je	endTable			;branch if so
		push	es, di
		segmov	es, ds
		mov	di, si
		call	LocalStringLength		;cx <- string len.
		pop	es, di
		call	LocalCmpStringsNoCase
		pop	si
		clc					;carry <- found
		je	done				;branch if found
		inc	ax				;ax <- next element
		add	si, (size nptr)			;ds:si <- next entry
		jmp	searchLoop

endTable:
		clr	ax				;ax <- 0 index
		stc					;carry <- not found
		pop	si
done:
		.leave
		ret
LookupString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a text byte to the actual value

CALLED BY:	Utility

PASS:		es:di - ptr to text
		cs:si - ptr to past text
RETURN:		bl - value
DESTROYED:	bh

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ConvertNibble	proc	near
		LocalCmpChar ax, '9'
		ja	isLetter
isDigit::
		sub	al, C_ZERO
		ret
isLetter:
SBCS <		clr	ah				;>
		call	LocalUpcaseChar
		sub	al, C_CAP_A - 10
		ret
ConvertNibble	endp

ConvertByte	proc	near
		uses	ax
		.enter

		LocalGetChar ax, esdi
		call	ConvertNibble
		mov	bl, al				;bl <- nibble1
		shl	bl, 1
		shl	bl, 1
		shl	bl, 1
		shl	bl, 1				;bl <- nibble1*16
		LocalGetChar ax, esdi
		call	ConvertNibble
		ornf	bl, al				;bl <- n1*16+n2

		.leave
		ret
ConvertByte	endp


SetHTMLColor	proc	near
	;
	; check for ="# at start
	;
		call	FindEqual
		jc	done				;branch if not found
		LocalGetChar ax, esdi			;ax <- char
		LocalCmpChar ax, '"'			;"?
		je	skippedQuote
		LocalPrevChar esdi			;back up for non-quote
skippedQuote:
		LocalGetChar ax, esdi			;ax <- char
		LocalCmpChar ax, '#'			;#?
		jne	done				;branch if not #
	;
	; convert the string into RGB color
	;
		push	bx, cx
		call	ConvertByte
		mov	al, bl				;al <- red
		call	ConvertByte
		mov	cl, bl				;cl <- green
		call	ConvertByte
		mov	ch, bl				;ch <- blue
		mov	ah, CF_RGB			;ah <- ColorFlag
		pop	bx, di				;^lbx:di <- text obj
	;
	; call the text object and set the color
	;
		call	SetColorCommon
done:
		ret
SetHTMLColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetColorCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle font tags

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		cx:ax - ColorQuad (al=R, cl=G, ch=B, ah=flag)
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, si

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SetBlack	proc	near
		mov	ax, CF_INDEX shl 8 or C_BLACK
		clr	cx				;axcx <- black
		FALL_THRU	SetColorCommon
SetBlack	endp

SetColorCommon	proc	near
		uses	dx
		.enter

		mov	dx, (size VisTextSetColorParams)
		sub	sp, dx
		mov	bp, sp
		movdw	ss:[bp].VTSCP_color, cxax
		mov	ax, MSG_VIS_TEXT_SET_COLOR
		call	CallTextSelectionCommon
		add	sp, dx

		.leave
		ret
SetColorCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle PARAM tags

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to end tag
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PSParam		proc	near
		mov	ax, FS_IN_BODY		;assume ending
		tst	dl			;ending?
		jnz	gotState		;branch if ending tag
	;
	; we mark ourselves as still in a tag so that the colors
	; that are between <PARAM> and </PARAM> will get removed.
	;
		mov	ax, FS_IN_TAG
gotState:
		ret
PSParam		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle CR-related tags

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to end tag
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

psCRStr TCHAR "\r";

PSCR	proc	near
		tst	dl				;end?
		jnz	done				;branch if so
		call	AppendCR
done:
		mov	ax, FS_IN_BODY			;ax <- FilterState
		ret
PSCR	endp

AppendCR	proc	near
		push	cx, bp
		mov	cx, 1				;cx <- length
		mov	bp, offset psCRStr		;cs:bp <- str
		call	AppendTextCommon
		pop	cx, bp
		ret
AppendCR	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetHRef, ClearHRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle <A HREF=> tags (hyperlink)

CALLED BY:	PSHRef()

PASS:		^lbx:cx - text object
		es:di - ptr to tag
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SetHRef	proc	near
	;
	; skip the 'A'
	;
		call	FindSpace
		LONG jc	done				;branch if not found
	;
	; look for HREF=
	;
		mov	si, offset hrefTable		;cs:si <- ptr to table
		call	LookupString
		LONG jc	done				;branch if not found
		call	FindEqual
		jc	done				;branch if not found
		LocalGetChar ax, esdi
		LocalCmpChar ax, '"'
		jne	done				;branch if not found
		mov	dx, 1				;dx <- adjust for "
SetURL label  near
	;
	; set the color to blue
	; and set the style to underline
	;
		xchg	di, cx				;^lbx:di <- text obj
		mov	ax, CF_INDEX shl 8 or C_BLUE
		push	cx, dx
		call	SetColorCommon
		clr	dl				;dl <- start tag
		call	PSUnderline
		pop	cx, dx
	;
	; create a name from the URL
	;
		xchg	di, cx				;es:di <- tag
		push	cx
		call	LocalStringLength		;cx <- length
		sub	cx, dx				;cx <- -1 for "
		mov	ax, cx				;ax <- length
		pop	cx
		cmp	ax, NAME_ARRAY_MAX_NAME_LENGTH	;length OK?
		ja	done				;branch if too long
		mov	dx, (size VisTextAddNameParams)
		sub	sp, dx
		mov	bp, sp
		movdw	ss:[bp].VTANP_name, esdi
		mov	di, cx				;^lbx:di <- text obj
		mov	ss:[bp].VTANP_size, ax
		mov	ss:[bp].VTANP_flags, 0
		mov	ss:[bp].VTANP_data.VTND_type, VTNT_CONTEXT
		mov	ss:[bp].VTANP_data.VTND_contextType, VTCT_TEXT
		mov	ss:[bp].VTANP_data.VTND_file, VIS_TEXT_CURRENT_FILE_TOKEN
		movdw	ss:[bp].VTANP_data.VTND_helpText, 0
		mov	ax, MSG_VIS_TEXT_ADD_NAME
		call	CallTextStackCommon		;ax <- name token
	;
	; save the start of the range and the token for later
	;
		mov	dx, ax				;dx <- name token
		mov	ax, (3*(size word) shl 8) or SST_START_HREF
		call	PushPosCommon
		add	sp, (size VisTextAddNameParams)
done:
		ret
SetHRef	endp

psSpaceStr TCHAR " ";

ClearHRef	proc	near
	;
	; set the color back to black
	; and clear the underline
	;
		mov	di, cx				;^lbx:di <- text obj
		call	PSUnderline
		call	SetBlack
	;		
	; get the saved start and the current/end of the range
	;
		mov	dx, (size VisTextSetHyperlinkParams)
		sub	sp, dx
		mov	bp, sp
		push	bx
		mov	al, SST_START_HREF		;al <- tag
		call	StyleStackPop
		mov	ax, bx				;axcx <- offset
		pop	bx				;^lbx:di <- text obj
		jc	doneEndTag			;branch if not found
	;
	; put a space in to keep things both hunky and dory
	;
		push	cx, bp
		mov	cx, 1				;cx <- length
		mov	bp, offset psSpaceStr		;cs:bp <- str
		call	AppendTextCommon
		pop	cx, bp
	;
	; set a link on the range
	;
		mov	ss:[bp].VTSHLP_context, dx
		movdw	ss:[bp].VTSHLP_range.VTR_start, axcx
		mov	ss:[bp].VTSHLP_file, VIS_TEXT_CURRENT_FILE_TOKEN
		mov	ss:[bp].VTSHLP_flags, mask VTCF_TOKEN
		mov	dx, (size VisTextSetHyperlinkParams)
		mov	ax, MSG_VIS_TEXT_SET_HYPERLINK
		call	CallTextRangeToCommon
doneEndTag:
		add	sp, (size VisTextSetHyperlinkParams)
		ret
ClearHRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSHRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle <A HREF=> tags (hyperlink)

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to end tag
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

psHREFStr TCHAR "HREF", 0;

hrefTable nptr \
	psHREFStr,
	-1

PSHRef	proc	near
		mov	es, ax
		xchg	di, cx				;es:di <- ptr to tag
							;^lbx:cx <- text obj
		tst	dl				;end?
		jnz	clearRef
		call	SetHRef
		
done:
		mov	ax, FS_IN_BODY			;ax <- FilterState
		ret

clearRef:
		call	ClearHRef
		jmp	done
PSHRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSBlockquote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle BLOCKQUOTE

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to end tag
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PSBlockquote	proc	near
		tst	dl				;end tag?
		jnz	endBlock			;branch if so
	;
	; save the start of the range
	;
		mov	ax, ((size dword) shl 8) or SST_START_BLOCKQUOTE
		call	PushPosCommon
done:
		mov	ax, FS_IN_BODY			;ax <- FilterState
		ret

endBlock:
	;
	; get the start of the range
	;
		push	bx
		mov	al, SST_START_BLOCKQUOTE
		call	StyleStackPop
		mov	dx, bx				;dx:cx <- selection
		pop	bx
		jc	done				;branch if not found
	;
	; get the end of the range
	;
		sub	sp, (size VisTextSetBorderBitsParams)
		mov	bp, sp
		mov	ss:[bp].VTSBBP_bitsToSet, mask VTPBF_LEFT
		mov	ss:[bp].VTSBBP_bitsToClear, 0
		movdw	ss:[bp].VTSBBP_range.VTR_start, dxcx
	;
	; set the border bits
	;
		mov	dx, (size VisTextSetBorderBitsParams)
		mov	ax, MSG_VIS_TEXT_SET_BORDER_BITS
		call	CallTextRangeToCommon
	;
	; set the border thickness so it is more visible
	;
CheckHack <(size VisTextSetBorderWidthParams) le (size VisTextSetBorderBitsParams)>
		mov	ss:[bp].VTSBWP_width, 2*8
		mov	dx, (size VisTextSetBorderWidthParams)
		mov	ax, MSG_VIS_TEXT_SET_BORDER_WIDTH
		call	CallTextRangeToCommon
		add	sp, (size VisTextSetBorderBitsParams)
	;
	; spit out a CR for good measure
	;
		call	AppendCR
		jmp	done
PSBlockquote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle font tags

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to end font tag
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

psfColorStr TCHAR "COLOR", 0;

fontTable nptr \
	psfColorStr,
	-1

PSFont	proc	near
		tst	dl				;clearing?
		jnz	clearFont			;branch if so
		mov	es, ax
		xchg	di, cx				;es:di <- ptr to tag
							;^lbx:cx <- text obj
	;
	; skip font
	;
		call	FindSpace
		jc	done				;branch if not found
	;
	; look for COLOR=
	;
		mov	si, offset fontTable		;cs:si <- ptr to table
		call	LookupString
		jc	done				;branch if not found
		call	SetHTMLColor
done:
		mov	ax, FS_IN_BODY			;ax <- FilterState
		ret

clearFont:
		call	SetBlack
		jmp	done
PSFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSBold, PSItalic, PSUnderline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle a text style

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to clear style
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PSBold		proc	near
		mov	ax, mask TS_BOLD		;ax <- set bold
		GOTO	SetStyleCommon
PSBold		endp

PSItalic	proc	near
		mov	ax, mask TS_ITALIC		;ax <- set italic
		GOTO	SetStyleCommon
PSItalic	endp

PSUnderline	proc	near
		mov	ax, mask TS_UNDERLINE		;ax <- set underline
		FALL_THRU	SetStyleCommon
PSUnderline	endp

SetStyleCommon	proc	near
		uses	bp
		.enter

	;
	; check for setting or clearing
	;
		clr	cx				;cx <- bits to clear
		tst	dl				;on or off?
		jz	gotBits				;branch if on
		xchg	cx, ax				;cx <- clear style
gotBits:
		mov	dx, (size VisTextSetTextStyleParams)
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].VTSTSP_extendedBitsToSet, 0
		mov	ss:[bp].VTSTSP_extendedBitsToClear, 0
		mov	ss:[bp].VTSTSP_styleBitsToSet, ax
		mov	ss:[bp].VTSTSP_styleBitsToClear, cx
		mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
		call	CallTextSelectionCommon
		add	sp, dx
		mov	ax, FS_IN_BODY			;ax <- new state

		.leave
		ret
SetStyleCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSAlign, PSCenter, PSRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle text alignment

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to clear alignment
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

psaLeftStr TCHAR "LEFT", 0;
psaRightStr TCHAR "RIGHT", 0;
psaCenterStr TCHAR "CENTER", 0;

alignTable nptr \
	psaLeftStr,
	psaRightStr,
	psaCenterStr,
	-1

PSAlign		proc	near
		push	di
		movdw	esdi, axcx			;es:di <- ptr to tag
		call	FindEqual			;es:di <- ptr after =
		jc	done				;branch if not found
		mov	si, offset alignTable
		call	LookupString			;dx <- index of string
		pop	di
		mov	cl, offset VTDPA_JUSTIFICATION
		shl	ax, cl				;dx <- shift into pos.
		GOTO	SetAlignmentCommon
done:
		pop	di
		mov	ax, J_LEFT shl offset VTDPA_JUSTIFICATION
		GOTO	SetAlignmentCommon
PSAlign		endp

PSRight		proc	near
		mov	ax, J_RIGHT shl offset VTDPA_JUSTIFICATION
		GOTO	SetAlignmentCommon
PSRight		endp

PSCenter	proc	near
		mov	ax, J_CENTER shl offset VTDPA_JUSTIFICATION
		FALL_THRU	SetAlignmentCommon
PSCenter	endp

SetAlignmentCommon	proc	near
		uses	bp
		.enter

	;
	; check for setting or clearing
	;
		tst	dl
		jnz	endAlignment			;branch if clearing
	;
	; save the start pos
	;
		mov	dx, ax				;dx <- Alignment
		mov	ax, ((size dword)+(size word)) shl 8 or SST_START_ALIGN
		call	PushPosCommon
done:
	;
	; note we've emitted a CR
	;
		mov	ax, FS_ADDED_CR			;ax <- FilterState

		.leave
		ret

endAlignment:
	;
	; we also need to emit a CR, because paragraph attrs
	; apply to...paragraphs.
	;
		call	AppendCR
	;
	; set the alignment on the range, and set left justified after it
	;
		push	bx
		mov	al, SST_START_ALIGN
		call	StyleStackPop			;bx:cx <- offset
		mov	ax, dx				;ax <- Alignment
		mov	dx, bx				;dx:cx <- offset
		pop	bx
		jc	done				;branch if not found
		sub	sp, (size VisTextSetParaAttrByDefaultParams)
		mov	bp, sp
		ornf	ax, VTDDT_INCH shl offset VTDPA_DEFAULT_TABS
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].VTSPABDP_paraAttr, ax
		movdw	ss:[bp].VTSPABDP_range.VTR_start, dxcx
		mov	dx, (size VisTextSetParaAttrByDefaultParams)
		mov	ax, MSG_VIS_TEXT_SET_PARA_ATTR_BY_DEFAULT
		call	CallTextRangeToCommon
		clr	ss:[bp].VTSPABDP_paraAttr
		mov	ax, MSG_VIS_TEXT_SET_PARA_ATTR_BY_DEFAULT
		call	CallTextSelectionCommon
		add	sp, dx
		jmp	done
SetAlignmentCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle list items, albeit simply

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to clear list
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

pslBullet TCHAR C_CR," ",C_BULLET," "

PSList	proc	near
		tst	dl				;end tag?
		jnz	done				;branch if so
	;
	; add "* " for list items
	;
		push	bp
		mov	bp, offset pslBullet		;cs:bp <- text
		mov	cx, length pslBullet		;cx <- length
		call	AppendTextCommon
		pop	bp
done:
		mov	ax, FS_IN_BODY
		ret
PSList	endp

	;
	; for end of list, emit CR
	; this is opposite of <BR> which works on the start tag
	;
PSEndList	proc	near
		not	dl
		jmp	PSCR
PSEndList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSHTML
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle HTML tag

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to clear attr
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PSHTML	proc	near
		mov	ax, FS_FOUND_HTML
		ret
PSHTML	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle STYLE tag

CALLED BY:	ProcessStyleTag()

PASS:		^lbx:di - text object
		dl - TRUE to clear attr
		ax:cx - ptr to tag
RETURN:		ax - FilterState
DESTROYED:	ax, bx, cx, dx, si, di

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PSStyle	proc	near
		mov	ax, FS_IN_STYLE_SHEET
		tst	dl
		jz	done
		mov	ax, FS_IN_BODY
done:
		ret
PSStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessRichTag, ProcessHTMLTag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	process a rich-text style or an HTML tag

CALLED BY:	FilterMailStyles() (C routine)

PASS:		textObj - optr of text object
		tag - ptr to tag text
		len - length of tag text
RETURN:		FilterState - current state (FS_ADDED_CR or FS_IN_BODY)
DESTROYED:	ax, bx, cx, dx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ProcessStyleEntry	struct
    PSE_name	  nptr.TCHAR;		;tag name
    PSE_function  nptr.near;		;handler
    PSE_cmp	  nptr.near;		;cmp routine
ProcessStyleEntry	ends

bStr TCHAR "B", 0
iStr TCHAR "I",  0
uStr TCHAR "U", 0
divStr TCHAR "DIV", 0
fontStr TCHAR "FONT", 0
brStr TCHAR "BR", 0
pStr TCHAR "P", 0
blockStr TCHAR "BLOCKQUOTE", 0
aStr TCHAR "A", 0
liStr TCHAR "LI", 0
olStr TCHAR "OL", 0
htmlStr TCHAR "HTML", 0
strongStr TCHAR "STRONG", 0
emphStr TCHAR "EM", 0
styleStr TCHAR "STYLE", 0

boldStr TCHAR "bold", 0
italicStr TCHAR "italic", 0
underStr TCHAR "underline", 0
centerStr TCHAR "center", 0
richRightStr TCHAR "flushright", 0
paramStr TCHAR "param", 0
excerptStr TCHAR "excerpt", 0

htmlStyleTable ProcessStyleEntry \
	<bStr, PSBold, CmpCX>,
	<iStr, PSItalic, CmpCX>,
	<uStr, PSUnderline, CmpCX>,
	<centerStr, PSCenter, CmpCX>,
	<divStr, PSAlign, CmpSpace>,
	<fontStr, PSFont, CmpSpace>,
	<brStr, PSCR, CmpCX>,
	<pStr, PSCR, CmpCX>,
	<blockStr, PSBlockquote, CmpSpace>,
	<aStr, PSHRef, CmpSpace>,
	<liStr, PSList, CmpCX>,
	<olStr, PSEndList, CmpCX>,
	<htmlStr, PSHTML, CmpCX>,
	<strongStr, PSBold, CmpCX>,
	<emphStr, PSItalic, CmpCX>,
	<styleStr, PSStyle, CmpCX>

richStyleTable	ProcessStyleEntry \
	<boldStr, PSBold, CmpCX>,
	<italicStr, PSItalic, CmpCX>,
	<underStr, PSUnderline, CmpCX>,
	<centerStr, PSCenter, CmpCX>,
	<richRightStr, PSRight, CmpCX>,
	<paramStr, PSParam, CmpCX>,
	<excerptStr, PSBlockquote, CmpSpace>

PROCESSHTMLTAG	proc	far 	textObj:optr, tag:fptr.TCHAR, len:word
		uses	si
		.enter
ForceRef textObj
ForceRef tag
ForceRef len

		mov	si, offset htmlStyleTable
		mov	cx, length htmlStyleTable
		call	ProcessTagCommon

		.leave
		ret
PROCESSHTMLTAG	endp

PROCESSRICHTAG	proc	far	textObj:optr, tag:fptr.TCHAR, len:word
		uses	si
		.enter
ForceRef textObj
ForceRef tag
ForceRef len

		mov	si, offset richStyleTable
		mov	cx, length richStyleTable
		call	ProcessTagCommon

		.leave
		ret
PROCESSRICHTAG	endp

ProcessTagCommon	proc	far
		uses	ds, es, di
		.enter	inherit	PROCESSRICHTAG

		tst	ss:len.high			;
EC <		WARNING_NZ -1				;tag too long>
		jnz	skipTag				;branch if too long
		segmov	ds, cs
		movdw	esdi, ss:tag
	;
	; See if the tag starts with a slash
	;
		clr	dl				;dl <- on
		cmp	{TCHAR}es:[di], '/'		;start with slash?
		jne	noSlash				;branch if not
		dec	dl				;dl <- off
		LocalNextChar esdi			;skip slash
		dec	ss:len				;one less char
noSlash:
		
tagLoop:
		push	cx, si, di
		mov	cx, ss:len			;cx <- tag len
		call	ds:[si].PSE_cmp			;match?
		pop	cx, si, di
		je	found				;branch if found
		add	si, (size ProcessStyleEntry)
		loop	tagLoop
skipTag:
		mov	ax, FS_IN_BODY			;ax <- no CR
		jmp	notFound

	;
	; found a match
	;
found:
		movdw	axcx, esdi			;ax:cx <- tag
		mov	dh, ss:len.low			;dh <- # chars
		mov	bx, ss:textObj.handle
		mov	di, ss:textObj.offset		;^lbx:di <- text obj
		call	ds:[si].PSE_function
notFound:

		.leave
		ret

ProcessTagCommon	endp

CmpCX	proc	near
		mov	si, ds:[si].PSE_name		;ds:si <- tag name
		call	LocalCmpStringsNoCase
		ret
CmpCX	endp

CmpSpace	proc	near
		mov	ax, ' '
		FALL_THRU	CompareToCommon
CmpSpace	endp

CompareToCommon	proc	near
		uses	dx
		.enter

		mov	dx, ax				;ax <- end char
		mov	si, ds:[si].PSE_name		;ds:si <- tag name
cmpLoop:
		LocalGetChar ax, esdi			;ax <- tag char
SBCS <		cmp	al, dl				;end char?>
DBCS <		cmp	ax, dx				;end char?>
		je	afterCompare			;branch if reached end
		push	cx
		LocalGetChar cx, dssi			;cx <- table char
		call	LocalCmpCharsNoCase
		pop	cx
		loope	cmpLoop				;loop while still =
afterCompare:
		.leave
		ret
CompareToCommon	endp

nbspChar TCHAR "nbsp", 0;
ltChar TCHAR "lt", 0;
gtChar TCHAR "gt", 0;
quotChar TCHAR "quot", 0;

htmlChars nptr \
	nbspChar,
	ltChar,
	gtChar,
	quotChar,
	-1

mapHTMLChars TCHAR \
	C_NONBRKSPACE,
	C_LESS_THAN,
	C_GREATER_THAN,
	C_QUOTE

PROCESSHTMLCHAR	proc	far	textObj:optr, tag:fptr.TCHAR, len:word
		uses	ds, si, es, di
		.enter
ForceRef textObj
ForceRef tag
ForceRef len

		movdw	esdi, ss:tag			;es:di <- tag
		mov	si, offset htmlChars		;cs:si <- table
		call	LookupString
		jc	done				;branch if not found
		push	bp
		mov	bx, ss:textObj.handle
		mov	di, ss:textObj.offset		;^lbx:di <- text obj
		mov	si, ax
		lea	bp, cs:mapHTMLChars[si]		;cs:bp <- ptr to text
		mov	cx, 1				;cx <- length
		call	AppendTextCommon
		pop	bp
done:
		mov	ax, FS_IN_BODY			;ax <- FilterState

		.leave
		ret
PROCESSHTMLCHAR	endp

PROCESSURLSTART proc far textObj:optr, tag:fptr.TCHAR, len:word
		uses	ds, si, es, di
		.enter
ForceRef textObj
ForceRef tag
ForceRef len
		movdw	esdi, ss:tag			;es:di <- tag
		mov	bx, ss:textObj.handle
		mov	cx, ss:textObj.offset		;^lbx:cx <- text obj
		clr	dx				;dx <- no adjustment
		call	SetURL

		.leave
		ret
PROCESSURLSTART	endp

PROCESSURLEND	proc	far textObj:optr, tag:fptr.TCHAR, len:word
		uses	ds, si, es, di
		.enter
ForceRef textObj
ForceRef tag
ForceRef len

		mov	bx, ss:textObj.handle
		mov	cx, ss:textObj.offset		;^lbx:cx <- text obj
		mov	dl, 0xff			;dl <- end tag
		call	ClearHRef

		.leave
		ret
PROCESSURLEND	endp

AsmCode	ends
