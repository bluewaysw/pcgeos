COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Object
FILE:		objectReloc.asm

ROUTINES:
	Name			Description
	----			-----------
   INT	ObjRelocate		Relocate an object
   INT	ObjUnRelocate		Un-relocate an object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to load a GEODE and execute it.

	$Id: objectReloc.asm,v 1.1 97/04/05 01:14:31 newdeal Exp $

------------------------------------------------------------------------------@

ObjectLoad segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocateObjBlock

DESCRIPTION:	Relocate all objects in an object block

CALLED BY:	INTERNAL
		FullObjLock

PASS:
	ds - segment of block to relocate
	cx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
		VMRT_LOADED_FROM_RESOURCE

RETURN:
	carry - set if error (non-ec only)

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

RelocateObjBlock	proc	near
	mov	dx, cx				;dx = type
	push	es

	; set the LMEM bit for the handle *now* so EC code won't die. doesn't
	; seem to be any advantage to doing this at the end as it was before...

	mov	bx,ds:[LMBH_handle]
	LoadVarSeg	es
	BitSet	es:[bx].HM_flags, HF_LMEM

if	MOVABLE_CORE_BLOCKS
	call	LockOwnersCoreBlockAndLibraries
endif

	segmov	es,ds
	push	ds:[OLMBH_inUseCount]		;save count
	mov	ds:[OLMBH_inUseCount],offset RelocateLow

	; relocate the object block output

	call	RelocOutput

	; for (each chunk in block) {

	mov	si,ds:LMBH_offset		;si points at handle
	mov	cx,ds:LMBH_nHandles		;cx is a counter
	mov	bp,ds:[si]			;ds:bp = flags for block

	;ds = es
	;ds:si - current position in handle table
	;ds:bp - current position in flags table
	;cx - count

relloop:
	mov	di,es:[si]
	inc	di
	jz	next
	dec	di
	jz	next

	;	if (OCF_IS_OBJECT) {
	;		ObjRelocate(chunk)

	mov	al, es:[bp]
	test	al, mask OCF_IS_OBJECT
	jz	next
	call	RelocOrUnRelocObj
	jc	error

next:
	add	si,2
	inc	bp
	loop	relloop

	segmov	ds,es
	pop	ds:[OLMBH_inUseCount]		;recover count
	BitSet	ds:[LMBH_flags],LMF_RELOCATED

	pop	es

EC <	call	ECLMemValidateHeapFar					>
	clc
NEC<done:								>
if	MOVABLE_CORE_BLOCKS
	mov	bx, ds:[LMBH_handle]
	call	UnlockOwnersCoreBlockAndLibraries
endif
	ret
error:
NEC <	segmov	ds,es				; return segment in ds	>
NEC <	pop	es:[OLMBH_inUseCount]		; recover count		>
NEC <	pop	es				;  and ES		>
NEC <	jmp	done				; Exit w/carry set	>
EC <	ERROR	CANNOT_RELOCATE						>
RelocateObjBlock	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	UnRelocateObjBlock

DESCRIPTION:	UnRelocate all objects in an object block

CALLED BY:	INTERNAL
		DetachObjBlock

PASS:
	ds - segment of block to relocate
	cx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
		VMRT_LOADED_FROM_RESOURCE

RETURN:
	carry - set if error (non-ec only)

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

UnRelocateObjBlock	proc	far
	mov	dx, cx				;dx = type
	push	es
	segmov	es,ds

if	MOVABLE_CORE_BLOCKS
	mov	bx, ds:[LMBH_handle]
	call	LockOwnersCoreBlockAndLibraries
endif

	BitClr	ds:[LMBH_flags],LMF_RELOCATED
	push	ds:[OLMBH_inUseCount]		;save count
	mov	ds:[OLMBH_inUseCount],offset UnRelocateLow

	; for (each chunk in block) {

	mov	si,ds:LMBH_offset		;si points at handle
	mov	cx,ds:LMBH_nHandles		;cx is a counter
	mov	bp,ds:[si]			;ds:bp = flags for block

	;ds:si - current position in handle table
	;ds:bp - current position in flags table
	;cx - count

Uloop:
	mov	di,es:[si]			;ES:DI <- addr of chunk
	inc	di				;If DI was -1, block is empty
	jz	Unext				; so go to next.
	dec	di				;If DI was 0, block is freed, 
	jz	Unext				; so go to next.

	;	if (OCF_IS_OBJECT) {
	;		ObjRelocate(chunk)

	mov	al, es:[bp]
	test	al, mask OCF_IS_OBJECT
	jz	Unext
	call	RelocOrUnRelocObj
	jc	error
Unext:
	add	si,2				;Go to the next chunk
	inc	bp				;go to next flag
	loop	Uloop				;branch

	segmov	ds,es

	; relocate the object block output (after doing the objects)

	call	RelocOutput

	pop	ds:[OLMBH_inUseCount]		;recover count

	clc					;no erro
	pop	es
NEC <done:								>
	mov	bx, ds:[LMBH_handle]
	call	UnlockOwnersCoreBlockAndLibraries
	ret
error:
NEC <	segmov	ds,es				;return segment in ds	>
NEC <	pop	ds:[OLMBH_inUseCount]		;recover inUseCount	>
NEC <	pop	es				; and ES		>
NEC <	jmp	done							>
EC <	ERROR 	CANNOT_UNRELOCATE					>
UnRelocateObjBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocOutput

DESCRIPTION:	Relocate the output field of an object block

CALLED BY:	INTERNAL

PASS:
	ds - object block
	es:[OLMBH_inUseCount] - routine to call (Reloc or UnReloc)


RETURN:
	none

DESTROYED:
	ax,bx,cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/30/92		Initial version

------------------------------------------------------------------------------@
RelocOutput	proc	near
	uses	dx
	.enter	
	movdw	cxdx, ds:[OLMBH_output]
	mov	bx, ds:[LMBH_handle]
	mov	al, RELOC_HANDLE
	call	es:[OLMBH_inUseCount]
	movdw	ds:[OLMBH_output], cxdx
	.leave
	ret

RelocOutput	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocOrUnRelocObj

DESCRIPTION:	Relocate an object

CALLED BY:	INTERNAL

PASS:
	es:[OLMBH_inUseCount] - routine to call (Reloc or UnReloc)
	*es:si - object
	al - ObjChunkFlags
	dx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE

RETURN:
	none

DESTROYED:
	ax, bx, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

RelocOrUnRelocObj	proc	near	uses cx, dx, si, bp, es

;	"object" is used by RelocOrUnRelocClass()

.warn -unref_local
object		local	lptr	\
		push	si
.warn @unref_local

relocType	local	VMRelocType	\
		push	dx
objflags	local	word	\
		push	ax
classoff	local	nptr
vdStart		local	word
vdEnd		local	word
	ForceRef vdEnd
	ForceRef relocType
	ForceRef objflags
	ForceRef classoff
	.enter

EC <	cmp	es:[OLMBH_inUseCount], offset RelocateLow	>
EC <	je	checkAfter					>
EC <	segxchg	ds, es						>
EC <	call	ECCheckLMemObject				>
EC <	segxchg	ds, es						>
EC <checkAfter:							>

	mov	bx,es:[si]			;es:bx = object
	call	RelocOrUnRelocAndLoadClass	;ds:si = class
NEC <	LONG jc	done						>

EC <	cmp	es:[OLMBH_inUseCount], offset RelocateLow	>
EC <	jne	alreadyChecked					>
EC <	segxchg	ds, es						>
EC <	push	si						>
EC <	mov	si, object					>
EC <	call	ECCheckLMemObject				>
EC <	pop	si						>
EC <	segxchg	ds, es						>
EC <alreadyChecked:						>

	; figure start and end of vardata for any relocations there may be
	; in there while we've got the bottom class handy..

	mov	di, ds:[si].Class_masterOffset
	tst	di			; any master parts?
	jz	addInstanceSize		; no -- vardata comes after instance
					;  data for bottom class
	mov	ax, es:[bx][di]		; ax <- value in master offset
	inc	di			; assume no data for final master part
	inc	di			;  so vardata starts after base struct
					;  (which assumes that master parts are
					;  built from the bottom up...)
	tst	ax			; correct?
	jz	haveStart		; yes, so di is start of vardata

	mov_tr	di, ax			; no. use start of last master part
					;  as thing to which to add size of
					;  last master part to get start of
					;  var data

addInstanceSize:
	add	di, ds:[si].Class_instanceSize

haveStart:
	add	di, bx
	mov	ss:[vdStart], di
	
	; loop to do all classes - ds:si = class

	call	RelocOrUnRelocClass
NEC <done:							>
	.leave
	ret

RelocOrUnRelocObj	endp
COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocOrUnRelocClass

DESCRIPTION:	Relocate or unrelocate at the class level

CALLED BY:	INTERNAL

PASS:
	ds:si - class
	es - block containing object
	ss:bp - inherited variables

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx, si, di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/24/92		Initial version

------------------------------------------------------------------------------@
RelocOrUnRelocClass	proc	far
	.enter inherit RelocOrUnRelocObj

EC <	tst	ds:[si].Class_superClass.segment	; MetaClass?	>
EC <	jz	classOK	; yes => must have no relocation table, so ok	>
EC <	test	ds:[si].Class_flags, mask CLASSF_NEVER_SAVED		>
EC <	ERROR_NZ	CLASS_AT_DS_SI_MARKED_NEVER_SAVED_SO_WHY_AM_I_RELOCATING_OR_UNRELOCATING_IT_BUB? >
EC <classOK:								>

	test	ds:[si].Class_flags, mask CLASSF_HAS_RELOC
	LONG jz	noCustomRelocation

	; send method to object to relocate itsself (for this class's part)
	; this message will call Reloc

	push	bp
	mov	dx, relocType
	segxchg	ds, es				;es=class, ds = obj
	mov	di, si				;es:di = class
	mov	si, object			;*ds:si = object

	; compute bx and di to pass

	mov	bp, di				;es:bp = class
	mov	ax,MSG_META_RELOCATE		;pass method in di. PCFOM
						; will shift to ax for us.
	cmp	ds:[OLMBH_inUseCount],offset RelocateLow
	jz	99$
	mov	ax,MSG_META_UNRELOCATE
99$:
	mov	ss:[TPD_dataAX], ax		;data to pass in AX

	mov	bx, ds:[si]
	mov	ss:[TPD_dataBX], bx		;data to pass in BX (base o'
						; object
	mov	di, es:[bp].Class_masterOffset
	tst	di
	jz	100$
	add	bx, ds:[bx][di]			;bx = di to send
100$:
	mov	di, bx
	;
	; Now point to the relocation handler's address, which is
	; immediately after the method table (or the CMethodDef table that
	; follows the method table for a C class).
	; 
	mov	bx, es:[bp].Class_methodCount	;calculate methodCount*6
	mov	cx, bx				; save *1
	shl	bx				;*2
	add	bx, cx				; bx = *3
	mov	cx, bx				; save for C class
	shl	bx				;  *6
	add	bx, bp
	test	es:[bp].Class_flags, mask CLASSF_C_HANDLERS
	pop	bp				;bp = frame pointer
	jnz	callCHandler

	mov	ax, ({fptr.far}es:Class_methodTable[bx]).offset
	mov	bx, ({fptr.far}es:Class_methodTable[bx]).segment
	call	ProcCallFixedOrMovable
done:
EC <	ERROR_C	ERROR_RETURNED_BY_RELOCATION_HANDLER			>
	ret

callCHandler:

	; C handler -- (pself, oself, message, VMRelocationType, frame)

	inc	cx				; round up to nearest word,
	andnf	cx, not 1			;  since that's what compilers
						;  like to do.
	add	bx, cx				; skip the CMethodDef table
	push	ds, di				; pass pself
	push	ds:[LMBH_handle], si		; pass oself
	push	ss:[TPD_dataAX]			; pass message
	push	dx				; pass reloc type
	push	bp				; pass inherited locals
	segmov	ds, es				; always a Good Thing to pass dgroup
						;  to a C routine (this assumes
						;  all C classes live in dgroup,
						;  of course, but we make that
						;  assumption elsewhere, too...)

	mov	ax, ({fptr.far}ds:Class_methodTable[bx]).offset
	mov	bx, ({fptr.far}ds:Class_methodTable[bx]).segment
	call	ProcCallFixedOrMovable

	tst	ax				;zero return (clears carry)?
	jz	done				;yes -- boogie
	stc					;no -- indicate error by setting
						; carry
EC <	jmp	done				;catch error in EC...	>
NEC <	ret					;return it in NEC...	>

noCustomRelocation:
	;
	; If no custom relocation, than just obey the relocation table for
	; the class, letting ObjRelocOrUnRelocSuper call us back for the
	; super class.
	; 
	.leave

	mov	di, object			;*es:di = object
	segxchg	ds, es
	xchg	si, di				;*ds:si = object, es:di = class
	FALL_THRU	ObjRelocOrUnRelocSuper

RelocOrUnRelocClass	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjRelocOrUnRelocSuper

DESCRIPTION:	Relocate an object's superclass

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	bp - inherited variables
	es:di - class

RETURN:
	carry - set if error

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/24/92		Initial version

------------------------------------------------------------------------------@
ObjRelocOrUnRelocSuper	proc	far	uses bx, si, di, ds, es
	.enter inherit RelocOrUnRelocObj

	segxchg	ds, es
	xchg	si, di				;ds:si = class, *es:di = obj

	mov	classoff, si

	; do instance data relocations

	push	ds:[si].Class_vdRelocTable
	mov	cx, ds:[si].Class_relocTable	;ds:si = reloc table
	jcxz	staticDataDone 			;no relocations -- done

	mov	bx, es:[di]			;es:bx = object
	mov	di, ds:[si].Class_masterOffset	;compute instance offset
	tst	di
	jz	noMaster
	mov	si, es:[bx][di]
	tst	si
	jz	staticDataDone
	add	bx, si				;es:bx = instance
noMaster:
	mov	si, cx				;ds:si = table

	; loop to do relocations -- ds:si = table, es:bx = object

relloop:
	lodsb					;al = type
		CheckHack <RELOC_END_OF_LIST eq 0>
	tst	al
	jz	staticDataDone
EC <	cmp	al,RELOC_LAST_LEGAL					>
EC <	ERROR_A	BAD_RELOCATION_TYPE					>
	push	bx
	mov_tr	cx, ax				;save type
	lodsw
	mov	di, bx
	add	di, ax				;es:di = target
	mov	ax, cx				;ax = type
	mov	cx, es:[di]			;dx:cx = data at target
	cmp	al,RELOC_ENTRY_POINT		;RELOC_ENTRY_POINT does dword
	je	relEP				;branch to read/write dword
	mov	bx, es:[LMBH_handle]		;bx = object handle 
	call	es:[OLMBH_inUseCount]
	pop	bx
	LONG jc	popSIDone			; Bail if error returned from
						; lower level handler (*after*
						; fixing stack!) -- Doug 5/17/93
	mov_tr	ax, cx				;store adjusted data
	stosw
	jmp	relloop

relEP:
	mov	dx, es:[di][2]
	mov	bx, es:[LMBH_handle]		;bx = object handle 
	call	es:[OLMBH_inUseCount]
	pop	bx
	LONG jc	popSIDone			; Bail if error returned from
						; lower level handler (*after*
						; fixing stack!) -- Doug 5/17/93
	mov_tr	ax, cx				;store adjusted data
	stosw
	mov_tr	ax, dx
	stosw
	jmp	relloop

	; done with normal instance data relocations -- now do vardata
	; instance relocations

staticDataDone:
	pop	si				;ds:si = table
	tst	si
	jz	toVardataDone
	test	objflags, mask OCF_VARDATA_RELOC
	jnz	doVardata
toVardataDone:
	jmp	vardataDone
doVardata:

	; recompute the end of the vardata area

	mov	bx, object
	mov	bx, es:[bx]
	ChunkSizePtr	es, bx, ax
	add	ax, bx
	mov	ss:[vdEnd], ax

varrelloop:
	lodsw					;al = type and tag
		CheckHack <RELOC_END_OF_LIST eq 0>
	test	ax, mask VORT_RELOC_TYPE
	jz	vardataDoneLeap
	mov_tr	cx, ax				;cx = tag and type
	lodsw					;ax = offset
	xchg	ax, cx				;ax = tag and type, cx = offset
	mov	bx, ss:[vdStart]
	push	si
	mov	si, ss:[vdEnd]
varrelFindLoop:
	cmp	bx, si				; hit end of vardata?
	jae	novardata			; yes

	mov	dx, es:[bx].VDE_dataType
	mov	di, dx				; see if all bits except
	xor	di, ax				;  VarDataFlags are the same
	and	di, not mask VarDataFlags	;  in both ax & dx, while
						;  preserving VDF_EXTRA_DATA
						;  in DX...
	jz	varrelFoundIt			; yes

	inc	bx				; assume no extra data
	inc	bx
	test	dx, mask VDF_EXTRA_DATA
	jz	varrelFindLoop

		CheckHack <offset VDE_entrySize eq 2>
	add	bx, es:[bx]
	dec	bx
	dec	bx
	jmp	varrelFindLoop

varrelFoundIt:
EC <	test	es:[bx].VDE_dataType, mask VDF_EXTRA_DATA		>
EC <	ERROR_Z	ILLEGAL_VARDATA_RELOCATION_OFFSET			>
EC <	push	ax							>
EC <	mov	ax, es:[bx].VDE_entrySize				>
EC <	sub	ax, size VarDataEntry					>
EC <	cmp	cx, ax							>
EC <	pop	ax							>
EC <	ERROR_AE	ILLEGAL_VARDATA_RELOCATION_OFFSET		>

	lea	di, es:[bx].VDE_extraData	; es:di <- start of extra data
	add	di, cx				;  point to proper place in same

	and	al, mask VORT_RELOC_TYPE
EC <	cmp	al,RELOC_LAST_LEGAL					>
EC <	ERROR_A	BAD_RELOCATION_TYPE					>
	mov	cx, es:[di]			;cx = data
	cmp	al,RELOC_ENTRY_POINT		;RELOC_ENTRY_POINT does dword
	je	varrelEP			;branch to read/write dword
	mov	bx, es:[LMBH_handle]
	call	es:[OLMBH_inUseCount]
	jc	popSIDone			; Bail if error returned from
						; lower level handler (*after*
						; fixing stack!) -- Doug 5/17/93
	mov_tr	ax, cx				;store adjusted data
	stosw
novardata:
	pop	si
	jmp	varrelloop

vardataDoneLeap:
	jmp	vardataDone
	
varrelEP:
	mov	dx, es:[di][2]
	mov	bx, es:[LMBH_handle]
	call	es:[OLMBH_inUseCount]
	jc	popSIDone			; Bail if error returned from
						; lower level handler (*after*
						; fixing stack!) -- Doug 5/17/93
	mov_tr	ax, cx				;store adjusted data
	stosw
	mov_tr	ax, dx
	stosw
	pop	si
	jmp	varrelloop

	; done with this class - move to next class

popSIDone:
	pop	si
	jmp	short done

vardataDone:

	mov	si, classoff
	mov	cx,ds:[si].Class_superClass.segment
	jcxz	done

	cmp	cx,VARIANT_CLASS		;variant class ?
	jz	variant
	mov	si, ds:[si].Class_superClass.offset
	mov	ds, cx

toSuper:
	call	RelocOrUnRelocClass
done:
	.leave
	ret

;---------------------

	; superclass is a variant -- get class from instance data

variant:
	mov	bx, ds:[si].Class_masterOffset
	mov	si, object
	mov	si, es:[si]
	add	si, es:[si][bx]

	; When unrelocating a class, the offset may be zero, but
	; the segment cannot be zero (with one exception). 
	; However, when relocating,
	; the entry point number of the class, which is stored in
	; the segment can be zero, but the ObjRelocationID will not
	; be zero (with one exception). So we must OR the segment
	; and offset and if the result is non-zero, then continue
	; with the reloc or unreloc. In the two exceptions I mentioned
	; above, unrelocating a class with a zero segment and relocating
	; a class with an ObjRelocationID of 0 (ORS_NULL), the desired
	; result is zero in both segment and offset which is already
	; the case.


	mov	cx,es:[si].MB_class.segment
	or	cx,es:[si].MB_class.offset
	jz	done		;if data null then done (carry clear)
	mov	bx, si
	call	RelocOrUnRelocAndLoadClass	; ds:si = class
EC  <	jmp	toSuper							>

NEC <	jnc	toSuper							>
NEC <	jmp	done							>

ObjRelocOrUnRelocSuper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OBJRELOCORUNRELOCSUPER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ObjRelocOrUnRelocSuper

CALLED BY:	Boolean _pascal ObjRelocOrUnRelocSuper(
			optr oself
			ClassStruct *class,
			word frame)
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
OBJRELOCORUNRELOCSUPER proc	far	oself:optr, 
					thisclass:fptr.ClassStruct,
					frame:word
		uses	ds, si, di, bp, es
		.enter
		movdw	bxsi, ss:[oself]
		les	di, ss:[thisclass]
		mov	bp, ss:[frame]	; we have no local variables, so Esp
					;  doesn't need us to preserve the
					;  bp it set up for us; it can recover
					;  without it.
		call	MemDerefDS
		call	ObjRelocOrUnRelocSuper
		mov	ax, 0
		jnc	done
		dec	ax
done:
		.leave
		ret
OBJRELOCORUNRELOCSUPER endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocOrUnRelocAndLoadClass

DESCRIPTION:	Relocate or unrelocate class pointer

CALLED BY:	RelocOrUnRelocObj

PASS:
	es:bx - instance
	es:[OLMBH_inUseCount] - routine to call (Reloc or UnReloc)

RETURN:
	class pointer relocated or unrelocated
	ds:si	= class pointer
	carry set if error relocating/unrelocating class pointer

DESTROYED:
	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

RelocOrUnRelocAndLoadClass	proc	near
	mov	cx,es:[bx].MB_class.offset	;low word in cx
	mov	dx,es:[bx].MB_class.segment	;high word in dx
	mov	al,RELOC_ENTRY_POINT
	push	bx
	mov	bx,es:[LMBH_handle]
EC <	call	ECCheckMemHandleFar					>
	cmp	es:[OLMBH_inUseCount], offset UnRelocateLow
	jne	callReloc
	mov	ds, dx			; Get the class pointer now
	mov	si, cx
callReloc:
	pushf
	call	es:[OLMBH_inUseCount]
NEC <	jc	error							>
	popf
	clc
	je	havePointer
	mov	ds, dx
	mov	si, cx
havePointer:
	pop	bx
if	ERROR_CHECK
	je	valid		;Branch if unrelocating, not relocating
HMA <	cmp	dx, HMA_SEGMENT						>
HMA <	je	valid							>
	cmp	dh, high MAX_SEGMENT
	ERROR_AE	CLASS_MUST_BE_IN_FIXED_RESOURCE
valid:
endif
	mov	es:[bx].MB_class.offset,cx
	mov	es:[bx].MB_class.segment,dx
	ret
NEC <error:								>
NEC <	popf								>
NEC <	stc								>
NEC <	jmp	havePointer						>
RelocOrUnRelocAndLoadClass	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjDoRelocation

DESCRIPTION:	Relocate a given word or double word

CALLED BY:	GLOBAL

PASS:
	al - relocation type (RelocationTypes)
		RELOC_HANDLE - resource ID to handle
		RELOC_SEGMENT - resource ID to segment
		RELOC_ENTRY_POINT - resource ID/entry # to dword
	bx - handle of block containing relocation
	cx - low word of relocation data
	dx - high word of relocation data (only used if RELOC_ENTRY_POINT)

RETURN:
	cx - low word, relocated
	dx - high word, relocated (if not RELOC_ENTRY_POINT then destroyed)
	carry set on error

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjDoRelocation	proc	far
if	MOVABLE_CORE_BLOCKS
	call	LockOwnersCoreBlockAndLibraries
endif
	push	ax, bx
	call	RelocateLow
	pop	ax, bx
if	MOVABLE_CORE_BLOCKS
	call	UnlockOwnersCoreBlockAndLibraries
endif
	ret

ObjDoRelocation	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjDoUnRelocation

DESCRIPTION:	UnRelocate a given word or double word

CALLED BY:	GLOBAL

PASS:
	al - relocation type (RelocationTypes)
		RELOC_HANDLE - resource ID to handle
		RELOC_SEGMENT - resource ID to segment
		RELOC_ENTRY_POINT - resource ID/entry # to dword
	bx - handle of block containing relocation
	cx - low word of relocation data
	dx - high word of relocation data (only used if RELOC_ENTRY_POINT)

RETURN:
	cx - low word, unrelocated
	dx - high word, unrelocated (if not RELOC_ENTRY_POINT then unchanged)
	carry set on error

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

ObjDoUnRelocation	proc	far
if	MOVABLE_CORE_BLOCKS
	call	LockOwnersCoreBlockAndLibraries
endif
	push	ax, bx
	call	UnRelocateLow
	pop	ax, bx
if	MOVABLE_CORE_BLOCKS
	call	UnlockOwnersCoreBlockAndLibraries
endif
	ret

ObjDoUnRelocation	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	RelocateLow

DESCRIPTION:	Relocate a given word or double word

CALLED BY:	ObjDoRelocation, RelocateObjBlock (via vector)

PASS:
	al - relocation type (RelocationTypes)
		RELOC_HANDLE - resource ID to handle
		RELOC_SEGMENT - resource ID to segment
		RELOC_ENTRY_POINT - resource ID/entry # to dword
	bx - handle of block containing relocation
	cx - low word of relocation data
	dx - high word of relocation data (only used if RELOC_ENTRY_POINT)
	owner's core block and imported libraries locked

RETURN:
	cx - low word, relocated
	dx - high word, relocated (if not RELOC_ENTRY_POINT then destroyed)

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

RelocateLow	proc	near

	mov	ah,ch
	andnf	cx,not mask RID_SOURCE
	andnf	ah,mask RID_SOURCE shr 8	;ah = relocation source
	jnz	notNull			;source = 0 -> null relocation

	; Null relocation

	cmp	al,RELOC_ENTRY_POINT		;if entry point must clear dx
	jnz	ret1
	clr	dx
ret1:
	xor	cx, cx				;clear cx, carry bit
	ret

notNull:
	cmp	ah,ORS_CURRENT_BLOCK shl (offset RID_SOURCE-8)
	jnz	notSelf

	; relocation to current block

	cmp	al,RELOC_HANDLE
EC <	ERROR_NZ	CANNOT_RELOC_CURRENT_BLOCK_TO_OTHER_THAN_HANDLE	>
NEC <	jne	error							>
	mov	cx,bx			;return handle
	ret

notSelf:
EC <	cmp	ah,ORS_KERNEL shl (offset RID_SOURCE-8)			>
EC <	ERROR_Z	KERNEL_RELOCATION_TYPE_IS_OBSOLETE			>

	push	ds
	LoadVarSeg	ds
	cmp	ah,ORS_OWNING_GEODE shl (offset RID_SOURCE-8)
	jnz	notOwningGeode

	; relocation to owning geode

	call	MemOwnerFar
	mov	ds,ds:[bx].HM_addr		;ds = owning geode

	cmp	cx,ds:[GH_resCount]
EC <	ERROR_AE	CANNOT_RELOC_OWNING_GEODE_TO_BAD_RESOURCE_ID	>
NEC <	jae	errorPopDS						>
	shl	cx,1				;*2 for index into table
	mov	bx,cx
	add	bx,ds:[GH_resHandleOff]
	mov	cx,ds:[bx]			;cx = handle
	cmp	al,RELOC_HANDLE
	jz	done
	LoadVarSeg	ds			;must get segment address
	mov	bx,cx
	mov	cx,ds:[bx].HM_addr
	cmp	al,RELOC_SEGMENT
	jz	done
	clc
	xchg	cx,dx
done:
	pop	ds
	ret

NEC <errorUnlockLibPopDS:						>
if not ERROR_CHECK and DELAY_LIBRARY_CORE_BLOCK_LOCK
	jcxz	errorPopDS	; => owning geode, so no unlock needed
	mov	bx, ds:[GH_geodeHandle]
	LoadVarSeg	ds, ax
	FastUnLock	ds, bx, ax
endif
NEC <errorPopDS:							>
NEC <	pop	ds							>
NEC <error:								>
NEC <	stc								>
NEC <	ret								>

	;--------------------
notOwningGeode:
	; ah = RID_SOURCE field of CX
	; bx = handle in which relocation is located
	; al = ObjRelocationType
	; cx = RID_INDEX
	; dx = additional info
	; 
	cmp	ah,ORS_LIBRARY shl (offset RID_SOURCE-8)
	LONG jnz notLibrary

	; relocation to a library. Find the thing's core block

	call	MemOwnerFar
	mov	ds, ds:[bx].HM_addr		;ds = owning geode
	mov	bx, ds:[GH_libOffset]		;assume explicit table
	cmp	cx, ds:[GH_libCount]		; in range?
	jb	getLibraryHandle		; yes

	mov	bx, ds:[GH_extraLibOffset]	; use implicit table
	sub	cx, ds:[GH_libCount]		; and adjust index accordingly
EC <	cmp	cx, ds:[GH_extraLibCount]				>
EC <	ERROR_AE	OBJ_RELOCATION_TO_INVALID_LIBRARY_NUMBER	>

getLibraryHandle:
	shl	cx, 1				;multiply by 2 to get offset
	add	bx, cx
	mov	bx, ds:[bx]			;bx = library handle
	LoadVarSeg	ds, cx

ife DELAY_LIBRARY_CORE_BLOCK_LOCK
	mov	ds, ds:[bx].HM_addr		;ds=library's core block
else
	FastLock1	ds, bx, cx, RLL1, RLL2
	mov	ds, cx
endif

libraryCommon:
	;
	; Fetch entry point from either a library or the owning geode.
	; ds	= core block (to be unlocked if library)
	; dx	= entry point #
	; cx	= 0 if owning geode, non-zero (ds) if library
	;
	; ERROR-CHECK PARAMETERS:
	; 	- we do not support handle or segment object relocations
	;	  to entry points.
	;	- entry point number must be within bounds of the table
	;
	CheckHack <RELOC_HANDLE lt RELOC_SEGMENT and \
		   RELOC_ENTRY_POINT gt RELOC_SEGMENT>

	cmp	al, RELOC_SEGMENT
EC <	ERROR_BE CANNOT_RELOC_LIBRARY_ENTRY_TO_HANDLE_OR_SEGMENT	>
NEC<	jbe	error							>
	cmp	dx, ds:[GH_exportEntryCount]
EC <	ERROR_AE	OBJ_RELOCATION_TO_INVALID_LIBRARY_ROUTINE_NUMBER >
NEC<	jae	errorUnlockLibPopDS					>

	shl	dx,1			; index far-pointer table
	shl	dx,1
	mov	bx, ds:[GH_exportLibTabOff]
	add	bx, dx

if DELAY_LIBRARY_CORE_BLOCK_LOCK
   	tst	cx			; library?
endif

	mov	cx, ds:[bx].offset
	mov	dx, ds:[bx].segment

if DELAY_LIBRARY_CORE_BLOCK_LOCK
   	jz	libraryCommonDone		; => owning geode entry point
						;  so no unlock needed

	push	bx
	mov	bx, ds:[LMBH_handle]
	LoadVarSeg	ds, ax
	FastUnLock	ds, bx, ax
	pop	bx
libraryCommonDone:
endif
	pop	ds

	; cx = new offset, dx = new segment

	clc
;ret2:
	ret

	;--------------------
notLibrary:
	; if a relocation to entry point in the owning geode
	; then use the same code as for an arbitrary library except use the
	; core block that we already have
	;
	; ah = RID_SOURCE field of CX
	; bx = handle in which relocation is located
	; al = ObjRelocationType
	; cx = RID_INDEX
	; dx = additional info
	; 
	cmp	ah,ORS_OWNING_GEODE_ENTRY_POINT shl (offset RID_SOURCE-8)
	jnz	notOwningGeodeEntryPoint

	; relocation to entry point in the owning geode

	call	MemOwnerFar
	mov	ds,ds:[bx].HM_addr		;ds = owning geode
if DELAY_LIBRARY_CORE_BLOCK_LOCK
   	clr	cx				; signal owning geode
endif
	jmp	libraryCommon

if DELAY_LIBRARY_CORE_BLOCK_LOCK
	FastLock2	ds, bx, cx, RLL1, RLL2
endif

	;--------------------
notOwningGeodeEntryPoint:
	;
	; ah = RID_SOURCE field of CX
	; bx = handle in which relocation is located
	; al = ObjRelocationType
	; cx = RID_INDEX
	; dx = additional info
	; 
	cmp	ah,ORS_VM_HANDLE shl (offset RID_SOURCE-8)
	jnz	notStateVM

	; relocation to VM handle of saved block

	cmp	al,RELOC_HANDLE
EC <	ERROR_NZ	CANNOT_RELOC_VM_HANDLE_TO_OTHER_THAN_HANDLE	>
EC <	push	bx							>
NEC<	LONG jne errorPopDS						>
	call	MemOwnerFar
	mov	ds,ds:[bx].HM_addr		;ds = owning geode
	mov	bx,ds:[PH_savedBlockPtr]
	LoadVarSeg	ds
savedLoop:
	tst	bx
	jz	hackMaster1
	cmp	cx,ds:[bx].HSB_vmID
	jz	dupFound
	mov	bx,ds:[bx].HSB_next
	jmp	savedLoop

dupFound:
	mov	cx,ds:[bx].HSB_handle
EC <	pop	bx							>
dupNotFoundButWeDontCare:
	pop	ds
	ret

hackMaster1:
	;
	; Deal with a relocation to a resource block in a data file. We
	; often get these when saving out data files containing objects that
	; are still on-screen. When the file is opened from a fresh instance
	; of the application, we can't find the proper memory handle again,
	; but that's ok because the pointer will get overwritten in a minute
	; anyway. If the file is re-opened from the same instance of the app
	; that saved it, we won't get here anyway b/c the saved block list
	; will contain the block being sought. Rather than choke in this
	; perfectly reasonable situation, we just relocate to 0 if we can't
	; find the memory handle when the relocation is in a VM block..
	; This is not a kludge. Really.
	; 
EC <	pop	bx			;make sure the block's a VM	>
EC <	mov	ds, ds:[bx].HM_addr	; block in a data file		>
EC <	test	ds:[LMBH_flags], mask LMF_IS_VM				>
EC <	ERROR_Z	BAD_RELOCATION_CANNOT_FIND_VM_HANDLE			>
	clr	cx			;set word to 0 (clears carry)
	jmp	dupNotFoundButWeDontCare

	;--------------------
notStateVM:
	;
	; ah = RID_SOURCE field of CX
	; bx = handle in which relocation is located
	; al = ObjRelocationType
	; cx = RID_INDEX
	; dx = additional info
	; 
	cmp	ah,ORS_NON_STATE_VM shl (offset RID_SOURCE-8)
	jnz	notNonStateVM

	; relocation to VM file stored in the block header

	cmp	al,RELOC_HANDLE
EC <	ERROR_NZ	CANNOT_RELOC_VM_HANDLE_TO_OTHER_THAN_HANDLE	>
NEC<	LONG jne	errorPopDS					>

	mov_tr	ax, cx			;ax = index
	call	VMObjIndexToMemHandle	;returns ax = mem handle

moveAndExit:
	mov_tr	cx, ax
	clc
	pop	ds
	ret

	;--------------------
notNonStateVM:
	;
	; ah = RID_SOURCE field of CX
	; bx = handle in which relocation is located
	; al = ObjRelocationType
	; cx = RID_INDEX
	; dx = additional info
	; 
	cmp	ah, ORS_UNKNOWN_BLOCK shl (offset RID_SOURCE-8)
EC <	ERROR_NZ	BAD_RELOCATION_TYPE				>
NEC<	LONG jne	errorPopDS					>

	mov_tr	ax, cx
	mov	cl, 4
	shl	ax, cl
	jmp	moveAndExit
RelocateLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UnRelocateLow

DESCRIPTION:	UnRelocate a given word or double word

CALLED BY:	ObjDoUnRelocation, UnRelocateObjBlock (via vector)

PASS:
	al - relocation type (RelocationTypes)
		RELOC_HANDLE - handle to resource ID
		RELOC_SEGMENT - segment to resource ID
		RELOC_ENTRY_POINT - dword to resource ID/entry #
	bx - handle of block containing relocation
	cx - low word of relocation data
	dx - high word of relocation data (only used if RELOC_ENTRY_POINT)
	owner's core block and imported libraries locked

RETURN:
	carry	- set if error
	cx - low word, unrelocated
	dx - high word, unrelocated (if not RELOC_ENTRY_POINT then unchanged)

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

UnRelocateLow	proc	near

	; check for value 0

	tst	cx
	jnz	notZero
	
	cmp	al,RELOC_ENTRY_POINT	; need we check DX too? (only double-
					;  word relocation)
	jnz	10$			; no -- just use ORS_NULL
	
	tst	dx
	jnz	notZero
10$:
	; Please don't get any ideas about "optimizing" this by realizing
	; that a plain "or" will clear the carry -- esp has the right to delete
	; the "ornf" altgeher since the only affect is to change the carry, &
	; hence this actually saves byes over an "or".  Aside from that, I've
	; already spent some 3 hours tracking down a problem here, & would
	; appreciate not have to do it gain.  In summary, keep your mitts off!
	; Thank you.  -- Doug 5/1793
	;
	or	cx,ORS_NULL shl offset RID_SOURCE	; (clears carry)
	ret

notZero:
	push	ax, di, bp, ds, es, si
	cbw				; clear ah (1-byte inst)
	mov_tr	bp,ax			;bp hold type (1-byte inst)

	; Convert whatever type is given into a handle (since this is
	; easy to deal with).

	cmp	bp,RELOC_HANDLE
	jz	gotHandle

	; convert segment to handle -- since all the block types that we
	; relocate have the handle at the beginning (except the kernel)

	cmp	bp,RELOC_ENTRY_POINT		;entry point has segment in dx
	jnz	segmentInCX
	xchg	cx,dx				;cx = seg, dx = off
segmentInCX:
	mov	si, cx				;si <- seg for export table
						; comparison

HMA <	cmp	cx, HMA_SEGMENT			;check hi-mem segment	>
HMA <	je	fixed							>
	cmp	ch, high MAX_SEGMENT		;movable?
	jb	fixed				;no -- deal with segment
	
	; "segment" is handle shifted right four bits. shift it back again...

	mov_tr	ax, cx
	mov	cl, 4			;shift left four times to multiply by
	shl	ax, cl			;16 to get number of bytes
	mov	cx, ax
	jmp	gotHandle

fixed:
	call	MemSegmentToHandle		;returns cx = handle
EC <	ERROR_NC	ILLEGAL_SEGMENT_VALUE				>
NEC <	jnc	errorPop						>

	; cx contains the handle of the relocation -- convert to type

	; check for ORS_CURRENT_BLOCK

gotHandle:
	; cx = handle of target
	; dx = offset, if far pointer
	; bx = handle of block in which relocation sits
	; bp = ObjRelocationType
	; 
	cmp	bx,cx
	jnz	notCurrentBlock
	cmp	bp,RELOC_ENTRY_POINT
EC <	ERROR_Z	CANNOT_UNRELOCATE_CURRENT_BLOCK_TO_ENTRY_POINT		>
NEC <	je	errorPop						>
	mov	cx,ORS_CURRENT_BLOCK shl offset RID_SOURCE
popAndReturn:
	clc
NEC <popAndReturnNoCLC:							>
	pop	ax, di, bp, ds, es, si
	ret

NEC <errorPop:								>
NEC <	stc								>
NEC <	jmp	popAndReturnNoCLC					>

	; check for resource

	;--------------------
notCurrentBlock:
	; cx = handle of target
	; dx = offset, if far pointer
	; bx = handle of block in which relocation sits
	; bp = ObjRelocationType
	; 
	LoadVarSeg	ds

	push	cx				;save reloc handle
	xchg	bx, cx				;bx = handle to reloc,
						; cx = handle holding reloc
	call	HandleToID
	xchg	bx, cx				;bx = data block, cx = ID
	mov	es, ax				;es <- core block of target's
						; owner
	LONG jc	notResource
	

	; figure whose export table we should look at by seeing who owns the
	; block that holds the entry point itself.
	mov	di, bx
	call	MemOwnerFar
	xchg	bx, di				;bx = block, di = owner
	cmp	di, es:[GH_geodeHandle]		;target owned by same geode
						; as owns the data block?
	je	isOwningGeode

	; to deal with the target being a shared resource handle while the
	; object block is an unshared block owned by the second instance of
	; an app, we need to compare the file handles for the two geodes
	; to see if they refer to the same geode (XXX: THIS WON'T WORK IF THE
	; TWO GEODES AREN'T KEEP_FILE_OPEN; for practical purposes, however,
	; all geodes that might require unrelocating will have discardable
	; resources...)

	mov	ax, es:[GH_geoHandle]		; fetch file handle for target's
						;  owner
FXIP <	tst	ax							>
FXIP <	jz	UnotOwningGeode						>
	push	ds
if MOVABLE_CORE_BLOCKS
EC <	tst	ds:[di].HM_lockCount					>
EC <	ERROR_Z	OWNER_CORE_BLOCK_NOT_LOCKED				>
endif
	mov	ds, ds:[di].HM_addr		; locked by caller
	cmp	ax, ds:[GH_geoHandle]
	pop	ds
	jne	UnotOwningGeode			;nope. must be a library

isOwningGeode:

	cmp	bp,RELOC_ENTRY_POINT
	pop	di				;discard handle
	jz	ownerEntryPoint
	; if not entry point, CX already contains the resource ID, which
	; must be all that's needed.
	ornf	cx,ORS_OWNING_GEODE shl offset RID_SOURCE

	push	bx
	mov	bx, es:[GH_geodeHandle]
	call	MemUnlock
;;ES will be popped in a moment, so no need for this....
;;EC <	call	NullES							>
	pop	bx				;it's already locked by caller
	jmp	popAndReturn

	; entry point in the owning geode, search library table

ownerEntryPoint:
	mov	cx,ORS_OWNING_GEODE_ENTRY_POINT shl offset RID_SOURCE
	LoadVarSeg	ds
	jmp	findLibraryEntry

	; The item is a resource, but is not one of ours or one of our
	; libraries.   HELP!

NEC <noMatchPanic:							>
if DELAY_LIBRARY_CORE_BLOCK_LOCK
NEC <	xchg	ax, bx		; bx <- library core			>
NEC <	call	MemUnlock						>
NEC <	mov_tr	bx, ax							>
endif
NEC <	pop	cx		; handle...				>
NEC <	jmp	errorPop						>


	; handle is a resource from a different owner (es = owner core block)
	; check for ORS_LIBRARY
	; on stack: ax, cx, ds, es
	; di = owner of data block in which relocation itself resides.

UnotOwningGeode:
	mov	ax,es:[GH_geodeHandle]		;ax = handle to match
	mov	es,ds:[di].HM_addr		;es = core block of client
	mov	di,es:[GH_libOffset]		;es:di = library table
	mov	cx,es:[GH_libCount]
	repne scasw
	jne	checkExtraLibs

	sub	cx, es:[GH_libCount]
	not	cx

foundLibrary:
	; cx = library # (either explicitly imported or implicitly...)
	inc	sp				; discard saved data block
	inc	sp				;  handle

	mov_tr	di, ax
	mov	es, ds:[di].HM_addr		;es <- target owner's core
						; block (needed in libDone)

	ornf	cx,ORS_LIBRARY shl offset RID_SOURCE
	cmp	bp,RELOC_ENTRY_POINT
	jnz	libDone				;if not entry point, all we
						; can need is the library #
 						;else we need to find the entry
						; point # as well.

	; search for entry point
	; es = segment of target owner's core block
	; ds = dgroup

findLibraryEntry:
	push	cx
	xchg	ax,si				;ax = segment of entry point
	mov	di,es:[GH_exportLibTabOff]	;es:di = exported lib table

	mov	cx,es:[GH_exportEntryCount]
	shl	cx

	; cx = #entry points * 2
	; es:di = entry point list
	; ax = segment to match, dx = offset to match

findEntryLoopNoMatchCheckCX:
	jcxz	notFound			;if no entry points then not
						;found
findEntryLoopNoMatch:
	clr	si				; clear "partial match" flag
findEntryLoop:
	xchg	ax, dx
	scasw
	loopne	findEntryLoopNoMatch
	jne	notFound			;if words not equal, then
						; we fell through the loopne
						; because cx=0 => not found
	not	si				;set "partial match" flag
	test	cx, 1				;if cx odd then we're in the
	jnz	findEntryLoop			; middle of our double word
						; compare, loop to finish it
	tst	si				;since we're here the second
	jnz	findEntryLoopNoMatchCheckCX	; word matched, if the first
						; word matched then a match
						; else continue looping

	; match found -- find the entry point #
	; es:di points at entry after the match
	; cx = (# of entries *2) - (match's entry # * 2)

	xchg	ax, cx					; 1b
	shr	ax					; 2b
	sub	ax, es:[GH_exportEntryCount]		; 4b
	not	ax					; 2b
	xchg	dx, ax					; 1b -- dx = entry #
	pop	cx					; 1b
libDone:
	push	bx
	mov	bx, es:[GH_geodeHandle]
	call	MemUnlock	; (ES popped in a moment, so no NullES)
	pop	bx
	jmp	popAndReturn

checkExtraLibs:
	mov	cx, es:[GH_extraLibCount]
	mov	di, es:[GH_extraLibOffset]
	repne	scasw
EC <	ERROR_NZ	CANNOT_UNRELOCATE_UNKNOWN_RESOURCE_HANDLE	>
NEC <	LONG jnz noMatchPanic						>
	sub	cx, es:[GH_extraLibCount]
	not	cx
	add	cx, es:[GH_libCount]	; offset by # explicitly-imported libs
	jmp	foundLibrary

notFound:
EC <	ERROR	CANNOT_UNRELOCATE					>
NEC <	pop	cx							>
NEC <	jmp	errorPop						>

	; not a resource, check for a duplicated block (ds = idata)

notResource:
	pop	cx				;recover data handle
	call	MemOwnerFar			;bx = owner
	mov	es,ds:[bx].HM_addr		;es = core block of owner
	mov	di,es:[PH_savedBlockPtr]
UsavedLoop:
	tst	di				;at end of list ?
	jz	notDuplicate
	cmp	cx,ds:[di].HSB_handle
	jz	UdupFound
	mov	di,ds:[di].HSB_next
	jmp	UsavedLoop

UdupFound:
	cmp	bp,RELOC_ENTRY_POINT
EC <	ERROR_Z	CANNOT_UNRELOCATE_VM_HANDLE_TO_ENTRY_POINT		>
NEC <	LONG je	errorPop						>
	mov	cx,ds:[di].HSB_vmID
	ornf	cx,ORS_VM_HANDLE shl offset RID_SOURCE
	jmp	popAndReturn

	; last ditch effort -- it must be a VM memory handle

notDuplicate:
	mov	bx, cx				;bx = handle to relocate
	push	bx
	mov	bx, ds:[bx].HM_owner
	cmp	ds:[bx].HG_type, SIG_VM
	pop	bx
	jnz	unknownBlock

	call	VMObjMemHandleToIndex
	ornf	ax, ORS_NON_STATE_VM shl offset RID_SOURCE
movePopAndReturn:
	mov	cx, ax
	jmp	popAndReturn

	; we have no idea what this block is -- just preserve the handle so
	; that at least we work in VM cases

unknownBlock:
	mov	ax, cx
	mov	cl, 4
	shr	ax, cl
	ornf	ax, ORS_UNKNOWN_BLOCK shl offset RID_SOURCE
	jmp	movePopAndReturn

UnRelocateLow	endp

;------------------------------------------------------

ObjectLoad ends

ObjectFile segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjRelocateEntryPoint

DESCRIPTION:	Relocate an entry point from a structure that identifies
		the geode from which the object comes

CALLED BY:	INTERNAL

PASS:
	On the stack, pushed in this order:
		dword - pointer to EntryPointRelocation structure

RETURN:
	dx:ax - entry point, or 0 if geode not available

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 3/92		Initial version

------------------------------------------------------------------------------@
OBJRELOCATEENTRYPOINT	proc	far	relocPtr:fptr
			uses bx, cx, di, es
	.enter

	; find the geode in the system

	les	di, relocPtr			;name
	mov	ax, GEODE_NAME_SIZE		;# chars to match
	clr	cx
	clr	dx
	call	GeodeFind
	jnc	notFound

	; lock the core block for the current geode to make sure that this
	; is an imported library (or the geode itsself)

	mov	cx, bx				;cx = geode to relocate to
	mov	bx, ss:TPD_processHandle
	cmp	bx, cx
	jz	geodeOK

	; lock the core block to search the library table

	call	MemLock
	mov	es, ax				;es = current process
	mov_tr	ax, cx
	mov	cx, es:[GH_libCount]
	mov	di, es:[GH_libOffset]
	repne	scasw
	jz	foundLib

	mov	cx, es:[GH_extraLibCount]
	mov	di, es:[GH_extraLibOffset]
	repne	scasw
	jz	foundLib

	call	MemUnlock
notFound:
	clrdw	dxax
	jmp	done

foundLib:

	; the library is found

	call	MemUnlock
EC <	call	NullES							>
	mov_tr	cx, ax				;cx = library

geodeOK:

	; cx = library, lock its core block and get the entry point

	mov	bx, cx
	les	di, relocPtr
	mov	ax, es:[di].EPR_entryNumber
	call	ProcGetLibraryEntry		;bxax = entry point
	mov	dx, bx				;dxax = entry point

done:
	.leave
	ret @ArgSize

OBJRELOCATEENTRYPOINT	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjUnRelocateEntryPoint

DESCRIPTION:	Unrelocate an entry point to a structure that identifies
		the geode from which the object comes

CALLED BY:	INTERNAL

PASS:
	On the stack, pushed in this order:
		dword - pointer to EntryPointRelocation structure (to fill in)
		dword - entry point

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 3/92		Initial version

------------------------------------------------------------------------------@
OBJUNRELOCATEENTRYPOINT	proc	far	entryPoint:fptr, relocPtr:fptr
			uses ax, bx, cx, dx, di, ds, es
	.enter

	; call the general routine to help us

	mov	bx, ss:[TPD_processHandle]
	movdw	dxcx, entryPoint
	mov	al, RELOC_ENTRY_POINT
	call	ObjDoUnRelocation
EC <	ERROR_C	ILLEGAL_SEGMENT_VALUE					>

	mov	ax, cx
	and	ax, mask RID_SOURCE
	cmp	ax, ORS_OWNING_GEODE_ENTRY_POINT shl offset RID_SOURCE
	jz	gotGeode

	; get library handle

	push	bx
	and	cx, mask RID_INDEX
	call	MemLock				;lock core block
	mov	ds, ax
	mov	bx, ds:[GH_libOffset]
	cmp	cx, ds:[GH_libCount]
	jb	getLibraryHandle
	mov	bx, ds:[GH_extraLibOffset]
	sub	cx, ds:[GH_libCount]
EC <	cmp	cx, ds:[GH_extraLibCount]				>
EC <	ERROR_AE	OBJ_RELOCATION_TO_INVALID_LIBRARY_NUMBER	>
getLibraryHandle:
	shl	cx				;multiply by 2 to get offset
	add	bx, cx
	mov	ax, ds:[bx]			;ax = library handle
	pop	bx
	call	MemUnlock
EC <	call	NullDS							>
	mov_tr	bx, ax

gotGeode:

	; bx = geode handle, dx = entry point number

	les	di, relocPtr
	mov	es:[di].EPR_entryNumber, dx
	mov	ax, GGIT_PERM_NAME_ONLY
	call	GeodeGetInfo

	.leave
	ret @ArgSize

OBJUNRELOCATEENTRYPOINT	endp

ObjectFile ends
