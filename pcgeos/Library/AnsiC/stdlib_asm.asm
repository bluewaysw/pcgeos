COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		AnsiC
FILE:		stdlib_asm.asm

AUTHOR:		Jenny Greenwood, 14 November 1991

ROUTINES:
	Name			Description
	----			-----------
GLB	qsort			Sort an array into ascending order
GLB	bsearch			Do binary search on a sorted array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	14/11/91	Initial version

DESCRIPTION:
	Assembly versions of ANSI C stdlib.h routines.

	$Id: stdlib_asm.asm,v 1.1 97/04/04 17:42:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include ansicGeode.def

	SetGeosConvention

;RESIDENT	segment	word	public	'CODE'
;MAINCODE	segment	word	public	'CODE'
MAINCODE	segment	public	'CODE'


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		qsort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	qsort

C DECLARATION	extern void
		_pascal qsort(void *array, word count, word elementSize,
			      int (*compare)(const void *, const void *));
		(For XIP system, *compare() has to be vfptr. )
DESTROYED:	ax, bx, cx, dx
 
PSEUDO CODE/STRATEGY:
	Set up stack frame with _qsort_callback as the callback
	to be called from ChunkArrayQuickSort, which inherits only the 
        CQSP_common portion of the frame. _qsort_callback
	inherits qsort's entire stack frame and calls the callback
	originally passed as an argument to qsort.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	14/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CQuickSortParameters	struct
		CQSP_compareCallback	fptr.far
		CQSP_realDS		sptr		; caller's dgroup
		CQSP_common		QuickSortParameters
CQuickSortParameters	ends

global	qsort:far
qsort	proc	far	array:fptr, count:word, elementSize:word, callback:fptr
		uses ds, si
params	local	CQuickSortParameters
		.enter
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, callback					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

		mov	cx, count
		cmp	cx, 1
		jbe	done
	;
	; Initialize the stack frame.
	;
		mov	ss:[params].CQSP_common.QSP_compareCallback.segment, cs
		mov	ss:[params].CQSP_common.QSP_compareCallback.offset, \
			offset _qsort_callback 
		movdw	bxax, callback
		movdw	ss:[params].CQSP_compareCallback, bxax
	
		clr	bx	; no lock
		mov	ss:[params].CQSP_common.QSP_lockCallback.segment, bx
		mov	ss:[params].CQSP_common.QSP_unlockCallback.segment, bx

		mov	ss:[params].CQSP_common.QSP_insertLimit, \
				DEFAULT_INSERTION_SORT_LIMIT
		mov	ss:[params].CQSP_common.QSP_medianLimit, \
				DEFAULT_MEDIAN_LIMIT
		mov	ss:[params].CQSP_realDS, ds
	;
	; Set up arguments for ArrayQuickSort.
	; Note that cx = count and bx = 0 = value to pass to callback.
	;
		lds	si, array
		mov	ax, elementSize
		call	ArrayQuickSort
done:
		.leave
		ret
qsort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		_qsort_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:	_qsort_callback

DESCRIPTION:	Callback routine for qsort

CALLED BY:	ChunkArrayQuickSort (via qsort)

PASS:		ds:si - first element
		es:di - second element (ds = es)
		ss:bp - inherited CQuickSortParameters

RETURN:		Flags set so ChunkArrayQuickSort can jl, je, or jg
		according to whether the first element is less than,
		equal to, or greater than the second

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		See explanation for qsort, above.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The callback called by this routine is of the form:
			      int (*compare)(const void *, const void *));

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/13/92		Initial version
        mgroeb  5/20/00         Fixed trashing of ES register

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_qsort_callback	proc	far
                uses ds, es
		.enter inherit qsort
		pushdw	dssi				; first element
		pushdw	esdi				; second element
		pushdw	ss:[params].CQSP_compareCallback
		mov	ds, ss:[params].CQSP_realDS
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		cmp	ax, 0				; set flags
		.leave
		ret
_qsort_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		bsearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	bsearch

C DECLARATION	extern void
		*_pascal bsearch(const void *key, const void *array,
			         word count, word elementSize,
			         int (*compare)(const void *, const void *));
		(For XIP system, *compare() has to be fptr.)

DESTROYED:	bx, cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	14/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	bsearch:far
bsearch	proc	far	key:fptr, array:fptr, count:word, elementSize:word,
			compareCallback:fptr
		uses es, di, si
		.enter
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, compareCallback				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		les	di, array
		mov	si, elementSize
		mov	cx, count
search:
		tst	cx
		jz	notFound	; no more elts to look at, alas
	;
	; Find median element.
	;
		mov	bx, di		; store ptr to search area
		shr	cx		; cx <- # elts/2
		pushf			; save carry flag (set if #elts odd)
		mov	ax, si		; ax <- element size
		mul	cx		; ax <- size of search area/2
EC <		ERROR_C	ERROR_BSEARCH_OVERFLOW			>
		add	di, ax		; di <- ptr to median element
	;
	; Compare key to median element.
	;
		push	bx, cx, si, di
		pushdw	key
		push	es, di
		call	compareCallback
		pop	bx, cx, si, di
	;
	; Set up for next search loop.
	;
		tst	ax		; test compareCallback result
		jl	truncateHighEnd	; 	key < array element
		jz	found		; 	key = array element
		add	di, si		; di <- ptr to high end
		popf			; restore carry flag (odd # elts)
		jnc	evenCount
		jmp	search
evenCount:
	;
	; If the # of elements (E) last time through the loop was even,
	; then the median element was the first element of the top
	; half. We aren't going to look at it again as we now search
	; the high end, so we have (E/2) - 1 elements this time through.
	;
		dec	cx		; cx <- correct # of high end elts
		jmp	search
truncateHighEnd:
		popf			; clear stack
		mov	di, bx		; di <- ptr to start of low end
		jmp	search
notFound:
		clrdw	dxax		; dx:ax <- NULL
		jmp	done
found:
		popf			; clear stack
		mov	dx, es		; dx:ax <- ptr to matching elt
		mov_tr	ax, di
done:
		.leave
		ret
bsearch	endp

;RESIDENT	ends
MAINCODE	ends
