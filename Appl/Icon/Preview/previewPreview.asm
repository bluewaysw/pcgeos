COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Preview	
FILE:		previewPreview.asm

AUTHOR:		Steve Yegge, Jul 30, 1992

ROUTINES:

Name					Description
----					-----------
DBViewerUpdatePreviewArea	- calls SetPreviewMonikers with current icon
DBViewerSetPreviewObject	- sets-usable a single preview object
SetAllUnusable			- sets all preview objects unusable
DBViewerApplyPreviewColorChanges- sets all preview objects to current colors
ChangePreviewObjectColors	- sets colors for a specific object
PreviewGetColorSelectorColors	- looks in dialog box for the colors
SetColorSelectorSelections	- sets color-dialog toolbox colors
SetPreviewMonikers		- sets the monikers
ResizeScrollingList		- they don't resize automatically...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/92		Initial revision

DESCRIPTION:

	This file contains the routines to allow the 'colors' dialog
	box to change its own colors and those of the preview objects.
	The preview objects are generic objects that you can place
	your icon into to see what it will look like, and for tools
	and triggers you can also change the background color to a
	mix of 2 VGA colors.


	$Id: previewPreview.asm,v 1.1 97/04/04 16:06:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

;-----------------------------------------------------------------------------
;
;  Here are the declarations necessary for creating a moniker
;  containing a reference to a bitmap on an lmem heap.
;
;-----------------------------------------------------------------------------
		
VMH2	label 	VisMoniker
		VisMoniker < <0,1,DAR_NORMAL,>, , >
		
VMGS2	label	VisMonikerGString
		VisMonikerGString < >
		GSBeginString			; takes no space
		
OPDB	label	OpDrawBitmapOptr
		OpDrawBitmapOptr <,0,0,0>
		
		GSEndString
VMH2_SIZE	equ $ - VMH2

idata	ends

PreviewCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerUpdatePreviewArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the monikers of the preview objects to the current bitmap

CALLED BY:	MSG_DB_VIEWER_UPDATE_PREVIEW_AREA

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	One thing we have to do is make sure the scrolling item group
	is the right height & width (since it refuses to resize itself
	to fit its children's monikers.)  We calculate how big it
	should be and send it a MSG_GEN_SET_FIXED_SIZE.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/ 1/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerUpdatePreviewArea	proc	far
		uses	ax,bx,cx,dx,si,di
		.enter
		
		push	si
		mov	bx, ds:[LMBH_handle]
		mov	si, offset BMO
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
		call	ObjMessage			; returns ^vcx:dx
		pop	si
		
		call	SetPreviewMonikers
		
		.leave
		ret
DBViewerUpdatePreviewArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSetPreviewObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set-enabled the desired preview object and disable others.

CALLED BY:	MSG_DB_VIEWER_SET_PREVIEW_OBJECT

PASS:		es = dgroup
		cx = object type (PreviewGroupInteractionObject)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Sets the currently displayed preview object to whatever menu
	selection was returned in cx.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSetPreviewObject	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  First set all the other children unusable.  Of course later 
	;  when the database is implemented I'll just check to see 
	;  which one we're currently viewing and disable that one.
	;
		call	SetAllUnusable
	;
	; set up for a call to ObjMessage
	;
		mov	ax, MSG_GEN_SET_USABLE
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
	;
	;  Now set-usable the appropriate selection
	;
		mov	bx, cx				; offset into table
		mov	bx, cs:[objectTable][bx]
		jmp	bx
		
objectTable	nptr	trigger,
		tool,
		scrollableList,
		bulletedList
		
trigger:
		GetResourceHandleNS	TriggerGroup, bx
		mov	si, offset	TriggerGroup
		jmp	short	done
tool:
		GetResourceHandleNS	ToolGroup, bx
		mov	si, offset	ToolGroup
		jmp	short	done
scrollableList:
		GetResourceHandleNS	ScrollableListGroup, bx
		mov	si, offset	ScrollableListGroup
		jmp	short	done
bulletedList:
		GetResourceHandleNS	BulletedListGroup, bx
		mov	si, offset	BulletedListGroup
		jmp	short	done
		
done:
		call	ObjMessage			; set-usable the object
		
		.leave
		ret
DBViewerSetPreviewObject endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAllUnusable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets all the children of the preview group unusable

CALLED BY:	PreviewSetPreviewObject, FindIcon
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- sets all 4 groups unusable
 
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetAllUnusable	proc	near
		uses	ax,bx,cx,dx,si,di
		.enter
		
		GetResourceHandleNS	TriggerGroup, bx
		mov	si, offset	TriggerGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjMessage
		
		GetResourceHandleNS	ToolGroup, bx
		mov	si, offset	ToolGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjMessage
		
		GetResourceHandleNS	ScrollableListGroup, bx
		mov	si, offset	ScrollableListGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjMessage
		
		GetResourceHandleNS	BulletedListGroup,bx
		mov	si, offset	BulletedListGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		call	ObjMessage
		
		.leave
		ret
SetAllUnusable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerApplyPreviewColorChanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Applies the color changes to all preview objects.

CALLED BY:	MSG_DB_VIEWER_APPLY_PREVIEW_COLOR_CHANGES

PASS:		*ds:si	= DBViewerObject
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This message is called when the user selects a new color
	from one of the color selectors in the preview dialog.

	We want to save their changes into the database, so we
	call the dirty-database routine, and then change the
	colors in the preview objects.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerApplyPreviewColorChanges	proc	far
		uses	ax, cx, dx, bp
		.enter
		
		mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
		call	ObjCallInstanceNoLock

		mov	ax, MSG_DB_VIEWER_MARK_ICON_DIRTY
		call	ObjCallInstanceNoLock
		
		call	ChangePreviewObjectColors
		
		.leave
		ret
DBViewerApplyPreviewColorChanges	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangePreviewObjectColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the colors for all the preview objects.

CALLED BY:	GLOBAL

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	This routine changes the BackgroundColors struct information in
	all of the preview objects, enabled or no.

	First we call a helper routine that puts the current selections
	from the Preview Colors dialog box into cx and dx:
		ch = selected ("on") color 1
		cl = selected ("on") color 2
		dh = unselected ("off") color 1
		dl = unselected ("off") color 2

	Then we call the message defined for each of the color-generic
	objects that changes all 4 colors 
	(MSG_DB_VIEWER_COLOR_<BLAH>_SET_ALL_COLORS)
	for each of the preview objects.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangePreviewObjectColors	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  First get all 4 colors into ch, cl, dh, dl.
	;
		call	PreviewGetColorSelectorColors
		push	cx, dx				; save the colors	
	;
	; Change off-trigger colors	(from dh and dl)
	;
		GetResourceHandleNS	Trigger1, bx
		mov	si, offset	Trigger1
		mov	bp, mask COCTS_ON_ONE or \
		mask COCTS_ON_TWO or \
		mask COCTS_OFF_ONE or \
		mask COCTS_OFF_TWO
		mov	ax, MSG_ICON_COLOR_TRIGGER_SET_COLORS
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; change tool colors
	;
		pop	cx, dx				; restore colors
		push	cx, dx				; save colors
		GetResourceHandleNS	Tool1, bx
		mov	si, offset	Tool1
		mov	bp, mask COCTS_ON_ONE or \
		mask COCTS_ON_TWO or \
		mask COCTS_OFF_ONE or \
		mask COCTS_OFF_TWO
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_COLOR_LIST_ITEM_SET_COLORS
		call	ObjMessage
		
		pop	cx, dx				; restore colors	
		push	cx, dx				; save colors
		GetResourceHandleNS	Tool2, bx
		mov	si, offset	Tool2
		mov	bp, mask COCTS_ON_ONE or \
		mask COCTS_ON_TWO or \
		mask COCTS_OFF_ONE or \
		mask COCTS_OFF_TWO
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_COLOR_LIST_ITEM_SET_COLORS
		call	ObjMessage
		
	;
	; Change scrollable-list item colors
	;
		pop	cx, dx					; restore colors
		push	cx, dx					; save colors
		GetResourceHandleNS	ScrollableListItem1, bx
		mov	si, offset	ScrollableListItem1
		mov	bp, mask COCTS_ON_ONE or \
		mask COCTS_ON_TWO or \
		mask COCTS_OFF_ONE or \
		mask COCTS_OFF_TWO
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_COLOR_LIST_ITEM_SET_COLORS
		call	ObjMessage
		
		pop	cx, dx					; restore colors
		push	cx, dx					; save colors
		GetResourceHandleNS	ScrollableListItem2, bx
		mov	si, offset	ScrollableListItem2
		mov	bp, mask COCTS_ON_ONE or \
		mask COCTS_ON_TWO or \
		mask COCTS_OFF_ONE or \
		mask COCTS_OFF_TWO
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_COLOR_LIST_ITEM_SET_COLORS
		call	ObjMessage
		
	;
	; Change bulleted list item colors
	;
		pop	cx, dx					; restore colors
		push	cx, dx					; save colors
		GetResourceHandleNS	BulletedListItem1, bx
		mov	si, offset	BulletedListItem1
		mov	bp, mask COCTS_ON_ONE or \
		mask COCTS_ON_TWO or \
		mask COCTS_OFF_ONE or \
		mask COCTS_OFF_TWO
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_COLOR_LIST_ITEM_SET_COLORS
		call	ObjMessage
		
		pop	cx, dx					; restore colors
		GetResourceHandleNS	BulletedListItem2, bx
		mov	si, offset	BulletedListItem2
		mov	bp, mask COCTS_ON_ONE or \
		mask COCTS_ON_TWO or \
		mask COCTS_OFF_ONE or \
		mask COCTS_OFF_TWO
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_COLOR_LIST_ITEM_SET_COLORS
		call	ObjMessage
		
		.leave
		ret
ChangePreviewObjectColors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreviewGetColorSelectorColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the selections from the 4 color selectors into cx and dx

CALLED BY:	ApplyPreviewColorChanges, SavePreviewStuff

PASS:		nothing

RETURN:		ch = on color 1
		cl = on color 2
		dh = off color 1
		dl = off color 2

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Sends a MSG_GEN_ITEM_GROUP_GET_SELECTION to each of the color
	selectors.  That method nukes cx, dx and bp, and returns the
	selection in ax.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PreviewGetColorSelectorColors	proc	far
		uses	ax,bx,si,di,bp
		.enter
		
		GetResourceHandleNS	OnColorSelector1, bx
		mov	si, offset	OnColorSelector1
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage
		push	ax				; save on-color 1
		
		GetResourceHandleNS	OnColorSelector2, bx
		mov	si, offset	OnColorSelector2
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage
		push	ax				; save on-color 2
		
		GetResourceHandleNS	OffColorSelector1, bx
		mov	si, offset	OffColorSelector1
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage
		push	ax				; save off-color 1
		
		GetResourceHandleNS	OffColorSelector2, bx
		mov	si, offset	OffColorSelector2
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, mask MF_CALL
		call	ObjMessage
		
		mov	dl, al				; off-color 2
		pop	ax				; off-color 1
		mov	dh, al
		pop	ax				; on-color 2
		mov	cl, al
		pop	ax				; on-color 1
		mov	ch, al
		
		.leave
		ret
PreviewGetColorSelectorColors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetColorSelectorSelections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the color-selector selections to the new colors.

CALLED BY:	SetUpPreviewStuff

PASS:		ax = on colorPair
		bx = off colorPair

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetColorSelectorSelections	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Set the selections in the color-selectors (ax = on, bp = off)
	;
		push	ax, bx			; save colors
		GetResourceHandleNS	OnColorSelector1, bx
		mov	si, offset	OnColorSelector1	
		mov	di, mask MF_CALL
		clrdw	cxdx
		mov	cl, al
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjMessage		; nukes ax, cx, dx, bp
		
		pop	ax, bx			; restore on & off colors
		push	bx			; save off colors
		GetResourceHandleNS	OnColorSelector2, bx
		mov	si, offset	OnColorSelector2
		mov	di, mask MF_CALL
		clrdw	cxdx
		mov	cl, ah			; cl <- color
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjMessage
	;
	;  Set OffColorSelectors
	;
		pop	ax			; restore off colors
		push	ax			; ...and save them
		mov	di, mask MF_CALL
		clrdw	cxdx			; not indeterminate
		mov	cl, al
		GetResourceHandleNS	OffColorSelector1, bx
		mov	si, offset	OffColorSelector1
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjMessage
		
		pop	ax			; restore off colors
		GetResourceHandleNS	OffColorSelector2, bx
		mov	si, offset	OffColorSelector2
		mov	di, mask MF_CALL
		clrdw	cxdx			; not indeterminate
		mov	cl, ah			; cl <- color
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjMessage
		
		.leave
		ret
SetColorSelectorSelections	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPreviewMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a bitmap and sets it as the moniker for all the
		preview objects.

CALLED BY:	GLOBAL

PASS:		*ds:si	= DBViewer object
		cx = vm file handle for bitmap
		dx = vm chain for bitmap (block handle)

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	In order to avoid having multiple copies of a big moniker in
	memory (potentially up to 64k per moniker), we have a special
	moniker defined in idata which contains an optr to a bitmap
	in an lmem heap somewhere.  This allows all the places where
	we're using the bitmap in a moniker to be pointing back to
	the original bitmap.  

	Note that we before we can free the old bitmap block, we have
	to change all the monikers to point to the new bitmap block,
	or there could be synchronization problems.

	We also have to resize the scrolling list correctly for the
	new moniker.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPreviewMonikers	proc	far
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		call	ResizeScrollingList
	;
	;  Turn the huge-bitmap into a regular bitmap in its own chunk
	;  in an lmem heap.  (optr = ^lcx:dx)
	;
		mov	bx, es:[OPDB].ODBOP_optr.handle	; get old bitmap block
		
		push	cx, dx			; save huge bitmap
		call	HugeBitmapToSimpleBitmap
		LONG	jc	errorPop2

		mov	es:[OPDB].ODBOP_optr.handle, cx ; optr to simple bitmap
		mov	es:[OPDB].ODBOP_optr.chunk, dx
		
		pop	cx, dx			; restore bitmap
		push	bx			; save ye olde block handle
		call	HugeBitmapGetFormatAndDimensions
	;
	;  Use the grabbed width & height for the cached size of the
	;  moniker, as well as in the ReplaceVisMonikerFrame.  Also
	;  set the DisplayClass for the moniker, based on the BMFormat.
	;
		mov	es:[VMH2].VM_width, cx
		mov	es:[VMGS2].VMGS_height, dx
		andnf	es:[VMH2].VM_type, not mask VMT_GS_COLOR
		cmp	al, BMF_MONO
		je	monochrome
		cmp	al, BMF_4BIT
		je	fourBit
		ornf	es:[VMH2].VM_type, DC_COLOR_8
		jmp	short	replaceTheDangThang
fourBit:
		ornf	es:[VMH2].VM_type, DC_COLOR_4
		jmp	short	replaceTheDangThang
monochrome:
		ornf	es:[VMH2].VM_type, DC_GRAY_1
		
replaceTheDangThang:
	;
	;  Set up the stack frame for all the following calls...
	;
		sub	sp, size ReplaceVisMonikerFrame
		mov	bp, sp
		mov	ss:[bp].RVMF_sourceType, VMST_FPTR
		mov	ss:[bp].RVMF_source.segment, es
		mov	ss:[bp].RVMF_source.offset, offset VMH2
		mov	ss:[bp].RVMF_dataType, VMDT_VIS_MONIKER
		mov	ss:[bp].RVMF_width, cx
		mov	ss:[bp].RVMF_height, dx
		mov	ss:[bp].RVMF_length, VMH2_SIZE
		mov	ss:[bp].RVMF_updateMode, VUM_NOW
	;
	;  replace the moniker of the TRIGGER preview object(s)
	;
		push	bp				; save stack frame
		GetResourceHandleNS	Trigger1, bx
		mov	si, offset	Trigger1
		mov	di, mask MF_CALL or mask MF_STACK
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	dx, size ReplaceVisMonikerFrame
		call	ObjMessage
		pop	bp				; restore stack frame
	;
	;  replace the moniker of the TOOL preview object(s)
	;
		push	bp
		GetResourceHandleNS	Tool1, bx
		mov	si, offset	Tool1
		mov	di, mask MF_CALL or mask MF_STACK 
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	dx, size ReplaceVisMonikerFrame
		call	ObjMessage
		pop	bp
		
		push	bp				; save locals
		GetResourceHandleNS	Tool2, bx
		mov	si, offset	Tool2
		mov	di, mask MF_CALL or mask MF_STACK 
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	dx, size ReplaceVisMonikerFrame
		call	ObjMessage
		pop	bp				; restore locals
	;
	;  replace the moniker of the SCROLLABLE LIST preview object(s)
	;
		push	bp
		GetResourceHandleNS	ScrollableListItem1, bx
		mov	si, offset	ScrollableListItem1
		mov	di, mask MF_CALL or mask MF_STACK 
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	dx, size ReplaceVisMonikerFrame
		call	ObjMessage
		pop	bp
		
		push	bp
		GetResourceHandleNS	ScrollableListItem2, bx
		mov	si, offset	ScrollableListItem2
		mov	di, mask MF_CALL or mask MF_STACK 
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	dx, size ReplaceVisMonikerFrame
		call	ObjMessage
		pop	bp
	;
	;  replace the moniker of the BULLETED LIST preview object(s)
	;
		push	bp
		GetResourceHandleNS	BulletedListItem1, bx
		mov	si, offset	BulletedListItem1
		mov	di, mask MF_CALL or mask MF_STACK 
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	dx, size ReplaceVisMonikerFrame
		call	ObjMessage
		pop	bp
		
		GetResourceHandleNS	BulletedListItem2, bx
		mov	si, offset	BulletedListItem2
		mov	di, mask MF_CALL or mask MF_STACK 
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	dx, size ReplaceVisMonikerFrame
		call	ObjMessage
		
		add	sp, size ReplaceVisMonikerFrame
		
	;
	;  Now that ALL the monikers are pointing to the new bitmap,
	;  we can free the old one.  If we had done it before, one
	;  of the objects might've tried to draw the old bitmap 
	;  during this routine (before it had been pointed to the
	;  new bitmap), and that would have been a Bad Thing.
	;
		pop	bx			; restore the old bitmap
		tst	bx
		jz	dontFreeHandle
		call	MemFree			; free the old lmem heap
dontFreeHandle:
done:
		.leave
		ret
errorPop2:
		pop	ax, ax
		jmp	done
SetPreviewMonikers	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeScrollingList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_GEN_SET_FIXED_SIZE to the scrolling list.

CALLED BY:	SetPreviewMonikers

PASS:		^vcx:dx = bitmap

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/28/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResizeScrollingList	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Set the scrolling list's size.
	;
		call	HugeBitmapGetFormatAndDimensions
		shl	cx			; cx = cx * 2 (2 children)
		
		sub	sp, size SetSizeArgs
		mov	bp, sp
		mov	ss:[bp].SSA_width, cx
		mov	ss:[bp].SSA_height, dx
		mov	ss:[bp].SSA_count, 2
		mov	ss:[bp].SSA_updateMode, VUM_NOW
		
		GetResourceHandleNS	ScrollableListGroup, bx
		mov	si, offset	ScrollableListGroup
		mov	di, mask MF_CALL or mask MF_STACK
		mov	ax, MSG_GEN_SET_FIXED_SIZE
		mov	dx, size SetSizeArgs
		call	ObjMessage
		
		add	sp, size SetSizeArgs
		
		.leave
		ret
ResizeScrollingList	endp


PreviewCode	ends
