COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Gadget
FILE:		gadgetMaster.asm

AUTHOR:		Ronald Braunstein, Jul 15, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	7/15/94		Initial revision


DESCRIPTION:
	Code for Dealing with GadgetClass
		

	$Id: gdgmast.asm,v 1.2 98/06/24 21:09:33 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	common.def

DefLib	Legos/gadget.def

idata	segment
GadgetClass
GadgetClipboardableClass
idata	ends
GadgetMastCode	segment	Resource


makePropEntry gadget, look, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_LOOK>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_LOOK>

makePropEntry gadget, readOnly, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_READ_ONLY>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_READ_ONLY>

makePropEntry gadget, caption, LT_TYPE_STRING,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_CAPTION>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_CAPTION>

makePropEntry gadget, graphic, LT_TYPE_COMPLEX,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_GRAPHIC>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_GRAPHIC>

makePropEntry gadget, left, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_LEFT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_LEFT>

makePropEntry gadget, top, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_TOP>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_TOP>

makePropEntry gadget, height, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_HEIGHT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_HEIGHT>

makePropEntry gadget, width, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_WIDTH>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_WIDTH>

makePropEntry gadget, sizeHControl, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_SIZE_HCONTROL>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_SIZE_HCONTROL>

makePropEntry gadget, sizeVControl, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_SIZE_VCONTROL>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_SIZE_VCONTROL>

makePropEntry gadget, helpContext, LT_TYPE_STRING, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_HELP_CONTEXT>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_HELP_CONTEXT>

makePropEntry gadget, helpFile, LT_TYPE_STRING, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_GET_HELP_FILE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_SET_HELP_FILE>

; Note: visible is still defined in Ent.

compMkPropTable GadgetProperty, gadget, look, \
	 readOnly, caption, graphic, left, top, height, width, \
	 sizeHControl, sizeVControl, helpContext, helpFile


makeActionEntry gadget, SetColor, MSG_GADGET_ACTION_SET_COLOR, LT_TYPE_UNKNOWN,-1
makeActionEntry gadget, SetSize, MSG_GADGET_ACTION_SET_SIZE, LT_TYPE_UNKNOWN,-1
makeActionEntry gadget, Positioned?, MSG_GADGET_ACTION_POSITIONED, LT_TYPE_UNKNOWN,0

compMkActTable gadget, SetColor, SetSize, Positioned?


makePropEntry clipboardable, focusable, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_GET_FOCUSABLE>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_SET_FOCUSABLE>
makePropEntry clipboardable, focusState, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_GET_FOCUS_STATE>,\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_SET_FOCUS_STATE>
makePropEntry clipboardable, clipboardable, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_GET_CLIPBOARDABLE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_SET_CLIPBOARDABLE>
makePropEntry clipboardable, deletable, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_GET_DELETABLE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_SET_DELETABLE>
makePropEntry clipboardable, copyable, LT_TYPE_INTEGER,	\
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_GET_COPYABLE>, \
	PDT_SEND_MESSAGE, <PD_message MSG_GADGET_CLIPBOARDABLE_SET_COPYABLE>

makeUndefinedPropEntry clipboardable, caption
makeUndefinedPropEntry clipboardable, graphic

compMkPropTable GadgetClipboardProperty, clipboardable, focusable, \
	focusState, clipboardable, deletable, copyable, caption, graphic

MakePropRoutines Clipboardable, clipboardable



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEntResolveAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_ENT_RESOLVE_ACTION
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/19/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GEntResolveAction	method dynamic GadgetClass, 
					MSG_ENT_RESOLVE_ACTION
	.enter
	mov	bx, offset gadgetActionTable
	segmov	es, cs
	mov	di, offset GadgetClass
	mov	ax, segment GadgetClass
	call	EntResolveActionCommon
	.leave
	ret
GEntResolveAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDoAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this is an action we know how to perform

CALLED BY:	MSG_ENT_DO_ACTION
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	8/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetDoAction	method dynamic GadgetClass, 
					MSG_ENT_DO_ACTION, MSG_ENT_CHECK_ACTION
	.enter
	
	segmov	es, cs
	mov	bx, offset gadgetActionTable
	mov	di, offset GadgetClass	; for calling super
	mov	ax, segment GadgetClass
	call	EntUtilDoAction
	.leave
	ret
GadgetDoAction	endm

	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetDoActionCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this is an action we know how to perform

CALLED BY:	MSG_ENT_DO_ACTION
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	8/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetActionJumpTable	nptr \
	offset	getFlexInfo
	
GadgetDoActionCommon	method dynamic GadgetClass,
					MSG_GADGET_ACTION_POSITIONED
			
.warn -jmp
		.enter
		sub	ax, MSG_GADGET_ACTION_SET_COLOR
		mov	bx, ax
		shl	bx
		jmp	cs:[GadgetActionJumpTable][bx]

	;=============== getFlexInfo ==============
getFlexInfo label near
		mov	ax, ATTR_GEN_POSITION
		clr	dx
		call	ObjVarFindData
		jnc	setInt
		inc	dx
setInt:
	; return dx as an integer variable
		les	di, ss:[bp].EDAA_retval
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, dx
.warn @jmp
	
done::		
		.leave
		ret
GadgetDoActionCommon	endm

if _PCV


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform operations that need to happen only once and before
		anything else happens.

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	11/ 4/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetEntInitialize	method dynamic GadgetClass, 
					MSG_ENT_INITIALIZE

		uses	cx
		.enter
		mov	di, offset GadgetClass
		call	ObjCallSuperNoLock
	;
	; Set the legos look to 0 as a default.
	; This helps the spui know the difference between a component
	; and a normal geos object
		clr	cx
		mov	ax, MSG_SPEC_SET_LEGOS_LOOK
		call	ObjCallInstanceNoLock

		.leave
		ret
GadgetEntInitialize	endm
endif ; pcv

ifdef USE_BACKGROUND_COLORS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the background in the provided mask.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 3/ 1/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetVisDraw	method dynamic GadgetClass, 
					MSG_VIS_DRAW
	uses	ax, cx, dx, bp
		.enter
		test	cl, mask DF_EXPOSED
		jz	callSuper

		mov	dl, ds:[di].GI_bgPattern
		
		push	cx
		mov	di, bp			; gstate

		mov	ax, C_BLACK
		call	GrSetAreaColor
		mov	al, dl
		call	GrSetAreaMask
		
		call	VisGetBounds
		call	GrFillRect
		pop	cx
		mov	al, SDM_100
		call	GrSetAreaMask

callSuper:
		mov	ax, MSG_VIS_DRAW
		mov	di, offset GadgetClass
		call	ObjCallSuperNoLock

		.leave
	ret
GadgetVisDraw	endm
endif


if 0
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetPrintStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forward print requests to the default draw mechanism.

CALLED BY:	MSG_PRINT_GET_DOC_NAME
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		*cx:dx	= PrintControlClass object		

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1998/5/29	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetPrintGetDocName	method dynamic GadgetClass, 
					MSG_PRINT_GET_DOC_NAME
	uses	ax, cx, dx, bp
		.enter

		movdw	bxsi, cxdx
		mov	ax, MSG_PRINT_CONTROL_SET_DOC_NAME
		mov	cx, cs
		mov	dx, offset defaultPrintJobName
		call	ObjMessage

		.leave
	ret
GadgetPrintGetDocName	endm

endif	   ;  0

 
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetPrintStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forward print requests to the default draw mechanism.

CALLED BY:	MSG_PRINT_START_PRINTING
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		*cx:dx	= PrintControlClass object		
		^hbp	= GState to draw through.

RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	1998/5/27	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
defaultPrintJobName	TCHAR	"NewBASIC Gadget", C_NULL
	
GadgetPrintStartPrinting	method dynamic GadgetClass, 
					MSG_PRINT_START_PRINTING
	uses	ax, cx, dx, bp
		.enter

		mov	ax, MSG_PRINT_START_PRINTING
		mov	di, offset GadgetClass
		call	ObjCallSuperNoLock	

		push	cx, dx		; save printControl 
 		push	ds, si		; save self 
		push	bp		; save gstate 
	;;
	;; First, send all the necessary messages to the PrintControl.
	;; 
		movdw	bxsi, cxdx	; cx:dx = PrintControl 
		call	MemDerefDS	; make printControl local self 
	
		mov	ax, MSG_PRINT_CONTROL_GET_PAPER_SIZE
		call	ObjCallInstanceNoLock	; cx:dx = default doc size 
		mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE
		call	ObjCallInstanceNoLock

		mov	cx, 1
		mov	dx, 1		; cx:dx = default page count
		mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
		call	ObjCallInstanceNoLock

		mov	cx, cs
		mov	dx, offset defaultPrintJobName
		mov	ax, MSG_PRINT_CONTROL_SET_DOC_NAME
		call	ObjCallInstanceNoLock
	;;
	;; Next, initialize gstate page size transforms.
	;; 
		pop	di		; restore gstate 
 		call	GrSaveState	
 		call	GrInitDefaultTransform
	;;
	;; Simply forward print requests to the default draw mechanism.
	;;
  		xchg	di, bp	
 		pop	ds, si		; restore self 
 		mov	ax, MSG_META_EXPOSED_FOR_PRINT
   		call	ObjCallInstanceNoLock
  		xchg	di, bp
	;;
	;; test square...
	;; 
;  		mov	ax, 10	
;  		mov	bx, 10
;  		mov	cx, 100
;  		mov	dx, 100
; 		call	GrDrawRect	
	;;
	;; Close up the gstate drawing.
	;; 
 		call	GrRestoreState

 		mov	ax, PEC_FORM_FEED
		call	GrNewPage
		xchg	di, bp
	;;
	;; Send out the completion signal.
	;; 
		pop	bx, si		; restore printControl 
 		mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
 		call	ObjMessage

		.leave
	ret
GadgetPrintStartPrinting	endm
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetReadOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get our read only state

CALLED BY:	MSG_GADGET_GET_READ_ONLY
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/11/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetReadOnly	method dynamic GadgetClass,
					MSG_GADGET_GET_READ_ONLY
		.enter

		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, 0
	
		mov	ax, MSG_GEN_GET_ATTRIBUTES
		call	ObjCallInstanceNoLock

		test	cl, mask GA_READ_ONLY
		jz	done

		mov	es:[di].CD_data.LD_integer, 1
done:
		.leave
		Destroy	ax, cx, dx
		ret
GadgetGetReadOnly	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetReadOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our read only state

CALLED BY:	MSG_GADGET_SET_READ_ONLY
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	FIXME - setting this property while the object is visible may cause
	problems....

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	10/11/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSetReadOnly	method dynamic GadgetClass,
					MSG_GADGET_SET_READ_ONLY
		uses	bp
		.enter

		clr	cx
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	ch, mask GA_READ_ONLY

		tst	es:[di].CD_data.LD_integer
		jz	setAttrs
		xchg	ch, cl
setAttrs:
	; Make sure we are not usable before setting attrs
	;
		call	GadgetSetGenAttrs
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetSetReadOnly	endm
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetGenAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the GenAttrs for the object making sure the
		component is not enabled when the attrs are set.

CALLED BY:	GLOBAL
PASS:		*ds:si		- component
		ch, cl		- as for MSG_GEN_SET_ATTRS
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Makes the object not usable if it is usabled then makes
		it usable again.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/10/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSetGenAttrs	proc	near
		.enter

	;	Assert	objectOD, {ds:[LBMH_handle]}si, EntClass, fixup
		push	cx			; attrs to set
		clr	bx			; 0 means not enabled
		mov	ax, MSG_GEN_GET_USABLE
		call	ObjCallInstanceNoLock
		jnc	okToSet
	;
	; Set it not usable and remember to set it usable later
	;
		mov	dx, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjCallInstanceNoLock
		inc	bx			; 1 means initially enabled

okToSet:
		pop	cx			; attrs to set
		mov	ax, MSG_GEN_SET_ATTRS
		call	ObjCallInstanceNoLock

		cmp	bx, 0
		je	done
	;
	; Now set it enabled again so the user doesn't have to
	; worry about this cruft.
	;
		mov	dx, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjCallInstanceNoLock

done:
		
		
		.leave
		ret
GadgetSetGenAttrs	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetCaption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the moniker with the string passed in.

CALLED BY:	MSG_GADGET_SET_CAPTION
PASS:		*ds:si	= GenClass object
		ds:di	= GenClass instance data
		ds:bx	= GenClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		*ds:si is not necessarily a gadget object.  It could be
		a GenItem for choice or toggle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	GadgetSetCaption:far
GadgetSetCaption	method	GadgetClass, MSG_GADGET_SET_CAPTION
		uses	bp
		.enter

		les	di, ss:[bp].SPA_compDataPtr
		cmp	es:[di].CD_type, LT_TYPE_STRING
		jne	typeError
if _PCV
		
	;
	; Make sure we use the right button regions when drawing
	;
		mov	ax, HINT_USE_COMPRESSED_INSETS_FOR_MONIKER
		call	ObjVarDeleteData
endif
		
	;
	; Lock down the string
	;
		sub	sp, size RunHeapLockStruct
		mov	bx, sp
		lea	dx, ss:[bx].RHLS_eptr
		movdw	ss:[bx].RHLS_dataPtr, ssdx
		mov	ax, es:[di].CD_data.LD_string
		mov	ss:[bx].RHLS_token, ax 
		movdw	cxdx, ss:[bp].SPA_runHeapInfoPtr
		movdw	ss:[bx].RHLS_rhi, cxdx
		call	RunHeapLock
		mov	bx, sp
		movdw	esdi, ss:[bx].RHLS_eptr		; fptr to data
		Assert	fptr	esdi
	;
	; Check for Null
	;
		Assert	nullTerminatedAscii esdi
		call	LocalStringSize
		jcxz	removeMoniker

		movdw	cxdx, esdi
	;
	; Tell the list what the string is
	;
		mov	bp, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		call	ObjCallInstanceNoLock
	;
	; Unlock the string
	;
done:
		call	RunHeapUnlock
		add	sp, size RunHeapLockStruct
doneError:
		.leave
		Destroy	ax, cx, dx
		ret

removeMoniker:
	;
	; If we just REPLACE_VIS_MONIKER_TEXT with a null text string, the
	; spui will still reserve a bit of space for the moniker.  Instead,
	; lets remove the moniker altogether by sending USE_VIS_MONIKER with a
	; null chunk handle.
	;
		mov	ax, MSG_GEN_GET_VIS_MONIKER		
		call	ObjCallInstanceNoLock		

		push	ax			; save vismon chunk
		clr	cx
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		call	ObjCallInstanceNoLock

		pop	ax			; restore vismon chunk
		tst	ax
		jz	done
		
		Assert	chunk ax, ds
		call	LMemFree

		jmp	done
typeError:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	doneError
GadgetSetCaption	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetCaption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the string that is being used as the moniker

CALLED BY:	MSG_GADGET_GET_CAPTION
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= GetPropertyArgs
RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_string filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
		*ds:si is not necessarily a gadget object.  It could be
		a GenItem for choice or toggle.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetCaption	method GadgetClass, MSG_GADGET_GET_CAPTION
		.enter
		push	bp				; param
		mov	ax, MSG_GEN_GET_VIS_MONIKER		
		call	ObjCallInstanceNoLock
		pop	bp				; param
		tst	ax
		LONG jz		storeStringToken
haveMoniker::
		mov	si, ax				; moniker chunk
		Assert	chunk	si, ds
		.norcheck
		ChunkSizeHandle	ds, si, ax
		.rcheck
		sub	ax, size VisMoniker
		sub	ax, size VisMonikerText		; ax = size of string
		mov	si, ds:[si]			; VisMoniker
	;
	; Make sure we don't have a gstring here.  If so, return null string
	;
		test	ds:[si].VM_type, mask VMT_GSTRING
		jnz	handleNoTextMoniker
		
	;
	; Create a string on the heap to hold the vis moniker text.
	;
	; ax = size of string
	;
		lea	si, ds:[si].VM_data.VMT_text
		sub	sp, size RunHeapAllocStruct
		mov	bx, sp
		movdw	cxdx, ss:[bp].GPA_runHeapInfoPtr

		movdw	ss:[bx].RHAS_data, dssi
		mov	ss:[bx].RHAS_size, ax
		clr	ss:[bx].RHAS_refCount
		mov	ss:[bx].RHAS_type, RHT_STRING
		movdw	ss:[bx].RHAS_rhi, cxdx
		
		call	RunHeapAlloc
		add	sp, size RunHeapAllocStruct
storeStringToken:
		
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_STRING
		mov	es:[di].CD_data.LD_string, ax
		.leave
		Destroy	ax, cx, dx
		ret
handleNoTextMoniker:
	;
	; return the null string
	;
		clr ax
		jmp	storeStringToken
GadgetGetCaption	endm
public GadgetGetCaption

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extracts the GSTRING or BITMAP from the LegosComplex passed 
		in the ComponentData protion of the SetPropertyArgs and sets
		the graphic moniker of this object from that.

CALLED BY:	MSG_GADGET_SET_GRAPHIC
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= SetPropertyArgs

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/13/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGadgetSetGraphic	method dynamic GadgetClass, 
					MSG_GADGET_SET_GRAPHIC
		mov	dx, si
		FALL_THRU	GadgetSetGraphicOnObject
GGadgetSetGraphic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetGraphicOnObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the graphic on the given object, not necessarily
		a component.
CALLED BY:	ENT_SET_GRAPHIC handlers
PASS:		ss:bp	= SetPropertyArgs
		*ds:dx	= Object to set graphic on
		ds:di	= GadgetInstanceData (needed)
		*ds:si	= Component to add hint to.

RETURN:		nada
DESTROYED:	ax, bx
SIDE EFFECTS:	Incs ref count of new graphic and decs ref count of old
		saved graphic

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	4/ 2/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSetGraphicOnObject	proc	far
		class	GadgetClass

		.enter
		
	;
	; Set es:bx to be the passed in ComponentData
	;
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr	esbx
	;	
	; If the gstring passed in is valid (TYPE_COMPLEX) then store
	; the reference in the property table and update the moniker.
	;
	; This type checking code is leftover from the days of when
	; all set property requests were handled by sending a
	; MSG_ENT_SET_PROPERTY question free.  Now that this is done
	; through byte-compilation, couldn't type checking be table
	; driven inside of EntDispatchSetProperty or in the interpreter?
	;						-martin 6/13/95
	;
	; yes, but it's still necessary at runtime, and
	; a table lookup mechanism would probably be slower --dubois
	;
		cmp	es:[bx].CD_type, LT_TYPE_COMPLEX
		jne	typeError

if _PCV
		
	;
	; Make sure we use the right button regions when drawing
	;
		push	bx, cx
		clr	cx
		mov	ax, HINT_USE_COMPRESSED_INSETS_FOR_MONIKER
		call	ObjVarAddData
		pop	bx, cx
	; rederef object
		Assert	objectPtr, dssi, GadgetClass
		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
endif
setComplexMoniker::
	; Save passed in LegosComplex into instance data
	; FIXME: is this wise?	Why save the complex?  If GetGraphic
	; is called, can just create a gstring and return that..
	;
		mov	ax, es:[bx].CD_data.LD_complex
		call	RunHeapIncRef_asm
		xchg	ds:[di].GI_graphic, ax
		tst	ax		; DecRef old value if non-null
		jz	afterDecRef
		call	RunHeapDecRef_asm

afterDecRef:
		pushdw	esbx			; push ComponentData
		mov	bx, ds:[LMBH_handle]
		pushdw	bxdx			; push component optr
ifdef __HIGHC__
		call	GadgetSetComplexMoniker ; set the complex moniker in C
else
		call	_GadgetSetComplexMoniker ; set the complex moniker in C
endif
		add	sp, 8			; fixup from 2 dword args
		jmp	done_setMoniker

typeError:
		mov	es:[bx].CD_type, LT_TYPE_ERROR
		mov	es:[bx].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
done_setMoniker:
		.leave
		ret
GadgetSetGraphicOnObject	endp
public GadgetSetGraphicOnObject


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGadgetGetGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_GET_GRAPHIC
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= GetPropertyArgs

RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_complex filled in
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	6/13/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGadgetGetGraphic	method dynamic GadgetClass, 
					MSG_GADGET_GET_GRAPHIC
	uses	bx
	.enter
		mov	ax, ds:[di].GI_graphic
		les	bx, ss:[bp].GPA_compDataPtr
		Assert	fptr	esbx
		mov	es:[bx].CD_type, LT_TYPE_COMPLEX
		mov	es:[bx].CD_data.LD_complex, ax
	.leave
	ret
GGadgetGetGraphic	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetLeftTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the component at the specified coordinate

CALLED BY:	MSG_GADGET_SET_LEFT, MSG_GADGET_SET_TOP
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		FIXME
		should check to make sure that "managed" is set on the parent
		group.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSetLeftTop	method dynamic GadgetClass, 
					MSG_GADGET_SET_LEFT,
					MSG_GADGET_SET_TOP
		.enter
		mov	dl, ds:[di].EI_flags
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		mov	cx, ATTR_GEN_POSITION_Y
		cmp	ax, MSG_GADGET_SET_LEFT
		jne	setCommon
		mov	cx, ATTR_GEN_POSITION_X

setCommon:

	; don't use GEN_ADD_GEOMETRY_HINT as it does not use the
	; word of data.
		mov_tr	ax, cx
		mov	cx, size sword
		Assert	chunk	si, ds
		call	ObjVarAddData
		Assert	fptr	dsbx
		mov	ax, es:[di].CD_data.LD_integer
		mov	ds:[bx], ax

	; If its not visible, don't worry about moving visibly.
		test	dl, mask EF_VISIBLE
		jz	done

	;
	; Visibly unbuild and build the object so the new poistion takes
	; effect.
	;
		mov	ax, MSG_ENT_VIS_HIDE
		call	ObjCallInstanceNoLock
		mov	ax, MSG_ENT_VIS_SHOW
		call	ObjCallInstanceNoLock
done:	
		.leave
		Destroy	ax, cx, dx
		ret
GadgetSetLeftTop	endm



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


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/30/95	Initial version
	dloft	7/18/95		Fixed vis positioning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetLeftTop	method dynamic GadgetClass, 
					MSG_GADGET_GET_LEFT,
					MSG_GADGET_GET_TOP
		.enter
if 0
	;
	; First check to see if the position was set, but not updated
	; visually.
	;
		mov	dx, ax			; message
		mov	cx, ATTR_GEN_POSITION_X
		cmp	ax, MSG_GADGET_GET_LEFT
		je	getAttrCommon
		mov	cx, ATTR_GEN_POSITION_Y
getAttrCommon:
		mov_tr	ax, cx			; attr
		call	ObjVarFindData
		jnc	checkVisible
		Assert	fptr	dsbx
		mov	cx, ds:[bx]
		jmp	getCommon

checkVisible:
endif
	;
	; If we're not visible or not built yet or have invalid
	; geometry/image/window, then use the gen hints.
	;
		push	ax		; message
		mov	ax, MSG_ENT_GET_FLAGS
		call	ObjCallInstanceNoLock
		mov	cl, al
		pop	ax		; message
		test	cl, mask EF_VISIBLE
		jz	useAttr
		test	cl, mask EF_BUILT
		jz	useAttr

		push	ax, bp
		mov	ax, MSG_VIS_GET_OPT_FLAGS
		call	ObjCallInstanceNoLock
		pop	ax, bp
		test	cl, VOF_INVALID_BITS
		jz	useVis
useAttr:
	;
	; Get the size from the Gen Hints.  FIXME:  This will return 0 if
	; we're being tiled.  Is that what we want?
	;
		mov	cx, ax
		mov	ax, ATTR_GEN_POSITION_X
		cmp	cx, MSG_GADGET_GET_LEFT
		je	scan
		mov	ax, ATTR_GEN_POSITION_Y
scan:
		mov	cx, 0
		call	ObjVarFindData
		jnc	getCommon
		mov	cx, ds:[bx]
		jmp	getCommon
useVis:
	;
	; If we've got to use the vis position, we must return the value
	; relative to our parent.... sigh.
	; If the parent is a windowed thing, then don't get its
	; position as that we only draw to the nearest window.
	;
	;		push	bp, dx
	; Add margins in here.
		push	bp, ax			; bp, message #
		mov	ax, MSG_VIS_GET_POSITION
		call	ObjCallInstanceNoLock
		push	cx, dx			; save our position
		call	GetParentPosition
		pop	bp, ax			; restore our position
		neg	cx
		neg	dx
		add	cx, bp			; calculate position relative
		add	dx, ax			; to parent
		pop	bp, ax			; bp, message #

		cmp	ax, MSG_GADGET_GET_LEFT
		je	getCommon
		mov_tr	cx, dx
getCommon:
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetGetLeftTop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetParentPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the position of the parent relative to its
		parent or window.  Returns offset of OLGadgetArea for
		forms.

CALLED BY:	GadgetGetLeftTop
PASS:		*ds:si		- object to call parent of
RETURN:		cx, dx		- parents position
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		call gen parent, as some spec UI stuff have weird
		vis parents that are built at run-time. (lists)
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	9/18/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetParentPosition	proc	near
		class	GadgetGeomClass
		uses	di, bx, si, ds
		.enter
	;
	; If the parent is a window, then return its margin
	;
		mov	ax, MSG_GEN_FIND_PARENT
		call	ObjCallInstanceNoLock

		push	si		; original object
		mov	ax, MSG_VIS_GET_TYPE_FLAGS
		movdw	bxsi, cxdx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		test	cl, mask VTF_IS_WIN_GROUP
		jz	getPosition
	;
	; If its a Geom thing, then get the OLGadgetArea position.
		clrdw	cxdx
		call	ObjLockObjBlock
		mov	ds, ax
		mov	ax, segment GadgetGeomClass
		mov	di, offset GadgetGeomClass
		call	ObjIsObjectInClass
		jnc	freeBlock
		
		Assert	objectPtr, dssi, GadgetGeomClass

		mov	di, ds:[si]
		add	di, ds:[di].GadgetGeom_offset
	; Can't assert this as it may not be built out yet.
	; This happens when loading in a file.
		
	;	Assert	objectPtr, ds:[di].GGI_childParent, VisCompClass
		
		mov	si, ds:[di].GGI_childParent.chunk

	;
	; Get position of thing holding us.
	;

		mov	ax, MSG_VIS_GET_POSITION
		call	ObjCallInstanceNoLock
freeBlock:
		call	MemUnlock
		pop	si		; original object
		jmp	done


getPosition:
		pop	si		; original object
	;
	; otherwise, return its position
	;
		mov	ax, MSG_VIS_GET_POSITION
		call	GenCallParent
done:
		.leave
		ret

GetParentPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetWidthHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Size the component as stated

CALLED BY:	MSG_GADGET_SET_WIDTH, MSG_GADGET_SET_HEIGHT
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:
		FIXME
		Setting Fixed Size does not correspond with getting Vis Size
		This needs to be fixed.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	 5/30/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSetWidthHeight	method dynamic GadgetClass, 
					MSG_GADGET_SET_HEIGHT,
					MSG_GADGET_SET_WIDTH
		.enter

	; if its not size as specified, just do nothing
if 0
		push	ax
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		pop	ax
		jnc	done
endif
		
		mov	dl, ds:[di].EI_flags
		push	dx			; save EntFlags
		Assert	fptr	ssbp
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error

		
		mov	bx, es:[di].CD_data.LD_integer
		cmp	bx, 0
		jg	valueOk
		mov	bx, 1
valueOk:
		
		Assert	chunk	si, ds
	;
	; restuff the current unspecified value back in.
	; We have to get the current width and height so we
	; can set it again as we can't set one without the other.
	;
		push	ax, bp, bx

		mov	ax, HINT_FIXED_SIZE
		clr	cx, dx
		call	ObjVarFindData
		jnc	dontAsk

		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock
dontAsk:
		pop	ax, bp, bx

		
		cmp	ax, MSG_GADGET_SET_HEIGHT
		je	setHeight
		mov_tr	cx, bx
		jmp	setCommon
setHeight:
		mov_tr	dx, bx
setCommon:
	; cx - width to set, dx - height to set.
		mov	al, VUM_DELAYED_VIA_APP_QUEUE
		call	GadgetUtilGenSetFixedSize

	; If its not visible, don't worry about moving visibly.

		pop	dx			; EntFlags
		test	dl, mask EF_VISIBLE
		jz	done

	;
	; Visibly unbuild and build the object so the new poistion takes
	; effect.
	;
		mov	ax, MSG_ENT_VIS_HIDE
		call	ObjCallInstanceNoLock
		mov	ax, MSG_ENT_VIS_SHOW
		call	ObjCallInstanceNoLock
		
done:		
		.leave
		Destroy	ax, cx, dx
		ret
error:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done
GadgetSetWidthHeight	endm


;
; Old code for GET_WIDTH/HEIGHT.  Does not raise RTE for
; non-visible, non-fixed-size gadgets.  Returns incorrect values
; for such gadgets. -jmagasin 7/10/96
;
if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetWidthHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the size

CALLED BY:	MSG_GADGET_GET_WIDTH, MSG_GADGET_GET_HEIGHT
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= EntGetPropertyArgs
RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_integer filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	none
		FIXME
		MSG_VIS_GET_SIZE and MSG_GEN_GET_FIXED_SIZE don't return the
		same thing! We need be consistent with return values and
		setting the properties.

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	5/30/95		Initial version
	dloft	4/11/96		Added update win group yuck, misc fiddling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetWidthHeight	method dynamic GadgetClass, 
					MSG_GADGET_GET_WIDTH,
					MSG_GADGET_GET_HEIGHT
		.enter
		sub	ax, MSG_GADGET_GET_WIDTH	; height flag

		push	bp, ax			; frame, height flag
		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock
		call	ZeroOutNonPixelUnits	; zero out anything that's
						; not SST_PIXELS
	;
	; If either gen size is 0 then check the vis size
	;
		jcxz	tryVis
		tst	dx
		jnz	haveRealSize
tryVis:
	;
	; No gen size, so get the vis size after dealing with invalid states.
	;
	; XXX: This is a potentially expensive operation, since we could force
	; the entire win group to update.  Perhaps there's a better way to
	; deal with this?  If this code is disabled, the builder will show 0,0
	; for a newly created component, since they are always sized
	; AS_NEEDED.	dl 4/11/96
	;
		mov	ax, MSG_VIS_GET_OPT_FLAGS
		call	ObjCallInstanceNoLock
		test	cl, VOF_INVALID_BITS
		jz	visSizeOkay

		mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
		mov	dl, VUM_NOW		; ouch!
		call	ObjCallInstanceNoLock
visSizeOkay:		
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock	; cxdx <- vis width, height
	;
	; cx, dx should have width, height
	;
haveRealSize:		
		pop	bp, ax			; frame, height flag
putValueInCX::
	; Make sure cx is the direction requested

		tst	ax			; ax = height flag
		jz	getCommon
		mov_tr	cx, dx		
getCommon:
	; cx - height or width
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
		
		.leave
		Destroy	ax, cx, dx
		ret
GadgetGetWidthHeight	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetCheckLegalWidthHeightRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the width/height of a gadget.  Note that it is
		illegal to ask for the width/height of a non-
		SIZE_AS_SPECIFIED, non-visible component.

CALLED BY:	MSG_GADGET_GET_WIDTH, MSG_GADGET_GET_HEIGHT
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		^fss:bp	= EntGetPropertyArgs
RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_integer filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:
	When we check for fixed-size, we don't look for HINT_SIZE
	_WINDOW_AS_RATIO_OF_PARENT.  Windows (see GadgetWindowGet
	WidthHeight in gdgform.asm) *do* consider this hint equivalent
	to fixed-size.  But windows won't call this method anyway.

	Note that we give bgadget a chance to ignore any error we may
	return so that we can avoid "RTE-27" at buildtime.  It would be
	cleaner to have bgadget intercept get_width/height, call super,
	and filter out errors.  I tried this but sometimes bgadgets
	fail to intercept get_width/height.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetWidthHeight	method dynamic GadgetClass, 
					MSG_GADGET_GET_WIDTH,
					MSG_GADGET_GET_HEIGHT
		.enter
		push	bp
	;
	; If we're fixed-size in the requested axis, then return
	; our size along that axis.  We assume 0 is not a legal
	; size for any gadget.  (See side effects.)
	;
		mov_tr	bx, ax				; save msg
		mov	ax, MSG_GEN_GET_FIXED_SIZE
		call	ObjCallInstanceNoLock		; cx/dx = w/h
		call	ZeroOutNonPixelUnits		; zero out anything
							; that's not SST_PIXELS
		cmp	bx, MSG_GADGET_GET_HEIGHT
		jne	checkWidth
		tst	dx
		jz	checkVisibility			; don't have height
		mov_tr	cx, dx
checkWidth:
		jcxz	checkVisibility			; don't have width

	;
	; We've got the desired size in cx.  Return it.
	;
		pop	bp
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
exit:
		.leave
		Destroy	ax, cx, dx
		ret

	;
	; We're not fixed-size along the requested axis.  If we're
	; visible, then we can still satisfy the request....or raise
	; an error if not.
	;
checkVisibility:
		pop	bp				; get params
		call	GadgetCheckVisibleBeforeGettingSize
		jmp	exit
GadgetGetWidthHeight	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetCheckVisibleBeforeGettingSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the visibility of a gadget before getting
		its size.  Called when we already know that the
		gadget is not fixed-size.  Carry tells the caller
		whether or not to raise an error.*

CALLED BY:	
PASS:		*ds:si	- gadget
		bx	- MSG_GADGET_GET_WIDTH/HEIGHT
		ss:bp	- GetPropertyArgs
RETURN:		GetPropertyArgs filled in
DESTROYED:	ax, dx, es, di, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		* At build-time, we don't want to raise errors
		  for width/height requests of non-visible gadgets.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetCheckVisibleBeforeGettingSize	proc	far
		.enter
	;
	; If we're visible, then we can get our size.
	;
		push	bp				; Save params.
		mov	ax, MSG_VIS_GET_ATTRS
		call	ObjCallInstanceNoLock
		test	cl, mask VA_REALIZED
		jnz	getSize

	; force update NOW so we can get the info we need
		mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
		mov	dl, VUM_NOW		; ouch!
		call	ObjCallInstanceNoLock

	; if we are still not visible, then throw up our hands in resignation
	; we concede this battle to the GEOS UI, but the war is far from over
	; (most likely the component is not supposed to be visible)
		mov	ax, MSG_VIS_GET_ATTRS
		call	ObjCallInstanceNoLock
		test	cl, mask VA_REALIZED
		jz	error
		
getSize:
		call	GadgetGetSizeOfGadget		; cx/dx = w/h
		cmp	bx, MSG_GADGET_GET_WIDTH
		je	gotSize
		mov_tr	cx, dx
gotSize:
		pop	bp				; Restore params.
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		mov	es:[di].CD_data.LD_integer, cx
exit:
		.leave
		Destroy	ax, dx, di, cx
		ret

	;
	; We're non-visible and non-fixed-size.  Raise a RTE
	; unless we really don't want to (i.e., bgadget at
	; buildtime - see side effects).
	;
error:
		mov	ax, MSG_GADGET_PREVENT_ERROR_ON_GET_WIDTH_HEIGHT
		call	ObjCallInstanceNoLock	   ; if no handler, cf=0
		jc	getSize			   ; Get size anyway
						   ; (for bgadget).
		pop	bp			   ; Restore params.
		Assert	fptr	ssbp
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_SPECIFIC_PROPERTY_ERROR
		jmp	exit
GadgetCheckVisibleBeforeGettingSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetSizeOfGadget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Helper routine for GadgetGetWidthHeigth.  Gets the
		size of a visible, non-fixed-size gadget.

CALLED BY:	GadgetCheckVisibleBeforeGettingSize only
PASS:		*ds:si	- gadget object
RETURN:		cx	- width
		dx	- height
DESTROYED:	ax, bp
SIDE EFFECTS:
   This is a potentially expensive operation, since we could force
   the entire win group to update.  Perhaps there's a better way to
   deal with this?  If this code is disabled, the builder will show 0,0
   for a newly created component, since they are always sized
   AS_NEEDED.	dl 4/11/96


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 7/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetSizeOfGadget	proc	near
		.enter

		mov	ax, MSG_VIS_GET_OPT_FLAGS
		call	ObjCallInstanceNoLock
		test	cl, VOF_INVALID_BITS
		jz	visSizeOkay

		mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
		mov	dl, VUM_NOW		; ouch!
		call	ObjCallInstanceNoLock
visSizeOkay:		
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock	; cxdx <- vis width, height

		.leave
		Destroy	ax, bp
		ret
GadgetGetSizeOfGadget	endp



MakeSystemPropRoutines Gadget, gadget
		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetSizeControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set size(H,V)Control properties

CALLED BY:	MSG_GADGET_SET_SIZE_VCONTROL, HCONTROL
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSetSizeHControl	method dynamic GadgetClass, 
					MSG_GADGET_SET_SIZE_HCONTROL
		.enter

		mov	ax, HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
		call	ObjVarDeleteData
		mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		call	ObjVarDeleteData
		
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	bx, es:[di].CD_data.LD_integer

		cmp	bx, GSCT_AS_SPECIFIED
		jb	badValue
		cmp	bx, GSCT_AS_NEEDED
		ja	badValue

		cmp	bx, GSCT_AS_SPECIFIED
		jne	clearFixed
	;
	; Make sure the current fixed size exists and is not 0.
	; It can be 0 if there are other size hints for that direction.
	; We can assume that if the width is already set, then the height
	; is also set in the FIXED size or on a hint. If there was alread
	; a Fixed Size hint before we go here and the width is 0, then
	; don't set it to a fixed size, it probably is AS_NEEDED
	;
		clr	di			; FIXED before
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jc	found
		inc	di			; not FIXED before
		mov	cx, size GadgetSizeHintArgs
		call	ObjVarAddData
found:
		cmp	ds:[bx].GSHA_width, 0
		jne	done
	; we know that if the width is 0, it is not set as there are not
	; other width hints (becuase we are in the width handler)
		mov	ax, MSG_VIS_GET_ATTRS
		call	ObjCallInstanceNoLock
		test	cl, mask VA_REALIZED
		mov	cx, 0
		mov	dx, cx
		jz	gotSize
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
gotSize:
		mov	ds:[bx].GSHA_width, cx
		cmp	di, 0
		je	done			; if FIXED before, don't change
		mov	cx, bx			; cx <- ptr to ExtraData
	; We need to check to see if there are height hints or if we
	; should set the height to the VisSize
	;
		cmp	ds:[bx].GSHA_height, 0
		jne	done
		mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
		call	ObjVarFindData
		jc	done
		mov	ax, HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
		call	ObjVarFindData
		jc	done
		mov	bx, cx			; ptr to ExtraData
		mov	ds:[bx].GSHA_height, dx	; store height in Fixed Size
		jmp	done
		
clearFixed:
	;
	; If there is a FIXED_SIZE hint (because of height) then
	; clear the height part as we are adding a different sizing width.

		mov	cx, bx			; value
		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		call	ObjVarFindData
		jc	clearCommon
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jnc	noFixed
clearCommon:
		CheckHack <GSHA_width eq SWSP_x>
		mov	ds:[bx].GSHA_width, 0	; clear SpecWidth...
		
noFixed:
		mov_tr	bx, cx			; value
		clr	cx
		mov	ax, HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
		mov	dx, HINT_EXPAND_WIDTH_TO_FIT_PARENT

		jmp	checkSizeHints
done:
		.leave
		ret
badValue:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done		
GadgetSetSizeHControl	endm

GadgetSetSizeVControl	method dynamic GadgetClass, 
					MSG_GADGET_SET_SIZE_VCONTROL
		.enter


		mov	ax, HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
		call	ObjVarDeleteData
		mov	ax, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
		call	ObjVarDeleteData
		
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	bx, es:[di].CD_data.LD_integer
		cmp	bx, GSCT_AS_SPECIFIED
		jb	badValue
		cmp	bx, GSCT_AS_NEEDED
		ja	badValue

		cmp	bx, GSCT_AS_SPECIFIED
		jne	clearFixed
	;
	; Make sure the current fixed size exists and is not 0.
	; It can be 0 if there are other size hints for that direction.
	; We can assume that if the height is already set, then the width
	; is also set in the FIXED size or on a hint.  If there was already
	; a Fixed Size hint before we got here and the width is 0, then
	; don't set it to a fixed size, it probablys is AS_NEEDED
	;
		clr	di			;  FIXED before
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jc	found
		inc	di			; di <- 1, not fixed before
		call	ObjVarAddData
		mov	cx, size GadgetSizeHintArgs
		call	ObjVarAddData
found:
		cmp	ds:[bx].GSHA_height, 0
		jne	done
	; we know that if the height is 0, it is not set as there are not
	; other height hints (becuase we are in the height handler)
		mov	ax, MSG_VIS_GET_ATTRS
		call	ObjCallInstanceNoLock
		test	cl, mask VA_REALIZED
		mov	dx, 0
		mov	cx, dx
		jz	gotSize
		
		mov	ax, MSG_VIS_GET_SIZE
		call	ObjCallInstanceNoLock
gotSize:
		mov	ds:[bx].GSHA_height, dx
		cmp	di, 0
		je	done			; if FIXED before, don't change
		mov	dx, bx			; dx <- ptr to ExtraData
	; We need to check to see if there are width hints or if we
	; should set the width to the VisSize
	;
		cmp	ds:[bx].GSHA_width, 0
		jne	done
		mov	ax, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		call	ObjVarFindData
		jc	done
		mov	ax, HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
		call	ObjVarFindData
		jc	done
		mov	bx, dx			; ptr to ExtraData
		mov	ds:[bx].GSHA_width, cx	; store height in Fixed Size
		jmp	done
		
clearFixed:

	;
	; If there is a FIXED_SIZE hint (because of width) then
	; clear the height part as we are adding a different sizing hint.
		push	bx
		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		call	ObjVarFindData
		jc	clearCommon
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jnc	noFixed
clearCommon:
		CheckHack <GSHA_height eq SWSP_y>
		mov	ds:[bx].GSHA_height, 0	; clear SpecHeight
noFixed:
		pop	bx
		clr	cx
		mov	ax, HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
		mov	dx, HINT_EXPAND_HEIGHT_TO_FIT_PARENT

checkSizeHints label near		
		cmp	bx, GSCT_AS_SMALL_AS_POSSIBLE
		je	doAdd
		cmp	bx, GSCT_AS_BIG_AS_POSSIBLE
		jne	done			; size as needed -- we're
						; done!
		mov_tr	ax, dx			; swap hints
doAdd:
	;
	; If you set fixed size, then set the fixed size data
	; to the vis size unless there is a hint in that direction.
		call	ObjVarAddData
done:		
		.leave
		ret
badValue:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done		
GadgetSetSizeVControl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetSizeControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return our H or V Size Control property

CALLED BY:	MSG_GADGET_GET_SIZE_CONTROL
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/10/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetSizeHControl	method dynamic GadgetClass, 
					MSG_GADGET_GET_SIZE_HCONTROL
		.enter

		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER

		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		call	ObjVarFindData
		jc	fixed
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jnc	testOthers
	CheckHack <GSHA_width eq SWSP_x>
fixed:
		tst	ds:[bx].GSHA_width	; check SpecWidth
		jnz	haveSpecified
	;
	; SpecHeight is 0, so we're not AS_SPECIFIED.  Check others.
	;
testOthers:
		mov	cx, HINT_EXPAND_WIDTH_TO_FIT_PARENT
		mov	dx, HINT_NO_WIDER_THAN_CHILDREN_REQUIRE
		call	GadgetGetSizeControl
done:
		.leave
		ret
haveSpecified:
		mov	es:[di].CD_data.LD_integer, GSCT_AS_SPECIFIED
		jmp	done

GadgetGetSizeHControl	endm

GadgetGetSizeVControl	method dynamic GadgetClass, 
					MSG_GADGET_GET_SIZE_VCONTROL
		.enter

		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER

		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT
		call	ObjVarFindData
		jc	fixed
		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jnc	testOthers
	CheckHack <GSHA_height eq SWSP_y>
fixed:
		tst	ds:[bx].GSHA_height	; check SpecHeight
		jnz	haveSpecified
	;
	; SpecHeight is 0, so we're not AS_SPECIFIED.  Check others.
	;
testOthers:
		mov	cx, HINT_EXPAND_HEIGHT_TO_FIT_PARENT
		mov	dx, HINT_NO_TALLER_THAN_CHILDREN_REQUIRE
		call	GadgetGetSizeControl
done:
		.leave
		ret
haveSpecified:
		mov	es:[di].CD_data.LD_integer, GSCT_AS_SPECIFIED
		jmp	done

GadgetGetSizeVControl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetSizeControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check hints, return size control property value.  Assumes
		AS_SPECIFIED has already been tested.

CALLED BY:	GadgetGetSize(H,V)Control
PASS:		es:di - ComponentData (type should be filled in already)
		cx - big as possible hint
		dx - small as possible hint
RETURN:		es:di.CD_data.LD_integer filled in
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	 8/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetSizeControl	proc	near
		.enter
		CheckHack	<GSCT_AS_SPECIFIED eq 0>
		CheckHack	<GSCT_AS_SMALL_AS_POSSIBLE eq 1>
		CheckHack	<GSCT_AS_BIG_AS_POSSIBLE eq 2>
		CheckHack	<GSCT_AS_NEEDED eq 3>

		push	cx			; big hint
		mov	cx, 1			; as specified		
		
		mov_tr	ax, dx			; small hint
		call	ObjVarFindData
		jc	donePop

		pop	ax			; big hint
		inc	cx
		call	ObjVarFindData
		jc	done

		inc	cx
		jmp	done
donePop:
		pop	ax			; pop small hint
done:
		mov	es:[di].CD_data.LD_integer, cx
		
		.leave
		ret
GadgetGetSizeControl	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GGadgetGetSetLook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GADGET_[GET|SET]_LOOK
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es 	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GGadgetGetSetLook	method dynamic GadgetClass, 
					MSG_GADGET_GET_LOOK,
					MSG_GADGET_SET_LOOK
		.enter
		les	di, ss:[bp].SPA_compDataPtr
		Assert	fptr	esdi
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		cmp	ax, MSG_GADGET_GET_LOOK
		je	getLook

		cmp	es:[di].CD_type, LT_TYPE_INTEGER
		jne	error
		
		mov	cx, es:[di].CD_data.LD_integer
ifdef DO_DBCS		
		mov	ax, MSG_SPEC_SET_LEGOS_LOOK
		push	cx
		call	ObjCallInstanceNoLock
		pop	cx
endif
		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
		mov	ds:[di].GI_look, cl
done:
		.leave
		ret
getLook:
		push	di
		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
		mov	cl, ds:[di].GI_look
		pop	di
		mov	es:[di].CD_type, LT_TYPE_INTEGER
		clr	ch
		mov	es:[di].CD_data.LD_integer, cx
		jmp	done
error:
		mov	es:[di].CD_type, LT_TYPE_ERROR
		mov	es:[di].CD_data.LD_error, CPE_PROPERTY_TYPE_MISMATCH
		jmp	done	
GGadgetGetSetLook	endm
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSpecGetExtraSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure there isn't extra space around stuff.

CALLED BY:	MSG_SPEC_GET_EXTRA_SIZE
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es 	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	8/29/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSpecGetExtraSize	method dynamic GadgetClass, 
					MSG_SPEC_GET_EXTRA_SIZE
		.enter
		clrdw	cxdx
		.leave
		ret
GadgetSpecGetExtraSize	endm

		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up look before building out

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es 	= segment of GadgetClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/ 9/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSpecBuild	method dynamic GadgetClass, 
					MSG_SPEC_BUILD
		uses	ax, cx, dx, bp
		.enter
		mov	cl, ds:[di].GI_look
		clr	ch
		jcxz	afterLookSet
ifdef DO_DBCS
		push	di
		mov	di, offset GadgetFormClass
		call	ObjIsObjectInClass
		pop	di
		jc	afterLookSet
		push	bp
		mov	ax, MSG_SPEC_SET_LEGOS_LOOK
		call	ObjCallInstanceNoLock
		pop	bp
endif
afterLookSet:
		mov	ax, MSG_SPEC_BUILD
		mov	di, offset GadgetClass
		call	ObjCallSuperNoLock
done::
		
		.leave
		ret
GadgetSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZeroOutNonPixelUnits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check the passed-in spec sizes and zero out any that aren't
		SST_PIXELS.

CALLED BY:	internal
PASS:		cx = SpecWidth
		dx = SpecHeight
RETURN:		same as passed, though one or the other may be 0
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	9/28/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ZeroOutNonPixelUnits	proc	near
	uses	ax
		.enter

		mov	ax, cx
		andnf	cx, mask SSS_TYPE
		cmp	cx, SpecSizeSpec <SST_PIXELS, 0>
		mov	cx, 0
		jne	checkDX

		mov_tr	cx, ax
checkDX:
		mov	ax, dx
		andnf	dx, mask SSS_TYPE
		cmp	dx, SpecSizeSpec <SST_PIXELS, 0>
		mov	dx, 0
		jne	done

		mov_tr	dx, ax
done:
		.leave
		ret
ZeroOutNonPixelUnits	endp

		
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GEntDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	kill of graphic if there is one

CALLED BY:	MSG_ENT_DESTROY
PASS:		*ds:si	= GadgetPictureClass object
		ds:di	= GadgetPictureClass instance data
		ds:bx	= GadgetPictureClass object (same as *ds:si)
		es 	= segment of GadgetPictureClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/22/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GEntDestroy	method dynamic GadgetClass, MSG_ENT_DESTROY
	uses	ax, cx, dx, bp
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].Gadget_offset
		mov	ax, ds:[di].GI_graphic
		tst	ax
		jz	callSuper
	; dec ref the graphic so it can be freed eventually
		call	RunHeapDecRef_asm
callSuper:
		mov	ax, MSG_ENT_DESTROY
		mov	di, offset GadgetClass
		call	ObjCallSuperNoLock
		.leave
		ret
GEntDestroy	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Code for the clipboardable API follows.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetInitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableEntInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a clipboardable:
		o Set its focusable property to 1.
		o Make it GA_TARGETABLE.  This will not ensure that it
		  gets the target.  If the clipboardable property is
		  set to 1, then the clipboardable may get the target.
		(see META_MUP_ALTER_FTVMC_EXCL below).

CALLED BY:	MSG_ENT_INITIALIZE
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		cx:dx	= fptr.RunHeapInfo
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableEntInitialize method dynamic GadgetClipboardableClass, 
					MSG_ENT_INITIALIZE
		.enter

	;
	; Set .focusable to 1.  (We default to being focusable.)
	;
		BitSet	ds:[di].GCLI_flags, CF_focusable

	;
	; Let superclass do its thing.
	;
		mov	di, offset GadgetClipboardableClass
		call	ObjCallSuperNoLock

	;
	; Make ourself targetable.
	;
		mov	ax, MSG_GEN_SET_ATTRS
		mov	cl, mask GA_TARGETABLE	; attrs to set
		clr	ch			; attrs to clear
		call	ObjCallInstanceNoLock
		
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetClipboardableEntInitialize	endm

GadgetInitCode	ends


GadgetClipboardableCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableFocusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise a "focusChanged" event if we've gained the focus
		or target.

CALLED BY:	MSG_META_[GAINED|LOST]_FOCUS_EXCL
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 2/28/96	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
focusString	TCHAR	"focusChanged", C_NULL
GadgetClipboardableFocusChanged	method dynamic GadgetClipboardableClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL,
					MSG_META_LOST_SYS_FOCUS_EXCL,
					MSG_META_GAINED_SYS_TARGET_EXCL,
					MSG_META_LOST_SYS_TARGET_EXCL
			
params		local	EntHandleEventStruct
		.enter
	;
	; Save message.  Might need to tell clipboard our status.
	;
		push	ax
	;
	; Save old clipboardable focusState.
	;
		mov	bx, ds:[di].GCLI_flags
		GetClipboardableFocusState	bx
		push	bx				; Save old state.
	;
	; Update our CF_hasFocus or CF_hasTarget flag.
	;
		mov	bx, mask CF_hasTarget
		cmp	ax, MSG_META_GAINED_SYS_TARGET_EXCL
		je	setState
		cmp	ax, MSG_META_LOST_SYS_TARGET_EXCL
		je	setState
		mov	bx, mask CF_hasFocus		; Gained/lost focus
setState:
EC <		call	ECCheckClipboardableFlagsOnFocusChange		>
		xor	ds:[di].GCLI_flags, bx		; Toggle the flag.
		mov	bx, ds:[di].GCLI_flags		; Current state.

	;
	; Let the system do its thing.
	;
		push	bp
		mov	di, offset GadgetClipboardableClass
		call	ObjCallSuperNoLock
		pop	bp
	;
	; Only make an event if our focus state changed.  We only care
	; if the enum value changed.  E.g., it doesn't matter if we lost
	; the target but still have the focus - still CFS_FULL.
	;
		mov	ax, bx
		GetClipboardableFocusState	ax
		pop	bx				; Fetch old state.
		cmp	ax, bx
		je	afterEvent
	;
	; Make event.
	;
		mov	ax, offset focusString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 1
		clr	di
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_INTEGER
		mov	ss:[params].EHES_argv[di].CD_data.LD_integer, bx
		
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock
	;
	; o If we've gained the focus, we might need to try and gain
	;   the target.
	; o If we've gained the target, raise a paste event so that
	;   our state can be updated.  Then notify the clipboard
	;   components of our state.
	;
afterEvent:
		pop	ax				; passed msg
		call	HandleFocusOrTargetGain

		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetClipboardableFocusChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleFocusOrTargetGain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gaining the focus/target requires special handling.
		o If we gain the focus and we're clipboardable, we should
		  try and gain the target.
		o We must tell the clipboard components our state.

CALLED BY:	GadgetClipboardableFocusChanged *only*
PASS:		ax	- message passed to GadgetClipboardableFocusChanged
		*ds:si	- GadgetClipboardableClass instance
		ds:di	- GadgetClipboardableClass instance data
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/15/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleFocusOrTargetGain	proc	near
		class	GadgetClipboardableClass
		.enter

	;
	; o If we've gained the focus, we might need to try and gain
	;   the target.
	; o If we've gained the target, raise a paste event so that
	;   our state can be updated.  Then notify the clipboard
	;   components of our state.
	;
		cmp	ax, MSG_META_GAINED_SYS_FOCUS_EXCL
		je	considerGrabbingTarget
		cmp	ax, MSG_META_GAINED_SYS_TARGET_EXCL
		jne	done
		call	RaiseAcceptPasteIfNotInAcceptPasteHandler
notifyClipboardComponents:		
		mov	ax, MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
		call	ObjCallInstanceNoLock
done:		
		.leave
		Destroy	ax, bx, cx, dx, di
		ret
	;
	; We've gained the focus.  If clipboardable=1, then we should
	; grab the target if we don't already have it.  If clipboardable=0,
	; then we should notify the clipboard components of our state now
	; (instead of waiting until after we've gained the target, since
	; we won't gain the target).
	;
considerGrabbingTarget:
		mov	di, ds:[si]
		add	di, ds:[di].GadgetClipboardable_offset
		mov	ax, ds:[di].GCLI_flags
		test	ax, mask CF_hasTarget
		jnz	done				; already have target
		test	ax, mask CF_clipboardable
		jz	notifyClipboardComponents	; not clipboardable
		mov	ax, MSG_META_GRAB_TARGET_EXCL
		mov	bx, ds:[LMBH_handle]
		call	GadgetUtilSetSysFocusTargetCommon
		jmp	done
HandleFocusOrTargetGain	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableGetFocusable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the focusable bit out of GCLI_flags.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_GET_FOCUSABLE,
		MSG_GADGET_CLIPBOARDABLE_GET_CLIPBOARDABLE,
		MSG_GADGET_CLIPBOARDABLE_GET_DELETABLE,
		MSG_GADGET_CLIPBOARDABLE_GET_COPYABLE
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		filled in GetPropertyArgs' *GPA_compDataPtr
DESTROYED:	ax, cx, dx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 2/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableGetFocusable	method dynamic GadgetClipboardableClass,
				MSG_GADGET_CLIPBOARDABLE_GET_FOCUSABLE,
				MSG_GADGET_CLIPBOARDABLE_GET_CLIPBOARDABLE,
				MSG_GADGET_CLIPBOARDABLE_GET_DELETABLE,
				MSG_GADGET_CLIPBOARDABLE_GET_COPYABLE

		.enter
	;
	; Get mask for the bit we want.  Note that bit order corresponds
	; to property message order.  (See CheckHacks in gadget.def.)
	;
		sub	ax, MSG_GADGET_CLIPBOARDABLE_GET_FOCUSABLE
		Assert	bitClear al, 0			; Better be even
		shr	al				; Get/Set pairs.
		inc	al				; Add 2 for hasFocus
		inc	al				; and hasTarget.
		mov_tr	cl, al
		mov	ax, 1
		shl	ax, cl				; ax has our mask.
	;
	; Get the flag out of our instance data.
	;
		les	bx, ss:[bp].GPA_compDataPtr
		Assert	fptr, esbx
		clr	dx
		test	ds:[di].GCLI_flags, ax
		jz	storeResult
		mov	dl, 1
storeResult:		
		mov	es:[bx].CD_data.LD_integer, dx
		mov	es:[bx].CD_type, LT_TYPE_INTEGER

		.leave
		Destroy	ax, cx, dx
		ret
GadgetClipboardableGetFocusable	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableSetFocusable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our focusable bit (in GCLI_flags) to 0 or 1.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_SET_FOCUSABLE
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		filled in SetPropertyArgs' *SPA_compDataPtr 
DESTROYED:	ax, cx, dx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:
		After changing the focusability, we release
		the focus/target if necessary.
		Note that we're only releasing the focus/target exclusive
		at our level.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableSetFocusable	method dynamic GadgetClipboardableClass, 
					MSG_GADGET_CLIPBOARDABLE_SET_FOCUSABLE
	uses	bp
		.enter
	;
	; Set ourself focusable or not focusable.
	; Actually, not-focusable is set at label releaseFocus (below).
	;
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr, esbx
		mov	cx, es:[bx].CD_data.LD_integer
		mov	bx, ds:[di].GCLI_flags
		jcxz	releaseFocus
		BitSet	bx, CF_focusable
		mov	ds:[di].GCLI_flags, bx

done:
		.leave
		Destroy	ax, cx, dx
		ret
		
	;
	; Set ourself not-focusable.  If we've got the focus and/or
	; target, update the state of any clipboards.  Also, release
	; it/them because non-focusable clipboardables never get system
	; focus nor do they take part in clipboard operations.
	;
releaseFocus:
		BitClr	bx, CF_focusable
		mov	ds:[di].GCLI_flags, bx	; Must do prior to META calls.
		
		test	bx, mask CF_hasFocus or mask CF_hasTarget
		jz	done			; no jump -> have one or both

		mov	ax, MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
		call	ObjCallInstanceNoLock
		
		test	bx, mask CF_hasFocus
		jz	releaseTarget
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		call	ObjCallInstanceNoLock

		test	bx, mask CF_hasTarget
		jz	done
releaseTarget:
		mov	ax, MSG_META_RELEASE_TARGET_EXCL
		call	ObjCallInstanceNoLock
		jmp	done
GadgetClipboardableSetFocusable	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableGetFocusState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the focus state out of GCLI_flags.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_GET_FOCUS_STATE
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		ss:bp	= GetPropertyArgs
RETURN:		filled in GetPropertyArgs' GPA_compDataPtr
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 2/28/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableGetFocusState  method dynamic GadgetClipboardableClass, 
				  MSG_GADGET_CLIPBOARDABLE_GET_FOCUS_STATE
		.enter

		mov	ax, ds:[di].GCLI_flags
		GetClipboardableFocusState	ax
		Assert	urange ax, CFS_NONE, CFS_FULL 
		les	di, ss:[bp].GPA_compDataPtr
		Assert	fptr, esdi
		mov	es:[di].CD_data.LD_integer, ax
		mov	es:[di].CD_type, LT_TYPE_INTEGER

		.leave
		Destroy	ax, cx, dx
		ret
GadgetClipboardableGetFocusState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableSetFocusState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an error, since this is a read-only property.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_SET_FOCUS_STATE
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		CPE_READONLY_PROPERTY error in SetPropertyArgs
DESTROYED:	ax, cx, dx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableSetFocusState  method dynamic GadgetClipboardableClass, 
				  MSG_GADGET_CLIPBOARDABLE_SET_FOCUS_STATE
		.enter

		mov	ax, CPE_READONLY_PROPERTY
		call	GadgetUtilReturnSetPropError

		.leave
		Destroy	ax, cx, dx
		ret
GadgetClipboardableSetFocusState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableSpecNavigationQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Depending on whether we're focusable, accept/reject
		an attempt to make us the focus.

CALLED BY:	MSG_SPEC_NAVIGATION_QUERY
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		(below copied from visC.def)
		^lcx:dx	= object which originated this query
		bp	= NavigateFlags
RETURN:		carry set if object to give focus to, with:
			^lcx:dx = object which is replying
		else
			^lcx:dx	= next object to query
		bp	= NavigateFlags
		al	= set if object is focusable via backtracking
DESTROYED:	nothing (ax,cx,dx,bp are return values)
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableSpecNavigationQuery	method dynamic GadgetClipboardableClass, 
					MSG_SPEC_NAVIGATION_QUERY
		.enter
	;
	; If we're already supposed to skip this node, do it.
	;
		test	bp, mask NF_SKIP_NODE
		jnz	callSuperclass
	;
	; Check if we're focusable.  If not, skip this node.
	;
		or	bp, mask NF_SKIP_NODE	; Assume not focusable.
		test	ds:[di].GCLI_flags, mask CF_focusable
		jz	callSuperclass
	;
	; We're focusable, so allow self to grab the focus.
	;
		and	bp, not mask NF_SKIP_NODE
		mov	cx, ds:LMBH_handle
		mov	dx, si
		stc

		.leave
		ret

callSuperclass:
		mov	di, offset GadgetClipboardableClass
		call	ObjCallSuperNoLock

		.leave
		ret
GadgetClipboardableSpecNavigationQuery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableMetaMupAlterFtvmcExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow ourself to become the focus/target only if we're
		focusable.
		Allow ourself to become the target only if we're
		clipboardable

CALLED BY:	MSG_META_MUP_ALTER_FTVMC_EXCL
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		^lcx:dx	= object wishing to grab/release exclusive(s)
		bp	= MetaAlterFTVMCExclFlags
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:
	Note that a clipboardable component with CF_clipboardable=0
	will have its GA_TARGETABLE GenAttr set.  So it might *almost*
	become the target...until this routine checks CF_clipboardable.
	We don't set/unset GA_TARGETABLE when the Legos programmer
	changes a component's clipboardability because GenAttr changes
	require that the component be unusable.  We don't want to toggle
	usability to fiddle with GA_TARGETABLE - we'd get flicker as the
	component were unbuilt/built.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableMetaMupAlterFtvmcExcl method dynamic GadgetClipboardableClass, 
					MSG_META_MUP_ALTER_FTVMC_EXCL
		.enter
	;
	; If this is a release, call superclass.  If this is a focus
	; or target grab, do special stuff.
	;
		test	bp, mask MAEF_GRAB
		jz	callSuperClass		; some kind of release
		test	bp, mask MAEF_FOCUS
		jnz	handleFocusGrab
		test	bp, mask MAEF_TARGET
		jnz	handleTargetGrab
callSuperClass:
		mov	di, offset GadgetClipboardableClass
		call	ObjCallSuperNoLock
		.leave
		Destroy	ax, cx, dx, bp
		ret

	;
	; If we're focusable, grab the focus via superclass call.
	;	
handleFocusGrab:
		test	ds:[di].GCLI_flags, mask CF_focusable
		jz	skipThisGrab
		jmp	callSuperClass

	;
	; If we're not focusable or not clipboardable, then
	; don't grab the target.
	;
handleTargetGrab:
		mov	bx, ds:[di].GCLI_flags
		and	bx, mask CF_clipboardable or mask CF_focusable
		xor	bx, mask CF_clipboardable or mask CF_focusable
		jnz	skipThisGrab
		jmp	callSuperClass

	;
	; Skip the grab.  Might not even call superclass.
	;
skipThisGrab:
		and	bp, not (mask MAEF_FOCUS or mask MAEF_TARGET)
		test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
		jnz	callSuperClass
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetClipboardableMetaMupAlterFtvmcExcl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableSetClipboardable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow or disallow clipboard operations.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_SET_CLIPBOARDABLE
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 2/28/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableSetClipboardable method dynamic GadgetClipboardableClass, 
				MSG_GADGET_CLIPBOARDABLE_SET_CLIPBOARDABLE
	uses	bp
		.enter

	;
	; Set ourself clipboardable or non-clipboardable.
	; Actually, non-clipboardable is set at label
	; releaseTarget (below).
	;
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr, esbx
		mov	cx, es:[bx].CD_data.LD_integer
		mov	bx, ds:[di].GCLI_flags
		jcxz	releaseTarget
	;
	; We're being set clipboardable.  If we have the focus, and
	; we don't have the target, then grab the target now because
	; we won't receive GAINED_SYS_FOCUS_EXCL (where we usually
	; grab the target).
	;
		BitSet	bx, CF_clipboardable
		mov	ds:[di].GCLI_flags, bx	; Need flag set for META call.
		
		test	bx, mask CF_hasFocus
		jz	done			; Don't have focus.
		test	bx, mask CF_hasTarget
		jnz	done			; Already have the target.

		mov	ax, MSG_META_GRAB_TARGET_EXCL
		mov	bx, ds:[LMBH_handle]
		call	GadgetUtilSetSysFocusTargetCommon

done:
		.leave
		Destroy	ax, cx, dx
		ret
		
	;
	; Set self as not clipboardable.  If we've got the target,
	; then update the clipboard components and release it.
	;
releaseTarget:
		BitClr	bx, CF_clipboardable
		mov	ds:[di].GCLI_flags, bx	; Need flag clr for META call.

		test	bx, mask CF_hasTarget
		jz	done
		mov	ax, MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
		call	ObjCallInstanceNoLock
		mov	ax, MSG_META_RELEASE_TARGET_EXCL
		call	ObjCallInstanceNoLock
		jmp	done

GadgetClipboardableSetClipboardable	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableSetDeletable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow or disallow deletion/copyability.
		If deletability is being changed on the active selection,
		raise an acceptPaste.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_SET_DELETABLE
		MSG_GADGET_CLIPBOARDABLE_SET_COPYABLE
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		nothing
DESTROYED:	ax,cx,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 2/28/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableSetDeletable	method dynamic GadgetClipboardableClass,
					MSG_GADGET_CLIPBOARDABLE_SET_COPYABLE,
					MSG_GADGET_CLIPBOARDABLE_SET_DELETABLE

	uses	bp
		.enter
	;
	; Get mask of the flag we want to change.
	;
		mov	dx, mask CF_copyable
		cmp	ax, MSG_GADGET_CLIPBOARDABLE_SET_COPYABLE
		je	changeFlag
		mov	dx, mask CF_deletable
	;
	; Change the flag if necessary.
	;
changeFlag:
		les	bx, ss:[bp].SPA_compDataPtr
		Assert	fptr, esbx
		mov	cx, es:[bx].CD_data.LD_integer
		mov	bx, ds:[di].GCLI_flags		; bx <- current flag
		jcxz	clearProperty
		test	bx, dx				; Already set?
		jnz	done
		or	bx, dx				; Nope. Do it now.
		jmp	updateState
		
clearProperty:
		test	bx, dx				; Already clear?
		jz	done
		not	dx
		and	bx, dx				; Nope. Do it now.

updateState:
		mov	ds:[di].GCLI_flags, bx		; Update state.

	;
	; Raise an acceptPaste and notify the clipboards if we are
	; the active selection (i.e., we have the target).
	;
		test	bx, mask CF_hasTarget
		jz	done
		cmp	ax, MSG_GADGET_CLIPBOARDABLE_SET_DELETABLE
		jne	notifyClipboards
		call	RaiseAcceptPasteIfNotInAcceptPasteHandler
		
notifyClipboards:
		mov	ax, MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
		call	ObjCallInstanceNoLock
done:
		.leave
		Destroy	ax, cx, dx
		ret
GadgetClipboardableSetDeletable	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RaiseAcceptPasteIfNotInAcceptPasteHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise an acceptPaste only if we're not currently
		in an acceptPaste handler.

		Explanation: A Legos acceptPaste handler could generate
		more acceptPastes by doing the following:
		 1. Setting the deletable property (infinite - well,
		    actually crash when run out of stack space).
		 2. Changing the system focus (not really infinite).
		 3. Setting the clipboard item (might be infinite - I
		    haven't tried this).


CALLED BY:	GadgetClipboardableSeteDeletable,
		GadgetClipboardableFocusChanged
		GadgetClipboardableClipboardItemChanged
PASS:		*ds:si	- clipboardable object
RETURN:		nothing
DESTROYED:	ax,cx,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 7/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RaiseAcceptPasteIfNotInAcceptPasteHandler	proc	near
	uses	bx
		.enter
	;
	; Do we have the magic vardata?
	;
		mov	ax, HINT_CLIPBOARDABLE_IN_ACCEPT_PASTE_HANDLER
		call	ObjVarFindData
		jc	done
	;
	; It's alright to raise an acceptPaste.
	;
		mov	ax, MSG_GADGET_CLIPBOARDABLE_RAISE_ACCEPT_PASTE_EVENT
		call	ObjCallInstanceNoLock

done:
		.leave
		Destroy	ax, cx, dx
		ret
RaiseAcceptPasteIfNotInAcceptPasteHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableRaiseAcceptPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate acceptPaste events until the component accepts
		some format or we run out of formats.

		Those components that don't need an acceptPaste handler
		should intercept this message and do nothing.  For example,
		the text and entry components will not raise acceptPaste
		events.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_RAISE_ACCEPT_PASTE_EVENT
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Loop through the formats supported on the current clipboard
	item until find one for which acceptPaste returns TRUE or
	we run out of formats.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 1/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RAISE_ACCEPT_PASTE_EVENT_LOCALS	equ	<\
.warn -unref_local\
stringToken	local	word				; RunHeapToken\
params		local	EntHandleEventStruct\
result		local	ComponentData\
formatList	local	CLIPBOARD_MAX_FORMATS dup(ClipboardItemFormatID)\
.warn @unref_local\
>

acceptPasteString	TCHAR	"acceptPaste", C_NULL

GadgetClipboardableRaiseAcceptPaste method dynamic GadgetClipboardableClass, 
			MSG_GADGET_CLIPBOARDABLE_RAISE_ACCEPT_PASTE_EVENT
RAISE_ACCEPT_PASTE_EVENT_LOCALS
		.enter
	;
	; Overhead:
	;    o Haven't allocated string on runheap yet.
	;    o Mark selves as currently raising an acceptPaste
	;
		clr	ss:[stringToken]
		mov	ax, HINT_CLIPBOARDABLE_IN_ACCEPT_PASTE_HANDLER
		clr	cx
		call	ObjVarAddData
	;
	; Get a list of all the formats supported.
	;
		push	bp
		segmov	es, ss, cx
		lea	di, ss:[formatList]		; es:di = buffer
		clr	bp				; Want normal item.
		call	ClipboardQueryItem		; bp <- # formats
							; bx:ax = item header
		mov	cx, bp
		jcxz	doneWithItem
		mov	cx, CLIPBOARD_MAX_FORMATS
		call	ClipboardEnumItemFormats  	; cx <- num formats
doneWithItem:
		call	ClipboardDoneWithItem
		pop	bp
	;
	; Loop through the list until find something acceptPaste likes.
	;
		sub	di, size ClipboardItemFormatID
formatLoop:
		jcxz	dontAllowPaste
		dec	cx
		add	di, size ClipboardItemFormatID
		call	MapCIFIDToLCBT			; ax <- LCBT
		cmp	ax, -1
		je	formatLoop			; no crspndng LCBT
		call	GetFormatForAcceptPasteEvent
		call	RaiseAcceptPasteEventLow
		jz	dontAllowPaste			; No handler.
	;
	; See if the handler accepted this format.
	;
		cmp	ss:[result].CD_type, LT_TYPE_INTEGER
		jne	formatLoop
		tst	ss:[result].CD_data.LD_integer
		jz	formatLoop			; Rejection!
	;
	; Found a format we can paste!
	;
		mov	di, ds:[si]
		add	di, ds:[di].GadgetClipboardable_offset
		or	ds:[di].GCLI_flags, mask CF_pastable	; Got one!
	;
	; Remove our special vardata and decrement ref count
	; for runheap buffer we allocated so that the block will
	; be freed.
	;
cleanUp:
		mov	ax, HINT_CLIPBOARDABLE_IN_ACCEPT_PASTE_HANDLER
		call	ObjVarDeleteData
EC <		ERROR_C	-1						>
		mov	ax, ss:[stringToken]
		tst	ax
		jz	done
		call	RunHeapDecRef_asm
done:
		.leave
		Destroy	ax, cx, dx
		ret

dontAllowPaste:
		mov	di, ds:[si]
		add	di, ds:[di].GadgetClipboardable_offset
		and	ds:[di].GCLI_flags, not mask CF_pastable ; Got one!
		jmp	cleanUp
GadgetClipboardableRaiseAcceptPaste	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapCIFIDToLCBT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a ClipboardItemFormatID to a LegosClipboardableType.

CALLED BY:	ClipboardableRaiseAcceptPasteInput only
PASS:		es:di	- ClipboardItemFormatID to be mapped
RETURN:		ax	- LegosClipboardableType or -1 if none found
DESTROYED:	dx,bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Find a matching ClipboardItemFormatID in the
		CIFIDToLCBTTable.
		The index of the match (shr 2 bits) is the LCBT.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; This table maps from a ClipboardItemFormatID into a LegosClipboardableType.
; The index of the CIFID is the LCBT.
;
; (UHH... ISN'T THIS A DUPLICATE OF LegosClipboardFormatTranslationTable IN
; SRVCLIPB.ASM?  dl)
;
CIFIDToLCBTTable  ClipboardItemFormatID \
	<CIF_TEXT, MANUFACTURER_ID_GEOWORKS>,
	<CIF_INTEGER, MANUFACTURER_ID_LEGOS>,
	<CIF_LONG, MANUFACTURER_ID_LEGOS>,
	<CIF_FLOAT, MANUFACTURER_ID_LEGOS>,
	<CIF_BITMAP, MANUFACTURER_ID_GEOWORKS>,
	<CIF_GRAPHICS_STRING, MANUFACTURER_ID_GEOWORKS>,
	<CIF_FAX_FILE_PAGE_WITH_INK, MANUFACTURER_ID_GEOWORKS>,
	<CIF_SOUND_SAMPLE, MANUFACTURER_ID_GEOWORKS>,
	<CIF_SPREADSHEET, MANUFACTURER_ID_GEOWORKS>

CheckHack <length CIFIDToLCBTTable eq LegosClipboardableType>

MapCIFIDToLCBT	proc	near
	uses	cx, si
		.enter

		CheckHack <NUM_LEGOS_CLIPBOARD_TYPES gt 0>
		CheckHack <size ClipboardItemFormatID eq 4>
		CheckHack <CIFID_manufacturer eq 0>
		CheckHack <CIFID_type eq 2>			; for cmpdw
		movdw	axdx, es:[di], bx			; dxax = CIFID
		clr	si
		mov	cx, NUM_LEGOS_CLIPBOARD_TYPES
tryNext:
		cmpdw	dxax, cs:[CIFIDToLCBTTable][si], bx	; (yes, dxax)
		je	gotIt
		add	si, size ClipboardItemFormatID
		loop	tryNext

		mov	ax, -1
done:
		.leave
		Destroy	dx, bx
		ret
gotIt:
		shr	si
		shr	si
		mov_tr	ax, si				; ax <- LCBT
		jmp	done
MapCIFIDToLCBT	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RaiseAcceptPasteEventLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise the acceptPaste event!

CALLED BY:	ClipboardableRaiseAcceptPasteEvent ONLY!
PASS:		locals on stack
		*ds:si	- clipboardable component
RETURN:		zf	- set if handler not called (doesn't exist)
DESTROYED:	ax,bx,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RaiseAcceptPasteEventLow	proc	near
	uses	cx, di, bp
RAISE_ACCEPT_PASTE_EVENT_LOCALS
		.enter inherit

		mov	ax, offset acceptPasteString
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[result]
		movdw	ss:[params].EHES_result, ssax
		mov	ss:[params].EHES_argc, 1
		clr	di
		mov	ss:[params].EHES_argv[di].CD_type, LT_TYPE_STRING
		mov	bx, ss:[stringToken]
		mov	ss:[params].EHES_argv[di].CD_data.LD_string, bx
		
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock		; ax=1 if handled
		tst	al				; zf <- result
		
		.leave
		Destroy	ax, bx, dx
		ret
RaiseAcceptPasteEventLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFormatForAcceptPasteEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make format string argument that will be passed
		in our acceptPaste event.

		The caller must decrement the ref count of the
		allocated block (from 1to 0) when done with it
		so that it'll be freed.

CALLED BY:	ClipboardableRaiseAcceptPasteEvent ONLY!
PASS:		ax	- LegosClipboardableType for the string
			  we need
		locals on stack
RETURN:		stringToken updated to hold runheap token for string
DESTROYED:	dx,bx,ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFormatForAcceptPasteEvent	proc	near
	uses	es, ds, si, di, cx
RAISE_ACCEPT_PASTE_EVENT_LOCALS
		.enter inherit

	;
	; Get pointer to string corresponding to format we found and put
	; it on the runtime heap.
	;
		push	ax
ifdef __HIGHC__
		call	SCBGetFormatString		; dx:ax = *TCHAR
else
		call	_SCBGetFormatString		; dx:ax = *TCHAR
endif
		add	sp, 2				; fix stack
	;
	; Do we have runheap space for the string arg yet?
	;
		pushdw	dxax				; save string ptr
		mov	ax, ss:[stringToken]
		tst	ax
		jz	doRunHeapAlloc			; need space
	;
	; Copy string to our runheap buffer.
	;
lockRunHeapString:
		call	RunHeapLock_asm			; es:di = buffer
		mov	bx, ds				; save sptr.
							;   EntObjectBlock
		popdw	dssi
		push	ax
		LocalCopyString
		pop	ax
		mov	ds, bx
		call	RunHeapUnlock_asm

		.leave
		Destroy	dx, bx, ax
		ret
	;
	; Make space for string arg.  ClipboardableRaiseAcceptPasteEven
	; will decrement the buffer's ref count to 0 when it is done
	; looping.
	;
doRunHeapAlloc:		
		mov	cx, MAX_CLIPBOARDABLE_TYPE_STRING_SIZE
		mov	bx, RHT_STRING
		clr	ax, di
		mov	dl, 1				; Caller sets to 0.
		call	RunHeapAlloc_asm		; ax = token
		mov	ss:[stringToken], ax
		jmp	lockRunHeapString
GetFormatForAcceptPasteEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableUpdateClipboards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent to a clipboardable when it needs to
		tell the clipboard components its state.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 1/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableUpdateClipboards method dynamic GadgetClipboardableClass, 
				MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
		.enter
	;
	;  Allocate a block to stuff our notification values into.
	;
		mov	bx, size NotifySelectStateChange
		call	ClipboardableAllocNotifyBlock
EC <		WARNING_C -1 						>
		jc	done
		call	MemLock
EC <		WARNING_C -1 						>
		jc	done
		mov	es, ax
	;
	;  The selection type and select all aren't part of the Legos API...
	;  Note that the clipboard component expects selectionType to be
	;  either SDT_TEXT or 0 (which = SDT_TEXT).  Otherwise it will
	;  not recognize the notification block as being from a Clipboardable.
	;
		clr	es:[NSSC_selectionType]
		mov	es:[NSSC_selectAllAvailable], BB_TRUE
	;
	;  Turn the copyable, deletable, and pastable flags into bytes,
	;  and write 'em into our block.
	;  Caveat: If we're not clipboardable or not focusable, then we're
	;  not copyable, deletable or pastable despite what those flags say.
	;  Caution: We're using zero/nonzero to mean BB_FALSE/BB_TRUE here
	;  for efficiency.
	;
EC <		call	ECCheckDSDIPointsToInstData			>
		mov	dx, ds:[di].GCLI_flags
		mov	cx, dx
		and	cx, mask CF_clipboardable or mask CF_focusable
		xor	cx, mask CF_clipboardable or mask CF_focusable
		jz	stuffFlagsInBlock
		clr	dx				; No clipboard ops.

stuffFlagsInBlock:
		mov	cx, dx
		and	cx, mask CF_copyable
		CheckHack < offset CF_copyable lt 8 >
		mov	es:[NSSC_clipboardableSelection], cl

		mov	cx, dx
		and	cx, mask CF_pastable
		CheckHack < offset CF_pastable lt 8 >
		mov	es:[NSSC_pasteable], cl

		mov	cx, dx
		and	cx, mask CF_deletable
		CheckHack < offset CF_deletable lt 8 >
		mov	es:[NSSC_deleteableSelection], cl
	;
	;  Send the thing off.
	;
		call	MemUnlock
		mov	cx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
		mov	dx, GWNT_SELECT_STATE_CHANGE
		call	ClipboardableSendNotification
done:
		.leave
		Destroy	ax, cx, dx
		ret
GadgetClipboardableUpdateClipboards	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardableAllocNotifyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the block of memory that will be used to
		update the clipboard components.

CALLED BY:	GadgetClipboardableUpdateClipboards

PASS:		bx - size to allocate

RETURN:		bx - block handle
		carry set if unable to allocate

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Initialize to zero 	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardableAllocNotifyBlock	proc near
	uses	ax, cx
	.enter
	mov	ax, bx			; size
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT) shl 8
	call	MemAlloc
	jc	done
	mov	ax, 1
	call	MemInitRefCount
	clc
done:
	.leave
	ret
ClipboardableAllocNotifyBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClipboardableSendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification that a clipboardable component
		changed.

CALLED BY:	GadgetClipboardableUpdateClipboards

PASS:		bx - Data block to send to controller, or 0 to send
		null data (on LOST_SELECTION) 
		cx - GenAppGCNListType
		dx - NotifyStandardNotificationTypes

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/30/91	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClipboardableSendNotification	proc near
	uses	bp
	.enter

	; create the event

	call	MemIncRefCount			;one more reference
	push	bx, cx, si
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	bp, bx				; data block
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bx, cx, si

	; Create messageParams structure on stack

	mov	dx, size GCNListMessageParams	; create stack frame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
	push	bx				; data block
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	
	; If data block is null, then set the IGNORE flag, otherwise
	; just set the SET_STATUS_EVENT flag

	mov	ax,  mask GCNLSF_SET_STATUS
	tst	bx
	jnz	gotFlags
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
gotFlags:
	mov	ss:[bp].GCNLMP_flags, ax
	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx				; data block
	
	add	sp, size GCNListMessageParams	; fix stack
	call	MemDecRefCount			; we're done with it 
	.leave
	Destroy	ax,cx,dx,bx,si,di
	ret
ClipboardableSendNotification	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableClipboardItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent to us from a clipboard component
		when it receives
		MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
		so that we can:
		  1) raise an acceptPaste for the new clipboard item;
		  2) tell the clipboard components our new state
		We then tell the clipboard to go ahead an raise a
		clipboardChanged event.

		NOTE: Be sure to send MSG_SCB_RAISE_CLIPBOARD_CHANGED_EVENT
		or else the clipboard component's eventFlags will be
		incorrect.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
		^lcx:dx	= clipboard component who sent us this message
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:
	We will receive this message for each clipboard component.  So
	multiple acceptPaste events might* be raised.  However, we do
	avoid sending out multiple notifications to clipboards
	(UPDATE_CLIPBOARDS).

	*Note that we won't raise an acceptPaste if one is already in
	 progress.


	Notice that we don't UPDATE_CLIPBOARDS if our flags do not
	change.  The GCN mechanism should ignore any redundant updates
	but it's more efficient to do the check here.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/ 2/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableClipboardItemChanged	method dynamic GadgetClipboardableClass, 
				MSG_GADGET_CLIPBOARDABLE_CLIPBOARD_ITEM_CHANGED
		.enter

		push	cx,dx				; Save clipboard.
	;
	; Get our current flags.
	; FIXME: Do we care about the hasFocus/hasTarget/clipboardable/
	; focusable flags?  What if in acceptPaste user makes the
	; component unfocusable/clipboardable?  Then it would be wierd
	; to send UPDATE_CLIPBOARDS.
	;
		mov	bx, ds:[di].GCLI_flags
	;
	; Raise acceptPaste events.
	;
		call	RaiseAcceptPasteIfNotInAcceptPasteHandler
	;
	; Get our flags again - did they change?  If not, don't cause
	; the clipboard components to raise selectionChanged events.
	;
EC <		call	ECCheckDSDIPointsToInstData			>
		cmp	bx, ds:[di].GCLI_flags
		je	raiseClipboardChanged
	;
	; Notify all clipboard components of our new state.
	;
		mov	ax, MSG_GADGET_CLIPBOARDABLE_UPDATE_CLIPBOARDS
		call	ObjCallInstanceNoLock
	;
	; Tell the clipboard to raise a clipboardChanged event.
	;
raiseClipboardChanged:
		pop	cx,dx				; Get clipboard.
		mov	ax, MSG_SCB_RAISE_CLIPBOARD_CHANGED_EVENT
		mov	bx, cx
		mov	si, dx
		clr	di
		call	ObjMessage
		
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetClipboardableClipboardItemChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetClipboardableMetaClipboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise a delete, copy, or paste event.

CALLED BY:	MSG_META_CLIPBOARD_CUT
		MSG_META_CLIPBOARD_COPY,
		MSG_META_CLIPBOARD_PASTE,
		MSG_META_DELETE

PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
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
deleteEventString		TCHAR	"delete", C_NULL
copyEventString			TCHAR	"copy", C_NULL
pasteEventString		TCHAR	"paste", C_NULL
GadgetClipboardableMetaClipboard method dynamic GadgetClipboardableClass, 
					MSG_META_CLIPBOARD_CUT,
					MSG_META_CLIPBOARD_COPY,
					MSG_META_CLIPBOARD_PASTE,
					MSG_META_DELETE
		uses	ax, cx, dx, bp
params	local	EntHandleEventStruct
		.enter

	;
	; Get the right string.
	;
		mov	bx, offset copyEventString
		cmp	ax, MSG_META_CLIPBOARD_COPY
		je	raiseEvent
		cmp	ax, MSG_META_CLIPBOARD_CUT	; = copy+delete
		je	raiseEvent

		mov	bx, offset pasteEventString
		cmp	ax, MSG_META_CLIPBOARD_PASTE
		je	raiseEvent
raiseDelete:
		mov	bx, offset deleteEventString
	;
	; Make event.
	;
raiseEvent:
		push	ax				; save msg
		mov	ax, bx
		movdw	ss:[params].EHES_eventID.EID_eventName, csax
		lea	ax, ss:[params]
		movdw	ss:[params].EHES_result, ssax
		clr	ss:[params].EHES_argc
		
		mov	ax, MSG_ENT_HANDLE_EVENT
		mov	di, mask MF_CALL
		lea	dx, params
		mov	cx, ss
		call	ObjCallInstanceNoLock
		pop	ax				; restore msg
	;
	; If we're doing a Cut(), we should now raise the Delete().
	;
		CheckHack <MSG_META_CLIPBOARD_CUT ne 0>
		sub	ax, MSG_META_CLIPBOARD_CUT
		jz	raiseDelete
		
		.leave
		ret
GadgetClipboardableMetaClipboard	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGadgetGetFocusableInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For internal use.  Gets the clipboardable's
		focusable status.

CALLED BY:	MSG_GADGET_CLIPBOARDABLE_GET_FOCUSABLE_INTERNAL
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
RETURN:		zero flg- set if gadget is *not* focusable
			- clear if gadget is focusable
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 12/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetClipboardableGetFocusableInternal method dynamic GadgetClipboardableClass, 
			MSG_GADGET_CLIPBOARDABLE_GET_FOCUSABLE_INTERNAL
		.enter

		test	ds:[di].GCLI_flags, mask CF_focusable
		
		.leave
		ret
GadgetClipboardableGetFocusableInternal	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetMakeClipboardSelectionStateNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When a non-ClipboardableClass object gets the target
		we want to make the selection state 0 for copyable,
		deletable and pastable.  This msg does just that.

		ClipboardableClass intercepts this message and does
		nothing.  Furthermore, ClipboardableClass updates
		the clipboards' selection states in its handler
		for GAINED_SYS_TARGET_EXCL.

CALLED BY:	MSG_GADGET_MAKE_CLIPBOARD_SELECTION_STATE_NULL
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es 	= segment of GadgetClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetMakeClipboardSelectionStateNull	method dynamic GadgetClass, 
				MSG_GADGET_MAKE_CLIPBOARD_SELECTION_STATE_NULL
		.enter
	;
	; Send notifcation with no data block.  No data block -> make
	; copyable/deletable/pastable 0.
	;
		clr	bx
		mov	cx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
		mov	dx, GWNT_SELECT_STATE_CHANGE
		call	ClipboardableSendNotification
		
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetMakeClipboardSelectionStateNull	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCMakeClipboardSelectionStateNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept and do nothing.  When a clipboardable gets
		the target, it update the selection state appropriately.

CALLED BY:	MSG_GADGET_MAKE_CLIPBOARD_SELECTION_STATE_NULL
PASS:		*ds:si	= GadgetClipboardableClass object
		ds:di	= GadgetClipboardableClass instance data
		ds:bx	= GadgetClipboardableClass object (same as *ds:si)
		es 	= segment of GadgetClipboardableClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCMakeClipboardSelectionStateNull method dynamic GadgetClipboardableClass, 
				MSG_GADGET_MAKE_CLIPBOARD_SELECTION_STATE_NULL
		.enter
	; Do nothing!
		.leave
		Destroy	ax, cx, dx, bp
		ret
GCMakeClipboardSelectionStateNull	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetMetaGainedSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We only intercept this msg so that we can send ourself
		MSG_GADGET_MAKE_CLIPBOARD_SELECTION_STATE_NULL.
		This is necessary for forms, dialogs (, floaters) and
		ink, all of which can gain the target (become the
		activeSelection) but do not support the clipboardable
		API.

CALLED BY:	MSG_META_GAINED_SYS_TARGET_EXCL
PASS:		*ds:si	= GadgetClass object
		ds:di	= GadgetClass instance data
		ds:bx	= GadgetClass object (same as *ds:si)
		es 	= segment of GadgetClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 4/29/96   	Initial version
	jmagasin 7/3/96		Reverse order of supercall and state_null
				so that a window doesn't null out state
				after its child clipboardable gains the
				system target.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetMetaGainedSysTargetExcl	method dynamic GadgetClass, 
					MSG_META_GAINED_SYS_TARGET_EXCL
		.enter
	;
	; Call our special message.
	;
		mov	ax, MSG_GADGET_MAKE_CLIPBOARD_SELECTION_STATE_NULL
		call	ObjCallInstanceNoLock
	;
	; Let the superclass do its thing.
	;
		mov	ax, MSG_META_GAINED_SYS_TARGET_EXCL
		mov	di, offset GadgetClass
		call	ObjCallSuperNoLock
		
		.leave
		Destroy	ax, cx, dx, bp
		ret
GadgetMetaGainedSysTargetExcl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckDSDIPointsToInstData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure ds:di is our instance data.

CALLED BY:	EC utility
PASS:		*ds:si	- GadgetClipboardableClass instance
		ds:di	- instance data, we hope
RETURN:		nothing (fatal error if di not offset to instance data)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECCheckDSDIPointsToInstData	proc	near
	uses	di,ax
		.enter

		Assert	objectPtr, dssi, GadgetClipboardableClass
		mov	ax, di				
		mov	di, ds:[si]					
		add	di, ds:[di].GadgetClipboardable_offset		
		cmp	di, ax						
		ERROR_NE -1
		
		.leave
		ret
ECCheckDSDIPointsToInstData	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckClipboardableFlagsOnFocusChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the focus or target change will toggle
		our hasFocus/hasTarget flag correctly.

CALLED BY:	GadgetClipboardableFocusChanged only
PASS:		ds:di	- Clipboardable instance data
		ax	- message
RETURN:		nothing (fatal error if flags not right)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jmagasin 3/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
ECCheckClipboardableFlagsOnFocusChange	proc	near
	uses	bx
	class	GadgetClipboardableClass
		.enter

		mov	bx, ds:[di].GCLI_flags
	;
	; If gained focus, better not think we already have focus.
	;
		cmp	ax, MSG_META_GAINED_SYS_FOCUS_EXCL
		jne	checkIfLostFocus
		test	bx, mask CF_hasFocus
		jnz	error
		jmp	done
	;
	; If we lost the focus, we better think we currently have it.
	;
checkIfLostFocus:
		cmp	ax, MSG_META_LOST_SYS_FOCUS_EXCL
		jne	checkIfGainedTarget
		test	bx, mask CF_hasFocus
		jz	error
		jmp	done
	;
	; If we gained the target, better not think we already have target.
	;
checkIfGainedTarget:
		cmp	ax, MSG_META_GAINED_SYS_TARGET_EXCL
		jne	handleLostTarget
		test	bx, mask CF_hasTarget
		jnz	error
		jmp	done
	;
	; If we lost the target, we better think we currently have it.
	;
handleLostTarget:
		test	bx, mask CF_hasTarget
		jz	error

done:		
		.leave
		ret
error:
		ERROR	-1
ECCheckClipboardableFlagsOnFocusChange	endp
endif

GadgetClipboardableCode	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetHelpContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the helpContext on a gadget

CALLED BY:	MSG_GADGET_SET_HELP_CONTEXT
PASS:		*ds:si	= GenClass object
		ds:di	= GenClass instance data
		ds:bx	= GenClass object (same as *ds:si)
		es	= segment of GadgetClass
		ax	= message #
		ss:bp	= SetPropertyArgs
RETURN:		
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/97		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSetHelpContext	method	GadgetClass, MSG_GADGET_SET_HELP_CONTEXT
		.enter

		mov	ax, ATTR_GEN_HELP_CONTEXT
		call	SetStringVardataProperty

		.leave
		Destroy	ax, cx, dx
		ret
GadgetSetHelpContext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetSetHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the helpFile on a gadget

CALLED BY:	MSG_GADGET_SET_HELP_FILE
PASS:		*ds:si	= GadgetClass object
		ss:bp - ptr to SetPropertyArgs
RETURN:		none
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/31/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetSetHelpFile	method dynamic GadgetClass, 
					MSG_GADGET_SET_HELP_FILE
		.enter

		mov	ax, ATTR_GEN_HELP_FILE
		call	SetStringVardataProperty

		.leave
		Destroy ax, cx, dx
		ret
GadgetSetHelpFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetHelpContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the helpContext for a gadget

CALLED BY:	MSG_GADGET_GET_HELP_CONTEXT
PASS:		*ds:si	= GadgetClass object
		ss:bp - ptr to GetPropertyArgs
RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_string filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetHelpContext	method dynamic GadgetClass, 
					MSG_GADGET_GET_HELP_CONTEXT
		.enter

		mov	ax, ATTR_GEN_HELP_CONTEXT
		call	GetStringVardataProperty

		.leave
		Destroy	ax, cx, dx
		ret
GadgetGetHelpContext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GadgetGetHelpFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the 

CALLED BY:	
CALLED BY:	MSG_GADGET_GET_HELP_CONTEXT
PASS:		*ds:si	= GadgetClass object
		ss:bp - ptr to GetPropertyArgs
RETURN:		*(ss:[bp].GPA_compDataPtr).CD_data.LD_string filled in
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/31/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GadgetGetHelpFile	method dynamic GadgetClass,
						MSG_GADGET_GET_HELP_FILE
		.enter

		mov	ax, ATTR_GEN_HELP_FILE
		call	GetStringVardataProperty

		.leave
		Destroy	ax, cx, dx
		ret
GadgetGetHelpFile	endp

GadgetMastCode	ends
