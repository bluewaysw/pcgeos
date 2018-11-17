COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Object
FILE:		objectVarData.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines for the ObjectVariableStorage mechanism.

NOTES:
	Be careful with pointers to "data" in this file, & when using
	the variable data mechanism in general;  all external routines
	take & return pointers to the EXTRA DATA which is stored in the
	data entry, not to the start of the data entry (which begins
	with the structure VarDataEntry.  Also -- for data entries having
	no extra data, the ptr passed & returned is the start of the 
	data entry + size VarDataEntry).   This make life much simpler for
	developers, as they don't have to put a "VarDataEntry" struct on
	the front end of an variable data structures they have, both for
	setting variable data, & accessing it.  On the other hand, it
	can make coding this stuff more confusing, particularly as some
	of the internal routines work with ptrs to the start of the
	data entries.

	THEREFORE, when looking through & documenting this code:

		"data entry" means a ptr to a VarDataEntry structure.
		"extra data" means a ptr PAST the VarDataEntry structure.

	-- Doug

	$Id: objectVarData.asm,v 1.1 97/04/05 01:14:42 newdeal Exp $

------------------------------------------------------------------------------@

kcode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAndCheckVarDataStartEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute start and end of an object's variable data storage
		and check if there is any variable data.

CALLED BY:	INTERNAL
			ObjVarFindData
			ObjVarScanData
			ObjVarDeleteDataRange
			ObjVarCopyDataRange

PASS:		*ds:si - object

RETURN:		ds:bx - start of variable data storage
		ds:bp - end of variable data storage
		status flags - set for 'cmp start (bx), end (bp)'
			Z set if no variable data

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAndCheckVarDataStartEnd	proc	far
	uses	ax, si, es, di
	.enter
EC <	call	ECLMemValidateHandle					>
	test	ds:[LMBH_flags], mask LMF_RELOCATED	; object fully
							;  relocated?
	jz	handleRelocation		; no -- don't load class into
						;  es:di, as this loads ES with
						;  a bogus segment...
getClass:
EC <	call	ECCheckLMemObject					>
	mov	si, ds:[si]			; deref. object
	les	di, ds:[si].MB_class		; es:di = class
haveClass:
EC <	call	ECCheckClass						>
	mov	bx, es:[di].Class_masterOffset	; bx offset of master offset
	mov	ax, bx				; (save it in case empty)
	tst	bx
	jz	addInstanceSize			; if no master offset, subclass
						;	of MetaClass, use bx=0
	mov	ax, ds:[si][bx]			; ax = master offset
	inc	bx				; assume no data for final
	inc	bx				;  master part so vardata starts
	tst	ax				;  after base structure (which
	jz	haveStart			;  assumes that master parts
						;  are built from the bottom
						;  up...)
	mov_tr	bx, ax

addInstanceSize:
	add	bx, es:[di].Class_instanceSize	; bx = offset w/in chunk to
						;  beginning of variable data
haveStart:
	add	bx, si				; bx = start of vardata

	ChunkSizePtr	ds, si, bp		; bp = size of object chunk
	add	bp, si				; bp = end of variable data
	cmp	bx, bp				; any variable data?
EC <	ERROR_A	OVS_SIZE_OF_VAR_DATA_ENTRIES_GREATER_THAN_VAR_DATA_AREA	>
	.leave
	ret

handleRelocation:
	;
	; Object block isn't relocated, which means it could be either
	; relocating or unrelocating. We can tell which by looking at the
	; OLMBH_inUseCount value, which holds the routine used to relocate
	; or unrelocate something.
	; 
	cmp	ds:[OLMBH_inUseCount], offset RelocateLow
	je	getClass	; => relocating, so class pointer is
				;  already relocated

	;
	; Block is being unrelocated, so we need to relocate the class
	; pointer again.
	;
	push	cx, dx
	mov	si, ds:[si]			; deref. object
	mov	cx, ds:[si].MB_class.offset	; cx <- low word
	mov	dx, ds:[si].MB_class.segment	; dx <- high word
	mov	bx, ds:[LMBH_handle]	; bx <- block holding relocation
	mov	al, RELOC_ENTRY_POINT	; al <- relocating far ptr
	call	ObjDoRelocation
	mov	di, cx
	mov	es, dx
	pop	cx, dx
	jmp	haveClass
GetAndCheckVarDataStartEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNextVarDataEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset to next variable data entry.

CALLED BY:	INTERNAL
			ObjVarFindData
			ObjVarScanData
			ObjVarDeleteDataRange
			ObjVarCopyDataRange

PASS:		ds:bx - variable data entry
		ds:bp - end of variable data entry

RETURN:		ds:bx - next variable data entry
		status flags - set for 'cmp entry (bx), end (bp)'
			Z set if end of variable data

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version
	doug	11/91		Optimized a tad

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNextVarDataEntry	proc	far
	test	ds:[bx].VDE_dataType, mask VDF_EXTRA_DATA
	jnz	extraData

.assert (size VDE_dataType eq 2)
	inc	bx				; bump to next
	inc	bx
	cmp	bx, bp				; reached end?
EC <	ERROR_A	OVS_SIZE_OF_VAR_DATA_ENTRIES_GREATER_THAN_VAR_DATA_AREA	>
	ret

extraData:
EC <	push	ax							>
EC <	mov	ax, bx				; save old offset	>
	add	bx, ds:[bx].VDE_entrySize	; add total size of data entry
	cmp	bx, bp				; reached end?
EC <	ERROR_A	OVS_SIZE_OF_VAR_DATA_ENTRIES_GREATER_THAN_VAR_DATA_AREA	>
EC <	pop	ax							>
	ret

GetNextVarDataEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjVarFindData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search object's variable data for a given data type.

CALLED BY:	GLOBAL

PASS:		*ds:si - object to find variable data in
		ax - data type to find
			VarDataFlags ignored

RETURN:		carry set if data type found
			IF entry has extra data:
				ds:bx	- pointer to extra data
			ELSE:
				ds:bx	- opaque ptr which may be passed to 
				          ObjVarDeleteDataAt (In actuality is
				          ptr to data entry + offset
					  VDI_extraData)
			NOTE:  This pointer should be used before doing any
			       lmem operations on the block containing the
			       object.
		carry clear if not found

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjVarFindData	proc	far
	uses	ax, cx, bp
	.enter
EC <	call	ECLMemValidateHandle					>

	mov	cx, ax
	andnf	cx, not mask VarDataFlags	; clear flags for comparison
	call	GetAndCheckVarDataStartEnd	; bx = start, bp = end, Z if =
	je	done				; no variable data, done
	;
	; loop through variable data entries of this object
	;	*ds:si = object
	;	ds:bx = data entry in variable data area
	;	cx = data type to find
	;	bp = end of variable data area
	;
varDataLoop:
	mov	ax, ds:[bx].VDE_dataType	; ax = data type
	andnf	ax, not mask VarDataFlags	; clear flags
	cmp	ax, cx				; is this the one?
	je	foundDataEntry			; yes, found it
	;
	; else, move to check next data entry
	;	*ds:si = object
	;	ds:bx = this data entry
	;	cx = data type to find
	;	bp = end of variable data area
	;

;
;	call	GetNextVarDataEntry		; ds:bx = next entry, Z if end
;
; Inserted in-line here for speed 	-- Doug
; {
	test	ds:[bx].VDE_dataType, mask VDF_EXTRA_DATA
	jnz	extraData

.assert (size VDE_dataType eq 2)
	inc	bx				; bump to next
	inc	bx
	cmp	bx, bp				; reached end?
EC <	ERROR_A	OVS_SIZE_OF_VAR_DATA_ENTRIES_GREATER_THAN_VAR_DATA_AREA	>
	jne	varDataLoop			; more variable data,
						;	go back for more
	jmp	short done

extraData:
EC <	tst	ds:[bx].VDE_entrySize		; if this is zero, it	>
EC <	ERROR_Z	OVS_CORRUPTED_VAR_DATA_ENTRY	;  will loop infinitely	>
EC <	push	ax							>
EC <	mov	ax, bx				; save old offset	>
	add	bx, ds:[bx].VDE_entrySize	; add total size of data entry
	cmp	bx, bp				; reached end?
EC <	ERROR_A	OVS_SIZE_OF_VAR_DATA_ENTRIES_GREATER_THAN_VAR_DATA_AREA	>
EC <	pop	ax							>
; }
	jne	varDataLoop			; more variable data,
						;	go back for more
	jmp	done				; else, done (carry clear)
	;
	; found data entry with matching data type
	;	*ds:si = object
	;	ds:bx = this data entry
	;
foundDataEntry:
	add	bx, offset VDE_extraData	; return ptr to extra data
	stc					; indicate found
done:
	.leave
	ret
ObjVarFindData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjVarDerefData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	EXTERNAL

PASS:		*ds:si - object in which to get ptr to variable data
		ax - data type
			VarDataFlags ignored
		dx, bp - data to pass to MSG_META_INITIALIZE_VAR_DATA if
			 it needs to be called.
RETURN:		
		IF entry has extra data:
			ds:bx	- pointer to extra data
		ELSE:
			ds:bx	- opaque ptr which may be passed to 
			          ObjVarDeleteDataAt (In actuality is
			          ptr to data entry + offset VDI_extraData)
		NOTE:  This pointer should be used before doing any
		       lmem operations on the block containing the
		       object.
		object marked dirty if entry created


DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version, pulled from Brian C's code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjVarDerefData	proc	far
	call	ObjVarFindData
	jnc	createNew
	ret

createNew:
	; Ask object to create & initialize the data

	push	ax, cx, dx, bp
	mov	cx, ax		; Pass data type in cx
	mov	ax, MSG_META_INITIALIZE_VAR_DATA
	call	ObjCallInstanceNoLock
	mov	bx, ax		; Return ptr to extra data in bx
	pop	ax, cx, dx, bp

EC <	push	cx					>
EC <	mov	cx, bx					>
EC <	call	ObjVarFindData				>
EC <	ERROR_NC	OVS_BAD_MSG_META_INITIALIZE_VAR_DATA_HANDLER	>
EC <	cmp	cx, bx					>
EC <	ERROR_NE	OVS_BAD_MSG_META_INITIALIZE_VAR_DATA_HANDLER	>
EC <	pop	cx					>
	ret

ObjVarDerefData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjVarScanData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan an object's variable data and call all pertaining
		routines listed in a "variable data handler" table.

CALLED BY:	GLOBAL

PASS:		*ds:si - object to scan variable data of
		ax     - number of VarDataHandlers in table
		es:di  - ptr to a list of VarDataHandlers.  The handler
			routines must be far routines in the same segment
			as the handler table.
		cx, dx, bp - data to pass through variable data handlers

		PASSED to variable data handler:
			*ds:si - object
			ds:bx - extra data, if any, else start of
				variable data entry + size VarDataEntry
				(May be passed to VarDataTypePtr,
				VarDataFlagsPtr, VarDataSizePtr macros)
			ax - data type
			cx, dx, bp - any data
		RETURNED from variable data handler:
			ds - updated segment for object block
			cx, dx, bp - any data
		OK TO DESTROY in variable data handler:
			ax, bx, si, di, es

RETURN:		cx, dx, bp - any data after passing through handlers
		ds - updated segment address of object

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
; Stack frame at time of EC check to make sure that the data handler has
; not added or removed any var data entries
;
StackAtEC	struct
	SAEC_bp			word
	SAEC_bx			word
	SAEC_entryType		word
	SAEC_tableOffset	word
	SAEC_numHandlers	word
	SAEC_endPtr		word
StackAtEC	ends
endif

ObjVarScanData	proc	far
	uses	ax, bx
	.enter
EC <	call	ECLMemValidateHandle					>

EC <	tst	ax							>
EC <	ERROR_E	BAD_TABLE_SIZE_PASSED_TO_OBJ_VAR_SCAN_DATA		>
EC <	cmp	ax, 1024						>
EC <	ERROR_A	BAD_TABLE_SIZE_PASSED_TO_OBJ_VAR_SCAN_DATA		>

	push	bp				; save BP data to pass
	call	GetAndCheckVarDataStartEnd	; bx = start, bp = end, Z if =

	; Convert end ptr to relative offset, & keep that way until those
	; points where we need the absolute ptr.  This will keep the value
	; valid across calls to data handlers, which may legally add or remove
	; chunks in the block (though not add or remove var data elements)
	;
	pushf
	sub	bp, ds:[si]			; convert to relative offset
	popf
	XchgTopStack	bp			; restore BP data to pass,
						; save end of var data on stack

	LONG je	pop1ThenDone			; no variable data, done

	;
	; loop through variable data entries of this object
	;	ax = # of data handlers
	;	*ds:si = object
	;	ds:bx = data entry in variable data area
	;	es:di = var data handler table
	;	cx, dx, bp = data for handlers
	;	on stack: (end of variable data)
	;
varDataLoop:
	push	ax				; save # of handlers
	push	di				; save table offset

	push	cx				; save handler data CX
	mov	cx, ax				; cx = number of handlers
EC <	tst	cx							>
EC <	ERROR_Z	OVS_BAD_HANDLER_TABLE					>
	mov	ax, ds:[bx].VDE_dataType	; ax = data type
	andnf	ax, not mask VarDataFlags	; clear flags
	;
	; search for a handler for this data type in the handler table
	;	ax = data type (with VarDataFlags cleared)
	;	es:di = handler table
	;	cx = number of remaining entries in handler table
	;	ds:bx = data entry
	;	dx, bp = data for handlers
	;	on stack: (data CX) (table offset) <num handlers>
	;						(end of variable data)
	;
searchTableLoop:
	push	bx				; save data entry offset
	mov	bx, es:[di].VDH_dataType
	andnf	bx, not mask VarDataFlags	; ignore flags
	cmp	ax, bx				; is this a handler?
	pop	bx				; retreive data entry offset
	je	foundHandler			; yes, process it
	add	di, size VarDataHandler		; else, move to next one
	loop	searchTableLoop
	pop	cx				; restore handler data CX

nextVarData:
	pop	di				; restore handler table offset
	pop	ax				; restore # of handlers

	XchgTopStack	bp			; get bp = end of variable data,
	add	bp, ds:[si]			; convert back to pointer
						; save bp pass data on stack
	call	GetNextVarDataEntry		; ds:bx = next entry, Z if end
	pushf
	sub	bp, ds:[si]			; convert to relative offset
	popf
	XchgTopStack	bp			; restore BP data to pass,
						; save end of var data on stack
	jne	varDataLoop			; more variable data,
						;	go back for more
	jmp	pop1ThenDone			; else done

	;
	; found handler for this data entry, call handler
	;	*ds:si = object
	;	ds:bx = data entry
	;	es:di = VarDataHandler
	;	dx, bp = data for handlers
	;	on stack: (data CX) (table offset) (num handlers)
	;		(relative offset from start of chunk to 
	;					end of variable data)
	;
foundHandler:
	pop	cx				; retrieve cx data

EC <	push	ds:[bx].VDE_dataType		; make sure type unchanged >

	mov	ax, bx				; ds:bx is ptr to data entry
	sub	ax, ds:[si]			; convert to relative offset
	push	ax				; from start of chunk & save

	push	es, si				; save values trashed by handler
	;
	; call var data handler via RET
	;
	; (allows calling far routine without actually combining offset
	; and segment into a fptr)
	;
	push	cs				; push return address
	mov	ax, offset afterHandler
	push	ax
	push	es				; push handler address
	push	es:[di].VDH_handler		; (same segment as table)
	mov	ax, ds:[bx].VDE_dataType	; ax = data type
	andnf	ax, not mask VarDataFlags	; clear flags for handler
	add	bx, size VarDataEntry		; pass ptr to extra data
	ret					; return to handler

	;
	; handler returns to here
	;	cx, dx, bp - data from handler
	;	ds - updated segment for object block
	;	on stack: (es, di) (relative offset) (EC data type)
	;		(table offset) <num handlers>(end of variable data)
	;
afterHandler:
	pop	es, si				; restore - trashed by handler
	pop	bx				; restore relative offset
	add	bx, ds:[si]			; convert to actual offset

EC <	push	bx, bp							>
EC <	call	GetAndCheckVarDataStartEnd				>
EC <	mov	bx, bp				; endptr in bx		>
EC <	mov	bp, sp							>
EC <	mov	bp, ss:[bp].SAEC_endPtr					>
EC <	add	bp, ds:[si]			; convert to ptr	>
EC <	cmp	bx, bp				; make sure unchanged	>
EC <	ERROR_NE	OVS_VAR_DATA_HANDLER_ADDED_OR_REMOVED_DATA_ENTRY    >
EC <	pop	bx, bp							>

EC <	pop	ax							>
EC <	cmp	ax, ds:[bx].VDE_dataType	; make sure unchanged	>
EC <	ERROR_NE	OVS_VAR_DATA_HANDLER_CHANGED_DATA_ENTRY		>
	jmp	short nextVarData		; do next var data entry

pop1ThenDone:					; no variable data, done
	add	sp, 2				; fix stack
;done:
	.leave
	ret

ObjVarScanData	endp


kcode ends

;----

ChunkArray	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjVarAddData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add new data type or replace the additional data in an
		existing data type.  Any data is left initialized to 0's.
		Returns ptr to the extra data to allow for immediate access.

CALLED BY:	EXTERNAL

PASS:		*ds:si - object to add variable data to
		ax - data type
			VDF_SAVE_TO_STATE set correctly
			incoming VDF_EXTRA_DATA is ignored, it will be set
			correctly by this routine
		cx - size of extra data
			cx = 0 if data type has no extra data

RETURN:		IF entry has extra data (cx passed non-zero):
			ds:bx	- pointer to extra data
		ELSE:
			ds:bx	- opaque ptr which may be passed to 
				  ObjVarDeleteDataAt (In actuality is
				  ptr to data entry + offset VDI_extraData)
		object marked dirty (even if data entry already exists)
		es	= fixed up if pointing to same block as DS on entry

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	11/91		Initial version, pulled from Brian C's code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjVarAddData	proc	far
	uses	ax, cx, dx, di
	.enter
EC <	call	ECCheckLMemObject					>

EC <	cmp	cx, 1024					>
EC <	ERROR_A	BAD_SIZE_PASSED_TO_OBJ_VAR_ADD_DATA		>

	call	PatchObjFlagsForVarData		;dl = old flags, di = data

	; Figure out size of full data entry

	andnf	ax, not mask VDF_EXTRA_DATA	; make sure this is clear
	jcxz	afterSizeDiff
	add	cx, size VDE_entrySize		; if data, add in storage 
						;	space for data size
	ornf	ax, mask VDF_EXTRA_DATA		; make sure this is set
afterSizeDiff:
	add	cx, size VDE_dataType		; add room for data type
						; cx = total size of data entry

	; See if we can just re-use an element already there

	call	ObjVarFindData			; ds:bx = extra data (if entry
						;	exists)
	jnc	createNewEntry			; if none existing, go
						; ahead & create a new one
	push	dx
	mov	dx, size VDE_dataType		; dx = total size of entry
	test	{word} ds:[bx].VEDP_dataType, mask VDF_EXTRA_DATA
	jz	noExtraData
	mov	dx, ds:[bx].VEDP_entrySize
noExtraData:
	cmp	cx, dx				; same size?
	pop	dx
	jne	goAheadAndDelete		; if not, delete & start over

	call	ObjMarkDirty			; object is changed

updateEntry:
						; ax = data type
						; cx = size of entire entry
						; ds:bx = extra data

	mov	di, bx				; ds:di = extra data
	sub	di, size VarDataEntry		; ds:di = new data entry
	push	es				; save ES only now so it gets
						;  properly fixed up if pointing
						;  to the same block as DS on
						;  entry. -- ardeb 4/19/94
	segmov	es, ds				; es:di = new entry

.assert (offset VDE_dataType eq 0)
	stosw					; store data type

	cmp	cx, size VDE_dataType		; any extra data?
	je	done				; if not, we're done.

	mov	ax, cx				; store size
.assert (offset VDE_entrySize eq 2)
	stosw

	sub	cx, size VarDataEntry		; & zero out extra data
	clr	al
.assert (offset VDE_extraData eq 4)
	rep	stosb				; clear rest of data space
done:
	pop	es
	call	UnPatchObjFlagsForVarData

	.leave
	ret


goAheadAndDelete:

	; likely a rare case, here..
	;
	call	ObjVarDeleteDataAt		; nuke old one

createNewEntry:
						; ax = data type
						; cx = size of entire entry
						; *ds:si is object

	push	ax				; preserve data type
	ChunkSizeHandle	ds, si, bx		; bx = add data entry at end
	mov	ax, si				; *ds:ax = object chunk
	call	LMemInsertAt
	pop	ax
	add	bx, ds:[si]			; ds:bx = new data entry
	add	bx, size VarDataEntry		; ds:bx = new extra data
	jmp	updateEntry

ObjVarAddData	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	PatchObjFlagsForVarData

DESCRIPTION:	Patch an object's flags for vardata manipulation

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - var data tag (VDF_SAVE_TO_STATE used)

RETURN:
	dl - old flags

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/22/92		Initial version

------------------------------------------------------------------------------@
PatchObjFlagsForVarData	proc	near	uses si
	.enter

	mov	di, ds:[LMBH_offset]		;*ds:di = flags
	sub	si, di
	shr	si				;si = handle #
	mov	di, ds:[di]			;ds:di = flags
	add	di, si

	mov	dl, ds:[di]			;dl = old flags
	test	ax, mask VDF_SAVE_TO_STATE
	jnz	done
	ornf	{byte} ds:[di], mask OCF_IGNORE_DIRTY
done:
	.leave
	ret

PatchObjFlagsForVarData	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UnPatchObjFlagsForVarData

DESCRIPTION:	Fix an object's flags after a vardata operation

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	dl - old flags

RETURN:
	none

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/22/92		Initial version

------------------------------------------------------------------------------@
UnPatchObjFlagsForVarData	proc	near	uses si
	.enter

	mov	di, ds:[LMBH_offset]		;*ds:di = flags
	sub	si, di
	shr	si				;si = handle #
	mov	di, ds:[di]			;ds:di = flags
	add	di, si

	test	{byte} ds:[di], mask OCF_DIRTY
	mov	ds:[di], dl
	jz	done
	ornf	{byte} ds:[di], mask OCF_DIRTY
done:

	.leave
	ret

UnPatchObjFlagsForVarData	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjVarDeleteData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete data type and additional data (if any).

CALLED BY:	GLOBAL

PASS:		*ds:si - object to delete variable data from
		ax - data type to delete
			VarDataFlags ignored

RETURN:		carry clear if data deleted
		carry set if not found
		ds - updated segment of object block
		object marked dirty of data found and deleted

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjVarDeleteData	proc	far
	uses	bx
	.enter
	call	ObjVarFindData			; ds:bx = extra data (if entry
						;	exists)
						; carry set = found
						; carry clear = not found
	cmc					; carry clear = found
						; carry set = not found
	jc	done				; if not found, done (carry set)
	call	ObjVarDeleteDataAt		; (marks object dirty)
	clc					; indicate data entry removed
done:
	.leave
	ret
ObjVarDeleteData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjVarDeleteDataAt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete specified data entry.

CALLED BY:	GLOBAL

PASS:		*ds:si -object to delete data entry from
		ds:bx - ptr as returned by ObjVarAddData, ObjVarFindData, or
			ObjVarDerefData  (must point to extra data, or if
			entry doesn't have extra data, to entry + offset
			VDI_extraData)

			VarDataFlags ignored

RETURN:		object marked dirty

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjVarDeleteDataAt	proc	far
	uses	ax, bx, cx, dx, di
	.enter
EC <	call	ECCheckLMemObject					>

	sub	bx, offset VDE_extraData	; adjust ptr to start of entry

	mov	ax, ds:[bx].VDE_dataType
	call	PatchObjFlagsForVarData		;dl = old flags

	mov	cx, size VDE_dataType			; assume no extra data
	test	ax, mask VDF_EXTRA_DATA	; extra data?
	jz	haveEntrySize
	mov	cx, ds:[bx].VDE_entrySize	; cx = total data entry size
haveEntrySize:
	mov	ax, si				; *ds:ax = object chunk
	sub	bx, ds:[si]			; bx = rel. OFFSET to delete at
	call	LMemDeleteAt

	call	UnPatchObjFlagsForVarData
	.leave
	ret
ObjVarDeleteDataAt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjVarDeleteDataRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete data types that fall into a given range.

CALLED BY:	GLOBAL

PASS:		*ds:si - object to delete variable data from
		cx - smallest data type to delete (inclusive)
			VarDataFlags ignored
		dx - largest data type to delete (inclusive)
			VarDataFlags ignored
		bp - 0 to delete all data entries with data types in range
		   - non-zero to only delete data entries with data types
			in range and with VDF_SAVE_TO_STATE clear

RETURN:		object marked dirty if any data types deleted

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjVarDeleteDataRange	proc	far
	uses	ax, bx, cx, dx
	.enter

EC <	call	ECCheckLMemObject					>
	push	bp				; save deletion flag
	andnf	cx, not mask VarDataFlags	; clear flags for comparison
	andnf	dx, not mask VarDataFlags	; clear flags for comparison
	call	GetAndCheckVarDataStartEnd	; bx = start, bp = end, Z if =
varDataTestAndLoop:
	cmp	bx, bp				; at end of variable data?
	je	done				; yes, done
	;
	; loop through variable data entries of this object
	;	*ds:si = object
	;	ds:bx = data entry in variable data area
	;	cx = smallest data type of range
	;	dx = largest data type of range
	;	bp = end of variable data
	;	on stack: (deletion flag = 0 to ignore VDF_SAVE_TO_STATE flag)
	;
varDataLoop:
	mov	ax, ds:[bx].VDE_dataType	; ax = data type
	andnf	ax, not mask VarDataFlags	; clear flags
	cmp	ax, cx				; is this one?
	jb	checkNext			; no, check next
	cmp	ax, dx
	jbe	foundDataEntry			; yes, delete it
	;
	; else, move to check next data entry
	;	*ds:si = object
	;	ds:bx = this data entry
	;	cx = smallest data type of range
	;	dx = largest data type of range
	;	bp = end of variable data
	;	on stack: (deletion flag = 0 to ignore VDF_SAVE_TO_STATE flag)
	;
checkNext:
	call	GetNextVarDataEntry		; ds:bx = next entry, Z if end
	jne	varDataLoop			; more variable data,
						;	go back for more
	jmp	done				; else, not found (carry clear)
	;
	; found data entry with data type within range, delete it
	;	*ds:si = object
	;	ds:bx = this data entry
	;	on stack: (deletion flag = 0 to ignore VDF_SAVE_TO_STATE flag)
	;
foundDataEntry:
	pop	ax				; (get deletion flag)
	tst	ax				; ignore VDF_SAVE_TO_STATE?
	push	ax				; (restore deletion flag)
	jz	ignoreFlag			; yes, delete it
	test	ds:[bx].VDE_dataType, mask VDF_SAVE_TO_STATE	; save?
	jnz	checkNext			; yes, don't delete
ignoreFlag:
	mov	ax, ds:[si]			; deref. object
	push	bx				; save actual data entry offset
	sub	bx, ax				; bx = relative offset to data
						;	entry from beg. of chunk
	mov	ax, bx
	pop	bx				; ds:bx = data entry to delete
	push	ax				; save relative offset
	add     bx, offset VDE_extraData        ; adjust ptr to that expected
						; by ObjVarDeleteDataAt
	call	ObjVarDeleteDataAt		; delete this entry
						; (marks object dirty)
	pop	bx				; restore relative offset
	add	bx, ds:[si]			; convert to actual offset
	ChunkSizeHandle	ds, si, bp
	add	bp, ds:[si]			; bp = end of variable data
	jmp	varDataTestAndLoop		; go to check next entry (at
						;	same position as the
						;	one we just deleted
						;	as it is shifted up)
done:
	pop	bp				; recover deletion flag
	.leave
	ret
ObjVarDeleteDataRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjVarCopyDataRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy data entries with data types in given range from one
		object to another.

CALLED BY:	GLOBAL

PASS:		*ds:si - source object to copy variable data from
		*es:bp - destination object to copy variable data to
		cx - smallest data type to copy (inclusive)
			VarDataFlags ignored
		dx - largest data type to copy (inclusive)
			VarDataFlags ignored

RETURN:		ds, es - updated segment blocks
		destination object marked dirty if entries copied

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjVarCopyDataRange	proc	far
	uses	ax, bx, cx, dx, di
	.enter
EC <	call	ECCheckLMemObject					>
	andnf	cx, not mask VarDataFlags	; clear flags for comparison
	andnf	dx, not mask VarDataFlags	; clear flags for comparison
	push	bp				; save dest. object chunk
	call	GetAndCheckVarDataStartEnd	; bx = start, bp = end, Z if =
	je	done				; no variable data, done
	;
	; loop through variable data entries of this object
	;	*ds:si = object
	;	ds:bx = data entry in variable data area
	;	cx = data type to find
	;	dx = largest data type of range
	;	bp = end of variable data
	;	on stack: (dest. object chunk)
	;
varDataLoop:
	mov	ax, ds:[bx].VDE_dataType	; ax = data type
	andnf	ax, not mask VarDataFlags	; clear flags
	cmp	ax, cx				; is this one?
	jb	checkNext			; no, check next
	cmp	ax, dx
	ja	checkNext			; no, check next
	;
	; found data entry with matching data type
	;	*ds:si = object
	;	ds:bx = this data entry
	;	es = segment of dest. object
	;	on stack: (dest. object chunk)
	;
	pop	ax				; *es:ax = dest. object
	push	ax, cx, dx, si

	push	si				; save object chunk
	mov	si, ax				; *es:si = dest. object
	mov	cx, 0				; assume no extra data
	mov	ax, ds:[bx].VDE_dataType	; ax = data type w/flags
	test	ax, mask VDF_EXTRA_DATA		; any extra data?
	jz	haveNewEntry			; nope, add just data type
	mov	cx, ds:[bx].VDE_entrySize	; cx = size of entry
	sub	cx, size VarDataEntry		; get size of extra data
haveNewEntry:
	;
	; save relative offset of this data entry (absolute offsets are useless
	; because chunk may be moved after ObjVarAddData)
	;	ds:bx = source data entry
	;	*es:si = dest. object
	;	ax = data type
	;	cx = extra data size
	;	on stack: (source object chunk, (ax, cx, dx))
	;
	pop	di				; get object chunk from stack
	push	di
	mov	di, ds:[di]			; deref. object
	push	bx				; temp. save actual offset
	sub	bx, di				; bx = relative offset
	mov	di, bx
	pop	bx				; bx = actual offset again
	push	di				; save src relative offset
	push	ds:[LMBH_handle]		; save src block handle
	;
	; *es:si = dest object
	;
	push	es
	pop	ds				; *ds:si = dest object
	call	ObjVarAddData			; (marks dest. object dirty)
						; ds:bx = new entry (ds updated)
	mov	di, bx				; ds:di = new entry
	push	ds
	pop	es				; es:di = dest extra data
	pop	bx				; restore src block handle
	call	MemDerefDS			; ds = source entry segment
	pop	bx				; bx = src relative offset
	pop	si				; si = src object chunk
	mov	si, ds:[si]			; deref. source object
	; update end of variable data after ObjVarAddData, which may
	; move the chunk
	ChunkSizePtr	ds, si, bp
	add	bp, si				; bp = end of variable data
	; update source data entry pointer after ObjVarAddData, which
	; may move the chunk
	add	si, bx				; ds:si = source data entry
	mov	bx, si				; ds:bx = source data entry
	add	si, size VarDataEntry		; ds:si = source extra data
	rep	movsb				; copy extra data over

	pop	ax, cx, dx, si
	push	ax				; put dest. chunk back on stack
	;
	; move to check next data entry
	;	*ds:si = object
	;	ds:bx = this data entry
	;	cx = data type to find
	;	dx = largest data type of range
	;	bp = end of variable data
	;	on stack: (dest. object chunk)
	;
checkNext:
	call	GetNextVarDataEntry		; ds:bx = next entry, Z if end
	jne	varDataLoop			; more variable data,
						;	go back for more
done:
	pop	bp				; retreive dest. object chunk
	.leave
	ret
ObjVarCopyDataRange	endp

ChunkArray	ends
