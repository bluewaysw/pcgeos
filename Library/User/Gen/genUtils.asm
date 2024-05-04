COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genUtils.asm

ROUTINES:
	Name			Description
	----			-----------

In Fixed resources:
-------------------
   GLB	GenSendToChildren
   GLB  GenSendProcess
   GLB  GenCallNextSibling
   GLB	GenCallParent
   GLB	UserCallSystem
   GLB  GenCopyChunk
   GLB	GenDrawMoniker
   GLB	GenFindParent
   GLB  GenGetMonikerPos
   GLB	GenGetMonikerSize
   GLB	GenSwapLockParent

   GLB	GenCheckIfFullyUsable	Check to see if object is fully usable.
   GLB	GenCheckIfFullyEnabled	Calls specific UI master class if grown
   GLB	GenCheckIfSpecGrown	Check to see if specific master class has
					grown out yet

EC GLB	GenCheckGenAssumption
EC GLB	GenEnsureNotUsable
EC GLB	ECEnsureInGenTree

   EXT  GenSetByte              Simple routines to fetch & stuff gen instance
   EXT  GenSetWord              Simple routines to fetch & stuff gen instance
   EXT	GenSetDWord		Simple routines to fetch & stuff gen instance
   EXT	GenGetDWord		Simple routines to fetch & stuff gen instance
   EXT	GenSetBitInByte		Simple routines to fetch & stuff gen instance
   
   EXT	GenReplaceMatchingDWord
   EXT	GenCallSpecIfGrown	Calls specific UI master class if grown

In Movable resources:
---------------------
   GLB  GenAddChildUpwardLinkOnly
   GLB	GenFindMoniker
   GLB	GenInsertChild
   GLB  GenProcessGenAttrsBeforeAction
   GLB  GenProcessAction
   GLB  GenProcessGenAttrsAfterAction
   GLB	GenRemoveDownwardLink
   GLB	GenSetUpwardLink
   GLB	GenSpecShrink
   GLB	GenFindObjectInTree
   GLB	GenCheckKbdAccelerator

   EXT	GenQueryUICallSpecificUI
   EXT	GenSpecShrinkBranch

EC EXT	ECGetGenClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Don	9/89		Added GenCopyChunk

DESCRIPTION:
	Utility routines for Gen* objects

	$Id: genUtils.asm,v 1.1 97/04/07 11:45:32 newdeal Exp $

------------------------------------------------------------------------------@

JustECCode	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCheckGenAssumption

DESCRIPTION:	Checks that object is generic object and that generic part
		been grown out

CALLED BY:	GLOBAL (EC)

PASS:
	*ds:si	- object to check

RETURN:
	FatalError if not generic object or generic part not grown

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@
GenCheckGenAssumption	proc	far
	class	GenClass
if	ERROR_CHECK
	pushf
	push	ax, bx
	call	SysGetECLevel
	test	ax, mask ECF_NORMAL
	pop	ax, bx
	jz	done
	push	di
	push	es

	mov	di, segment GenClass
	mov	es, di
	mov	di, offset GenClass
	call	ObjIsObjectInClass
	ERROR_NC UI_GEN_OBJECT_REQUIRED_FOR_THIS_OPERATION

	mov	di, ds:[si]
	cmp	ds:[di].Gen_offset, 0
	jnz	CGA_90
	ERROR	UI_GEN_USED_BEFORE_GROWN
CGA_90:
	pop	es
	pop	di
done:
	popf
endif
	ret
GenCheckGenAssumption	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenEnsureNotUsable

DESCRIPTION:	Checks that generic object is not usable

CALLED BY:	GLOBAL (EC)

PASS:
	*ds:si	- object to check

RETURN:
	FatalError if generic object is usable

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@
GenEnsureNotUsable	proc	far
if	ERROR_CHECK
	class	GenClass
	uses	cx
	.enter
	pushf
	push	ax, bx
	call	SysGetECLevel
	test	ax, mask ECF_NORMAL
	pop	ax, bx
	jz	done
	mov	cx, -1			; no optimizations for EC code
	call	GenCheckIfFullyUsable
	ERROR_C		UI_ERROR_CAN_NOT_DO_OPERATION_WHEN_USABLE
done:
	popf
	.leave
endif
	ret
GenEnsureNotUsable	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECEnsureInGenTree

DESCRIPTION:	Checks that generic object is generic tree

CALLED BY:	GLOBAL (EC)

PASS:
	*ds:si	- object to check

RETURN:
	FatalError if generic object is not in generic tree

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@
ECEnsureInGenTree	proc	far
	class	GenClass
if	ERROR_CHECK
	pushf
	push	ax, bx
	call	SysGetECLevel
	test	ax, mask ECF_NORMAL
	pop	ax, bx
	jz	done
	push	bx
	push	si
	call	GenFindParent
	tst	bx
	ERROR_Z	UI_FUNCTION_REQUIRES_THAT_GENERIC_OBJECT_BE_IN_TREE
	pop	si
	pop	bx
done:
	popf
endif
	ret
ECEnsureInGenTree	endp

JustECCode	ends

;
;---------------
;

Resident segment resource

if	(0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGetDisplayScheme
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the display scheme for the passed object.

CALLED BY:	GLOBAL (utility)
PASS:		*ds:si - Generic object to get the display scheme for
RETURN:		Display scheme structure in ax,cx,dx,bp
		al - DS_colorScheme	;(not to be used by applications)
		ah - DS_displayType
		cx - DS_unused
		dx - DS_fontID
		bp - DS_pointSize

DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/90		stolen from Tony (GetAppDisplayScheme)
	doug	10/90		added cached uiDisplayScheme support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenGetDisplayScheme	proc	far
	uses	bx,si,di

	push	ds
	mov	ax, segment dgroup
	mov	ds, ax
					; See if there is only one such beast,
					; and it is cached here in the UI
	test	ds:uiFlags, mask UIF_HAVE_CACHED_DISPLAY_SCHEME
	jz	hardWay
	mov	ax, {word} ds:[uiDisplayScheme].DS_colorScheme
	mov	cx, ds:[uiDisplayScheme].DS_unused
	mov	dx, ds:[uiDisplayScheme].DS_fontID
	mov	bp, ds:[uiDisplayScheme].DS_pointSize
	pop	ds
	ret

hardWay:
	pop	ds

	.enter
	mov	di, si			;Save object handle
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	tst	bx			;If application object found, branch
	jnz	common
					; if NO application object found,
					; then this must be something like
					; a popup-window owned by the UI
					; itself. Use VUP method, first
					; trying for a visible parent, & if
					; that fails, a generic parent.

	; We *must* find the parent and send the VUP_QUERY there or
	; we recurse infinitely (OpenWinVupQuery will call us again...).

	mov	si, di
	call	VisFindParent		; see if this object has a visible
	tst	bx			; 	parent
	jnz	doVupQuery		; if so, VUP through it.

					; if not, try generic parent
	mov	si, di			; Restore obj chunk handle
EC <	push	es							>
EC <	mov	di, segment GenClass					>
EC <	mov	es,di							>
EC <	mov	di, offset GenClass					>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC GEN_GET_DISPLAY_SCHEME_REQUIRES_GEN_OBJECT		>
EC <	pop	es							>
	call	GenFindParent		; Get OD of generic parent in bx:si

doVupQuery:
	mov	ax,MSG_VIS_VUP_QUERY	; Do VUP query to get display scheme
	mov	cx,VUQ_DISPLAY_SCHEME	;
common:
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret

GenGetDisplayScheme	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCheckIfSpecGrown

DESCRIPTION:	Tests to see if generic object has been grown into a specific
		one or not

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si	- object to test

RETURN:
	carry	- set if grown into specific object

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	stevey	7/94		several optimizations

------------------------------------------------------------------------------@

GenCheckIfSpecGrown	proc	far
	uses	si
	class	VisClass		; Need access to vis & gen stuff
	.enter
					; Has specific part been grown?
	mov	si, ds:[si]		; use si to avoid segment override
	tst	ds:[si].Vis_offset	; clears carry (assumes not grown)
	jz	done			; if not grown, we're done
	stc				; fastest if object is grown
					; (most common case)
; Can't do this, as some specific objects have no specific instance data!
; Will have to rely on object system correctly leaving master offset at
; 0 before grown, & non-zero after.
;	cmp	ax, ds:[di].Gen_offset	; See if of size 0
;	je	specNotGrown

done:
	.leave
	ret

GenCheckIfSpecGrown	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCallSpecIfGrown

DESCRIPTION:	Calls superclass of GenClass if specific UI part of object
		has been grown. NOTE that this does NOT call this superclass
		of the current class level, but actually the variant 
		superclass of this generic object.

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- object
	es	- segment of GenClass
	ax	- method to send
	cx, dx, bp	- data to send

RETURN:
	carry	- set if specific UI class called, clear if not

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

GenCallSpecIfGrown	proc	far
	call	GenCheckIfSpecGrown
	jnc	done
	mov	di, segment GenClass
	mov	es, di
	mov	di, offset GenClass
	call	ObjCallSuperNoLock
	stc				; Indicate specific UI called
done:
	ret
GenCallSpecIfGrown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenCallParentEnsureStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls GenCallParent after ensuring that there is some minimal
		amount of stack space.

CALLED BY:	GLOBAL
PASS:		args for GenCallParent
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenCallParentEnsureStack	proc	far	uses	di
	.enter
	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	call	GenCallParent
	call	ThreadReturnStackSpace
	.leave
	ret
GenCallParentEnsureStack	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCallParent

DESCRIPTION:	Call the parent of a generic object

CALLED BY:	GLOBAL (utility)
		can also MSG_GEN_CALL_PARENT

PASS:
	*ds:si - instance data
	ax - method to pass
	cx, dx, bp - data for method

RETURN:
	carry	- clear if null parent link, else set by method called.
	ax, cx, dx, bp - return values

	bx, si	- unchanged
	ds	- updated segment

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

GenCallParent	proc	far
	class	GenClass
	push	bx, di
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, offset Gen_offset	; Call generic parent
	mov	di, offset GI_link	; Pass generic linkage
	call	ObjLinkCallParent
	pop	bx, di
	ret

GenCallParent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenGotoParentTailRecurse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Method handler to do nothing but GenCallParent.  May ONLY
		be used to replace a:

			GOTO	GenCallParent
			
		from within a method handler, as the non-EC version
		optimally falls through to GenGotoParentTailRecurse.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- method

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenGotoParentTailRecurse		proc	far
	class	GenClass

	call	GenFindParent		; Find parent object

EC <	mov	di, mask MF_CALL					>
EC <	call	ObjMessage						>
EC <	ret								>

NEC <	FALL_THRU	ObjMessageCallFromHandler	 	 	>

GenGotoParentTailRecurse		endp

;--


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ObjMessageCallFromHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used in place of:

			mov	di, mask MF_CALL
			GOTO ObjMessage

		... where ds is pointing to a currently locked object block
		that is likely to also be the destination block.  Optimizes
		stack usage for this case.

CALLED BY:	INTERNAL
PASS:		ds	- any locked object block
		ax, bx, si, cx, dx, bp	- per ObjMessage
RETURN:
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessageCallFromHandler	proc	far
					; Call OD, but check for in same
					; block (do faster call)
	cmp	bx, ds:[LMBH_handle]		;in same block ?
	jne	differentBlock			;skip if not...

EC <	call	ObjCallInstanceNoLock				>
EC <	ret							>

NEC <	jmp	ObjGotoInstanceTailRecurse			>

differentBlock:
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

ObjMessageCallFromHandler	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenFindParent

DESCRIPTION:	Find the parent of a generic object

CALLED BY:	GLOBAL (utility)
		can also use MSG_GEN_FIND_PARENT

PASS:
	*ds:si - instance data

RETURN:
	^lbx:si - parent

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

GenFindParent	proc	far
	class	GenClass
	push	di
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, offset Gen_offset	; Call generic parent
	mov	di, offset GI_link	; Pass generic linkage
	call	ObjLinkFindParent
	pop	di
	ret

GenFindParent	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSwapLockParent

DESCRIPTION:	Utility routine to setup *ds:si to be the generic parent of
		the current object.  To be used in cases where you want
		to get access to a generic parent's instance data, or 
		prepare to call a routine where *ds:si much be the object,
		or for cases where you otherwise might be doing a
		series of GenCallParent's, which can be somewhat expensive.

		USAGE:

							; *ds:si is our object
			push	si			; save chunk offset
			call	GenSwapLockParent	; set *ds:si = parent
			push	bx			; save bx (handle
							; of child's block)


			pop	bx			; restore bx
			call	ObjSwapUnlock
			pop	si			; restore chunk offset


CALLED BY:	GLOBAL (utility)

PASS:		*ds:si - instance data of object

RETURN:		carry	- set if successful (clear if no parent)
		*ds:si	- instance data of parent object  (si = 0 if no parent)
		bx	- block handle of original object, which is
			  still locked.

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@

GenSwapLockParent	proc	far
	class	GenClass
	push	di

EC<	call	GenCheckGenAssumption	; Make sure gen data exists >

	mov	bx, offset Gen_offset	; Call generic parent
	mov	di, offset GI_link	; Pass generic linkage

	call	ObjSwapLockParent
	pop	di
	ret

GenSwapLockParent	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSendToChildren

DESCRIPTION:	Send method to all children of generic composite

CALLED BY:	GLOBAL (utility)
		can also use MSG_GEN_SEND_TO_CHILDREN

PASS:
	*ds:si - instance data
	ax - method to pass
	cx, dx, bp - data for method

RETURN:
	cx, dx, bp - unchanged
	ds 	- updated to point at segment of same block as on entry
	es	- unchanged, not fixed up

DESTROYED:
	bx, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version

------------------------------------------------------------------------------@

GenSendToChildren	proc	far
	class	GenClass

EC <	mov	di, 1000		; EC code may sometimes run out	>
EC <	call	ThreadBorrowStackSpace	;  of stack space here.		>
EC <	push	di							>

EC <	call	ECCheckObject						>
	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx, offset GI_link	; Pass offset to LinkPart
	push	bx
	clr	bx			; Use standard function
	push	bx
	mov	bx,OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	push	bx
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
EC <	pop	di							>
EC <	call	ThreadReturnStackSpace	; return borrowed stack space	>

	ret

GenSendToChildren	endp




COMMENT @----------------------------------------------------------------------

FUNCTION:	GenDrawMoniker

DESCRIPTION:	Draw an object's visual moniker

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si - instance data
	cl - how to draw moniker: DrawMonikerFlags
	ss:bp  - DrawMonikerArgs

RETURN:
	ax, bx - position the moniker was drawn at
	bp - preserved

PASSED TO MONIKER:
       When designing a moniker for a gadget, here's what you can expect to get:
       
       		* Line color, text color, area color set to the desired moniker
		  for that gadget and specific UI, typically black.  You should
		  use these if your gstring is black and white.  If you're using
		  color, you can choose your own colors but you must be sure 
		  they look OK against all of the specific UI background colors.
		  
		* Pen position set to the upper left corner of where the moniker
		  should be drawn.  Your graphics string *must* be drawn
		  relative to this pen position.
       
       		* The moniker must return all gstate variables intact, except
		  that colors and pen position can be destroyed.
		  
DESTROYED:
	cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@


GenDrawMoniker	proc	far
	class	GenClass

	segmov	es, ds
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset		; ds:bx = GenInstance
	mov	bx, ds:[bx].GI_visMoniker	;*ds:bx = visMoniker
	GOTO	VisDrawMoniker

GenDrawMoniker	endp


Resident	ends

;
;---------------
;
		
GetUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenGetMonikerPos

DESCRIPTION:	Get the position of an object's visual moniker

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si - instance data
	cl - how to draw moniker: MonikerDrawFlags
	ss:bp  - DrawMonikerArgs

RETURN:
	ax, bx - position of the moniker 
	bp - preserved

DESTROYED:
	cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenGetMonikerPos	proc	far
	class	GenClass
	segmov	es, ds
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset		; ds:bx = GenInstance
	mov	bx, ds:[bx].GI_visMoniker	;*ds:bx = visMoniker
	GOTO	VisGetMonikerPos

GenGetMonikerPos	endp

GetUncommon	ends

;
;---------------
;
		
Resident	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenGetMonikerSize

DESCRIPTION:	Get the size of an object's visual moniker

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si - instance data
	bp - graphics state (containing font and style) to use
	ax - height of the system font if known, zero if not

RETURN:
	cx - moniker width
	dx - moniker height

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenGetMonikerSize	proc	far
	class	GenClass
	push	di
	push	es
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		; ds:di = GenInstance
	mov	di, ds:[di].GI_visMoniker	;*ds:di = visMoniker
	segmov	es, ds				;*es:di = visMoniker

	GOTO	GetMonikerSizeCommon, es, di
						;will do error checking

GenGetMonikerSize	endp
	


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCallNextSibling

DESCRIPTION:	Call next sibling of this generic object

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si - instance data
	ax - method to pass
	cx, dx, bp - data for method

RETURN:
	carry	- may be set by method handler, will be clear if no next
		sibling is found.
	ax, cx, dx, bp - returned from method handler
	ds	- updated to point at segment of same block as on entry

DESTROYED:
	bx, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	8/89		Initial version

------------------------------------------------------------------------------@


GenCallNextSibling	proc	far
	class	GenClass
	push	bx, di
EC<	call	GenCheckGenAssumption	; Make sure gen data exists >
	mov	bx, offset Gen_offset	; Call generic sibling
	mov	di, offset GI_link	; Pass generic linkage
	call	ObjLinkCallNextSibling
	pop	bx, di
	ret
GenCallNextSibling	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCopyChunk

DESCRIPTION:	Copy an LMem chunk to a newly created chunk

CALLED BY:	GLOBAL (utility)

PASS:		*es:ax	- Chunk to copy
		bp - CompChildFlags (only uses CCF_MARK_DIRTY,clear other bits)
			if CCF_MARK_DIRTY is set, set new chunk dirty
			if CCF_MARK_DIRTY is clear, set new chunk IGNORE_DIRTY

		ds	- Segment in which to create new chunk

RETURN:		ds:*ax	- New chunk
		ds,es - possibly moved (ES, only if the same as DS)

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Create a new chunk (in the correct segment)
		Copy the data from old to new

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/89		Initial version
	atw	4/90		Added DIRTY/IGNORE_DIRTY flag
------------------------------------------------------------------------------@

GenCopyChunk	proc	far
	uses	si, di, bx, cx, bp
	.enter

EC <	test	bp, not mask CCF_MARK_DIRTY				>
EC <	ERROR_NZ BAD_FLAGS_PASSED_TO_GEN_COPY_CHUNK			>

	; Test for empty handle
	;
	tst	ax
	jz	exit			;If no chunk, exit

					; Chunk *es:ax -> new chunk *ds:ax
	; Create a new chunk
	;
	push	ax			;Save chunk handle of source
	mov_tr	si, ax			; *ES:SI <- source
	mov	si, es:[si]		; es:si = source
	clr	cx			; assume source chunk is emptr
	cmp	si, -1			; is source chunk size = 0?
	je	haveSize		; skip if so...

	ChunkSizePtr	es, si, cx	; cx = size

haveSize:

;	ALLOCATE THE DESTINATION CHUNK

	mov	al, mask OCF_DIRTY	;Assume that chunk should be dirty.
	test	bp, mask CCF_MARK_DIRTY	;If so, branch...
	jne	10$			;
	mov	al, mask OCF_IGNORE_DIRTY ; ...else, mark it as IGNORE_DIRTY
10$:
	call	LMemAlloc		; allocate a new chunk

	pop	si			;*ES:SI <- source chunk
	
	; Copy the old chunk => new chunk
	;
	tst	cx			; empty chunk?
	jz	exit			; skip if so...

	mov	di, ax			;*DS:DI <- dest chunk
	mov	bx, es			;BX <- source segment
	mov	bp, ds			;CX <- dest segment
	mov	ds, bx			;DS <- source segment
	mov	es, bp			;ES <- dest segment
;
;	Now, *ES:DI = dest, *DS:SI = source
;
	mov	di, es:[di]		;ES:DI <- dest 
	mov	si, ds:[si]		;DS:SI <- source
	rep	movsb			; Copy over contents
	mov	ds, bp			;Restore ES,DS
	mov	es, bx
exit:
	.leave
	ret
GenCopyChunk	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSetByte

DESCRIPTION:	Stores a byte of data into generic instance data.  Marks
		the object dirty and returns the carry set if the new byte
		differs from the old byte.

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- object
	bx	- offset within Gen master group
	cl	- byte to store into instance data

RETURN:
	carry set if setting the byte changes the value of the instance data

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version
------------------------------------------------------------------------------@

GenSetByte	proc	far
	class	GenClass
	push	di
	mov	di, ds:[si]		; point at instance
	add	di, ds:[di].Gen_offset	; get offset to Gen master part
	add	di, bx			; add in offset into gen part
	cmp	ds:[di], cl
	je	exit			; no difference, exit, carry clear
	mov	ds:[di], cl		; else set new data
	call	ObjMarkDirty
	stc				; return carry set
exit:
	pop	di
	ret

GenSetByte	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSetWord

DESCRIPTION:	Store word of data into generic instance data.  Dirties the
		object and returns carry set if it changes the instance data.

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- object
	bx	- offset within Gen master group
	cx	- word to store into instance data

RETURN:
	carry set if new value changes the instance data

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version
------------------------------------------------------------------------------@

GenSetWord	proc	far
	class	GenClass
	push	di
	mov	di, ds:[si]		; point at instance
	add	di, ds:[di].Gen_offset	; get offset to Gen master part
	add	di, bx			; add in offset into gen part
	cmp	ds:[di], cx
	je	exit			; if same, exit, carry clear
	mov	ds:[di], cx
	call	ObjMarkDirty
	stc
exit:
	pop	di
	ret

GenSetWord	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSetDWord

DESCRIPTION:	Stores dword of data into generic instance data,
		marks object as dirty
		(seg:offset, handle:chunk)

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- object
	bx	- offset within Gen master group
	cx:dx	- dword

RETURN:

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version
------------------------------------------------------------------------------@

GenSetDWord	proc	far
	class	GenClass
	push	di
	mov	di, ds:[si]		; point at instance
	add	di, ds:[di].Gen_offset	; get offset to Gen master part
	add	di, bx			; add in offset into gen part
	cmp	cx, ds:[di].handle	
	jne	storeNew
	cmp	dx, ds:[di].chunk
	je	exit			; no, change, exit, carry clear
storeNew:
	mov	ds:[di].handle, cx	; high word
	mov	ds:[di].chunk, dx	; low word
	call	ObjMarkDirty
	stc				; mark as changed
exit:
	pop	di
	ret

GenSetDWord	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenGetDWord

DESCRIPTION:	Retrieves a DWord of data from generic instance data
		(seg:offset, handle:chunk)

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- object
	bx	- offset within Gen master group

RETURN:
	cx:dx	- dword at offset

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version
------------------------------------------------------------------------------@

GenGetDWord	proc	far
	class	GenClass
	push	si
	mov	si, ds:[si]		; point at instance
	add	si, ds:[si].Gen_offset	; get offset to Gen master part
	mov	cx, ds:[si][bx].handle	; dword high
	mov	dx, ds:[si][bx].chunk	; dword low
	pop	si
	ret
GenGetDWord	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	GenSetBitInByte

SYNOPSIS:	Sets a bit in a byte record, marking the byte dirty if the
		bit actually changed.
		
CALLED BY:	GenItemGroupSetIndeterminateState

PASS:		*ds:si -- object
		dl     -- bit to set/clear
		bx     -- offset to byte record in Gen instance data
		cx     -- non-zero if we're to set the bit, zero if to clear

RETURN:		carry set if state changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/20/92		Initial version

------------------------------------------------------------------------------@

GenSetBitInByte	proc	far			uses	bp, cx, dx, di
	class	GenClass
	.enter
	mov	bp, cx				;passed flag in bp
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	add	di, bx				; add in offset into gen part
	mov	cl, ds:[di]
	tst	bp
	jz	clearState
	ornf	cl, dl
	jmp	short finishState
clearState:
	not	dl
	andnf	cl, dl
finishState:
	call	GenSetByte			; set byte (if changed, will
						;   mark dirty)
	.leave
	ret
GenSetBitInByte	endp



Resident ends

;--------

BuildUncommon segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenReplaceMatchingDWord

DESCRIPTION:	Replaces DWord stored in generic instance data if it matches
		the search DWord passed

CALLED BY:	EXTERNAL

PASS:
	*ds:si	- object
	ax	- *_SET_<DWord> method to call to replace DWord
	bx	- offset within Gen master group to instance data
	ss:bp	- offset to BranchReplaceParams:
			BRP_searchParam
			BRP_replaceParam

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

GenReplaceMatchingDWord	proc	far	uses	ax, cx, dx, bp
	class	GenClass
	.enter

	push	si
	mov	si, ds:[si]		; point at instance
	add	si, ds:[si].Gen_offset	; get offset to Gen master part
	add	si, bx			; add in offset into gen part
	mov	cx, ss:[bp].BRP_searchParam.handle
	mov	dx, ss:[bp].BRP_searchParam.chunk
	cmp	cx, ds:[si].handle
	jne	done
	cmp	dx, ds:[si].chunk
	jne	done
	pop	si
	mov	cx, ss:[bp].BRP_replaceParam.handle
	mov	dx, ss:[bp].BRP_replaceParam.chunk
					; If matches search DWord, call method
					; to set new DWord
	call	ObjCallInstanceNoLock
	push	si
done:
	pop	si
	.leave
	ret
GenReplaceMatchingDWord	endp


BuildUncommon ends

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenFindMoniker

DESCRIPTION:	Find the specified moniker (or most approriate moniker) in
		this object's VisMonikerList, and optionally copy the
		Moniker into this generic object's block, OR replace the
		VisMonikerList with the moniker.

CALLED BY:	GLOBAL (utility)

PASS:		*ds:si - instance data for this Generic object
		carry set to use GenApplication's MonikerList
		bp	- VisMonikerSearchFlags (see visClass.asm)
				flags indicating what type of moniker to find
				in the VisMonikerList, and what to do with
				the Moniker when it is found.
		cx	- handle of destination block (if bp contains
				VMSF_COPY_CHUNK command)

RETURN:		carry flag = same
		ds updated if ObjectBlock moved as a result of chunk overwrite
		WARNING: If ES points to either of the blocks, and they move,
			 ES will *NOT* be updated.
		^lcx:dx	- VisMoniker (^lcx:dx = NIL if none)
		bx, bp = same

DESTROYED:	ax, di
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

NOTE:  If VMSF_COPY_CHUNK is passed, & the moniker selected by the
	search flags turns out to be in the same block as cx refers to,
	then the moniker is NOT copied, but instead its chunk handle is
	returned.  This may seem to be efficient, but may not yield the
	desired effect...
- no longer done - brianc 4/3/92

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Initial version

------------------------------------------------------------------------------@


GenFindMoniker	proc	far
	class	GenClass
	pushf

	jc	useApp			;skip to use application's list...

EC <	call	GenCheckGenAssumption	;Make sure gen data exists	>

	;Fetch chunk handle of Visual moniker

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	  ;ds:di = GenInstance
	mov	di, ds:[di].GI_visMoniker ;*ds:di = VisMoniker

	test	bp, mask VMSF_COPY_CHUNK ;check flag
	jnz	mustCopy		 ;skip to copy chunk...

	;if this moniker list is actually just one moniker, then we are done

	clr	ax			;clear ^lcx:dx, in case no moniker
	mov	dx, ax
	xchg	ax, cx			;ax = destination block, ^lcx:dx = NIL
	tst	di
	jz	done			;skip if no moniker list at all...

	mov	cx, ds:[LMBH_handle]	;set ^lcx:dx = moniker, in case not list
	mov	dx, di
	push	di
	mov	di, ds:[di]		;ds:di = VisMoniker
	test	ds:[di].VM_type, mask VMT_MONIKER_LIST
	pop	di
	jz	done			;skip if is single moniker...
	mov_tr	cx, ax			;cx = destination block

	;If we've been asked to replace the moniker list with a gstring moniker
	;then check for HINT_USE_ICON_TEXT_COMBINATION_MONIKER.

	test	bp, mask VMSF_REPLACE_LIST
	jz	mustCopy
	test	bp, mask VMSF_GSTRING
	jz	mustCopy

	push	bx
	mov	ax, HINT_USE_ICON_TEXT_COMBINATION_MONIKER
	call	ObjVarFindData
	mov	ax, ds:[bx].ITMP_flags
	mov	dx, ds:[bx].ITMP_spacing
	pop	bx
	jnc	mustCopy

	;Replace moniker list with icon/text combination moniker

	call	ReplaceMonikerListWithIconTextMoniker
	jmp	done

mustCopy: ;send a visual query upwards to find a display scheme

        call    UserGetDisplayType   		;Returns AH <- DisplayType

	;pass:	*ds:di = VisMoniker or VisMonikerList
	;	ah = DisplayType
	;	bp = VisMonikerSearchFlags
	;	cx = handle of destination block

	call	UserLimitDisplayTypeToStandard

	mov	bh, ah				;bh = DisplayType
	push	si
	call	VisFindMoniker
	pop	si

done:
	popf
	ret


useApp:
	;Pass:	cx = handle of destination block (if VMSF_COPY_CHUNK mode)
	;	ah = DisplayType
	;	bp = VisMonikerSearchFlags

	call	UserGetDisplayType		;Returns AH <- DisplayType
	call	UserLimitDisplayTypeToStandard
	mov	dh, ah				;dh = DisplayType
	mov	ax, MSG_GEN_APPLICATION_FIND_MONIKER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	UserCallApplication		;returns ^lcx:dx = VisMoniker
	jmp	short done
GenFindMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceMonikerListWithIconTextMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create icon/text combination moniker

CALLED BY:	GenFindMoniker
PASS:		*ds:si	= GenClass object
		ax	= ITMP_flags
		dx	= ITMP_spacing
		bp	= VisMonikerSearchFlags
RETURN:		^lcx:dx	= icon/text combination moniker
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/04/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceMonikerListWithIconTextMoniker	proc	near
searchFlags	local	VisMonikerSearchFlags	push	bp
monikerFlags	local	IconTextMonikerFlags	push	ax
monikerSpacing	local	word			push	dx
textMoniker	local	optr
iconMoniker	local	optr
	uses	ax,bx,cx,dx,si,di,bp
	.enter

EC <	test	ss:[searchFlags], mask VMSF_REPLACE_LIST		>
EC <	ERROR_Z	-1							>
EC <	test	ss:[searchFlags], mask VMSF_GSTRING			>
EC <	ERROR_Z	-1							>

	call	UserGetDisplayType
	call	UserLimitDisplayTypeToStandard
	mov	bh, ah

	push	si, bp
	mov	bp, VMS_TEXT shl offset VMSF_STYLE
	call	VisFindMoniker
	pop	si, bp

	movdw	ss:[textMoniker], cxdx

	push	si, bp
	mov	bp, ss:[searchFlags]
	call	VisFindMoniker
	pop	si, bp

	movdw	ss:[iconMoniker], cxdx

	; Now combine the monikers

	CheckHack <offset CITMF_POSITION_ICON_ABOVE_TEXT eq \
		   offset ITMF_POSITION_ICON_ABOVE_TEXT> 
	CheckHack <offset CITMF_SWAP_ICON_TEXT eq \
		   offset ITMF_SWAP_ICON_TEXT> 

	sub	sp, size CreateIconTextMonikerParams
	mov	bx, sp
	mov	ax, ss:[monikerFlags]		
	andnf	ax, mask CITMF_POSITION_ICON_ABOVE_TEXT or \
			mask CITMF_SWAP_ICON_TEXT
	mov	ss:[bx].CITMP_flags, ax
	mov	ax, ss:[monikerSpacing]
	mov	ss:[bx].CITMP_spacing, ax
	mov	ss:[bx].CITMP_destination, 0	; doesn't matter
	movdw	cxdx, ss:[iconMoniker]
	movdw	ss:[bx].CITMP_iconMoniker, cxdx
	movdw	cxdx, ss:[textMoniker]
	movdw	ss:[bx].CITMP_textMoniker, cxdx
	call	UserCreateIconTextMoniker
	add	sp, size CreateIconTextMonikerParams

	mov	cx, dx
	mov	dx, ax				; ^lcx:dx = VisMoniker

	.leave
	ret
ReplaceMonikerListWithIconTextMoniker	endp

Build	ends

;
;---------------
;
		
BuildUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenInsertChild

DESCRIPTION:	Add a child object to a composite.  Allows caller to state
	the handle and offset of the reference child rather than the reference
	child position, when the caller is lucky enough to be able to call
	a routine directly rather than through a method.

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si - instance data 

	^lcx:dx  - object to add
	^lax:bx  - reference child
	bp - flags for how to add child (InsertChildFlags)

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	ax, bx, cx, dx, di, bp
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version

------------------------------------------------------------------------------@


GenInsertChild	proc	far
	class	GenClass
EC <	call	VisCheckVisAssumption	; Make sure vis data exists >
EC <	push	bp							>
		;Test for any extraneous bits set
EC <	test	bp, not mask InsertChildFlags				>
EC <	ERROR_NZ VIS_ADD_OR_REMOVE_CHILD_BAD_FLAGS			>
EC <	and	bp, mask ICF_OPTIONS					>
EC <	cmp	bp, InsertChildOption					>
EC <	ERROR_AE VIS_ADD_OR_REMOVE_CHILD_BAD_FLAGS			>
EC <	pop	bp							>
	push	cx, dx
	mov	cx, ax			;pass reference child in cx:dx
	mov	dx, bx

	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	test	bp, mask ICF_MARK_DIRTY	;
	pushf				;
	and	bp, mask ICF_OPTIONS	;
	cmp	bp, ICO_FIRST		;
	je	VIC_noRef		;
	cmp	bp, ICO_LAST		;
	je	VIC_last
	push	bp			;save flags
	call	ObjCompFindChild
	pop	dx			;restore flags
	jc	VIC_last		;if can't find ref, just add as last
	cmp	dx, ICO_BEFORE_REFERENCE;If before reference, branch
	je	VIC_noRef		;
	inc	bp
	jmp	VIC_noRef
VIC_last:
	mov	bp, CCO_LAST
VIC_noRef:
	popf				;Restore mark dirty flag
	je	noMarkDirty
	or	bp, mask CCF_MARK_DIRTY
noMarkDirty:
	DoPop	dx, cx			;restore child
	GOTO	ObjCompAddChild

GenInsertChild	endp

BuildUncommon	ends

;
;---------------
;
		
Build	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenAddChildUpwardLinkOnly

DESCRIPTION:	Attaches object to a generic composite, by constructing an
		upward link only.  Used internally by specific UI, in cases
		where it is constructing UI components which need not be
		saved when the application is shut down.  This routine allows
		objects with the GS_USABLE flag set to be attached, so all
		updating must be handled by the caller.

CALLED BY:	GLOBAL (utility)
		can also use MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY

PASS:
	*ds:si	- composite object to add object to
	^lcx:dx - object to add (set up generic upward link for)

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/89		Initial version
------------------------------------------------------------------------------@

GenAddChildUpwardLinkOnly	proc	far
	push	ax, bx, cx, ds

	mov	bx, cx
	mov	cx, ds:[LMBH_handle]
	xchg	dx, si
	call	ObjLockObjBlock
	mov	ds, ax
					; *ds:si is object to add
					; ^lcx:dx is object to add it to.
	call	GenSetUpwardLink	; set the upward link only
	call	MemUnlock
	xchg	dx, si			; restore dx, si values

	pop	ax, bx, cx, ds
	ret

GenAddChildUpwardLinkOnly	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSetUpwardLink

DESCRIPTION:	Converts parent OD into a one-way link & stuffs it into the
		generic child's linkage.  Similar to GenAddChildUpwardLinkOnly
		except you have the child locked instead of the parent.

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si  - object to add (set up generic upward link for)
	^lcx:dx - parent composite object to add obj to

RETURN:

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/89		Initial version
------------------------------------------------------------------------------@

GenSetUpwardLink	proc	far
	class	GenClass
	push	di
EC <	call	ECCheckLMemObject					>
EC <	call	GenCheckGenAssumption	;Make sure gen data exists	>

	mov	di, ds:[si]		; get ptr to obj to add
	add	di, ds:[di].Gen_offset
					; & Set one way generic link upward
					; Start by assuming null parent...
	mov	ds:[di].GI_link.LP_next.chunk, cx
	mov	ds:[di].GI_link.LP_next.handle, cx
	jcxz	COWGLU_afterChunkSet
	inc	dx			; CHANGE TO BE PARENT LINK
	mov	ds:[di].GI_link.LP_next.chunk, dx
	dec	dx			; fixup dx

COWGLU_afterChunkSet:
	pop	di
	ret

GenSetUpwardLink	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	GenRemoveDownwardLink

SYNOPSIS:	Removes a child from the generic tree, preserving the upward
		link and the child's usable flag.

CALLED BY:	GLOBAL (utility)

PASS:		*ds:si -- handle of child
		bp - CCF_MARK_DIRTY bit set if this bit should be passed
		     to GenRemoveGenChild

RETURN:		nothing
		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/ 6/89	Initial version

------------------------------------------------------------------------------@

GenRemoveDownwardLink	proc	far
	class	GenClass
	push	ax, bx, cx, dx, di, bp
EC <	call	ECCheckLMemObject					>
;	mov	di, ds:[si]			;point to instance
;	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
;	mov	al, ds:[di].GI_states		;get the state flags	
;	and	al, mask GS_USABLE		;just keep usable flag
;	push	ax				;save it
;	and	ds:[di].GI_states, not mask GS_USABLE	;clear the usable flag
	
	push	si				;save si
	call	GenSwapLockParent		;set *ds:si = parent
	pop	dx				;restore child's handle
	push	dx				;save again
	mov	cx, bx				;child's block in cx
	push	bx				;save child's block
	
						;*ds:si is parent
						;^lcx:dx is object to remove
	call	GenRemoveGenChildLow		;remove the child
	call	GenAddChildUpwardLinkOnly	;and add upward link back in
	pop	bx				;restore bx
	call	ObjSwapUnlock
	pop	si				;child back in *ds:si	
;	pop	ax
;	mov	di, ds:[si]			;point to instance
;	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
;	or	ds:[di].GI_states, al		;or in the usable flag
	pop	ax, bx, cx, dx, di, bp
	ret
GenRemoveDownwardLink	endp


Build	ends
;
;----------------
;
GenUtils segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenInstantiateIgnoreDirty

DESCRIPTION:	Instantiate an object and mark it ignore dirty

CALLED BY:	UTILITY

PASS:
	Same as ObjInstantiate

RETURN:
	Same as ObjInstantiate

DESTROYED:
	Same as ObjInstantiate

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

; Place in GenUtils because this is something the specific UI normally uses,
; as opposed to the developer.  Is used to build out text edit areas everytime
; spin gadget comes up on screen.
;
GenInstantiateIgnoreDirty	proc	far
	call	ObjInstantiate
	push	ax, ds
	call	ObjLockObjBlock
	mov	ds, ax
	mov	ax, si				;ax = chunk
	push	bx
	mov	bx, mask OCF_IGNORE_DIRTY
	call	ObjSetFlags
	pop	bx
	call	MemUnlock
	pop	ax, ds
	ret
GenInstantiateIgnoreDirty	endp

GenUtils	ends
;
;----------------
;
Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenQueryUICallSpecificUI

DESCRIPTION:	Find a block of memory of the given size and type.

CALLED BY:	EXTERNAL

PASS:
	ax	- reference # of routine to call

RETURN:
	cx:dx - class to build into

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

GenQueryUICallSpecificUI	proc	far
	push	ax

	call	GenSpecGrowParents	; Force all generic parents to be 
					; specifically grown out before
					; this object is

	; NO MULTIPLE UI'S FOR NOW

if	1
	push	ds
	mov	bx, segment uiSpecUILibrary
	mov	ds, bx
	mov	bx, ds:[uiSpecUILibrary]
	pop	ds

else

	mov	cx, ds:[LMBH_handle]	; Just in case an app wants to subclass
	mov	dx, si			; this (as apps which create fields do)
					; this is the object we're trying to
					; get a UI for.
	mov	ax, MSG_GEN_APPLICATION_QUERY_UI
	call	UserCallApplication
	jc	GQUI_10

	mov	ax, MSG_SPEC_GUP_QUERY
	mov	cx, GUQT_UI_FOR_MISC
	call	GenCallParentEnsureStack
EC <	ERROR_NC	NO_SPECIFIC_UI					>

GQUI_10:

	mov	bx, ax			; put specific UI to use in bx

endif

EC <	tst	bx							>
EC <	ERROR_Z	NO_SPECIFIC_UI						>
EC <	call	ECCheckLibraryHandle					>

					; dx = segment of specific UI to use
	pop	ax
	mov	di,MSG_META_RESOLVE_VARIANT_SUPERCLASS
	call	ProcGetLibraryEntry
	GOTO	ProcCallFixedOrMovable

GenQueryUICallSpecificUI	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSpecShrink

DESCRIPTION:	"Unbuild" a generic object by shrinking the vis & specific
		master parts back to size 0, if they are not already there.

CALLED BY:	GLOBAL (utility)
		GenSpecShrinkBranch

PASS:	*ds:si	- generic object

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

GenSpecShrink	proc	far	uses ax, bx, dx, di, cx, bp
	class	VisClass		; Need acces to vis & gen stuff
	.enter
					; Has visual part been grown?
	mov	di, ds:[si]
	tst	ds:[di].Vis_offset
	jz	VisNotGrown

EC <	add	di, ds:[di].Vis_offset					>
EC <	test	ds:[di].VI_attrs, mask VA_REALIZED			>
EC <	ERROR_NZ	UI_VIS_MASTER_NOT_READY_FOR_UNBUILD		>
;removed to allow this to work for GenAppLazarus (see GenAppAttach)
;- brianc 3/8/93
;EC <	test	ds:[di].VI_specAttrs, mask SA_TREE_BUILT_BUT_NOT_REALIZED >
;EC <	jnz	AfterVisLinkTest					>
;EC <	cmp	ds:[di].VI_link.LP_next.handle, 0			>
;EC <	ERROR_NZ	UI_VIS_MASTER_NOT_READY_FOR_UNBUILD		>
;EC <AfterVisLinkTest:							>
EC <	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE		>
EC <	jz	NotComposite		; skip test if not composite	>
EC <	cmp	ds:[di].VCI_window, 0  	; see if window stored here	>
EC <	ERROR_NZ	UI_VIS_MASTER_NOT_READY_FOR_UNBUILD		>
EC <NotComposite:
				; NUKE the visible master instance data
	mov	bx, offset Vis_offset
	clr	ax
	call	ObjResizeMaster

				; NUKE all vardata for the Vis level.
	mov	cx, first VisVarData	; start of range
	mov	dx, first GenVarData-1	; end of range (inclusive)
	clr	bp			; nuke all entries
	call	ObjVarDeleteDataRange
VisNotGrown:
	clr	ax
	mov	di, ds:[si]		; zero out master offset
	mov	ds:[di].Vis_offset, ax

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].segment, ax	; Nuke variant class ptr, so that
	mov	ds:[di].offset, ax	; specific class to use is not defined

	.leave
	ret
GenSpecShrink	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSpecShrinkBranch

DESCRIPTION:	"Unbuild" a generic branch by shrinking the vis & specific
		master parts back to size 0, if they are not already there.

		Starts by recursively sending GenSpecShrinkBranch to any child
		which has been specifically grown.

		Relies on assumption that any object which has been 
		specifically grown has all parent objects grown as well.

CALLED BY:	EXTERNAL
		MSG_GEN_SET_NOT_USABLE

PASS:	*ds:si	- generic object

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@

GenSpecShrinkBranch	proc	far	uses ax, bx, cx, dx, bp, di
	class	VisClass		; Need acces to vis & gen stuff
	.enter

	call	GenCheckIfSpecGrown	; if already ungrown, quit
	jnc	done

	; UNBUILD CHILDREN
	mov	di, ds:[si]		; make sure composite
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GI_comp.CP_firstChild.handle, 0
	je	childrenDone		;if not, exit

	clr	bx			; initial child (first
	push	bx			; child of
	push	bx			; composite)
	mov	bx,offset GI_link
	push	bx			;push offset to LinkPart
NOFXIP <	push	cs			;push call-back routine	>
FXIP <		mov	bx, SEGMENT_CS					>
FXIP <		push	bx						>
	mov	bx,offset GenSpecShrinkCallBack
	push	bx

	mov	bx,offset Gen_offset
	mov	di,offset GI_comp
	call	ObjCompProcessChildren	;must use a call (no GOTO) since
					;parameters are passed on the stack
childrenDone:

	push	es
	mov	di, segment GenViewClass
	mov	es, di
	mov	di, offset GenViewClass
	call	ObjIsObjectInClass
	pop	es
	jnc	viewDone
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
.warn -private
	test	ds:[di].GVI_attrs, mask GVA_GENERIC_CONTENTS
.warn @private
	jz	viewDone		; no generic content
	push	si
.warn -private
	movdw	bxsi, ds:[di].GVI_content
.warn @private
EC <	call	ObjTestIfObjBlockRunByCurThread				>
EC <	ERROR_NZ	GVA_GENERIC_CONTENTS_MUST_BE_RUN_BY_SAME_THREAD	>
	call	ObjSwapLock		; generic content must be run by
					;	same thread
	call	GenSpecShrinkBranch	; shrink content
	call	ObjSwapUnlock
	pop	si
viewDone:

	; THEN UNBUILD THIS ONE
	call	GenSpecShrink		; Unbuild this object
done:
	.leave
	ret
GenSpecShrinkBranch	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSpecShrinkCallBack

DESCRIPTION:	Generically unbuilds branch at each child 

CALLED BY:	INTERNAL
			GenSpecShrinkBranch

PASS:
	*ds:si - child
	*es:di - composite
	cx, dx, bp -?

RETURN:
	carry - set to end processing
	cx, dx, bp - data to send to next child

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/90		Initial version

------------------------------------------------------------------------------@

GenSpecShrinkCallBack	proc	far
	class	GenClass
	call	GenCheckIfSpecGrown		; if already ungrown, quit
	jnc	done

	call	GenSpecShrinkBranch		; Unbuild from here on down

done:
	clc
	ret

GenSpecShrinkCallBack	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenSpecGrowParents

DESCRIPTION:	Make sure that this object's generic parent, & that obj's
		parent, all the way to the top, are specifically grown.  If
		we run into one that is already grown, we may safely assume
		that they are grown to the top.

		This should be called from every MSG_META_RESOLVE_VARIANT_SUPERCLASS in the
		generic UI, to make sure that we specific grow objects from
		the top down, not missing any objects.

		Enforces the assumption that any object which is specifically
		grown has its parents grown as well.

CALLED BY:	INTERNAL
		MSG_META_RESOLVE_VARIANT_SUPERCLASS handlers,
		GenQueryUICallSpecificUI

PASS:
	*ds:si	- generic object

RETURN:
	*ds:si	- generic object, w/all generic parents specifically grown.

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
------------------------------------------------------------------------------@


GenSpecGrowParents	proc	far	uses	bx, si
	class	GenClass
	.enter

	call	GenFindParent
	tst	bx
	jz	done

	mov	di, UI_STACK_SPACE_REQUIREMENT_FOR_RECURSE_ITERATION
	call	ThreadBorrowStackSpace
	push	di

	; See if parent run by same thread or not
	;
	cmp	bx, ds:[LMBH_handle]	; same block?
	je	sameThread
	call	ObjTestIfObjBlockRunByCurThread
	jz	sameThread

	; If parent object run by different thread, use message.
	;
	mov	ax, MSG_GEN_GROW_PARENTS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jmp	restoreStack

sameThread:
	call	ObjSwapLock
	call	GenCheckIfSpecGrown	; See if specifically grown
	jc	afterParent		; if so, then we can ASSUME
					; that all parents of that
					; object are grown as well,
					; & we can stop.

	call	GenSpecGrowParents	; Before growing this parent,
					; do his parents
	push	bx
	mov	bx, offset Vis_offset	; Grow our own parent
	call	ObjInitializePart
	pop	bx
afterParent:
	call	ObjSwapUnlock		; Restore ds as seg of our obj
restoreStack:
	pop	di
	call	ThreadReturnStackSpace
done:
	.leave
	ret

GenSpecGrowParents	endp

Build ends

;-------

Resident segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserCallSystem

DESCRIPTION:	Call the UI system object

CALLED BY:	GLOBAL (utility)

PASS:
	ax	- METHOD to pass to system object
	cx, dx, bp	- data to pass on
	ds	- segment of LMem block
			or block with ds:[LMBH_handle] = block handle

RETURN:
	carry		- returned
	ax, cx, dx, bp 	- data returned

	bx, si	- unchanged
	ds 	- updated to point at segment of same block as on entry

DESTROYED:
	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
------------------------------------------------------------------------------@

UserCallSystem	proc	far
	push	bx
	push	si

	push	ds
	mov	bx, segment idata
	mov	ds,bx
	mov	bx, ds:[uiSystemObj].handle
	mov	si, ds:[uiSystemObj].chunk
	pop	ds

	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	pop	si
	pop	bx
	ret

UserCallSystem	endp

Resident	ends
;
;-------------------
;
Common	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenProcessGenAttrsBeforeAction

DESCRIPTION:	Process attributes associated with a generic object
		which state what automatic things we should do upon
		the gadget being activated  (Call before sending any
		action method out)

CALLED BY:	GLOBAL (utility)
		GenTriggerTrigger

PASS:
	*ds:si	- generic object

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version
------------------------------------------------------------------------------@


GenProcessGenAttrsBeforeAction	proc	far
	uses ax, bx, di, cx, dx, bp
	class	GenClass
	.enter

	; SEE if we should mark app as busy
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	test	ds:[di].GI_attrs, mask GA_INITIATES_BUSY_STATE
	jz	GIT_NoBusyState
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	UserCallApplication

GIT_NoBusyState:

	; SEE if we should have APP hold up further UI
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	test	ds:[di].GI_attrs, mask GA_INITIATES_INPUT_HOLD_UP
	jz	GIT_NoHoldUp
	mov	ax, MSG_GEN_APPLICATION_HOLD_UP_INPUT
	call	UserCallApplication
GIT_NoHoldUp:

	; SEE if we should have APP discard further input
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	test	ds:[di].GI_attrs, mask GA_INITIATES_INPUT_IGNORE
	jz	GIT_NoIgnore
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	UserCallApplication
GIT_NoIgnore:

	; FINALLY, see if this terminates an interaction
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	test	ds:[di].GI_attrs, mask GA_SIGNAL_INTERACTION_COMPLETE
	jz	GTT_NoCompletion	; skip if not.
					; If so, then send notification
					; of completion
				; & send the method
	mov	cx, IC_INTERACTION_COMPLETE
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	GenCallParentEnsureStack

GTT_NoCompletion:

	.leave
	ret

GenProcessGenAttrsBeforeAction	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenProcessAction

DESCRIPTION:	Send the action specified, via MSG_GEN_OUTPUT_ACTION

		Note: this is an assembly utility.  C apps should
		use MSG_GEN_OUTPUT_ACTION() instead.

CALLED BY:	GLOBAL (utility)
		GenTriggerTrigger

PASS:	*ds:si	- generic object
	ax	- method to send
	cx, dx, bp	- data to send
	di	- MessageFlags
		  Flags referring to the data passed:
		  	MF_STACK	- set if data passed uses stack

		  Flags which should be passed to ObjMessage when calling
		  self with the MSG_GEN_OUTPUT_ACTION:
		  	MF_CALL		- NOTE:  nothing is returned from
					  MSG_GEN_OUTPUT_ACTION, & this routine
					  preserves registers, so usage is
					  be limited to synchronization-type
					  effects...
		  	MF_FORCE_QUEUE
		  	MF_INSERT_AT_FRONT
		  	MF_FIXUP_DS
		  	MF_FIXUP_ES

	On stack (pushed in this order):
		word - high word of optr to send to
		word - low word of optr to send to

RETURN:
	If MF_FIXUP_DS specified:
		ds - updated to point at segment of same block as on entry
	If MF_FIXUP_ES specified:
		es - updated to point at segment of same block as on entry

DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/91		Initial version
------------------------------------------------------------------------------@

GenProcessAction	proc	far	target:optr
	uses	ax, bx, cx, dx, di
	.enter
	push	si, di, bp
	and	di, mask MF_STACK	; keep stack bit only
	or	di, mask MF_RECORD	; record this event
	clr	bx
	clr	si
	mov	bp, ss:[bp]		;Get original BP that was passed in
					; (it was nuked by the .enter above)
	call	ObjMessage		; returns handle of event in di
	mov_tr	ax, di
	pop	si, di, bp

	movdw	cxdx, target
	mov	bp, ax			; pass handle of event in bp
	mov	ax, MSG_GEN_OUTPUT_ACTION
	and	di, not (mask MF_STACK)
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage
	.leave
	ret	@ArgSize

GenProcessAction	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenProcessGenAttrsAfterAction

DESCRIPTION:	Process attributes associated with a generic object
		which state what automatic things we should do after the
		action for a gadget has been activated.

CALLED BY:	GLOBAL (utility)
		GenTriggerTrigger

PASS:
	ds:*si	- generic object

RETURN:
	ds - updated to point at segment of same block as on entry

DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/89		Initial version
------------------------------------------------------------------------------@


GenProcessGenAttrsAfterAction	proc	far
	uses ax, bx, di, cx, dx, bp
	class	GenClass
	.enter

	; SEE if we should mark app as busy
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	test	ds:[di].GI_attrs, mask GA_INITIATES_BUSY_STATE
	jz	GIT_NoBusyState
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	UserSendToApplicationViaProcess

GIT_NoBusyState:

	; SEE if we should have APP hold up further UI
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	test	ds:[di].GI_attrs, mask GA_INITIATES_INPUT_HOLD_UP
	jz	GIT_NoHoldUp
	mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT
	call	UserSendToApplicationViaProcess
GIT_NoHoldUp:

	; SEE if we should have APP discard further input
	mov	di, ds:[si]		; get ptr to instance data
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	test	ds:[di].GI_attrs, mask GA_INITIATES_INPUT_IGNORE
	jz	GIT_NoIgnore
	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	UserSendToApplicationViaProcess
GIT_NoIgnore:

	.leave
	ret

GenProcessGenAttrsAfterAction	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenFindObjectInTree

DESCRIPTION:	Find an object within the generic tree

CALLED BY:	GLOBAL (utility)

PASS:
	ds - segment of LMem block, or block
		in which ds:[LMBH_handle] = block handle
	^lbx:si - object
	es:di - table of bytes where each byte is the child number at the
		given level.  -1 signals the end of the table
		(es:di *cannot* be pointing into the movable XIP resource.)

RETURN:
	^lcx:dx - object
	ds - updated to point at segment of same block as on entry

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

GenFindObjectInTree	proc	far	uses	ax, bx, si, di, bp
	.enter

if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr of the table is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif		

treeLoop:

	; get child number, brach if done

	clr	cx
	mov	cl, es:[di]
	cmp	cl, -1
	jz	done

	; find OD

	push	di
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	di

	mov	bx, cx
	mov	si, dx
	inc	di
	jmp	treeLoop

done:
	mov	cx, bx
	mov	dx, si

	.leave
	ret

GenFindObjectInTree	endp

Common ends

;-----------

JustECCode segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECGetGenClass

DESCRIPTION:	Return the generic class of an object

CALLED BY:	EXTERNAL

PASS:
	*ds:si - object

RETURN:
	es:di - generic class

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


if	ERROR_CHECK		; NOT EXPORTED, so don't need to have ret 
				; in non-ec case

if	0	;Not currently used

ECGetGenClass	proc	far
	class	GenClass
EC <	call	ECCheckLMemObject					>
	mov	di,ds:[si]
	les	di,ds:[di].MB_class		;es:di = class
ECGGC_loop:
	cmp	es:[di].Class_masterOffset,offset Gen_offset
	ERROR_B	OBJECT_NOT_GENERIC
	je	ECGGC_found
	les	di,es:[di].Class_superClass
	jmp	ECGGC_loop

ECGGC_found:
	ret

ECGetGenClass	endp

endif

endif

JustECCode ends

Navigation segment resource


COMMENT @----------------------------------------------------------------------

ROUTINE:	GenCheckKbdAccelerator

SYNOPSIS:	See if keyboard accelerator matches.

CALLED BY:	GLOBAL (utility)

PASS:		*ds:si -- handle of object
		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		carry set if accelerator found 

DESTROYED:	di, ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 4/90		Initial version

------------------------------------------------------------------------------@

GenCheckKbdAccelerator	proc	far
	class	GenClass
	kbdAccelerator	local	KeyboardShortcut
	savedBp		local	word	
	
	mov	di, bp				;save bp
	.enter
	mov	savedBp, di			;   in a local variable
	
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	mov	di, ds:[di].GI_kbdAccelerator	;get kbd accelerator to match
	test	di, mask KS_CHAR		;anything to do?
	clc					;assume not
	jz	exit				;no, exit
	;
	; Set ds:si to point to our moniker.
	;
	mov	kbdAccelerator, di		;store in local var
	push	ds, si
	segmov	ds, ss, si
	lea	si, kbdAccelerator
	mov	ax, 1				;one entry in table
	push	bp				;save local vars ptr
	mov	bp, savedBp			;pass original bp
	call	FlowCheckKbdShortcut		;see if shortcut matches
	pop	bp				;restore local vars ptr
	pop	ds, si				;carry set if moniker found
	jc	exit
	;
	; check extra kbd accelerators
	;
	push	bx
	mov	ax, ATTR_GEN_EXTRA_KBD_ACCELERATORS
	call	ObjVarFindData
	jnc	noExtra				;none, no accelerator found
	VarDataSizePtr	ds, bx, ax		;ax = byte size
	shr	ax, 1				;ax = num words (accels)
	push	si
	mov	si, bx				;ds:si = accel table
	push	bp
	mov	bp, savedBp
	call	FlowCheckKbdShortcut		;carry set if match
	pop	bp
	pop	si
noExtra:
	pop	bx
exit:
	.leave
	ret

GenCheckKbdAccelerator	endp

Navigation ends

;
;----------------
;

Resident segment resource
       

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenCheckIfFullyUsable

DESCRIPTION:	Tests to see if this object & all parents above it are
		marked as GS_USABLE.  This routine is thorough, making
		no optimizations.   It does NOT force the growing out of
		specific or visual instance data.

		NOTE:   specific UI objects shouldn't need to use this, as
			objects will not be resolved out to specific UI classes
			if not FULLY USABLE... that is, if not in the middle
			of processing MSG_SPEC_SET_NOT_USABLE.

CALLED BY:	GLOBAL (utility)

PASS:
	*ds:si	- object to test

	cx	- optimization flag:

		  If non-zero, routine will take no shortcuts, & check each
		  object up to GenApplication or GenSystem before approving
		  the object as FULLY USABLE.

		  If clear, then we use the steady-state axim that any object
		  that is VA_REALIZED must be FULLY USABLE.
		  This assumption is a correct one during steady-state
		  conditions, and in the processing of setting objects
		  USABLE, but not when evaluating whether an object is now
		  fully usable or not based on an object possibly above it
		  in the tree having become NOT_USABLE.


RETURN:
	carry	- set if FULLY USABLE
	ds - updated to point at segment of same block as on entry

DESTROYED:
	Nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	Doug	4/92		Rewrote for new thread model
------------------------------------------------------------------------------@

GenCheckIfFullyUsable	proc	far	uses	ax, bx, si, di
	class	GenClass
	.enter

checkThisObj:
EC <	call	GenCheckGenAssumption					>
	; if THIS object is not USABLE, then certainly is not FULLY usable.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_USABLE
	jz	done			; (test clears carry)

	; If this one IS USABLE, check optimization bit to see if we
	; can establish usability based on VA_REALIZED

	tst	cx			; if flag non-zero, no optimization.
	jnz	afterOpt

	call	VisCheckIfVisGrown	; See if has visible part
	jnc	afterOpt		; if not, skip optimization
					; Otherwise, see if realized.

EC <	; Make sure object actually of VisClass				>
EC <	;								>
EC <	push	di, es							>
EC <	mov	di, segment VisClass					>
EC <	mov	es, di							>
EC <	mov	di, offset VisClass					>
EC <	call	ObjIsObjectInClass					>
EC <	pop	di, es							>
EC <	ERROR_NC	BAD_ASSUMPTION_IN_GenCheckIfFullyUsable		>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED

EC <	jz	afterOpt						>
EC <	push	cx							>
EC <	mov	cx, -1			; no optimizations		>
EC <	call	GenCheckIfFullyUsable					>
EC <	pop	cx							>
EC <	ERROR_NC	BAD_ASSUMPTION_IN_GenCheckIfFullyUsable		>

	stc				; if REALIZED, then must be
					; FULLY_USABLE.
	jnz	done

afterOpt:
	; Nope, have to continue up tree
	;
	mov	ax, si			; save chunk of child object in ax,
					; in case needed
	call	GenFindParent
	cmp	bx, ds:[LMBH_handle]	; if parent in same block, just loop
	je	checkThisObj		; back to walk up tree

	tst	bx
	jz	reachedTop		; branch to handle case of no parent

	call	ObjTestIfObjBlockRunByCurThread
	jne	reachedTop		; branch to handle case of diff thread

	; Else just a change of blocks, but same running thread.  Keep
	; checking them bits...
	;
	call	ObjSwapLock		; set *ds:si to be parent
	call	GenCheckIfFullyUsable	; travel recursively up tree
	call	ObjSwapUnlock		; return flag according to parent
done:
	.leave
	ret


reachedTop:
	; OK.  We've just reached the top of a branch run by a particular
	; thread, that is, we have a generic parent that is run by a different
	; thread (or NULL).  The rules are as follows:  If THIS top object is a
	; GenApplication or GenSystem object, we will deem the branch FULLY
	; USABLE.  If not, we have to call the parent object to find out.  If
	; there is no parent, then this branch is NOT fully usable.

	xchg	ax, si			; get *ds:si = top object,
					; ^lbx:ax = parent
	push	dx
	mov	dx, MSG_GEN_CHECK_IF_FULLY_USABLE
	call	GenCheckIfFullyXXCommon
	pop	dx
	jmp	short done

GenCheckIfFullyUsable	endp

;
;----------------------------------------
;

GenCheckIfFullyXXCommon	proc	near

	; dx	= message to call

	; OK.  We've just reached the top of a branch run by a particular
	; thread, that is, we have a generic parent that is run by a different
	; thread (or NULL).  The rules are as follows:  If THIS top object is a
	; GenApplication or GenSystem object, we will deem the branch FULLY
	; ENABLED/USABLE.  If not, we have to call the parent object to find
	; out.  If there is no parent, then this branch is NOT fully usable/
	; enabled.

	push	es
	mov	di, segment GenApplicationClass
	mov	es, di
	mov	di, offset GenApplicationClass
	call	ObjIsObjectInClass	; see if GenApplication object
	pop	es
	jc	done

	push	es
	mov	di, segment GenSystemClass
	mov	es, di
	mov	di, offset GenSystemClass
	call	ObjIsObjectInClass	; see if GenSystem object
	pop	es
	jc	done

	tst	bx			; if no parent, not fully usable.
	jz	done			; so exit w/carry clear. (tst clears it)

	xchg	ax, si			; get ^lbx:si = parent
	mov	ax, dx			; get message to call
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	cx, bp
	call	ObjMessage
	pop	cx, bp
done:
	ret

GenCheckIfFullyXXCommon	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	GenCheckIfFullyEnabled

SYNOPSIS:	Checks to see if an object is fully enabled.

CALLED BY:	GLOBAL (utility)

PASS:	*ds:si -- handle of your object

	cx	- optimization flag:
	
		  If non-zero, routine will take no shortcuts, & check each
		  object up to GenApplication or GenSystem before approving
		  the object as FULLY ENABLED.

		  If clear, then we use the steady-state axim that any object
		  in a visual tree has its VA_FULLY_ENABLED bit set correctly.
		  This assumption is a correct one during steady-state
		  conditions, but not during SPEC_BUILD or when trying to
		  re-evaluate the effect that setting an object NOT_ENABLED
		  has on objects possibly lower in the tree than it.

		NOTE:   specific UI objects, once specifically built, may
			just look at the VA_FULLY_ENABLED flag directly, as
			this flag is set during spec-build.

RETURN:		carry set if fully enabled
		ds - updated to point at segment of same block as on entry

DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  to them.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
        Traverse up generic tree to gen application.  If at any time we
	encounter the enabled flag clear, we'll exit with the carry clear.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 8/90		Initial version
	Doug	5/8/91		Adjusted for new thread model
	Doug	4/92		Rewrote for new thread model

------------------------------------------------------------------------------@

GenCheckIfFullyEnabled	proc	far	uses	ax, bx, si, di
	class	GenClass
	.enter

checkThisObj:
	; if THIS object is not ENABLED, then certainly is not FULLY enabled.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jz	done			; (test clears carry)

	; If this one IS USABLE, check optimization bit to see if we
	; can establish usability based on VA_REALIZED

	tst	cx			; if non-zero, don't use optimization
	jnz	afterOpt		;	technique

	call	VisCheckIfSpecBuilt	; See if specifically built
	jnc	afterOpt		; if not, skip optimization
					; Otherwise, check if fully enabled


EC <	; Make sure object actually of VisClass				>
EC <	;								>
EC <	push	di, es							>
EC <	mov	di, segment VisClass					>
EC <	mov	es, di							>
EC <	mov	di, offset VisClass					>
EC <	call	ObjIsObjectInClass					>
EC <	pop	di, es							>
EC <	ERROR_NC	BAD_ASSUMPTION_IN_GenCheckIfFullyEnabled	>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED

EC <	jz	afterOpt						>
EC <	push	cx							>
EC <	mov	cx, -1			; no optimizations		>
EC <	call	GenCheckIfFullyEnabled					>
EC <	pop	cx							>
EC <	ERROR_NC	BAD_ASSUMPTION_IN_GenCheckIfFullyEnabled	>

	stc				; if VA_FULLY_ENABLED, then must be
					; FULLY ENABLED.
	jnz	done

afterOpt:
	; Nope, have to continue up tree
	;
	mov	ax, si			; save chunk of child object in ax,
					; in case needed
	call	GenFindParent
	cmp	bx, ds:[LMBH_handle]	; if parent in same block, just loop
	je	checkThisObj		; back to walk up tree

	tst	bx
	jz	reachedTop		; branch to handle case of no parent

	call	ObjTestIfObjBlockRunByCurThread
	jne	reachedTop		; branch to handle case of diff thread

	; Else just a change of blocks, but same running thread.  Keep
	; checking them bits...
	;
	call	ObjSwapLock		; set *ds:si to be parent
	call	GenCheckIfFullyEnabled	; travel recursively up tree
	call	ObjSwapUnlock		; return flag according to parent
done:
	.leave
	ret

reachedTop:
	; OK.  We've just reached the top of a branch run by a particular
	; thread, that is, we have a generic parent that is run by a different
	; thread (or NULL).  The rules are as follows:  If THIS top object is a
	; GenApplication or GenSystem object, we will deem the branch FULLY
	; ENABLED.  If not, we have to call the parent object to find out.  If
	; there is no parent, then this branch is NOT fully enabled.

	xchg	ax, si			; get *ds:si = top object,
					; ^lbx:ax = parent
	push	dx
	mov	dx, MSG_GEN_CHECK_IF_FULLY_ENABLED
	call	GenCheckIfFullyXXCommon
	pop	dx
	jmp	short done

GenCheckIfFullyEnabled	endp

Resident ends
