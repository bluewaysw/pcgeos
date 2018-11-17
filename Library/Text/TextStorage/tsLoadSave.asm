COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		TextStorage
FILE:		tsLoadSave.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:

	$Id: tsLoadSave.asm,v 1.1 97/04/07 11:22:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextStorageCode	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextSetVMFile -- MSG_VIS_TEXT_SET_VM_FILE for VisTextClass

DESCRIPTION:	Change the file handle with which the text object is associated

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - VMFileHandle

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/10/91		Initial version

------------------------------------------------------------------------------@
VisTextSetVMFile	proc	far	; MSG_VIS_TEXT_SET_VM_FILE
	class	VisTextClass

	mov	ds:[di].VTI_vmFile, cx
	ret

VisTextSetVMFile	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextLoadFromDBItem -- MSG_VIS_TEXT_LOAD_FROM_DB_ITEM
							for VisTextClass

DESCRIPTION:	Load a text object from a DB item

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx.dx - DBItem to load from
	bp - VMFileHandle to use (or 0 to use VTI_vmFile)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/10/91		Initial version

------------------------------------------------------------------------------@
VisTextLoadFromDBItem	proc	far
					; MSG_VIS_TEXT_LOAD_FROM_DB_ITEM

	mov_tr	ax, bp			;ax = file
	clr	bp			;no styles
	call	LoadDBCommon
	ret

VisTextLoadFromDBItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextLoadFromDBItemFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the data from a locked DB item

CALLED BY:	GLOBAL
PASS:		cx:dx - data to load
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextLoadFromDBItemFormat	proc	far
					;MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_FORMAT
	class	VisTextClass
	.enter
EC <	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE		>
EC <	ERROR_NZ	VIS_TEXT_REQUIRES_SMALL_TEXT_OBJECT		>

;	Delete the old data in the text object

	movdw	esdi, cxdx
	mov	ax, es:[di]
	call	DeleteRunsForLoadFromDBItem

	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock

	clr	bp
	call	LoadDataFromDBItem

	; nuke any cached information

	mov	ax, TEMP_VIS_TEXT_CACHED_RUN_INFO
	call	ObjVarDeleteData

	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	ObjCallInstanceNoLock

	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification

	.leave
	ret
VisTextLoadFromDBItemFormat	endp

;---



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteRunsForLoadFromDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the runs for "LoadFromDBItem"

CALLED BY:	GLOBAL
PASS:		ax - VisTextSaveDBFlags
		*ds:si - VisText object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteRunsForLoadFromDBItem	proc	near	uses	bx, cx, dx, bp, di
	class	VisTextClass
	.enter
	mov	cl, offset VTSDBF_CHAR_ATTR
	mov	bx, offset VTI_charAttrRuns
	call	DeleteRuns1N
	mov	cl, offset VTSDBF_PARA_ATTR
	mov	bx, offset VTI_paraAttrRuns
	call	DeleteRuns1N
	mov	cl, offset VTSDBF_TYPE
	mov	bx, OFFSET_FOR_TYPE_RUNS
	call	DeleteRuns1N
	mov	cl, offset VTSDBF_GRAPHIC
	mov	bx, OFFSET_FOR_GRAPHIC_RUNS
	clr	dl				;dl <- start run
	call	DeleteRunsCommon
	call	DeleteGraphicsForLoad
	.leave
	ret
DeleteRunsForLoadFromDBItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadDataFromDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the data from the passed locked DB item

CALLED BY:	GLOBAL
PASS:		*ds:si - text object
		es:di - data
		bp - StyleSheetParams structure (or 0 for none)
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		If a StyleSheetParams structure is passed in it means that
		we are moving a text object from one attribute space into
		another attribute space (we abritrarily say that without
		style information we will not move between attribute spaces,
		not a elegant solution).

		Thus is bp!=0 we copy elements one by one, which we should
		probably do for non style sheet cases also, but we do not.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadDataFromDBItem	proc	near
	class	VisTextClass
	.enter

	mov	ax, es:[di]			;ax = flags
	add	di, size word			;es:di = next data

	; load the text (if any)

	test	ax, mask VTSDBF_TEXT
	jz	noLoadText
	push	ax
	mov	ax, VTST_SINGLE_CHUNK
	mov	bx, offset VTI_text
	clc					;normal instance data
	call	LoadDataFromDB
	pop	ax
noLoadText:

	; load the character attribute information (if any)

	push	ax
	and	ax, mask VTSDBF_CHAR_ATTR
	mov	cl, offset VTSDBF_CHAR_ATTR
	shr	ax, cl
	jz	noLoadCharAttr
	mov	bx, offset VTI_charAttrRuns
	call	loadRun
noLoadCharAttr:
	pop	ax

	; load the paragraph attribute information (if any)

	push	ax
	and	ax, mask VTSDBF_PARA_ATTR
	mov	cl, offset VTSDBF_PARA_ATTR
	shr	ax, cl
	jz	noLoadParaAttr
	mov	bx, offset VTI_paraAttrRuns
	call	loadRun
noLoadParaAttr:
	pop	ax

	; load the type information (if any)

	push	ax
	and	ax, mask VTSDBF_TYPE
	mov	cl, offset VTSDBF_TYPE
	shr	ax, cl
	jz	noLoadType
	mov	bx, ATTR_VIS_TEXT_TYPE_RUNS
	stc					;variable instance data
	call	LoadDataFromDB
noLoadType:
	pop	ax

	; load the graphic information (if any)

	push	ax
	and	ax, mask VTSDBF_GRAPHIC
	mov	cl, offset VTSDBF_GRAPHIC
	shr	ax, cl
	jz	noLoadGraphic
	mov	bx, ATTR_VIS_TEXT_GRAPHIC_RUNS

	tst_clc	bp			;clear carry to indicate normal instance
					;data
	jnz	5$
	stc					;variable instance data
	call	LoadDataFromDB
	jmp	6$
5$:
	call	LoadGraphicRunFromDB
6$:

noLoadGraphic:
	pop	ax

	; load the style information (if any)

	push	ax
	test	ax, mask VTSDBF_STYLE
	jz	noLoadStyles
	mov	bx, ATTR_VIS_TEXT_STYLE_ARRAY
	mov	al, VTST_SINGLE_CHUNK
	stc					;variable instance data
	call	LoadDataFromDB
	call	StyleSheetIncNotifyCounter	;force style sheet update
noLoadStyles:
	pop	ax

	; load the region information (if any)

if 0
	push	ax
	test	ax, mask VTSDBF_REGION
	jz	noLoadRegions
	mov	bx, ATTR_VIS_TEXT_REGION_ARRAY
	mov	al, VTST_SINGLE_CHUNK
	stc					;variable instance data
	call	LoadDataFromDB
	call	StyleSheetIncNotifyCounter	;force style sheet update
noLoadRegions:
	pop	ax
endif

	; load the name information (if any)

	push	ax
	test	ax, mask VTSDBF_NAME
	jz	noLoadNames
	mov	bx, ATTR_VIS_TEXT_NAME_ARRAY
	mov	al, VTST_SINGLE_CHUNK
	stc					;variable instance data
	call	LoadDataFromDB
	call	StyleSheetIncNotifyCounter	;force style sheet update
noLoadNames:
	pop	ax
	.leave
	ret
;---

loadRun:
	tst_clc	bp			;clear carry to indicate normal instance
					;data
	jnz	10$
	call	LoadDataFromDB
	retn
10$:
	call	LoadStyledRunFromDB
	retn

LoadDataFromDBItem	endp

	; ax = file
	; bp = StyleSheetParams structure (or 0 for none)

LoadDBCommon	proc	near
	class	VisTextClass

EC <	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE		>
EC <	ERROR_NZ	VIS_TEXT_REQUIRES_SMALL_TEXT_OBJECT		>

	tst	cx
	LONG jz	doDelete

	; if a VM file passed then set it

	mov_tr	bx, ax
	tst	bx
	jnz	gotFile
	call	T_GetVMFile			;bx = file
gotFile:

	;
	; Delete any old runs first.  We do this because otherwise
	; deleting the text below will cause the reference counts
	; on the elements to be decremented.  When they reach zero,
	; of course, they will be deleted.
	; However, we only do this if we are loading new runs without
	; new elements (VTST_RUNS_ONLY)
	;
	call	LockCXDXToESDI
	mov	ax, es:[di]			;ax <- flags
	call	DBUnlock

	call	DeleteRunsForLoadFromDBItem

doDelete:
	; suspend the object and clear the current text

	push	cx, dx, bp
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock
	pop	cx, dx, bp

	; lock the DB item (if any)

	jcxz	afterLoad
	call	LockCXDXToESDI			;es:di = data
	call	LoadDataFromDBItem

	call	DBUnlock

afterLoad:

	; nuke any cached information

	mov	ax, TEMP_VIS_TEXT_CACHED_RUN_INFO
	call	ObjVarDeleteData

	mov	ax, MSG_VIS_TEXT_RECALC_AND_DRAW
	call	ObjCallInstanceNoLock

	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	call	TA_SendNotification

	ret

				   
LoadDBCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTestSaveType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get and test the VisTextSaveType from VisTextSaveDBFlags

CALLED BY:	DeleteRunsCommon(), DeleteGraphicsForLoad()
		ax - VisTextSaveDBFlags for item we're loading
		cl - offset of saved info for runs in VisTextSaveDBFlags
RETURN:		z flag - set (je) if VTST_RUNS_ONLY
		ax - VisTextSaveType
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTestSaveType		proc	near
	.enter

	shr	ax, cl
	andnf	ax, VisTextSaveType-1		;ax <- VisTextSaveType
	cmp	ax, VTST_RUNS_ONLY		;runs only?

	.leave
	ret
GetTestSaveType		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteRunsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete runs from text object before a load

CALLED BY:	LoadDBCommon()
PASS:		*ds:si - text object
		ax - VisTextSaveDBFlags for item we're loading
		cl - offset of saved info for runs in VisTextSaveDBFlags
		bx - offset of run array
		dl - start run (0 or 1)

RETURN:		ds - fixed up
DESTROYED:	bx, dx

PSEUDO CODE/STRATEGY:
	normally delete all but first and last runs (start = 1)
	if graphics, delete all but the last run (start = 0)
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteRuns1N		proc	near
	mov	dl, 1
	FALL_THRU	DeleteRunsCommon
DeleteRuns1N		endp

DeleteRunsCommon	proc	near
	uses	ax, cx, si
	.enter

	;
	; See if runs of this type exist in the item we're about to load
	;
	call	GetTestSaveType
	jne	skipDelete			;branch if not runs only
	;
	; Get the VM file to use
	;
	push	ds:LMBH_handle			;save for fixup
	push	bx
	call	T_GetVMFile
	mov_tr	ax, bx				;ax <- VM file handle
	pop	bx				;bx <- offset of run array
	push	ax				;save VM file handle
	;
	; Lock the run array
	;
	call	FarRunArrayLock			;ds:si <- first element
	;
	; Skip to the start run to delete
	;
	cmp	dl, 1				;start at one or zero?
	jne	gotStart			;branch if start at 0
	call	FarRunArrayNext
gotStart:
	pop	bx				;bx <- VM file handle
	;
	; Delete runs until there is only the last one left
	;
deleteLoop:
	cmp	ds:[si].TRAE_position.WAAH_low, TEXT_ADDRESS_PAST_END_LOW
	jne	notLast
	cmp	ds:[si].TRAE_position.WAAH_high, TEXT_ADDRESS_PAST_END_HIGH
	je	doneDelete			;branch if last element
notLast:
	push	bx				;save VM file handle
	call	FarRunArrayDeleteNoElement	;don't delete elements
	pop	bx				;bx <- VM file handle
	jmp	deleteLoop

doneDelete:
	;
	; Unlock the run array
	;
	call	FarRunArrayUnlock
	;
	; Fixup ds if necessary
	;
	pop	bx				;bx <- handle of text object
	call	MemDerefDS			;ds <- (new) ds
skipDelete:

	.leave
	ret
DeleteRunsCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteGraphicsForLoad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete graphics from the text as necessary before a load

CALLED BY:	LoadDBCommon()
PASS:		*ds:si - text object
		ax - VisTextSaveDBFlags for item we're loading
		cl - offset of saved info for runs in VisTextSaveDBFlags
RETURN:		ds - fixed up
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteGraphicsForLoad		proc	near
	class	VisTextClass
	uses	es
	.enter

	;
	; See if graphic runs exist in the item we're about to load
	;
	call	GetTestSaveType
	jne	skipDelete			;branch if not runs only
	;
	; See if any text chunk exists
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VTI_text		;di <- chunk of text
	tst	di				;any text?
	jz	skipDelete			;branch if no text
	;
	; Get a pointer to the text
	;
	mov	di, ds:[di]
	segmov	es, ds				;es:di <- ptr to text
	ChunkSizePtr	ds, di, cx		;cx <- size of text
DBCS <	shr	cx, 1				;cx <- # of chars (DBCS) >
	;
	; Scan the text for graphics chars and replace them
	;
	mov	ax, C_GRAPHIC			;ax <- char to scan for
scanForGraphics:
	jcxz	skipDelete			;branch if done
	LocalFindChar				;scan for graphics
	jne	scanForGraphics
SBCS <	mov	{byte}es:[di][-1], C_PERIOD	;>
DBCS <	mov	{word}es:[di][-1], C_PERIOD	;>
	jmp	scanForGraphics

skipDelete:

	.leave
	ret
DeleteGraphicsForLoad		endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadDataFromDB

DESCRIPTION:	Load a chunk from the DB file.  This also marks the object
		as "clean".

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	carry - set if variable instance data
	bx - if normal instance data:
		offset (in instance data) of chunk
	     if variable instance data:
		vardata key
	es:di - data to read from
	al - VisTextSaveType

RETURN:
	es:di - pointing after data read in

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/91		Initial version

------------------------------------------------------------------------------@
LoadDataFromDB	proc	near	uses si, bp, cx
	class	VisTextClass
	.enter

	call	GetChunkForLoadSave		;si = chunk

	; if reading in run or run&element then get current element array

	cmp	al, VTST_SINGLE_CHUNK
	jz	noElements
	mov	bp, ds:[si]
	mov	cx, ds:[bp].TRAH_elementVMBlock
	mov	bp, ds:[bp].TRAH_elementArray
noElements:

	; read the data

	call	LoadChunkFromDB

	; if single chunk then done

	cmp	al, VTST_SINGLE_CHUNK
	jz	done

	; if reading runs only then stuff element chunk & vm block

	mov	si, ds:[si]
	mov	ds:[si].TRAH_elementVMBlock, cx
	mov	ds:[si].TRAH_elementArray, bp
	cmp	al, VTST_RUNS_ONLY
	jz	done

	mov	si, bp
	call	LoadChunkFromDB

done:

	.leave
	ret

LoadDataFromDB	endp

;---

GetChunkForLoadSave	proc	near
	jnc	notVardata
	push	ax, bx, cx
	mov_tr	ax, bx
	call	ObjVarFindData
	mov	si, ds:[bx]
	pop	ax, bx, cx
	jmp	common

notVardata:

	; get the chunk handle

	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	si, ds:[si][bx]			;si = chunk to read into

common:
	ret

GetChunkForLoadSave	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadChunkFromDB

DESCRIPTION:	Load a chunk from a DB file

CALLED BY:	INTERNAL

PASS:
	*ds:si - chunk to read into
	es:di - data to read from

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
	Tony	12/11/91		Initial version

------------------------------------------------------------------------------@
LoadChunkFromDB	proc	near	uses ax, cx, si
	.enter

	; the first word is a count -- read it in

	mov	cx, es:[di]			;cx = size
	add	di, 2

	mov	ax, si				;ax = chunk
	call	LMemReAlloc

	mov	si, ds:[si]			;ds:si = dest
	segxchg	ds, es
	xchg	si, di
	rep movsb
	segxchg	ds, es
	mov	di, si

	.leave
	ret

LoadChunkFromDB	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextLoadFromDBItemWithStyles --
		MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_WITH_STYLES for VisTextClass

DESCRIPTION:	Load a text object from a DB item

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - VisTextLoadFromDBWithStylesParams

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/20/92		Initial version

------------------------------------------------------------------------------@
VisTextLoadFromDBItemWithStyles	proc	far
				; MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_WITH_STYLES
	class	VisTextClass

if FULL_EXECUTE_IN_PLACE
	;
	; Validate that the params structure is *not* in a movable code segment
	;
EC<	push	bx, si						>
EC<	movdw	bxsi, ss:[bp].VTLFDBWSP_params			>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	pop	bx, si						>
endif

	movdw	cxdx, ss:[bp].VTLFDBWSP_dbItem
	mov	ax, ss:[bp].VTLFDBWSP_file
	mov	bp, ss:[bp].VTLFDBWSP_params.offset

	; somewhat of a hack here -- if this object does not have any runs
	; to save then just use the normal save

	test	ds:[di].VTI_storageFlags, mask VTSF_MULTIPLE_CHAR_ATTRS or \
					  mask VTSF_MULTIPLE_PARA_ATTRS
	jnz	hasRuns
	mov_tr	bp, ax					;bp = VM file
	mov	ax, MSG_VIS_TEXT_LOAD_FROM_DB_ITEM
	GOTO	ObjCallInstanceNoLock
hasRuns:

	; initialize the StyleSheetParams structure

	stc					;preserve xfer stuff
	call	LoadSSParams

	; if the graphic elements have not yet been relocated then do
	; that now

	push	ax, cx, dx, si, bp, ds
	mov_tr	bx, ax				;bx = vm file
	clr	ax
	xchg	ax, ss:[bp].VTSSSP_treeBlock
	tst	ax
	jz	afterRelocation
	mov	dx, ss:[bp].VTSSSP_graphicsElements
	mov	di, ss:[bp].VTSSSP_graphicTreeOffset
	call	VMLock				;lock tree block
	mov	ds, ax
	mov	ax, ds:[di].high
	call	VMUnlock
	tst	ax
	jz	afterRelocation
	call	VMLock				;lock graphics tree block
	mov	es, ax
	mov	di, es:[VMCT_offset]		;es:di = block data

	mov_tr	ax, dx
	call	TT_RelocateGraphics
	call	VMUnlock
afterRelocation:
	pop	ax, cx, dx, si, bp, ds

	call	LoadDBCommon

	ret

VisTextLoadFromDBItemWithStyles	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadStyledRunFromDB

DESCRIPTION:	Load a run with style information to a DB item.  This routine
		just saves the run (the styles are assumed to be saved
		elsewhere)

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset (in instance data) of chunk
	cxdx - db group and item
	di - offset into db item
	ss:bp - StyleSheetParams

RETURN:
	di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/91		Initial version

------------------------------------------------------------------------------@
LoadStyledRunFromDB	proc	near	uses ax, bx, cx, dx
	class	VisTextClass
	.enter

	; first we save the run array

	push	si
	clc
	call	GetChunkForLoadSave		;si = chunk
	call	LoadChunkFromDB
	pop	si

	push	di				;save offset to return

	; now we traverse the runs to translate tokens to the transfer space

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di][bx]			;*ds:di = run
	mov	di, ds:[di]
	mov	cx, ds:[di].CAH_count		;cx = count
	dec	cx				;don't do last array element

	; load bx with the offset to pass to the style sheet code (0 for
	; char attr, 2 for para attr)

	; also get the correct TRAH_elementVMBlock

	cmp	bx, offset VTI_charAttrRuns
	mov	bx, 0
	mov	dx, ss:[bp].SSP_attrArrays[0*(size StyleChunkDesc)].SCD_vmBlockOrMemHandle
	jz	gotStyleOffset
	inc	bx
	mov	dx, ss:[bp].SSP_attrArrays[1*(size StyleChunkDesc)].SCD_vmBlockOrMemHandle
gotStyleOffset:
	mov	ds:[di].TRAH_elementVMBlock, dx
	add	di, ds:[di].CAH_offset
	clr	dx				;optimization block

	; ds:di = run
	; dx = optimization block
	; cx = run size
	; bx = run offset to pass to style sheet code

translateLoop:
	push	bx, cx
	push	di
	mov	ax, ds:[di].TRAE_token
	mov	di, dx				;di = opt block
	mov	cx, 1				;flag: from transfer space
	mov	dx, CA_NULL_ELEMENT
	call	StyleSheetCopyElement		;bx = dest token
	mov	dx, di				;dx = opt block
	pop	di
	mov	ds:[di].TRAE_token, bx
	pop	bx, cx
	add	di, size TextRunArrayElement
	loop	translateLoop

	; free the optimization block

	mov	bx, dx
	tst	bx
	jz	noFree
	call	MemFree
noFree:

	pop	di				;di = offset in db item
	
	.leave
	ret

LoadStyledRunFromDB	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadGraphicRunFromDB

DESCRIPTION:	Load a graphic run from a DB item.  Then merge the graphics
		elements one-by-one from the source to the destination.

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset (in instance data) of chunk
	cxdx - db group and item
	di - offset into db item
	ss:bp - StyleSheetParams

RETURN:
	di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/91		Initial version

------------------------------------------------------------------------------@
LoadGraphicRunFromDB	proc	near	uses ax, bx, cx, dx
graphic	local	VisTextGraphic
	class	VisTextClass
	.enter

	; first we load the run array. save the elementVMBlock from the existing
	; array header, as that's where the new elements should be stored,
	; not the VM block in the file from which the transfer item came

	push	si
	stc
	call	GetChunkForLoadSave		;si = chunk

	push	di
	mov	di, ds:[si]
	mov	cx, ds:[di].TRAH_elementVMBlock
	pop	di

	push	cx
	mov	cx, si
	call	LoadChunkFromDB
	pop	ax				;ax <- element array vm block
	pop	si				;si <- text object

	push	di				;save offset to return

	; now we traverse the runs to translate tokens to the transfer space

	mov	di, cx
	mov	di, ds:[di]
	mov	cx, ds:[di].CAH_count		;cx = count
	
	mov	ds:[di].TRAH_elementVMBlock, ax	;restore vm block of element
						; array, after it was trashed
						; by LoadChunkFromDB

	dec	cx				;don't do last array element
	LONG jz done
	add	di, ds:[di].CAH_offset

	; ds:di = run
	; cx = run size

translateLoop:
	push	cx
	push	di
	mov	ax, ds:[di].TRAE_token

	; get the graphic from the transfer

	push	si, bp, ds
	push	ax
	mov	cx, ss
	lea	dx, graphic			;cxdx = buffer
	mov	bp, ss:[bp]
	mov	ax, ss:[bp].VTSSSP_graphicsElements
	mov	bx, ss:[bp].SSP_xferAttrArrays[0*(size StyleChunkDesc)].\
								SCD_vmFile
	call	VMLock
	mov	ds, ax
	pop	ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si = array
	call	ChunkArrayGetElement
	call	VMUnlock
	pop	si, bp, ds

	; add the graphic to the text object

	push	bp
	lea	bp, graphic
	call	TA_AddGraphicElement		;ax = token
	pop	bp

	pop	di
	mov	ds:[di].TRAE_token, ax
	pop	cx
	add	di, size TextRunArrayElement
	loop	translateLoop

done:
	pop	di				;di = offset in db item
	
	.leave
	ret

LoadGraphicRunFromDB	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextSaveToDBItem -- MSG_VIS_TEXT_SAVE_TO_DB_ITEM
							for VisTextClass

DESCRIPTION:	Save a text object to a DB item.  This also marks the
		object as "clean".

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx.dx - DBItem to save to (or 0 to allocate)
	bp - VisTextSaveDBFlags

RETURN:
	cx.dx - DBItem saved

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/10/91	Initial version

------------------------------------------------------------------------------@
VisTextSaveToDBItem	proc	far
					; MSG_VIS_TEXT_SAVE_TO_DB_ITEM

	mov_tr	ax, bp				;ax = flags
	call	NukeUnneededSaveFlags
	clr	bp				;no styles
	call	SaveDBCommon
	ret

VisTextSaveToDBItem	endp

;---

	; ax = flags
	; bp = StyleSheetParams structure (or 0 for none)

SaveDBCommon	proc	near
	class	VisTextClass

EC <	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE		>
EC <	ERROR_NZ	VIS_TEXT_REQUIRES_SMALL_TEXT_OBJECT		>

	andnf	ds:[di].VTI_state, not mask VTS_USER_MODIFIED	;set clean

	call	GetFileForSave			;bx = file

	; allocate DB item if needed, else resize to 2

	push	ax
	jcxz	doesNotExist
	mov	ax, 2
	call	ReAllocAX
	jmp	common
doesNotExist:
	mov	cx, 2
	mov	ax, DB_UNGROUPED
	call	DBAlloc
	movdw	cxdx, axdi
common:
	pop	ax

	; store type

	call	LockCXDXToESDI

	mov	es:[di], ax
	call	UnlockDirty
	mov	di, 2				;offset to data

	; save the text (if any)

	test	ax, mask VTSDBF_TEXT
	jz	noSaveText
	push	ax
	mov	al, VTST_SINGLE_CHUNK
	clc					;normal instance data
	mov	bx, offset VTI_text
	call	SaveDataToDB
	pop	ax
noSaveText:

	; save the character attribute information (if any)

	push	ax
	push	cx
	and	ax, mask VTSDBF_CHAR_ATTR
	mov	cl, offset VTSDBF_CHAR_ATTR
	shr	ax, cl
	pop	cx
	jz	noSaveCharAttr
	clc					;normal instance data
	mov	bx, offset VTI_charAttrRuns
	call	saveRun
noSaveCharAttr:
	pop	ax

	; load the paragraph attribute information (if any)

	push	ax
	push	cx
	and	ax, mask VTSDBF_PARA_ATTR
	mov	cl, offset VTSDBF_PARA_ATTR
	shr	ax, cl
	pop	cx
	jz	noSaveParaAttr
	clc					;normal instance data
	mov	bx, offset VTI_paraAttrRuns
	call	saveRun
noSaveParaAttr:
	pop	ax

	; load the type information (if any)

	push	ax
	push	cx
	and	ax, mask VTSDBF_TYPE
	mov	cl, offset VTSDBF_TYPE
	shr	ax, cl
	pop	cx
	jz	noSaveType
	stc					;variable instance data
	mov	bx, ATTR_VIS_TEXT_TYPE_RUNS
	call	SaveDataToDB
noSaveType:
	pop	ax

	; load the graphic information (if any)

	push	ax
	push	cx
	and	ax, mask VTSDBF_GRAPHIC
	mov	cl, offset VTSDBF_GRAPHIC
	shr	ax, cl
	pop	cx
	jz	noSaveGraphic
	mov	bx, ATTR_VIS_TEXT_GRAPHIC_RUNS

	tst_clc	bp				;normal instance data
	jnz	5$
	stc					;variable instance data
	call	SaveDataToDB
	jmp	6$
5$:
	call	SaveGraphicRunToDB
6$:
noSaveGraphic:
	pop	ax

	; load the style information (if any)

	push	ax
	test	ax, mask VTSDBF_STYLE
	jz	noSaveStyles
	mov	bx, ATTR_VIS_TEXT_STYLE_ARRAY
	mov	al, VTST_SINGLE_CHUNK
	stc					;variable instance data
	call	SaveDataToDB
noSaveStyles:
	pop	ax

	; load the region information (if any)

if 0
	push	ax
	test	ax, mask VTSDBF_REGION
	jz	noSaveRegions
	mov	bx, ATTR_VIS_TEXT_REGION_ARRAY
	mov	al, VTST_SINGLE_CHUNK
	stc					;variable instance data
	call	SaveDataToDB
noSaveRegions:
	pop	ax
endif

	; load the name information (if any)

	push	ax
	test	ax, mask VTSDBF_NAME
	jz	noSaveNames
	mov	bx, ATTR_VIS_TEXT_NAME_ARRAY
	mov	al, VTST_SINGLE_CHUNK
	stc					;variable instance data
	call	SaveDataToDB
noSaveNames:
	pop	ax

	ret

;---

saveRun:
	tst_clc	bp				;normal instance data
	jnz	10$
	call	SaveDataToDB
	retn
10$:
	call	SaveStyledRunToDB
	retn

SaveDBCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	NukeUnneededSaveFlags

DESCRIPTION:	Clear flags that are telling us to save things that don't
		exist

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ds:di - vis data
	ax - VisTextSaveDBFlags

RETURN:
	ax - real VisTextSaveDBFlags

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/ 8/92		Initial version

------------------------------------------------------------------------------@
NukeUnneededSaveFlags	proc	near	uses bx
	class	VisTextClass
	.enter

	mov	bl, ds:[di].VTI_storageFlags

	test	bl, mask VTSF_MULTIPLE_CHAR_ATTRS
	jnz	afterCharAttr
	and	ax, not mask VTSDBF_CHAR_ATTR
afterCharAttr:

	test	bl, mask VTSF_MULTIPLE_PARA_ATTRS
	jnz	afterParaAttr
	and	ax, not mask VTSDBF_PARA_ATTR
afterParaAttr:

	test	bl, mask VTSF_TYPES
	jnz	afterType
	and	ax, not mask VTSDBF_TYPE
afterType:

	test	bl, mask VTSF_GRAPHICS
	jnz	afterGraphics
	and	ax, not mask VTSDBF_GRAPHIC
afterGraphics:

	test	bl, mask VTSF_STYLES
	jnz	afterStyles
	and	ax, not mask VTSDBF_STYLE
afterStyles:

	.leave
	ret

NukeUnneededSaveFlags	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetFileForSave

DESCRIPTION:	Get the file to save to

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - StyleSheetParams (or 0)

RETURN:
	bx - file

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/26/92		Initial version

------------------------------------------------------------------------------@
GetFileForSave	proc	near
	tst	bp
	jz	useObjectFile
	mov	bx, ss:[bp].SSP_xferAttrArrays[0*(size StyleChunkDesc)].\
						SCD_vmFile
	ret

useObjectFile:
	call	T_GetVMFile			;bx = file
	ret

GetFileForSave	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SaveDataToDB

DESCRIPTION:	Save run/element to DB item

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	carry - set if variable instance data
	bx - if normal instance data:
		offset (in instance data) of chunk
	     if variable instance data:
		vardata key
	al - VisTextSaveType
	cxdx - db group and item (or 0 to allocate)
	di - offset into db item

RETURN:
	di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/91		Initial version

------------------------------------------------------------------------------@
SaveDataToDB	proc	near	uses si, bp
	class	VisTextClass
	.enter

	push	di
	mov	di, si				;di saves object chunk
	call	GetChunkForLoadSave		;si = chunk
	xchg	di, si				;si = obj, di = chunk to save
	call	GetFileForSave			;bx = file
	mov	si, di
	pop	di

	; if reading in run or run&element then get current element array

	cmp	al, VTST_SINGLE_CHUNK
	jz	noElements
	mov	bp, ds:[si]
	mov	bp, ds:[bp].TRAH_elementArray
noElements:

	; save the data

	call	SaveChunkToDB

	; if single chunk or runs only then done

	cmp	al, VTST_RUNS_AND_ELEMENTS
	jnz	done

	mov	si, bp
	call	SaveChunkToDB

done:
	.leave
	ret

SaveDataToDB	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SaveChunkToDB

DESCRIPTION:	Save a chunk to a DB file

CALLED BY:	INTERNAL

PASS:
	*ds:si - chunk to save
	cxdx - db item
	di - offset into db item
	bx - our vm file

RETURN:
	di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/91		Initial version

------------------------------------------------------------------------------@
SaveChunkToDB	proc	near	uses ax, cx, si, bp, es
	.enter

	; get the chunk size to calculate new size

	mov	si, ds:[si]
	ChunkSizePtr	ds, si, ax
	push	ax				;save size
	add	ax, di				;calculate new chunk size
	add	ax, 2				;allow for size word
	mov	bp, ax				;bp = new size
	call	ReAllocAX
	mov_tr	ax, di				;ax = offset

	call	LockCXDXToESDI
	add	di, ax				;es:di = dest
	pop	cx				;cx = size
	mov	es:[di], cx
	add	di, 2
	rep movsb

	call	UnlockDirty
	mov	di, bp

	.leave
	ret

SaveChunkToDB	endp

;---

UnlockDirty	proc	near
	call	DBDirty
	call	DBUnlock
	ret
UnlockDirty	endp

;---

	; bx = file handle

ReAllocAX	proc	near
	xchgdw	axdi, cxdx
	call	DBReAlloc
	xchgdw	axdi, cxdx
	ret
ReAllocAX	endp

;---

LockCXDXToESDI	proc	near	uses ax
	.enter

	movdw	axdi, cxdx
	call	DBLock				;*es:di = data
	mov	di, es:[di]			;es:di = data

	.leave
	ret

LockCXDXToESDI	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextSaveToDBItemWithStyles --
		MSG_VIS_TEXT_SAVE_TO_DB_ITEM_WITH_STYLES for VisTextClass

DESCRIPTION:	Save a text object to a DB item

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	ss:bp - VisTextSaveToDBWithStylesParams

RETURN:
	cx.dx - DBItem saved

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/20/92		Initial version

------------------------------------------------------------------------------@
VisTextSaveToDBItemWithStyles	proc	far
				; MSG_VIS_TEXT_SAVE_TO_DB_ITEM_WITH_STYLES
	class	VisTextClass

if FULL_EXECUTE_IN_PLACE
	;
	; Validate that the params structure is *not* in a movable code segment
	;
EC<	push	bx, si						>
EC<	movdw	bxsi, ss:[bp].VTSTDBWSP_params			>
EC<	call	ECAssertValidFarPointerXIP			>
EC<	pop	bx, si						>
endif

	movdw	cxdx, ss:[bp].VTSTDBWSP_dbItem
	mov	ax, ss:[bp].VTSTDBWSP_flags
	mov	bx, ss:[bp].VTSTDBWSP_xferFile
	mov	bp, ss:[bp].VTSTDBWSP_params.offset
	call	NukeUnneededSaveFlags

	; somewhat of a hack here -- if this object does not have any runs
	; to save then just use the normal save

	test	ax, mask VTSDBF_CHAR_ATTR or mask VTSDBF_PARA_ATTR
	jnz	hasRuns
	tst	bx
	jnz	gotFile
	mov	bx, ss:[bp].SSP_xferStyleArray.SCD_vmFile
gotFile:
	xchg	bx, ds:[di].VTI_vmFile
	mov_tr	bp, ax
	mov	ax, MSG_VIS_TEXT_SAVE_TO_DB_ITEM
	call	ObjCallInstanceNoLock
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	xchg	bx, ds:[di].VTI_vmFile
	ret

hasRuns:

	; initialize the StyleSheetParams structure if needed

	tst	bx
	jz	noInitialize
	clc
	call	LoadSSParams

	push	ax, cx, dx
	mov	ss:[bp].SSP_xferStyleArray.SCD_vmFile, bx
	mov	ss:[bp].SSP_xferAttrArrays[0*(size StyleChunkDesc)].\
						SCD_vmFile, bx
	mov	ss:[bp].SSP_xferAttrArrays[1*(size StyleChunkDesc)].\
						SCD_vmFile, bx
	mov	ss:[bp].SSP_xferStyleArray.SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_xferAttrArrays[0*(size StyleChunkDesc)].\
					SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_xferAttrArrays[1*(size StyleChunkDesc)].\
					SCD_chunk, VM_ELEMENT_ARRAY_CHUNK

	; temporarily save the VM file and fool our code into thinking that
	; we are in the destination file

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	xchg	bx, ds:[di].VTI_vmFile
	push	bx

	; create graphics element array if needed

	and	ax, mask VTSDBF_GRAPHIC
	cmp	ax, (VTST_RUNS_ONLY shl offset VTSDBF_GRAPHIC)
	jnz	noGraphicArray
	mov	bl, TAT_GRAPHICS
	mov	bh, 1
	call	TA_CreateElementArray
	mov	ss:[bp].VTSSSP_graphicsElements, ax
noGraphicArray:

	; create attribute stuff

	mov	bh, 1
	call	TA_CreateStyleArray
	mov	ss:[bp].SSP_xferStyleArray.SCD_vmBlockOrMemHandle, bx

	mov	bl, TAT_PARA_ATTRS
	mov	bh, 1
	call	TA_CreateElementArray
	mov	ss:[bp].SSP_xferAttrArrays[1*(size StyleChunkDesc)].\
					SCD_vmBlockOrMemHandle, ax

	mov	bl, TAT_CHAR_ATTRS
	mov	bh, 1
	call	TA_CreateElementArray
	mov	ss:[bp].SSP_xferAttrArrays[0*(size StyleChunkDesc)].\
					SCD_vmBlockOrMemHandle, ax


	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	pop	ds:[di].VTI_vmFile
	pop	ax, cx, dx

noInitialize:

	call	SaveDBCommon

	ret

VisTextSaveToDBItemWithStyles	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SaveStyledRunToDB

DESCRIPTION:	Save a run with style information to a DB item.  This routine
		just saves the run (the styles are assumed to be saved
		elsewhere)

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset (in instance data) of chunk
	cxdx - db group and item
	di - offset into db item
	ss:bp - StyleSheetParams

RETURN:
	di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/91		Initial version

------------------------------------------------------------------------------@
SaveStyledRunToDB	proc	near	uses ax, bx, cx, dx, si
runOffset	local	word	push	bx
dbOffset	local	word	push	di
object		local	word	push	si
retOffset	local	word
	class	VisTextClass
	.enter

	; first we save the run array

	clc
	call	GetChunkForLoadSave		;si = chunk
	push	si, bp
	mov	si, object
	mov	bp, ss:[bp]
	call	GetFileForSave			;bx = file
	pop	si, bp
	call	SaveChunkToDB
	mov	retOffset, di			;save offset to return

	; now we traverse the runs to translate tokens to the transfer space

	call	LockCXDXToESDI
	add	di, dbOffset
	add	di, size word			;skip size word

	; load bx with the offset to pass to the style sheet code (0 for
	; char attr, 2 for para attr)

	cmp	runOffset, offset VTI_charAttrRuns
	mov	bx, 0
	jz	gotStyleOffset
	inc	bx
gotStyleOffset:
	clr	dx				;optimization block

	mov	cx, es:[di].CAH_count
	dec	cx				;don't do last array element
	add	di, es:[di].CAH_offset

	; es:di = run
	; dx = optimization block
	; cx = count
	; bx = run offset to pass to style sheet code

translateLoop:
	push	bx, cx
	push	di
	mov	ax, es:[di].TRAE_token
	mov	di, dx				;di = opt block
	clr	cx				;flag: to transfer space
	mov	dx, CA_NULL_ELEMENT
	push	bp
	mov	bp, ss:[bp]
	call	StyleSheetCopyElement		;bx = dest token
	pop	bp
	mov	dx, di				;dx = opt block
	pop	di
	mov	es:[di].TRAE_token, bx
	pop	bx, cx
	add	di, size TextRunArrayElement
	loop	translateLoop

	; free the optimization block

	mov	bx, dx
	tst	bx
	jz	noFree
	call	MemFree
noFree:

	call	UnlockDirty
	mov	di,retOffset
	
	.leave
	ret

SaveStyledRunToDB	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SaveGraphicRunToDB

DESCRIPTION:	Save a run with style information to a DB item.  This routine
		just saves the run (the styles are assumed to be saved
		elsewhere)

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	bx - offset (in instance data) of chunk (OFFSET_FOR_GRAPHICS_RUNS)
	cxdx - db group and item
	di - offset into db item
	ss:bp - VisTextSaveStyleSheetParams

RETURN:
	di - updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/91		Initial version

------------------------------------------------------------------------------@
SaveGraphicRunToDB	proc	near	uses ax, bx, cx, dx, si
dbOffset	local	word	push	di
object		local	word	push	si
retOffset	local	word
destFile	local	word
sourceFile	local	word
graphic		local	VisTextGraphic
	class	VisTextClass
	.enter

	; first we save the run array

	push	si
	stc
	call	GetChunkForLoadSave		;si = chunk
	push	si, bp
	mov	si, object
	mov	bp, ss:[bp]
	call	GetFileForSave			;bx = file
	pop	si, bp
	call	SaveChunkToDB
	mov	retOffset, di			;save offset to return
	mov	destFile, bx
	pop	si

	; now we traverse the runs to translate tokens to the transfer space

	call	LockCXDXToESDI
	add	di, dbOffset
	add	di, size word			;skip size word

	mov	cx, es:[di].CAH_count
	dec	cx				;don't do last array element
	LONG jz done
	add	di, es:[di].CAH_offset

	call	T_GetVMFile
	mov	sourceFile, bx

	; es:di = run
	; cx = count

translateLoop:
	push	cx, si, di
	mov	ax, es:[di].TRAE_token

	; get the graphic from the text object

	push	bp
	lea	bp, graphic
	call	TA_GetGraphicElement
	pop	bp

	; copy the graphic to the array

	push	ds
	push	bp
	mov	cx, ss
	lea	dx, graphic			;cxdx = element to add
	lea	ax, sourceFile
	push	ax
	mov	bp, ss:[bp]
	mov	ax, ss:[bp].VTSSSP_graphicsElements
	call	GetFileForSave			;bx = file
	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK	;*ds:si = array
	mov	bx, vseg TG_CompareGraphics
	mov	di, offset TG_CompareGraphics
	pop	bp
	call	ElementArrayAddElement		;ax = new token
	jnc	noNewGraphic

	; new graphic element added -- copy the data

	push	ax
	mov	bx, ss:[bp+2]			;bx = dest file
	mov	ax, ss:[bp]			;ax = source file
	mov	bp, dx				;ss:bp = graphic
	mov_tr	dx, ax				;dx = source file
	call	TG_CopyGraphic
	pop	ax
	call	ChunkArrayElementToPtr		;ds:di = ptr
	movdw	cxdx, ss:[bp].VTG_vmChain
	movdw	ds:[di].VTG_vmChain, cxdx

	; and add the block to the VM tree

	pop	bp				;ss:bp = local vars
	push	bp
	mov	bp, ss:[bp]
	call	AddGraphicToTree

noNewGraphic:
	mov	bp, ds:[LMBH_handle]
	call	VMDirty
	call	VMUnlock
	pop	bp
	pop	ds

	pop	cx, si, di
	mov	es:[di].TRAE_token, ax
	add	di, size TextRunArrayElement
	dec	cx
	LONG jnz translateLoop

done:
	call	UnlockDirty
	mov	di,retOffset
	
	.leave
	ret

SaveGraphicRunToDB	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddGraphicToTree

DESCRIPTION:	Add a graphic to the given tree

CALLED BY:	INTERNAL

PASS:
	ss:bp - VisTextSaveStyleSheetParams
	bx - VM file
	cxdx - vm tree to add

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
	Tony	12/29/92		Initial version

------------------------------------------------------------------------------@
AddGraphicToTree	proc	near	uses ax, di, bp, ds
	.enter

	mov	ax, ss:[bp].VTSSSP_treeBlock
	mov	di, ss:[bp].VTSSSP_graphicTreeOffset
	call	VMLock
	mov	ds, ax

	; does a tree block exist already ?

	mov	ax, ds:[di].high
	tst	ax
	jnz	gotTreeBlock

	; no -- allocate one

	push	cx, bp, ds
	mov	cx, size VMChainTree
	clr	ax				;no user ID
	call	VMAlloc
	mov	ds:[di].high, ax
	push	ax
	call	VMLock
	mov	ds, ax
	mov	ds:[VMCT_meta].VMCL_next, 0
	mov	ds:[VMCT_offset], size VMChainTree
	mov	ds:[VMCT_count], 0
	call	VMUnlock
	pop	ax
	pop	cx, bp, ds

gotTreeBlock:
	call	VMUnlock			;unlock top level tree

	call	VMLock
	mov	ds, ax
	inc	ds:[VMCT_count]
	mov	ax, ds:[VMCT_count]		;calculate new block size
	shl	ax
	shl	ax
	add	ax, size VMChainTree
	push	ax, cx
	xchg	bx, bp
	mov	ch, mask HAF_NO_ERR
	call	MemReAlloc
	mov	ds, ax
	xchg	bx, bp
	pop	di, cx
	movdw	<ds:[di-(size dword)]>, cxdx
	call	VMUnlock

	.leave
	ret

AddGraphicToTree	endp

TextStorageCode ends
