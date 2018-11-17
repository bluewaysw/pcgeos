COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/LMem
FILE:		lmemC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the lmem routines

	$Id: lmemC.asm,v 1.1 97/04/05 01:14:15 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemInitHeap

C DECLARATION:	extern void
		    _far _pascal LMemInitHeap(MemHandle mh, LMemType type,
					word flags, word lmemOffset,
					word numHandles, word freeSpace)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LMEMINITHEAP	proc	far	mh:hptr, ltype:LMemType, flags:word,
				lmemOffset:word, numHandles:word,
				freeSpace:word
						uses si, di, bp, ds
	.enter

	mov	ax, ltype
	mov	bx, mh
	call	MemDerefDS
	mov	cx, numHandles
	mov	dx, lmemOffset
	mov	si, freeSpace
	mov	di, flags
	call	LMemInitHeap

	.leave
	ret

LMEMINITHEAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemReAlloc

C DECLARATION:	extern Boolean
			_far _pascal LMemReAlloc(MemHandle mh,
					ChunkHandle chunk, word chunkSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	AMS	7/92		Made it Boolean, return = carry

------------------------------------------------------------------------------@
LMEMREALLOC	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = han, ax = chnk, cx = size

	push	ds
	call	MemDerefDS
	call	LMemReAlloc
	pop	ds

	mov	ax, 0
	jnc	done
	dec	ax
done:
	ret

LMEMREALLOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemInsertAt

C DECLARATION:	extern Boolean
			_far _pascal LMemInsertAt(MemHandle mh,
					ChunkHandle chunk, word insertOffset,
					word insertCount);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	AMS	7/92		Changed to Boolean; return = carry

------------------------------------------------------------------------------@
LMEMINSERTAT	proc	far	mh:hptr, lchunk:word, insertOffset:word,
				insertCount:word
					uses ds
	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	ax, lchunk
	mov	bx, insertOffset
	mov	cx, insertCount
	call	LMemInsertAt

	mov	ax, 0
	jnc	done
	dec	ax
done:

	.leave
	ret

LMEMINSERTAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemDeleteAt

C DECLARATION:	extern void
			_far _pascal LMemDeleteAt(MemHandle mh,
					ChunkHandle chunk, word deleteOffset,
					word deleteCount);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LMEMDELETEAT	proc	far	mh:hptr, lchunk:word, deleteOffset:word,
				deleteCount:word
					uses ds
	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	ax, lchunk
	mov	bx, deleteOffset
	mov	cx, deleteCount
	call	LMemDeleteAt

	.leave
	ret

LMEMDELETEAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemGetChunkSize

C DECLARATION:	extern word
			_far _pascal LMemGetChunkSize(MemHandle mh,
							ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
LMEMGETCHUNKSIZE	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = chunk

	push	ds
	call	MemDerefDS
	mov_trash	bx, ax
	ChunkSizeHandle	ds, bx, ax
	pop	ds

	ret

LMEMGETCHUNKSIZE	endp

C_Common	ends

;-

C_System	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	LMemContract

C DECLARATION:	extern void
			_far _pascal LMemContractBlock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/91		Initial version

------------------------------------------------------------------------------@
LMEMCONTRACT	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = handle

	push	ds
	call	MemDerefDS
	call	LMemContract
	pop	ds
	ret

LMEMCONTRACT	endp

C_System	ends

;-

C_ChunkArray	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CHUNKARRAYCREATEAT_OLD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the poisition of old buggy CHUNKARRAYCREATAT
CALLED BY:	see CHUNKARRAYCREATEAT
PASS:		see CHUNKARRAYCREATEAT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/18/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CHUNKARRAYCREATEAT_OLD	proc	far	han:hptr, chan:word, esize:word,
					hsize:word
		.enter
		push	han
		push	chan
		push	esize
		push	hsize
		clr	ax
		push	ax
		call	CHUNKARRAYCREATEAT
		.leave
		ret

CHUNKARRAYCREATEAT_OLD	endp
	

global CHUNKARRAYCREATEAT_OLD:far
	ForceRef CHUNKARRAYCREATEAT_OLD

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayCreateAt

C DECLARATION:	extern ChunkHandle
			_far _pascal ChunkArrayCreateAt(MemHandle mh,
					    ChunkHandle chunkHan, 
					    word elementSize, word headerSize,
						ObjChunkFlags ocf);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYCREATEAT	proc	far	han:hptr, chan:word, esize:word,
					hsize:word,ocf:word
			uses	ds, si
	.enter
	mov	bx, han
	call	MemDerefDS

	mov	si, chan
	mov	cx, hsize
	mov	bx, esize
	mov	ax, ocf
	call	ChunkArrayCreate
	mov_trash	ax, si
	.leave
	ret

CHUNKARRAYCREATEAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayElementToPtr

C DECLARATION:	extern void _far *
			_far _pascal ChunkArrayElementToPtr(MemHandle mh,
					ChunkHandle chunk, word elementNumber,
					word _far *elementSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYELEMENTTOPTR	proc	far	mhan:hptr, chan:word, ele:word,
					eleSize:fptr
			uses	si, di, ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chan
	mov	ax, ele
	call	ChunkArrayElementToPtr
	mov	dx, ds
	mov_trash	ax, di
	tst	eleSize.segment
	jz	10$
	lds	si, eleSize
	mov	ds:[si], cx
10$:

	.leave
	ret

CHUNKARRAYELEMENTTOPTR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayPtrToElement

C DECLARATION:	extern word
			_far _pascal ChunkArrayPtrToElement(
					optr arr, void _far *element);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYPTRTOELEMENT	proc	far	arr:optr, element:fptr
				uses si, di, ds
	.enter

	lds	di, element
	mov	si, arr.chunk
	call	ChunkArrayPtrToElement

	.leave
	ret

CHUNKARRAYPTRTOELEMENT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayGetElement

C DECLARATION:	extern void
			_far _pascal ChunkArrayGetElement(MemHandle mh,
						ChunkHandle array,
						word token,
						void _far *buffer);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYGETELEMENT	proc	far	mhan:hptr, carray:word, token:word,
					buf:fptr
				uses si, ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, carray
	mov	ax, token
	mov	cx, buf.segment
	mov	dx, buf.offset
	call	ChunkArrayGetElement

	.leave
	ret

CHUNKARRAYGETELEMENT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayAppend

C DECLARATION:	extern void _far *
			_far _pascal ChunkArrayAppend(MemHandle mh,
							ChunkHandle chunk,
							word elementSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYAPPEND	proc	far	mh:hptr, chk:word, elsz:word
	uses	si, di, ds
	.enter
	mov	bx, ss:[mh]
	mov	si, ss:[chk]
	mov	ax, ss:[elsz]

	call	MemDerefDS
	call	ChunkArrayAppend
	mov	dx, ds		; dx:ax <- elt
	mov_tr	ax, di
	.leave
	ret

CHUNKARRAYAPPEND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayInsertAt

C DECLARATION:	extern void _far *
			_far _pascal ChunkArrayInsertAt(optr arr,
						    void _far *insertPointer,
						    word elementSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This routine exists solely for export from the .gp file at the
	position formerly occupied by the old, buggy version of
	CHUNKARRAYINSERTAT.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	9/93		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYINSERTAT_OLD	proc	far
	REAL_FALL_THRU	CHUNKARRAYINSERTAT
CHUNKARRAYINSERTAT_OLD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayInsertAt

C DECLARATION:	extern void _far *
			_far _pascal ChunkArrayInsertAt(optr arr,
						    void _far *insertPointer,
						    word elementSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jenny	9/93		Fixed not to trash si

------------------------------------------------------------------------------@
CHUNKARRAYINSERTAT	proc	far	arr:optr, insptr:fptr, esize:word
	uses di, si, ds
	.enter

	lds	di, insptr
	mov	si, arr.chunk
	mov	ax, esize
	call	ChunkArrayInsertAt
	mov	dx, ds
	mov_trash	ax, di

	.leave
	ret

CHUNKARRAYINSERTAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayDelete

C DECLARATION:	extern void
			_far _pascal ChunkArrayDelete(
					optr arr, void _far *element);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYDELETE	proc	far	arr:optr, element:fptr
				uses si, di, ds
	.enter

	lds	di, element
	mov	si, arr.chunk
	call	ChunkArrayDelete

	.leave
	ret

CHUNKARRAYDELETE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayDeleteRange

C DECLARATION:	extern void
			_far _pascal ChunkArrayDeleteRange(
					optr arr,
					word first,
					word count);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 5/ 6/92	Initial version

------------------------------------------------------------------------------@
CHUNKARRAYDELETERANGE	proc	far	arr:optr, firstElement:word, count:word
	uses	si, di, ds
	.enter

	mov	bx, arr.handle
	call	MemDerefDS
	mov	si, arr.chunk
	
	mov	ax, firstElement
	mov	cx, count

	call	ChunkArrayDeleteRange
	.leave
	ret

CHUNKARRAYDELETERANGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayGetCount

C DECLARATION:	extern word
			_far _pascal ChunkArrayGetCount(MemHandle mh,
							ChunkHandle chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYGETCOUNT	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = han, ax = chunk

	push	ds
	call	MemDerefDS
	xchg	si, ax
	call	ChunkArrayGetCount
	mov_trash	si, ax
	mov_trash	ax, cx
	pop	ds

	ret

CHUNKARRAYGETCOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayElementResize

C DECLARATION:	extern void
			_far _pascal ChunkArrayElementResize(MemHandle mh,
					ChunkHandle chunk, word element,
					word newSize);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYELEMENTRESIZE	proc	far	mhan:hptr, chan:word, element:word,
					newSize:word
				uses si, ds
	.enter

	mov	bx, mhan
	call	MemDerefDS
	mov	si, chan
	mov	ax, element
	mov	cx, newSize
	call	ChunkArrayElementResize

	.leave
	ret

CHUNKARRAYELEMENTRESIZE	endp

if FULL_EXECUTE_IN_PLACE
C_ChunkArray  ends
GeosCStubXIP    segment resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayEnum

C DECLARATION:	extern Boolean
		    _far _pascal ChunkArrayEnum(MemHandle mh,
				ChunkHandle chunk, void _far *enumData,
				Boolean _far (*callback)   /* TRUE = stop */
				    (void _far *element, void _far *enumData));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYENUM	proc	far	mh:hptr, chk:word, enumData:fptr,
					callback:fptr.far
				uses si, di, ds
	ForceRef	enumData
	ForceRef	callback
	.enter
	
	mov	dx, ds			;ds to pass to callback
	mov	bx, mh
	call	MemDerefDS
	mov	si, chk
	mov	bx, cs
	mov	di, offset _CHUNKARRAYENUM_callback
	call	ChunkArrayEnum

	mov	ax, 0
	jnc	done
	dec	ax
done:

	.leave
	ret

CHUNKARRAYENUM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayEnumRange

C DECLARATION:	extern Boolean
	    _far _pascal ChunkArrayEnumRange(
	    			MemHandle mh,
				ChunkHandle chunk, 
				word startElement,
				word count,
				void _far *enumData,
				Boolean _far (*callback),   /* TRUE = stop */
			    	(void _far *element, void _far *enumData));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 5/ 6/92	Initial version

------------------------------------------------------------------------------@
CHUNKARRAYENUMRANGE	proc	far	mh:hptr, chk:word, startElement:word,
					count:word,
					enumData:fptr, callback:fptr.far
				uses si, di, ds
	ForceRef	enumData
	ForceRef	callback
	.enter

	mov	ax, startElement
	mov	cx, count
	mov	dx, ds			;ds to pass to callback
	mov	bx, mh
	call	MemDerefDS
	mov	si, chk
	mov	bx, cs
	mov	di, offset _CHUNKARRAYENUM_callback
	call	ChunkArrayEnumRange

	mov	ax, 0
	jnc	done
	dec	ax
done:

	.leave
	ret

CHUNKARRAYENUMRANGE	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_CHUNKARRAYENUM_callback

DESCRIPTION:	Callback routine for FileEnum

CALLED BY:	FileEnum (via CHUNKARRAYENUM)

PASS:
	*ds:si - chunk array
	ds:di - element
	ss:bp - inherited variables
	dx - ds to pass

RETURN:
	carry - set to stop

DESTROYED:
	ax, cx, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

				Boolean _far (*callback)   /* TRUE = stop */
				    (void _far *element, void _far *enumData));

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

_CHUNKARRAYENUM_callback	proc	far	mh:hptr, chk:word,
						enumData:fptr,
						callback:fptr.far
	ForceRef	mh
	ForceRef	chk
	uses	dx
	.enter inherit far

	push	ds:[LMBH_handle]

	; push arguments to callback

	pushdw	dsdi			;element
	pushdw	enumData		;enumData

	mov	ds, dx
	pushdw	callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL

	pop	bx
	call	MemDerefDS

	; ax non-zero to stop

	tst	ax			;clears carry
	jz	done			;zero means leave carry clear
	stc
done:

	.leave
	ret

_CHUNKARRAYENUM_callback	endp

if FULL_EXECUTE_IN_PLACE
GeosCStubXIP    ends
C_ChunkArray  segment resource
endif

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArrayZero

C DECLARATION:	extern void
			_far _pascal ChunkArrayZero(MemHandle mh,
					    		word chunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYZERO	proc	far
	C_GetTwoWordArgs	bx, ax,  cx,dx	;bx = handle, ax = chunk

	push	ds
	call	MemDerefDS
	xchg	si, ax
	call	ChunkArrayZero
	mov_trash	si, ax
	pop	ds

	ret

CHUNKARRAYZERO	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ChunkArraySort

C DECLARATION:	extern void
		    _far _pascal ChunkArraySort(MemHandle mh,
				ChunkHandle chunk, word valueForCallback,
				sword _far (*callback)
					(void _far *el1, void _far *el2,
						    word valueForCallback));
			Note: The callback has to be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
CHUNKARRAYSORT	proc	far	mh:hptr, chk:word, valueForCB:word,
					callback:fptr.far
				uses si, ds
realDS	local	sptr	push	ds
	ForceRef	valueForCB
	ForceRef	callback
	ForceRef	realDS
	.enter

if      FULL_EXECUTE_IN_PLACE
        ;
        ; Make sure the fptr passed in is valid
        ;
EC <    pushdw  bxsi                                            >
EC <    movdw   bxsi, callback                                      >
EC <    call    ECAssertValidFarPointerXIP                      >
EC <    popdw   bxsi                                            >
endif

	mov	bx, mh
	call	MemDerefDS
	mov	si, chk
	mov	bx, bp
	mov	cx, SEGMENT_CS
	mov	dx, offset _CHUNKARRAYSORT_callback
	call	ChunkArraySort

	.leave
	ret

CHUNKARRAYSORT	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	_CHUNKARRAYSORT_callback

DESCRIPTION:	Callback routine for FileSort

CALLED BY:	ChunkArraySort (via CHUNKARRAYSORT)

PASS:
	ds:si - first element
	es:di - second element (ds = es)
	ss:bx - inherited variables

RETURN:	flags set so routine can jl, je or jg to determine whether the
	first element is less-than, equal-to, or greater-than the second.

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

		   sword (*callback) (void *el1, void *el2,
				      word valueForCallback));

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	jenny	8/13/92		Changed name, fixed to push callback

------------------------------------------------------------------------------@

_CHUNKARRAYSORT_callback	proc	far
				uses ds, es
	.enter inherit CHUNKARRAYSORT

	push	bp
	mov	bp, bx

	pushdw	dssi			;el1
	pushdw	esdi			;el2
	push	valueForCB		;valueForCallback

	mov	ds, realDS
	pushdw	callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
	cmp	ax, 0			;set flags

	pop	bp

	.leave
	ret

_CHUNKARRAYSORT_callback	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	ArrayQuickSort

C DECLARATION:	extern void
    			_pascal ArrayQuickSort(void *array, word count,
		 			       word elementSize,
			   		       word valueForCallback,
					       QuickSortParameters *parameters);
			Note: "parameters" *cannot* be pointing to the XIP
				movable code resource.
			      The callback routines have to be vfptrs for
				XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	jenny	8/92		Rewrote to use QuickSortParameters

------------------------------------------------------------------------------@

CArrayQuickSortParameters	struct
	CAQSP_compareCallback	fptr.far
	CAQSP_lockCallback	fptr.far
	CAQSP_unlockCallback	fptr.far
	CAQSP_realDS		sptr		; caller's dgroup
	CAQSP_common		QuickSortParameters
CArrayQuickSortParameters	ends

ARRAYQUICKSORT	proc	far	array:fptr, count:word, elementSize:word,
				valueForCB:word,
				parameters:fptr.QuickSortParameters
				uses si, ds
params	local	CArrayQuickSortParameters
	.enter

if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, parameters				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	ax, count
	cmp	ax, 1
	LONG jbe done
;
; Copy parameters to params structure on stack.
;
	mov	dx, ds			;save caller's dgroup
	lds	si, parameters
	segmov	es, ss
	lea	di, ss:[params].CAQSP_common
	mov	cx, size QuickSortParameters
	push	si
	rep	movsb			;copy parameters to stack
;
; Set up comparison callback.
;
	pop	si
	mov	ss:[params].CAQSP_common.QSP_compareCallback.segment, SEGMENT_CS
	mov	ss:[params].CAQSP_common.QSP_compareCallback.offset, \
			offset _ARRAYQUICKSORT_compareCallback 
	movdw	bxcx, ds:[si].QSP_compareCallback
	movdw	ss:[params].CAQSP_compareCallback, bxcx
	mov	ss:[params].CAQSP_realDS, dx
;
; Set up lock and unlock callbacks, if any.
;
	tst	ss:[params].CAQSP_common.QSP_lockCallback.segment
	jz	makeCall
if 0
EC <	tst	ss:[params].CAQSP_common.QSP_unlockCallback.segment		>
EC <	ERROR_Z	NO_UNLOCK_CALLBACK_SPECIFIED					>
endif
	mov	ss:[params].CAQSP_common.QSP_lockCallback.segment, SEGMENT_CS
	mov	ss:[params].CAQSP_common.QSP_lockCallback.offset, \
			offset _ARRAYQUICKSORT_lockCallback 
	movdw	bxcx, ds:[si].QSP_lockCallback
	movdw	ss:[params].CAQSP_lockCallback, bxcx

	mov	ss:[params].CAQSP_common.QSP_unlockCallback.segment, SEGMENT_CS
	mov	ss:[params].CAQSP_common.QSP_unlockCallback.offset, \
			offset _ARRAYQUICKSORT_unlockCallback
	movdw	bxcx, ds:[si].QSP_unlockCallback
	movdw	ss:[params].CAQSP_unlockCallback, bxcx
makeCall:
	lds	si, array
	mov_tr	cx, ax			; cx <- count
	mov	ax, elementSize
	mov	bx, valueForCB
	call	ArrayQuickSort
done:
	.leave
	ret

ARRAYQUICKSORT	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	_ARRAYQUICKSORT_compareCallback

DESCRIPTION:	Callback routine for ARRAYQUICKSORT

CALLED BY:	ArrayQuickSort (via ARRAYQUICKSORT)

PASS:		ds:si 	- first array element
		es:di 	- second array element (ds = es)
		bx	- value for callback
		ss:bp	- inherited CArrayQuickSortParameters

RETURN:		Flags set so ChunkArrayQuickSort can jl, je, or jg
		according to whether the first element is less than,
		equal to, or greater than the second

DESTROYED:	ax, bx, cx, dx, di, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

        word       (*QSP_compareCallback) (void *el1, void *el2,
					   word valueForCallback);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/13/92		Initial version

------------------------------------------------------------------------------@
_ARRAYQUICKSORT_compareCallback	proc	far
					uses ds, es
	.enter inherit ARRAYQUICKSORT

	pushdw	dssi			; el1
	pushdw	esdi			; el2
	push	bx			; valueForCallback
	mov	ds, ss:[params].CAQSP_realDS
	pushdw	ss:[params].CAQSP_compareCallback
	call	PROCCALLFIXEDORMOVABLE_PASCAL
	cmp	ax, 0			;set flags
	.leave
	ret

_ARRAYQUICKSORT_compareCallback	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	_ARRAYQUICKSORT_lockCallback

DESCRIPTION:	Callback routine for ARRAYQUICKSORT

CALLED BY:	ArrayQuickSort (via ARRAYQUICKSORT)

PASS:		ds:si 	- array element to lock
		bx	- value for callback
		ss:bp	- inherited CArrayQuickSortParameters

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

        void       (*QSP_lockCallback) (void *el1, word valueForCallback);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/13/92		Initial version

------------------------------------------------------------------------------@
_ARRAYQUICKSORT_lockCallback	proc	far	
					uses ax, bx, cx, dx, di, si, ds, es
	.enter inherit ARRAYQUICKSORT

	pushdw	dssi			; el
	push	bx			; valueForCallback
	pushdw	ss:[params].CAQSP_lockCallback
	mov	ds, ss:[params].CAQSP_realDS
	call	PROCCALLFIXEDORMOVABLE_PASCAL
	.leave
	ret

_ARRAYQUICKSORT_lockCallback	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	_ARRAYQUICKSORT_unlockCallback

DESCRIPTION:	Callback routine for ARRAYQUICKSORT

CALLED BY:	ArrayQuickSort (via ARRAYQUICKSORT)

PASS:		ds:si 	- array element to unlock
		bx	- value for callback
		ss:bp	- inherited CArrayQuickSortParameters

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

        void       (*QSP_unlockCallback) (void *el, word valueForCallback);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/13/92		Initial version

------------------------------------------------------------------------------@
_ARRAYQUICKSORT_unlockCallback	proc	far
					uses ax, bx, cx, dx, di, si, ds, es
	.enter inherit ARRAYQUICKSORT

	pushdw	dssi			; el
	push	bx			; valueForCallback
	pushdw	ss:[params].CAQSP_unlockCallback
	mov	ds, ss:[params].CAQSP_realDS
	call	PROCCALLFIXEDORMOVABLE_PASCAL
	.leave
	ret

_ARRAYQUICKSORT_unlockCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ELEMENTARRAYCREATEAT_OLD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the poisition of old buggy ELEMENTARRAYCREATAT
CALLED BY:	see ELEMENTARRAYCREATEAT
PASS:		see ELEMENTARRAYCREATEAT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/18/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ELEMENTARRAYCREATEAT_OLD proc	far	han:hptr, chan:word, esize:word,
					hsize:word
	.enter
	push	han
	push	chan
	push	esize
	push	hsize
	clr	ax
	push	ax
	call	ELEMENTARRAYCREATEAT
	.leave
	ret
ELEMENTARRAYCREATEAT_OLD	endp

global ELEMENTARRAYCREATEAT_OLD:far
	ForceRef ELEMENTARRAYCREATEAT_OLD

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ElementArrayCreateAt

C DECLARATION:	extern ChunkHandle
			_far _pascal ElementArrayCreateAt(MemHandle mh,
					    ChunkHandle chunkHan, 
					    word elementSize, word headerSize,
						ObjChunkFlags ocf);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ELEMENTARRAYCREATEAT	proc	far	han:hptr, chan:word, esize:word,
					hsize:word,ocf:word
			uses	ds, si
	.enter
	mov	bx, han
	call	MemDerefDS	; get segment into ds for ElementArrayCreate

	mov	si, chan
	mov	cx, hsize
	mov	bx, esize
	mov	ax, ocf
	call	ElementArrayCreate
	mov_trash	ax, si
	.leave
	ret

ELEMENTARRAYCREATEAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ElementArrayAddReference

C DECLARATION:	extern void
			_far _pascal ElementArrayAddReference(MemHandle mh,
						ChunkHandle array, word token);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ELEMENTARRAYADDREFERENCE	proc	far
	mov	dx, offset elementArrayAddRef
	jmp	elementArrayAddRefDeleteChangedCommon
ELEMENTARRAYADDREFERENCE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ElementArrayAddElement

C DECLARATION:	extern void
			_far _pascal ElementArrayAddElement(MemHandle mh,
					ChunkHandle array,
					void _far *element,
					word callbackData,
					Boolean _far (*callback)
						(void _far *elementToAdd,
						 void _far *elementFromArray,
						 dword valueForCallback));
		Note: "element" is vfptr if XIP'ed geode, and "callback" is
			also vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ELEMENTARRAYADDELEMENT	proc	far	mhan:hptr, carray:word, element:fptr,
					callbackData:dword, callback:fptr
	ForceRef	callbackData
				uses si, di, ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, callbackData				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	bx, mhan
	call	MemDerefDS
	mov	si, carray
	mov	cx, element.segment
	mov	dx, element.offset
	clr	bx				;assume no callback
	clr	di
	tst	callback.segment
	jz	common
	mov	bx, SEGMENT_CS			;pass our callback
	mov	di, offset _EAAE_callback
common:
	call	ElementArrayAddElement

	.leave
	ret

ELEMENTARRAYADDELEMENT	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_EAAE_callback

DESCRIPTION:	Callback for ELEMENTARRAYADDELEMENT

CALLED BY:	ELEMENTARRAYADDELEMENT

PASS:
	es:di - element to add
	ds:si - element from array
	ax - value for callback (bp for inherited variables)

RETURN:
	zero flag - set if elements equal

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
					Boolean _far (*callback)
						(void _far *elementToAdd,
						 void _far *elementFromArray,
						 dword valueForCallback));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	jenny	8/13/92		Fixed to push callback before call to PROCCALL...

------------------------------------------------------------------------------@

_EAAE_callback	proc	far		mhan:hptr, carray:word, element:fptr,
					callbackData:dword, callback:fptr
	.enter inherit far
	mov_trash	bp, ax

	pushdw	esdi		;elementToAdd
	pushdw	dssi		;elementFromArray
	pushdw	callbackData
	pushdw	callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL

	tst	ax

	.leave
	ret

_EAAE_callback	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ElementArrayDelete

C DECLARATION:	extern void
			_far _pascal ElementArrayDelete(MemHandle mh,
					ChunkHandle array,
					word token);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ELEMENTARRAYDELETE	proc	far	mh:hptr, array:word, token:word
	mov	dx, offset elementArrayDelete

elementArrayAddRefDeleteChangedCommon label near
	on_stack	retf
	uses	si, ds
	.enter
	
	on_stack	ds si retf
	
	mov	bx, ss:[mh]
	mov	si, ss:[array]
	mov	ax, ss:[token]
	call	MemDerefDS

	call	dx

	.leave
	ret

elementArrayDelete label near
	call	ElementArrayDelete
	retn

elementArrayAddRef label near
	call	ElementArrayAddReference
	retn
ELEMENTARRAYDELETE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ElementArrayElementChanged

C DECLARATION:	extern word
    ElementArrayElementChanged(MemHandle mh, ChunkHandle array, word token,
			       dword callbackData,
			       Boolean (*callback) (void *elementChanged,
					        void *elementToCompare,
					        dword valueForCallback));
	Note: "callbackData" cannot be pointing to the XIP movable code
		resource.
	      "callback" has to be vfptr for XIP.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ELEMENTARRAYELEMENTCHANGED	proc	far mhan:hptr, carray:word, token:word,
					callbackData:dword, callback:fptr
	ForceRef	callbackData
				uses si, di, ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, callbackData				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	bx, mhan
	call	MemDerefDS
	mov	si, carray
	mov	ax, token
	clrdw	bxdi				;assume no callback
	tst	callback.segment
	jz	common
	mov	bx, SEGMENT_CS				;pass our callback
	mov	di, offset _EAAE_callback
common:
	call	ElementArrayElementChanged

	.leave
	ret


ELEMENTARRAYELEMENTCHANGED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ElementArrayRemoveReference

C DECLARATION:	extern Boolean
			_far _pascal ElementArrayRemoveReference(MemHandle mh,
					ChunkHandle array,
					word token,
					dword callbackData,
					void _far (*callback)
						(void _far *element,
						 dword valueForCallback));
			Note: "callback" must be vfptr for XIP.
			      "callbackData" cannot be pointing to the XIP
			      movable code resource.
				
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ELEMENTARRAYREMOVEREFERENCE	proc	far	mhan:hptr, carray:word,
						token:word, callbackData:dword,
						callback:fptr
	ForceRef	callbackData
				uses si, di, ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in are valid
	;
EC <	pushdw	bxsi						>
EC <	movdw	bxsi, callbackData				>
EC <	call	ECAssertValidFarPointerXIP			>
EC <	movdw	bxsi, callback					>
EC <	tst	bx						>
EC <	jz	xipSafe						>
EC <	call	ECAssertValidFarPointerXIP			>
EC < xipSafe:							>
EC <	popdw	bxsi						>
endif

	mov	bx, mhan
	call	MemDerefDS
	mov	si, carray
	mov	ax, token
	clr	bx				;assume no callback
	clr	di
	tst	callback.segment
	jz	common
	mov	bx, SEGMENT_CS				;pass our callback
	mov	di, offset _EARR_callback
common:
	call	ElementArrayRemoveReference

	mov	ax, 0
	jnc	done
	dec	ax
done:

	.leave
	ret

ELEMENTARRAYREMOVEREFERENCE	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_EARR_callback

DESCRIPTION:	Callback for ELEMENTARRAYREMOVEREFERENCE

CALLED BY:	ELEMENTARRAYREMOVEREFERENCE

PASS:
	ds:di - element
	ax - value for callback (bp for inherited variables)

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
					void _far (*callback)
						(void _far *element,
						 dword valueForCallback));

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	jenny	8/13/92		Fixed to push callback before call to PROCCALL...

------------------------------------------------------------------------------@

_EARR_callback	proc	far		mhan:hptr, carray:word,
					token:word, callbackData:dword,
					callback:fptr
	.enter inherit far
	mov_trash	bp, ax

	pushdw	dsdi		;element
	pushdw	callbackData
	pushdw	callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL

	.leave
	ret

_EARR_callback	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	ElementArrayGetUsedCount

C DECLARATION:	extern word
		    ElementArrayGetUserCount(MemHandle mh, ChunkHandle array,
				    	dword callbackData,
					Boolean callback(void *element),
		    Note: "callback" is vfptr for XIP.
			  "callbackData" cannot be pointing to XIP movable
				code segment.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version
	cassie	10/95		fixed to check for null callback

------------------------------------------------------------------------------@
ELEMENTARRAYGETUSEDCOUNT	proc	far	mhan:hptr, chk:word,
						cbData:dword, callback:fptr
				uses si, di, ds
	ForceRef callback
	ForceRef cbData
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cbData					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	dx, ds			;dx passes ds
	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	mov	cx, bp
	clr	bx
	tst	callback.high	
	jz	10$
	mov	bx, SEGMENT_CS
	mov	di, offset _INDEXTOKEN_callback
10$:
	call	ElementArrayGetUsedCount

	.leave
	ret

ELEMENTARRAYGETUSEDCOUNT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	    ElementArrayUsedIndexToToken

C DECLARATION:	extern word
    ElementArrayUsedIndexToToken(MemHandle mh, ChunkHandle array, word index,
				    	dword callbackData);
					Boolean callback(void *element),
	Note: "callbackData" cannot be pointing to the XIP code resource.
	      "callback" must be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ELEMENTARRAYUSEDINDEXTOTOKEN	proc	far	mhan:hptr, chk:word, index:word,
						cbData:dword, callback:fptr
				uses si, di, ds
	ForceRef callback
	ForceRef cbData
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cbData					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	dx, ds			;dx passes ds
	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	mov	ax, index
	mov	cx, bp
	clr	bx
	jcxz	10$
	mov	bx, SEGMENT_CS
	mov	di, offset _INDEXTOKEN_callback
10$:
	call	ElementArrayUsedIndexToToken

	.leave
	ret

ELEMENTARRAYUSEDINDEXTOTOKEN	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	_INDEXTOKEN_callback

DESCRIPTION:	Callback routine for ElementArrayUsedIndexToToken

CALLED BY:	ElementArrayUsedIndexToToken (via ELEMENTARRAYUSEDINDEXTOTOKEN)

PASS:
	*ds:si - chunk array
	ds:di - element
	cx:dx - callback

RETURN:
	carry - set to stop

DESTROYED:
	ax, cx, dx, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

				Boolean _far (*callback)   /* TRUE = stop */
				    (void _far *element, dword enumData));

********Note that this callback is used by ElementArrayGetUsedCount as well,
	and in that routine, the parameters do not include "index", but
	because we are not referencing mhan or chk, which are placed on
	the stack after index. cbData and callback are at the bottom of
	the stack frame, so their locations do not cheange, even when
	index is not present.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	jenny	8/13/92		push callback before call to PROCCALL...
	cassie	10/95		added bp to the uses line

------------------------------------------------------------------------------@

_INDEXTOKEN_callback	proc	far	mhan:hptr, chk:word, index:word,
					cbData:dword, callback:fptr
	uses	ds, bp
	.enter inherit far

	mov	bp, cx

	; push arguments to callback

	pushdw	dsdi			;element
	pushdw	cbData			;enumData

	mov	ds, dx
	pushdw	callback
	call	PROCCALLFIXEDORMOVABLE_PASCAL

	; ax non-zero  -> carry set

	tst	ax			;clears carry
	jz	done			;zero means leave carry clear
	stc
done:
	.leave
	ret

_INDEXTOKEN_callback	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	    ElementArrayTokenToUsedIndex

C DECLARATION:	extern word
    ElementArrayTokenToUsedIndex(MemHandle mh, ChunkHandle array, word token,
					Boolean< callback(void *element),
				    	dword callbackData);
	Note: "callbackData" cannot be pointing to the XIP movable code
		resource.
	      "callback" has to be vfptr for XIP.
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
ELEMENTARRAYTOKENTOUSEDINDEX	proc	far	mhan:hptr, chk:word, token:word,
						cbData:dword, callback:fptr
				uses si, di, ds
	ForceRef callback
	ForceRef cbData
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, cbData
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	dx, ds			;dx passes ds
	mov	bx, mhan
	call	MemDerefDS
	mov	si, chk
	mov	ax, token
	mov	cx, bp
	clr	bx
	jcxz	10$
	mov	bx, SEGMENT_CS
	mov	di, offset _INDEXTOKEN_callback
10$:
	call	ElementArrayTokenToUsedIndex

	.leave
	ret

ELEMENTARRAYTOKENTOUSEDINDEX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NAMEARRAYCREATEAT_OLD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exported in the poisition of old buggy NAMEARRAYCREATAT
CALLED BY:	see NAMEARRAYCREATEAT
PASS:		see NAMEARRAYCREATEAT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/18/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NAMEARRAYCREATEAT_OLD	proc	far	han:hptr, chan:word, esize:word,
					hsize:word
		.enter
		push	han
		push	chan
		push	esize
		push	hsize
		clr	ax
		push	ax

		call	NAMEARRAYCREATEAT
		.leave
		ret
NAMEARRAYCREATEAT_OLD	endp

global NAMEARRAYCREATEAT_OLD:far
	ForceRef NAMEARRAYCREATEAT_OLD

COMMENT @----------------------------------------------------------------------

C FUNCTION:	NameArrayCreateAt

C DECLARATION:	extern ChunkHandle
			_far _pascal NameArrayCreateAt(MemHandle mh,
					    ChunkHandle chunkHan, 
					    word elementSize, word headerSize,
						ObjChuynkFlags ocf);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
NAMEARRAYCREATEAT	proc	far	han:hptr, chan:word, esize:word,
					hsize:word,ocf:word
			uses	ds, si
	.enter
	mov	bx, han
	call	MemDerefDS

	mov	si, chan
	mov	cx, hsize
	mov	bx, esize
	mov	ax, ocf
	call	NameArrayCreate

	mov_trash	ax, si
	.leave
	ret

NAMEARRAYCREATEAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	NameArrayAdd

C DECLARATION:	extern dword
		    _far _pascal NameArrayAdd(MemHandle mh, ChunkHandle array,
			      char _far *nameToAdd, word nameLength,
			      word flags, const void _far *data);
			Note:The fptrs *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
NAMEARRAYADD	proc	far	mhan:hptr, carray:word, nametoadd:fptr,
				nlen:word, flags:word, pdata:fptr
				uses si, di, ds, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, pdata					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, nametoadd					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	bx, mhan
	call	MemDerefDS
	mov	si, carray
	les	di, nametoadd
	mov	cx, nlen
	mov	bx, flags
	mov	dx, pdata.segment
	mov	ax, pdata.offset
	call	NameArrayAdd
	mov	dx, 0			;assume not newly added
	jnc	done
	dec	dx
done:

	.leave
	ret

NAMEARRAYADD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	NameArrayFind

C DECLARATION:	extern dword
		    _far _pascal NameArrayFind(MemHandle mh, ChunkHandle array,
			      char _far *nameToAdd, word nameLength,
			      void _far *returnData);
			Note: "nametoadd" *cannot* be pointing to the XIP 
				movable code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
NAMEARRAYFIND	proc	far	mhan:hptr, carray:word, nametoadd:fptr,
				nlen:word, pdata:fptr
				uses si, di, ds, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, nametoadd					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	bx, mhan
	call	MemDerefDS
	mov	si, carray
	les	di, nametoadd
	mov	cx, nlen
	mov	dx, pdata.segment
	mov	ax, pdata.offset
	call	NameArrayFind

	.leave
	ret

NAMEARRAYFIND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	NameArrayChangeName

C DECLARATION:	extern dword
		    _far _pascal NameArrayChangeName(MemHandle mh,
				ChunkHandle array, word nameToken,
				char _far *newName, word nameLength);
			Note:"newName" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
NAMEARRAYCHANGENAME	proc	far	mhan:hptr, carray:word, token:word,
					newname:fptr, nlen:word
				uses si, di, ds, es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, newname					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif

	mov	bx, mhan
	call	MemDerefDS
	mov	si, carray
	les	di, newname
	mov	cx, nlen
	mov	ax, token
	call	NameArrayChangeName

	.leave
	ret

NAMEARRAYCHANGENAME	endp

C_ChunkArray	ends



C_GeneralChange	segment	resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListAdd

C DECLARATION:	extern Boolean
			_far _pascal GCNListAdd(optr OD,
				ManufacturerID manufID, word changeType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTADD	proc	far	OD:optr,
				manufID:word, changeType:word

	clc
gcnListAddRemoveCommon	label	near
	on_stack	retf
	.enter
	on_stack	bp retf

	mov	bx, manufID
	mov	ax, changeType
	mov	cx, OD.handle
	mov	dx, OD.chunk
	jc	remove

	call	GCNListAdd
returnBoolean:
	mov	ax, 0			; set Boolean return value
	jnc	done
	dec	ax
done:

	.leave

	ret
remove:
	call	GCNListRemove
	jmp	returnBoolean
GCNLISTADD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListRemove

C DECLARATION:	extern Boolean
			_far _pascal GCNListRemove(optr OD,
				ManufacturerID manufID, word changeType);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTREMOVE	proc	far
	stc				; flag remove
	jmp	gcnListAddRemoveCommon
GCNLISTREMOVE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListSend

C DECLARATION:	extern word
			_far _pascal GCNListSend(
				ManufacturerID manufID, word changeType,
				EventHandle event,
				MemHandle dataBlock,
				word gcnListSendFlags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTSEND	proc	far	manufID:word, changeType:word,
				event:word, dataBlock:word, flags:word
	uses	bp

	.enter

	mov	bx, manufID
	mov	ax, changeType
	mov	cx, event
	mov	dx, dataBlock
	mov	bp, flags
	call	GCNListSend

	mov_tr	ax, cx		; ax <- # messages sent

	.leave

	ret
GCNLISTSEND	endp

;-------

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListAddToBlock

C DECLARATION:	extern Boolean
			_far _pascal GCNListAddToBlock(optr OD,
				ManufacturerID manufID, word changeType,
				MemHandle mh, ChunkHandle listOfLists);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
GCNLISTADDTOBLOCK	proc	far	OD:optr,
					manufID:word, changeType:word,
					mh:word, listOfLists:word

	clc
gcnListAddRemoveBlockCommon label near

	on_stack	retf
	uses	ds, di

	.enter

	on_stack	ds di bp retf

	mov	bx, mh
	call	MemDerefDS		; preserves flags
	mov	bx, manufID
	mov	ax, changeType
	mov	cx, OD.handle
	mov	dx, OD.chunk
	mov	di, listOfLists
	jc	remove
	call	GCNListAddToBlock
returnBoolean:
	mov	ax, 0			; set Boolean return value
	jnc	done
	dec	ax
done:

	.leave

	ret
remove:
	call	GCNListRemoveFromBlock
	jmp	returnBoolean
GCNLISTADDTOBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListRemoveFromBlock

C DECLARATION:	extern Boolean
			_far _pascal GCNListRemoveFromBlock(optr OD,
				ManufacturerID manufID, word changeType,
				MemHandle mh, ChunkHandle listOfLists);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
GCNLISTREMOVEFROMBLOCK	proc	far
	stc
	jmp	gcnListAddRemoveBlockCommon
GCNLISTREMOVEFROMBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListSendToBlock

C DECLARATION:	extern word
			_far _pascal GCNListSendToBlock(
				ManufacturerID manufID, word changeType,
				EventHandle event,
				MemHandle dataBlock,
				MemHandle mh, ChunkHandle listOfLists,
				word gcnListSendFlags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

------------------------------------------------------------------------------@
GCNLISTSENDTOBLOCK	proc	far	manufID:word, changeType:word,
					event:word,
					dataBlock:word,
					mh:word, listOfLists:word,
					flags:word

	uses	ds, di, bp

	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	bx, manufID
	mov	ax, changeType
	mov	cx, event
	mov	dx, dataBlock
	mov	di, listOfLists
	mov	bp, flags
	call	GCNListSendToBlock

	mov_tr	ax, cx			; ax <- # messages sent

	.leave

	ret
GCNLISTSENDTOBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListFindListInBlock

C DECLARATION:	extern ChunkHandle
			_far _pascal GCNListFindListInBlock(
				ManufacturerID manufID, word changeType,
				MemHandle mh, ChunkHandle listOfLists,
				Boolean createIfNotFound);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/91		Initial version

------------------------------------------------------------------------------@
GCNLISTFINDLISTINBLOCK	proc	far	manufID:word, changeType:word,
					mh:word, listOfLists:word,
					createIfNotFound:word
	uses	ds, di, bp

	.enter

	mov	bx, mh
	call	MemDerefDS
	mov	bx, manufID
	mov	ax, changeType
	mov	di, listOfLists

	tst	createIfNotFound	; (clears carry)
	jnz	haveFlag
	stc
haveFlag:

	call	GCNListFindListInBlock
					; returns chunk handle in si
	jc	haveChunk
	clr	si			; return NULL if not found
haveChunk:

	mov_tr	ax, si
	.leave
	ret
GCNLISTFINDLISTINBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNInitBlock

C DECLARATION:	extern ChunkHandle
			_far _pascal GCNInitBlock(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTCREATEBLOCK	proc	far
	clc
gcnCreateListCommon	label near
	on_stack	retf

	C_GetOneWordArg		bx,  cx,dx		; bx = handle

	push	ds, si
	on_stack	si ds retf

	call	MemDerefDS
	jc	createList

	call	GCNListCreateBlock	; returns si = list chunk
returnChunk:
	mov_tr	ax, si
	pop	ds, si

	ret

createList:
	call	GCNListCreateList
	jmp	returnChunk

GCNLISTCREATEBLOCK	endp

;-------

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListAddToList

C DECLARATION:	extern Boolean
			_far _pascal GCNListAddToList(optr OD,
					MemHandle mh, ChunkHandle listChunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTADDTOLIST	proc	far	OD:optr,
					mh:word, listChunk:word
	mov	ax, offset addToList
gcnListManipListCommon label near

	on_stack	retf
	uses	ds, si

	.enter

	on_stack	ds si bp retf

	mov	bx, mh
	call	MemDerefDS
	mov	si, listChunk		; *ds:si = list chunk
	mov	cx, OD.handle
	mov	dx, OD.chunk
	call	ax

	mov	ax, 0			; set Boolean return value
	jnc	done
	dec	ax
done:

	.leave

	ret

addToList:
	call	GCNListAddToList
	retn

removeFromList label near
	call	GCNListRemoveFromList
	retn

findItemInList label near
	call	GCNListFindItemInList
	retn
GCNLISTADDTOLIST	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListRemoveFromList

C DECLARATION:	extern Boolean
			_far _pascal GCNListRemoveFromList(optr OD,
					MemHandle mh, ChunkHandle listChunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTREMOVEFROMLIST	proc	far
	mov	ax, offset removeFromList	; signal remove
	jmp	gcnListManipListCommon
GCNLISTREMOVEFROMLIST	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListFindItemInList

C DECLARATION:	extern Boolean
			_far _pascal GCNListFindItemInList(optr OD,
					MemHandle mh, ChunkHandle listChunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTFINDITEMINLIST	proc	far
	mov	ax, offset findItemInList
	jmp	gcnListManipListCommon
GCNLISTFINDITEMINLIST	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListSendToList

C DECLARATION:	extern void
			_far _pascal GCNListSendToList(
				MemHandle mh, ChunkHandle listChunk,
				EventHandle event,
				MemHandle dataBlock,
				word gcnListSendFlags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTSENDTOLIST	proc	far	mh:word, listChunk:word,
					event:word,
					dataBlock:word,
					flags:word

	uses	ds, si, bp

	.enter

	mov	bx, mh
	call	MemDerefDS		; *ds:si = list chunk
	mov	si, listChunk
	mov	cx, event
	mov	dx, dataBlock
	mov	bp, flags
	call	GCNListSendToList

	.leave

	ret
GCNLISTSENDTOLIST	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListCreateList

C DECLARATION:	extern ChunkHandle
			_far _pascal GCNListCreateList(MemHandle mh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/91		Initial version

------------------------------------------------------------------------------@
GCNLISTCREATELIST	proc	far
	stc
	jmp	gcnCreateListCommon
GCNLISTCREATELIST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListDestroyBlock

C DECLARATION:	extern void
			_far _pascal GCNListDestroyBlock(
				MemHandle mh, ChunkHandle listOfLists);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

------------------------------------------------------------------------------@
GCNLISTDESTROYBLOCK	proc	far	mh:word, listOfLists:word
	clc
gcnDestroyListCommon label near
	on_stack	retf
	uses	ds, di, si

	.enter

	on_stack	ds di si retf

	mov	bx, mh
	call	MemDerefDS
	mov	di, listOfLists
	jc	destroyList

	call	GCNListDestroyBlock
done:
	.leave
	ret

destroyList:
	mov	si, listOfLists			; *ds:si = actual list!
	call	GCNListDestroyList
	jmp	done
GCNLISTDESTROYBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListDestroyList

C DECLARATION:	extern void
			_far _pascal GCNListDestroyList(
				MemHandle mh, ChunkHandle listChunk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version

------------------------------------------------------------------------------@
GCNLISTDESTROYLIST	proc	far
	stc
	jmp	gcnDestroyListCommon
GCNLISTDESTROYLIST	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListRelocateBlock

C DECLARATION:	extern void
			_far _pascal GCNListRelocateBlock(
				MemHandle mh, ChunkHandle listOfLists,
				MemHandle relocBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/3/92		Initial version

------------------------------------------------------------------------------@
GCNLISTRELOCATEBLOCK	proc	far	mh:word, listOfLists:word, rBlk:word
	mov	ax, offset relocateBlock	; relocate block
gcnRelocateCommon label near
	on_stack	retf
	uses	ds, di, si

	.enter

	on_stack	ds di si retf

	mov	bx, mh
	call	MemDerefDS
	mov	di, listOfLists		; *ds:di = list of lists (for block
					;	routines)
	mov	si, listOfLists		; *ds:si = list (for list routines)
	mov	dx, rBlk
	call	ax			; may return carry
	mov	ax, 0			; set Boolean return value
	jnc	exit			; (only good for GCNListUnRelocateBlock)
	dec	ax
exit:
	.leave
	ret

relocateBlock:
	call	GCNListRelocateBlock
	retn
relocateList	label	near
	call	GCNListRelocateList
	retn
unrelocateBlock	label	near
	call	GCNListUnRelocateBlock
	retn
unrelocateList	label	near
	call	GCNListUnRelocateList
	retn
GCNLISTRELOCATEBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListUnRelocateBlock

C DECLARATION:	extern Boolean
			_far _pascal GCNListUnRelocateBlock(
				MemHandle mh, ChunkHandle listChunk,
				MemHandle relocBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/3/92		Initial version

------------------------------------------------------------------------------@
GCNLISTUNRELOCATEBLOCK	proc	far
	mov	ax, offset unrelocateBlock	; unrelocate block
	jmp	gcnRelocateCommon
GCNLISTUNRELOCATEBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListRelocateList

C DECLARATION:	extern void
			_far _pascal GCNListRelocateList(
				MemHandle mh, ChunkHandle listChunk,
				MemHandle relocBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/3/92		Initial version

------------------------------------------------------------------------------@
GCNLISTRELOCATELIST	proc	far
	mov	ax, offset relocateList		; relocate list
	jmp	gcnRelocateCommon
GCNLISTRELOCATELIST	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GCNListUnRelocateList

C DECLARATION:	extern void
			_far _pascal GCNListUnRelocateList(
				MemHandle mh, ChunkHandle listChunk,
				MemHandle relocBlock);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/3/92		Initial version

------------------------------------------------------------------------------@
GCNLISTUNRELOCATELIST	proc	far
	mov	ax, offset unrelocateList	; unrelocate list
	jmp	gcnRelocateCommon
GCNLISTUNRELOCATELIST	endp

C_GeneralChange	ends

	SetDefaultConvention
