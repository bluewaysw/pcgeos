COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallStorage.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Routines for creating/destroying line and field storage in large
	text objects.

	$Id: tlLargeStorage.asm,v 1.1 97/04/07 11:20:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextInstance	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeStorageCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create line and field storage for a large text object.

CALLED BY:	TL_StorageCreate via CallLineHandler
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeStorageCreate	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di, bp
	.enter
	;
	; Allocate a chunk-array.
	;
	call	T_GetVMFile
	clr	cx				; Variable sized elements
	mov	di, cx				; No extra header space
	call	HugeArrayCreate			; di <- huge-array handle
	
	;
	; Allocate a single item that is the correct size
	;
	push	si				; Save instance chunk
	mov	cx, size LineInfo		; cx <- size of data
NOFXIP<	mov	bp, cs				; bp:si <- line structure >
NOFXIP<	mov	si, offset cs:initLine					  >
if FULL_EXECUTE_IN_PLACE
	push	es, di
	segmov	es, cs
	mov	di, offset cs:initLine
	call	SysCopyToStackESDI
	mov	bp, es
	mov	si, di
	pop	es, di
endif
	call	HugeArrayAppend
FXIP<	call	SysRemoveFromStack				>
	pop	si				; Restore instance chunk

	;
	; *ds:si= Instance ptr
	; di	= Array-handle of the line/field array
	;
	mov	ax, di				; ax <- array pointer
	call	TextLine_DerefVis_DI		; ds:di <- instance ptr
	mov	ds:[di].VTI_lines, ax		; Save the chunk array
	.leave
	ret
LargeStorageCreate	endp


;
; This line is copied into new lines as they are created.
;
initLine	LineInfo <
						; LI_flags
	mask LF_STARTS_PARAGRAPH or \
	mask LF_ENDS_PARAGRAPH or \
	mask LF_ENDS_IN_NULL,
	<0,0>,					; LI_hgt
	<0,0>,					; LI_blo
	0,					; LI_adjustment
	<0,0>,					; LI_start
	<0,0>,					; LI_spacePad
	0,					; LI_lineEnd
	<					; LI_firstField
		0,				;	FI_nChars
		0,				;	FI_position
		0,				;	FI_width
		<				;	FI_tab
			TRT_RULER,		;		TR_TYPE
			0x7f			;		TR_REF_NUMBER
		>
	>
>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeStorageDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy line and field storage for a large text object.

CALLED BY:	TL_StorageDestroy via CallLineHandler
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeStorageDestroy	proc	far
	class	VisTextClass
	uses	ax, bx, di
	.enter
	call	TextLine_DerefVis_DI		; ds:di <- instance ptr
	mov	ax, ds:[di].VTI_lines		; ax <- array

	tst	ax				; Check for no storage
	jz	quit				; Branch if none

	mov	di, ax				; di <- array
	call	T_GetVMFile			; bx = VM file
	call	HugeArrayDestroy		; Nuke it
quit:
	.leave
	ret
LargeStorageDestroy	endp

TextInstance	ends

TextLineCalc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert some number of lines into a large text object.

CALLED BY:	TL_LineInsert via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line to insert in front of
		dx.ax	= Number of lines to insert
RETURN:		bx.di	= First new line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineInsert	proc	far
	class	VisTextClass
	uses	ax, cx, dx, bp
	.enter
	pushdw	bxcx				; Save line to return

	xchgdw	dxax, bxcx			; dx.ax <- line to insert before
						; bx.cx <- number to insert
	;
	; Get the line-array and start adding lines
	;
	call	Text_DerefVis_DI		; ds:di <- instance ptr
	mov	di, ds:[di].VTI_lines		; di <- line array
	
	
;-----------------------------------------------------------------------------
insertLoop:
	;
	; di	= Line-array
	; bp:si	= Pointer to tInitLine
	; dx.ax	= Line to insert in front of
	; bx.cx	= Number of lines to insert
	;
	tstdw	bxcx				; Check for nothing to insert
	jz	endloop
	
	push	bx, cx, si			; Save count.low
	call	T_GetVMFile			; bx = VM file
	mov	cx, size LineInfo		; cx <- size of element
NOFXIP<	mov	bp, cs				; bp:si <- tInitLine	>
NOFXIP<	mov	si, offset cs:tInitLine					>
if FULL_EXECUTE_IN_PLACE
	push	es, di
	segmov	es, cs
	mov	di, offset cs:tInitLine
	call	SysCopyToStackESDI
	mov	bp, es
	mov	si, di
	pop	es, di
endif
	call	HugeArrayInsert			; Insert another line
FXIP<	call	SysRemoveFromStack					>
	pop	bx, cx, si			; Restore count.low

	decdw	bxcx				; One less to insert
	incdw	dxax				; Insert after last line
	jmp	insertLoop

endloop:
;-----------------------------------------------------------------------------

	popdw	bxdi				; Restore line to return
	.leave
	ret
LargeLineInsert	endp

;
; This line is copied into new lines as they are created.
;
tInitLine	LineInfo <
						; LI_flags
	mask LF_STARTS_PARAGRAPH or \
	mask LF_ENDS_PARAGRAPH or \
	mask LF_ENDS_IN_NULL,
	<0,0>,					; LI_hgt
	<0,0>,					; LI_blo
	0,					; LI_adjustment
	<0,0>,					; LI_start
	<0,0>,					; LI_spacePad
	0,					; LI_lineEnd
	<					; LI_firstField
		0,				;	FI_nChars
		0,				;	FI_position
		0,				;	FI_width
		<				;	FI_tab
			TRT_RULER,		;		TR_TYPE
			0x7f			;		TR_REF_NUMBER
		>
	>
>




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete some number of lines from a large text object.

CALLED BY:	TL_LineDelete via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line to start deleting at
		dx.ax	= Number of lines to delete
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineDelete	proc	far
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	push	bx
	call	T_GetVMFile			; bx = VM file
	mov	bp, bx
	pop	bx
	;
	; Set up to delete
	;
	call	LargeGetLineArray		; di <- line-array

	;
	; We want:
	;	dx.ax = Start line
	;	bx.si = Count
	; We have:
	;	dx.ax = Count
	;	bx.cx = Start line
	;
	mov	si, cx				; bx.si <- start line
	xchgdw	dxax, bxsi			; dx.ax <- start line
						; bx.si <- count
	;
	; di	= Array
	; dx.ax	= Starting element
	; bx.si	= Number to delete
	;
nukeMore:
	tstdw	bxsi				; Check for no more
	jz	quit				; Branch if no more

	mov	cx, si				; Assume this many left
	tst	bx				; Check for >64K
	jz	gotCount			; Branch if less
	mov	cx, -1				; Else delete lots of them
gotCount:
	xchg	bx, bp
	call	HugeArrayDelete			; Nuke the elements
	xchg	bx, bp
	
	sub	si, cx				; Update the count
	sbb	bx, 0
	jmp	nukeMore

quit:
	.leave
	ret
LargeLineDelete	endp

TextLineCalc	ends
