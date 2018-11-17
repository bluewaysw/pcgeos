COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		graphics kernel
FILE:		Graphics/grRegion

AUTHOR:		Jim DeFrisco, Doug Fults

ROUTINES:
    Name		Description
    ----		-----------
    GrSetClipRect	Set the application clip region for a gstate.
    GrChunkRegOp	Performs boolean operations using chunk-handles to
			regions.
    GrPtrRegOp		Performs boolean operations using pointers to regions.
    DoStosW		Checks to see if the stosw will fit in the destination
    			region, sets overflow flag if it won't.
    DoPtrAndOrOp	Does general line by line walking for GrPtrRegOp. Used
			for AND & OR operations.
    ElimRedundant	Removes redundant line data for DoPtrAndOrOp.
    GrANDLine		Perform AND operation on a single line.
    GrORLine		Perform OR operation on a single line.
    GrNOTPtrReg		Perform NOT operation for GrPtrRegOp.
    GrMoveReg		Move a region by a given offset.
    GrTestPointInReg	Test to see if a point is in a region.
    GrTestRectInReg	Tests to see if a rectangle is outside,
			partially inside, or completely inside a
			region.
    GrGetPtrRegBounds	Return the bounding rectangle of a region.
    GrDrawRegion	Draw a region at a given position.
    GrDrawRegionAtCP	Draw a region at the pen position.
    DoRegion		Call the video driver to draw a region.

These routines are included only in the error checking version of the kernel:
    CheckRegDef		Make sure that a region is valid.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/88		initial version
	doug	9/27/88		added GrPtrRegOp
	doug	10/28/88	Completed initial region manipulation routines,
				as required by windowing system.  Added new
				routines  GrChunkRegOp & GrTestPointInReg
	adam	1/19/88		Added GrTestRectInReg
	john	 8-Aug-89	Cleaned up, documented, and understood.

DESCRIPTION:
	This file contains region related routines.  Regions are defined as
	follows:

		    X1 X2
		    |  |
		Y1 -		Y1, $		- Blank to here
		    XXXX
		    XXXX
		Y2 -XXXX	Y2, X1, X2, $	- X1, X2 through here
				$		- End of region definition

	$Id: graphicsRegion.asm,v 1.1 97/04/05 01:13:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; This structure is used by several of the low level region routines.
;
RegionVars	struct
    RV_reg1Ptr		word	(?)
    RV_reg2Ptr		word	(?)
    RV_reg3Ptr		word	(?)
    RV_regOpFlags	word	(?)
    RV_firstLinePtr	word	(?)
    RV_prevReg3Ptr	word	(?)
    RV_reg3PtrLimit	word	(?)
RegionVars	ends
;
; Set up aliases for local scratch variables, for GrANDReg() & GrORReg()
;
RegionLocals	equ	<ss:[bp - size RegionVars]>

;
; Local structure used to save bytes & time
;
SCR_inline	struct
    SCR_path	word				; GState offset OR'ed with mask
    SCR_flags	word				; WinGrFlags & WinGrRegFlags
    SCR_opcode	GStringElement			; Opcode to write for GString
SCR_inline	end

CLIP_RECT_COORD_MASK	= 0x8000		; mask OR'ed with SCR_path to
						; indicate window coordinates


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Setting a Clip Rectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	If you are wondering what type of clip rectangle to use, please
	read the following.  The graph below describes how a document
	coordinate (on provided by an application in its document) turns
	into a device coordinate (such as one on a video monitor or
	printout).

	Document Coords		Window Coords		Device Coords
		|		   |     |                    |
		A-------GState ----B     B-------Window-------C

	To provide clipping, there are several functions that are available,
	to be used byt both applications and the system software. They
	occur in pairs: GrSetClipRect() & GrSetClipPath(), and
	GrSetWinClipRect() & GrSetWinClipPath(). The ClipRect() routines
	can be used for optimized clipping, when it is known that a
	rectangle is the desired geometry. The Rect & Path routines may
	be used together, and will be combined together appropriately
	at drawing time.

	The first pair of routines specify the clipping in terms of
	document coordinates, which will be transformed by both the
	GState & Window transformation matrices. A transformation can
	be any combination of translating, scaling, & rotating.

	The second pair of routines specify the clipping in terms of
	window coordinates, and will only be transformed by the Window's
	transformation matrix.

	In general, applications will want to be using GrSetClipRect() &
	GrSetClipPath()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows user to restrict clipping region further by specifying
		a rectangle which will be ANDed w/the final clip region
		generated by the windowing system, in order to determine where
		graphics can be drawn.

CALLED BY:	GLOBAL

PASS:		DI	= GState handle
		SI	= PathCombineType
				PCT_NULL
				PCT_REPLACE
				PCT_UNION
				PCT_INTERSECTION
		AX	= Left
		BX	= Top
		CX	= Right
		DX	= Bottom

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	The rectangle should be defined in the document coordinate space
	of the window associated with the GState. The region will be
	transformed appropriately when used by the graphics & windowing
	systems.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version
	Doug	10/28/88	Change register passing for more flexibility
	John	 9-Aug-89	One more time...To match WinOpen and WinMove
				for parameters. Redocumented, etc.
	Gene	4/90		Changed for transforming regions.
	Don	7/ 8/91		Changed to use Paths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetClipRect	proc	far
	call	SetClipRectCommon		; do the real work

	; SCR_inline structure
	;
.inst	word	(offset GS_clipPath) or 0	; SCR_path
.inst	word	not (mask WGF_MASK_VALID or \
		     mask WGRF_PATH_VALID shl 8) ; SCR_flags
.inst	byte	GR_SET_CLIP_RECT		; SCR_opcode
	.unreached
GrSetClipRect	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetWinClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows user to restrict clipping region further by specifying
		a rectangle which will be ANDed w/the final clip region
		generated by the windowing system, in order to determine where
		graphics can be drawn.

CALLED BY:	GLOBAL

PASS:		DI	= GState handle
		SI	= PathCombineType
				PCT_NULL
				PCT_REPLACE
				PCT_UNION
				PCT_INTERSECTION
		AX	= Left
		BX	= Top
		CX	= Right
		DX	= Bottom

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/31/90		Initial version
	don	7/ 8/91		Changed to use Paths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetWinClipRect	proc	far
	call	SetClipRectCommon		; do the real work

	; SCR_inline structure
	;
.inst	word	offset GS_winClipPath or CLIP_RECT_COORD_MASK	; SCR_path
.inst	word	not (mask WGF_MASK_VALID or \
		     mask WGRF_WIN_PATH_VALID shl 8) ; SCR_flags
.inst	byte	GR_SET_WIN_CLIP_RECT		; SCR_opcode
	.unreached
GrSetWinClipRect	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClipRectCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the real work of setting a clip rectangle.

CALLED BY:	GrSetClipRect(), GrSetWinClipRect()

PASS:		DI	= GState handle
		SI	= PathCombineType
		AX	= Left
		BX	= Top
		CX	= Right
		DX	= Bottom
		inline.SCR
		inline.SCR_path		= offset of region to create
		inline.SCR_flags	= WinGrFlags & WinGrRegFlags to preserve
		inline.SCR_opcode	= GString opcode

RETURN:		Doesn't return

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Create the clipPath
		If possible, also create rectangular region
		Clear proper Window flags
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine does weird stuff, like inline arguments, so
	don't call it unless you know what you're doing...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/14/90		Initial version
	don	7/ 8/91		Changed to deal with Paths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCR_CALLER	equ ss:[bp+2]			; where to find inline params

SetClipRectCommon	proc	near
	push	bp				; save BP
	mov	bp, sp
	mov	bp, SCR_CALLER			; ptr to inline params => BP

	; Some set-up work
	;
	call	PushAll				; save everything
EC <	cmp	si, PathCombineType					>
EC <	ERROR_A	GRAPHICS_PATH_ILLEGAL_COMBINE_PARAMETER			>
	call	LockDI_DS_check			; lock GState, check for gstring
	ja	normal				; if not GString, jump

	; We're writing to a GString. Do the dirty work in another code seg
	;
	segmov	es, cs
	call	LibGSSetClipRect		; write GString opcode & data
	
	; Set-up for call to add rectangle to a Path
normal:
	push	bp				; save pointer to SCR_inline
	mov	bp, cs:[bp].SCR_path		; path offset => BP
	push	bp				;  ...and save for after
	call	AddRectangleToPath
	pop	di				; offset to clipPath => DI
	andnf	di, not (CLIP_RECT_COORD_MASK)	; clear window mask bit
	mov	ds:[di], ax			; store new ClipPath handle
	pop	bp				; restore local variable pointer
	mov	cx, cs:[bp].SCR_flags		; window flags => CX

	; Clean up and exit
	;
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	call	IntExitGState			; biff flags, unlock GState
	call	PopAll				; restore all registers
	pop	bp				; restore BP
	inc	sp
	inc	sp				; biff local caller
	retf					; return to fall caller
SetClipRectCommon	endp


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrChunkRegOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		ax	- Operator

		ds	- segment of locked LMEM managed block X
		si	- chunk handle for X:reg1

		es	- segment of locked LMEM managed block Y
		bx	- chunk handle for Y:reg2
		di	- chunk handle for Y:reg3

		NOTE:  ds may = es for this routine.  If they are, then both
		ds & es are updated to be identical if the lock must be resized
		by LMem.  NOTE also that the block pointed to by es MUST have
		a lock count of 1 (only one person locking block).  This is
		so that LMem can unlock & resize the block.

RETURN:		es	- new segment for block containing chunk
		ds	- updated as well, if ds=es at entry.
		reg1 OP reg2 -> reg3,

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/28/88	Initial version
	Chris	1/16/89		Removed check for errors from LMem

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

NOT_EXTRA	equ	14	; # extra bytes for NOT
AND_OR_EXTRA	equ	14	; # of bytes extra to add into buffer for
				;	outputed region, just to insure no
				;	overflow. (is size of rect reg)


GrChunkRegOp	proc	far
	mov	cx, ds			;
	mov	dx, es			;
	cmp	cx, dx			; operation in same segment?
	jne	GCRO_10			;
	ornf	ax, mask ROF_ES_DS_SAME	; set flag for later, to show in same
					; segment
GCRO_10:				;
					; start w/cx is size of reg1
	call	ChunkSizeHandleDS_SI_CX
EC<	tst	cx							>
EC<	jnz	10$							>
EC<badRegion:								>
EC<	ERROR	GRAPHICS_BAD_REGION_DEF					>
EC<10$:									>

	test	al, mask ROF_AND_OP	; AND operation?
	jnz	GCRO_AND		; if so, do AND
	test	al, mask ROF_OR_OP	; OR operation?
	jnz	GCRO_OR			; jump if OR
				; GUESS FOR NOT SIZE
	mov	dx, NOT_EXTRA		; extra amount for NOT
	mov	bx, di			; change bx to be a valid handle (even
					; if not used, so we don't index to
					; weird places in memory)

					; cx = 2 * cx + EXTRA
	add	dx, cx			; add size into extra amount
	add	cx, dx			; add size into extra amount
	jmp	GCRO_50

GCRO_OR:			; GUESS FOR OR SIZE
	call	ChunkSizeHandleES_BX_DX			; dx <- size
	add	cx, dx			; add to prev reg size
EC<	tst	dx						>
EC<	jz	badRegion					>
	jmp	short GCRO_30
GCRO_AND:			; GUESS FOR AND SIZE
	call	ChunkSizeHandleES_BX_DX			; dx <- size
EC<	tst	dx						>
EC<	jz	badRegion					>
	cmp	cx, dx			; use larger of two sizes
	ja	GCRO_30			;
	xchg	cx, dx			;
GCRO_30:				;
	mov	dx, AND_OR_EXTRA	;
					; cx = 1.5 * cx + EXTRA
	add	dx, cx			; add size into extra amount
	shr	cx, 1			; calc 1/2 more of size
	add	cx, dx			; add together, for final guess in cx
					; LOOP here if we have to redo op.
GCRO_50:				;
	xchg	ax, dx
	call	ChunkSizeHandleES_DI_AX
	xchg	ax, dx			; dx <- size
	cmp	cx, dx			; if already big enough, don't resize
	jbe	GCRO_60
	call	reAlloc_ESDI
GCRO_60:				;
	push	ax			; save operators
	push	bx			; save handles
	push	si			;
	push	di			;
					; Convert handles to pointers
	mov	si, ds:[si]		;
	mov	bx, es:[bx]		;
	mov	di, es:[di]		;
					; es:di points to reg 3
	call	GrPtrRegOp		; Perform the operation
					; cx = size of resultant region
	pop	di			; Restore handles, operator
	pop	si			;
	pop	bx			;
	pop	ax			;
	jc	GCRO_50			; if overflow, redo w/new size

	call	reAlloc_ESDI
	ret				;

;---

reAlloc_ESDI:
	push	ax			; save flags
	segxchg	ds, es			; swap ds & es
	mov	ax, di			;
	call	LMemReAlloc		; resize chunk storage for reg 3
	segxchg	ds, es			; swap ds & es
	pop	ax			; restore flags
	test	ax, mask ROF_ES_DS_SAME	; Check for segments the same.
	jz	99$			; skip if not
	segmov	ds, es			; else is flag that ds=es, adjust both
					;	segment registers
99$:
	retn

GrChunkRegOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrPtrRegOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Region 3 <- Region 1 OP Region 2

CALLED BY:	GLOBAL

PASS: 		ax	- flags for operation (only one set, please:)
			  mask ROF_AND_OP
			  mask ROF_OR_OP
			  mask ROF_NOT_OP

		cx	- size allocated for region 3

		      Suggested buffer sizes for operations (if operations
		      returns overflow, you'll need to reallocate buffer &
		      try it again.  Routine will return new size estimate,
		      increasing each time by 25% beyond new estimate)

		      NOT:  2.0 * (size of reg1) + 14
		      AND:  1.5 * (size of larger of (reg1, reg2)) + 14
		      OR:   1.5 * (size of reg1 + size of reg2) + 14

		      Also note:  The NOT operation is predictable in terms
		      of buffer space required, & will never require more
		      than the above amount (never return overflow).
		      In order to keep it fast, it does NOT check for
		      overflow, hence, you MUST pass a buffer the size of
		      the above estimate.  Thank you.  The AND & OR routines
		      will function correctly for any size buffer, returning
		      overflow if it occurs.

		ds:si	- far pointer to region 1
		es:bx	- far pointer to region 2
		es:di	- far pointer to region 3

RETURN: 	carry	- set if buffer overflow (bad region created)
		cx	- size of region created, or "estimate" of buffer
			  size required to try operation again
		di	- points past end of new region created

DESTROYED:	ax, bx, dx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/27/88		Initial version
	Doug	10/28/88	Regions test for overflow of buffer, return
				new "estimate" for next iteration.
	Don	6/27/91		Cleaned up code & comments for readability

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrPtrRegOp	proc	far

if	FULL_EXECUTE_IN_PLACE
EC<	push	bx				; save trashed offset	>
EC<	mov	bx, ds				; bx:si <- pointer	>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx				; restore offset	>
EC<	test	ax, mask ROF_NOT_OP					>
EC<	jnz	continue						>
EC<	push	bx, si				; save trash registers	>
EC<	movdw	bxsi, esbx			; bx:si <- pointer	>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si				; restore registers	>
EC<	continue:							>
endif

	; Perform some initialization work
	;
	push	bp				; save frame pointer
	mov	bp, sp				; set up frame
	sub	sp, size RegionVars 		; need local space
	push	cx				; save original space estimate
	mov	RegionLocals.RV_regOpFlags, ax	; initialize this record
	mov	RegionLocals.RV_firstLinePtr,di	; store first line ptr
	andnf	cx, 0fffeh			; Only even numbers, please
	add	cx, di				; calc end ptr of Region 3
	mov	RegionLocals.RV_reg3PtrLimit,cx ; ...and store it away
	push	di				; Save start of output region

	; Check out both Region #1 & #2 (if necessary)
	;
EC<	push	cx,dx				; save some registers	>
EC<	mov	cx, ds							>
EC<	mov	dx, si							>
EC<	call	CheckRegDef			; check Region #1	>
EC<	test	ax, mask ROF_NOT_OP		; if performing NOT	>
EC<	jnz	checkDone			; ...no Region #2	>
EC<	mov	cx, es							>
EC<	mov	dx, bx							>
EC<	call	CheckRegDef			; check Region #2	>
EC<checkDone:
EC<	pop	cx,dx				; clean up registers	>

	; Now let's do the real work (AND & OR)
	;
	test	ax, mask ROF_NOT_OP		; if performing NOT
	jnz	notOp				; ...then go do the work
	mov	RegionLocals.RV_prevReg3Ptr, 0ffffh ; null previous line pointer
	call	DoPtrAndOrOp			; do AND /OR operation
	mov	ax, di				; end of resulting Region => AX
	sub	ax, RegionLocals.RV_firstLinePtr ; Size of output region => AX
	cmp	ax, (7*2)-2			; minimum definition is 7 words
	jae	notNullReg			; if >=7 words, branch
	mov	di, RegionLocals.RV_firstLinePtr
	jmp	endReg

	; Perform the NOT operation
	;
notOp:
	call	GrNOTPtrReg
	jmp	finished

	; Not a NULL region. Clean up last line in Region, if necessary
	;
notNullReg:
	test	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW
	jnz	endReg				; if bit set, overflow exists
	cmp	{word} es:[di-6], EOREGREC	; see if last line is NULL
	jne	endReg				; branch if not
	sub	di, 4				; else back up & overwrite it
endReg:
	mov	ax, EOREGREC
	call	DoStosW				; store final $ for region

	; We're finished. Check for overflow
	;
finished:
	mov	cx, di				; get ptr past reg into cx
	pop	ax				; start of output region => AX
	sub	cx, ax				; subtract off start position
	pop	si				; get original estimate in si
	test	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW
	jnz	overflow			; if bit set, we have overflow
EC<	push	cx, dx							>
EC<	mov	cx, es				; check resulting Region>
EC<	mov	dx, ax							>
EC<	call	CheckRegDef			; check Region #3	>
EC<	pop	cx, dx							>
	clc					; clear carry for success
	mov	sp, bp				; restore stack pointer
	pop	bp				; restore frame pointer
	ret

	; Deal with overflow. Return new estimate of size
	;
overflow:
	mov	ax, si				; calc 1.25 * original estimate
	shr	ax, 1
	shr	ax, 1
	add	ax, si				; 1.25 * original size => AX
	cmp	cx, ax				; check new size vs size needed
	jge	done				; if greater, return size in CX
	mov	cx, ax				; else return original estimate
done:
	stc					; carry indicates overflow
	mov	sp, bp				; restore stack pointer
	pop	bp				; restore frame pointer
	ret
GrPtrRegOp	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoStosw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store one word in a Region, checking for overflow

CALLED BY:	INTERNAL
	
PASS:		ES:DI	= Destination
		SS:BP	= RegionLocals
		AX	= Data

RETURN:		ES:DI	= One word past destination (always)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/27/91		Created procedure header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoStosW		proc	near
	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	overflow
	stosw
	ret
overflow:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di
	inc	di				; move up ptr
	ret
DoStosW		endp




COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPtrAndOrOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	GrPtrRegOp

PASS:
	ds:si	- far pointer to region 1
	es:bx	- far pointer to region 2
	es:di	- far pointer to region 3

	bp	- set  pointing to local variables:
	    RegionLocals.RV_reg1Ptr	- point to start of current reg 1 line
	    RegionLocals.RV_reg2Ptr	- "" reg 2 line
	    RegionLocals.RV_reg3Ptr	- "" reg 3 line
	    RegionLocals.RV_regOpFlags	- same as ax value passed to GrPtrRegOp
					  except that mask ROF_OVERFLOW is ored
					  in if region overflows buffer
	    RegionLocals.RV_firstLinePtr- points to start of region 3
	    RegionLocals.RV_prevReg3Ptr	- points to start of previous reg 3
					  line (where we back up to if
					  eliminating redundant data)
	    RegionLocals.RV_reg3PtrLimit- pointer past buffer we can write to.
					  Used to detect overflow

RETURN:	di		- points past end of created reg3 def
	RegionLocals.RV_regOpFlags	- mask ROF_OVERFLOW ored in if overflow

		Core of AND/OR operation performed.

DESTROYED:

PSEUDO CODE/STRATEGY:
		The code here does the
		overall region operation, calling GrORLine & GrANDLine to
		perform the operation on each line.  EliminateRedundant is
		called after each line to combine the two last lines produced
		if they are identical in terms of ON/OFF point data.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

OV_Handle_50:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di				; move up ptr
	inc	di
	jmp	OV_Resume_50


DoPtrAndOrOp	proc	near
	lodsw			; Get first reg 1 Y value
	mov	cx, es:[bx] + 0 ; get first reg 2 Y value
	inc	bx
	inc	bx

	cmp	ax, EOREGREC	; End of region 1?
	je	DPAOO_EndReg1	;	jmp if so
	cmp	cx, EOREGREC	; end of region 2?
	je	DPAOO_EndReg2	;	jmp if so

DPAOO_Loop:
	push	ax
	push	cx
					; AX = y value for reg 1 line
					; CX = y value for reg 2 line
				; COMBINE LINES, USING SPECIFIED OPERATION
				; GENERATE LINE SET
	mov	RegionLocals.RV_reg1Ptr, si	; store RegionLocals.RV_reg1Ptr to allow back up later
	mov	RegionLocals.RV_reg2Ptr, bx	; store RegionLocals.RV_reg2Ptr to allow back up

	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	OV_Handle_50
	cmp	ax, cx		; See which Y def extends shorter
	jl	DPAOO_20	; branch if reg2 extends farther
	xchg	ax, cx		; put smaller Y value in AX
DPAOO_20:
				; AX = smaller Y end of reg1 & reg2
				;	lines,
	stosw			; store smaller Y as end value for line
	mov	RegionLocals.RV_reg3Ptr, di	; store RegionLocals.RV_reg3Ptr
						; to allow back up later
OV_Resume_50 label near
			; SEE IF DOING AND OR OR
	test	RegionLocals.RV_regOpFlags, mask ROF_AND_OP
	jnz	DPAOO_30		; 	branch if so
			; DO OR OPERATION
				; OR lines from reg1 & reg2 into reg3
	call	GrORLine	; OR lines together
	jmp	short DPAOO_40	; Branch to handle after line op

DPAOO_30:			; DO AND OPERATION
	call	GrANDLine	; Perform AND operation on the line
DPAOO_40:
				; ELIMINATE REDUNDANT LINE DATA
	call	ElimRedundant	; Eliminate redundant lines, set
				;	flag for last line null
				; ADJUST PTR, LOOP FOR NEXT POINT SET
	pop	cx		;	Get last Y values used
	pop	ax


	cmp	ax, cx		; Which ptr should move up?
	je	DPAOO_MoveBoth	;	if = line values, both move up
	jg	DPAOO_MoveReg2	; branch if reg1 is defined further

	lodsw			; Fetch new reg1
	mov	bx, RegionLocals.RV_reg2Ptr	; back up reg2
	mov	cx, es:[bx] - 2	; fetch old reg 2 Y value
	jmp	short DPAOO_CheckEnd	; Check for end
DPAOO_MoveReg2:
	mov	si, RegionLocals.RV_reg1Ptr	; back up reg1
	mov	ax, ds:[si] - 2 ; fetch old reg1 Y
	mov	cx, es:[bx]	; Fetch new reg 2
	inc	bx
	inc	bx
	jmp	short DPAOO_CheckEnd	; Check for end
DPAOO_MoveBoth:
	lodsw			; Get next reg 1 Y value
	mov	cx, es:[bx]	; get next reg 2 Y value
	inc	bx
	inc	bx
DPAOO_CheckEnd:
				; NOW, CHECK FOR END OF REGIONS
	cmp	ax, EOREGREC	; End of region 1?
	je	DPAOO_EndReg1	;	jmp if so
	cmp	cx, EOREGREC	; end of region 2?
	jne	DPAOO_Loop; & loop


				; FINISH UP WHEN REGION 2 ENDS
DPAOO_EndReg2:
	test	RegionLocals.RV_regOpFlags, mask ROF_AND_OP
	jnz	DPAOO_Done21	; IF doing AND, all done
				; Else OR in rest of region 1
DPAOO_Reg1Lp:
	dec	bx		; back up reg 2 ptr to point at NULL
	dec	bx
	call	DoStosW		; store Y as end value for line
			; store RegionLocals.RV_reg3Ptr to allow back up later
	mov	RegionLocals.RV_reg3Ptr, di
	call	GrORLine	; OR lines together
				; ELIMINATE REDUNDANT LINE DATA IN OUTPUT
	call	ElimRedundant	; Eliminate redundant lines, set
				;	flag for last line null

	lodsw			; Get Next Y value from reg 1
	cmp	ax, EOREGREC	; end of region 1?
	jne	DPAOO_Reg1Lp	; loop if not
DPAOO_Done21:
	ret


				; FINISH UP WHEN REGION 1 ENDS

DPAOO_EndReg1:
	test	RegionLocals.RV_regOpFlags, mask ROF_AND_OP
	jnz	DPAOO_Done12	; IF doing AND, all done
				; Else OR in rest of region 2
	cmp	cx, EOREGREC	; see if both done at same time
	je	DPAOO_Done12	; if so, out of here.
DPAOO_Reg2Lp:
	dec	si		; back up reg 1 ptr to point at NULL
	dec	si
	mov	ax, cx		; get Y value
	call	DoStosW		; store Y as end value for line
		; store RegionLocals.RV_reg3Ptr to allow back up later
	mov	RegionLocals.RV_reg3Ptr, di
	call	GrORLine	; OR lines together
				; ELIMINATE REDUNDANT LINE DATA
	call	ElimRedundant	; Eliminate redundant lines, set
				;	flag for last line null
	mov	cx, es:[bx] + 0	; Get Next Y value from reg 2
	inc	bx
	inc	bx
	cmp	cx, EOREGREC	; end of region 2?
	jne	DPAOO_Reg2Lp	; loop if not
DPAOO_Done12:
	ret
DoPtrAndOrOp	endp




COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ElimRedunant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Eliminates current output line of region operation if it is
		identical to the previous line produced.

CALLED BY:	DoPtrAndOrOp

PASS:		Context of DoPtrAndOrOp

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

ElimRedundant	proc	near
					; Store end of previous line
	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	OV_Handle_60
	mov	ax, EOREGREC
	stosw
	test	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; Overflow?
	jnz	ELR_90		; if so, can't do elimination of
				;	redundant lines from now on
				; Eliminates redundant lines.
				; Updates RegionLocals.RV_prevReg3Ptr for next
				; pass.
	push	bx
	push	si
	push	ds
	mov	bx, di		; save current output pointer here
		; get pointer to line before this one
	mov	si, RegionLocals.RV_prevReg3Ptr
	cmp	si, 0ffffh	; if null, nothing redundant
	je	ELR_70
		; get pointer to line we just did
	mov	di, RegionLocals.RV_reg3Ptr
	segmov	ds, es
ELR_10:
	cmpsw			; see if lines match so far
	jne	ELR_70		; if they aren't identical, OK, done
				; see if end of region found
	cmp	ds:[si-2], EOREGREC
	jne	ELR_10		; if not, loop for more
				; here if redundant line

	mov	si, RegionLocals.RV_prevReg3Ptr	; get ptr to previous line
	mov	bx, RegionLocals.RV_reg3Ptr	; get ptr to line we just did
	mov	ax, es:[bx] - 2	; get Y value of line we just did
	mov	es:[si] - 2, ax	; store over Y value of previous line
	dec	bx		; backup to erase line we just did
	dec	bx
	jmp	short ELR_80
ELR_70:
	mov	ax, RegionLocals.RV_reg3Ptr
		; store new previous RegionLocals.RV_reg3Ptr
	mov	RegionLocals.RV_prevReg3Ptr, ax
ELR_80:
	mov	di, bx		; restore di pointer
	pop	ds
	pop	si
	pop	bx
ELR_90:
	ret

OV_Handle_60:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di				; move up ptr
	inc	di
	ret
ElimRedundant	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrANDLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	DoPtrAndOrOp

PASS:
		ds:si	- far pointer to start of line past Y in region 1
		es:bx	- far pointer to start of line past Y in region 2
		es:di	- far pointer to start of line past Y in region 3

RETURN:
		ax	- EOREGREC
		ds:si	- far pointer to next line start of region 1
		es:bx	- far pointer to next line start of region 2
		es:di	- far pointer past last added word to region 3

		RegionLocals.RV_regOpFlags	- mask ROF_OVERFLOW ored in if overflow

		NOTE that if the combination of the line results in no
		intersection, then nothing will be stored in the destination
		region.  The calling routine should determine whether or
		not to keep the line of the region.  If the line is kept,
		the calling routine should do a "stosw" to store an
		EOREGREC to region 3, finishing the line.

DESTROYED:
		ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/27/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrANDLine	proc	near

GAL_loop:
				; SEE IF AT END OF LINE
	lodsw			; fetch next reg 1 word, inc pointer
	mov	cx, es:[bx + 0]	; fetch next reg 2 word
	cmp	ax, EOREGREC	; at end?
	je	GAL_Reg1Done	; if so, AND done, eat up rest of line
	cmp	cx, EOREGREC	; at end?
	je	GAL_Reg2Done	; if so, AND done, eat up rest of line
				; GENERATE NEXT POINT SET
	cmp	ax, cx		; use larger of two start values
	jl	GAL_10
	xchg	ax, cx		; put larger into CX
GAL_10:
				; CX is possible ON point
	lodsw			; get OFF point from reg 1
	mov	dx, ax		; DX = OFF point of reg1
	mov	ax, es:[bx + 2]	; AX = OFF point of reg 2
	cmp	ax, dx		; see which OFF point is larger
	jg	GAL_20		; branch if reg2 OFF point is larger
	je	GAL_18		; branch if extents are the same
	xchg	ax, dx		; put lesser into DX
	sub	si, 4		; backup reg1 pointer
GAL_18:
	add	bx, 4		; move up reg 2 ptr
GAL_20:
	cmp	cx, dx		; see if ON point <= OFF point
	jg	GAL_loop	; skip if not

	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	OV_Handle_10
	mov	ax, cx		; Store next ON & OFF points in dest reg
	stosw
OV_Resume_10:
	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	OV_Handle_12
	mov	ax, dx
	stosw
				; LOOP FOR NEXT POINT SET
	jmp	short GAL_loop

OV_Handle_10:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di				; move up ptr
	inc	di
	jmp	short OV_Resume_10
OV_Handle_12:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di				; move up ptr
	inc	di
	jmp	short GAL_loop



				; EAT UP REST OF ONE LINE
GAL_Reg1Done:				; Eat up rest of reg2 line
	xchg	bx, di		; 4 need line pointed to by es:di
	mov	cx, 0ffffh	; 4 no limit
	mov	ax, EOREGREC	; 4
	repnz	scasw		; 19 keep looking at words until
				;	EOREGREC found -
				;	will point to next word
	xchg	bx, di		; 4 restore di, bx points past EOREGREC
				; = 19 * n + 16
	ret

GAL_Reg2Done:				; Eat up rest of reg1 line
	inc	bx		; Point past end of reg2
	inc	bx

;GAL_80:
;		lodsw			; 16 get next reg1 word
;		cmp	ax, EOREGREC	; 4
;		jne	GAL_80		; 16
;					; = 36 * n
; Faster {
	mov	ax, ds		; 2
	mov	dx, es		; 2
	mov	es, ax		; 2
	mov	ds, dx		; 2
	xchg	si, di		; 4
	mov	cx, 0ffffh	; 4 no limit
	mov	ax, EOREGREC	; 4
	repnz	scasw		; 19 keep looking at words until
				;	EOREGREC found -
				;	will point to next word
	xchg	si, di		; 4
	mov	ax, ds		; 2
	mov	dx, es		; 2
	mov	es, ax		; 2
	mov	ds, dx		; 2
				; = 19 * n + 32
; }


	ret
GrANDLine	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrORLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	DoPtrAndOrOp

PASS:
		ds:si	- far pointer to start of line past Y in region 1
		es:bx	- far pointer to start of line past Y in region 2
		es:di	- far pointer to start of line past Y in region 3

RETURN:
		ds:si	- far pointer to next line start of region 1
		es:bx	- far pointer to next line start of region 2
		es:di	- far pointer to next line start of regoin 3

		RegionLocals.RV_regOpFlags	- mask ROF_OVERFLOW ored in if overflow

		NOTE that if the combination of the line results in no
		intersection, then nothing will be stored in the destination
		region.  The calling routine should determine whether or
		not to keep the line of the region.  If the line is kept,
		the calling routine should do a "stosw" to store an
		EOREGREC to region 3, finishing the line.


DESTROYED:
		ax, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/27/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OV_Handle_15:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di				; move up ptr
	inc	di
	jmp	short GOL_17

OV_Handle_20:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di				; move up ptr
	inc	di
	jmp	GOL_loop

GrORLine	proc	near
	mov	dx, EOREGREC	; FLAG for first point pass
GOL_loop label	near
				; SEE IF AT END OF LINE
	lodsw			; fetch next reg 1 word, inc pointer
	mov	cx, es:[bx + 0]	; fetch next reg 2 word
	cmp	ax, EOREGREC	; at end?
	je	GOL_Reg1Done	; if so, copy rest of reg2 line
	cmp	cx, EOREGREC	; at end?
	je	GOL_Reg2Done	; if so, copy rest of reg1 line
			; GENERATE NEXT POINT SET
	cmp	ax, cx		; compare two start values
	jl	GOL_10
	xchg	ax, cx		; put smaller in AX, larger into CX
GOL_10:
	cmp	dx, EOREGREC	; see if first point (DX will not
				;	be EOREGREC on any subsequent
				;	passes)
	je	GOL_16		; if so, use point
	dec	ax
	cmp	es:[di-2], ax	; see if previous point overlaps this
				;	one (or touches it)
	jl	GOL_15		; branch if not
	dec	di		; else back up to update it
	dec	di
	jmp	short GOL_17
GOL_15:
	inc	ax		; correct value
GOL_16:
	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	OV_Handle_15
	stosw			; store ON point (smaller of two)
GOL_17 	label near
				; Keep CX, larger point, to see if
				;	overlap
	lodsw			; get OFF point from reg 1
	mov	dx, ax		; DX = OFF point of reg1
	mov	ax, es:[bx + 2]	; AX = OFF point of reg 2
				; TEST EXTENT of reg 1 & 2
	cmp	ax, dx		; see which OFF point is larger
	jg	GOL_20		; branch if reg2 OFF point is larger
	je	GOL_18		; if same extent, move up both
	xchg	ax, dx		; put lesser into DX
	sub	si, 4		; Move back reg1 pointer
GOL_18:
	add	bx, 4		; Move up reg2 pointer
GOL_20:
	dec	cx		; consider touching to be overlap
	cmp	cx, dx		; see if region ON/OFF segments overlap
	jle	GOL_30		; skip if overlap
	mov	ax, dx		; if no overlap, use smaller value
GOL_30:
	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	OV_Handle_20
	stosw			; store OFF point
			; LOOP FOR NEXT POINT SET
	jmp	short GOL_loop
			; COPY REST OF ONE LINE
GOL_Reg1Done:				; Copy rest of reg2 line

	cmp	dx, EOREGREC	; see if we should check for overlap
	je	GOL_88		; jump if not
	mov	ax, es:[bx]	; COPY line from reg2 to reg3
	inc	bx
	inc	bx
	cmp	ax, EOREGREC
	je	GOL_Done
	dec	ax		; see if point overlaps, or even
				;	adjoins this one
	cmp	es:[di-2], ax
	jl	GOL_82		; branch if not
	dec	di		; else back up to update it
	dec	di
	jmp	short GOL_88
GOL_82:
	inc	ax		; correct point value
	jmp	short GOL_89

GOL_88:
	mov	ax, es:[bx]	; COPY line from reg2 to reg3
	inc	bx
	inc	bx
	cmp	ax, EOREGREC
	je	GOL_Done
GOL_89:
	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	OV_Handle_30
	stosw
	jmp	short GOL_88

GOL_Reg2Done:				; Copy rest of reg1 line
	inc	bx		; point past end of reg2
	inc	bx
	cmp	dx, EOREGREC	; see if we should check for overlap
	je	GOL_94		; jump if not
	cmp	ax, EOREGREC	; is this the end of the region line?
	je	GOL_Done
	dec	ax
	cmp	es:[di-2], ax	; see if previous point overlaps this
				;	one
	jl	GOL_92		; branch if not
	dec	di		; else back up to update it
	dec	di
	jmp	short GOL_97
GOL_92:
	inc	ax
GOL_94:
	cmp	ax, EOREGREC	; is this the end of the region line?
	je	GOL_Done

	cmp	di, RegionLocals.RV_reg3PtrLimit ; will it fit?
	jae	OV_Handle_40
	stosw
GOL_97:
	lodsw			; get next reg1 word
	jmp	short GOL_94	; loop to copy rest of line
GOL_Done:
	ret

OV_Handle_30:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di				; move up ptr
	inc	di
	jmp	short GOL_88

OV_Handle_40:
	ornf	RegionLocals.RV_regOpFlags, mask ROF_OVERFLOW	; mark overflow
	inc	di				; move up ptr
	inc	di
	jmp	GOL_97

GrORLine	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrNOTPtrReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Region 3 <- NOT (Region 1)

CALLED BY:	GrPtrRegOp

PASS:
		ds:si	- far pointer to region 1
		es:di	- far pointer to region 3

RETURN:		di	- pointing past last word written in reg3
		Stores in region 3 the following image:

		Region 3 = (NOT (Region 1)) AND
				(mask of entire graphics area)

		The entire graphics area mask goes from
			Y = c000h through 3fffh, &
			X = c000h through 3fffh.


DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/27/88		Initial version
	Jim	2/6/90		Completely re-written. Fixed so that it is 
				reversible. In the 1st version, two NOTs in a
				row created a BAD_REGION_DEF. (This operation
				is done in BltCommon...)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrNOTPtrReg	proc	near
		uses	bp
		.enter

		; init last X/Y value to below lowest, then check 1st line

		mov	dx, MIN_COORD-2	; init last Y
		mov	bp, EOREGREC	; we use this a lot, so keep it around

		; for first line, either we want to add a prefix to the region
		; so that it starts at the beginning of the coordinate space,
		; or skip over the first record because it already does.

		lodsw			; get first Y value
		cmp	ax, MIN_COORD-1	; check for big region
		je	cutInitialRec	;  yes, don't need first part
		inc	dx		; update last Y
		mov	cx, ax		; save first Y value
		mov	ax, dx		; and use for first record
		stosw
		mov	ax, bp		; store an end of record marker
		stosw
		mov	ax, cx		; restore Y value
		jmp	checkForEnd	; and join in the usual fun
cutInitialRec:
		mov	dx, ax		; update last y value
		inc	si		; bump over the inevitable EOREGREC
		inc	si

		; Region scan line loop
nextRecord:
		lodsw			; get next Y value
checkForEnd:
		cmp	ax, bp		; check for NULL region
		je	writeTrailer	;  yes, all finished
		cmp	ax, MAX_COORD-1	; check need to truncate old region..
		je	checkCutEnd	;  maybe, check some more

		; On/Off point loop
startNewRec:
		stosw			; write y value
		mov	dx, ax		; store as last Y
		clr	cx		; written no x coords yet
		lodsw			; get first x value
		cmp	ax, MIN_COORD	; if at minimum, skip it
		jne	linePrefix	;  no, store prefix first
nextOnOff:
		lodsw			; get next x coord
checkOnOff:
		cmp	ax, bp		; check for end of line on input
		je	finishRecord
		cmp	ax, MAX_COORD-1	; if at maximum, skip it
		je	nextOnOff
		dec	ax		; assume it's an off point
		test	cl, 1		; 
		jnz	storeOnOff	;  yes, store the value
		inc	ax		; needed to increment
		inc	ax
storeOnOff:
		stosw			; store as next on/off point
		inc	cx		; bump on/off flag
		jmp	nextOnOff	; go get the next one

		; all done, check for last record then leave
writeTrailer:
		mov	ax, bp		; assume we're done
		cmp	dx, MAX_COORD-1	; see if already full
		jne	bigSuffix	;  no, write out the final record
writeFinalEOR:
		stosw
		.leave
		ret

;-------------------------------------------------------------------------

		; not a full region to start, fill region to end of coord space
bigSuffix:
		mov	ax, MAX_COORD-1	;  no, write out the final record
		stosw
		mov	ax, MIN_COORD	; first ON point in full region
		stosw
		mov	ax, MAX_COORD-1	; final off point in full region
		stosw
		mov	ax, bp		; write end of record marker
		stosw
		jmp	writeFinalEOR	; all done

		; started with a full region, so check if we need to kill the
		; last part
checkCutEnd:
		cmp	ds:[si], MIN_COORD ; if last record is full, eliminate
		jne	startNewRec	;      no, act normal
		cmp	ds:[si+2], MAX_COORD-1 
		jne	startNewRec
		mov	ax, bp		; was big, write final EOREGREC
		jmp	writeFinalEOR

		; finished with this record.  If not enough x values written,
		; write another, then write the EOR
finishRecord:
		test	cl, 1		; check if we need to write both
		jz	writeEOLN	;  maybe, check some more
		mov	ax, MAX_COORD-1	; 
		stosw
		mov	ax, bp
writeEOLN:
		stosw			; write out the EOREGREC
		jmp	nextRecord	; start on another one

		; first on point in source is not at MIN_COORD, so stuff one 
		; of those first
linePrefix:
		mov	cx, ax		; save x value
		mov	ax, MIN_COORD	; store an initial far left side
		stosw
		mov	ax, cx		; restore previous value
		mov	cx, 1		; init to "stored on point" (it's odd)
		jmp	checkOnOff
GrNOTPtrReg	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMoveReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves a region by a given amount in X & Y

CALLED BY:	GLOBAL

PASS:		ds:si	- far ptr to region definition
		cx	- x amount to shift (signed)
		dx	- y amount to shift (signed)

RETURN:		region shifted (same storage space required)
		ds:si	- far ptr just past region definition

DESTROYED:
		ax

PSEUDO CODE/STRATEGY:
		For each byte of region definition [
			if y value, add in Y offset;
			if x value, add in X offset;
		]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	9/22/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrMoveReg	proc	far
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx							>
EC<	mov	bx, ds							>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx							>
endif
EC<	call	ECCheckBounds						>

yLoop:				; START OF A NEW SCAN LINE RECORD
	lodsw			; get next y value
	cmp	ax, EOREGREC	; see if at end of entire region
	je	done		;  yes, exit
	add	ax, dx		; shift in Y
checkCoord:
	cmp	ax, MAX_COORD	; make sure it's still in bounds
	jge	coordHi		;  nope, bound on high side
	cmp	ax, MIN_COORD	; check low end too
	jl	coordLo		;  no, clip to bounds
storeCoord:
	mov	ds:[si-2], ax	; store back the modified word
				; WORK ON ON-OFF POINTS
	lodsw			; get next x coord
	cmp	ax, EOREGREC	; see if end of line
	je	yLoop		;  yes, on to next scan line
	add	ax, cx		; shift in X
	jmp	checkCoord	; do coordinate check before storing
done:
	ret

	; coordinate overflowed at hi end, clip to MAX_COORD
coordHi:
	mov	ax, MAX_COORD-1
	jmp	storeCoord

	; coordinate overflowed at low end, clip to MIN_COORD
coordLo:
	mov	ax, MIN_COORD
	jmp	storeCoord
GrMoveReg	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTestPointInReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if a point is inside of a region or not

CALLED BY:	EXTERNAL

PASS:		cx	- x position
		dx	- y position
		ds:si	- pointer to region

RETURN:		carry set if point in region
		If in region, then returns rectangle inside region that the
		point was in:
		ax		- top bounding Y value
		bx		- bottom bottom X value
		ds:[si-4]	- left bounding X value
		ds:[si-2]	- right bounding X value

DESTROYED:

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/25/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

GrTestPointInReg	proc	far
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx							>
EC<	mov	bx, ds							>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx							>
endif
EC<	call	ECCheckBounds						>

	mov	bx, 0c000h-1		; start with top bound as negative edge
GTPIRLineStart:
	lodsw				; Get Y value
	cmp	ax, EOREGREC		; if end of region, not in reg
	je	GTPIR_NotInReg

	cmp	dx, ax			; does line include Y pos?
	jle	GTPIRFound		; If so, line found
	mov_tr	bx, ax			; else update next possible Y top bound
GTPIR15:				; SEARCH for next line
	lodsw				; Get next word
	cmp	ax, EOREGREC
	jne	GTPIR15			; loop till found
	jmp	short GTPIRLineStart	; Branch to handle next line
GTPIRFound:
	push	ax			; save bottom Y bound on stack

GTPIR_NextLine:
				; SI points to clip line data
	lodsw			; Get X ON value
	cmp	ax, EOREGREC
	je	GTPIR_NotInLine		; if NULL line, not in reg
	cmp	cx, ax			; if before ON point, not in reg
	jl	GTPIR_NotInLine
	lodsw			; Get X OFF value
	cmp	cx, ax
	jg	GTPIR_NextLine		; if > OFF point, keep going

	mov_tr	ax, bx			; get top Y bound -1
	inc	ax			; change to be bound
	pop	bx			; return bottom Y bound in bx
	stc				; else if <= OFF, IN region, done
	ret

GTPIR_NotInLine:
	pop	bx			; fix stack
GTPIR_NotInReg:
	clc
	ret
GrTestPointInReg	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GrTestRectInReg

DESCRIPTION:	Find a block of memory of the given size and type.

CALLED BY:	GLOBAL

PASS:
	ax - left
	bx - top
	cx - right
	dx - bottom
	ds:si - region
	carry - clear if ds:si is the start of a region, set if ds:si is
		a value from W_clipPtr

RETURN:
	al - TestRectReturnType - TRRT_OUT if not in region
				 TRRT_PARTIAL if partially in region
				 TRRT_IN if entirely in region

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Jim	2/90		Optimized, added more documentation

------------------------------------------------------------------------------@

GrTestRectInReg	proc	far
	uses	si, di, bp
	.enter
if	FULL_EXECUTE_IN_PLACE
EC<	pushf							>
EC<	push	bx						>
EC<	mov	bx, ds						>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	pop	bx						>
EC<	popf							>
endif

	mov	di,ax				;di - left

	; bp represents the y value in the region definition that is >= top
	; of rect.  

	mov	bp,ds:[W_clipRect.R_bottom]	;assume from W_clipPtr
	jc	eitherLoop
	jmp	fullEntry

	; this section of code charges through the region until it finds
	; the part that overlaps the desired rectangle

skipXLoop:
	inc	si			; bump past next x value
	inc	si
checkNullLine:
	lodsw				; get 1st value after y value
	cmp	ax, EOREGREC		; check for NULL line in region
	jne	skipXLoop		;  no, skip over more x values
fullEntry:
	lodsw				; get Y value
	cmp	ax, EOREGREC		; check for NULL region
	je	returnOut		;  yes, all done
	cmp	bx,ax			; check if top of rect overlaps yet
	jg	checkNullLine		;  no, skip this line
	mov	bp,ax			;  yes, set new >=top

	; rectangle could be either totally visible, partially visible or
	; totally obscured

eitherLoop:
	lodsw				;firstON
	cmp	ax, EOREGREC		;NULL ?
	jz	outEOLN			;if so then done with check
	cmp	ax,cx			;after left ?
	jg	outEOLN			;if so then entirely clipped
	cmp	ax,di			;does region start in middle of rect
	jg	returnPart		;if so then complex
	lodsw				;lastON
	cmp	ax,di			;is this area to the left of the rect ?
	jl	eitherLoop		;
	cmp	ax,cx			;does region end in middle of rect ?
	jl	returnPart		;if so then complex
	jmp	inEOLN			;
	;
	; part of the rectangle is visible
	;
inLoop:
	lodsw				;firstON
	cmp	ax, EOREGREC		;NULL ?
	jz	returnPart		;if so then done with check
	cmp	ax,cx			;after left ?
	jg	returnPart		;if so then entirely clipped
	cmp	ax,di			;does region start in middle of rect
	jg	returnPart		;if so then complex
	lodsw				;lastON
	cmp	ax,di			;is this area to the left of the rect ?
	jl	inLoop		;
	cmp	ax,cx			;does region end in middle of rect ?
	jl	returnPart		;if so then complex
	;
	; rect is visible in this scan area -- loop to see if rest is visible
	;
inEOLN:
	cmp	dx,bp			;check for bottom above region bottom.
	jg	keepChecking		;

	; rectangle in region, done

	mov	al,TRRT_IN
	jmp	done

loop1:
	lodsw
keepChecking:
	cmp	ax, EOREGREC
	jne	loop1
	lodsw				;load next line
	mov	bp,ax			;
	cmp	ax, EOREGREC		;
	jne	inLoop			;if still in rectangle then loop

returnPart:
	mov	al,TRRT_PARTIAL
	jmp	done

returnOut:
	mov	al, TRRT_OUT
done:
	.leave
	ret

	;
	; part of the rectangle is obscured
	;
outLoop:
	lodsw				;firstON
	cmp	ax, EOREGREC		;NULL ?
	jz	outEOLN			;if so then done with check
	cmp	ax,cx			;after left ?
	jg	outEOLN			;if so then entirely clipped
	cmp	ax,di			;does region start in middle of char
	jg	returnPart		;if so then complex
	lodsw				;lastON
	cmp	ax,di			;is this area to the left of the char ?
	jl	outLoop			;
	jmp	returnPart		;rectangle is visible in this scan
					;line, must use complex routine
outEOLN:
	cmp	dx,bp			;
	jg	keepChecking2		;
	jmp	returnOut

loop2:
	lodsw
keepChecking2:
	cmp	ax,EOREGREC
	jne	loop2
	lodsw				;load next line
	mov	bp,ax			;
	cmp	ax, EOREGREC		;
	jnz	outLoop			;if still in rectangle then loop
	jmp	returnOut

GrTestRectInReg	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetPtrRegBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the coords of the region's bounding rectangle

CALLED BY:	INTERNAL

PASS:		ds:si	- far pointer to region definition

RETURN:		ax - left bound
		bx - top bound
		cx - right bound
		dx - bottom bound
		ds:si point past the last word of the region definition

DESTROYED:	ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
		if (1st byte == EOREGREC)
		   return (top/bottom/left/right = EOREGREC);
		else
		   top = 1st byte+1;
		   init bottom = 1st byte;
		   init	left = max x coordinate;
		   init right = min x coordinate;
		   while (not at end of region definition)
		      left = min (left, onXPos);
		      right = max (right, offXPos);
		      bump to next on/off pair;
		      if (end of scan line record)
			 bottom = (nextScanLineValue - 1);

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/88...		Initial version
	Doug	9/26/88		Fixed near-infinite loop caused when processing
	Doug	9/27/88		Modified for new region def format

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetPtrRegBounds	proc	far
if	FULL_EXECUTE_IN_PLACE
EC<	push	bx							>
EC<	mov	bx, ds							>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx							>
endif
EC<	call	ECCheckBounds						>

	lodsw				; get first word of region definition
	cmp	ax, EOREGREC		; see if NULL region
	jne	GPRB10			;  no, continue
	mov	dx, ax			;  yes, set all bounds to EOREGREC
	mov	bx, ax
	mov	cx, ax
	jmp	short GPRBend
GPRB10:				; PROCESS 1st word of first line
	inc	ax			; first line w/data
	push	ax			; save top coordinate
	mov	dx, ax			; init bottom = top
	mov	bx, 03fffh		; init left = max x pos
	mov	cx, 0c000h		; init right = min x pos
GPRB20:
				; GET & PROCESS non-first word of a line
	lodsw				; get next word
	cmp	ax, EOREGREC		; see if at end of scan line record
	jne	GPRB40			;  no, check for new left value
				; GET & PROCESS first word of a line
	lodsw				;  yes, get next scan line value
	cmp	ax, EOREGREC		; see if at end of region defintion
	je	GPRB90			;  yes, quit
				; PROCESS NEW Y VALUE
	mov	dx, ax			; no, bump bottom to next scan line
	jmp	short GPRB20		; branch to fetch & handle non-first
					;	of line value
GPRB40:
				; PROCESS ON VALUE
	cmp	ax, bx			; calc min(left,on point)
	jge	GPRB50			;  = left, continue
	mov	bx, ax			;  = on point, store it
GPRB50:
				; GET & PROCESS OFF VALUE
	lodsw				; get "off" point
	cmp	ax, cx			; calc max(right,off point)
	jle	GPRB20			;  = right, continue
	mov	cx, ax			;  = off point, store it
	jmp	GPRB20			; and continue with loop

GPRB90:
	pop	ax			; restore top position
GPRBend:
	xchg	ax, bx			; switch to have top in ax, left in bx
	ret
GrGetPtrRegBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a region

CALLED BY:	GLOBAL

PASS:
		ax	- x position
		bx	- y position
		cx, dx 	- parameters to region (if needed, PARAM_2 and
			  PARAM_3, respectively)
		ds:si	- segment and offset to region
		di	- handle of graphics state (locked)

RETURN:		ax,bx,cx,dx - unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call GSStore to try to store command to memory
		if we're writing to the screen:
			translate coords to screen coords;
			call rectangle function in driver;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version
	Jim	2/90		Changed to use common code in GrDrawRegionAtCP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawRegion	proc	far
if	FULL_EXECUTE_IN_PLACE
EC <	call	ECCheckBounds			>
endif	
	call	EnterGraphics
	call	SetDocPenPos			; set new pen position
	jmp	drawRegCommon
GrDrawRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRegionAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a region at the current pen position

CALLED BY:	GLOBAL

PASS:
		ax, bx, cx, dx 	- paramters to region (if needed)
		ds:si	- segment and offset to region
		di	- handle of graphics state (locked)

RETURN:		ax,bx,cx,dx - unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		call GSStore to try to store command to memory
		if we're writing to the screen:
			translate coords to screen coords;
			call rectangle function in driver;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/88...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawRegionAtCP proc	far
if	FULL_EXECUTE_IN_PLACE
EC <	call	ECCheckBounds			>
endif	
	call	EnterGraphics

	; common entry point for GrDrawRegion

drawRegCommon	label	near
	jc	quickExit

	call	TrivialReject

	mov	dx, ss:[bp].EG_ds		;pass region in dx:cx
	mov	cx, si

	add	bp, EG_ax			;pass address of AX on stack
	mov	si, GS_areaAttr			;use area attributes
	call	DoRegion

	jmp	ExitGraphics

		; gstring handling code.  We'll have to support this soon...
quickExit:
	jmp	ExitGraphicsGseg

GrDrawRegionAtCP endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoRegion

DESCRIPTION:	Call the video driver to draw a rectangle after translating
		to driver coordinates

CALLED BY:	INTERNAL
		GrDrawRegion

PASS:
	ax - x position
	bx - y position
	dx:cx - seg and offset to region
	si - offset to CommonAttr
	ss:bp - address of AX, BX, CX, DX
	ds - graphics state structure
	es - Window structure

RETURN:
	es - Window structure (may have moved)

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/88		Initial version
	jad	3/89		changed to use CurTransMatrix
				also added check for complex coord trans

-------------------------------------------------------------------------------@


DoRegion	proc	near

	; transform the coordinates

	call	GetDevPenPos			; device coordinates => (AX, BX)
	jc	done				; don't draw if overflow

	mov	di,DR_VID_REGION
	call	es:[W_driverStrategy]		; make call to driver
done:
	ret

DoRegion	endp


if	ERROR_CHECK
include	system.def
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckRegDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine for Error Checking version of kernel.  Tests to
		make sure that regions are valid.

CALLED BY:	GLOBAL

PASS:		cx:dx	- pointer to region

RETURN:		returns if region OK, else:
		ERROR	GRAPHICS_BAD_REGION_DEF	if error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Ensures the following:
		1) Y line values must be in the range c000h to 3fffh
		2) Y line values increase, and never repeat, as the definition
			is traversed.
		3) X point values must be in the range c000h to 3fffh
		4) Point values always come in pairs of ON, OFF.
		5) Within a point pair, ON must be <= OFF value
		6) The ON value of a pair must be > previous pair's OFF value
			+ 1
		7) There is an EOREGREC at the end of each line, and at the
			ending of the region definition

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8//88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK

CheckRegDef	proc	far
	uses	ax, bx
	.enter
	call	SysGetECLevel
	test	ax, mask ECF_GRAPHICS
	jz	CRD_90

	push	ds
	push	si
	push	cx
	push	dx
	call	CheckRegPtr	; check the pointer out
	mov	ds, cx
	mov	si, dx
	lodsw
	cmp	ax, EOREGREC	; if NULL region, done
	je	done
	mov	cx, ax
;	call	CheckRegCoord	; Make sure in graphics space
	lodsw
	cmp	ax, EOREGREC
	jne	badRegion	; Error w/bad region
lineStart:
	lodsw			; fetch first word
	cmp	ax, EOREGREC	; if NULL region, done
	je	done
	cmp	ax, cx		; make sure larger than last Y
	jle	badRegion	; if not, bad region
	mov	cx, ax		; store for next pass
;	call	CheckRegCoord	; Make sure in graphics space
	mov	dx, MIN_COORD-1	; init last "OFF point"
restOfLine:
	lodsw			; fetch ON point
	cmp	ax, EOREGREC	; if NULL region, done with line>
	je	lineStart	; branch to do next line
;	call	CheckRegCoord	; make sure in bounds
	cmp	ax, dx		; make sure gt last off point+1
	jle	badRegion	;
	mov	dx, ax		; save here
	lodsw			; fetch OFF point
;	call	CheckRegCoord	; make sure in bounds
	cmp	ax, dx		; Make sure gt or = e on point
	jl	badRegion	; show error
	mov	dx, ax		; store here
	inc	dx		; actually, store off + 1
	jmp	restOfLine
done:
	pop	dx
	pop	cx
	pop	si
	pop	ds
CRD_90:
	.leave
	ret

badRegion	label	near
	ERROR	GRAPHICS_BAD_REGION_DEF
CheckRegDef	endp


;CheckRegCoord	proc	near
;	Commented out 10/20/92 cbh.  All values are legal as they can be
;	parameterized.
;	cmp	ax, MIN_COORD-1	; see if below min
;	jl	badRegion
;	cmp	ax, MAX_COORD	; see if above max
;	jg	badRegion
;	ret
;
;CheckRegCoord	endp



;		cx = segment, dx = offset
CheckRegPtr	proc	near	; DS must not be 0 or -1
	push	ax,bx, es
	cmp	cx, 0
	ERROR_E	GRAPHICS_BAD_REG_PTR
	cmp	cx, 0ffffh
	ERROR_E	GRAPHICS_BAD_REG_PTR
	mov	es, cx
	mov	bx,es:[LMBH_handle]
	call	ECCheckMemHandleFar
	pop	ax, bx, es
	ret
CheckRegPtr	endp

endif

