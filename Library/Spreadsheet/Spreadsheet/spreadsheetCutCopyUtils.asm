COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 6/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial revision

DESCRIPTION:
	Utility and error checking routines.
		
	$Id: spreadsheetCutCopyUtils.asm,v 1.1 97/04/07 11:14:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CutPasteCode	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyRedrawRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ds:si - Spreadsheet instance

RETURN:		none

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopyRedrawRange	proc	near
	uses	ax, bx, cx, dx
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	RecalcRowHeightsFar		; destroys ax,bx,cx,dx
	;
	; Recalculate the view's document size, update the UI, and
	; redraw everything.
	; We update the UI for:
	;	edit bar
	;	cell notes
	;	all cell attributes
	;
	mov	ax, SNFLAGS_ACTIVE_CELL_DATA_CHANGE or \
		    SNFLAGS_SELECTION_ATTRIBUTES_CHANGE
	call	UpdateDocUIRedrawAll

	.leave
	ret
CutCopyRedrawRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyGetCellSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	given 

CALLED BY:	INTERNAL (CutCopySaveCell)

PASS:		al - CellType
		es:di - Cell... structure

RETURN:		ax - size of structure (=0 if empty)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopyGetCellSize	proc	near	uses    si
	.enter
	clr     ah
	mov     si, ax
EC <    cmp     si, size sizeRoutines >
EC <    ERROR_AE        CUT_COPY_CELL_TYPE_UNKNOWN >
	call    cs:sizeRoutines[si]
	.leave
	ret

sizeRoutines    nptr \
	CutCopyTextCellGetSize,		;CT_TEXT
	CutCopyConstantCellGetSize,	;CT_CONSTANT
	CutCopyFormulaCellGetSize,	;CT_FORMULA
	CutCopyError,			;CT_NAME
	CutCopyError,			;CT_CHART
	CutCopyEmptySize,		;CT_EMPTY
	CutCopyFormulaCellGetSize	;CT_DISPLAY_FORMULA
CheckHack <(size sizeRoutines) eq CellType>
CutCopyGetCellSize	endp

;;;
;;; Changes 3/25/93 -jw
;;; Added CutCopyError routine. It should not be possible to copy
;;; a NAME cell or a CHART cell, because they can't be selected.
;;;
CutCopyError		proc	near
EC <	ERROR	CELL_SHOULD_NOT_BE_A_NAME_CELL		>
NEC <	ret						>
CutCopyError		endp

;;;
;;; Changes 3/25/93 -jw
;;; Changed to return the actual size of an empty cell, rather than zero.
;;; CutCopyGetCellSize() is only called from CutCopySaveCell() and that
;;; code really does want to get the size of an empty cell because it
;;; really does want to copy these cells of type CT_EMPTY.
;;;
CutCopyEmptySize	proc	near
	mov	ax, size CellEmpty
	ret
CutCopyEmptySize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyTextCellGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Returns string size (including C_NULL) so caller can memory
		duplicated us.

CALLED BY:	INTERNAL (CutCopySaveCell)

PASS:		es:di - CellText structure

RETURN:		ax - size including the null terminator

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/91		Initial version
	witt	11/93		DBCS-ized for DBCS "size"

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CutCopyTextCellGetSize	proc	near	uses	bx,cx,di
	.enter
	;
	; figure size of structure
	;
	mov	bx, di			; save ptr to start of structure
	add	di, size CellText	; di <- start of string
SBCS<	clr	al							>
DBCS<	clr	ax							>
	mov	cx, 0ffffh
	LocalFindChar			; where does string end?
	sub	di, bx			; di <- string size (incl NULL)
	mov	ax, di

	.leave
	ret
CutCopyTextCellGetSize	endp


CutCopyFormulaCellGetSize	proc	near
	.enter

	mov	ax, size CellFormula
	add	ax, es:[di].CF_formulaSize
	cmp	es:[di].CF_return, RT_TEXT	; Check for text 
	jne	noText				; skip if no text
	add	ax, es:[di].CF_current.RV_TEXT  ; otherwise add text length
noText:	

	.leave
	ret
CutCopyFormulaCellGetSize	endp


CutCopyConstantCellGetSize	proc	near
	.enter

	mov	ax, size CellConstant

	.leave
	ret
CutCopyConstantCellGetSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyVMAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Don't use any override.

CALLED BY:	INTERNAL ()

PASS:		bx - vm file handle
		cx - size of block to allocate

RETURN:		ax - vm block handle

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
CutCopyVMAlloc	proc	near
	.enter

	call	VMAlloc			; ax <- VM block handle

	.leave
	ret
CutCopyVMAlloc	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyVMLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Doesn't mess with the BP register.

CALLED BY:	INTERNAL ()

PASS:		bx - vm file handle
		ax - vm handle

RETURN:		es - seg addr of vm block
		cx - VM mem handle

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
CutCopyVMLock	proc	near	uses	ax,bp
	.enter

	call	VMLock
	mov	cx, bp			; cx <- VM mem handle
	mov	es, ax			; es <- seg addr

	.leave
	ret
CutCopyVMLock	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	CutCopyVMUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Doesn't mess with the BP register.

CALLED BY:	INTERNAL ()

PASS:		cx - VM mem handle

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
CutCopyVMUnlock	proc	near	uses	bp
	.enter

	mov	bp, cx
	call	VMUnlock

	.leave
	ret
CutCopyVMUnlock	endp
endif

CutPasteCode	ends
