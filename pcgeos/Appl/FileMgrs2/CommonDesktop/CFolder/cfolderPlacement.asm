COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop
FILE		cfolderPlacement.asm

AUTHOR:		Martin Turon, Jul 20, 1992

ROUTINES:

------------ FolderCode segment ----------
	INT	FolderOpenDirInfo	- opens  dirinfo w/error checking
	EXT	FolderLoadDirInfo 	- load icon position information
	INT	FolderPlaceUnpositionedIcons  - finds a home for "lost" icons
	EXT	FolderSaveDirInfo	- save icon position information
	INT	FolderFillDirInfo	- fill chunk array with folder info
	INT	FolderGetIconAreaSize	- gets the bounds of the icon area
	INT	FolderCheckForIconInRect

------------ FolderAction segment ----------
	INT	FolderRepositionIcons
	INT	FolderRepositionSingleIcon
	INT	FolderRecalcDocBounds
	INT	FolderObjectBringToTop
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/20/92		Initial Version


DESCRIPTION:	Routines that deal with access to the dirinfo.vm file,
		and initiating any changes to folder information that
		that file specifies.
		Currently this includes: icon placement
					 folder window position and size 

	
RCS STAMP:
	$Id: cfolderPlacement.asm,v 1.2 98/06/03 13:35:54 joon Exp $

=============================================================================@

FolderCode	segment

;
; Filename to store icon position info to.
;

idata		segment

GM <LocalDefNLString dirinfoFilename <'@DIRINFO (GeoManager)',0>	>
if DBCS_PCGEOS
ND <LocalDefNLString dirinfoFilename <'@ND Directory',0>	>
else
ND <LocalDefNLString dirinfoFilename <'@Directory Information',0>	>
endif

idata		ends


COMMENT @-------------------------------------------------------------------
			FolderOpenDirInfo
----------------------------------------------------------------------------

DESCRIPTION:	Decides which dirinfo file to open, opens it, and
		handles errors

CALLED BY:	FolderLoadDirInfo

PASS:		*ds:si	= FolderClass object

RETURN:		if error
			carry set
		else
			carry clear
			es - DirInfoFileHeader
			bx - VM file handle
			bp - memory handle of locked VM block


DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	None of the Wizard/BA specific code in this routine should be
	needed! (Advanced and Entry Level default dirinfo should exist
	in the Geoworks source tree)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	9/ 9/92		Initial version

---------------------------------------------------------------------------@
FolderOpenDirInfo	proc	near
		class	FolderClass
		uses	ds, si, di
		.enter

	;								
	; only use default position info in Wizard/BA entry level	
	;								
BA <		call	UtilAreWeInEntryLevel?				>
BA <		jc	done						>

		call	UtilCheckReadDirInfo
		jc	done

		call	FolderSeeIfDirInfoFileExists	; dx <- filename offset
		cmc
		jc	done
		
NOFXIP<		segmov	ds, dgroup		; ds:dx - filename to open >
FXIP	<	mov	ax, bx						>
FXIP	<	GetResourceSegmentNS dgroup, ds, TRASH_BX		>
FXIP	<	mov	bx, ax						>
		call	ShellOpenDirInfo
		segmov	es, ds			; es - segment of
						; DirInfoFileHeader 

done:
		.leave
		ret
FolderOpenDirInfo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderFindFilenameCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the 2 filenames match

CALLED BY:	FolderOpenDirInfoLow

PASS:		ss:dx - 1 filename (idata:dx)
		ds:di - another

RETURN:		if match:
			CARRY SET
		else:
			CARRY CLEAR

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/16/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderFindFilenameCB	proc far

	uses	ds,si,cx

	.enter

	mov	si, di		; ds:si - FolderRecord filename
NOFXIP<	segmov	es, ss							>
FXIP  <	mov	cx, bx							>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP  <	mov	bx, cx							>
	mov	di, dx
	clr	cx
	call	LocalCmpStrings
	clc
	je	found
done:
	.leave
	ret

found:
	stc
	jmp	done
FolderFindFilenameCB	endp



COMMENT @-------------------------------------------------------------------
			FolderLoadDirInfo
----------------------------------------------------------------------------

DESCRIPTION:	Load in position info from the dirinfo.vm file in the
		current directory (must be set correctly). 

CALLED BY:	EXTERNAL - 
			FolderScan, FolderSetDisplayOptions

PASS:		*ds:si	= FolderClass object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/16/92		Initial version

---------------------------------------------------------------------------@
ifdef SMARTFOLDERS
idata	segment
positioned	BooleanByte
idata	ends
endif

FolderLoadDirInfo	proc	far

GM <		class FolderClass					>
ND <		class NDFolderClass					>

		uses	ax, ds, si
		.enter

		DerefFolderObject	ds, si, di 
ifdef SMARTFOLDERS
		andnf	ds:[di].FOI_positionFlags,
			not (mask FIPF_POSITIONED or mask FIPF_DIRTY or mask FIPF_WIN_SAVED)
else
		andnf	ds:[di].FOI_positionFlags,
			not (mask FIPF_POSITIONED or mask FIPF_DIRTY)
endif

	;
	; build the display list, by whatever the current sort order
	; is.
	;
		mov	ax, TRUE
		call	BuildDisplayList

	;
	; Bail unless in large icon mode
	;
		test	ds:[di].FOI_displayMode, mask FIDM_LICON
		jz	done
		
	;
	; Try to open the dirinfo file.  If it's not there, then just
	; build the display list, preserving the existing sort order.
	;

		call	FolderOpenDirInfo
		jc	done

	;
	; Now have each FolderRecord on the display list load their
	; positions from the dirinfo file.  
	;

ifdef SMARTFOLDERS
		mov	ss:[positioned], BB_FALSE
else
		BitSet	ds:[di].FOI_positionFlags, FIPF_POSITIONED
endif
		push	bx			; save VM info for closing
		mov	dx, es			; dx = locked dirinfo.vm block
		mov	cx, es:[DIFH_posArray]	; *dx:cx = chunk array
		mov	bx, offset FolderRecordLoadPosition
		mov	ax, SEGMENT_CS		; ax:bx = callback routine
		call	FolderSendToDisplayList
ifdef SMARTFOLDERS
		BitClr	ds:[di].FOI_positionFlags, FIPF_POSITIONED
		cmp	ss:[positioned], BB_TRUE
		jne	notPositioned
		BitSet	ds:[di].FOI_positionFlags, FIPF_POSITIONED
notPositioned:
endif

		pop	bx			; retrieve VM info for closing
		call	ShellCloseDirInfo


	;
	; Icons on the desktop save their positions as a percentage of
	; the sceen size.  We need to convert these percentages back
	; to positions when the sceen size is known (FolderFixLayout.)
	;

ND <		cmp	ds:[di].NDFOI_ndObjType, WOT_DESKTOP		>
ND <		jne	done						>
ND <		BitSet	ds:[di].FOI_positionFlags, FIPF_PERCENTAGES	>

done:

	;
	; Now have each FolderRecord that didn't have positioning
	; information in the dirinfo file find a place for itself
	; between the other positioned icons.
	;
		BitSet	ds:[di].FOI_positionFlags, FIPF_RECALC

		.leave
		ret

FolderLoadDirInfo	endp




COMMENT @-------------------------------------------------------------------
			FolderPlaceUnpositionedIcons
----------------------------------------------------------------------------

DESCRIPTION:	Finds an unobstructed place for all icons marked as
		having no position.

CALLED BY:	FolderFixLayout

PASS:		*ds:si - FolderClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/2/92		Initial version

---------------------------------------------------------------------------@
FolderPlaceUnpositionedIcons	proc	near
GM <		class	FolderClass					>
ND <		class	NDFolderClass					>

		uses	ax, bx, cx, dx, di, bp

		.enter

if _NEWDESK
	;
	; Place any unpositioned "special" icons first.  This involves
	; looking up their positions, as percentages, in a lookup
	; table.  Only do this if the folder sort mode is FIDS_NAME!
	;
		DerefFolderObject	ds, si, di
		cmp	ds:[di].NDFOI_ndObjType, WOT_DESKTOP
		jne	afterDesktop

		test	ds:[di].FOI_displaySort, mask FIDS_NAME
		jz	afterDesktop

	;
	; In NAMES or NAMES & DETAILS mode, bail on this positioning
	; stuff.
	;

		test	ds:[di].FOI_displayMode, mask FIDM_SHORT or \
				mask FIDM_FULL
		jnz	afterDesktop

	;
	; If the desktop is unpositioned, ie, is sorted by name, then
	; mark all the folder records unpositioned now, so that
	; they'll properly placed after a recalc.
	;
		
		test	ds:[di].FOI_positionFlags, mask FIPF_POSITIONED
		jnz	afterMark

		mov	ax, SEGMENT_CS
		mov	bx, offset markUnpositionedCB
		call	FolderSendToDisplayList

	;
	; Place the "special" icons, first, and then place the rest of them
	;
afterMark:
		movP	cxdx, ds:[di].FOI_winBounds
		mov	ax, SEGMENT_CS		; this is in FolderCode for now
		mov	bx, offset FolderRecordPlaceIfSpecial
		mov	di, FCT_UNPOSITIONED
		call	FolderSendToChildren
		jmp	placeUnpositioned

	;
	; If the folder is positioned, then find empty slots in which
	; to stick the unpositioned kids.  Otherwise, place all kids
	; "geomanager" style.
	;
afterDesktop:
		test	ds:[di].FOI_positionFlags, mask FIPF_POSITIONED
		jz	geoManagerStyle

placeUnpositioned:
		mov	ax, SEGMENT_CS
		mov	bx, offset FolderCode:FolderRecordFindEmptySlot
		mov	di, FCT_UNPOSITIONED
		call	FolderSendToChildren
		jmp	done

geoManagerStyle:
endif		; if _NEWDESK

		call	FolderPlaceIconsGeoManagerStyle

ND <done:							>
		.leave
		ret

if _NEWDESK
markUnpositionedCB:
	; callback routine -- mark each folder record unpositioned
	; ds:di - FolderRecord
	;
		ornf	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		retf
endif		; if _NEWDESK
		
FolderPlaceUnpositionedIcons	endp



COMMENT @-------------------------------------------------------------------
			FolderSaveIconPositions
----------------------------------------------------------------------------

DESCRIPTION:	Saves out any directory information.
		Currently this includes icon positions only.

CALLED BY:	EXTERNAL - 
			FolderViewWinClosed, FolderClosed,
			FolderRescan, FolderSetDisplayOptions

PASS:		*ds:si	= FolderClass object
		ds:di - FolderClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/13/92		Initial version

---------------------------------------------------------------------------@
FolderSaveIconPositions	method	dynamic FolderClass,	
					MSG_FOLDER_SAVE_ICON_POSITIONS
		uses	ax, cx, dx, bp

		.enter

BA <		call	UtilAreWeInEntryLevel?				>
BA <		jc	done						>

	;
	; If the folder isn't positioned, then delete it instead of
	; opening it
	;
		test	ds:[di].FOI_positionFlags, mask FIPF_POSITIONED
		jz	deleteFile

	;
	; If the folder is positioned, but isn't dirty, then don't
	; bother saving the info
	;

		test	ds:[di].FOI_positionFlags, mask FIPF_DIRTY
		jz	done
		andnf	ds:[di].FOI_positionFlags, not mask FIPF_DIRTY

	;
	; Otherwise, open the file
	;

		mov	ax, MSG_FOLDER_SET_CUR_PATH
		call	ObjCallInstanceNoLock 
		jc	done

		call	UtilCheckWriteDirInfo
		jc	done

		push	ds, si			; *ds:si - folder
NOFXIP<		segmov	ds, dgroup					>
FXIP	<	mov	dx, bx						>
FXIP	<	GetResourceSegmentNS dgroup, ds, TRASH_BX		>
FXIP	<	mov	bx, dx						>
		mov	dx, offset dirinfoFilename
		call	ShellCreateDirInfo
		movdw	dxcx, dssi		; *dx:cx = dirinfo chunk array
		pop	ds, si			; *ds:si - folder

		jc	done			; unable to open file
		
		push	bx, bp

		mov	bx, offset FolderRecordSavePosition
		mov	ax, SEGMENT_CS		; ax:bx = callback routine
		call	FolderSendToDisplayList

		pop	bx, bp
		call	VMDirty
		call	ShellCloseDirInfo

done:
		.leave
		ret

	;
	; Delete the file, if it exists.
	;
		
deleteFile:
ifdef SMARTFOLDERS
		test	ds:[di].FOI_positionFlags, mask FIPF_WIN_SAVED
		jnz	done
endif
		call	FolderSeeIfDirInfoFileExists	; dx <- filename offset
		jnc	done

		mov	ax, MSG_FOLDER_SET_CUR_PATH
		call	ObjCallInstanceNoLock 
		jc	done

NOFXIP<		segmov	ds, dgroup					>
FXIP	<	mov	ax, bx						>
FXIP	<	GetResourceSegmentNS dgroup, ds, TRASH_BX		>
FXIP	<	mov	bx, ax						>
		call	FileDelete
		jmp	done

FolderSaveIconPositions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSeeIfDirInfoFileExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Since we already have a FolderBuffer full of all the
		files in this directory, search this buffer for the
		dirinfo file, rather than going to disk, since most of
		the time it won't be there.

CALLED BY:	FolderSaveIconPositions, FolderOpenDirInfo

PASS:		nothing 

RETURN:		carry SET if file exists, carry CLEAR otherwise
		dx - offset of dirinfo filename

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/21/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSeeIfDirInfoFileExists	proc near
		uses	ax,bx,di
		.enter

		mov	dx, offset dirinfoFilename
		mov	ax, SEGMENT_CS
		mov	bx, offset FolderFindFilenameCB
		mov	di, FCT_ALL
		call	FolderSendToChildren

		.leave
		ret
FolderSeeIfDirInfoFileExists	endp



COMMENT @-------------------------------------------------------------------
			FolderGetIconAreaSize
----------------------------------------------------------------------------

DESCRIPTION:	Returns the size of the area that icons are allowed to
		position themselves in.  The icon area is as wide as
		the view, unless there are scroll bars, in which case
		it is as wide as the document. 

CALLED BY:	INTERNAL - FolderRecordFindEmptySlot

PASS:		*ds:si - FolderClass object

RETURN:		cx	= view width
		dx	= view height

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/2/92		Initial version

---------------------------------------------------------------------------@
FolderCalcIconAreaSize	proc	near
		class	FolderClass
		uses	di
		
		.enter

		DerefFolderObject	ds, si, di

		movP	cxdx, ds:[di].FOI_docBounds
		cmp	cx, ds:[di].FOI_winBounds.P_x
		jge	gotWidth
		mov	cx, ds:[di].FOI_winBounds.P_x

gotWidth:
ifdef GPC
		cmp	dx, ds:[di].FOI_winBounds.P_y
		jge	gotHeight
		mov	dx, ds:[di].FOI_winBounds.P_y
gotHeight:
endif
		.leave
		ret
FolderCalcIconAreaSize	endp



COMMENT @-------------------------------------------------------------------
			FolderCheckForIconInRect
----------------------------------------------------------------------------

DESCRIPTION:	Checks whether an icon occupies the given rectangle.

CALLED BY:	INTERNAL - FolderRecordFindEmptySlot

PASS:		ax,bx,cx,dx	= bounds of region to check
		*ds:si		= FolderClass object
		es		= locked folder buffer

RETURN:		CARRY SET if an object overlaps given region
		CARRY CLEAR  if no object overlaps given region

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/9/92		Initial version

---------------------------------------------------------------------------@
FolderCheckForIconInRect	proc	near

rect		local	Rectangle	push	dx, cx, bx, ax

		uses	ax, cx, dx

		.enter
		
	;
	; Check the middle, first, as this will usually catch it if
	; there's something there.
	;

		mov	cx, rect.R_left
		add	cx, rect.R_right
		shr	cx
		
		mov	dx, rect.R_top
		add	dx, rect.R_bottom
		shr	dx

		mov	ax, FALSE
		call	GetFolderObjectClicked
		jc	done
		
		
		mov	cx, rect.R_right
		mov	dx, rect.R_bottom
		call	GetFolderObjectClicked	; check bottom-right
		jc	done

		mov	cx, rect.R_left
		call	GetFolderObjectClicked	; check bottom-left
		jc	done

		mov	dx, rect.R_top
		call	GetFolderObjectClicked	; check top-left
		jc	done

		mov	cx, rect.R_right
		call	GetFolderObjectClicked	; check top-right

done:
		.leave
		ret
FolderCheckForIconInRect	endp

if _NEWDESK


COMMENT @-------------------------------------------------------------------
			FolderConvertPercentagesToPositions
----------------------------------------------------------------------------

DESCRIPTION:	Builds icon positions from percentages for those files
		that are positioned.

CALLED BY:	INTERNAL - FolderFixLayout

PASS:		*ds:si - FolderClass object

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/25/92	Initial version

---------------------------------------------------------------------------@
FolderConvertPercentagesToPositions	proc	near
		class	FolderClass

		.enter

		mov	ax, SEGMENT_CS
		mov	bx, offset FolderRecordConvertPercentageToPositionCB
		mov	di, FCT_POSITIONED
		call	FolderSendToChildren

		DerefFolderObject	ds, si, di
		BitClr	ds:[di].FOI_positionFlags, FIPF_PERCENTAGES

		.leave
		ret
FolderConvertPercentagesToPositions	endp





COMMENT @-------------------------------------------------------------------
		FolderRecordConvertPercentageToPositionCB
----------------------------------------------------------------------------

DESCRIPTION:	Converts the position information of the given
		FolderRecord from a percentage of the given view size
		to a document coordinate. 

CALLED BY:	FolderConvertPercentagesToPositions via FolderSendToChildren

PASS:		ds:di	= FolderRecord

RETURN:		carry clear

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/16/92	Initial version
	eric	1/30/93		Updated for new high-precision % value,
				added round-up support

---------------------------------------------------------------------------@

FolderRecordConvertPercentageToPositionCB	proc	far

		.enter

		test	ds:[di].FR_state, mask FRSF_PERCENTAGE
		jz	done

		andnf	ds:[di].FR_state, not mask FRSF_PERCENTAGE
		mov	cx, ds:[di].FR_iconBounds.R_left
		mov	dx, ds:[di].FR_iconBounds.R_top
		call	FolderRecordSetPositionAsPercentage
done:
		
		clc
		.leave
		ret
FolderRecordConvertPercentageToPositionCB	endp

endif		; if _NEWDESK

FolderCode	ends


FolderAction	segment



COMMENT @-------------------------------------------------------------------
			FolderRepositionIcons
----------------------------------------------------------------------------

DESCRIPTION:	Moves an icon(s) within a folder, and updates video
		without a rescan.

CALLED BY:	INTERNAL - FolderEndMoveCopy

PASS:		bx:ax	= Quick Transfer (VM file):(VM block)
		*ds:si - FolderClass object
		cx, dx	= mouse position
		es	= segment of FolderClass

RETURN:		
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
	1) Figures out which icon to reposition within the folder
	   (the selected group of icons, or a single icon under the cursor)
	2) Calls the appropriate routine to move the icon(s)
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/ 9/92		Initial version

---------------------------------------------------------------------------@
if _NEWDESK
FolderRepositionIcons	proc	near

		class	FolderClass
		uses	ds, es, ax, bp
		.enter

	;
	; Bail if not in large icon mode
	;
		DerefFolderObject	ds, si, di
		test	ds:[di].FOI_displayMode, mask FIDM_LICON
		LONG jz	exit

		push	ax, bx, dx, si, di
		
	;
	; Suspend the folder's window, so that we don't get an exposed
	; event before the MSG_META_CONTENT_VIEW_SIZE_CHANGED arrives
	;
		mov	di, ds:[di].DVI_window
		call	WinSuspendUpdate
		
	;
	; Clear the selection in the sort-by list.
	;
		

		mov	bx, handle GlobalMenuDisplaySortByList
		mov	si, offset GlobalMenuDisplaySortByList
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		clr	dx, di
		call	ObjMessage

afterCleared::
		pop	ax, bx, dx, si, di

		
		DerefFolderObject	ds, si, di
		ornf	ds:[di].FOI_positionFlags, mask FIPF_DIRTY	\
					or mask FIPF_POSITIONED

	 	sub	cx, ss:[lastMousePosition].P_x
		sub	dx, ss:[lastMousePosition].P_y

		call	VMLock		; pass:	   bx:ax = (VM file):(VM block)
					; returns: ax = segment, bp =
					; mem handle
		mov	es, ax		; es:0 = top of VM block


		cmp	es:[FQTH_numFiles], 1	; only one icon to be moved?
		call	VMUnlock		; pass: bp = mem handle
						; note: flags not affected
		pushf
		call	FolderLockBuffer
		popf
		mov	bp, ds:[di].DVI_gState
		jne	useSelectedList		; use selected list if more
						; than one icon to be moved.

		mov	ax, TRUE
 		xchg	cx, ss:[lastMousePosition].P_x
 		xchg	dx, ss:[lastMousePosition].P_y
		call	GetFolderObjectClicked		; returns: es:di =
							; folder record
		jnc	done

	 	xchg	cx, ss:[lastMousePosition].P_x
 		xchg	dx, ss:[lastMousePosition].P_y
		call	FolderRepositionSingleIcon
done:
		call	FolderRecalcDocBounds
		call	FolderUnlockBuffer

	;
	; Unsuspend the window, making sure the message arrives AFTER
	; the MSG_META_CONTENT_VIEW_SIZE_CHANGED.  Boy this is fun!
	;
		
		mov	ax, MSG_FOLDER_UNSUSPEND_WINDOW
		mov	di, mask MF_FORCE_QUEUE
		mov	bx, ds:[LMBH_handle]
		call	ObjMessage
exit:
		.leave
		ret

useSelectedList:
		mov	di, ds:[di].FOI_selectList
	
continue:
		cmp	di, NIL
		je	done
		call	FolderRepositionSingleIcon
		mov	di, es:[di].FR_selectNext
		jmp	continue	

FolderRepositionIcons	endp

endif	; _NEWDESK


COMMENT @-------------------------------------------------------------------
			FolderRepositionSingleIcon
----------------------------------------------------------------------------

DESCRIPTION:	Moves a single icon within a window:
		updates proper variables, updates the document size if
		necessary, and forces a redraw

CALLED BY:	INTERNAL - FolderRepositionIcons

PASS:		*ds:si - FolderClass object
		es:di	= pointer to folder record
 		cx,dx	= offset from old icon position
		bp	= gState
		es:0	= segment of buffer containing folder records 

RETURN:		
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	1) erase icon at old position 
	2) calculate new position of icon
	3) draw icon at new position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/13/92		Initial version

---------------------------------------------------------------------------@
if _NEWDESK
FolderRepositionSingleIcon	proc	near

ifdef GPC
		class	NDFolderClass
else
		class	FolderClass
endif
		uses	cx, dx, di

		.enter

ND <		call	FolderDrawCursor	; erase old cursor	>

	;
	; if on desktop and beyond left or right, don't allow
	;
ifdef GPC
		DerefFolderObject	ds, si, bx
		cmp	ds:[bx].NDFOI_ndObjType, WOT_DESKTOP
		jne	notDesktop
		mov	ax, cx
		add	ax, es:[di].FR_boundBox.R_right
		cmp	ax, ds:[bx].FOI_winBounds.P_x
		jg	done
		mov	ax, dx
		add	ax, es:[di].FR_boundBox.R_bottom
		cmp	ax, ds:[bx].FOI_winBounds.P_y
		jg	done
notDesktop:
endif

		add	cx, es:[di].FR_iconBounds.R_left
		add	dx, es:[di].FR_iconBounds.R_top

	;
	; if either of the SIGN bits are set in the positions, then
	; this position is bogus, and don't allow it!
	;
		
		mov	ax, cx
		or	ax, dx
		js	done

		push	ds
		segmov	ds, es
		call	FolderRecordInvalRect
		call	FolderRecordSetPosition
		pop	ds

		mov	ax, mask DFI_DRAW
		call	DrawFolderObjectIcon
done:

ND <		call	FolderDrawCursor	; draw new cursor	>
		call	FolderObjectBringToTop	

		.leave
		ret
FolderRepositionSingleIcon	endp
endif

FolderAction	ends

FolderCode	segment resource




COMMENT @-------------------------------------------------------------------
			FolderRecalcDocBounds
----------------------------------------------------------------------------

DESCRIPTION:	Calculate the minimum document size needed to hold
		all icons within a given folder, and update the view
		with this information.

CALLED BY:	FolderFixLayout, FolderRepositionIcons

PASS:		*ds:si - FolderClass object

RETURN:		folderDocWidth, folderDocHeight	- updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/27/92		Initial version

---------------------------------------------------------------------------@
FolderRecalcDocBounds	proc	far
		class	FolderClass
		
		uses	cx, dx, di

		.enter
		
		DerefFolderObject	ds, si, di

	;
	; Calculate size of document, and set document size if needed.
	;
		push	ds:[di].FOI_docBounds.P_y
		push	ds:[di].FOI_docBounds.P_x

		clr	cx, dx
		mov	ax, SEGMENT_CS
		mov	bx, offset FolderCode:FolderRecalcDocBoundsCB
		call	FolderSendToDisplayList

		;
		; If either size is 0, set it to 1 so the darn scrollbars
		; will behave correctly (the draw huge if they have a
		; 0 -> 0 range) - brianc 6/18/93
		;
		tst	cx
		jnz	haveX
		mov	cx, 1
haveX:
		tst	dx
		jnz	haveY
		mov	dx, 1
haveY:

		mov	ax, MSG_FOLDER_SET_DOC_BOUNDS
		call	ObjCallInstanceNoLock

		DerefFolderObject	ds, si, di
		movP	cxdx, ds:[di].FOI_docBounds

	;
	; Compare new and old sizes.  If same, then bail
	;
		pop	ax		; old X
		pop	bx		; old Y
		cmp	ax, cx
		jne	changeSize
		cmp	bx, dx
		je	done

changeSize:
	;
	; since we changed the document size, clear old anchor point
	; as it could be off the document now.
	;

		mov     ds:[di].FOI_anchor.P_x, -1      ; no anchor

		push	si
		mov	bx, ds:[di].FOI_windowBlock	; bx:si = window's pane
		mov	si, FOLDER_VIEW_OFFSET
		mov	di, mask MF_FIXUP_DS
		call	GenViewSetSimpleBounds		; set document size
		pop	si

done:
		.leave
		ret

FolderRecalcDocBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRecalcDocBoundsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to recalc the document bounds

CALLED BY:	FolderRecalcDocBounds

PASS:		cx, dx - current document bounds

RETURN:		cx, dx, - updated
		CARRY CLEAR ALWAYS

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRecalcDocBoundsCB	proc far
		.enter

	;
	; if position not valid, skip
	;
		test	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		jnz	done	

		cmp	cx, ds:[di].FR_boundBox.R_right
		jge	wideEnough
		mov	cx, ds:[di].FR_boundBox.R_right

wideEnough:
		cmp	dx, ds:[di].FR_boundBox.R_bottom
		jge	done
		mov	dx, ds:[di].FR_boundBox.R_bottom

done:

		clc
		.leave
		ret
FolderRecalcDocBoundsCB	endp



FolderCode	ends

FolderAction	segment resource



COMMENT @-------------------------------------------------------------------
			FolderObjectBringToTop
----------------------------------------------------------------------------

DESCRIPTION:	Moves to given Folder Record to the end of the display
		list, so that it will be displayed on top of every
		other icon.

CALLED BY:	INTERNAL -
			FolderRepositionIcons

PASS:		*ds:si - FolderClass object
		es:di	= pointer to folder record

RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:	
	Not tested for the case when the given folder is not in display list.
	O(n) in all cases (goes through ENTIRE display list.)

	This is fine for single icon moves, but with multiple icons,
		performance degrades quickly... 
	Write new routine: FolderSelectedObjectsBringToTop

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/31/92		Initial version

---------------------------------------------------------------------------@
if _NEWDESK
FolderObjectBringToTop	proc	near

	class	FolderClass

	uses	bp


	.enter

	DerefFolderObject	ds, si, bp

	mov	ax, ds:[bp].FOI_displayList
	cmp	ax, NIL
	je	exit					; exit if no records

	cmp	ax, di
	jne	continue

	mov	ax, es:[di].FR_displayNext
	cmp	ax, NIL
	je	exit					; exit if only 1 record
	mov	bx, es:[di].FR_displayNext		; icon before ->

	mov	ds:[bp].FOI_displayList, bx		; 	icon after

continue:
	xchg	bx, ax					; bx = last record (ax)
continue2:
	mov	ax, es:[bx].FR_displayNext		; ax = next record
	cmp	ax, NIL
	je	done					; exit if last record
	cmp	ax, di
	jne	continue
	mov	ax, es:[di].FR_displayNext
	cmp	ax, NIL					; if already last,
	je	alreadyOnTop				;   do the right thing
	mov	es:[bx].FR_displayNext, ax		; icon before ->	
							; 	 icon after
alreadyOnTop:
	mov	bx, di
	jmp	continue2

done:
	mov	es:[bx].FR_displayNext, di		; last icon -> my icon
	mov	es:[di].FR_displayNext, ax		; ax = NIL
exit:
	.leave
	ret
FolderObjectBringToTop	endp

endif
FolderAction	ends

