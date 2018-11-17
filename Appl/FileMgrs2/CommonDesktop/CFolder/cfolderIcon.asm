COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cfolderIcon.asm

AUTHOR:		Martin Turon, Nov  2, 1992

ROUTINES:
	Name				Description
	----				-----------
	FolderRecordLoadPosition	Get position from given dirinfo array
	FolderRecordSetPosition		Set position given coordinates
	FolderRecordGetNameWidth	Get width of name in doc. coord.
	FolderRecordCalcBounds		Calculate bounds from icon and name
	FolderRecordSetBounds		Set boundsBox
	FolderRecordGetBounds		Get boundsBox
	FolderRecordInvalRect		Invalidate boundsBox
	FolderRecordFindEmptySlot	Find empty spot in folder's view

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version


DESCRIPTION:
	Routines to deal with FolderRecord "objects" in the visual
	realm.  All routines in this file have been designed to follow
	the API of the messaging system.  The hope is that someday
	FolderRecords will be changed to VisFileClass objects, since
	they are essentially visual files...
		
RCS STAMP:
	$Id: cfolderIcon.asm,v 1.2 98/06/03 13:33:42 joon Exp $

=============================================================================@

FolderCode	segment


COMMENT @-------------------------------------------------------------------
			FolderRecordLoadPosition
----------------------------------------------------------------------------

DESCRIPTION:	Loads the position of the given FolderRecord from the
		given in DIRINFO file.  

CALLED BY:	INTERNAL - FolderLoadDirInfo (via FolderSendToDisplayList)

PASS:		ds:di	= FolderRecord
		*dx:cx	= dirinfo chunk array

RETURN:		carry clear

DESTROYED:	ax, bx, di, si, ds, es 

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/1/92		Initial version

---------------------------------------------------------------------------@
FolderRecordLoadPosition	proc	far
		uses	cx, dx
		.enter
		
		segmov	es, ds		; segment of folder record

	;
	; Look in the given dirinfo file for the filename associated
	; with the given FolderRecord.  If there is no stored position
	; information for that file, mark this FolderRecord as
	; UNPOSITIONED. 
	;

		push	dx, cx
		movdw	cxdx, ds:[di].FR_id
		pop	ds, si
		call	ShellSearchDirInfo
		jc	done

	;
	; Set the percent flag in the folder record, if it's set in
	; the file.
	;
		ECCheckFlags	al, DirInfoFileEntryFlags
		test	al, mask DIFEF_PERCENTAGE
		jz	afterSetPercent
		ornf	es:[di].FR_state, mask FRSF_PERCENTAGE
afterSetPercent:
ifdef SMARTFOLDERS
		mov	ss:[positioned], BB_TRUE
endif

	;
	; Folder's position is stored, so use it (cx, dx)
	;


		segmov	ds, es
		call	FolderRecordSetPosition
done:
		clc
		.leave
		ret			

FolderRecordLoadPosition	endp



COMMENT @-------------------------------------------------------------------
			FolderRecordSavePosition
----------------------------------------------------------------------------

DESCRIPTION:	Saves the position of the given FolderRecord by appending
		the given DIRINFO file.

CALLED BY:	INTERNAL - FolderSaveIconPositions 
				(via FolderSendToDisplayList)

PASS:		ds:di	= FolderRecord  "instance data"
		*dx:cx	= dirinfo chunk array

RETURN:		*dx:cx	= fixed-up pointer to chunk array
		carry clear

DESTROYED:	ax, bx, di, si, bp, ds, es 

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/15/92	Initial version

---------------------------------------------------------------------------@
FolderRecordSavePosition	proc	far
		uses	cx

		.enter

		test	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		jnz	done


		segmov	es, ds
		mov	bp, di			; es:bp = FolderRecord

		mov	ds, dx
		mov	si, cx			; *ds:si = chunk array

		call	ChunkArrayAppend

		mov	cx, es:[bp].FR_iconBounds.R_left
		mov	dx, es:[bp].FR_iconBounds.R_top

		movdw	ds:[di].DIFE_position, dxcx
		movdw	ds:[di].DIFE_fileID, es:[bp].FR_id, ax

	;
	; Set the DIFEF_PERCENTAGE flag same as the FRSF_PERCENTAGE
	; flag.  There's probably some clever way to do this with
	; CheckHacks, but...
	;
		
		clr	al
		test	es:[bp].FR_state, mask FRSF_PERCENTAGE
		jz	gotFlag

		mov	al, mask DIFEF_PERCENTAGE
gotFlag:
		mov	ds:[di].DIFE_flags, al
		
		mov	dx, ds			; fixup DX
done:
		clc
		.leave
		ret
FolderRecordSavePosition	endp


COMMENT @-------------------------------------------------------------------
			FolderRecordSetPosition
----------------------------------------------------------------------------

DESCRIPTION:	Builds all the appropriate bounding regions for a
		FolderRecord to display correctly in Large Icon mode.

CALLED BY:	FolderRecordLoadPosition, FolderRecordPlaceIfSpecial

PASS:		ds:di	= FolderRecord
		cx, dx	= new location of icon

GLOBALS USED:	largeIconBoxWidth
		desktopFontHeight

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	uses global variables in dgroup!! (yuck)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/3/92		Pulled out of BuildLargeMode

---------------------------------------------------------------------------@
FolderRecordSetPosition	proc	far

		uses	ax, bx, cx, dx

		.enter
	;
	; Set icon bounds box
	;
		mov	ds:[di].FR_iconBounds.R_left, cx
		mov	ds:[di].FR_iconBounds.R_top, dx
		mov	ax, cx
		mov	bx, dx
		call	FolderCalcIconSize
		add	cx, ax
		add	dx, bx
		mov	ds:[di].FR_iconBounds.R_right, cx
		mov	ds:[di].FR_iconBounds.R_bottom, dx
	;
	; Set name bounds box
	; 	ax, bx, cx, dx	= icon bounds
	
	;
	; 1) Caculate upper and lower bounds of name:
	;	- top is LARGE_ICON_VERT_SPACING below bottom of icon
	;	- bottom is desktopFontHeight below top
	;
		add	dx, LARGE_ICON_VERT_SPACING+1
		mov	ds:[di].FR_nameBounds.R_top, dx
		add	dx, ss:[desktopFontHeight]
		mov	ds:[di].FR_nameBounds.R_bottom, dx
	;
	; 2) Calculate right and left bounds of name
	;
	;    Register usage:
	;	ax = left icon bound
	;	bx = scratch register
	;	cx = left name bound
	;	dx = name width
	;
		mov	cx, ss:[largeIconBoxWidth]
		call	FolderRecordGetNameWidth	; dx = name width
		cmp	dx, cx
if WRAP
	;
	; If the name fits on one line, then clear the FRSF_WRAP flag,
	; otherwise, set it.
	;
		jg	maybeWrap
		andnf	ds:[di].FR_state, not mask FRSF_WORD_WRAP
		jmp	gotWidth
maybeWrap:
		test	ss:[desktopFeatures], mask DF_WRAP
		jz	noWrap

	;
	; Otherwise, make the two-line calculation, and set the flag.
	;
		ornf	ds:[di].FR_state, mask FRSF_WORD_WRAP
		call	CalcNameBoundsForWrap
		jmp	afterNameBounds
else
		jle	gotWidth
endif
noWrap:
		mov	dx, cx
gotWidth:
		sub	cx, dx				; cx = excess space
		sar	cx, 1				; cx = excess space/2
	;
	; Adjust left name bound relative to left icon bound
	;
		mov	bx, ss:[largeIconBoxWidth]
		sub	bx, LARGE_ICON_WIDTH
		shr	bx, 1
		sub	ax, bx		; left = left - 
					;         2*(largeIconBoxWidth
					;            - LARGE_ICON_WIDTH)

		add	cx, ax		
		mov	ds:[di].FR_nameBounds.R_left, cx
		add	cx, dx			; cx = left + name width
		mov	ds:[di].FR_nameBounds.R_right, cx

afterNameBounds::
if ICON_INVERT_MASK
		sub	ds:[di].FR_nameBounds.R_left, ICON_BOX_X_MARGIN
		add	ds:[di].FR_nameBounds.R_right, ICON_BOX_X_MARGIN
endif
		call	FolderRecordSetPositionCommon

	;
	; If the bounds are negative, then bump the icon over slightly
	;
		mov	ax, ds:[di].FR_boundBox.R_left
		mov	bx, ds:[di].FR_boundBox.R_top
		mov	cx, ax		; no mov_tr!
		or	cx, bx
		jns	done

		mov	cx, ds:[di].FR_iconBounds.R_left
		mov	dx, ds:[di].FR_iconBounds.R_top
		tst	ax
		jns	leftOK
		sub	cx, ax
leftOK:
		tst	bx
		jns	topOK
		sub	dx, bx
topOK:
		call	FolderRecordSetPosition
done:
		.leave
		ret
FolderRecordSetPosition	endp


if WRAP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNameBoundsForWrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out after how many characters the name should
		wrap, and determine the horizontal positions of the
		first and second line, and the number of characters in
		each. 

CALLED BY:	FolderRecordSetPosition

PASS:		ds:di - FolderRecord
		dx - name width
		cx - max allowed width

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcNameBoundsForWrap	proc near
		uses	ax,bx,cx,dx,di,si,bp

		.enter

	;
	; Move the bottom of the name bounds down
	;
		mov	dx, ds:[di].FR_nameBounds.R_bottom
		add	dx, ss:[desktopFontHeight]
		mov	ds:[di].FR_nameBounds.R_bottom, dx

	;
	; Start at the beginning of the name, keeping track of
	; non-alphabetic characters.  We'll stop at the last one at
	; which the name width is less than the max allowed width
	;
		mov	dx, cx		; max allowed width
		clr	bx, cx
		lea	si, ds:[di].FR_name
		CheckHack	<offset FR_name eq 0>

		mov	di, ss:[calcGState]

startLoop:

	;
	; bx - last character that's a likely candidate
	; cx - current character 
	; ds:si - FolderRecord (also, filename)
	; dx - max allowable width
	;	

		inc	cx

		push	dx
		call	GrTextWidth
		mov_tr	ax, dx
		pop	dx
		
		cmp	ax, dx
		jae	endLoop
	;
	; We're still in bounds, so see if this character is one we
	; can break on
	;
		mov	bp, cx
DBCS <		shl	bp, 1						>
SBCS <		mov	al, ds:[si][bp]					>
DBCS <		mov	ax, ds:[si][bp]					>
		LocalCmpChar ax, ','
		je	breakAfter
		LocalCmpChar ax, ' '
		je	breakBefore
		LocalCmpChar ax, '.'
		je	breakBefore
		LocalCmpChar ax, '('
		jne	startLoop
if _NEWDESKBA
	;
	; A left parenthesis is handled differently.  If this folder
	; record is a student, then always break here, since this is
	; probably the student's user ID.  What a nightmare.  If it's
	; not a student, then just treat this character as one that we
	; can break on, if necessary.
	;
		
		mov	ax, ds:[si].FR_desktopInfo.DI_objectType
		cmp	ax, WOT_STUDENT_UTILITY
		je	isStudent
		cmp	ax, WOT_STUDENT_HOME
		je	isStudent
		cmp	ax, WOT_STUDENT_HOME_TVIEW
		jne	breakBefore
	;
	; It IS a student, so exit the loop here
	;
isStudent:
		mov	bx, cx
		jmp	endLoop
endif
	

breakBefore:
		mov	bx, cx
		jmp	startLoop
breakAfter:
		mov	bx, cx
		inc	bx
		jmp	startLoop

endLoop:

		mov	di, si		; FolderRecord

	;
	; If this name is really screwy, then just set BX to CX-1 and
	; hope for the best
	;
		
		tst	bx
		jnz	gotBX
		mov	bx, cx
		dec	bx
gotBX:
		
	;
	; Now, BX is the number of chars in line 1.  Store it away,
	; and fetch the widths of lines 1 and 2.
	;
		
		mov	ds:[di].FR_line1NumChars, bx
		mov	cx, bx
		call	GetHorizPositionFromTextWidth
		mov	ds:[di].FR_line1Pos, cx
		mov	ds:[di].FR_nameBounds.R_left, cx
		add	cx, ax
		mov	ds:[di].FR_nameBounds.R_right, cx
		
		segmov	es, ds
		call	LocalStringLength	; # chars in filename
		sub	cx, bx			; # chars in line 2
DBCS <		shl	bx, 1						>
		add	si, bx
		call	GetHorizPositionFromTextWidth
		mov	ds:[di].FR_line2Pos, cx
		Min	ds:[di].FR_nameBounds.R_left, cx

		add	cx, ax
		Max	ds:[di].FR_nameBounds.R_right, cx

		.leave
		ret

		
CalcNameBoundsForWrap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHorizPositionFromTextWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the horizontal position of this piece of
		text from the text width

CALLED BY:	CalcNameBoundsForWrap

PASS:		ds:si - string
		ds:di - FolderRecord
		cx - number of chars to look at
		dx - max allowed width
		
RETURN:		cx - horizontal position
		ax - name width

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Horiz position = (FolderRecord center) - width/2


KNOWN BUGS/SIDE EFFECTS/IDEAS:
+
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHorizPositionFromTextWidth	proc near
		uses	dx, bx
		.enter

		mov	bx, dx			; max allowed width

		call	FolderGetTextWidth

		Min	dx, bx			; keep width within range
		
		mov	ax, dx			; return width in AX
		mov	cx, ds:[di].FR_iconBounds.R_right
		add	cx, ds:[di].FR_iconBounds.R_left
		sub	cx, dx 
		shr	cx			; position
		
		.leave
		ret
GetHorizPositionFromTextWidth	endp


endif			; code for wrapping



COMMENT @-------------------------------------------------------------------
			FolderRecordSetPositionCommon
----------------------------------------------------------------------------

DESCRIPTION:	Sets the boundBox given iconBounds and nameBounds

CALLED BY:	INTERNAL - FolderRecordSetPosition

PASS:		ds:di	= FolderRecord	
			  (iconBounds, and nameBounds are set correctly)

RETURN:		boundBox set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/6/92		Initial version

---------------------------------------------------------------------------@
FolderRecordSetPositionCommon	proc	near
		.enter
	;
	; Set bounds box
	;
		call	FolderRecordCalcBounds
		call	FolderRecordSetBounds
		BitClr	ds:[di].FR_state, FRSF_UNPOSITIONED
		

EC <		call	ECCheckFolderRecordDSDI			>
		.leave
		ret
FolderRecordSetPositionCommon	endp


COMMENT @-------------------------------------------------------------------
			FolderRecordGetNameWidth
----------------------------------------------------------------------------

DESCRIPTION:	Gets the width of the FileLongName of the given
		FolderRecord for the current video mode/font.

CALLED BY:	INTERNAL - FolderRecordSetPosition,
			   GetNameWidth

PASS:		ds:di	= FolderRecord

RETURN:		dx	= name width

DESTROYED:	nothing

GLOBALS USED:	calcGState

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Leaves in two places, so watch out!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/12/92	Pulled out of GetNameWidth

---------------------------------------------------------------------------@
FolderRecordGetNameWidth	proc	near

	;
	; Check if we have our name width already.  
	; If we don't, calculate it.
	;
		test	ds:[di].FR_state, mask FRSF_HAVE_NAME_WIDTH
		jz	getName

		mov	dx, ds:[di].FR_nameWidth
		ret			; <---- EXIT 1

getName:
		push	cx, si
		BitSet	ds:[di].FR_state, FRSF_HAVE_NAME_WIDTH
		lea	si, ds:[di].FR_name
		mov	cx, FILE_LONGNAME_LENGTH
		call	FolderGetTextWidth
		mov	ds:[di].FR_nameWidth, dx	; store name width
		pop	cx, si
		ret			; <---- EXIT 2

FolderRecordGetNameWidth	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetTextWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the width of a piece of text, truncating the
		first leading space, if such there be

CALLED BY:	GetHorizPositionFromTextWidth, FolderRecordGetNameWidth

PASS:		ds:si - string
		cx - max # chars to check

RETURN:		dx - width

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/19/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetTextWidth	proc near
		uses	cx, si
		.enter

	;
	; Trim off leading spaces, and decrement the character count
	; accordingly. 
	;
		
		mov	dx, si
		call	FolderNameSkipLeadingSpace
		sub	dx, si
	;
	; DBCS: Convert number of bytes to number of chars
	;
DBCS <		sar	dx						>
		add	cx, dx
		
		push	di
		mov	di, ss:[calcGState]
		call	GrTextWidth		; dx - width
		pop	di

		.leave
		ret
FolderGetTextWidth	endp




COMMENT @-------------------------------------------------------------------
			FolderRecordCalcBounds
----------------------------------------------------------------------------

SYNOPSIS:	Compute new bounding box from icon bounds and name
		bounds combination.

CALLED BY:	INTERNAL -
			FolderRecordSetPosition

PASS:		ds:di	= FolderRecord

RETURN:		ax, bx, cx, dx - bounds

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/31/89		Initial version
	martin	10/3/92		Changed API to treat FolderRecord like object

----------------------------------------------------------------------------@
FolderRecordCalcBounds	proc	far
		.enter
	;
	; do left
	;
		mov	ax, ds:[di].FR_iconBounds.R_left
		cmp	ax, ds:[di].FR_nameBounds.R_left
		jle	gotLeft
		mov	ax, ds:[di].FR_nameBounds.R_left
gotLeft:
	;
	; do top
	;
		mov	bx, ds:[di].FR_iconBounds.R_top
		cmp	bx, ds:[di].FR_nameBounds.R_top
		jle	gotTop
		mov	bx, ds:[di].FR_nameBounds.R_top
gotTop:
	;
	; do right
	;
		mov	cx, ds:[di].FR_iconBounds.R_right
		cmp	cx, ds:[di].FR_nameBounds.R_right
		jge	gotRight
		mov	cx, ds:[di].FR_nameBounds.R_right
gotRight:
	;
	; do bottom
	;
		mov	dx, ds:[di].FR_iconBounds.R_bottom
		cmp	dx, ds:[di].FR_nameBounds.R_bottom
		jge	gotBottom
		mov	dx, ds:[di].FR_nameBounds.R_bottom
gotBottom:
		.leave
		ret
FolderRecordCalcBounds	endp



COMMENT @-------------------------------------------------------------------
			FolderRecordSetBounds
----------------------------------------------------------------------------

DESCRIPTION:	Sets the bounding box of the given icon.

CALLED BY:	INTERNAL - FolderRecordSetPosition

PASS:		ds:di		= FolderRecord "instance data"
		ax, bx, cx, dx	= new bounds

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderRecordSetBounds	proc	near
	.enter
	mov	ds:[di].FR_boundBox.R_left, ax
	mov	ds:[di].FR_boundBox.R_top, bx
	mov	ds:[di].FR_boundBox.R_right, cx
	mov	ds:[di].FR_boundBox.R_bottom, dx
	.leave
	ret
FolderRecordSetBounds	endp



COMMENT @-------------------------------------------------------------------
			FolderRecordGetBounds
----------------------------------------------------------------------------

DESCRIPTION:	Returns the bounding box of the given icon.

CALLED BY:	INTERNAL - FolderRecordInvalRect

PASS:		ds:di		= FolderRecord "instance data"

RETURN:		ax, bx, cx, dx	= new bounds

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderRecordGetBounds	proc	near
		uses	ds, si, di, es

		class	FolderClass
		
		.enter

		mov	ax, ds:[di].FR_boundBox.R_left
		mov	bx, ds:[di].FR_boundBox.R_top
		mov	cx, ds:[di].FR_boundBox.R_right
		mov	dx, ds:[di].FR_boundBox.R_bottom
	;
	; If this FoldeRecord is the cursor, then adjust the bounds
	; slightly. 
	;
		call	FolderRecordGetParent
		DerefFolderObject	ds, si, si
		cmp	di, ds:[si].FOI_cursor
		jne	done

		sub	ax, CURSOR_MARGIN
		sub	bx, CURSOR_MARGIN
		add	cx, CURSOR_MARGIN
		add	dx, CURSOR_MARGIN

done:
		.leave
		ret
FolderRecordGetBounds	endp


COMMENT @-------------------------------------------------------------------
			FolderRecordInvalRect
----------------------------------------------------------------------------

DESCRIPTION:	Invalidates the bounding box of the given icon.

CALLED BY:	INTERNAL - FolderRepositionSingleIcon

PASS:		ds:di	= FolderRecord
		bp	= gstate

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderRecordInvalRect	proc	far
	uses	ax, bx, cx, dx
	.enter
	call	FolderRecordGetBounds
	xchg	di, bp
	call	GrInvalRect
	xchg	di, bp
EC <	call	ECCheckFolderRecordDSDI				>
	.leave
	ret
FolderRecordInvalRect	endp



COMMENT @-------------------------------------------------------------------
			FolderRecordFindEmptySlot
----------------------------------------------------------------------------

DESCRIPTION:	Searchs intelligently for an empty area to place the
		given icon, and places it there.

CALLED BY:	FolderPlaceUnpositionedIcons,
			FolderRescanFolderEntry

PASS:		ds:di	= FolderRecord

RETURN:		carry clear

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderRecordFindEmptySlot	proc	far

ND <		class	NDFolderClass				>
		
iconBoxSize	local	Point
folderSize	local	Point
ifdef GPC
folderType	local	word
endif

		uses	cx, dx, si, es
		.enter

BA <		call	FolderRecordFindEmptyDesktopSlot		>
BA <		jnc	setPosition					>

 		push	ds, di			; save FolderRecord
		call	FolderRecordGetParent
ifdef GPC
		push	si
		DerefFolderObject	ds, si, si
		mov	si, ds:[si].NDFOI_ndObjType
		mov	folderType, si
		pop	si
endif
	;
	; Get proper constants into local variables
	;
		call	FolderCalcIconAreaSize
		movP	folderSize, cxdx

	;
	; Subtract off the icon box size from the folder width, so
	; that we don't try to stick an icon right near the right edge.
	;
		
		call	FolderCalcIconBoxSize
		sub	folderSize.P_x, cx
ifdef GPC
		sub	folderSize.P_y, dx
endif
		movP	iconBoxSize, cxdx

		clr	bx 			; bx = initial Y pos.
						; dx = iconHeight

if _NEWDESKBA

	;
	; In entry level, don't position anything in the top third of
	; the desktop, where the Assistance window resides.
	;
		push	si
		DerefFolderObject	ds, si, si
		cmp	ds:[si].NDFOI_ndObjType, WOT_DESKTOP
		jne	afterDesktop
		call	UtilAreWeInEntryLevel?
		jnc	afterDesktop

	;
	; Start at FolderHeight/3
	;

		push	dx
		mov	ax, ds:[si].FOI_winBounds.P_y
		clr	dx
		mov	bx, 3
		div	bx
		mov_tr	bx, ax
		pop	dx
		add	dx, bx
afterDesktop:
		pop	si		; *ds:si - folder
		
endif

loopY:
	;
	; BX - y-position
	; DX = BX + iconBoxSize.P_y
	;
		mov	ax, LARGE_ICON_INDENT
		mov	cx, ax
		add	cx, LARGE_ICON_WIDTH
loopX:
		call	FolderCheckForIconInRect
		jnc	found			; if no icon in
						; region, we're done!
		add	ax, iconBoxSize.P_x
		add	cx, iconBoxSize.P_x
		cmp	ax, folderSize.P_x
		jl	loopX

		add	bx, iconBoxSize.P_y
		add	dx, iconBoxSize.P_y
ifdef GPC
		cmp	folderType, WOT_DESKTOP
		jne	notDesktop
		cmp	bx, folderSize.P_y
		jl	loopY
	;
	; overflow, just put at bottom right
	;
		mov	ax, folderSize.P_x
		dec	ax
		mov	bx, folderSize.P_y
		dec	bx
		jmp	found
notDesktop:
endif
		jmp	loopY

found:
		pop	ds, di			; restore FolderRecord
		mov_tr	cx, ax
		mov	dx, bx

BA <setPosition:						>
		call	FolderRecordSetPosition
		clc
		.leave
		ret
FolderRecordFindEmptySlot	endp




COMMENT @-------------------------------------------------------------------
			FolderRecordGetParent
----------------------------------------------------------------------------

DESCRIPTION:	Returns a pointer to the instance data of the parent
		folder for the given FolderRecord.

CALLED BY:	INTERNAL - FolderRecordFindEmptySlot

PASS:		ds:di	= FolderRecord

RETURN:		*ds:si - FolderClass object
		es:di	= FolderRecord

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/15/92	Initial version

---------------------------------------------------------------------------@
FolderRecordGetParent	proc	far
		uses	bx
		.enter
		segmov	es, ds
		movdw	bxsi, es:[FBH_folder]
		call	MemDerefDS

		.leave
		ret
FolderRecordGetParent	endp


FolderCode	ends








