COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gdgsprt.asm

AUTHOR:		Jimmy Lefkowitz, Jul  7, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/ 7/95   	Initial revision


DESCRIPTION:
	gadget component code
		

	$Id: gdgsprt.asm,v 1.1 98/03/11 04:29:26 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



include Objects/winC.def
include Internal/grWinInt.def
include graphics.def

;
; I need to set GGI_attrs before the META_RESOLVE_VARIANT_SUPERCLASS handler
; And I can't do it at the Ent level handler for META_INITIALIZE.
; This class exists solely to get MSG_INITIALIZE at a Gen Level so I can
; set the instance data.

GadgetSpecGenGadgetClass	class	GenGadgetClass
GadgetSpecGenGadgetClass	endc

idata	segment
	GadgetGadgetClass
	GadgetSpecGenGadgetClass
idata	ends

GadgetFloaterCode	segment
global	ValidateRegion:far
GadgetFloaterCode	ends

GadgetGadgetCode	segment resource


INIT_COMMAND_BUF_SIZE 	equ 40
TEXT_EXTRA_DATA_SIZE	equ 16
UISHAPE_EXTRA_DATA_SIZE	equ 18
COMMAND_START_OFFSET	equ 4

makeActionEntry gadget, Setchildren, MSG_GADGET_GADGET_ACTION_SET_CHILDREN, LT_TYPE_VOID, 1
makeActionEntry gadget, Getchildren, MSG_GADGET_GADGET_ACTION_GET_CHILDREN, LT_TYPE_COMPONENT, 1
makeActionEntry gadget, DrawHLine, MSG_GADGET_GADGET_ACTION_HLINE, LT_TYPE_VOID, 4
makeActionEntry gadget, DrawVLine, MSG_GADGET_GADGET_ACTION_VLINE, LT_TYPE_VOID, 4
makeActionEntry gadget, DrawRect, MSG_GADGET_GADGET_ACTION_FILL_RECT, LT_TYPE_VOID, 5
makeActionEntry gadget, InvertRect, MSG_GADGET_GADGET_ACTION_INVERT_RECT, LT_TYPE_VOID, 4
makeActionEntry gadget, DrawText, MSG_GADGET_GADGET_ACTION_STRING, LT_TYPE_INTEGER,7
makeActionEntry gadget, SetClipRect, MSG_GADGET_GADGET_ACTION_SET_CLIP_RECT, LT_TYPE_VOID,4
makeActionEntry gadget, ClearClipRect, MSG_GADGET_GADGET_ACTION_CLEAR_CLIP_RECT, LT_TYPE_VOID,0
makeActionEntry gadget, DrawUIShape, MSG_GADGET_GADGET_ACTION_UISHAPE, LT_TYPE_VOID,9
makeActionEntry gadget, InvertUIShape, MSG_GADGET_GADGET_ACTION_INVERT_UISHAPE, LT_TYPE_VOID,8
makeActionEntry gadget, Redraw, MSG_GADGET_GADGET_ACTION_REDO_GEOMETRY, LT_TYPE_VOID,0
makeActionEntry gadget, GrabMouse, MSG_GADGET_GADGET_ACTION_GRAB_PEN, LT_TYPE_VOID,0
makeActionEntry gadget, DrawImage, MSG_GADGET_GADGET_ACTION_DRAW_IMAGE, LT_TYPE_VOID,3
makeActionEntry gadget, DrawLine, MSG_GADGET_GADGET_ACTION_DRAW_LINE,LT_TYPE_VOID,5
makeActionEntry gadget, InvertLine, MSG_GADGET_GADGET_ACTION_INVERT_LINE,LT_TYPE_VOID,4
makeActionEntry gadget, TextHeight, MSG_GADGET_GADGET_ACTION_TEXT_HEIGHT,LT_TYPE_INTEGER,3
makeActionEntry gadget, TextWidth, MSG_GADGET_GADGET_ACTION_TEXT_WIDTH,LT_TYPE_INTEGER,4


; makeActionEntry gadget, ReadyPenMove, MSG_GADGET_GADGET_ACTION_READY_PEN_MOVE, LT_TYPE_UNKNOWN

compMkActTable 	gadget, Getchildren, Setchildren, \
		DrawHLine, DrawVLine, DrawRect, InvertRect, DrawText,\
		SetClipRect, ClearClipRect, DrawUIShape, InvertUIShape,\
		Redraw, GrabMouse, DrawImage, DrawLine, \
		InvertLine, TextHeight, TextWidth


makePropEntry gadget, numChildren, LT_TYPE_INTEGER, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GADGET_GET_NUM_CHILDREN>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GADGET_SET_NUM_CHILDREN>

makePropEntry gadget, mouseInterest, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GADGET_GET_PEN>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GADGET_SET_PEN>

makePropEntry gadget, tile, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GADGET_GET_TILE>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GADGET_SET_TILE>

makeUndefinedPropEntry gadget, readOnly
makeUndefinedPropEntry gadget, enabled
makeUndefinedPropEntry gadget, look
makeUndefinedPropEntry gadget, caption
makeUndefinedPropEntry gadget, graphic

compMkPropTable GadgetGadgetProperty, gadget, \
	numChildren, mouseInterest, tile, \
	readOnly, enabled, look, caption, graphic

MakeActionRoutines Gadget, gadget
MakePropRoutines Gadget, gadget

GadgetGadgetDrawCode	segment	resource
global	FloatToWWFixed:far


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockStringArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grab a string value from passed args

CALLED BY:	
PASS:		ds:si points to an array of args
		ss:bp	= EntDoActionArgs
RETURN:		carry clear if evertyhing ok
		if	carry set, nothing is locked.
			cx:dx  = string pointer
DESTROYED:	nothing
SIDE EFFECTS:
		Locks down a string on the RunTimeHeap. It needs
		to be unlocked by someone later.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockStringArg	proc	far
		uses	bx, ax, es
		.enter

		cmp	ds:[si].CD_type, LT_TYPE_STRING
		LONG jne	argTypeError
		mov	cx, ds:[si].CD_data.LD_string
		add	si, size ComponentData

	;
	; Lock down the string and return the fptr
	;
		sub	sp, size RunHeapLockStruct
		mov	bx, sp
		mov	ss:[bx].RHLS_token, cx
		lea	cx, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, sscx
		movdw	cxdx, ss:[bp].EDAA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, cxdx
		call	RunHeapLock
		mov	bx, sp
		movdw	cxdx, ss:[bx].RHLS_eptr
		add	sp, size RunHeapLockStruct
		Assert	nullTerminatedAscii cxdx
		clc
done:	
		.leave
		ret
argTypeError:	
		stc
		jmp	done
LockStringArg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockStringArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	unlocks the current string

CALLED BY:	
PASS:		ds:si points to an array of args (after arg that was locked)
		ss:bp	= EntDoActionArgs
RETURN:		carry clear if evertyhing ok
			cx:dx  = string pointer
DESTROYED:	nothing
SIDE EFFECTS:
		Locks down a string on the RunTimeHeap. It needs
		to be unlocked by someone later.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnlockStringArg	proc	far
		uses	ax, bx, cx, dx, si, es
		.enter

		sub	si, size ComponentData
		cmp	ds:[si].CD_type, LT_TYPE_STRING
		
EC <		ERROR_NE	-1 					>
	; If you hit the above error, then you didn't call unlock right
	; after calling lock.
		
		jne	argTypeError
		mov	cx, ds:[si].CD_data.LD_string
		add	si, size ComponentData

	;
	; Unlock the string.
	;
		sub	sp, size RunHeapLockStruct
		mov	bx, sp
		mov	ss:[bx].RHLS_token, cx
		movdw	cxdx, ss:[bp].EDAA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, cxdx
		call	RunHeapUnlock
		add	sp, size RunHeapLockStruct
		clc
done:	
		.leave
		ret
argTypeError:	
		stc
		jmp	done
UnlockStringArg	endp

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetComplexArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grab a complex value from passed args

CALLED BY:	
PASS:		ds:si points to an array of args
RETURN:		carray clear if evertyhing ok
			ax  = integer value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetComplexArg	proc	near
		.enter

		cmp	ds:[si].CD_type, LT_TYPE_COMPLEX
		jne	argTypeError
		mov	ax, ds:[si].CD_data.LD_complex
		add	si, size ComponentData
		clc
done:	
		.leave
		ret
argTypeError:	
		stc
		jmp	done
GetComplexArg	endp
	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLongArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grab an integer value from passed args

CALLED BY:	
PASS:		ds:si points to an array of args
RETURN:		carray clear if evertyhing ok
			ax  = integer value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLongArg	proc	near
		.enter

		cmp	ds:[si].CD_type, LT_TYPE_LONG
		jne	checkInteger
		movdw	bxax, ds:[si].CD_data.LD_long
		add	si, size ComponentData
		clc
done:	
		.leave
		ret
checkInteger:
		cmp	ds:[si].CD_type, LT_TYPE_INTEGER
		jne	argTypeError
		mov	ax, ds:[si].CD_data.LD_integer
		clr	bx	; clears the carry flag
		jmp	done
argTypeError:	
		stc
		jmp	done
GetLongArg	endp

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFloatArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grab a float value from passed args

CALLED BY:	
PASS:		ds:si points to an array of args
RETURN:		carray clear if evertyhing ok
			ax  = integer value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
GetFloatArg	proc	near
		.enter

		cmp	ds:[si].CD_type, LT_TYPE_FLOAT
		jne	argTypeError
		movdw	bxax, ds:[si].CD_data.LD_long
		add	si, size ComponentData
		clc
done:	
		.leave
		ret
argTypeError:	
		stc
		jmp	done
GetFloatArg	endp
endif
	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetIntegerArg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grab an integer value from passed args

CALLED BY:	
PASS:		ds:si points to an array of args
RETURN:		carry clear if evertyhing ok
			ax  = integer value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetIntegerArg	proc	near
		.enter

		cmp	ds:[si].CD_type, LT_TYPE_INTEGER
		jne	checkLong
getInteger:
		mov	ax, ds:[si].CD_data.LD_integer
		add	si, size ComponentData
		clc
done:	
		.leave
		ret
checkLong:
	; if its a long, just grab the low word
		cmp	ds:[si].CD_type, LT_TYPE_LONG
		je	getInteger

		stc				; arg type error
		jmp	done
GetIntegerArg	endp

	
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTwoIntegerArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grab two integer values from passed args

CALLED BY:	
PASS:		ds:si points to an array of args
RETURN:		carray clear if evertyhing ok
			ax, bx  = two integer values
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 4/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTwoIntegerArgs	proc	near
		.enter

		call	GetIntegerArg
		jc	done
		mov	bx, ax
		call	GetIntegerArg
		xchg	ax, bx
done:	
		.leave
		ret
GetTwoIntegerArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetThreeIntegerArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get 3 integer values

CALLED BY:	
PASS:		
RETURN:		ax, bx, cx as 3 values
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetThreeIntegerArgs	proc	near
		.enter
		call	GetTwoIntegerArgs
		jc	done
		mov_tr	cx, ax
		call	GetIntegerArg
		xchg	cx, ax
done:
		.leave
		ret
GetThreeIntegerArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFourIntegerArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get 4 integer args

CALLED BY:	
PASS:		
RETURN:		ax, bx, cx, dx as four values
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFourIntegerArgs	proc	near
		.enter
		call	GetTwoIntegerArgs
		jc	done
		mov_tr	cx, ax
		mov_tr	dx, bx
		call	GetTwoIntegerArgs
		xchg	cx, ax
		xchg	dx, bx
done:
		.leave
		ret
GetFourIntegerArgs	endp



			
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGGadgetGadgetSetClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_SET_CLIP_RECT
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGGadgetGadgetSetClipRect	method GadgetGadgetClass, 
				MSG_GADGET_GADGET_ACTION_SET_CLIP_RECT,
				MSG_GADGET_GADGET_ACTION_CLEAR_CLIP_RECT
		uses	ax, bx, cx, dx, bp, di, si
		.enter
		cmp	ax, MSG_GADGET_GADGET_ACTION_CLEAR_CLIP_RECT
		je	clrClip

		push	ds, si
		lds	si, ss:[bp].EDAA_argv	; array of
		call	GetFourIntegerArgs
		pop	ds, si
		jc	error
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset

	; if we have an old clip rect, clear it out rather than adding
	; this one in addition to the old one as that's more intuitive
		cmp	ds:[di].GGI_clipRect.R_left, -1
		je	setClip

	; this is cute, I will just call this routine to clear out the
	; old clip rect
		push	ax
		mov	ax, MSG_GADGET_GADGET_ACTION_CLEAR_CLIP_RECT
		call	GGGadgetGadgetSetClipRect
		pop	ax
setClip:
		mov	ds:[di].GGI_clipRect.R_left, ax
		mov	ds:[di].GGI_clipRect.R_top, bx
		mov	ds:[di].GGI_clipRect.R_right, cx
		mov	ds:[di].GGI_clipRect.R_bottom, dx

		tst	ds:[di].GGI_gstate
		jz	done
		push	ax, cx, dx
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		mov	di, ds:[di].GGI_gstate
		mov	si, ax
		pop	ax, cx, dx
		add	ax, si
		add	cx, si
		add	bx, bp
		add	dx, bp
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
		jmp	done
clrClip:
	; just add back in the VIS bounds and we are back to where we
	; started with clipping
		mov	ds:[di].GGI_clipRect.R_left, -1
		tst	ds:[di].GGI_gstate
		jz	done
	; add in the vis bounds of the gadget to get rid of the clip
	; rect for the current gstate
		mov	bx, ds:[di].GGI_gstate
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		mov	di, bx
		mov	bx, bp
		mov	si, PCT_UNION
		call	GrSetClipRect
done:		
		.leave
		ret
error:
		jmp	done
GGGadgetGadgetSetClipRect	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGGadgetGadgetActionTextHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_ACTION_TEXT_HEIGHT
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGGadgetGadgetActionTextHeight	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_ACTION_TEXT_HEIGHT,
					MSG_GADGET_GADGET_ACTION_TEXT_WIDTH
passedBP	local	word	push	bp
msg		local	word		
		uses	ax, cx, dx, bp
		.enter

		mov	msg, ax

	; create a gstring to play with
		push	ax, bp
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		mov	di, bp
		pop	ax, bp

		push	bp
		mov	bp, passedBP
		lds	si, ss:[bp].EDAA_argv
		
		cmp	ax, MSG_GADGET_GADGET_ACTION_TEXT_HEIGHT
		je	gotFontArg
		
		add	si, size ComponentData
gotFontArg:
		call	LockStringArg	; cx:dx = string
		pop	bp
		jc	error
		push	ds, si
		mov	ds, cx
		mov	si, dx
		mov	dl, mask FEF_STRING or mask FEF_BITMAPS
		call	GrCheckFontAvail
		pop	ds, si
		push	bp
		mov	bp, passedBP
		call	UnlockStringArg
		pop	bp
		CheckHack <FID_INVALID eq 0>
	;
	; Don't check for error, we'll just use the current font
	;		cmp	cx, FID_INVALID
	;		je	error
	; get font size and set the font
		call	GetTwoIntegerArgs
		jc	error
	; ax = point size
	; bx = style
	;
		mov	dx, ax
		clr	ah
	; DBCS doesn't like really small point sizes		
DBCS <		cmp	dx, 6						>
DBCS <		jae	gotDBCSPointSize				>
DBCS <		mov	dx, 6						>
DBCS < gotDBCSPointSize:						>
		call	GrSetFont
	;
	; bl = text style (follows TextStyle record):
	;	0 = plain
	;	1 = underline
	;	2 = strike through
	;	4 = subscript
	;	8 = superscript
	;	16 = italic
	;	32 = bold
	;
		mov	al, bl			;al <- styles to set
		mov	ah, 0xff		;ah <- styles to clear
		call	GrSetTextStyle
		cmp	msg, MSG_GADGET_GADGET_ACTION_TEXT_HEIGHT
		jne	doWidth
		
		mov	si, GFMI_HEIGHT or GFMI_ROUNDED
		call	GrFontMetrics 		; dx = height
		mov	ax, LT_TYPE_INTEGER
stuffAnswer:
		call	GrDestroyState
		mov	di, passedBP
		les	di, ss:[di].EDAA_retval
		mov	es:[di].CD_type, ax
		mov	es:[di].CD_data.LD_integer, dx

		.leave
		ret
doWidth:
	; go back and get action text string
		push	bp
		mov	bp, passedBP
		lds	si, ss:[bp].EDAA_argv
		call	LockStringArg	; cx:dx = text string
		pop	bp
		push	ds, si
		mov	ds, cx
		mov	si, dx
	; the string is always Null Termianted
		mov	cx, 0ffffh
		call	GrTextWidth	; dx = width
		pop	ds, si
		push	bp
		mov	bp, passedBP
		call	UnlockStringArg
		pop	bp
		mov	ax, LT_TYPE_INTEGER
		jmp	stuffAnswer
error:
		mov	ax, LT_TYPE_ERROR
		mov	dx, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	stuffAnswer
GGGadgetGadgetActionTextHeight	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSGadgetGadgetActionHline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_ACTION_HLINE
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GSGadgetGadgetActionCommon	method dynamic GadgetGadgetClass, 
				MSG_GADGET_GADGET_ACTION_HLINE,
				MSG_GADGET_GADGET_ACTION_VLINE,
				MSG_GADGET_GADGET_ACTION_FILL_RECT,
				MSG_GADGET_GADGET_ACTION_INVERT_RECT,
				MSG_GADGET_GADGET_ACTION_STRING,
				MSG_GADGET_GADGET_ACTION_UISHAPE,
				MSG_GADGET_GADGET_ACTION_INVERT_UISHAPE,
				MSG_GADGET_GADGET_ACTION_DRAW_IMAGE,
				MSG_GADGET_GADGET_ACTION_DRAW_LINE,
				MSG_GADGET_GADGET_ACTION_INVERT_LINE
		
passedBP	local	word	push bp
commands	local	hptr
bufSize		local	word
temp		local	word
msg		local	word
self		local	word		
		uses	ax, cx, dx, bp
		.enter

		mov	msg, ax
		mov	self, si
		push	ax, cx, dx, bp
		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		pop	ax, cx, dx, bp
		jnc	reallyDone
		
		push	ds, si
		push	ax
		mov	bx, ds:[di].GGI_commands
		mov	commands, bx
		mov	ax, ds:LMBH_handle
		Assert	handle	bx
		call	MemLock
		mov	es, ax
		mov	ax, es:[GCH_bufSize]
		mov	bufSize, ax
		pop	ax
		push	bx
	; the first word is the pointer for where to insert next command
		mov	di, es:[GCH_offset]
		sub	ax, MSG_GADGET_GADGET_ACTION_HLINE
		Assert	etype al, GadgetDrawCommands
		mov	bx, ax
	; commands start at one, not zero unlike the jump table
		inc	al
		stosb
		shl	bx
		push	bp
		mov	bp, passedBP
		lds	si, ss:[bp].EDAA_argv	; array of
		pop	bp
		jmp	cs:[dcjt][bx]
storeColor:
		xchg	bl, al
		stosw
		mov	ax, bx
		stosw
		retn
hline:
vline:
		call	GetThreeIntegerArgs
		jc	shortError
		add	di, 4

		stosw
		mov	ax, bx
		stosw
		mov	ax, cx
		stosw

		call	GetLongArg
		jc	shortError

		sub	di, 10
		call	storeColor
		add	di, 6
		jmp	done
fillRect:
drawLine:
		call	GetFourIntegerArgs
		jc	shortError
		add	di, 4
		
		stosw
		mov_tr	ax, bx
		stosw
		mov_tr	ax, cx
		stosw
		mov_tr	ax, dx
		stosw
		call	GetLongArg
		jc	shortError
		sub	di, 12
		call	storeColor
		add	di, 8
		jmp	done
shortError:
		jmp	error
copyStringArg:
	; get length of string (0 for null terminiated)
	;		call	GetIntegerArg
	; 		jc	shortError
	; now get string
		push	bp
		mov	bp, passedBP
		call	LockStringArg ; cx:dx = string
				; wont return error if locked
		pop	bp
		jc	shortCSError
		push	ds, si
		mov	ds, cx
		mov	si, dx
		push	es, di
		segmov	es, ds
		mov	di, dx
		LocalStrLength	; cx = string length
		pop	es, di
		mov	ax, cx
	;copyNString:

		push	cx
DBCS <		shl	cx						>
		add	cx, TEXT_EXTRA_DATA_SIZE
		add	cx, di
		call	ReAllocCommandsBuffer
		pop	cx
		stosw
reallyCopyNString::
		LocalCopyNString
afterCopy::
		pop	ds, si
		push	bp
		mov	bp, passedBP
		call	UnlockStringArg
		pop	bp
		clc
shortCSError:
		retn
string:
		call	copyStringArg
		jc	shortError
	; get coordiniates
		call	GetTwoIntegerArgs
		jc	shortError
		stosw
		mov_tr	ax, bx
		stosw
	; now get the color
		call	GetLongArg
		jc	shortError
		call	storeColor

	; get font name
		call	copyStringArg
		jc	shortError
	; add a null terminator
		clr	ax
SBCS <		stosb							>
DBCS <		stosw							>
	; now get font info
		call	GetTwoIntegerArgs
		stosw
		mov_tr	ax, bx
		stosw
		jmp	done
drawImage:
		call	GetComplexArg
		jc	shortError
		stosw
	; grab coordinates
		call	GetTwoIntegerArgs
		jc	shortError
		stosw
		mov_tr	ax, bx
		stosw
		jmp	done
invertRect:
invertLine:
		call	GetFourIntegerArgs
		jc	shortError
		stosw
		mov_tr	ax, bx
		stosw
		mov_tr	ax, cx
		stosw
		mov_tr	ax, dx
		stosw
		jmp	done
invertUIShape:
		mov	dx, 4
		jmp	uiShapeCommon
uiShape:
		mov	dx, 8
uiShapeCommon:
	; here is how we store the data
	; 	COLOR (uiShape only) (4 bytes)
	; 	coordinates (4 bytes)
	; 	regionSize (2 bytes)
	; 	Region (many bytes)
	;	4 region params (8 bytes)
		
		cmp	ds:[si].CD_type, LT_TYPE_ARRAY
		jne	shortError
		mov	bx, ds:[si].CD_data.LD_gen_word
		Assert	handle	bx
		add	si, size ComponentData

		push	di
		add	di, dx
		call	GetIntegerArg
		
		call	CreateRegionFromArray
	; save pointer at end of region
		mov	temp, di
		pop	di
		jc	error
		
		call	GetTwoIntegerArgs
		jc	error

		sub	dx, 4
		add	di, dx
		stosw
		mov_tr	ax, bx
		stosw

		tst	dx
		jz	resetDI	; no color for invert
	;		call	GetFourIntegerArgs
		call	GetLongArg
		jc	error
		sub	di, 8
		call	storeColor
resetDI:
		mov	di, temp
	; get the four params, same as getting a clip rect		
		jmp	invertRect
done:
	; add a null terminator to the end
		mov	{byte}es:[di], 0
		
	; store current position so we know where to add next command
		mov	es:[GCH_offset], di
		Assert	urange di, 0, bufSize-1
		pop	bx
		call	MemUnlock
		pop	ds, si
		
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
		or	ds:[di].GGI_gadgetFlags, mask GGF_DRAW_COMMANDS

	;
	; Force the drawing command to happen now.
	; It would be nice to use MSG_VIS_INVALIDATE, but it doesn't draw
	; now and empty our buffer that we keep overwriting.
	;
	; If we came here via a _redraw then we already have a gstate
	; that we just write to, otherwise, call up the tree, get one and
	; make sure stuff draws now (use Begin/End).
	; 9/11/95 -- ron  [actually we can check DrawFlags to see if we
	; need begin end]

	; Change these to call superclass 10/4/95 - ron
	; we don't need to generate more events now.
		
		mov	ax, segment GadgetGadgetClass
		mov	es, ax

		push	bp
		mov	bp, ds:[di].GGI_gstate
		tst	bp
		jz	createGState
		mov	cl, mask DF_EXPOSED or mask DF_OBJECT_SPECIFIC
		mov	ax, MSG_VIS_DRAW
		mov	di, offset GadgetGadgetClass
		call	ObjCallClassNoLock
		jmp	redrawn

createGState:
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		push	bp		; gstate
		mov	bx, di		; Instance data
		mov	cl, mask  DF_EXPOSED or mask DF_OBJECT_SPECIFIC
		mov	ax, segment GadgetGadgetClass
		mov	es, ax
		mov	ax, MSG_VIS_DRAW
	;
	; we don't want subclasses intercept this as it is not a real
	; VIS_DRAW but just something we are using to draw our cached
	; commands.
	;
		mov	di, offset GadgetGadgetClass
		call	ObjCallClassNoLock
		pop	bp		; gstate
		mov	di, bp
		call	GrDestroyState
redrawn:
		pop	bp
		
	; now fetch the return value
		mov	ax, msg
		mov	si, self
		push	bp		; frame ptr
		mov	bp, ss:[passedBP]
		les	di, ss:[bp].EDAA_retval
		cmp	ax, MSG_GADGET_GADGET_ACTION_STRING
		mov	ax, LT_TYPE_VOID
		jne	gotRetVal
		mov	bx, ds:[si]
		add	bx, ds:[bx].GadgetGadget_offset
		mov	dx, ds:[bx].GGI_retval
		Assert	fptr, esdi
		mov	es:[di].CD_data.LD_integer, dx
		mov	ax, LT_TYPE_INTEGER
gotRetVal:		
		mov	es:[di].CD_type, ax
		pop	bp		; frame ptr
reallyDone:
		.leave
		ret
error:
		pop	bx		; command buffer
		call	MemUnlock	
		pop	ds, si		; self
		push	bp		; frame ptr
		mov	bp, ss:[passedBP]
		les	di, ss:[bp].EDAA_retval
		Assert	fptr, esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_integer, CPE_SPECIFIC_PROPERTY_ERROR
		pop	bp		; frame ptr
		jmp	reallyDone
dcjt nptr 	hline, vline, fillRect, invertRect, string, \
		uiShape, invertUIShape, drawImage, \
		drawLine, invertLine
GSGadgetGadgetActionCommon	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateRegionFromArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	stuff a region into the commands data

CALLED BY:	MSG_GADGET_GADGET_ACTION_UISHAPE
PASS:		bx = handle of array, es:di = commands buffer
		ax = size of array
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateRegionFromArray	proc	near
		uses	ds, si
		.enter inherit GSGadgetGadgetActionCommon

		push	ax
	; first, point ds:si at the array's elements
		call	MemLock
		mov	ds, ax
		mov	si, size ArrayHeader
		pop	ax
		
	; now calculate the actual number of bytes being used so
	; DrawCommands doen't need to do the calculation
	; ax = sizeof(word) * (numElements + 4)
	; the 4 is for the bounds rect that goes before the region data
		mov	cx, ax
		push	es, di
		segmov	es, ds
		mov	di, si
		call	ValidateRegion
		pop	es, di
		jc	error
		
		add	ax, 4
		shl	ax
	; store the calculated number of bytes
		stosw
	; store bogus rect

		push	ax
		clr	ax
		stosw
		stosw
	;	mov	ax, 0ffffh
		stosw
		stosw
		pop	ax
		
		push	cx
		mov	cx, ax
		add	cx, UISHAPE_EXTRA_DATA_SIZE
		call	ReAllocCommandsBuffer
		pop	cx
		
	; then copy the actual region data
		rep	movsw
		call	MemUnlock
		clc
done:
		.leave
		ret
error:
		stc
		jmp	done
CreateRegionFromArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReAllocCommandsBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reallocates the command buffer

CALLED BY:	GSGadgetGadgetActionCommon and CraeteRegionFromArray
PASS:		cx = size of buffer you need
RETURN:		es is updated to point to new position if block moved
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReAllocCommandsBuffer	proc	near
		uses	ax, bx, cx
		.enter inherit GSGadgetGadgetActionCommon

	; set ax to the last byte in the buffer you can write to.
		mov	ax, bufSize
		dec	ax		
	
	; now added in the initail data at the top and the token byte
	; removed		add	cx, COMMAND_START_OFFSET + 1
	; and changed to use real offset
	; The add 2 to cx, 1 for the mandatory end of command byte
	; and 1 because the bufsize is 1 past the last place we
	; can write (or something.  It fixes a bug).
		add	cx, es:[GCH_offset]
		add	cx, 2
		cmp	cx, ax
		jl	done
	; we need to realloc our bufferd
		mov	ax, cx
		
	; set the bufSize value in the first word of the commands
		mov	es:[GCH_bufSize], ax
		
	; this is used in some EC code at the end of the routine 
EC <		mov	bufSize, ax					>
		mov	ch, mask HAF_ZERO_INIT
		mov	bx, commands
		call	MemReAlloc
		mov	es, ax
done:
		.leave
		ret
ReAllocCommandsBuffer	endp

		
GadgetGadgetDrawCode	ends

GadgetInitCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetMetaResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the system of our association Vis

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		cx:dx	= superclass to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetMetaResolveVariantSuperclass method dynamic GadgetGadgetClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	cmp	cx, Ent_offset
	je	returnSuperEnt

	mov	di, offset GadgetGadgetClass
	call	ObjCallSuperNoLock
done:
	.leave
	ret
	
returnSuperEnt:	
	mov	cx, segment GadgetSpecGenGadgetClass
	mov	dx, offset GadgetSpecGenGadgetClass
	jmp	done
GadgetGadgetMetaResolveVariantSuperclass	endm

GadgetInitCode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return "fig"

CALLED BY:	MSG_ENT_GET_CLASS
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		cx:dx	= fptr.char

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
GadgetGadgetGetClass	method dynamic GadgetGadgetClass, 
					MSG_ENT_GET_CLASS
		mov	cx, segment GadgetGadgetString
		mov	dx, offset GadgetGadgetString
		ret
GadgetGadgetGetClass	endm

GadgetInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up ent level flags used when setting the parent

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 4/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetMetaInitialize	method dynamic GadgetGadgetClass, 
					MSG_META_INITIALIZE
		.enter
		mov	di, offset GadgetGadgetClass
		call	ObjCallSuperNoLock

	;
	; Set the GenGadget instance data to make generic children
	; become visual children
	;

		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		BitSet	ds:[di].EI_flags EF_ALLOWS_CHILDREN

	.leave
	ret
GadgetGadgetMetaInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSpecGenGadgetMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= GadgetSpecGenGadgetClass object
		ds:di	= GadgetSpecGenGadgetClass instance data
		ds:bx	= GadgetSpecGenGadgetClass object (same as *ds:si)
		es 	= segment of GadgetSpecGenGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 2/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSpecGenGadgetMetaInitialize	method dynamic GadgetSpecGenGadgetClass, 
					MSG_META_INITIALIZE

	.enter
		mov	di, offset GadgetSpecGenGadgetClass
		call	ObjCallSuperNoLock

	;
	; Set the GenGadget instance data to make generic children
	; become visual children
	;
		mov	di, ds:[si]
		add	di, ds:[di].GenGadget_offset
		mov	ds:[di].GGI_attrs, GenGadgetAttributes <1,0>


	.leave
	ret
GadgetSpecGenGadgetMetaInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	arrange our guts the way we wants 'em

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		First tell superclass to Init itself.
		Then send messages to the superclass telling it what
		the init figs should really be.  We don't have much
		to initialize in the object at our level.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	6/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetEntInitialize	method dynamic GadgetGadgetClass, 
					MSG_ENT_INITIALIZE
	.enter

	;
	; Tell superclass to do its thing
	;
		push	ds:LMBH_handle, si
		mov	di, offset GadgetGadgetClass
		call	ObjCallSuperNoLock

		
		pop	bx, si
		call	MemDerefDS
EC <		call	VisCheckVisAssumption				>
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID or\
					     mask VOF_GEO_UPDATE_PATH or\
					     mask VOF_IMAGE_INVALID or\
					     mask VOF_WINDOW_INVALID or\
					     mask VOF_WINDOW_UPDATE_PATH or\
					     mask VOF_IMAGE_UPDATE_PATH
	;
	; Let everyone know that we are *VIS* !
	;
		mov	di, ds:[si]
		add	di, ds:[di].Ent_offset
		mov	ds:[di].GGI_shiftState, 0
		mov	ds:[di].GGI_gadgetFlags, ALL_PEN_EVENTS
		SetGadgetPenState GPS_NONE
		mov	ds:[di].GGI_clipRect.R_left, -1
	; allocate a command buffer, the first word is the offset for
	; where to insert the next command
		
		mov	ax, INIT_COMMAND_BUF_SIZE
		mov	cl, mask HF_SWAPABLE
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
		call	MemAlloc
		Assert	handle	bx
		mov	ds:[di].GGI_commands, bx
		mov	es, ax
		mov	es:[GCH_bufSize], INIT_COMMAND_BUF_SIZE
		mov	es:[GCH_offset], COMMAND_START_OFFSET 		
		call	MemUnlock
	; Set the vis size
	;
		mov	al, VUM_DELAYED_VIA_APP_QUEUE
		mov	cx, 15
		mov	dx, 15
		call	GadgetUtilGenSetFixedSize

		mov	ax, MSG_VIS_SET_SIZE
		call	ObjCallInstanceNoLock
	.leave
	ret
GadgetGadgetEntInitialize	endm

GadgetInitCode	ends

GadgetGadgetDrawCode	segment	resource

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGGadgetClipperDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_DRAW
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGGadgetClipperDraw	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_DRAW
		uses	ax, cx, dx, bp
		.enter

		
		mov	bp, ds:[di].GGI_gstate
		
		push	si
		mov	ax, MSG_VIS_GET_BOUNDS
		mov	bx, bp
		call	ObjCallInstanceNoLock
		mov	di, bx
		mov	bx, bp
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
		pop	si
		
		mov	bp, di
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset

		mov	dx, ds:[di].GGI_commands
		cmp	ds:[di].GGI_clipRect.R_left, -1
		je	afterClip
		
	; add clip rect to gstate
		push	si, dx
	; note that the clip rect we set is not relative to the left and
	; top of the gadget's vis bounds but to the window, thus we
	; add in the left and top of the gadget's bounds to our clip rect
		mov	dx, bx
		mov	cx, ax
		add	ax, ds:[di].GGI_clipRect.R_left
		add	bx, ds:[di].GGI_clipRect.R_top
		add	cx, ds:[di].GGI_clipRect.R_right
		add	dx, ds:[di].GGI_clipRect.R_bottom
		mov	di, bp
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
		pop	si, dx
afterClip:
		mov	bx, dx
		push	ds, si
		mov	di, bp
		call	GadgetGadgetDrawCommands
		pop	ds, si
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
		mov	bx, ds:[di].GGI_commands
		call	MemLock
		mov	ds, ax
	; reset pointer on where to add commands
		mov	ds:[GCH_offset], COMMAND_START_OFFSET
	; reset first command to null command
		clr	{byte}ds:[COMMAND_START_OFFSET]
		call	MemUnlock
		.leave
		ret
GGGadgetClipperDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertByteToMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	convert a byte value to a GEOS mask value

CALLED BY:	
PASS:		al = byte value
RETURN:		al = mask value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		mask value = ((271 - <input value>) DIV 32) * 8 + 25

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertByteToMask	proc	far
		uses	bx, cx
		.enter
		clr	ah
		mov	bx, 271
		sub	bx, ax
		mov	cl, 5
		shr	bx, cl
		mov	al, 8
		mul	bl
		add	al, 25
		.leave
		ret
ConvertByteToMask	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatToWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a RegFloat number to a WWFixed number

CALLED BY:	GLOBAL

PASS:		dxcx	= RegFloat
RETURN:		dxcx	= WWFixed
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include rgfloat.def
FloatToWWFixed	proc	far
	uses	ax
	.enter

	tstrf	dxcx
	clc
	jz	exit

	; add check for the value 1
	cmprf	dxcx, 3f800000h
	je	floatOne	
		

	shl	cx, 1		; put sign bit in carry, exponent in dh
	rcl	dx, 1
	pushf			; save for later negation if necessary

	;
	; with the implied one in dh, we are shifted 8 times up from
	; what we should be (WWFixed 1.0), so subtract that from the
	; exponent and all is ready to be shifted.
	;
	clr	ax
	mov	al, dh		; exponent in al
	mov	dh, 1		; the implied one
	sub	al, REG_FLOAT_EXP_BIAS + 8 ; un-bias the exponent + shift
	clc
	jz	adjusted	; all done
	js	negativeExponent

	;
	; positive exponent, so check it against reasonable bounds and
	; exit out if it is too big.  Shift into place if not.
	;
	cmp	al, 6		; word size - sign bit - shifted 8 already
	jle	shiftUpLoop

	mov	dx, 0x7fff
	mov	cx, 0xffff
error:
	popf			; who really cares about the sign
	stc
	jmp	exit

shiftUpLoop:
	shldw	dxcx		; shift everything up one bit
	dec	al		; decrement exponent
	jnz	shiftUpLoop
	jmp	adjusted

	;
	; negative exponent, so check it agains reasonable bounds and exit
	; out if it is too small.  Shift into place if not.
	;
negativeExponent:
	cmp	al, -23		; - word size - shifted 8 already (no sign bit)
	jge	shiftDownLoop

	clrwwf	dxcx
	jmp	error

shiftDownLoop:
	shr	dx, 1		; shift everything down one bit
	rcr	cx, 1
	rcr	ah, 1		; overflow into ah for later rounding
	inc	al		; increment exponent
	jnz	shiftDownLoop

	cmp	ah, 80h	; compare to 1/2
	jb	adjusted
	ja	roundUp
	test	cl, 1		; round toward even
	jz	adjusted
roundUp:
	add	cx, 1		; inc won't set carry
	adc	dx, 0

adjusted:
	popf
	jnc	exit
	negwwf	dxcx		; negate if sign bit was set
	clc			; number fit in a WWFixed
exit:
	.leave
	ret
floatOne:
	; deal with 1.0 case specially since most drawings will be
	; done with a scale of one
	mov	dx, 1
	clr	cx
	clc
	jmp	exit
FloatToWWFixed	endp

		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetDrawCommands
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	run through commands drawing them to the gstate

CALLED BY:	
PASS:		di = gstate, bx = hptr to commands
		*ds:si = self pointer
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
GadgetGadgetDrawCommands	proc	near
		class	GadgetGadgetClass
posX	local	word
posY	local	word
posX2	local	word
posY2	local	word
temp1	local	word	
temp2	local	word
self	local	optr
cmd	local	word		
		.enter
		Assert	handle	bx
		Assert	gstate	di

		mov	dx, ds:LMBH_handle
		movdw	self, dxsi
		
		push	bx
		push	bp
	; get current position so we know where to draw relative to
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		mov	bx, bp
		pop	bp
		mov	posX, ax
		mov	posY, bx
		mov	posX2, cx
		mov	posY2, dx
		pop	bx
		push	bx
		call	MemLock		
		mov	ds, ax
		mov	si, COMMAND_START_OFFSET; ds:si = commands buffer
processLoop:
		Assert	etype	{byte}ds:[si], GadgetDrawCommands
		lodsb		; get next command
		tst	al
		LONG jz	done
		dec	al	; commands start at one, not zero
		clr	ah
		mov	bx, ax
		shl	bx
		mov	cmd, ax
		jmp	cs:[dcjt2][bx]
hline:
vline:
		call	getMask
		cmp	cmd, SDC_HLINE-1
		jne	drawVLine
	; now get coordinates
		lodsw
		add	ax, posX
		push	ax
		lodsw
		add	ax, posX
		mov_tr	cx, ax
		lodsw
		add	ax, posY
		mov_tr  bx, ax
		mov	dx, bx
		pop	ax
		call	GrDrawLine
		jmp	processLoop
drawVLine:
	; now get coordinates
		lodsw
		add	ax, posY
		mov_tr	bx, ax
		lodsw
		add	ax, posY
		mov_tr	dx, ax
		lodsw
		add	ax, posX
		mov	cx, ax
		call	GrDrawLine
		jmp	processLoop
		
invertMask:
		mov	al, 0ffh
		mov	ah, CF_RGB
		mov	bx, 0ffffh
		call	GrSetAreaColor
		call	GrSetLineColor
		call	GrSetTextColor
		mov	al, SDM_100
		call	GrSetAreaMask
		call	GrSetLineMask
		call	GrSetTextMask
		mov	al, MM_XOR
		call	GrSetMixMode
		retn
getMask:
		lodsw
		mov	bl, ah
		mov	bh, ds:[si]
		inc	si
		mov	ah, CF_RGB
		call	GrSetAreaColor
		call	GrSetLineColor
		call	GrSetTextColor
		lodsb
		call	ConvertByteToMask
		call	GrSetAreaMask
		call	GrSetLineMask
		call	GrSetTextMask
		retn

drawImage:
		call	GrSaveState
	; first get coords
		add	si, 2
		lodsw
		mov_tr	bx, ax
		lodsw
		xchg	ax, bx
	; now get the run heap token for the complex data
		push	si
		push	ax, bx
		sub	si, 6
		lodsw
		add	si, 4
		mov_tr	bx, ax
	;		lodsw	; get scale factor
	;	push	ax
		
		push	bx
		pushdw	self
ifdef __HIGHC__
		call	GadgetConvertComplexDataToGString
else
		call	_GadgetConvertComplexDataToGString
endif
		add	sp, 6	; fixup dword and word args 
		mov	si, ax
	;	pop	dx	; dx = scale factor
	;	mov	bx, dx
	;	clr	ax
	;	mov	cx, ax
	;	call	GrApplyScale
		pop	ax, bx
		clr	dx
		tst	si
		jz	afterGStringDraw
	; this seems a little crazy, but to get the graphics string to
	; draw exactly relative to the origin of the gadget, we need
	; to jump through a few hoops - I peeked at the code for
	; VisDrawMoniker for some ideas on how this should be done and
	; this is what I came up with
	; first - calculate the point we want to draw at
	; then get the gstring bounds relative and
	; subtract those values from the point and we are golden
		add	ax, posX
		add	bx, posY
		push	ax, bx
		call	GrGetGStringBounds
		mov	cx, ax
		mov	dx, bx
		pop	ax, bx
		sub	ax, cx
		sub	bx, dx
		call	GrMoveTo
		clr	dx
		call	GrDrawGStringAtCP
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
afterGStringDraw:
		call	GrRestoreState
		pop	si
	;	add	si, 2	; reposition si to after image data
		jmp	processLoop
fillRect:
drawLine:
		call	getMask
		jmp	fillInvertCommon
invertRect:
invertLine:
		call	invertMask
	; grab out the RGB and opacity values
	; maskSub is implemented as a call routine as it reused so i
	; need to call it

fillInvertCommon:
		
		lodsw
		add	ax, posX
		push	ax
		lodsw
		add	ax, posY
		mov_tr	bx, ax
		lodsw
		add	ax, posX
		mov_tr	cx, ax
		lodsw
		add	ax, posY
		mov_tr	dx, ax
		pop	ax

		cmp	cmd, SDC_FILL_RECT-1
		je	doRect
		cmp	cmd, SDC_INVERT_RECT-1
		je	doRect
		
		call	GrDrawLine
		mov	al, MM_COPY
		call	GrSetMixMode
		jmp	processLoop
doRect:
	; dont draw if width or height is zero
		cmp	ax, cx
		je	afterFillRect
		cmp	bx, dx
		je	afterFillRect
		call	GrFillRect
afterFillRect:
		mov	al, MM_COPY
		call	GrSetMixMode
		jmp	processLoop
string:
	; first get the length of the string
		lodsw
		mov	temp1, si
		mov_tr	cx, ax
DBCS <		shl	cx						>
		add	si, cx
getCoords::
		lodsw
		add	ax, posX
		mov_tr	bx, ax
		lodsw
		add	ax, posY
		xchg	ax, bx
	; ax, bx = coords, cx = string size
	; now get the text color
		mov	temp2, cx
		push	ax, bx
		call	getMask

	; now lets get the font
		lodsw	; read in string length
		inc	ax	; add one for null terminator
		mov	dl, mask FEF_STRING or mask FEF_BITMAPS
		call	GrCheckFontAvail
	; cx = font ID
DBCS <		shl	ax						>
		add	si, ax
		lodsw
		mov_tr	dx, ax
		clr	ah
	; now set font with same font, new point size
DBCS <		cmp	dx, 6						>
DBCS <		jae	gotDBCSPointSize				>
DBCS <		mov	dx, 6						>
DBCS < gotDBCSPointSize:						>
		call	GrSetFont

	; al = text style (follows TextStyle record):
	;	0 = plain
	;	1 = underline
	;	2 = strike through
	;	4 = subscript
	;	8 = superscript
	;	16 = italic
	;	32 = bold
	;
		lodsw				;al <- styles to set
		mov	ah, 0xff		;ah <- styles to clear
		call	GrSetTextStyle
		
		pop	ax, bx	; ax, bx = coords
		mov	cx, temp2
DBCS <		shr	cx			; convert to # chars	 >
		push	si
		mov	si, temp1
	; if cx is 0 there is no text to draw
		jcxz	afterDraw
		call	GrDrawText
afterDraw:
		call	GrTextWidth	; dx = text width
	; store the return value in instance data
		push	ds, bx, di
		movdw	bxsi, self
		call	MemDerefDS
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
		mov	ds:[di].GGI_retval, dx
		pop	ds, bx, di
		pop	si
		
		jmp	processLoop
uiShape:
		call	getMask
		jmp	uiShapeCommon
invertUIShape:
		call	invertMask
uiShapeCommon:
	; load coordinates to draw region at
		lodsw
		mov	temp1, ax
		lodsw
		mov_tr	bx, ax
	; now load the number of bytes in the region structure
		lodsw
		mov	temp2, ax
		clr	cx
		mov	dx, cx
		mov	{word}ds:[si], 0
		mov	{word}ds:[si+2], 0
		segmov	ds:[si+4], posX2, ax
		mov	ax, posX
		sub	ds:[si+4], ax
		segmov	ds:[si+6], posY2, ax
		mov	ax, posY
		sub	ds:[si+6], ax
		mov	ax, temp1
	; set the pen to the proper spot
		add	ax, posX
		add	bx, posY
		call	GrMoveTo

	; now region params
		push	si
		add	si, temp2
		lodsw
		mov_tr	dx, ax
		lodsw
		mov_tr	bx, ax
		lodsw
		mov_tr	cx, ax
		lodsw
		xchg	ax, dx
		pop	si
		call	GrDrawRegionAtCP
		mov	al, MM_COPY
		call	GrSetMixMode
		mov	ax, temp2
		add	si, ax
		add	si, 8	; bypass region params at the end
		jmp	processLoop
done:
		pop	bx
		Assert	handle	bx
		call	MemUnlock
		.leave
		ret
dcjt2 nptr 	hline, vline, fillRect, invertRect, string, \
		uiShape, invertUIShape, drawImage, \
		drawLine, invertLine
GadgetGadgetDrawCommands	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call basic code to do drawing

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
		cl	= DrawFlags - if DF_OBJECT_SPECIFIC set then
			  		just draw, don't generate events.
		bp	= gstate to draw to
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
drawString	TCHAR	"draw", C_NULL
GadgetGadgetVisDraw	method dynamic GadgetGadgetClass, 
					MSG_VIS_DRAW
		gstate	local	hptr push bp
		flags	local	word push cx
		params	local	EntHandleEventStruct
		.enter

		mov	dl, ds:[di].GGI_gadgetFlags

		mov	ax, gstate
		push	di
		mov	di, ax
		call	GrSaveState
		pop	di

	;	mov	di, ds:[si]
	;	add	di, ds:[di].GadgetGadget_offset
		mov	ds:[di].GGI_gstate, ax
		push	bp				; frame ptr
		test	dl, mask GGF_DRAW_COMMANDS
		jnz	drawCommands

	;
	; If we got here recurrsively, draw the command buffer
	; but don't send an event.
		test	cl, mask DF_OBJECT_SPECIFIC
		jnz	drawCommands
		
		
		
		mov	ax, offset drawString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 0
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock

		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
restore:		
		mov	ds:[di].GGI_gstate, 0
		pop	bp				; frame ptr
callChildren::

	;
	; Tell children to draw themselves
	;
		push	bp				; frame ptr
		mov	cx, ss:[flags]
		mov	bp, ss:[gstate]
		mov	ax, MSG_VIS_DRAW
		mov	di, offset GadgetGadgetClass
		call	ObjCallSuperNoLock

		pop	bp				; frame ptr

		mov	di, ss:[gstate]			; gstate
		Assert	gstate di
		call	GrRestoreState
		
		.leave
		ret
drawCommands:
		mov	ax, MSG_GADGET_GADGET_DRAW
		call	ObjCallInstanceNoLock
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
		and	ds:[di].GGI_gadgetFlags, not mask GGF_DRAW_COMMANDS
		jmp	restore
GadgetGadgetVisDraw	endm

GadgetGadgetDrawCode	ends
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deal keyboard input

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
		cl	= DrawFlags
		bp	= gstate to draw to
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	9/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
charString	TCHAR	"char", C_NULL
GadgetGadgetKbdChar	method dynamic GadgetGadgetClass, 
					MSG_META_KBD_CHAR
params	local	EntHandleEventStruct
		.enter

SBCS <		clr	ch						>
		mov	ax, offset charString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 3

		
		test	dl, mask CF_STATE_KEY
		jnz	doShiftState

		mov	dh, ds:[di].GGI_shiftState
	; the first arg is the action (press, repeat, release, etc...)
		
		push	dx
	; translate the GEOS value into a LEGOS value
		mov	dh, GPA_PRESS
		cmp	dl, mask CF_FIRST_PRESS
		je	stuffAction
		mov	dh, GPA_HOLD
		cmp	dl, mask CF_REPEAT_PRESS
		je	stuffAction
		mov	dh, GPA_RELEASE
		cmp	dl, mask CF_RELEASE
		jne	done
stuffAction:
		mov	dl, dh
		clr	dh
		clr	di
		
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, dx
		pop	dx

		add	di, size ComponentData
		
	; next argument is the character itself
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, cx
		
		add	di, size ComponentData
		
	; now the shift state
		
		mov	dl, dh
		clr	dh
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, dx
		
		
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
doShiftState:
	; store away the shift state (or clear stored shift state)
		test	dl, mask CF_RELEASE
		jz	setShiftState
		clr	dh
setShiftState:
		mov	ds:[di].GGI_shiftState, dh
		jmp	done
GadgetGadgetKbdChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GSGadgetGadgetSetWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_SET_WIDTH
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
GSGadgetGadgetSetWidth	method dynamic GadgetGadgetClass, 
					MSG_GADGET_SET_WIDTH,
					MSG_GADGET_SET_HEIGHT,
					MSG_VIS_OPEN
		.enter
	; the code in gadgetclass will get the GEN_SIZE correctly
		mov	di, offset GadgetGadgetClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_VIS_SET_SIZE
		call	ObjCallInstanceNoLock
		.leave
		ret
GSGadgetGadgetSetWidth	endm
endif


		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSendPenEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	code to call pen event handler

CALLED BY:	various routines
PASS:		ax = action, bx = flag, cx,dx = x,y coords
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
penString TCHAR  "mouse", C_NULL
GadgetSendPenEvent	proc	near
params		local	EntHandleEventStruct
		.enter

	; this has been taken out of the spec
	; send a TO event if we are about to send a release event
	;		cmp	ax, GPA_RELEASE
	;	jnz	cont
	;	push	ax, bx
	;	mov	ax, GPA_TO
	;	mov	bx, 1
	;	call	GadgetSendPenEvent
	;	pop	di, bx
	;	tst	ax
	;	jz	done
	;	mov	ax, di
	;cont:
		cmp	ax, GPA_LOST
		jne	argsOk
		clr	bx
		mov	cx, bx
		mov	dx, bx
argsOk:		
		push	ax
		mov	ax, offset penString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 5
		pop	ax
		clr	di
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, ax
		add	di, size ComponentData
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, bx
		add	di, size ComponentData
	;		sub	cx, left
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, cx
		add	di, size ComponentData
	;	sub	dx, top
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, dx
		add	di, size ComponentData
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, 0

		
		push	ax, bx, cx, dx
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock
		pop	di, bx, cx, dx
		cmp	di, GPA_RELEASE
		jne	done

		tst	ax
		jz	done

	; send a LOST event if we just sent a RELEASE event
		mov	ax, GPA_LOST
		call	GadgetSendPenEvent
done:
		
		.leave
		ret
GadgetSendPenEvent	endp
		
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetGrabMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the mouse.

CALLED BY:	GadgetGadgetMetaStartSelect,
		GGGadgetGadgetActionGrabPen
PASS:
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; a macro to check if ds:si = objects AND ds:di = instance data
ECCheckGadgetObjPtrAndInstancePtr macro
EC <		Assert	objectPtr, dssi, GadgetGadgetClass		>
EC <		push	ax, di						>
EC <		mov	ax, di						>
EC <		mov	di, ds:[si]					>
EC <		add	di, ds:[di].GadgetGadget_offset			>
EC <		Assert	e, di, ax					>
EC <		pop	ax, di						>
endm

GadgetGadgetGrabMouse	proc	far
		uses	bp, cx, dx, ax
.warn -private
		ECCheckGadgetObjPtrAndInstancePtr
		test	ds:[di].EI_flags, mask EF_BUILT
		jz	done
		test	ds:[di].GGI_gadgetFlags, mask GGF_HAS_MOUSE_GRAB
		jnz	done
		or	ds:[di].GGI_gadgetFlags, mask GGF_HAS_MOUSE_GRAB
.warn @private
		.enter		
		mov	ax, MSG_VIS_GRAB_MOUSE
		call	ObjCallInstanceNoLock
		.leave		
done:
		ret
GadgetGadgetGrabMouse	endp
		
GadgetGadgetReleaseMouse	proc	far
		uses	bp, cx, dx, ax
.warn -private		
		ECCheckGadgetObjPtrAndInstancePtr
		test	ds:[di].GGI_gadgetFlags, mask GGF_HAS_MOUSE_GRAB
		jz	done
.warn @private
		.enter
		mov	ax, MSG_VIS_RELEASE_MOUSE
		call	ObjCallInstanceNoLock
.warn -private
		ECCheckGadgetObjPtrAndInstancePtr
		and	ds:[di].GGI_gadgetFlags, not mask GGF_HAS_MOUSE_GRAB
.warn @private
		.leave
done:	
		ret
GadgetGadgetReleaseMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadget{Grab,Release}Focus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the gadget grab the focus exclusive at its level (Grab).
		Or release the focus exclusive (Release).

CALLED BY:	GadgetGadgetMetaStartSelect,
		GGGadgetGadgetActionGrabPen
PASS:		*ds:si = gadget
		ds:di  = instance data of gadget
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		FIXME: We go ahead and send ourself a grab msg
		even if we've already got the focus.  Maybe we
		can just check our focusState once that's
		completely coded.  But be wary of synch problems.
		Code as is works, just might slow things down by an
		unnecessary msg.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
GadgetGadgetGrabFocus	proc	near
		uses	ax,cx,dx,bp
.warn -private
		ECCheckGadgetObjPtrAndInstancePtr
		test	ds:[di].EI_flags, mask EF_BUILT
		jz	done
.warn @private
		.enter
		mov	ax, MSG_META_GRAB_FOCUS_EXCL
		call	ObjCallInstanceNoLock
		.leave
done:		
		ret
GadgetGadgetGrabFocus	endp
endif

GadgetGadgetReleaseFocus	proc	near
		uses	ax,cx,dx,bp
.warn -private
		ECCheckGadgetObjPtrAndInstancePtr
.warn @private		
		.enter
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		call	ObjCallInstanceNoLock
		.leave
		ret
GadgetGadgetReleaseFocus	endp


		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertTOToHOLD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check the global hold tolerance and adjust PEN_TO to
	PEN_HOLD as needed

CALLED BY:	
PASS:		ds:di = GadgetGadgetInstance
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	3/20/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertTOToHOLD	proc	near
		class	GadgetGadgetClass
		uses	es
		.enter
		push	ax
		mov	ax, dgroup
		mov	es, ax
		pop	ax
		
		sub	cx, ds:[di].GGI_lastPenX
		tst	cx
		jge	gotX
		neg	cx
gotX:
		cmp	cx, es:[holdTolerance]
		ja	done
		
		sub	dx, ds:[di].GGI_lastPenY
		tst	dx
		jge	gotY
		neg	dx
gotY:
		cmp	dx, es:[holdTolerance]
		ja	done
		
	; we are within the tolerance so its a HOLD		
		mov	ax, GPA_HOLD
		SetGadgetPenState GPS_HELD

	; pretend this event happened right at the original spot so we
	; know	when we have really moved far enough away from the
	; original press to do TO events
		
		mov	cx, ds:[di].GGI_lastPenX
		mov	dx, ds:[di].GGI_lastPenY
done:
		.leave
		ret
ConvertTOToHOLD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetMetaStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there is a basic handler for this object being
		clicked on then call it.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
		bp	= ButtonInfo
		cx, dx	= x, y coords of event
RETURN:		ax	= MouseReturnFlags
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	11/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetMetaStartSelect	method dynamic GadgetGadgetClass, 
					MSG_META_START_SELECT,
					MSG_META_DRAG_SELECT,
					MSG_META_END_SELECT,
					MSG_META_MOUSE_PTR
buttonInfo	local 	word push bp
mouseX		local	word push cx
mouseY		local	word push dx
msg		local	word push ax
top		local	word
left		local	word	
temp		local	word
		
		
		uses	bp
		.enter
	;
	; If there is a child, send the message on to it.
	;
		push	bp
		mov	bp, buttonInfo
		call	VisCallChildUnderPoint
		pop	bp
		jc	doneWithAX

		mov	ax, msg
		push	bp
		mov	ax, MSG_VIS_GET_BOUNDS
		call	ObjCallInstanceNoLock
		mov	bx, bp
		pop	bp

		mov	left, ax
		mov	top, bx

		Assert	objectPtr, dssi, GadgetGadgetClass
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
		test	ds:[di].GGI_gadgetFlags, mask GGF_PEN
	; FIXME - this should send this event to the parent component
	; If you change it to send to the parent, make sure tables don't.
		LONG jz	done

		mov	temp, 1		
		cmp	mouseX, ax
		jge	checkRight
		mov	temp, 0
checkRight:
		cmp	mouseX, cx
		jle	checkUp
		mov	temp, 0
checkUp:
		cmp	mouseY, bx
		jge	checkDown
		mov	temp, 0
checkDown:
		cmp	mouseY, dx
		jle	afterBoundsCheck
		mov	temp, 0
afterBoundsCheck:

		mov	ax, msg
		mov	bx, temp
		mov	cx, mouseX
		mov	dx, mouseY
		
	; calculate value for action and flag args
		cmp	ax, MSG_META_START_SELECT
		je	doStartSelect

		cmp	ax, MSG_META_END_SELECT
		LONG je	doEndSelect

		cmp	ax, MSG_META_DRAG_SELECT
		LONG je	doDragSelect

		cmp	ax, MSG_META_MOUSE_PTR
		je	doMousePtr

		jmp	done

doMousePtr:
		mov	temp, 0
	; see if this was done with the button down or not
		.assert GPS_NONE eq 0
		test	ds:[di].GGI_gadgetFlags, mask GGF_PEN_STATE
		jz	doFlyOver

	; since the penState is not NONE, we must have the button down
	; so this is a MOVE

	; there are two ways a move event is made, either by moving
	; with readyPenMove set, or by entering or leaving the
	; object's bounds

	; check bounds situation
		tst	bx
		jz	moveIsOut

		test	ds:[di].GGI_gadgetFlags, mask GGF_IN_BOUNDS
		lahf
		or	ds:[di].GGI_gadgetFlags, mask GGF_IN_BOUNDS
		sahf
		jz	doMove
		mov	temp, 1
		jmp	doMove
moveIsOut:
	; were we in or out - if out, check readyPenMove
		test	ds:[di].GGI_gadgetFlags, mask GGF_IN_BOUNDS
		lahf
		and	ds:[di].GGI_gadgetFlags, not mask GGF_IN_BOUNDS
		sahf
		jnz	doMove
		mov	temp, 1
	; were went from in to out
	;	jmp	doMove
	;checkMoveReady:
	;	test	ds:[di].GGI_gadgetFlags, mask GGF_READY_PEN_MOVE
	;	jnz	doMove
	; we need to set the state either way so that MSG_META_PTRs
	; will do the right thing in both cases
	;	SetGadgetPenState	GPS_DRAGGED
	;	LONG jz	done
doMove:
		GetGadgetPenState	al
		Assert urange al, GPS_PRESSED, GPS_MOVED
		cmp	al, GPS_PRESSED
		jne	stuffTo
		mov	ax, GPA_DRAG
		SetGadgetPenState	GPS_DRAGGED
	; also convert drags holds if within tolerance
		call	ConvertTOToHOLD
	; if we converted to a HOLD, then we really just want to ignore this
	; as we will get the HOLD from the DRAG_SELECT when it comes in
		cmp	ax, GPA_HOLD
		jne	stuffIt
	; so we go back to PRESSED
		SetGadgetPenState	GPS_PRESSED
		jmp	done
stuffTo:
		SetGadgetPenState	GPS_MOVED
		mov	ax, GPA_TO
		tst	temp
		jz	stuffIt
		test	ds:[di].GGI_gadgetFlags, mask GGF_READY_PEN_MOVE
		LONG jz	done
		jmp	stuffIt
doFlyOver:
	; if the left mouse button is down, then someone clicked
	; outside of the gadget, and then moved the mouse over the
	; gadget without lifting the pen, so we don't want to generate
	; fly over events in that case
		test	buttonInfo, mask BI_B0_DOWN
		jnz	done
		
	; if the coordinates of this event are the last as the last
	; event then ignore it
		cmp	cx, ds:[di].GGI_lastPenX
		jne	contFlyOver
		cmp	dx, ds:[di].GGI_lastPenY
		je	done
contFlyOver:
		test	ds:[di].GGI_gadgetFlags, mask GGF_HAS_MOUSE_GRAB
		jz	flyOverGrabMouse

		tst	bx
		jnz	checkFlyOverRPM

	; if we are not in the vis bounds but still have the mouse
	; grab we need to get rid of the mouse grab and create a fly
	; over exit event.
	; We shouldn't have the focus at this point, so don't release it.
	;   							-jmagasin
		call	GadgetGadgetReleaseMouse
stuffFlyOver:
		mov	ax, GPA_FLY_OVER
		jmp	stuffIt
flyOverGrabMouse:
	; see if we are inside out bounds or not, if not then
	; just ignore the eveny, otherwise
	; grab the mouse so we can find out when the mouse exits our
	; bounds
		tst	bx
		jz	done

		call	GadgetGadgetGrabMouse
		jmp	stuffFlyOver
checkFlyOverRPM:
		test	ds:[di].GGI_gadgetFlags, mask GGF_READY_PEN_MOVE
		LONG jz	done
		jmp	stuffFlyOver
doStartSelect:
		tst	bx
		LONG jz	done
		or	ds:[di].GGI_gadgetFlags, mask GGF_IN_BOUNDS
		SetGadgetPenState GPS_PRESSED
		call	GadgetGadgetGrabMouse
stuffPress::
		mov	ax, GPA_PRESS
		clr	bx
		test	buttonInfo, mask BI_DOUBLE_PRESS
		jz	stuffIt
		inc	bx
		jmp	stuffIt
doEndSelect:
		and	ds:[di].GGI_gadgetFlags, not mask GGF_IN_BOUNDS
		
	; if we end select outside the bounds we want to release the mouse
	; but as long as we are inside, we dont release the mouse so
	; we can keep getting PTR events

		mov_tr	ax, bx
		GetGadgetPenState bl
		SetGadgetPenState GPS_NONE
		tst	ax
		jnz	stuffRelease

	; we are not in the bounds, so this will be a lost rather than
	; a release
		mov	ax, GPA_LOST
		call	GadgetGadgetReleaseMouse
		jmp	stuffIt
stuffRelease:
		clr	bh
	; if we are not expecting an pen release, just ignore it
		cmp	bl, GPS_NONE
		je	done
		Assert	urange bl, GPS_PRESSED, GPS_MOVED
	; return 1 for quick press, 0 otherwise
		cmp	bl, GPS_PRESSED
		mov	bl, 1
		mov	ax, GPA_RELEASE
		je	stuffIt
		clr	bl
		jmp	stuffIt
doDragSelect:
		tst	bx
		LONG jz	done

		GetGadgetPenState al
	
	; record that we have been held down a "while"
		SetGadgetPenState GPS_HELD

	; if we are already in some other state, then ignore this
		cmp	al, GPS_PRESSED
		jne	done
		
		mov	ax, GPA_HOLD
		mov	bx, 1
		jmp	stuffIt
if 0		
checkTolerance:
	;	check the hold tolerance if its a PEN_TO and see if
	;	should really be a PEN_HOLD
	; 	will set ax to GPA_HOLD as needed
		call	ConvertTOToHOLD
endif
stuffIt:
	; clear out ready pen move after ALL pen activity
	; we need to do it BEFORE we call ENT_HANDLE_EVENT as the
	; event may want to reset readyPenMove at the end, and we
	; don't want to undo that
	; the spec has changed, now this gets handles by the
	; penInterest action
		
	;	and	ds:[di].GGI_gadgetFlags, not mask GGF_READY_PEN_MOVE

		
		mov	ds:[di].GGI_lastPenX, cx
		mov	ds:[di].GGI_lastPenY, dx
		
		sub	cx, left
		sub	dx, top
		call	GadgetSendPenEvent
		tst	ax
		
		jnz	done
callSuper::
	;
	; if not, just pass it on and let the object handle it
	;
		push	bp
		mov	di, offset GadgetGadgetClass
		mov	ax, msg
		mov	cx, mouseX
		mov	dx, mouseY
		call	ObjCallSuperNoLock
		pop	bp
		jmp	doneWithAX
done:
		mov	ax, mask MRF_PROCESSED
doneWithAX:
		.leave
		ret
GadgetGadgetMetaStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGGadgetGadgetSetPen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_SET_PEN
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGGadgetGadgetSetPen	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_GET_PEN,
					MSG_GADGET_GADGET_SET_PEN
		uses	ax, cx, dx, bp
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset

		les	si, ss:[bp].SPA_compDataPtr
		
		cmp	ax, MSG_GADGET_GADGET_GET_PEN
		je	getPen

		cmp	es:[si].CD_type, LT_TYPE_INTEGER
		jne	wrongType

		and	ds:[di].GGI_gadgetFlags, not ALL_PEN_EVENTS
		
		mov	ax, es:[si].CD_data.LD_integer
		tst	ax
		jz	done

		or	ds:[di].GGI_gadgetFlags, mask GGF_PEN
		cmp	al, GPI_ENTER_LEAVE
		je	done
		
		or	ds:[di].GGI_gadgetFlags, mask GGF_READY_PEN_MOVE
done:
		.leave
		ret

getPen:
		clr	ax
		test	ds:[di].GGI_gadgetFlags, mask GGF_PEN
		jz	stuffIt
		inc	al	; al = GPI_ENTER_LEAVE
		test	ds:[di].GGI_gadgetFlags, mask GGF_READY_PEN_MOVE
		jz	stuffIt
		inc	al	; al = GPI_ALL
stuffIt:
		mov	es:[si].CD_data.LD_integer, ax
		mov	es:[si].CD_type, LT_TYPE_INTEGER
		jmp	done
wrongType:
		mov	es:[si].CD_type, LT_TYPE_ERROR
		mov	es:[si].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done		
GGGadgetGadgetSetPen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGGadgetGadgetActionRedoGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_ACTION_REDO_GEOMETRY
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGGadgetGadgetActionRedoGeometry	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_ACTION_REDO_GEOMETRY
		uses	ax, cx, dx, bp
		.enter

		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
		
		.leave
		ret
GGGadgetGadgetActionRedoGeometry	endm

if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGGadgetGadgetActionReadyPenMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_ACTION_READY_PEN_MOVE
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 7/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGGadgetGadgetActionReadyPenMove	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_ACTION_READY_PEN_MOVE
		uses	ax, cx, dx, bp
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].GadgetGadget_offset
		or	ds:[di].GGI_gadgetFlags, mask GGF_READY_PEN_MOVE
		.leave
		ret
GGGadgetGadgetActionReadyPenMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGEntValidateParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_VALIDATE_PARENT
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	8/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGEntValidateParent	method dynamic GadgetGadgetClass, 
					MSG_ENT_VALIDATE_PARENT
		.enter
		mov	ax, segment GadgetClipperClass
		mov	es, ax
		mov	di, offset GadgetClipperClass
		call	EntUtilCheckClass
		.leave
		ret
GGEntValidateParent	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunMainMessageDispatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	try to dispatch messages on queue from RunMainLoop

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 2/22/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetMessageDispatch	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	clr	bx
	call	GeodeInfoQueue
	mov_tr	cx, ax
	jcxz	done
	mov	di, mask MF_CALL
dispatchLoop:
	push	cx, di, bx	
	call	QueueGetMessage
	mov_tr	bx, ax
	call	MessageDispatch
	pop	cx, di, bx
	loop	dispatchLoop
done:	
	.leave
	ret
GadgetMessageDispatch	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGEntUnivLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_UNIV_LEAVE
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	9/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGEntUnivLeave	method dynamic GadgetGadgetClass, 
					MSG_ENT_UNIV_LEAVE
		uses	ax, cx, dx, bp
		.enter
	; if we don't have the mouse grab nothing interesting is happening
		test	ds:[di].GGI_gadgetFlags, mask GGF_HAS_MOUSE_GRAB
		jz	done

	; if the mouse is down this might already work
		GetGadgetPenState	al
		cmp	al, GPS_NONE
		jne	done
		
		call	GadgetGadgetReleaseMouse
		clr	bx
		mov	ax, GPA_FLY_OVER

		clr	cx
		mov	dx, cx
		call	GadgetSendPenEvent
done:
		.leave
		ret
GGEntUnivLeave	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
		bp	= SpecBuildFlags
RETURN:		
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetSpecBuild	method dynamic GadgetGadgetClass, 
					MSG_SPEC_BUILD
		.enter

	;
	; Set instance data of GenGadgetClass
	;

		mov	ax, MSG_SPEC_BUILD
		mov	di, offset GadgetGadgetClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_VIS_COMP_SET_GEO_ATTRS
		clr	dx				; bits to clear
		mov	cx, mask VCGA_CUSTOM_MANAGE_CHILDREN	; set
		call	ObjCallInstanceNoLock
	;
	; I am not sure if setting this flag actually does anything,
	; but it seems like it should be set.  - ron (IS_COMPOSITE)
	;
	; Let's be an input node so that we can receive MSG_META_MUP
	; ALTER_FTVMC_EXCL and do the right thing if we are or aren't
	; focusable. - jonathan
	;
		mov	ax, MSG_VIS_SET_TYPE_FLAGS
		mov	cl, mask VTF_IS_COMPOSITE or mask VTF_IS_INPUT_NODE
		clr	ch
		call	ObjCallInstanceNoLock

		.leave
		ret
GadgetGadgetSpecBuild	endm

GadgetGadgetSpecUnbuild method	dynamic	GadgetGadgetClass,
							MSG_SPEC_UNBUILD
		.enter

		call	GadgetGadgetReleaseMouse
		call	GadgetGadgetReleaseFocus

	;
	; If we had the pen while we were dismissed, raise a "lost"
	; event and fix up our state.  (Covers case where we don't
	; get META_ND_SELECT.)  Note that we don't clear GGF_IN_BOUNDS.
	; Instead we rely on GadgetGadgetMetaStartSelect to fix flags.
	;
.warn -private
		GetGadgetPenState bl
		cmp	bl, GPS_NONE
		je	callSuper
		SetGadgetPenState GPS_NONE
.warn @private
		clr	cx,dx				; Coords???
		mov	ax, GPA_LOST
		call	GadgetSendPenEvent

callSuper:
		mov	di, offset GadgetGadgetClass
		mov	ax, MSG_SPEC_UNBUILD
		call	ObjCallSuperNoLock
		.leave
		ret
GadgetGadgetSpecUnbuild	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetVisRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
		cx	= RecalcSizeArgs -- suggest width for object
		dx	= RecalcSizeArgs -- suggest height for object
RETURN:		cx	= widt to use
		dx	= height to use
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetVisRecalcSize	method dynamic GadgetGadgetClass, 
					MSG_VIS_RECALC_SIZE
		.enter
	;
	;
	; We have to tell our children to recalc their sizes as the superclass
	; won't do it because we have CUSTOM_MANAGE_CHILDREN set.
	; We have CUSTOM_MANAGE_CHILDREN set so the superclass doesn't try
	; to make itself as big as its children.
	;
		call	GadgetUtilVisRecalcSize		 ; size children

	; get what our size should be.

		call	GadgetUtilSizeSelf

	; and set the size
	;		mov	ax, MSG_VIS_SET_SIZE
	;		call	ObjCallInstanceNoLock

	; set the geometry falgs, there is no message for this.
EC <		call	VisCheckVisAssumption				>
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or mask VOF_GEO_UPDATE_PATH)

		
		.leave
		ret
GadgetGadgetVisRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetGetTile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_GET_TILE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- GetPropertyArgs
RETURN:		ComponentData filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetGetTile	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_GET_TILE
		.enter
		les	di, ss:[bp].GPA_compDataPtr
		mov	es:[di].CD_data.LD_integer, 0
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		.leave
		Destroy	ax, cx, dx
		ret
GadgetGadgetGetTile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetSetTile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_SET_TILE
PASS:		ds,si,di,bx,es,ax - standard method stuff
		ss:bp	- SetPropertyArgs
RETURN:		SPA_compData.CD_type possibly set to LT_TYPE_ERROR
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	10/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetSetTile	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_SET_TILE
		.enter
	; this page intentionally left blank
	; You can't set this property, but returning a RTE is unnecessary.

		.leave
		Destroy	ax, cx, dx
		ret
GadgetGadgetSetTile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGGadgetGadgetActionGrabPen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GADGET_ACTION_GRAB_PEN
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/25/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGGadgetGadgetActionGrabPen	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_ACTION_GRAB_PEN
		uses	ax, cx, dx, bp
		.enter

		call	GadgetGadgetGrabMouse
		
		.leave
		ret
GGGadgetGadgetActionGrabPen	endm



		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	cleanup if neccessary

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	10/26/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGEntDestroy	method dynamic GadgetGadgetClass, 
					MSG_ENT_DESTROY, MSG_META_DETACH
		.enter

		tst	ds:[di].GGI_commands
		jz	afterFree
		push	bx
		mov	bx, ds:[di].GGI_commands
		call	MemFree
		pop	bx
afterFree:
		call	GadgetGadgetReleaseMouse
		call	GadgetGadgetReleaseFocus
		mov	di, offset GadgetGadgetClass
		call	ObjCallSuperNoLock
		.leave
		ret
GGEntDestroy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetGetNumChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of children we've got.

CALLED BY:	MSG_GADGET_GADGET_GET_NUM_CHILDREN
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		GetPropertyArgs filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 6/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGadgetGetNumChildren	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_GET_NUM_CHILDREN
		.enter
	;
	; EntClass does child-support:)
	;
		mov	ax, MSG_ENT_GET_NUM_CHILDREN
		call	ObjCallInstanceNoLock
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetGadgetGetNumChildren	endm

GadgetGadgetSetNumChildren	method dynamic GadgetGadgetClass,
					MSG_GADGET_GADGET_SET_NUM_CHILDREN,
					MSG_GADGET_GADGET_ACTION_SET_CHILDREN
		.enter

		mov	ax, CPE_READONLY_PROPERTY
		call	GadgetUtilReturnSetPropError
		
		.leave
		ret
GadgetGadgetSetNumChildren	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGActionGetChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the gadget's children.

CALLED BY:	MSG_GADGET_GADGET_ACTION_GET_CHILDREN
PASS:		*ds:si	= GadgetGadgetClass object
		ds:di	= GadgetGadgetClass instance data
		ds:bx	= GadgetGadgetClass object (same as *ds:si)
		es 	= segment of GadgetGadgetClass
		ax	= message #
		ss:bp	= EntDoActionArgs
RETURN:		ComponentData filled in (_retVal)
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 6/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGActionGetChildren	method dynamic GadgetGadgetClass, 
					MSG_GADGET_GADGET_ACTION_GET_CHILDREN
		.enter
	;
	; Have EntClass take care of this for us.
	;
		mov	ax, MSG_ENT_GET_CHILDREN
		call	ObjCallInstanceNoLock
		
		.leave
		Destroy	ax, cx, dx
		ret
GGActionGetChildren	endm



GadgetGadgetCode	ends
