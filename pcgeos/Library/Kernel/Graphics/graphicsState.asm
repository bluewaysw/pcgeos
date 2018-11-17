COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		graphics
FILE:		Graphics/grState.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    GBL	GrCreateState		Create a graphics state
    GBL	GrDestroyState		Destroy a graphics state
    GBL	GrSaveState		Push current gstate
    GBL	GrRestoreState		Pop current gstate

    GBL	GrSetMixMode		set the drawing mode for subsequent output
    GBL	GrMoveTo		set current pen position
    GBL	GrSetLineColor		set current line color
    GBL	GrSetAreaColor		set current area color
    GBL	GrSetTextColor		set current text color
    GBL	GrSetLineMask		set current line drawing mask
    GBL	GrSetAreaMask		set current area drawing mask
    GBL	GrSetTextMask		set current text drawing mask
    GBL	GrSetLineColorMap	set color mapping mode for lines
    GBL	GrSetAreaColorMap	set color mapping mode for areas
    GBL	GrSetTextColorMap	set color mapping mode for text
    GBL GrSetTextMode		Sets the current text mode.
    GBL GrSetTextStyle		Sets the current text style.
    GBL	GrSetTextSpacePad	Set the amount to pad spaces in PutString.
    GBL GrSetLineWidth		Sets width of lines
    GBL GrSetLineEnd		Sets the end type for lines
    GBL GrSetLineJoin		Sets the join type for connected lines
    GBL GrSetMiterLimit		Sets the miter limit

    GBL	GrSetLineAttr		Set all line attributes
    GBL	GrSetAreaAttr		Set all area attributes
    GBL	GrSetTextAttr		Set all text attributes
    GBL GrSetLineStyle		Sets line style attributes
    GBL GrSetTextDirection	Sets the direction of the text

    INT CalcRectOpts		Calc some optimizations for rectangle drawing
    INT CalcOtherColorValue 	Calc either RGB value or index, given one
    INT UpdateOpts		Update optimizations for text drawing
    INT LockDI_DS_check		Lock gstate for access by attr setting routines
    INT UnlockDI_popDS		Unlock gstate ""
    INT GetPtrToSysDashArray	Returns ptr to system dash array

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	6/88	initial versions
	chris	11/88	Added GrSetStoreMode
	jim	10/89	Changed names, changed graphics string support
	les     02/02   Added text direction support


DESCRIPTION:
	This file contains routines to manipulate the graphics attributes
	in the Window structure

	$Id: graphicsState.asm,v 1.1 97/04/05 01:13:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrAllocState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a block for use as a GState.

CALLED BY:	INTERNAL (GrCreateState, GrSaveState)
PASS:		ax	= size of state needed.
RETURN:		bx	= locked state block
		ax	= segment of locked block
		ds	= idata
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GR_ALLOC_FLAGS	= mask HF_SWAPABLE or mask HF_SHARABLE

GrAllocState	proc	near
		.enter
		LoadVarSeg	ds

	;
	; Does the requested size match the size of gstates stuck in the cache?
	;
		cmp	ax, DEF_GSTATE_SIZE
		jne	notCache

	;
	; If anything in the cache, we can use it.
	;
		INT_OFF
		mov	bx, ds:[GStateCachePtr]		;get first cached GState
		tst	bx
		jnz	cacheNotEmpty			; branch if GState in
							;   cache

		; GState cache is empty -- allocate GState

		INT_ON
notCache:
		mov	cx,(HAF_STANDARD_NO_ERR_LOCK shl 8) or GR_ALLOC_FLAGS
		call	MemAlloc
		jmp	done

		; remove GState from cache

cacheNotEmpty:
	;
	; Initialize and lock cached gstate handle.
	;
		mov	ax,1				;init HM_otherInfo to 1
		xchg	ax,ds:[bx][HM_otherInfo]	;get next GState,
							;   set HM_otherInfo
		mov	ds:[GStateCachePtr],ax
		mov	ax,ss:[TPD_processHandle]	;set owner
		mov	ds:[bx][HM_owner],ax

		; lock GState

		FastLock1	ds, bx, ax, GC_1, GC_2	;turns on interrupts

EC <		cmp	ds:[bx].HM_size, DEF_GSTATE_SIZE/16		>
EC <		ERROR_NE	GASP_CHOKE_WHEEZE			>

done:
		.leave
		ret

		FastLock2	ds, bx, ax, GC_1, GC_2

GrAllocState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFreeState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up a graphics state, caching it if it's the right size.

CALLED BY:	INTERNAL (GrDestroyState, GrRestoreState)
PASS:		bx	= handle of state to free
		ds	= idata
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrFreeState	proc	near
		.enter

		; before we cache it or biff it, make sure that there are
		; no path blocks lying around that will fill up the heap.
		; as the EC code below assures, the GState is locked here.

		push	ds, ax
		call	MemDerefDS		; ds -> GState
		mov	ax, 0xffff		; biff all path blocks
		call	InvalidatePaths
		pop	ds, ax

		INT_OFF				;ensure consistency

EC <		tst	ds:[bx].HM_lockCount				>
EC <		ERROR_Z	GASP_CHOKE_WHEEZE				>

		; make sure GState is the correct size

		cmp	ds:[bx].HM_size,DEF_GSTATE_SIZE/16
		jnz	badSize

		; get head of GState cache list

		mov	di,ds:[GStateCachePtr]

		; make this GState point to the rest of the list

		BitClr	ds:[bx][HM_flags],HF_LMEM	;unmark as lmem block
							; to avoid having it
							; contracted during the
							; window between when
							; all gstates are biffed
							; and all lmem blocks
							; are contracted.
		mov	ds:[bx].HM_lockCount, 0		; Unlock the state
		mov	ds:[bx].HM_otherInfo,di
		call	SetOwnerToKernel		;owned by kernel

		; make this GState the first one on the list

		mov	ds:[GStateCachePtr],bx
EC <		call	NullSegmentRegisters				>

done:
		INT_ON
		.leave
		ret
badSize:
	;
	; Not of a proper size to store in the cache (must be the same size as
	; a default gstate), so just free the thing.
	;
		INT_ON
		call	NearFree
		jmp	done
GrFreeState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCreateState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a graphics state block containing a default graphics
		state.

CALLED BY:	GLOBAL

PASS: 		di - handle of window to associate with graphics state
			(0 for none)

RETURN: 	di - handle to graphics state block containing default state

DESTROYED: 	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Graphics states are cached so that MemAlloc and MemFree
		usually do not need to be called by GrCreateState and
		GrDestroyState.

		The cache is stored as a linked list with the HM_otherInfo
		field of the block handle being the link to the next
		GState cached.

		Consistency of the cache is maintained by turning
		interrupts off for access to it.

		When GStates are freed, they are added to the cache.
		When the memory manager needs to find space on the heap
		it calls FlushGstateCache.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	Jim	10/89		Changed name, made header consistent

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrCreateState	proc	far
		uses	ax, bx, cx, si, ds, es
		.enter

EC <		tst	di						>
EC <		jz	GC_e10						>
EC <		mov	bx, di						>
EC <		call	ECCheckWindowHandle				>
EC <GC_e10:								>

		mov	ax, DEF_GSTATE_SIZE
		call	GrAllocState

		; set new GState to default,
		; bx = handle of new GState, ax = segment, ds = idata

		push	di				;save window handle
		mov	di, 2				;es:di = GState
		mov	es, ax
		mov	si, (offset defaultState) + 2	;ds:si = default state
		mov	cx, (DEF_GSTATE_SIZE - 2) / 2	;
		rep movsw				;set default GState
							;
		mov	es:[GS_header].LMBH_handle, bx	;store block handle
		BitSet	ds:[bx].HM_flags, HF_LMEM	;mark as lmem block
		pop	es:[GS_window]			;set window
		mov	di, bx				;return di = new GState

EC <		push	ds						>
EC <		mov	ds, ax						>
EC <		call	ECLMemValidateHeapFar		; verify heap	>
EC <		pop	ds						>

		; unlock GState

		FastUnLock	ds, di, ax
		.leave
		ret
GrCreateState	endp

if (0)		; this was called by GrNewPage, but there are too many 
		; problems with this routine.  sigh.  jim  8/24/93

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDefaultState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a GState structure to its default value

CALLED BY:	GLOBAL
PASS:		di	- handle of GState
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy the defaultState to the block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetDefaultState proc	far
		uses	ds, ax, bx, cx, di, es, si
		.enter

		mov	bx, di				; lock down GState
		call	NearLockDS			; ds -> GState

		; invalidate fonts, paths, etc.

		call	InvalidateFont		; invalidate font, if any
		mov	ax, 0xffff		; nuke any created paths
		call	InvalidatePaths		; do it now

		; need to check to see if this gState is the one that the
		; window structure uses to update clip regions and
		; transformations

		mov	bx, ds:[GS_window] 	; bx <- window handle.
		tst	bx			; check for null handle
		jnz	checkWindow		;  yes, skip the window manip

		; save the handles we want to preserve, then copy the default
		; state over.
saveHandles:
		push	ds:[GS_window]			; save window handle
		push	ds:[GS_gstring]			; save gstring handle
		push	ds:[GS_saveStateLink]		; save linked states
EC <		test	ds:[GS_pathFlags], mask PF_DEFINING_PATH	>
EC <		ERROR_NZ GRAPHICS_DEFINING_PATH_CANT_SET_DEFAULT_STATE	>

		mov	bx, di				; restore GState handle
		mov	ax, DEF_GSTATE_SIZE		; resize to original
		clr	ch
		call	MemReAlloc			; 
		mov	es, ax				; es -> GState

		mov	di, 2
		LoadVarSeg ds				; ds -> idata
		mov	si, offset defaultState+2	; ds:si = default state
		mov	cx, (DEF_GSTATE_SIZE-2)/2	;
		rep movsw				; set default GState
		mov	di, bx				; restore GState handle

		BitSet	ds:[bx].HM_flags, HF_LMEM	; mark as lmem block
		pop	es:[GS_window]			; restore window and
		pop	es:[GS_gstring]			;  gstring handles
		pop	bx				; restore saveState

		; check for evil saved states.

		tst	bx				; fail if any
NEC <		jnz	deleteSavedStates				>
EC <		ERROR_NZ GRAPHICS_UNBALANCED_SAVE_RESTORE_STATE		>

NEC <done:								>
		mov	bx, di
		call	NearUnlock

		.leave
		ret

		; check to see if we need to invalidate anything in the window
checkWindow:
EC <		call	ECCheckWindowHandle			>
		call	MemPLock
		mov	es, ax			; lock the window
		cmp	di, es:[W_curState] 	; is this the one ?
		jne	gstateOK		; GState is ok
		mov	es:[W_curState], 0 	; invalidate handle
		mov	es:[W_grFlags], 0 	; invalidate opt flags
gstateOK:
		call	NearUnlockV		; release the window
		jmp	saveHandles

		; there were SaveStates called without RestoreStates, tsk tsk.
		; Biff them all.
NEC <deleteSavedStates:							>
NEC <		push	es						>
NEC <freeLoop:								>
NEC <		call	NearLockES		; es <- seg addr of GState >
NEC <		push	es:[GS_saveStateLink]	; Save next state to free >
NEC <		call	GrFreeState					>
NEC <		pop	bx						>
NEC <		tst	bx			; any more states?	>
NEC <		jnz	freeLoop					>
NEC <		pop	es						>
NEC <		jmp	done						>
		
GrSetDefaultState endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDestroyState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Destroy a graphics state block

CALLED BY:	GLOBAL

PASS: 		di - handle of graphics state block to destroy

RETURN: 	nothing

DESTROYED: 	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	See GrCreateState

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	Jim	3/89		Changed to check W_curState in window against
				GState that we're going to destroy
	Jim	10/89		Changed name, documentation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDestroyState	proc	far
		push	ax, bx, ds
		LoadVarSeg	ds

EC <		INT_OFF				; for cache stuff	>
EC <		push	bx						>
EC <		call	ECCheckGStateHandle				>
EC <		mov	bx,ds:[GStateCachePtr]				>
EC <GD_10:								>
EC <		cmp	bx,di						>
EC <		jz	GD_fatal					>
EC <		tst	bx						>
EC <		jz	GD_20						>
EC <		mov	bx,ds:[bx].HM_otherInfo				>
EC <		jmp	short GD_10					>
EC <GD_fatal:								>
EC <		ERROR	GRAPHICS_BAD_GSTATE_DESTROY			>
EC <GD_20:								>
EC <		pop	bx						>
EC <		INT_ON				; for cache stuff	>

		push	ds			; save VAR_SEG
		mov	bx, di			;
		call	NearLockDS		; lock the GState
EC <		tst	ds:[GS_gstring]		; make sure not a gstring >
EC <		jne	GD_fatal					  >

		; remove any saved states
		;
		call	InvalidateFont		; invalidate font, if any
		mov	ax, 0xffff		; nuke any created paths
		call	InvalidatePaths		; do it now

		; need to check to see if this gState is the one that the
		; window structure uses to update clip regions and
		; transformations

		mov	bx, ds:[GS_window] 	; bx <- window handle.
		tst	bx			; check for null handle
		jz	skipwin			;  yes, skip the window manip
EC <		call	ECCheckWindowHandle			>
		call	MemPLock
		mov	ds, ax			; lock the window
		cmp	di, ds:[W_curState] 	; is this the one ?
		jne	gstateOK		; GState is ok
		mov	ds:[W_curState], 0 	; invalidate handle
		mov	ds:[W_grFlags], 0 	; invalidate opt flags
gstateOK:
		call	NearUnlockV		; release the window
skipwin:
		pop	ds			; restore VAR_SEG
		mov	bx, di			; bx <- gstate handle for loop
		push	es			; need ES for loop
freeLoop:
		call	NearLockES		; es <- seg addr of GState
		push	es:[GS_saveStateLink]	; Save next state to free

		call	GrFreeState

		pop	bx
		tst	bx			; any more states?
		jnz	freeLoop

		pop	es

		pop	ax, bx, ds
		ret

GrDestroyState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save the current gstate (for later GrRestoreState)

CALLED BY:	GLOBAL

PASS: 		di - handle of gstate to save

RETURN: 	di - same

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Note that the block in which the GState is saved is not
		usable as a gstate. It's handle is not marked as an LMem
		block, and the LMBH_handle field is not set correctly.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSaveState	proc	far
		call	PushAll

		; lock gstate passed

		mov	bx,di
		call	NearLockDS		;ds <- seg addr of GState

		; allocate a buffer for the saved state

		mov	ax, ds:[LMBH_blockSize]
		push	ax
		push	ds
		LoadVarSeg	ds
		
		;
		; use size from global handle table when using GrAllocState
		; so that a once-default gstate of size DEF_GSTATE_SIZE
		; (with its pre-allocated path chunk) that has undergone
		; lmem garbage collection (and thus reduction of
		; LMBH_blockSize) can still be satisfied with a cached gstate
		;
EC <		mov	cx, ax						>
		mov	ax, ds:[bx].HM_size
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1			; paragraphs to bytes
EC <		cmp	ax, DEF_GSTATE_SIZE				>
EC <		jne	notDefault					>
EC <		cmp	cx, DEF_GSTATE_SIZE				>
;too annoying
;EC <		WARNING_NE	ROUNDING_UP_GSTATE_SIZE_TO_USE_CACHE	>
EC <notDefault:								>

		call	GrAllocState

		mov	es,ax			;es = save buffer
		pop	ds

		; copy block

		pop	cx			;cx = size
		shr	cx,1
		push	si, di
		clr	si
		clr	di
		rep	movsw
	;
	; 6/24/94: By duplicating the GState, we've duplicated the font
	; handle and now have an additional reference to the font. When
	; we do the corresponding GrRestoreState(), we'll decrement the
	; reference count, so we need to deal with it here
	;
	; We could increment the reference count here, but it would require
	; some amount of code, and would require locking the font info block.
	;
	; Alternatively, we could simply clear the font handle in either
	; the new GState or the saved one.  This would take less code,
	; but it be less efficient as one or the other would be
	; forced to find the font again.
	;
 	; On the other hand, it is not clear if locking the font info
 	; block at this point in execution might cause deadlock.  In
 	; the interest of keeping the code change simpler and saving
 	; some bytes (we're in kcode re: fixed memory) and cycles,
 	; I decided on a compromise which checks for the more common
 	; case of the font being the default font, and only nukes
 	; the font handle if it is not the default.  -- gene 6/24/94
	;
	; Well, the above used to refer below, where it was nuking the
	; font in the new GState.  Now it is nuking it in the saved
	; GState instead, and the extra nuke previously done in
	; GrRestoreState() is no longer done.  The old way had the
	; unfortunate side-effect of not updating the reference
	; count of the font in the GState previously saved / currently
	; being restored from, which was OK unless the font had
	; changed since the save... -- gene 7/15/94
	;
		clr	es:GS_fontHandle
	;


		; deal with Paths, by removing Regions cached with the Path
		;
if		not CACHED_PATHS
		clr	ax			;just invalidate
		call	InvalidatePaths		;invalidate for usage
endif
		; unlock copy. No need to worry about LMBH_handle b/c block
		; isn't marked as LMem.

		pop	si, di
		call	NearUnlock

		; save handle of block to which we've saved state and check
		;  for a gstring, then unlock the gstate

		mov	ds:[GS_saveStateLink],bx


		mov	bx, ds:[GS_gstring]	; check for gstring 
		tst	bx			; valid handle ?
		jz	unlockGS		;  no, just unlock the gstate
		xchg	bx, di			; swap handles momentarily
		mov	al, GR_SAVE_STATE	; load up code
		clr	cl			; no data to write
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; use fast routine
		xchg	bx, di			; get handle back where it goes
unlockGS:
		mov	bx,di			; bx = gstate handle
		call	NearUnlock

		call	PopAll
		ret
GrSaveState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Restore the current gstate (from previous GrSaveState)

CALLED BY:	GLOBAL

PASS: 		di - handle of gstate to restore

RETURN: 	di - same

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Re-allocate the gstate to be the same size as the state we are
		restoring from.
		Copy the data from the restore-state to the current gstate.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrRestoreState	proc	far
		call	PushAll

		mov	bx, di			;Lock the destination gstate.
		call	NearLockES		;es <- seg addr of GState
		mov	ds, ax			;ds <- seg addr of GState
		call	InvalidateFont		;invalidate me jesus
		push	si, di			; for movsw, below (makes life
						;  easier as we needn't save
						;  and restore di around call to
						;  GrFreeState)

		; nuke any paths in the GState we are about to kill

		mov	ax, 0xffff
		call	InvalidatePaths

		mov	bx, ds:GS_saveStateLink	;bx <- handle of saved state
EC <		tst	bx			; if zero, it's bad	>
EC <		ERROR_Z GRAPHICS_BAD_RESTORE_STATE			>
		call	NearLockDS		;ds <- GState to copy from

if		CACHED_PATHS
		mov	ax, 0x8000		;nuke paths if we need to
else
		mov	ax, 0xffff		;nuke paths always
endif
		call	InvalidatePaths		;clean up Path stuff

		; check out the paths.  If they are the same, then don't
		; nuke the old ones (don't even invalidate them).  If they
		; are different, then nuke the old ones.

		mov	ax, ds:LMBH_blockSize
		cmp	ax, es:LMBH_blockSize	; if size hasn't changed then
		je	sizeSame		;    no need to re-alloc block.
		;
		; Need to re-allocate destination gstate to be the
		; same size as the source.
		; ax already holds the size of the source.
		;
		mov	ch, mask HAF_NO_ERR	; can't handle errors here.
		xchg	bx, di			; bx <- handle of destination.
		call	MemReAlloc		; ax <- new seg address.
		xchg	bx, di
		mov	es, ax			; reset seg address.
sizeSame:
		;
		; copy from saved state
		;
		mov	cx, ds:LMBH_blockSize	; Heap is always word aligned
		shr	cx,1			; so this always is OK.

		clr	si
		clr	di
		rep	movsw

		LoadVarSeg	ds
		call	GrFreeState		; Free the copy.
		pop	si, di

		;
		; The window may have changed -- so we invalidate stuff.
		;
		segmov	ds, es			;ds <- seg addr of GState
		;
		; check for gstring -- skip window stuff if so
		;
		mov	bx, ds:[GS_gstring]	; get gstring handle
		tst	bx			; check handle
		jnz	gseg

if ERROR_CHECK
		;
		; In GrSaveState() we nuked the font handle in the saved
		; GState Make sure the reference is dead, dead, dead.
		;
		tst	ds:GS_fontHandle
		ERROR_NZ GASP_CHOKE_WHEEZE
endif

		mov	cx, not (mask WGF_MASK_VALID or \
			         mask WGF_XFORM_VALID or \
			         mask WGRF_PATH_VALID shl 8 or \
			         mask WGRF_WIN_PATH_VALID shl 8)
		call	IntExitGState		;set flags, unlock stuff

exit:
		call	PopAll
		ret

;--------------------------------------------------------------------------

		; handle is to a graphics string, store the code
gseg:
		xchg	bx, di			; swap the handles
		mov	al, GR_RESTORE_STATE	; load up code
		clr	cl			; no data to write
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; use fast routine
		call	NearUnlock		; unlock the GState
		mov	di, bx			; di <- handle of GState
		jmp	exit
GrRestoreState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalidatePaths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate any Path information in the current GState

CALLED BY:	GrSaveState, GrRestoreState
	
PASS:		DS	= GState
		AX	= 0 (invalidate)
			= 0xffff (invalidate and destroy)
			= 0x8000 (es -> old GState, ds -> new GState)
			  (destroy old paths if new paths are different)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InvalidatePaths	proc	near
		uses	bx, cx, di, si
		.enter

		; Loop through, nuking Paths
		;
		mov	cx, 3			; number of Paths to free
		mov	di, offset GS_currentPath

if		CACHED_PATHS
		cmp	ah, 0x80		; special case ?
		je	compareAndNuke
endif
		; Free any Path region, if one exists
freePath:
		mov	si, ds:[di]		; Path chunk handle => SI
		tst	si
		jz	next
		mov	si, ds:[si]		; Path => DS:BX
		and	ds:[si].P_flags, not (mask PSF_REGION_VALID)
		clr	bx			; nuke handle reference
		xchg	bx, ds:[si].P_slowRegion ; RegionPath handle => BX
		and	bx, ax			; AX = 0 or 0xffff
		jz	next
		call	MemDecRefCount		; free the Path
next:
		add	di, size lptr		; go to next Path
		loop	freePath
if		CACHED_PATHS
done:
endif
		.leave
		ret

if		CACHED_PATHS
		; if the old paths are different, nuke them.
compareAndNuke:
		mov	si, es:[di]		; Path chunk handle => si
		tst	si			; if no path, continue
		jz	nextNukeNoPop
		mov	si, es:[si]		; dereference chunk
		mov	bx, es:[si].P_slowRegion ; load up handle
		tst	bx
		jz	nextNukeNoPop		; if none, nothing to nuke.
		push	di
		mov	di, ds:[di]
		tst	di			; if no path, clip this one
		jz	nukeOldOne
		mov	di, ds:[di]		; deref chunk
		mov	ax, es:[si].P_flags	; get old flags
		test	ax, mask PSF_PATH_IS_RECT  ; if rect, nothing to nuke
		jnz	nextNuke
		mov	al, ds:[di].P_flags.high ; get new ones
		cmp	al, ah			; if different fill rule, 
		jne	nukeOldOne		;  nuke old one
		cmp	bx, ds:[di].P_slowRegion ; if diff...
		jne	nukeOldOne
		mov	ax, es:[si].P_checksum
		cmp	ax, ds:[di].P_checksum
		je	nextNuke
nukeOldOne:
		call	MemFree			; free old slowRegion
nextNuke:
		pop	di
nextNukeNoPop:
		add	di, size lptr
		loop	compareAndNuke
		mov	ax, 0x8000		; reload parameter
		jmp	done
endif
InvalidatePaths	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetPrivateData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the private data for a GState

CALLED BY:	GLOBAL

PASS: 		ax, bx, cx, dx - private data
		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetPrivateData proc	far
		push	ds
		call	LockDI_DS_check
		mov	ds:[GS_privData].GPD_ax,ax
		mov	ds:[GS_privData].GPD_bx,bx
		mov	ds:[GS_privData].GPD_cx,cx
		mov	ds:[GS_privData].GPD_dx,dx
		GOTO	UnlockDI_popDS, ds
GrSetPrivateData endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetMixMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current drawing mode for a window

CALLED BY:	GLOBAL

PASS:		al	- new draw mode from:
			MM_CLEAR 	; dest <- 0
			MM_COPY 	; dest <- src
			MM_NOP 	; dest <- dest
			MM_AND 	; dest <- src AND dest
			MM_INVERT 	; dest <- NOT dest
			MM_XOR 	; dest <- src XOR dest
			MM_SET 	; dest <- 1
			MM_OR 	; dest <- src OR dest
		di - handle of graphics state

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		store the new draw mode;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When (graphical) segments are supported, this routine should
		deal with saving this "command" to the any currently open
		segments.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GSDM_CLEAR_BOTH	=	(not (mask AO_MASK_1_COPY or mask AO_MASK_1_INVERT)) and 0ffh

GrSetMixMode	proc	far
EC <		cmp	al,LAST_MIX_MODE				>
EC <		ERROR_A GRAPHICS_ILLEGAL_DRAW_MODE			>

		push	ds
		call	LockDI_DS_check
		mov	ds:[GS_mixMode], al		; set new draw mode
		jc	GSDM_gstring

		; must update optimization flags (not important for gstrings)

		push	si, ax
		mov	si, offset GS_lineAttr.CA_flags
		call	CalcRectOpts
		mov	si, offset GS_areaAttr.CA_flags
		call	CalcRectOpts
		mov	si, offset GS_textAttr.CA_flags
		call	CalcRectOpts
		pop	si, ax
exit:
		GOTO	UnlockDI_popDS, ds

GSDM_gstring:
		jnz	exit			; do nothing if a Path
		push	ax,cx			; retore reg
		mov	ah, GR_SET_MIX_MODE	; set up the code
		xchg	al, ah			; get in right spaces
		mov	cl, 1			; one data byte
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write em out
		pop	ax,cx			; restore reg
		jmp	exit
GrSetMixMode	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcRectOpts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Calculate rectangle optimization flags

CALLED BY:	INTERNAL
		GrSetMixMode

PASS: 		al - draw mode
		ds:[si] - previous optimization flags

RETURN: 	ds:[si] - new optimization flags

DESTROYED: 	ah

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcRectOpts	proc	near
		mov	ah,ds:[si]		;ah = line flags

		and	ah,GSDM_CLEAR_BOTH		;assume neither
		test	ah,mask AO_MASK_1
		jz	CRO_done

		or	ah, mask AO_MASK_1_COPY
		cmp	al, MM_COPY
		jz	CRO_done

		and	ah, not mask AO_MASK_1_COPY
		or	ah, mask AO_MASK_1_INVERT
		cmp	al, MM_INVERT
		jz	CRO_done

		and	ah, not mask AO_MASK_1_INVERT
CRO_done:
		mov	ds:[si],ah
		ret
CalcRectOpts	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRelMoveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current pen position

CALLED BY:	GLOBAL

PASS:		di - GState handle
		dx.cx	- X displacement (doc coords)
		bx.ax	- Y displacement (doc coords)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new positions;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrRelMoveTo	proc	far
		push	ds
		call	LockDI_DS_check
		call	SetRelDocPenPos
		jc	writeGString
		GOTO	UnlockDI_popDS, ds
writeGString:
		push	ds, bp
		mov	bp, GR_REL_MOVE_TO or (GSSC_FLUSH shl 8)

WriteMoveWWF	label	near
		push	si, bx, ax, dx, cx	; push in right order
		segmov	ds, ss, si
		mov	si, sp
		mov	cx, size PointWWFixed	; amount of data to save
		mov_tr	ax, bp			; opcode -> AL
		call	GSStore
		pop	si, bx, ax, dx, cx	
		pop	ds, bp
		GOTO	UnlockDI_popDS, ds
GrRelMoveTo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMoveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current pen position (used for relative drawing)

CALLED BY:	GLOBAL

PASS:		ax	- new x position
		bx	- new y position
		di - handle of graphics state

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new positions;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrMoveTo	proc	far
		push	ds
		call	LockDI_DS_check
		call	SetDocPenPos		; set current position
		jnc	exit

		; writing to a graphics string, store there too

		push	dx			; save a reg
		mov	dl, GR_MOVE_TO		; set up opcode
		push	ax,bx,cx		; save a few
		xchg	bx, ax			; first word
		xchg	ax, dx
		mov	cl, size Point		; storing 4 bytes
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write em out
		pop	ax,bx,cx		; save a few
		pop	dx
exit:
		GOTO	UnlockDI_popDS, ds
GrMoveTo	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMoveToWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current pen position 

CALLED BY:	GLOBAL

PASS:		di	GState handle
		dxcx	- new x position
		bxax	- new y position

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new positions;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	5/92...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrMoveToWWFixed	proc	far
		push	ds
		call	LockDI_DS_check
		call	SetDocWWFPenPos		; set current position
		jc	writeGString
		GOTO	UnlockDI_popDS, ds

		; writing to a graphics string, store there too
writeGString:
		push	ds, bp
		mov	bp, GR_MOVE_TO_WWFIXED or (GSSC_FLUSH shl 8)
		jmp	WriteMoveWWF
GrMoveToWWFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current line drawing color

CALLED BY:	GLOBAL

PASS:		ah - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					al = index
				CF_RGB (1)
					al = red
					bl = green
					bh = blue
		di - handle of graphics state

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new color;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		*** NOTE ***
		The pushes at the top of this routine must match those of
		GrSetAreaColor and GrSetTextColor

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetLineColor	proc	far
		push	ds
		call	LockDI_DS_check
		push	cx, si
		mov	si, GS_lineAttr.CA_colorIndex ; set offset to color
		mov	cx,(GR_SET_LINE_COLOR_INDEX shl 8) or GR_SET_LINE_COLOR
		jmp	SetTheDarnColor
GrSetLineColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current area drawing color

CALLED BY:	GLOBAL

PASS:		ah - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					al = index
				CF_RGB (1)
					al = red
					bl = green
					bh = blue
		di - handle of graphics state

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new color;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When segments are supported, this routine should deal with
		saving this "command" to the any currently open segments.

		*** NOTE ***
		The pushes at the top of this routine must match those of
		GrSetAreaColor and GrSetTextColor

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetAreaColor	proc	far
		push	ds
		call	LockDI_DS_check
		push	cx, si
		mov	si, GS_areaAttr.CA_colorIndex ; set offset to color
		mov	cx,(GR_SET_AREA_COLOR_INDEX shl 8) or GR_SET_AREA_COLOR

		; common entry point for all SetXXXXColor routines

SetTheDarnColor	label	near
		push	ax, bx
		jnz	callSetColor		; jump for Paths or GState

		; don't write out CF_GRAY to a GString.  Change it to
		; CF_RGB first...

		cmp	ah, CF_GRAY
		jne	checkRGB
		mov	ah, CF_RGB
		mov	bl, al
		mov	bh, al

		; writing to a gstring, do that before calc color
checkRGB:
		push	ax
		cmp	ah, CF_RGB		; see how we're setting it
		mov	ah, cl			; assume rgb
		mov	cl, size RGBValue	; size of rgb gstring element
		je	storeColorElement	; assumption right, store it
		mov	ah, ch			; else set to index
		mov	cl, 1			; size of index gstring element
storeColorElement:
		xchg	al, ah
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes
		pop	ax

		; done with gstring processing, set color in gstate
callSetColor:
		mov	cl, GSTATE_LOCKED or LEAVE_GSTATE ; gstate locked
		call	SetColorAfterPWin		; set color in gstate

		pop	ax, bx
		pop	cx, si
		GOTO	UnlockDI_popDS, ds

GrSetAreaColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current line drawing color

CALLED BY:	GLOBAL

PASS:		ah - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					al = index
				CF_RGB (1)
					al = red
					bl = green
					bh = blue
		di - handle of graphics state

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new color;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When segments are supported, this routine should deal with
		saving this "command" to the any currently open segments.

		*** NOTE ***
		The pushes at the top of this routine must match those of
		GrSetAreaColor and GrSetTextColor

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTextColor	proc	far
		push	ds
		call	LockDI_DS_check
		push	cx, si
		mov	si, GS_textAttr.CA_colorIndex ; set offset to color
		mov	cx,(GR_SET_TEXT_COLOR_INDEX shl 8) or GR_SET_TEXT_COLOR
		jmp	SetTheDarnColor
GrSetTextColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate and set a new color in a gstate

CALLED BY:	GLOBAL

PASS:		es	- locked/owned window structure
			  (unless passed a gstring, or gstate w/o window)
		si	- offset in gstate to store color info
			  (pointer to CA_colorIndex field of the common
			   attributes structure)
		di	- gstate handle
		ah	- color flag (CF_RGB or CF_INDEX or CF_GRAY)
		al	- either red component (for CF_RGB)
				 or
			  color index (for CF_INDEX)
				 or
			  gray value (for CF_GRAY)
		bl,bh	- green/blue components (for CF_RGB)
		cl	- bit flags:
				bit 0: set if gstate is already locked
				bit 1: set if desire to leave gstate locked

RETURN:		nothing

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		lock the gstate, if we need to;
		lock custom palette, if there is one;
		calculate both index and RGB value;
		store the result in the gstate;
		unlock palette and gstate;

		note: CF_GRAY is just a shorthand for setting an RGB color.
		      This routine converts the passed gray value immediately
		      into an RGB triplet.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GSTATE_LOCKED	equ	0x01
LEAVE_GSTATE	equ	0x02
ATTR_FLAG	equ	<CA_flags-CA_colorIndex>

SetColor	proc	far
		uses	dx
		.enter

		; check for CF_GRAY, and change it to RGB

		cmp	ah, CF_GRAY		; setting with gray value ?
		je	setGray
		cmp	ah, CF_CMY		; setting with CMY value ?
		je	setCMY

		; if gstate not locked yet, then lock it now
checkGState:
		push	cx			; save color info
		test	cl, GSTATE_LOCKED	; check for locked gstate
		jnz	gsLocked
		mov	cx, bx			; save color info
		mov	bx, di			; get gstate handle
		push	ax
		call	MemLock			; lock GState
		mov	ds, ax			;  ds -> GState
		pop	ax
		mov	bx, cx			; restore color info

		; calc full color value, store result in gstate
gsLocked:
		mov	cx, ax			; save original RGB
		push	bx			; save blue/green
		call	CalcOtherColorValue
		pop	dx			; use pal reg for blue/green

		; assume we're setting by index

		or	{byte} ds:[si][ATTR_FLAG], mask AO_USE_INDEX
		cmp	ch, CF_RGB		; if setting RGB, special
		jne	storeEm			;  no, use calc'd values

		; we're setting by RGB.  Leave the flag set if we ended up
		; with a perfect match.

		cmp	ah, cl			; same?
		jne	resetFlag		;  if so, leave the flag set
		cmp	bx, dx
		je	setRGBValues
resetFlag:
		and	{byte} ds:[si][ATTR_FLAG], not mask AO_USE_INDEX
setRGBValues:
		mov	ah, cl			; restore original red value
		mov	bx, dx			; restore orig green/blue
storeEm:
		mov	ds:[si], ax		; store index and red comp
		mov	ds:[si+2], bx
		pop	cx			; restore flags

		; all done, unlock gstate and palette

		test	cl, LEAVE_GSTATE	; check if leaving gstate alone
		jnz	gsUnlocked		;  yes, continue
		mov	bx, di			; unlock gstate
		call	MemUnlock
gsUnlocked:
		.leave
		ret

		; user set gray value.  Change to RGB
setGray:
		mov	ah, CF_RGB
		mov	bl, al			; copy values equally
		mov	bh, al
		jmp	checkGState

		; user set CMY value.  Change to RGB
setCMY:
		mov	dx, 0xffff
		sub	dx, bx
		mov	bx, dx
		mov	ah, 255
		sub	ah, al
		mov	al, ah
		mov	ah, CF_RGB
		jmp	checkGState
SetColor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetColorAfterPWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end routine for SetColor to be called by those routines
		that would otherwise call SetColor but don't have the window
		P'ed yet (as SetAreaColorInt does...)

CALLED BY:	(INTERNAL) GrSetAreaColor, GrSetLineColor, GrSetTextColor
PASS:		ds	= locked GState
		si	- offset in gstate to store color info
			  (pointer to CA_colorIndex field of the common
			   attributes structure)
		di	- gstate handle
		ah	- color flag (CF_RGB or CF_INDEX or CF_GRAY)
		al	- either red component (for CF_RGB)
				 or
			  color index (for CF_INDEX)
				 or
			  gray value (for CF_GRAY)
		bl,bh	- green/blue components (for CF_RGB)
		cl	- bit flags:
				bit 0: set if gstate is already locked
				bit 1: set if desire to leave gstate locked

RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		HandleP the window for the passed gstate
		call SetColor to do the work
		HandleV the window

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetColorAfterPWin proc	far
		uses	dx
		.enter
		Assert	bitSet, cl, GSTATE_LOCKED
		Assert	e, ds:[LMBH_lmemType], LMEM_TYPE_GSTATE
	;
	; P the window, since SetColor/CalcOtherColorValue will always
	; need to lock the thing down, and can't safely do that without
	; having the window P'd.
	; 
		mov	dx, bx		; preserve green/blue
		mov	bx, ds:[GS_window]
		tst	bx
		jz	windowPed
		call	HandleP

windowPed:
		xchg	bx, dx		; bx <- green/blue, dx <- win handle
		call	SetColor
	;
	; V the window handle again.
	; 
		tst	dx
		jz	done
		mov	bx, dx
		call	HandleV
done:
		.leave
		ret
SetColorAfterPWin endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcOtherColorValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	From a passed color index or RGB value calculate the other

CALLED BY:	INTERNAL
		GrSetLineColor, GrSetAreaColor, GrSetTextColor

PASS: 		ds:	- locked GState
		ah - flag:
			enum of type ColorFlag:
				CF_INDEX (0)
					al = index
				CF_RGB (1)
					al = red
					bl = green
					bh = blue
RETURN: 	al - color index
		ah - red component of RGB value
		bl - green component
		bh - blue component

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	10/88		Initial version
		Jim	02/89		Changed CF_INDEX to ah=0,
					set color table

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcOtherColorValue proc	near
		uses	cx, dx, di, si, es
		.enter

		; lock window, get pointer to palette info

		mov	dl, 0xff		; map to all 255 colors
		mov	cx, bx			; save color 
		mov	bx, ds:[GS_window]	; need to lock window
		push	ds
		tst	ds:[GS_gstring]
		jnz	getDefault		; => doing path work, so ignore
						;  window
		tst	bx
		jnz	getWinPalette
getDefault:
		LoadVarSeg ds, si
		mov	si, offset defaultPalette
		jmp	havePalette

getWinPalette:
		push	ax			; save color
	; EC: ensure window handle is P'd (but doesn't have to be locked yet)
EC <		LoadVarSeg es, ax					>
EC <		Assert	ne, es:[bx].HM_otherInfo, 1			>
		call	NearLockES
		pop	ax

	; Query the video driver to determine how many colors
	; it can support at one time
		
	; Responder is known to use 4 bit color 
		mov	di, DR_VID_INFO
		call	es:[W_driverStrategy]
		mov	ds, dx			; ds:si = VideoDriverInfo
		mov	dl, 0xff		; assume we can use 255 colors
		cmp	ds:[si].VDI_nColors, 4
		ja	haveMaxColors
		mov	dl, 0xf			; nope, only use first 16 colors
haveMaxColors:
		tst	es:[W_palette]		; check for palette
		jz	getDefault
		segmov	ds, es, si
		mov	si, ds:[W_palette]
		mov	si, ds:[si]		; dereference custom palette
havePalette:
		mov	bx, cx			; restore color
		cmp	ah, CF_RGB		; passing RGB?
		jne	indexLookup		;  no treat as index

		; the color has been set via an RGB value. Look up the
		; closest indexed value, in case we are not dithering

		mov	ch, dl			; ch = max color count
		call	MapRGBtoIndex		; calc index value
		xchg	al, ah			; get index in right place
		jmp	done

		; an index was passed in, so look up the RGB value
		; in the palette.
indexLookup:
		mov	bl, al			; calculate offset into palette
		clr	bh
		clr	ah
		shl	bx, 1
		add	bx, ax
		mov	ah, ds:[si][bx]		; get red component
		mov	bx, ds:[si][bx+1]	; get green/blue
done:
		pop	ds
		tst	ds:[GS_gstring]
		jnz	exit			; => window not locked by us
		tst	ds:[GS_window]
		jz	exit
		push	bx
		mov	bx, ds:[GS_window]
		call	NearUnlock
		pop	bx
exit:
		.leave
		ret

CalcOtherColorValue 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetLineMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current line drawing pattern

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

		al	- record of type SysDrawMask, where


			   bit 7: 	set to use inverse of passed pattern
					use mask SDM_INVERSE
			   bits 6-0: 	system pattern number


		if the low 7 bits of al = SDM_CUSTOM, then:

			ds:si	- pattern to set


RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new index;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When segments are supported, this routine should deal with
		saving this "command" to the any currently open segments.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetLineMask	proc	far
		
if	FULL_EXECUTE_IN_PLACE
EC <		push	ax					>
EC <		andnf	al, mask SDM_MASK			>
EC <		cmp	al, SDM_CUSTOM				>
EC <		pop	ax					>
EC <		jne	xipOK					>
EC <		call	ECCheckBounds				>
xipOK::
endif
		push	ds
		push	bx,cx,es
		mov	bx, offset GS_lineAttr
		mov	cx,(GR_SET_CUSTOM_LINE_MASK shl 8) or GR_SET_LINE_MASK 
NEC <setMaskCommon	label	near					>
EC <setMaskCommon	label	far					>
		segmov	es, ds			; es -> custom mask (if passed)
		call	LockDI_DS_check
		jnz	callSetMask		; jump for Paths or GState

		; writing to a gstring, do it

		push	ax
		mov	ah, al			; make copy so we can trash it
		and	ah, mask SDM_MASK	; isolate mask number
		cmp	ah, SDM_CUSTOM
		mov	ah, cl			; assume system pattern
		je	GSLM_custom
		mov	cl, 1			; setting 1 byte pattern index
		xchg	al, ah
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes
rejoinGS:
		pop	ax
callSetMask:
		push	di
		mov	di, bx			; set up pointer into gstate
		call	SetMask
		pop	di
		cmp	bx, offset GS_textAttr	; need to update opt vars
		pop	bx,cx,es
		jne	exit			; if we set the text mask, 
		call	UpdateOptsAndReturn	;  update optimization vars
exit:
		GOTO	UnlockDI_popDS, ds

		; set custom pattern, gstate
GSLM_custom:
		push	ds			; save gstate segment
		mov	ah, ch			; use custom gstring code
		segmov	ds, es			; restore pointer segment
		;
		; copy the pattern into stack
		;
if FULL_EXECUTE_IN_PLACE
		mov	cx, 8			; 8 byte-pattern
		call	SysCopyToStackDSSIFar	; ds:si = pattern on stack
endif
		test	al, mask SDM_INVERSE	; see if we need to invert
		jz	storeit
		mov	cx, 0xffff
		xor	ds:[si], cx		; invert the mask
		xor	ds:[si+2], cx		; invert the mask
		xor	ds:[si+4], cx		; invert the mask
		xor	ds:[si+6], cx		; invert the mask
storeit:
		mov	al, ah
		mov	ah, GSSC_FLUSH		; allow flushes
		mov	cx, 8			; eight bytes/pattern
		call	GSStore			; write element
		mov	cx, 0xffff		; restore passed mask
		xor	ds:[si], cx		; invert the mask
		xor	ds:[si+2], cx		; invert the mask
		xor	ds:[si+4], cx		; invert the mask
		xor	ds:[si+6], cx		; invert the mask
if FULL_EXECUTE_IN_PLACE
		call	SysRemoveFromStackFar	; release stack space
endif
		pop	ds			; restore gstate pointer
		jmp	rejoinGS		; rejoin normal code
GrSetLineMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetAreaMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current area drawing pattern

CALLED BY:	GLOBAL

		
PASS:		di - handle of graphics state

		al	- record of type SysDrawMask, where


			   bit 7: 	set to use inverse of passed pattern
					use mask SDM_INVERSE
			   bits 6-0: 	system pattern number


		if the low 7 bits of al = SDM_CUSTOM, then:

			ds:si	- pattern to set

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new index;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When segments are supported, this routine should deal with
		saving this "command" to the any currently open segments.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetAreaMask	proc	far
if	FULL_EXECUTE_IN_PLACE
EC <		push	ax					>
EC <		andnf	al, mask SDM_MASK			>
EC <		cmp	al, SDM_CUSTOM				>
EC <		pop	ax					>
EC <		jne	xipOK					>
EC <		call	ECCheckBounds				>
xipOK::
endif
		push	ds
		push	bx,cx,es
		mov	bx, offset GS_areaAttr
		mov	cx,(GR_SET_CUSTOM_AREA_MASK shl 8) or GR_SET_AREA_MASK 
		jmp	setMaskCommon
GrSetAreaMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current text drawing pattern

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state

		al	- record of type SysDrawMask, where


			   bit 7: 	set to use inverse of passed pattern
					use mask SDM_INVERSE
			   bits 6-0: 	system pattern number


		if the low 7 bits of al = SDM_CUSTOM, then:

			ds:si	- pattern to set

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set the new index;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When segments are supported, this routine should deal with
		saving this "command" to the any currently open segments.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTextMask	proc	far
		
if	FULL_EXECUTE_IN_PLACE
EC <		push	ax					>
EC <		andnf	al, mask SDM_MASK			>
EC <		cmp	al, SDM_CUSTOM				>
EC <		pop	ax					>
EC <		jne	xipOK					>
EC <		call	ECCheckBounds				>
xipOK::
endif
		push	ds
		push	bx,cx,es
		mov	bx, offset GS_textAttr
		mov	cx,(GR_SET_CUSTOM_TEXT_MASK shl 8) or GR_SET_TEXT_MASK 
		jmp	setMaskCommon
GrSetTextMask	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new draw mask in the gstate structure

CALLED BY:	INTERNAL
		GrSetLineMask, GrSetAreaMask, GrSetTextMask

PASS:		di	- offset in gstate to mask attribute to set

		al	- new pattern index (for system pattern)
		- OR -
		al	- SET_CUSTOM_PATTERN (for custom pattern)
		ds:si	- pattern to set

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		set the mask;
		shift if necessary;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMask		proc	near
		uses	dx
		.enter

		mov	dl, ds:[di].CA_flags	;assume no optimizations
		and	dl, not ((mask AO_MASK_1) or (mask AO_MASK_1_COPY) or \
				 (mask AO_MASK_1_INVERT))
		cmp	al, SDM_100		;draw mask all 1's
		jz	allOnes
		cmp	al, SDM_0 or mask SDM_INVERSE
		jz	allOnes

		; save flags and mask
storeMask:
		mov	ds:[di].CA_flags, dl

		mov	ds:[di].CA_maskType, al ; save number too
		add	di,CA_mask		;point at draw mask
		call	GrCopyDrawMask

		; need to shift mask to align with screen

		mov	dx, si			; save source pointer
		push	ax
		mov	ax, word ptr ds:[GS_xShift]; get curr shift values
		sal	ax, 1			; *2 since GrShift..
		mov	si, di			;  calcs relative shift
		call	GrShiftMaskFar		; ds:si -> mask buffer,
						;  shift it
		pop	ax
		mov	si, dx			; restore source pointer

		.leave
		ret

		; optimization possible, save flag
		; test for GR_COPY
allOnes:
		mov	dh,ds:[GS_mixMode]
		or	dl,mask AO_MASK_1 or mask AO_MASK_1_COPY
		cmp	dh, MM_COPY
		jz	storeMask

		; test for GR_INVERT

		xor	dl,mask AO_MASK_1_COPY or mask AO_MASK_1_INVERT
		cmp	dh, MM_INVERT
		jz	storeMask
		xor	dl,mask AO_MASK_1_INVERT
		jmp	storeMask

SetMask		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetLineColorMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the current line color mapping mode

CALLED BY:	GLOBAL

PASS: 		al - color mapping mode:
		    bits 0-1: enum of type ColorMapType
			CMT_CLOSEST   - map colors to black or white
			CMT_DITHER  - map colors to gray scales

		    bit 2 = bit CMM_ON_BLACK
			clear - writing on white background
			set   - writing on black background

		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetLineColorMap proc	far
		push	ds
		push	ax, bx
		mov	ah, GR_SET_LINE_COLOR_MAP
		mov	bx, offset GS_lineAttr.CA_mapMode
ColorMapCommon	label	near

EC <		cmp	al,LAST_MAP_MODE				>
EC <		ERROR_A	GRAPHICS_ILLEGAL_LINE_MAP_MODE			>
		call	LockDI_DS_check
		mov	ds:[bx],al
		jnz	exit			; jump for Paths or GState

		; need to write out to a gstring

		push	cx
		xchg	al, ah
		mov	cl, 1
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes
		pop	cx
exit:
		pop	ax, bx
		GOTO	UnlockDI_popDS, ds
GrSetLineColorMap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetAreaColorMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the current area color mapping mode

CALLED BY:	GLOBAL

PASS: 		al - color mapping mode:
		    bits 0-1: enum of type ColorMapType
			CMT_CLOSEST   - map colors to black or white
			CMT_DITHER  - map colors to gray scales

		    bit 2 = bit CMM_ON_BLACK
			clear - writing on white background
			set   - writing on black background

		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetAreaColorMap	proc	far
		push	ds
		push	ax, bx
		mov	ah, GR_SET_AREA_COLOR_MAP
		mov	bx, offset GS_areaAttr.CA_mapMode
		jmp	ColorMapCommon
GrSetAreaColorMap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextColorMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the current text color mapping mode

CALLED BY:	GLOBAL

PASS: 		al - color mapping mode:
		    bits 0-1: enum of type ColorMapType
			CMT_CLOSEST   - map colors to black or white
			CMT_DITHER  - map colors to gray scales

		    bit 2 = bit CMM_ON_BLACK
			clear - writing on white background
			set   - writing on black background

		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTextColorMap	proc	far
		push	ds
		push	ax, bx
		mov	ah, GR_SET_TEXT_COLOR_MAP
		mov	bx, offset GS_textAttr.CA_mapMode
		jmp	ColorMapCommon
GrSetTextColorMap	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextSpacePad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the amount to pad spaces by in PutString().

CALLED BY:	GLOBAL

PASS:		di - handle of graphics state
		dx.bl - space padding (WBFixed)
		DBCS:
			dx:15 - 1 = char padding, 0 = space padding
			dx:0-14 - space padding

RETURN:		none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTextSpacePad	proc	far
		push	ds
		call	LockDI_DS_check
if CHAR_JUSTIFICATION
		pushf					;save carry
		push	ax, dx
	;
	; Set the one and only TextMiscModeFlag.
	;
		mov	ah, dh
		mov	al, ds:GS_textMiscMode
		andnf	al, not (mask TMMF_CHARACTER_JUSTIFICATION)
			CheckHack <offset TMMF_CHARACTER_JUSTIFICATION eq 7>
		ornf	al, ah
		mov	ds:GS_textMiscMode, al
	;
	; Set the space padding
	;
		andnf	dh, not (mask TMMF_CHARACTER_JUSTIFICATION)
		mov	ds:GS_textSpacePad.WBF_int,dx
		pop	ax, dx
		popf					;restore carry
else
		mov	ds:GS_textSpacePad.WBF_int,dx
endif
		mov	ds:GS_textSpacePad.WBF_frac, bl
		jnc	exit

		; If GString or Path, store data away for future use

		push	ax,bx,cx
		mov	al, GR_SET_TEXT_SPACE_PAD
		mov	ah, bl
		mov	bx, dx
		mov	cx, size WBFixed or (GSSC_FLUSH shl 8)
		call	GSStoreBytes
		pop	ax,bx,cx
exit:
		GOTO	UpdateOpts, ds
GrSetTextSpacePad	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the current text style

CALLED BY:	GLOBAL

PASS: 		al - style bits to SET (TextStyle)
		ah - style bits to RESET (TextStyle)
		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTextStyle	proc	far
		push	ds

		; lock down the gstate

		call	LockDI_DS_check

		; handle update of gstate structure

		pushf				; save carry
		push	ax
		not	ah
		and	ah,ds:[GS_fontAttr.FCA_textStyle]
		or	al,ah			;mask in bits to set

		mov	ah,al			;save new value for opts
		xchg	ds:[GS_fontAttr.FCA_textStyle],al ;save new, al = old

		xor	al,ah			;al = bits that changed
		and	al, not KERNEL_STYLES	;don't worry about these
		je	noStyles		;branch if no style change
		call	FarInvalidateFont	;style changed - font does, too
noStyles:
		pop	ax
		popf				; restore carry
		jnc	exit			; if GState, do nothing

		; For GString or Path, store data away for future use

		push	bx, cx
		mov_tr	bx, ax
		mov	al, GR_SET_TEXT_STYLE
		mov	cx, 2 or (GSSC_FLUSH shl 8)
		call	GSStoreBytes
		mov_tr	ax, bx
		pop	bx, cx
exit:
		GOTO	UnlockDI_popDS, ds
GrSetTextStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the current text mode

CALLED BY:	GLOBAL

PASS: 		al - mode bits to SET
		ah - mode bits to RESET
		    TM_DRAW_MEAN  - Draw characters from middle of font.
		    TM_DRAW_BASE  - Draw characters from the baseline offset.
		    TM_DRAW_BOTTOM- Draw characters from bottom of font.
		    TM_DRAW_ACCENT- Draw characters from accent line of font.
		    TM_DRAW_OPTIONAL_HYPHENS - Draw optional hyphens if they
		    		    fall at the end of a string.
		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTextMode	proc	far
NEC <		and	ax, not ((TM_INTERNAL shl 8) or (TM_INTERNAL))	>

		push	ds
		call	LockDI_DS_check
		pushf				; save carry
		push	ax
		not	ah
		and	ah,ds:[GS_textMode]	;mask out bits to reset
		or	al,ah			;mask in bits to set
		mov	ds:[GS_textMode],al
		pop	ax
		popf				; restore carry
		jnc	done			; if GState, we're done

		; For GString or Path, store data away for future use

		push	bx, cx
		mov_tr	bx, ax
		mov	al, GR_SET_TEXT_MODE
		mov	cx, 2 or (GSSC_FLUSH shl 8)
		call	GSStoreBytes
		mov_tr	ax, bx			; restore AX
		pop	bx, cx
done:
		GOTO	UpdateOpts, ds
GrSetTextMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the current text direction

CALLED BY:	GLOBAL

PASS: 		al - TextDirection
		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Les	02/12/02	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SIMPLE_RTL_SUPPORT
GrSetTextDirection	proc	far
		push	ds
		call	LockDI_DS_check
		pushf
		; Just store it away
		mov	ds:[GS_textDirection], al
		popf
		jnc	done
		push	ax, bx, cx
		mov	ah, al
		mov	al, GR_SET_TEXT_DIRECTION
		mov	cx, 1 or (GSSC_FLUSH shl 8)
		call	GSStoreBytes
		pop	ax, bx, cx
done:
		GOTO	UnlockDI_popDS, ds
GrSetTextDirection endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextDrawOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	# of characters at the end of the string to draw.
		
		This operation is NEVER saved out to a graphics string.

CALLED BY:	
PASS:		di	= GState handle.
		ax	= # of characters to draw.
			= 0 to draw the entire string.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetTextDrawOffset	proc	far
	push	ds
	call	LockDI_DS_check
	mov	ds:GS_textDrawOffset, ax	; save offset.
	GOTO	UpdateOpts, ds
GrSetTextDrawOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the line width

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		dx.ax - line width (WWFixed)
RETURN:
		nothing
DESTROYED:
		nothing

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetLineWidth	proc	far
		push	ds

EC <		cmp	dx, MAX_LINE_WIDTH				>
EC <		ERROR_A	GRAPHICS_ILLEGAL_LINE_WIDTH			>
		call	LockDI_DS_check
		mov	ds:[GS_lineWidth].WWF_frac, ax
		mov	ds:[GS_lineWidth].WWF_int, dx
		jnz	exit			; jump if Path or GState

		; write line width setting to gstring

		push	ax, bx, cx
		mov	bx, ax
		mov	al, GR_SET_LINE_WIDTH
		mov	cl, size WWFixed	; storing much data
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes
		pop	ax, bx, cx
exit:
		GOTO	UnlockDI_popDS, ds

GrSetLineWidth	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetLineEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the end type

CALLED BY:	GLOBAL

PASS:		al - end type (enum type is LineEnd)
			LE_BUTTCAP
			LE_ROUNDCAP
			LE_SQUARECAP
		di - handle of graphics state
RETURN:
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetLineEnd	proc	far
		push	ds
		push	bx, cx
		mov	bx, offset GS_lineEnd
		mov	cl, GR_SET_LINE_END
EC <		cmp	al,LAST_LINE_END_TYPE			>
EC <		ERROR_A	GRAPHICS_ILLEGAL_LINE_END_TYPE		>
		jmp	setByteCommon
GrSetLineEnd	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetLineJoin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the join type

CALLED BY:	GLOBAL

PASS:		al - join type (enum type is LineJoin)
			LJ_MITERED
			LJ_ROUND
			LJ_BEVELED
		di - handle of graphics state
RETURN:		LineEnd
DESTROYED:

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetLineJoin	proc	far
		push	ds
		push	bx, cx
		mov	bx, offset GS_lineJoin
		mov	cl, GR_SET_LINE_JOIN

EC <		cmp	al,LAST_LINE_JOIN_TYPE				>
EC <		ERROR_A	GRAPHICS_ILLEGAL_LINE_JOIN_TYPE			>
setByteCommon	label	near
		call	LockDI_DS_check
		mov	ds:[bx], al
		jnz	exit			; jump if Path or GState

		; write it out to a gstring

		push	ax
		mov	ah, cl
		xchg	al, ah
		mov	cl, 1
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes
		pop	ax
exit:
		pop	bx, cx
		GOTO	UnlockDI_popDS, ds
GrSetLineJoin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetMiterLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the miter limit. Actually, in the GState the inverse
		of the miter limit is stored. See the routine CheckMiterLimit
		for the reason why. Also, to keep the size to only one word
		if, 1 is passed to us we store 0ffffh. Its close enough.
		(1 <= miter limit <= 32767 )

CALLED BY:	GLOBAL

PASS:		bx:ax - miter limit (16 bits integer, 16 bits fractional)
		di - handle of graphics state

RETURN:		GS_inverseMiterLimit

DESTROYED:

PSEUDO CODE/STRATEGY:
	The miter limit basically defines the smallest angle that will
	be drawn with a miter join. Any smaller angles will be drawn with
	a beveled join.
	A miter limit of one means that all miter joins will be drawn as
	bevels. As the miter limit increase the cut off angle gets smaller.
	The initial value is 10 ( stored as .1 ) which corresponds to
	approximately 11 degrees

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetMiterLimit	proc	far
EC <		cmp	bx, 0						>
EC <		ERROR_LE GRAPHICS_ILLEGAL_MITER_LIMIT			>

		push	ds
		call	LockDI_DS_check
		pushf					; save gstring stat
		push	ax, bx				; save passed limit
		call	GrReciprocal32Far
		tst	ax
		jne	GSML_10
		mov	ax,0ffffh
GSML_10:
		mov	ds:[GS_inverseMiterLimit], ax
		pop	ax, bx			; restore orig limit
		popf
		jnz	exit			; jump if Path or GState

		; writing to a gstring, do it

		push	cx,dx
		mov	dx, bx
		mov	bx, ax
		mov	al, GR_SET_MITER_LIMIT
		mov	cl, size WWFixed
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes
		mov	ax, dx
		pop	cx,dx
exit:
		GOTO	UnlockDI_popDS, ds
GrSetMiterLimit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the line attributes

CALLED BY:	GLOBAL

PASS:		di	- gstate/gstring handle

		ds:si	- pointer to LineAttr structure

			LineAttr	struct
			    LA_colorFlag ColorFlag CF_INDEX	; color type
			    LA_color	 RGBValue <0,0,0>	; color values 
			    LA_mask	 SystemDrawMask		; draw mask
			    LA_mapMode	 ColorMapMode 		; map mode
			    LA_end	 LineEnd		; end type
			    LA_join	 LineJoin		; join type
			    LA_style	 LineStyle		; dotted...
			    LA_width	 WWFixed		; line width
			LineAttr	ends

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set all the new parameters in the gstate.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetLineAttr	proc	far
		push	ds
		uses	ax, bx, cx, dx, di, si, bp, es
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		call	ECCheckBounds					>
endif
		; first check possible errors in parameters

EC <		cmp	ds:[si].LA_end, LAST_LINE_END_TYPE		>
EC <		ERROR_A GRAPHICS_ILLEGAL_LINE_END_TYPE			>
EC <		cmp	ds:[si].LA_join, LAST_LINE_JOIN_TYPE		>
EC <		ERROR_A GRAPHICS_ILLEGAL_LINE_JOIN_TYPE			>
EC <		cmp	ds:[si].LA_width.WWF_int, MAX_LINE_WIDTH	>
EC <		ERROR_A GRAPHICS_ILLEGAL_LINE_WIDTH			>

		mov	bp, ds			; bp:si -> LineAttr

		; call a common routine to set map mode, mask and color

		call	LockDI_DS_check
		mov	bx, si			; bp:bx -> LineAttr
		mov	si, offset GS_lineAttr	; pointer to structure
		call	SetCommonAttr
		
		mov	es, bp			; es:bx -> passed structure
		mov	al, es:[bx].LA_end	; copy over each component
		mov	ds:[GS_lineEnd], al
		mov	al, es:[bx].LA_join
		mov	ds:[GS_lineJoin], al
		mov	al, es:[bx].LA_style
		pushf
		push	ds, es, bx, di, bp
		segmov	es, ds, bx
		clr	bl
		call	SetLineStyle
		pop	ds, es, bx, di, bp
		popf
		mov	ax, es:[bx].LA_width.WWF_frac
		mov	ds:[GS_lineWidth].WWF_frac, ax
		mov	ax, es:[bx].LA_width.WWF_int
		mov	ds:[GS_lineWidth].WWF_int, ax
		jnz	exit			; jump if Path or GState

		; writing to a gstring, do it

		push	ds			; save gstate seg
		mov	ds, bp			; ds:si -> LineAttr struc
		mov	si, bx			; 
		mov	ax, (GSSC_FLUSH shl 8) or GR_SET_LINE_ATTR ; opcode
		mov	cx, size LineAttr
		call	GSStore
		pop	ds			; restore gstate seg
exit:
		.leave
		GOTO	UnlockDI_popDS,ds
GrSetLineAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current line style

CALLED BY:	INTERNAL
		GrSetLineStyle

PASS:		es 	- segment of graphics state	
		al	- LineStyle enum
				LS_SOLID
				LS_DASHED
				...
				LS_CUSTOM
		bl	- skip distance into first pair
		
		if al = LS_CUSTOM
			ds:si - seg,offset to dash array
			ah - # of pairs in dash array
RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,es,ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetLineStyle	proc	far

	; do some parameter checking

EC <	tst	bl			 				>
EC < 	jge	skipOK							>
EC < badSkip:								>
EC <	ERROR	GRAPHICS_ILLEGAL_DASH_SKIP_DISTANCE ;bad dash skip dist	>
EC < skipOK:								>
EC <	cmp	al, LS_CUSTOM					>
EC <	ERROR_A	GRAPHICS_ILLEGAL_LINE_STYLE	;bad line style 	>
EC <	jb	GSLS_10				;jmp if not custom 	>
EC <	cmp	ah,MAX_DASH_ARRAY_PAIRS					>
EC <	ja	badPair							>
EC <	tst	ah							>
EC <	jnz	lineOK							>
EC <badPair:								>
EC < 	ERROR	GRAPHICS_ILLEGAL_NUM_DASH_PAIRS	;bad dash array size 	>
EC <lineOK:								>
EC <GSLS_10:								>

	mov	es:[GS_lineStyle],al		;set line style
	cmp	al, LS_SOLID			; if solid, were home free
	je	done
	
	; resolve pointer to on/off array, either system or custom

	cmp	al, LS_CUSTOM
	je	GSLS_20				;jmp if custom style
	call	GetPtrToSysDashArray

GSLS_20:					;ds:si, ah -number of pairs
	mov	cl,ah				;number of pairs
	mov	es:[GS_numOfDashPairs],cl
	mov	es:[GS_dashSkipDistance],bl	
	mov	di,GS_dashPairArray		;offset to store
EC <	lodsw					;get first pair	>
EC <	add	al,ah				;total of first pair >
EC <	cmp	bl,al				;skip distance to first pair >
EC <	ja	badSkip							>
EC <	sub	si,2				;pt back to first >

GSLS_30:
	lodsw					;get a pair
EC <	tst	al 							>
EC <	jz	badSeed							>
EC <	tst	ah 							>
EC <badSeed:								>
EC <	ERROR_Z	GRAPHICS_ILLEGAL_DASH_ARRAY_ELEMENT ;bad dash array element >
	stosw					;store the pair
	dec	cl
	jnz	GSLS_30
done:
	ret

SetLineStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetAreaAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the area attributes

CALLED BY:	GLOBAL

PASS:		di	- gstate/gstring handle

		ds:si	- pointer to AreaAttr structure

			AreaAttr	struct
			    AA_colorFlag ColorFlag CF_INDEX	; color type
			    AA_color	 RGBValue <0,0,0>	; color value
			    AA_mask	 SystemDrawMask		; draw mask
			    AA_mapMode	 ColorMapMode 		; map mode
			AreaAttr	ends
		
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set all the new parameters in the gstate.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrSetAreaAttr	proc	far
		push	ds
		uses	ax, bx, bp, si, cx
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		call	ECCheckBounds			>
endif

		; lock the gstate, check for graphics string, set the
		; frist few attributes

		mov	bp, ds			; bp:si -> AreaAttr
		call	LockDI_DS_check
		mov	bx, si			; bp:bx -> AreaAttr
		mov	si, offset GS_areaAttr	; pointer to structure
		call	SetCommonAttr
		jnz	exit			; jump if Path or GState

		; valid gstring, write out element

		push	ds
		mov	ds, bp
		mov	si, bx
		mov	ax, (GSSC_FLUSH shl 8) or GR_SET_AREA_ATTR ; opcode
		mov	cx, size AreaAttr
		call	GSStore
		pop	ds			; restore gstate pointer
exit:
		.leave
		GOTO	UnlockDI_popDS,ds
GrSetAreaAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCommonAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to set a few of the common attributes
		GrSetAreaAttr, GrSetLineAttr

CALLED BY:	GLOBAL

PASS:		ds	- gstate (locked)
		carry	- set if gseg

		bp:bx	- pointer to attribute structure.  The first part of
			  each of the LineAttr and AreaAttr structures are 
			  the same.
		ah	- color flag, al/bx has color info (see above)
		dl	- color map mode
		dh	- system draw mask
		si	- offset to attr info struct (type CommonAttr)

RETURN:		ds	- gstate segment
		carry	- set if writing to a gstring
		above attr set in gstate

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetCommonAttr	proc	near
		uses	ax, cx, es, bx
		.enter

		; first check possible errors in parameters

		mov	es, bp
EC <		pushf						>
EC <		cmp	es:[bx].AA_mapMode, LAST_MAP_MODE		>
EC <		ERROR_A GRAPHICS_ILLEGAL_LINE_MAP_MODE		>
EC <		cmp	es:[bx].AA_mask, LAST_SYSTEM_DRAW_MASK	>
EC <		ERROR_A GRAPHICS_ILLEGAL_SYSTEM_PATTERN		>
EC <		popf						>

		; first lock the gstate and see about gstring status

		pushf					; save gstring flag

		; set the color map mode

		mov	al, es:[bx].AA_mapMode
		mov	ds:[si].CA_mapMode, al

		; set the color

		mov	cl, GSTATE_LOCKED or LEAVE_GSTATE ; flags to SetColor
		add	si, offset CA_colorIndex	; set ptr to color info
		mov	ah, es:[bx].AA_colorFlag
		mov	al, es:[bx].AA_color.RGB_red
		push	bx
		mov	bx, {word} es:[bx].AA_color.RGB_green
		call	SetColorAfterPWin		; set 
		sub	si, offset CA_colorIndex	; restore pointer
		pop	bx				; restore attr offset

		; set the draw mask

		push	di				; save gstring handle
		mov	di, si				; set up pointer
		mov	al, es:[bx].AA_mask		; set up sys patt #
		call	SetMask
		pop	di				; restore gstring han
		popf					; restore gstring flag
		.leave
		ret
SetCommonAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTextAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the text attributes

CALLED BY:	GLOBAL

PASS:		di	- gstate/gstring handle

		ds:si	- ptr to TextAttr structure

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		set all the new parameters in the gstate.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTextAttr	proc	far
		push	ds
		uses	ax, cx, bp, bx
		.enter

if	FULL_EXECUTE_IN_PLACE
EC <		call	ECCheckBounds			>		
endif		
		; lock the gstate

		mov	bp, ds			; save original segment
		call	LockDI_DS_check


		; set the parameters after P'ing the window

		pushf				; save gstring flag
		mov	bx, ds:[GS_window]
		tst	bx
		jz	windowPed
		call	HandleP

windowPed:
		call	SetTextAttrLow		; set them all

		tst	bx
		jz	checkGstring
		call	HandleV
checkGstring:
		popf				; gstore gstring flag
		jnc	done			; jump if GState

		; writing to a gstring, so do it

		push	ds			; save reg not saved yet
		mov	ds, bp			; restore data pointer
		mov	ax, (GSSC_FLUSH shl 8 ) or GR_SET_TEXT_ATTR ; opcode
		mov	cx, size TextAttr	; store them all
		call	GSStore
		pop	ds			; restore reg
done:
		.leave
		GOTO	UnlockDI_popDS,ds
GrSetTextAttr	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextAttrInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal version of GrSetTextAttr

CALLED BY:	INTERNAL
		GrDrawTextField

PASS:		es	- locked/owned window structure
		ds:si	- ptr to block holding TextAttr structure
		di	- gstate handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Set all the attributes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
SetTextAttrInt	proc	far
		uses	ax, bx, bp, ds
		.enter

		; lock the gstate

		mov	bp, ds			; save data ptr
		mov	bx, di			; gstate handle
		call	MemLock			; ds <- GState
		mov	ds, ax

		; now set the attributes

		call	SetTextAttrLow		; set all the attributes

		; now unlock the gstate

		call	MemUnlock		; unlock gstate

		.leave
		ret
SetTextAttrInt	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextAttrLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the text attributes in one swell foop

CALLED BY:	INTERNAL
		GrSetTextAttr, SetTextAttrInt

PASS:		es	- locked/owned window segment
		ds	- locked gstate segment
		bp:si	- pointer to TextAttr structure

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		Set all the parameters;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
SetTextAttrLow	proc	near
		uses	bx, cx, dx, di, es
		.enter

		push	es
		mov	es, bp				; get old ds
		mov	ax, es:[si].TA_color.low
		mov	bx, es:[si].TA_color.high
		pop	es
		mov	dx, si				; save ptr to args
		mov	cl, GSTATE_LOCKED or LEAVE_GSTATE
		mov	si, GS_textAttr.CA_colorIndex	; ptr to color part
		call	SetColor
		mov	si, dx				; restore args ptr

		; set text draw mask

		mov	es, bp			; get old ds
		mov	di, offset GS_textAttr	; set mask
		mov	al, es:[si].TA_mask
		call	SetMask

		mov	ax, {word} es:[si].TA_styleSet
		not	ah
		and	ah, ds:[GS_fontAttr.FCA_textStyle]	;bits to set
		or	al, ah			;mask out bits to reset
		mov	ah, al			;ah <- new bits
		xchg	ds:[GS_fontAttr.FCA_textStyle], al ;save new, al -> old
		xor	al, ah			;al <- bits that changed
		and	al, not KERNEL_STYLES	;don't worry about these
		je	sameStyle		;branch if same style
		call	FarInvalidateFont	;else invalidate font
sameStyle:

		mov	ax, {word} es:[si].TA_modeSet
NEC <	and	ax, not ((TM_INTERNAL shl 8) or (TM_INTERNAL))		>
EC <	test	ax, (TM_INTERNAL shl 8) or (TM_INTERNAL)		>
EC <	ERROR_NZ	GRAPHICS_ILLEGAL_TEXT_MODE			>
		not	ah
		and	ah,ds:[GS_textMode]	;mask out bits to reset
		or	al, ah			;or in bits to reset
		mov	ds:[GS_textMode], al

		mov	al, es:[si].TA_spacePad.WBF_frac ; get fractional part
		mov	ds:GS_textSpacePad.WBF_frac, al
		mov	ax, es:[si].TA_spacePad.WBF_int	 ; get pixel part
		mov	ds:GS_textSpacePad.WBF_int, ax

;-----------------------------------------------------------------------------
		;
		; Set up the font parameters:
		;	Font	word	(cx)
		;	Size	WBFixed	(dxah)
		;	Weight	word	(bx)
		;	Width	word	(di)
		;
		mov	cx, es:[si].TA_font		; cx <- font ID
		movwbf	dxah, es:[si].TA_size		; dx.ah <- pointsize
		mov	bx, {word} es:[si].TA_fontWeight ; bx <- width + width

		;
		; Check for any differences so we can invalidate the font
		;
		cmp	ds:GS_fontAttr.FCA_fontID, cx
		jne	diffFace

		cmpwbf	ds:GS_fontAttr.FCA_pointsize, dxah
		jne	diffFace
		
		cmp	{word}ds:GS_fontAttr.FCA_weight, bx
		je	fontDone

diffFace:
		call	FarInvalidateFont	; invalidate font handle
		
		;
		; Save new font info
		;
		mov	ds:GS_fontAttr.FCA_fontID, cx
		movwbf	ds:GS_fontAttr.FCA_pointsize, dxah
		mov	{word} ds:GS_fontAttr.FCA_weight, bx
fontDone:
;-----------------------------------------------------------------------------
		mov	ax, {word}es:[si].TA_trackKern
		mov	{word}ds:GS_trackKernDegree, ax

		; Set the pattern

		mov	ax, {word} es:[si].TA_pattern
		mov	{word}ds:GS_textPattern, ax

		call	UpdateOptsAndReturn	; update optimization vars

		.leave
		ret
SetTextAttrLow	endp

;
; Test some assertions I've made above, -jw
;
.assert	(offset FCA_width) eq (offset FCA_weight + 1)
.assert	(offset TA_fontWidth) eq (offset TA_fontWeight + 1)


GraphicsDashedLine	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetLineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL

PASS:		
		al - LineStyle enum
		bl - skip distance into first pair
		di - handle of graphics state		

		if al = LS_CUSTOM
			ds:si - seg,offset to dash array
			ah - # of pairs in dash array
		
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/89	Initial version
	jim	2/90		moved some to klib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetLineStyle		proc	far
	uses 	ax,bx,cx,dx,di,si,es		;don't destroy

	; need to preserve passed ds since it's trashed by LockDS_DS_check

	push	ds
	.enter
if	FULL_EXECUTE_IN_PLACE
EC <	cmp	al, LS_CUSTOM						>
EC <	jne	continue						>
EC <	push	bx							>
EC <	mov	bx, ds							>
EC <	call	ECAssertValidFarPointerXIP				>
EC <	pop	bx							>
continue::
endif	
	mov	dx, ds				; save custom pointer in case
	call	LockDI_DS_checkFar		; ds -> gstate
	push	ax,bx,dx,si,di
	pushf					; save gstring flag

	segmov	es, ds				; es -> gstate
	mov	ds, dx				; ds -> dash array
	call	SetLineStyle			; moved to klib

	popf					; restore gstring flag
	pop	ax,bx,dx,si,di			; restore params
	jc	handleGS			; handle gstring if present

	; all done, get outta here
exit:
	segmov	ds, es				; reset ds -> gstate
	.leave
	GOTO	UnlockDI_popDS,ds

	; write out the gstring
handleGS:
	jnz	exit				; if Path, get out of here
	cmp	al, LS_CUSTOM
	je	gsegCustom
	mov	bh, bl				; standard style, set index
	mov	bl, al				; set style type
	mov	al, GR_SET_LINE_STYLE		; set opcode
	mov	cl, 2				; store index and style type
	mov	ch, GSSC_FLUSH
	call	GSStoreBytes			; write out to gstring	
	jmp	exit

	; setting custom line style, write out style bytes
gsegCustom:
	mov	al, GR_SET_CUSTOM_LINE_STYLE	; bl already = index
	mov	dl, ah				; bl = index, dl = count
	clr	dh, bh
	mov	cl, 4				; store index and count
	mov	ch, GSSC_DONT_FLUSH
	call	GSStoreBytes
	mov	cx, dx				; get count
	shl	cx, 1				; byte count = #pairs * 2
	mov	ax, (GSSC_FLUSH shl 8) or 0xff	; just store the data
	call	GSStore				; write out array
	jmp	exit
GrSetLineStyle		endp

GraphicsDashedLine	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPtrToSysDashArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns pointer to system dash array

CALLED BY:	INTERNAL
		GrGetLineStyle

PASS:		
	al		- dash array number

RETURN:		
	ds:si		- offset to pairs in system dash array
	ah		- size of system dash array

DESTROYED:	
	al,cx,dx

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: the pointer this routine returns is in code.  Therefore,
	this routine must be in a fixed code segment, such as kcode.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.assert @CurSeg eq kcode

GetPtrToSysDashArray	proc	near
	mov	cx,cs				;segment sys dash arrays
	mov	ds,cx				;in ds
	mov	si, offset cs:sysDashArray01
GPTSDA_5:
	dec	al
	jz	GPTSDA_90			;jmp if pointing to it
	clr	dh
	mov	dl,ds:[si]			;num pairs in dash array
	shl	dx,1				;each pair is a word
	inc	dx				;byte for num elements
	add	si,dx				;advance to next sys array
	jmp	GPTSDA_5
GPTSDA_90:		
	lodsb					;return number of pairs
	mov	ah,al				;in ah
	ret
GetPtrToSysDashArray	endp

				;LS_DASHED
sysDashArray01		db	1		;number of pairs
			db	4		;ON
			db	4		;OFF

				;LS_DOTTED
; sysDashArray02		
			db	1		;number of pairs
			db	1		;ON
			db	2		;OFF

				;LS_DASHDOT
; sysDashArray03		
			db	2		;number of pairs
			db	4		;ON
			db	4		;OFF
			db	1		;ON
			db	4		;OFF

				;LS_DASHDDOT
; sysDashArray04
			db	3		;number of pairs
			db	4		;ON
			db	4		;OFF
			db	1		;ON
			db	4		;OFF
			db	1		;ON
			db	4		;OFF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateOptsAndReturn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update optimizations in the gstate and return.

CALLED BY:	Utility.
PASS:		ds = segment address of gstate.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateOptsAndReturn	proc	near
	uses	ax, dx
	.enter

	;
	; Check for draw mask all 1's
	;
	clr	al
	test	ds:GS_textAttr.CA_flags, mask AO_MASK_1
	jnz	isOnes
	dec	al
isOnes:
	mov	ds:GS_optDrawMask, al

	;
	; Check for any space padding
	;
	mov	dl, ds:GS_textMode		;dl <- TextMode
	mov	dh, 0
	mov	al, GO_FALL_THRU		;assume no padding
	mov	ah, ds:GS_textSpacePad.WBF_int.high
	or	ah, ds:GS_textSpacePad.WBF_int.low
	or	ah, ds:GS_textSpacePad.WBF_frac
if CHAR_JUSTIFICATION
	mov	ah, GO_JNE
endif
	jz	noPad
	mov	dh, mask TM_PAD_SPACES
	mov	al, GO_SPECIAL_CASE		;there is padding
if CHAR_JUSTIFICATION
	;
	; For justification type, the logic is reversed. If we are
	; using character justification, then we want to fall
	; through.  For word justification, it should do a 'jne'.
	;
	test	ds:GS_textMiscMode, mask TMMF_CHARACTER_JUSTIFICATION
	jz	gotJustType
	mov	ah, GO_FALL_THRU
gotJustType:
endif

noPad:
	mov	ds:GS_optSpacePad, al
if CHAR_JUSTIFICATION
	mov	ds:GS_optFullJust, ah
endif
	andnf	dl, not (mask TM_PAD_SPACES)
	ornf	dl, dh				;set/clear padding flag
	mov	ds:GS_textMode, dl		;store (new) TextMode

	;
	; Check for handling soft hyphens:
	;	dl = GS_textMode
	;
	mov	al, GO_SPECIAL_CASE
	test	dl, mask TM_DRAW_OPTIONAL_HYPHENS
	jnz	drawHyphens
	mov	al, GO_FALL_THRU
drawHyphens:
	mov	ds:GS_hyphenOpcode, al

	;
	; Check for drawing control characters
	;
	mov	al, GO_SPECIAL_CASE
	test	dl, mask TM_DRAW_CONTROL_CHARS
	jnz	drawControl
	mov	al, GO_FALL_THRU
drawControl:
	mov	ds:GS_drawCtrlOpcode, al

	;
	; Check for track kerning or pairwise kerning
	;	dl = GS_textMode
	;
	mov	ds:GS_kernOp, GO_FALL_THRU	;
	mov	{word}ds:GS_trackKernValue, 0	;assume no kerning
	tst	{word}ds:GS_trackKernDegree	;see if track kerning
	jnz	isKern				;branch if track kerning
	test	dl, mask TM_PAIR_KERN
	jz	afterKern			;branch if no pairwise kerning
isKern:
	call	RecalcKernValues		;recalc kern values
afterKern:
	mov	al, GO_FALL_THRU
	tst	ds:GS_textDrawOffset
	jz	setOffsetOp
	mov	al, GO_SPECIAL_CASE
setOffsetOp:
	mov	ds:GS_drawOffsetOpcode, al
	.leave
	ret

UpdateOptsAndReturn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockDI_DS_check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Lock handle in di, move segment to ds and check for gseg.
		Called by attributes routines to do this generic entry stuff.
		Uses inline macros for speed

CALLED BY:	INTERNAL

PASS: 		di - handle

RETURN: 	if normal graphics drawing
		    carry clear
		    zero clear
		    ds - segment of handle (presumably to the graphics state)
		else if GString
		    carry set
		    zero set
		    ds - GState segment
		    di - graphics segment handle
		else Path
		    carry set
		    zero clear
		    ds - GState segment
		    di - graphics segment handle

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	12/88		Initial version
		jim	2/90		Changed to support new type gstring
					handles
		Don	6/91		Changed to support Paths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockDI_DS_checkFar	proc	far
		call	LockDI_DS_check
		ret
LockDI_DS_checkFar	endp

LockDI_DS_check	proc	near
		uses	ax
		.enter
		; check for valid gstate handle
		;
EC <		call	AssertInterruptsEnabled				>
EC <		call	ECCheckGStateHandle				>

		LoadVarSeg	ds, ax
		FastLock1	ds, di, ax, LDI_1, LDI_2
		mov	ds, ax				; ds = graphics state
		mov	ax, ds:[GS_gstring]		; see if gstring
		or	ax, ax				; check for valid han
		lahf
		xor	ah, mask CPU_ZERO		; invert the zero flag
		sahf
		jnz	exit				; carry is clear if

		; If we are a GString, see if we are a Path
		; or truly a GString

		mov	di, ds:[GS_gstring]		; GString handle => DI
		test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
		stc					; we have a GString
exit:
		.leave
		ret

		; special case of lock macro

		FastLock2	ds, di, ax, LDI_1, LDI_2
LockDI_DS_check	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateOpts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update optimization flags in the GState

CALLED BY:	INTERNAL

PASS: 		ds - GState

RETURN: 	NEVER -- jumps to UnlockDI_popDS

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateOpts	proc	far
	call	UpdateOptsAndReturn
	REAL_FALL_THRU	UnlockDI_popDS
UpdateOpts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockDI_popDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Unlock the block that ds is pointing to (assumed to be a 
		gstate), pop DS and return to caller.  Used by attributes 
		routines to do generic exiting.

		CAUTION: This routine must only be jumped to

CALLED BY:	INTERNAL

PASS: 		ds - gstate segment
		on stack - ds to pop, FAR return address

RETURN: 	NEVER RETURNS

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	12/88		Initial version
		Jim	2/90		Changed to support new type gstring
					handles

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnlockDI_popDS	proc	far
EC <		call	AssertInterruptsEnabled				>
		pushf
		push	ax

		mov	di, ds:[GS_header].LMBH_handle	; get real gstate han
		LoadVarSeg	ds, ax
		FastUnLock	ds, di, ax

		pop	ax
		popf

		FALL_THRU_POP	ds
		retf
UnlockDI_popDS	endp
