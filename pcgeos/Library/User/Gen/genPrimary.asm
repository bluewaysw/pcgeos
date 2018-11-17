COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genPrimary.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenPrimaryClass		Primary window for an app

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version

DESCRIPTION:
	This file contains routines to implement the GenPrimary class.

	$Id: genPrimary.asm,v 1.1 97/04/07 11:45:25 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT `CLASS DESCRIPTION-----------------------------------------------------

			GenPrimaryClass

Synopsis
--------

GenPrimaryClass provides base windows.

------------------------------------------------------------------------------`

UserClassStructures	segment resource

	GenPrimaryClass

UserClassStructures	ends


Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenPrimaryBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenPrimaryClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

GenPrimaryBuild	method	GenPrimaryClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_PRIMARY
	GOTO	GenQueryUICallSpecificUI

GenPrimaryBuild	endm

Build	ends

;
;---------------
;
		
BuildUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenPrimaryCopyTree -- MSG_GEN_COPY_TREE for
		GenPrimaryClass

DESCRIPTION:	Copy this GenPrimary object (with long-term moniker chunk,
		if any)

PASS:
	*ds:si - instance data
	es - segment of GenPrimaryClass

	ax - MSG_GEN_COPY_TREE

	^lcx:dx	- object to add onto
	bp	- CompChildFlags, if adding onto object

RETURN: ^lcx:dx	- OD of new object created

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/2/92		Initial version

------------------------------------------------------------------------------@

GenPrimaryCopyTree	method	GenPrimaryClass, MSG_GEN_COPY_TREE
EC <	call	ECCheckGenCopyTreeArgs	;check passed arguments		>
	push	bp
	;
	; First call my superclass to do normal handling
	;
	mov	di, offset GenPrimaryClass
	call	ObjCallSuperNoLock		; ^lcx:dx = new GenPrimary
	;
	; Lock the new block, and access generic data of new and old
	;
	mov	bx, cx				; block handle to BX
	call	ObjLockObjBlock
	mov	es, ax				; segment to ES
	mov	bx, dx				; chunk handle to BX
	mov	bx, es:[bx]			; dereference it
	add	bx, es:[bx].Gen_offset		; access generic data of new
	mov	di, ds:[si]			; dereference old chunk handle
	add	di, ds:[di].Gen_offset		; access generic data of old
	;
	; Copy the long term moniker chunk over
	;
	mov	ax, ds:[di].GPI_longTermMoniker
	pop	bp
	and	bp, mask CCF_MARK_DIRTY		;Restore dirty flag
	push	cx, dx				; save our new object
	push	ds
	push	es
	pop	ds
	pop	es
	call	GenCopyChunk
	push	ds
	push	es
	pop	ds
	pop	es
	pop	cx, dx				; restore our new object

	mov	bx, dx				; chunk handle back to BX
	mov	bx, es:[bx]			; dereference it
	add	bx, es:[bx].Gen_offset		; access generic data of new
	mov	es:[bx].GPI_longTermMoniker, ax	; store the new moniker handle

	mov	bx, cx				; put block handle back in BX
	GOTO	MemUnlock			; clean up

GenPrimaryCopyTree	endm

BuildUncommon	ends

;
;---------------
;
		
DestroyCommon	segment	resource

COMMENT @-----------------------------------------------------------------------

METHOD:		GenPrimaryFinalObjFree -- MSG_META_FINAL_OBJ_FREE for
			GenPrimaryClass

DESCRIPTION:	Intercept method normally handled at GenClass to add
		behavior of freeing the chunks that a GenPrimaryClass object
		references.
		Free long term moniker, unless any of these chunks
		came from a resource, in which case we mark dirty & resize
		to zero.

PASS:
	*ds:si - object

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/90		Initial version

-------------------------------------------------------------------------------@

GenPrimaryFinalObjFree	method GenPrimaryClass, MSG_META_FINAL_OBJ_FREE

				; Long term moniker
    	mov	ax, ds:[di].GPI_longTermMoniker
	tst	ax
	jz	afterMoniker
	call	ObjFreeChunk
afterMoniker:

				; Finish up w/nuking the object itself
	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset GenPrimaryClass
	GOTO	ObjCallSuperNoLock

GenPrimaryFinalObjFree	endm


DestroyCommon ends

;--------

WindowFiddle segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenPrimarySetMaximized

DESCRIPTION:	Maximize the GenPrimary.

PASS:	*ds:si	= instance data for object
	es - segment of GenPrimaryClass

	ax - MSG_GEN_DISPLAY_SET_MAXIMIZED

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/5/92		initial version

------------------------------------------------------------------------------@

GenPrimarySetMaximized	method	GenPrimaryClass, MSG_GEN_DISPLAY_SET_MAXIMIZED
	;
	; If not maximizable, ignore.
	;
	mov	ax, ATTR_GEN_DISPLAY_NOT_MAXIMIZABLE
	call	ObjVarFindData			; carry set if found
	jc	done				; cannot maximize, ignore
	;
	; Check if already maximized, if not set maximized flag and let
	; spui maximize.
	;
	mov	ax, ATTR_GEN_DISPLAY_MAXIMIZED_STATE or mask VDF_SAVE_TO_STATE
	call	ObjVarFindData			; carry set if found
	jc	done				; already maximized
	clr	cx
	call	ObjVarAddData			; else, add maximized flag

	clr	cx				; allow optimized check
	call	GenCheckIfFullyUsable		; if not fully usable, bail
	jnc	done

	mov	ax, MSG_GEN_DISPLAY_SET_MAXIMIZED
	call	GenCallSpecIfGrown		; let spui do the actual work
done:
	ret
GenPrimarySetMaximized	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenPrimarySetNotMaximized

DESCRIPTION:	Unmaximize the GenPrimary.

PASS:	*ds:si	= instance data for object
	es - segment of GenPrimaryClass

	ax - MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/5/92		initial version

------------------------------------------------------------------------------@

GenPrimarySetNotMaximized	method	GenPrimaryClass, \
					MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED
	;
	; If not restorable, ignore.
	;
	mov	ax, ATTR_GEN_DISPLAY_NOT_RESTORABLE
	call	ObjVarFindData			; carry set if found
	jc	done				; cannot restore, ignore
	;
	; Check if already not maximized, if not, clear maximized flag and let
	; spui unmaximize.
	;
	mov	ax, ATTR_GEN_DISPLAY_MAXIMIZED_STATE
	call	ObjVarDeleteData	; carry clear if found and deleted
					;	(marks dirty if deleted)
	jc	done			; not found -> already unmaximized

	clr	cx				; allow optimized check
	call	GenCheckIfFullyUsable	; if not fully usable, bail
	jnc	done

	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED
	call	GenCallSpecIfGrown	; let spui do the actual work
done:
	ret
GenPrimarySetNotMaximized	endm

WindowFiddle	ends

;
;---------------
;
		
Common	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenPrimaryGetMaximized

DESCRIPTION:	Get maximized mode of GenPrimary.

PASS:	*ds:si	= instance data for object
	es - segment of GenDisplayClass

	ax - MSG_GEN_DISPLAY_GET_MAXIMIZED

RETURN:	carry set if maximized

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/5/92		initial version

------------------------------------------------------------------------------@

GenPrimaryGetMaximized	method	GenPrimaryClass, MSG_GEN_DISPLAY_GET_MAXIMIZED
	;
	; Check maximized-mode storage attr
	;
	mov	ax, ATTR_GEN_DISPLAY_MAXIMIZED_STATE
	call	ObjVarFindData		; carry set if found
	ret
GenPrimaryGetMaximized	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenPrimaryGetLongTermMoniker --
		MSG_GEN_PRIMARY_GET_LONG_TERM_MONIKER for GenPrimaryClass

DESCRIPTION:	Get the long term moniker

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenClass

	ax - MSG_GEN_PRIMARY_GET_LONG_TERM_MONIKER

RETURN: ax - long term moniker chunk
	dx, bp - unchanged

ALLOWED TO DESTROY:
	ax
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

GenPrimaryGetLongTermMoniker	method	GenPrimaryClass,
					MSG_GEN_PRIMARY_GET_LONG_TERM_MONIKER

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GPI_longTermMoniker
	ret

GenPrimaryGetLongTermMoniker	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenPrimaryReplaceLongTermMoniker -- 
		MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER for GenPrimaryClass

DESCRIPTION:	Replace GenPrimary object's current long term moniker.

PASS:		*ds:si 	- instance data
		es     	- segment of GenPrimaryClass
		ax 	- MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER
		
		ss:bp	- ReplaceVisMonikerFrame
				ReplaceVisMonikerFrame	struct
					RVMF_source	dword
					RVMF_sourceType	VisMonikerSourceType
					RVMF_dataType	VisMonikerDataType
					RVMF_length	word
					RVMF_width	word
					RVMF_height	word
					RVMF_updateMode	VisUpdateMode
				ReplaceVisMonikerFrame	ends
		(For XIP'ed geodes, the fptrs passed in ReplaceVisMonikerFrame
			*cannot* be pointing into the movable XIP code resource.)
		dx	- size ReplaceVisMonikerFrame

RETURN:		ax - chunk handle of long term moniker
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/23/92		Initial version

------------------------------------------------------------------------------@
GenPrimaryReplaceLongTermMoniker	method	dynamic	GenPrimaryClass, \
				MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is not pointing into the code segment
	; of the caller
	;
EC <		cmp	ss:[bp].RIMF_sourceType, VMST_FPTR		>
EC <		jne	xipSafe						>
EC <		cmp	ss:[bp].RIMF_dataType, VMDT_NULL		>
EC <		je	xipSafe						>
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, ss:[bp].RIMF_source			>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
EC < xipSafe:								>
endif
	call	ObjMarkDirty
	;
	; handle freeing of current vis moniker
	;
	mov	dl, ss:[bp].RVMF_updateMode	; dl = VisUpdateMode
	cmp	ss:[bp].RVMF_dataType, VMDT_NULL
	jne	normalCreate
	;
	; free current moniker
	;	dl = VisUpdateMode
	;
freeCurrentMoniker:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GPI_longTermMoniker	; get current moniker
	jcxz	done				; no current moniker, done
	push	cx				; else, save current moniker
	clr	cx
	mov	ax, MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER
	call	ObjCallInstanceNoLock		; set no moniker
	pop	ax
	call	ObjFreeChunk			; free old moniker
	jmp	short done

normalCreate:
	;
	; we now pass ReplaceVisMonikerFrame as CreateVisMonikerFrame
	;	ss:bp = ReplaceVisMonikerFrame
	;
.assert (offset RVMF_source eq offset CVMF_source)
.assert (offset RVMF_sourceType eq offset CVMF_sourceType)
.assert (offset RVMF_dataType eq offset CVMF_dataType)
.assert (offset RVMF_length eq offset CVMF_length)
.assert (offset RVMF_width eq offset CVMF_width)
.assert (offset RVMF_height eq offset CVMF_height)
.assert (offset RVMF_updateMode eq offset CVMF_flags)
.assert (size ReplaceVisMonikerFrame eq size CreateVisMonikerFrame)
.assert (size RVMF_updateMode eq size CVMF_flags)
	mov	ss:[bp].CVMF_flags, mask CVMF_DIRTY	; mark new chunk dirty
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GPI_longTermMoniker	; replace current vis moniker
	push	ax				; save for later usage
	call	VisCreateMonikerChunk		; ax = vis moniker chunk
						; carry set if VMDT_TOKEN and
						;	token not found
	pop	bx				; restore old vis moniker chunk
	jc	freeCurrentMoniker		; if error, free current mkr
						; (b/c it is now bogus)
	;
	; clear moniker and set it again (forces
	; MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER to update even if same moniker
	; chunk is reused)
	;	ax = new moniker chunk
	;	bx = old vis moniker chunk
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	ds:[di].GPI_longTermMoniker	; replace current vis moniker
	;
	; mirror this object's OCF_IGNORE_DIRTY flag in the new moniker chunk
	; (it is also marked as OCF_DIRTY and ~OCF_IGNORE_DIRTY by
	;  VisCreateMonikerChunk)
	; (only do this if the vis moniker chunk is newly created, if we
	;  replaced an existing moniker, we maintain the previous
	;   OCF_IGNORE_DIRTY status)
	;	*ds:ax = new vis moniker chunk
	;	bx = old moniker chunk
	;
	mov	cx, ax				; cx = new moniker chunk
	tst	bx				; new moniker? 
	jnz	notIgnoreDirty			; no, leave alone
	mov	ax, si				; *ds:ax = this object
	call	ObjGetFlags			; al = flags, ah = 0
	test	al, mask OCF_IGNORE_DIRTY	; ignore-dirty?
	jz	notIgnoreDirty
	mov	ax, cx				; *ds:ax = moniker chunk
	mov	bx, mask OCF_IGNORE_DIRTY	; set this, clear nothing
	call	ObjSetFlags
notIgnoreDirty:
	mov	ax, MSG_GEN_PRIMARY_USE_LONG_TERM_MONIKER	; does update
	call	ObjCallInstanceNoLock
done:
	ret
GenPrimaryReplaceLongTermMoniker	endm

Common ends
