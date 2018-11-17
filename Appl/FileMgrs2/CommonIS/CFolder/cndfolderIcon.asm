COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cndfolderIcon.asm

AUTHOR:		Martin Turon, Nov 13, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/13/92	Initial version


DESCRIPTION:
	
		

RCS STAMP:
	$Id: cndfolderIcon.asm,v 1.2 98/06/03 13:11:12 joon Exp $


=============================================================================@

FolderCode	segment



COMMENT @-------------------------------------------------------------------
			FolderRecordGetViewSize
----------------------------------------------------------------------------

DESCRIPTION:	Gets the size of the parent folder's view.

CALLED BY:	FolderRecordFindEmptyDesktopSlot

PASS:		ds:di	= FolderRecord

RETURN:		ax, bx	= parent folder's view size
		ZF	= set if desktop
			  clear otherwise
	
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/14/92	Initial version

---------------------------------------------------------------------------@
FolderRecordGetViewSize	proc	near
ND <		class	NDFolderClass					>
GM <		class	FolderClass					>


		uses	di, ds, es, si, di

		.enter

		call	FolderRecordGetParent

		DerefFolderObject	ds, si, di
		movP	axbx, ds:[di].FOI_winBounds
ND <		cmp	ds:[di].NDFOI_ndObjType, WOT_DESKTOP		>

		.leave
		ret
FolderRecordGetViewSize	endp





specialObjectLookupTable	label	NewDeskObjectType
	NewDeskObjectType	WOT_WASTEBASKET
	NewDeskObjectType	WOT_PRINTER
	NewDeskObjectType	WOT_LOGOUT
	NewDeskObjectType	WOT_HELP
if _NEWDESKBA
	NewDeskObjectType	WOT_TEACHER_COMMON
	NewDeskObjectType	WOT_OFFICE_COMMON
	NewDeskObjectType	WOT_TEACHER_CLASSES
	NewDeskObjectType	WOT_STUDENT_CLASSES
	NewDeskObjectType	WOT_STUDENT_UTILITY
	NewDeskObjectType	WOT_TEACHER_HOME
	NewDeskObjectType	WOT_STUDENT_HOME
	NewDeskObjectType	WOT_OFFICE_HOME
endif		; if _NEWDESKBA

SPECIAL_OBJECT_LOOKUP_TABLE_LENGTH	equ \
	(($ - specialObjectLookupTable)/size NewDeskObjectType)


;
; These values are fractions, based on the number 16384
; This means <16383,16383> = lower right hand corner of screen.


ROW_HEIGHT = 2380
COLUMN_WIDTH = 2380
BOTTOM_ROW = ROW_HEIGHT * 6
ONE_ROW_UP_FROM_BOTTOM = BOTTOM_ROW - ROW_HEIGHT

LEFT_EDGE = 320
CENTER_HORIZ = 7360

RIGHT_EDGE = 14600

specialObjectPositionTable	label	Point
	Point	<RIGHT_EDGE,BOTTOM_ROW>		; WOT_WASTE_BASKET
	Point	<LEFT_EDGE,12160>		; WOT_PRINTER
	Point	<LEFT_EDGE,320>			; WOT_LOGOUT
	Point	<RIGHT_EDGE,320>		; WOT_HELP
if _NEWDESKBA
	Point	<RIGHT_EDGE,BOTTOM_ROW>		; WOT_TEACHER_COMMON
	Point	<RIGHT_EDGE,BOTTOM_ROW>		; WOT_OFFICE_COMMON
	Point	<5120,BOTTOM_ROW>		; WOT_TEACHER_CLASSES
	Point	<5120,BOTTOM_ROW>		; WOT_STUDENT_CLASSES
	Point	<2880,BOTTOM_ROW>		; WOT_STUDENT_UTILITY
	Point	<CENTER_HORIZ,BOTTOM_ROW>	; WOT_TEACHER_HOME
	Point	<CENTER_HORIZ,BOTTOM_ROW>	; WOT_STUDENT_HOME
	Point	<CENTER_HORIZ,BOTTOM_ROW>	; WOT_OFFICE_HOME
endif		; if _NEWDESKBA

SPECIAL_OBJECT_POSITION_TABLE_LENGTH	equ \
	(($ - specialObjectPositionTable)/size Point)


; Position the first few drives specially -- near the bottom right
; corner.  If user has more than this many drives, they'll be
; positioned as normal icons
;

drivePositionTable		Point	\
	<9920,BOTTOM_ROW>,
	<11328,BOTTOM_ROW>,
	<RIGHT_EDGE,BOTTOM_ROW-ROW_HEIGHT>,
	<RIGHT_EDGE,BOTTOM_ROW-2*ROW_HEIGHT>,
	<RIGHT_EDGE,BOTTOM_ROW-3*ROW_HEIGHT>,
	<RIGHT_EDGE,BOTTOM_ROW-4*ROW_HEIGHT>,
	<RIGHT_EDGE,BOTTOM_ROW-5*ROW_HEIGHT>



COMMENT @-------------------------------------------------------------------
			FolderRecordPlaceIfSpecial
----------------------------------------------------------------------------

DESCRIPTION:	Searchs the list of special NewDeskObjectTypes for the
		WOT of the given FolderRecord.  If a match is found,
		the corresponding position of the special type is
		stuffed into the FolderRecord.

CALLED BY:	INTERNAL - FolderPlaceUnpositionedIcons
				(via FolderSendToChildren)

PASS:		ds:di	= FolderRecord
	
RETURN:		CARRY CLEAR

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/10/92	Initial version

---------------------------------------------------------------------------@

FolderRecordPlaceIfSpecial	proc	far


	;
	; If this is a drive, handle it.
	;
		call	FolderRecordPlaceIfDrive
		jc	done

	;
	; Look up positions of special Wizard/BA specific NewDeskObjectTypes.
	;
		push	di, es
		mov	ax, ds:[di].FR_desktopInfo.DI_objectType
		segmov	es, cs
		mov	di, offset specialObjectLookupTable	
		mov	cx, SPECIAL_OBJECT_LOOKUP_TABLE_LENGTH
		repne	scasw
		mov	bx, di
		pop	di, es

	;
	; If can't find a match, just bail.  Unpositioned icons will
	; be placed in empty slots later...
	;

		jne	done

		sub	bx, offset specialObjectLookupTable + \
				size	NewDeskObjectType
		shl	bx, 1		; size of Point is twice that of a WOT
		movdw	dxcx, cs:[specialObjectPositionTable][bx]

		call	FolderRecordSetPositionAsPercentage

done:
		clc
		ret

FolderRecordPlaceIfSpecial	endp


COMMENT @-------------------------------------------------------------------
			FolderRecordPlaceIfDrive
----------------------------------------------------------------------------

DESCRIPTION:	Currently, Wizard/BA defines specific places where its
		drive icons should go.  This routine will check if the
		given FolderRecord and position it in the next drive
		slot if it is.  It also updates the drive slot
		appropriately. 

CALLED BY:	INTERNAL - FolderRecordPlaceIfSpecial

PASS:		ds:di	= FolderRecord

RETURN:		if position found:
			CARRY SET
		else
			CARRY CLEAR

DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/13/92	Initial version

---------------------------------------------------------------------------@
FolderRecordPlaceIfDrive	proc	near
		.enter
	;
	; Check if this FolderRecord is a drive.
	;
		cmp	ds:[di].FR_desktopInfo.DI_objectType, WOT_DRIVE
		je	positionIt
		clc
done:
		.leave
		ret


	;
	; Changed to use FolderRecordFindEmptyDesktopSlot, and
	; modified that routine accordingly, to fix a problem where
	; user moves from a machine that doesn't have a particular
	; drive, to one that does, and the drive icons end up
	; overlapping, or some such nonsense.
	;
		
positionIt:
		call	FolderRecordFindEmptyDesktopSlot
		jc	done
		call	FolderRecordSetPosition
		stc
		jmp	done

FolderRecordPlaceIfDrive	endp



COMMENT @-------------------------------------------------------------------
			FolderRecordFindEmptyDesktopSlot
----------------------------------------------------------------------------

DESCRIPTION:	Place the given file in the next empty slot on the
		desktop. 

CALLED BY:	FolderRecordFindEmptySlot,
		FolderRecordPlaceIfDrive
		

PASS:		ds:di	= FolderRecord

RETURN:		IF POSITION FOUND:
			carry clear
			cx, dx - position
		ELSE:
			carry set

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/14/92	Initial version

---------------------------------------------------------------------------@
FolderRecordFindEmptyDesktopSlot	proc	near
		class	NDFolderClass

		uses	di, ds, es
		
iconWidth	local	word
iconHeight	local	word		
winBounds	local	Point
tableStart	local	nptr
tableSize	local	word

		.enter

		call	FolderRecordGetParent	; *ds:si - folder
						; es:di - FolderRecord 

		DerefFolderObject	ds, si, bx
		cmp	ds:[bx].NDFOI_ndObjType, WOT_DESKTOP
		jne	notFound

		movP	ss:[winBounds], ds:[bx].FOI_winBounds, ax

		call	FolderCalcIconBoxSize
		mov	ss:[iconWidth], cx
		mov	ss:[iconHeight], dx

	;
	; Figure out which table to use, based on whether this
	; FolderRecord is an icon of a drive.
	;

		mov	ss:[tableStart], offset drivePositionTable
		mov	ss:[tableSize], size drivePositionTable
		
		cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_DRIVE
		je	gotTable

notDrive:
		mov	ss:[tableStart], offset emptyDesktopPositionTable
		mov	ss:[tableSize], size emptyDesktopPositionTable
gotTable:
		
		
		clr	bx		; table offset


findEmptyDesktopSlotLoop:

	;
	; Find next unoccupied table entry.
	;
		push	bx
		add	bx, ss:[tableStart]
		movdw	dxcx, cs:[bx]		; fetch position from table
		movdw	bxax, ss:[winBounds]
		call	ConvertPercentageToPosition

		mov	ax, cx
		mov	bx, dx
		add	cx, ss:[iconWidth]
		add	dx, ss:[iconHeight]
		call	FolderCheckForIconInRect
		mov	dx, bx			; in case found
		pop	bx
		jnc	found

		add	bx, size Point
		cmp	bx, ss:[tableSize]
		jl	findEmptyDesktopSlotLoop

	;
	; If we arrive here, and we were unable to place a drive icon,
	; then try again, using the "not drive" table
	;
		cmp	ss:[tableStart], offset drivePositionTable
		je	notDrive
		
notFound:
		stc

done:
		.leave
		ret

found:
	;
	; Return position in cx, dx (carry is clear here)
	;
		
		mov_tr	cx, ax
		jmp	done
		
FolderRecordFindEmptyDesktopSlot	endp

;
; For non-special objects on the desktop, we still want to place them
; specially, unless there's no more room in this table.
;

FUDGE_FACTOR = 50

emptyDesktopPositionTable		Point	\
	<LEFT_EDGE, ROW_HEIGHT>,
	<LEFT_EDGE, ROW_HEIGHT*2>,
	<LEFT_EDGE, ROW_HEIGHT*3>,
	<LEFT_EDGE, ROW_HEIGHT*4>,
	<COLUMN_WIDTH, ROW_HEIGHT*5+FUDGE_FACTOR>,
	<COLUMN_WIDTH*2, ROW_HEIGHT*5+FUDGE_FACTOR>,
	<COLUMN_WIDTH*3, ROW_HEIGHT*5+FUDGE_FACTOR>,
	<COLUMN_WIDTH*4, ROW_HEIGHT*5+FUDGE_FACTOR>,
	<COLUMN_WIDTH*5, ROW_HEIGHT*5+FUDGE_FACTOR>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRecordSetPositionAsPercentage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the position of this folder record as a percentage
		of the folder size.

CALLED BY:	FolderRecordPlaceIfSpecial

PASS:		ds:di - FolderRecord
		(cx, dx) - x, y percentage

RETURN:		nothing 

DESTROYED:	cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRecordSetPositionAsPercentage	proc near

		uses	ax,bx,es

		class	FolderClass

		.enter

	;
	; Get bounds of folder
	;
		call	FolderRecordGetViewSize	; ax, bx, - view size

	;
	; Using those bounds, convert the percentage to a position
	;

		call	ConvertPercentageToPosition
		call	FolderRecordSetPosition

	;
	; If the bottom of the icon is below the bottom of the screen,
	; then adjust.
	;
		sub	bx, ds:[di].FR_boundBox.R_bottom
		jg	done

		add	dx, bx
		call	FolderRecordSetPosition
done:
		.leave
		ret
FolderRecordSetPositionAsPercentage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPercentageToPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to convert a percentage to a position

CALLED BY:	FolderRecordSetPositionAsPercentage

PASS:		(ax, bx) - screen bounds
		(cx, dx) - percentage

RETURN:		(cx, dx) - position 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPercentageToPosition	proc near
		uses	ax, bx
		.enter

		push	dx		; dx 	= y
		imul	cx		; dx:ax = x*screenWidth

		shl	ax, 1		; dx = signed dx:ax / 16384
		rcl	dx, 1
		shl	ax, 1
		rcl	dx, 1
		test	ax, 0x8000	; test fractional bit
		jz	10$

		inc	dx		; round up (very important!)

10$:
		mov	cx, dx		; cx = (x * screenWidth) / 16384

		pop	ax		; ax 	= y
		imul	bx		; dx:ax = y*screenWidth

		shl	ax, 1		; dx = signed dx:ax / 16384
		rcl	dx, 1
		shl	ax, 1
		rcl	dx, 1
		test	ax, 0x8000	; test fractional bit
		jz	20$

		inc	dx		; round up (very important!)

20$:

		.leave
		ret
ConvertPercentageToPosition	endp


FolderCode	ends








