COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genClassBuild.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenClass		Gen UI object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of genClass.asm

DESCRIPTION:
	This file contains routines to implement the Gen class

	$Id: genClassBuild.asm,v 1.1 97/04/07 11:45:36 newdeal Exp $

------------------------------------------------------------------------------@
Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenInitialize

DESCRIPTION:	Initialize a generic object

PASS:
	*ds:si - instance data
	es - segment of GenClass
	ax - MSG_META_INITIALIZE

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	NOTE:  THIS ROUTINE ASSUME THAT THE OBJECT HAS JUST BEEN CREATED
	AND HAS INSTANCE DATA OF ALL 0'S FOR THE VIS PORTION

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@

GenInitialize	method static	GenClass, MSG_META_INITIALIZE

; No parent class initialization since this is a master class

	or	ds:[di].GI_states, mask GS_ENABLED 
	ret

GenInitialize	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenRelocOrUnReloc

DESCRIPTION:	Relocate or unrelocate active list

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	es - segment of GenClass

	ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE

	cx - handle of block containing relocation
	dx - VMRelocType:
		VMRT_UNRELOCATE_BEFORE_WRITE
		VMRT_RELOCATE_AFTER_READ
		VMRT_RELOCATE_AFTER_WRITE
	bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:
	carry - set if error
	bp - unchanged

DESTROYED:
	ax, cx, dx, bp 
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	11/89		Copied from GenActiveListClass

------------------------------------------------------------------------------@

GenRelocOrUnReloc	method	GenClass, reloc		uses bp
	.enter

	;
	; Set BP non-zero if unrelocating.
	;
	clr	bp				; Assume we're relocating
	cmp	ax, MSG_META_RELOCATE
	je	10$				; yup
	inc	bp				; wrong
10$:

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:di = instance

	;now if the VisMoniker supplied for the generic object
	;is actually a moniker list, relocate the optr's in the list.

	mov	cx, ds:[di].GI_visMoniker	;*ds:cx = VisMoniker
						;or VisMonikerList
	mov	bx,cx
	tst	<{word} ds:[bx]>		;Is the block freed?
	jne	cont				;Branch if not
	clr	ds:[di].GI_visMoniker		;Else, clear out vis moniker
						; instance data
cont:
	mov	dx, ds:[LMBH_handle]		;dx = relocation block to use
	call	GenRelocMonikerList		;Relocate the list
	.leave
	mov	di, offset GenClass
	call	ObjRelocOrUnRelocSuper
	ret

GenRelocOrUnReloc	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenRelocMonikerList

DESCRIPTION:	Relocate or unrelocate MonikerList

CALLED BY:	GLOBAL

PASS:	*ds:cx	- moniker list
	dx	- block in which moniker list came from/will be stored back to,
		  i.e. block whose owner has correct relocation tables to use.
		  (In most all cases ds:[LMBH_handle] will work fine.  This
		  option is offered for cases where an unrelocated moniker
		  list is copied out of one library's resource & into a block
		  owned by another geode.  In this latter case, the block
		  handle in which the moniker list came from should be passed)

	bp 	- 0 if we want to relocate the list
	     	  1 if we want to unrelocate the list	

RETURN: carry set if RelocOrUnRelocHandle returned carry set

DESTROYED:
	Nothing	- This routine used both as static method call & as a utility
		  routine outside of object world.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/89		Copied from GenActiveListClass
	doug	5/92		Change to be static, added "relocation block"
				option
	martin	2000/10/9	Added EC check for CORRUPT_MONIKER_LIST 
------------------------------------------------------------------------------@

GenRelocMonikerList	method	static GenClass, MSG_GEN_RELOC_MONIKER_LIST

	push	di

	tst	cx				;is there anything?
	jz	quickExit			;skip to end if not...
	mov	di, cx
	mov	di, ds:[di]			;ds:di = moniker or list
	tst	di				;If freed, exit
	jz	quickExit
	cmp	di, -1
	jz	quickExit
	test	ds:[di].VM_type, mask VMT_MONIKER_LIST	;is it a list?
	jnz	doList
quickExit:
	pop	di
	clc				; no errors
	ret

doList:
	push	ax, bx, cx, dx

	;walk through this VisMonikerList, updating the optr's which point
	;to VisMonikers.

	ChunkSizePtr	ds, di, cx		;cx -> size of list (in bytes)
	;; 
	;; EC: Make sure the list size is a multiple of one entry 
	;; 
EC <	push	ax, cx							>
EC <	mov	ax, cx				; ax = size of list	>
EC <	mov	cx, size VisMonikerListEntry	; cx = list increment	>
EC <	div	cl				; ah = remainder	>
EC <	tst	ah				; is list size valid?	>
EC <	ERROR_NZ UI_CORRUPT_MONIKER_LIST				>
EC <	pop	ax, cx							>
	
	mov	bx, dx				;bx = relocation block to use
relocEntry:
	push	cx
	mov	cx, ds:[di].VMLE_moniker.handle	;relocate the handle
	call	RelocOrUnRelocHandle		;uses bp flag to decide
						;whether to reloc or unreloc.
	mov	ds:[di].VMLE_moniker.handle,cx
	pop	cx
	jc	done
	add	di,size VisMonikerListEntry
	sub	cx,size VisMonikerListEntry
	jnz	relocEntry

	clc				; no errors
done:
	pop	ax, bx, cx, dx
	pop	di
	ret

GenRelocMonikerList	endm


RelocOrUnRelocHandle	proc	near
	mov	al, RELOC_HANDLE
	tst	bp
	jnz	un
	call	ObjDoRelocation
	jmp	exit
un:
	call	ObjDoUnRelocation
exit:
	ret
RelocOrUnRelocHandle	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenCopyTree

DESCRIPTION:

	MSG_GEN_COPY_TREE may be used to copy a generic object tree, 
 starting at the object first called.  This method should be supported by
 all Generic object classes, & any subclassings thereof, by first calling
 the superclass method, & then copying over any additional data needed for
 that class level.

 This method is guaranteed NOT to force the specific building of any object.
 In fact, the copied object should NOT be grown above the Gen level.
 
 It will also NOT send MSG_META_INITIALIZE to any of the master levels of the
 object.

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass
	ds:bx - base structure
	ax - MSG_GEN_COPY_TREE

	cx	- block into which to copy tree
	dx	- 0 to copy tree w/no parent, else is chunk handle of
		  generic object in destination block onto which to add the new
		  object.
	bp	- CompChildFlags
			if CCF_MARK_DIRTY is set:
				CCF_MARK_DIRTY is passed to GenAddChild and the

object is marked dirty
			if CCF_MARK_DIRTY is clear:
				The object is marked as ignore dirty

RETURN: ^lcx:dx	- new object created


ALLOWED_TO_DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version

------------------------------------------------------------------------------@

GenCopyTree	method	dynamic GenClass, MSG_GEN_COPY_TREE
EC <	call	ECCheckGenCopyTreeArgs	;check passed arguments		>

	;
	; Copy the template object to the new block wholesale, without any
	; sort of MSG_INITIALIZEs getting sent or anything. This is
	; easier, and faster than calling ObjInstantiate and growing the
	; individual master levels up to the Gen level...Since no one in the
	; Gen world relies on MSG_META_INITIALIZE
	; 
	push	si			; save source object chunk for copy
					;  of children (if any)

EC <	push	bp			; preserve all CompChildFlags	>
EC <					;  for final ADD_GEN_CHILD	>
EC <	andnf	bp, mask CCF_MARK_DIRTY	; GenCopyChunk wants only	>
EC <					;  CCF_MARK_DIRTY		>

	mov	bx, cx
	mov	ax, si			; get flags so we can transfer
					;  vardataReloc
	call	ObjGetFlags
	push	ax
	segmov	es, ds			; es <- source segment

	call	ObjLockObjBlock
	mov	ds, ax			; ds <- dest segment
	mov	ax, si
	call	GenCopyChunk
	pop	bx			; mark chunk as object and transfer
					;  vardataReloc flag
	andnf	bx, mask OCF_IS_OBJECT or mask OCF_VARDATA_RELOC
	call	ObjSetFlags		; (DIRTY/IGNORE_DIRTY taken care of by
					;  GenCopyChunk)

	; Copy over Gen-specific chunks.

	mov	bx, es:[si]		; es:bx <- source object Gen data
	add	bx, es:[bx].Gen_offset
	xchg	si, ax			; *ds:si <- destination object (1-b i)

	mov	ax, es:[bx].GI_visMoniker
	call	GenCopyChunk		;

	mov	di, ds:[si]		; get ptr to new object
	add	di, ds:[di].Gen_offset
					; Store moniker chunk copied over
	mov	ds:[di].GI_visMoniker, ax

	; zero out linkage of new object

	clr	ax
	mov	ds:[di].GI_link.LP_next.handle, ax
	mov	ds:[di].GI_link.LP_next.chunk, ax
	mov	ds:[di].GI_comp.CP_firstChild.handle, ax
	mov	ds:[di].GI_comp.CP_firstChild.chunk, ax

	; ADD TO GENERIC PARENT PASSED
	mov	cx, ds:[LMBH_handle]	; Setup ^lcx:dx = new obj
	xchg	dx, si			;  and *ds:si = parent obj
	
EC <	pop	bp			; get addition flags, if we	>
EC <					;  mangled them for EC purposes	>


	tst	si			; see if we're supposed to add
	jz	copyChildren		; if not, skip

					; Force not USABLE for a moment,
					; while we do generic add
	mov	al, ds:[di].GI_states	;save states
	push	ax
	andnf	al, not mask GS_USABLE
	mov	ds:[di].GI_states, al

	push	bp			; needed for calling kids...
	push	dx			; save chunk of new object as parent
					;  for calling kids and for restoration
					;  of GI_states

	mov	ax, MSG_GEN_ADD_CHILD
	call	ObjCallInstanceNoLockES

	pop	si			; restore chunk of new object
	pop	bp

	mov	di, ds:[si]		; ds:di <- Gen instance data
	add	di, ds:[di].Gen_offset
	pop	ax			;  and its GI_states flags
	mov	ds:[di].GI_states, al	; Store complete state value

	mov	dx, si			; dx <- parent chunk (object just
					;  copied) for copying kids

copyChildren:
	; FINISH BY COPYING ALL GENERIC CHILDREN OVER

	pop	si			; Fetch source object chunk handle
					;  so we can call all its children

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock		; Unlock destination block

	segmov	ds, es			; Send method to template object
	mov	cx, bx			; cx <- destination block (might have
					;  been trashed by ADD_GEN_CHILD)

	push	cx, dx

	andnf	bp, mask CCF_MARK_DIRTY	; Make sure kids get added in their
	or	bp, CCO_LAST		;  current order (each child added is
					;  added as the last one)
	mov	ax, MSG_GEN_COPY_TREE
	call	GenSendToChildren

	pop	cx, dx
	ret

GenCopyTree	endm



COMMENT @-----------------------------------------------------------------------

METHOD:		GenFinalObjFree

DESCRIPTION:	Intercept method normally handled at MetaClass to add
		behavior of freeing the chunks that a GenClass object
		references.
		Free chunk, hints & vis moniker, unless any of these chunks
		came from a resource, in which case we mark dirty & resize
		to zero.

PASS:	*ds:si	- object
	ax	- MSG_META_FINAL_OBJ_FREE

RETURN:	nothing

ALLOWED_TO_DESTROY:
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

GenFinalObjFree	method GenClass, MSG_META_FINAL_OBJ_FREE

    	mov	ax, ds:[di].GI_visMoniker	; get moniker chunk

	tst	ax
	jz	afterMoniker
	call	ObjFreeChunk
afterMoniker:

				; Finish up w/nuking the object itself
	mov	ax, MSG_META_FINAL_OBJ_FREE
	GOTO	GenCallMeta

GenFinalObjFree	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenAddGenChild

DESCRIPTION:	Add a child object to a composite

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass
	ax - MSG_GEN_ADD_CHILD

	^lcx:dx	- object to add
	bp - flags for how to add child (CompChildFlags)
		mask CCF_MARK_DIRTY if we want to mark the links as dirty

RETURN:	nothing
	cx, dx - unchanged


ALLOWED_TO_DESTROY:
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


GenAddGenChild	method	GenClass, MSG_GEN_ADD_CHILD
	uses	cx, dx
	.enter
EC <	call	CheckForCXDXNotUsable				>

	call	GenCheckIfSpecGrown	; If this object is NOT
	jc	AddChild		; specifically grown
					; (destroys nothing)

					; Then unbuild the new branch
					; that is being added, before
					; adding it  (It has already
					; been determined that it
					; is NOT USABLE, & therefore
					; may be ungrown to ensure
					; a consistent "grown" path)
	push	si
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock
	call	GenSpecShrinkBranch	; Unbuild branch, to match
					; (destroys nothing)
	call	ObjSwapUnlock		; parent.  This is almost
	pop	si			; always what we want, as the next most
					; likely thing to happen is a 
					; MSG_GEN_SET_USABLE, which will
					; require it to be ungrown anyway.

AddChild:
	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompAddChild		; destroys ax, bx & di only
	mov	bx, cx
	mov	si, dx
	call	ObjSwapLock
	mov	di, ds:[si]		; point to instance
	add	di, ds:[di].Gen_offset	; ds:[di] -- GenInstance
	test	ds:[di].GI_attrs, mask GA_KBD_SEARCH_PATH
	jnz	setPath			; search path set to here, continue up
	test	ds:[di].GI_kbdAccelerator, mask KS_CHAR	
	jz	10$			; no keyboard accelerator, branch
setPath:
	;
	; Clear any path bit on this object, so that the routine that sets
	; path bits doesn't think it has gone as far as it needs to.
	; (i.e. force MSG_GEN_SET_KBD_MKR_PATH handler to do what its
	; supposed to)
	;
	and	ds:[di].GI_attrs, not mask GA_KBD_SEARCH_PATH
	
	mov	ax, MSG_GEN_SET_KBD_MKR_PATH
	call	ObjCallInstanceNoLock	; else set path bits upward
10$:
	call	ObjSwapUnlock
	.leave
	ret

GenAddGenChild	endm


COMMENT @----------------------------------------------------------------------

METHOD:		MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY

DESCRIPTION:
	Sets the parent link of the child to point to the parent.  This is a 
 	"One way" link, in that the parent does not have the child anywhere
	amongst its children.  NOTE: marks nothing dirty

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY
	^lcx:dx	- object to add

RETURN:	nothing
	cx, dx - unchanged

ALLOWED_TO_DESTROY:
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

	method	GenAddChildUpwardLinkOnly, GenClass, \
				MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY


COMMENT @----------------------------------------------------------------------

METHOD:		MSG_GEN_GROW_PARENTS

DESCRIPTION:	Internal message to makes sure that this object's
		generic parent, & that obj's parent, all the way to the
		top, are specifically grown.  This is required of the
		parents of any generic object before it itself may be
		specifically grown.  The handlers use this requirement as
		well, to optimize the effort:  If we run into one that is
		already grown, we may safely assume that they are grown
		all the way to the top.

WHO CAN USE:	Anyone

PASS:		*ds:si - instance data
		es - segment of GenClass

		ax - MSG_GEN_GROW_PARENTS

RETURN:		nothing

ALLOWED_TO_DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version

------------------------------------------------------------------------------@

	method	GenSpecGrowParents, GenClass, MSG_GEN_GROW_PARENTS


COMMENT @----------------------------------------------------------------------

METHOD:		GenSetKbdMkrPath

DESCRIPTION:	Sets the keyboard accelerator path for this object and parent
		objects.

PASS:		*ds:si 	- instance data
		es     	- segment of GenClass
		ax 	- MSG_GEN_SET_KBD_MKR_PATH

RETURN:		nothing
		bx, si, ds, es	- unchanged for static handling

ALLOWED_TO_DESTROY:
		ax, cx, dx, bp
		di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/17/90		Initial version

------------------------------------------------------------------------------@

GenSetKbdMkrPath	method GenClass, MSG_GEN_SET_KBD_MKR_PATH
	uses	bx, si
	.enter
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	test	ds:[di].GI_attrs, mask GA_KBD_SEARCH_PATH
	jnz	exit				;kbd accelerator path set,branch
	
	or	ds:[di].GI_attrs, mask GA_KBD_SEARCH_PATH
	
	mov	di, ds:[si]			;point to instance
	mov	di, ds:[di].MB_class.offset	;get this object's class
	cmp	di, offset GenApplicationClass	;are we at the application?
	je	exit				;yes, go no higher, exit
	
	call	GenFindParent			;Set ^lbx:si = gen parent
	tst	bx	
	jz	exit				;If NO vis parent, done
	
	call	ObjTestIfObjBlockRunByCurThread
	je	sameThread			;run by same thread, branch

	mov	ax, MSG_GEN_SET_KBD_MKR_PATH	;else use obj message
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jmp	short exit

sameThread:
	call	ObjSwapLock			;get parent's instance data
	call	GenSetKbdMkrPath		;call routine recursively
	call	ObjSwapUnlock
exit:
	.leave
	ret
GenSetKbdMkrPath	endm




COMMENT @----------------------------------------------------------------------

METHOD:		GenRemove

DESCRIPTION:	Remove a object from generic tree.

 This method is guaranteed NOT to force the specific building of any object.

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass
	ax - MSG_GEN_REMOVE

	dl    - VisUpdateMode
	bp    - mask CCF_MARK_DIRTY if we want to mark the links as dirty

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/1/92		Initial version

------------------------------------------------------------------------------@


GenRemove	method	GenClass, MSG_GEN_REMOVE
	push	bp				; save CCF_MARK_DIRTY
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjCallInstanceNoLock
	pop	bp				; restore CCF_MARK_DIRTY
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_REMOVE_CHILD
	GOTO	GenCallParent

GenRemove	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenRemoveGenChild

DESCRIPTION:	Remove a child object from a composite

 This method is guaranteed NOT to force the specific building of any object.

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass
	ax - MSG_GEN_REMOVE_CHILD

	^lcx:dx - object to remove
	bp    - mask CCF_MARK_DIRTY if we want to mark the links as dirty

RETURN:	nothing
	cx, dx - unchanged

ALLOWED_TO_DESTROY:
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


GenRemoveGenChild	method	GenClass, MSG_GEN_REMOVE_CHILD
EC <	call	CheckForCXDXNotUsable				>
	FALL_THRU	GenRemoveGenChildLow

GenRemoveGenChild	endm


GenRemoveGenChildLow	proc	far
	class	GenClass

	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	GOTO	ObjCompRemoveChild

GenRemoveGenChildLow	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenClass

DESCRIPTION:	Blow up if superclass requested -- GenClass isn't allowed to
		be used separately from other Gen* classes.

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
	Doug	8/92		Initial version

------------------------------------------------------------------------------@


EC <GenBuild	method	GenClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
EC <	ERROR	UI_GEN_CLASS_ILLEGALLY_USED
EC <GenBuild	endm

Build	ends
BuildUncommon	segment	resource

COMMENT @----------------------------------------------------------------------

METHOD:		GenMoveGenChild

DESCRIPTION:	Move a child object in the composite, to reside in another
		location among its siblings

 This method is guaranteed NOT to force the specific building of any object.

WHO CAN USE:	Anyone

PASS:
	*ds:si - instance data
	es - segment of GenClass
	ax - MSG_GEN_MOVE_CHILD

	^lcx:dx - child to move
	bp - flags for how to move child (CompChildFlags)
		mask CCF_MARK_DIRTY if we want to mark the links as dirty

RETURN:	nothing
	cx, dx - unchanged

ALLOWED_TO_DESTROY:
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


GenMoveGenChild	method	GenClass, MSG_GEN_MOVE_CHILD
	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	GOTO	ObjCompMoveChild

GenMoveGenChild	endm

BuildUncommon	ends
Build	segment	resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenFindGenChild

DESCRIPTION:	Determine the position of a generic child of this object

 This method is guaranteed NOT to force the specific building of any object.

CALLED BY:	EXTERNAL

PASS:
	*ds:si  - instance data of composite
	^lcx:dx - child

RETURN:
	carry - set if NOT FOUND
	bp - child position (0 = first child, -1 if not found)
	^lcx:dx - child preserved

ALLOWED_TO_DESTROY:
	ax
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Eric	12/89		Updated comments, copying from ObjCompFindChild
	Chris	5/10/93		Moved to Build resource, since used when app
				attaches to field.

------------------------------------------------------------------------------@

GenFindGenChild	method	GenClass, MSG_GEN_FIND_CHILD
EC <	tst	cx							>
EC <	ERROR_Z	UI_GEN_FIND_CHILD_BAD_OD				>
EC <	tst	dx							>
EC <	ERROR_Z	UI_GEN_FIND_CHILD_BAD_OD				>
	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompFindChild
	jnc	done			; if found, return child #
	mov	bp, -1			; else, signal not found
done:
	Destroy	ax
	ret
GenFindGenChild	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	GenFindGenChildAtPosition

DESCRIPTION:	Looks up a child's address, given its position in the tree.

 This method is guaranteed NOT to force the specific building of any object.

CALLED BY:	EXTERNAL

PASS:
	*ds:si  - instance data of composite
	cx = # of child to find

RETURN:
	carry - set if NOT FOUND
	^lcx:dx - child, or null if no child at that position

ALLOWED_TO_DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/89		Initial version
	Eric	12/89		Updated comments, copying from ObjCompFindChild

------------------------------------------------------------------------------@

GenFindGenChildAtPosition	method	GenClass, MSG_GEN_FIND_CHILD_AT_POSITION
	mov	dx, cx			; dx = child #
	clr	cx			; use child #
	mov	ax, offset GI_link
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	call	ObjCompFindChild
	jnc	done			; if found, done
	mov	cx, 0			; else, signal not found
	mov	dx, cx
done:
	Destroy	ax, bp
	ret
GenFindGenChildAtPosition	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	GenFindGenParent -- MSG_GEN_FIND_PARENT

DESCRIPTION:	Find the generic parent of this object.

PASS:	*ds:si	= instance data for object

RETURN:	^lcx:dx = parent

ALLOWED_TO_DESTROY:
	ax, bp
	bx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/90		initial version

------------------------------------------------------------------------------@

GenFindGenParent	method	GenClass, MSG_GEN_FIND_PARENT
	push	si
	call	GenFindParent		;returns ^lbx:si = parent
	mov	cx, bx
	mov	dx, si
	pop	si
	ret
GenFindGenParent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle VarData intializations for GenClass

CALLED BY:	MSG_META_INITIALIZE_VAR_DATA
PASS:		*ds:si	= generic object
		cx	= variable data type
RETURN:		ax	= offset to extra data created
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 8/92		Initial version
	doug	5/92		Moved base handler to genClass.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenInitializeVarData method dynamic GenClass, MSG_META_INITIALIZE_VAR_DATA
		cmp	cx, ATTR_GEN_PATH_DATA
		je	initGenPathData

		GOTO	GenCallMeta

initGenPathData:
		call	GenPathInitPathData
		ret

GenInitializeVarData endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenCallMeta

DESCRIPTION:	Passes MetaClass methods OVER the specific & vis classes,
		so that they are not grown out.  After all, we're trying
		to destroy this stuff!

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_META_BLOCK_FREE, 
		MSG_META_OBJ_FREE,
		MSG_META_OBJ_FLUSH_INPUT_QUEUE,
		MSG_META_DETACH,
		MSG_META_DETACH_COMPLETE,
		MSG_META_GCN_LIST_SEND

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version
	ardeb	3/1/92		added MSG_META_DETACH to list of handled
				messages to emulate behaviour of SPUI
				(passing up to Meta) esp. w.r.t.
				GenActiveList objects (which
				perform an extra ObjIncDetach before calling
				their superclass with dx:bp = self).

------------------------------------------------------------------------------@

GenCallMeta	method	GenClass, MSG_META_BLOCK_FREE, MSG_META_OBJ_FREE,
			MSG_META_OBJ_FLUSH_INPUT_QUEUE, MSG_META_DETACH,
			MSG_META_DETACH_COMPLETE, MSG_META_WIN_DEC_REF_COUNT,
			MSG_META_GCN_LIST_SEND, MSG_META_ADD_VAR_DATA,
			MSG_META_SET_OBJ_BLOCK_OUTPUT,
			MSG_META_SET_FLAGS,
			MSG_META_GET_FLAGS

	call	GenCheckIfSpecGrown
	jnc	notGrown
	mov	di, offset GenClass
	GOTO	ObjCallSuperNoLock

notGrown:
	mov	bx, segment MetaClass
	mov	es, bx
	mov	di, offset MetaClass
	GOTO	ObjCallClassNoLock

GenCallMeta	endm



Build ends
BuildUncommon	segment	resource
	

COMMENT @----------------------------------------------------------------------

METHOD:		GenFindViewRanges -- 
		MSG_GEN_FIND_VIEW_RANGES for GenClass

DESCRIPTION:	Searches for view ranges.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_FIND_VIEW_RANGES
		
		cl -- RequestedViewArea, if any, so far, for horizontal range
		dx -- chunk handle of horizontal range, if any
		ch -- RequestedViewArea, if any, so far, for vertical range
		bp -- chunk handle of vertical range, if any
		
RETURN:		cl -- RequestedViewArea, update if horiz scrollbar found at 
				or under this object
		dx -- chunk handle of horizontal range, if any
		ch -- RequestedViewArea, update if vertical scrollbar found
				at or under this object.
		bp -- chunk handle of vertical range, if any
		ax	- destroyed

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
       	save old dx, old bp
	GenSendToChildren
	bl = GetRangeAreaHint
	if old (dx = 0) and (dx <> 0) and (cl = RVA_NO_AREA_CHOICE)
		cl = bl
	if old (bp = 0) and (bp <> 0) and (ch = RVA_NO_AREA_CHOICE)
		ch = bl

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 9/91		Initial version

------------------------------------------------------------------------------@

GenFindViewRanges	method GenClass, MSG_GEN_FIND_VIEW_RANGES
	test	ds:[di].GI_states, mask GS_USABLE
	jz	exit				;we're not usable, don't
						;  look for scrollbars
	push	bp
	push	dx
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GenCallCommonAX			;send to children, return args
	
	call	GetUnambiguousViewAreaRequest	;bl <- any area hint
	pop	di				;get old horiz scrollbar chunk
	tst	di
	jnz	10$				;wasn't zero, branch
	tst	dx				;is it now?
	jz	10$				;no, branch
	cmp	cl, RVA_NO_AREA_CHOICE		;was an area choice made?
	jne	10$				;yes, branch
	mov	cl, bl				;else use our area choice
10$:
	pop	di				;get old vert scrollbar chunk
	tst	di
	jnz	exit				;wasn't zero coming in, branch
	tst	bp				;was a scrollbar found?
	jz	exit				;yes, branch
	cmp	ch, RVA_NO_AREA_CHOICE		;was an area choice made?
	jne	exit				;yes, branch
	mov	ch, bl				;else use positioning hint
exit:
	ret
GenFindViewRanges	endm

			


COMMENT @----------------------------------------------------------------------

ROUTINE:	GetUnambiguousViewAreaRequest

SYNOPSIS:	Returns an unambiguous view area request.   It it just wants
		to be with the x or y scroller, we'll return no request.
		This is used when figuring out where the scrollbars will go.

CALLED BY:	GenFindViewRanges, GenRangeFindViewRanges

PASS:		*ds:si -- object

RETURN:		bl -- RequestedViewArea:
			area choice for this object, or RVA_AREA_CHOICE if none

DESTROYED:	di, es, ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@

GetUnambiguousViewAreaRequest	proc	far
	call	GetViewAreaRequest		;look up hints
	cmp	bl, RVA_X_SCROLLER_AREA		;is it ambiguous?
	je	returnNoChoice			;yes, no choice made 
	cmp	bl, RVA_Y_SCROLLER_AREA
	jne	exit
	
returnNoChoice:
	mov	bl, RVA_NO_AREA_CHOICE		;return no choice made
	
exit:
	ret
GetUnambiguousViewAreaRequest	endp

COMMENT @----------------------------------------------------------------------

METHOD:		GenBranchReplaceParams

DESCRIPTION:	Simply passes method on to all children.  Generic objects
	which know how will test for the replacement type, & if a match is
	found, will replace the specified type of instance data.

PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_BRANCH_REPLACE_PARAMS

	dx	- size BranchReplaceParams structure
	ss:bp	- offset to BranchReplaceParams


RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


GenBranchReplaceParams	method	GenClass, MSG_GEN_BRANCH_REPLACE_PARAMS
	call	GenSendToChildren	; Send method on to all generic children
	ret
GenBranchReplaceParams	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenBranchReplaceOutputOptrConstant

DESCRIPTION:	

	This is simply a special case of MSG_GEN_BRANCH_REPLACE_PARAMS,
 where the param type is BRPT_OUTPUT_OPTR, & the search paramater
 optr.handle = 0.
 It simply maps into calling the more elaborate method, but is provided
 as a simpler interface to do a common action when building UI components
 from template .ui files.


PASS:
	*ds:si - instance data
	es - segment of GenClass

	ax - MSG_GEN_BRANCH_REPLACE_OUTPUT_OPTR_CONSTANT

	cx:dx	- optr to use to replace any optr's of action descriptors
		  or output optr's, which match constant value below.
	bp	- constant value to search for.  (Chunk portion of
		  an optr whose Handle portion is 0)

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@


GenBranchReplaceOutputOptrConstant	method	GenClass, \
			MSG_GEN_BRANCH_REPLACE_OUTPUT_OPTR_CONSTANT
	mov	bx, bp
	sub	sp, size BranchReplaceParams	; Make room on stack for
						; params
	mov	bp, sp				; ss:[bp] points at params
							; Search for 
							; optr = bp value passed
	mov	ss:[bp].BRP_searchParam.handle, 0
	mov	ss:[bp].BRP_searchParam.chunk, bx

	mov	ss:[bp].BRP_replaceParam.handle, cx	; Replace w/cx:dx
	mov	ss:[bp].BRP_replaceParam.chunk, dx	; is real optr

	mov	ss:[bp].BRP_type, BRPT_OUTPUT_OPTR
	mov	ax, MSG_GEN_BRANCH_REPLACE_PARAMS
	mov	dx, size BranchReplaceParams
	call	ObjCallInstanceNoLock		; Do it! replace params!
	add	sp, size BranchReplaceParams	; fix stack.
	ret
GenBranchReplaceOutputOptrConstant	endm

BuildUncommon ends
Build segment resource
			
COMMENT @----------------------------------------------------------------------

ROUTINE:	GetViewAreaRequest

SYNOPSIS:	Searches for range area hints.

CALLED BY:	GenFindViewRanges, GenRangeFindViewRanges

PASS:		*ds:si -- object

RETURN:		bl -- RequestedViewArea:
			area choice for this object, or RVA_AREA_CHOICE if none

DESTROYED:	di, es, ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 9/91		Initial version

------------------------------------------------------------------------------@

GetViewAreaRequest	proc	far
	push	cx
	mov	cl, RVA_NO_AREA_CHOICE		;assume no area choice here
	mov	di, cs
	mov	es, di
	mov	di, offset cs:AreaHints
	mov	ax, length (cs:AreaHints)
	call	ObjVarScanData			;look for positioning hint
	mov	bl, cl				;return in bl
	pop	cx
	ret
GetViewAreaRequest	endp

			
AreaHints	VarDataHandler \
 <HINT_SEEK_LEFT_OF_VIEW, offset ReturnAreaHint>,
 <HINT_SEEK_TOP_OF_VIEW, offset ReturnAreaHint>,
 <HINT_SEEK_RIGHT_OF_VIEW, offset ReturnAreaHint>,
 <HINT_SEEK_BOTTOM_OF_VIEW, offset ReturnAreaHint>,
 <HINT_SEEK_X_SCROLLER_AREA, offset ReturnAreaHint>,
 <HINT_SEEK_Y_SCROLLER_AREA, offset ReturnAreaHint>

ReturnAreaHint	proc	far
	mov	cx, ax				;return hint in cx
	sub	cx, HINT_SEEK_LEFT_OF_VIEW
	shr	cx, 1
	shr	cx, 1
	add	cx, RVA_LEFT_AREA		;convert to our enum
	ret
ReturnAreaHint	endp
		
		
CheckHack <(HINT_SEEK_TOP_OF_VIEW - HINT_SEEK_LEFT_OF_VIEW)/4 eq \
	   (RVA_TOP_AREA - RVA_LEFT_AREA)>
CheckHack <(HINT_SEEK_RIGHT_OF_VIEW - HINT_SEEK_LEFT_OF_VIEW)/4 eq \
	   (RVA_RIGHT_AREA - RVA_LEFT_AREA)>
CheckHack <(HINT_SEEK_BOTTOM_OF_VIEW - HINT_SEEK_LEFT_OF_VIEW)/4 eq \
	   (RVA_BOTTOM_AREA - RVA_LEFT_AREA)>
CheckHack <(HINT_SEEK_X_SCROLLER_AREA - HINT_SEEK_LEFT_OF_VIEW)/4 eq \
	   (RVA_X_SCROLLER_AREA - RVA_LEFT_AREA)>
CheckHack <(HINT_SEEK_Y_SCROLLER_AREA - HINT_SEEK_LEFT_OF_VIEW)/4 eq \
	   (RVA_Y_SCROLLER_AREA - RVA_LEFT_AREA)>
	   
	   
	   


COMMENT @----------------------------------------------------------------------

METHOD:		GenQueryViewArea -- 
		MSG_GEN_QUERY_VIEW_AREA for GenClass

DESCRIPTION:	Returns any preference for where to be put under a GenView.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_QUERY_VIEW_AREA
		cl	- RequestedViewArea: area request already made by a
				sibling, possibly

RETURN:		cl 	- RequestedViewArea: area request, if any

DESTROYED:	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/10/91		Initial version

------------------------------------------------------------------------------@

GenQueryViewArea	method GenClass, MSG_GEN_QUERY_VIEW_AREA
	cmp	cl, RVA_NO_AREA_CHOICE		;any choice made yet?
	jne	exit				;yes, don't bother looking
	
	push	ax
	call	GetViewAreaRequest		;look for any area hints
	pop	ax
	mov	cl, bl				;keep in cl
	cmp	bl, RVA_NO_AREA_CHOICE		;any choice made here?
	jne	exit				;yes, exit
	
	mov	di, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GenCallCommonAX			;else look for something in
						;   the children
exit:
	ret
GenQueryViewArea	endm

			
		
Build	ends
