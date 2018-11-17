COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:	        Text
FILE:		taC.asm

AUTHOR:		Cassie Hartzog, Nov 24, 1993

ROUTINES:
	Name			Description
	----			-----------
	MSGVISTEXTGETTYPE	C routine to call MSG_VIS_TEXT_GET_TYPE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	11/24/93	Initial revision


DESCRIPTION:
	C stubs for the TextAttr module of the Text library.

	$Id: taC.asm,v 1.1 97/04/07 11:18:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


TextC	segment resource

	SetGeosConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTMAPDEFAULTCHARATTR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	C Stub for TextMapDefaultCharAttr

C DECLARATION:

extern void	
    _pascal TextMapDefaultCharAttr(VisTextDefaultCharAttr defaulAttr,
				   VisTextCharAttr *attr);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTMAPDEFAULTCHARATTR:far
TEXTMAPDEFAULTCHARATTR	proc far  defaultAttr:VisTextDefaultCharAttr,
				  attr:fptr.VisTextCharAttr
		uses	si,di,ds,es
		.enter

	;
	; Make room on the stack for a VisTextCharAttr structure
	;
		mov	cx, size VisTextCharAttr
		sub	sp, cx	
		mov	si, sp

		mov	ax, ss:[defaultAttr]
		xchg	si, bp		; ss:bp <- VisTextCharAttr buffer
		call	TextMapDefaultCharAttr

	;
	; Copy the stack buffer to the passed buffer
	;
		segmov	ds, ss, ax
		xchg	si, bp		; ss:bp <- stack frame

		les	di, ss:[attr]
		rep	movsb

		add	sp, size VisTextCharAttr

		.leave
		ret
TEXTMAPDEFAULTCHARATTR		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTFINDDEFAULTCHARATTR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	C Stub for TextFindDefaultCharAttr

C DECLARATION:

extern Boolean
    _pascal TextFindDefaultCharAttr(VisTextDefaultCharAttr *defaultAttr,
				    VisTextCharAttr *attr) = carry;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTFINDDEFAULTCHARATTR:far
TEXTFINDDEFAULTCHARATTR	proc	far  defaultAttr:fptr.VisTextDefaultCharAttr,
				     attr:fptr.VisTextCharAttr
		uses	si,ds,di,es
		.enter

	;
	; Make room on the stack for a VisTextCharAttr structure
	;
		mov	cx, size VisTextCharAttr
		sub	sp, cx	

		mov	di, sp
		segmov	es, ss, ax	; es:di <- VisTextCharAttr buffer

	;
	; Copy the passed attrs to the buffer
	;
		push	di
		lds	si, ss:[attr]	
		rep	movsb
		pop	di
		
		xchg	di, bp		; ss:bp <- VisTextCharAttr buffer
		call	TextFindDefaultCharAttr

		mov	bp, di
		lds	si, ss:[defaultAttr]
		mov	ds:[si], ax

		clr	ax		; assume false
		jnc	done
		dec	ax
done:		
		add	sp, size VisTextCharAttr
		
		.leave
		ret
TEXTFINDDEFAULTCHARATTR		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTMAPDEFAULTPARAATTR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	C Stub for TextMapDefaultParaAttr

C DECLARATION:

extern void
    _pascal TextMapDefaultParaAttr(VisTextDefaultParaAttr defaultAttr,
				   VisTextParaAttr *attr);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTMAPDEFAULTPARAATTR:far
TEXTMAPDEFAULTPARAATTR	proc	far	defaultAttr:word,
					attr:fptr.VisTextParaAttr
		uses	si,di,ds,es
		.enter

	;
	; Make room on the stack for a VisTextParaAttr
	;
		mov	cx, size VisTextParaAttr
		sub	sp, cx
		mov	si, sp
		mov	ax, ss:[defaultAttr]
		xchg	si, bp
		call	TextMapDefaultParaAttr

	;
	; Copy the stack buffer to the passed buffer
	;
		segmov	ds, ss, ax
		xchg	bp, si
		les	di, ss:[attr]
		rep	movsb

		add	sp, size VisTextParaAttr
		
		.leave
		ret
TEXTMAPDEFAULTPARAATTR		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTFINDDEFAULTPARAATTR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	C Stub for TextFindDefaultParaAttr

C DECLARATION:

extern Boolean
    _pascal TextFindDefaultParaAttr(VisTextDefaultParaAttr *defaultAttr,
				    VisTextParaAttr *attr) = carry;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTFINDDEFAULTPARAATTR:far
TEXTFINDDEFAULTPARAATTR	proc	far	defaultAttr:fptr.word,
					attr:fptr.VisTextParaAttr
		uses	si,ds,di,es
		.enter


	;
	; Make room on the stack for a VisTextParaAttr structure
	;
		mov	cx, size VisTextParaAttr
		sub	sp, cx	

		mov	di, sp
		segmov	es, ss, ax	; es:di <- VisTextParaAttr buffer

	;
	; Copy the passed attrs to the buffer
	;
		push	di
		lds	si, ss:[attr]	
		rep	movsb
		pop	di
		
		xchg	di, bp		; ss:bp <- VisTextParaAttr buffer
		call	TextFindDefaultParaAttr

		mov	bp, di
		lds	si, ss:[defaultAttr]
		mov	ds:[si], ax

		clr	ax		; assume false
		jnc	done
		dec	ax
done:		
		add	sp, size VisTextParaAttr
		
		.leave
		ret
TEXTFINDDEFAULTPARAATTR		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TEXTGETSYSTEMCHARATTRRUN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	C Stub for TextGetSystemCharAttrRun

C DECLARATION:

extern Boolean
    _pascal TextGetSystemCharAttrRun(word *chunkOrConstant, optr object, 
				     ObjChunkFlags flags) = carry;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	TEXTGETSYSTEMCHARATTRRUN:far
TEXTGETSYSTEMCHARATTRRUN proc	far	chunkOrConstant:fptr.word, \
					object:optr, flags:word
		uses	bx,si,ds
		.enter

		movdw	bxsi, ss:[object]
		call	ObjLockObjBlock
		mov	ds, ax
		mov	al, ss:[flags].low
		call	TextGetSystemCharAttrRun

		lds	si, ss:[chunkOrConstant]
		mov	ds:[si], ax

		mov	ax, 0		; return FALSE if chunk allocated
		jnc	done		; carry clear - chunk allocated
		dec	ax		; return TRUE if default returned
done:
		call	MemUnlock
		.leave
		ret
TEXTGETSYSTEMCHARATTRRUN	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSGVISTEXTLOADSTYLESHEETPARAMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	C Stub for MsgVisTextLoadStyleSheetParams

C DECLARATION:

extern void
    _pascal MsgVisTextLoadStyleSheetParams(StyleSheetParams *params,
			    	    	   optr object,
					   word preserveArrays);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine must be called from the same thread as
	that which is running the text object.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	MSGVISTEXTLOADSTYLESHEETPARAMS:far
MSGVISTEXTLOADSTYLESHEETPARAMS proc	far	params:fptr.StyleSheetParams,
					object:optr, preserveArrays:word
		uses	si,ds,di,es
		.enter

	;
	; Make room on the stack for StyleSheetParams
	;
		sub	sp, size StyleSheetParams
		mov	di, sp
	;
	; @call object::MSG_VIS_TEXT_LOAD_STYLE_SHEET_PARAMS()
	;
		push	bp, di
		movdw	bxsi, ss:[object]
		mov	cx, ss:[preserveArrays]
		mov	bp, di
		mov	ax, MSG_VIS_TEXT_LOAD_STYLE_SHEET_PARAMS

		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp, si

	;
	; Copy the filled-in buffer back to the passed buffer
	;
		segmov	ds, ss, ax		; ds:si <- stack buffer
		mov	cx, size StyleSheetParams
		les	di, ss:[params]
		rep	movsb

		add	sp, size StyleSheetParams

		.leave
		ret
MSGVISTEXTLOADSTYLESHEETPARAMS	endp


	SetDefaultConvention


ForceRef TEXTMAPDEFAULTCHARATTR
ForceRef TEXTFINDDEFAULTCHARATTR
ForceRef TEXTFINDDEFAULTPARAATTR
ForceRef TEXTFINDDEFAULTPARAATTR
ForceRef MSGVISTEXTLOADSTYLESHEETPARAMS

TextC	ends
