COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Icon editor
MODULE:		Document
FILE:		documentSaveIcon.asm

AUTHOR:		Steve Yegge, Sep 11, 1992

ROUTINES:

Name				Description
----				-----------
SaveCurrentIcon			-- save current icon
SaveCurrentFormat		-- saves the current format into the database
SavePreviewStuff		-- save preview object & colors
SaveImageBitSize		-- saves current ImageBitSize into database
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/11/92		Initial revision

DESCRIPTION:
	
	This file contains routines for saving an icon.

	$Id: documentSaveIcon.asm,v 1.1 97/04/04 16:05:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocSaveIcon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveCurrentIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the current icon into the database

CALLED BY:	GLOBAL

PASS:		*ds:si	= DBViewer instance data
		ds:[di]	= DBViewer instance data

RETURN:		nothing
DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	This routine ONLY gets called by the document control, and
	that's about all the doc-control method does.  We take care
	of updating everybody from this routine (preview, format,
	transform, etc).

PSEUDO CODE/STRATEGY:

	- if no current icon, quit
	- save the current format
	- redraw the current format
	- save pertinent stuff into the database for the icon
	- update the preview area

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSaveCurrentIcon	method	dynamic	DBViewerClass,
					MSG_DB_VIEWER_SAVE_CURRENT_ICON
		uses	ax,cx,dx,bp
		.enter
		
		cmp	ds:[di].DBVI_currentIcon, NO_CURRENT_ICON
		je	done			; see if no current icon
	;
	;  Save the current bitmap into the database, and redraw it in 
	;  the format area.
	;
		mov	ax, MSG_DB_VIEWER_SAVE_CURRENT_FORMAT
		call	ObjCallInstanceNoLock
		mov	cx, ds:[di].DBVI_currentFormat
		
		push	ds:[LMBH_handle], si
		mov	si, offset FormatViewer
		mov	ax, MSG_FORMAT_CONTENT_REDRAW_FORMAT
		call	ObjCallInstanceNoLock
		pop	bx, si
		
		call	MemDerefDS		; *ds:si = DBViewer object
	;
	;  Save the preview settings.  Update format area and TF dialog,
	;  if it's on the screen.  Updating the TF dialog can take
	;  some time, so we might as well test to see if it's usable first.
	;
		call	SavePreviewStuff
	;
	;  Instead of entirely rescanning the database (which I
	;  used to do), I've created a new message to cause the
	;  currently-edited icon (if any) to redraw itself.
	;
		mov	ax, MSG_DB_VIEWER_REDRAW_CURRENT_ICON
		call	ObjCallInstanceNoLock
	;
	;  Update the preview area.
	;
		mov	ax, MSG_DB_VIEWER_UPDATE_PREVIEW_AREA
		call	ObjCallInstanceNoLock

		mov	ax, MSG_DB_VIEWER_INIT_CHANGE_ICON_DIALOG
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
DBViewerSaveCurrentIcon	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerSaveCurrentFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the currently-edited format into the database.

CALLED BY:	GLOBAL

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewer instance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the bitmap object's main bitmap
	- call SetFormat with it

	- delete the previously selected format

	(we used to delete the old one first, but it caused
	 some fairly serious barfing when the UI thread tried
	 to use the vm blocks that had just been freed).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerSaveCurrentFormat	method	dynamic	DBViewerClass,
					MSG_DB_VIEWER_SAVE_CURRENT_FORMAT
		uses	ax, cx, dx, bp
		.enter
	;
	;  Delete the current format (unless there's none selected)
	;
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		cmp	bx, NO_CURRENT_FORMAT
		je	done
	;	
	;  Get the BMO's main bitmap.
	;
		push	si				; save self
		mov	si, offset BMO
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
		call	ObjCallInstanceNoLock		; returns ^vcx:dx
		pop	si				; restore self
	;
	;  Set the bitmap as the current format, deleting the old one.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset
		
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bx, ds:[di].DBVI_currentFormat
		mov	bp, ds:[di].GDI_fileHandle
		call	IdClearAndSetFormat

		clr	ds:[di].DBVI_iconDirty
done:
		.leave
		ret
DBViewerSaveCurrentFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SavePreviewStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves preview object & colors for current icon

CALLED BY:	SaveCurrentIcon

PASS:		*ds:si	= DBViewer object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- get the preview object (from the menu selection)
	- save it in the current icon
	- get the preview colors (from the color selectors)
	- save them in the current icon

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SavePreviewStuff	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get the preview object and save it.
	;
		push	si
		GetResourceHandleNS	PreviewListGroup, bx
		mov	si, offset	PreviewListGroup
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	; returns in ax
		call	ObjMessage			; nukes cx, dx, bp
		pop	si
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		
		mov_tr	bx, ax				; bx <- preview object
		mov	ax, ds:[di].DBVI_currentIcon
		mov	bp, ds:[di].GDI_fileHandle
		call	IdSetPreviewObject
	;
	;  get the preview object's colors (since all of them have the
	;  same VarData--that is, the same colors--we can just ask
	;  any one of them for its colors.  I chose trigger1.)
	;
		push	si
		GetResourceHandleNS	Trigger1, bx
		mov	si, offset	Trigger1
		mov	di, mask MF_CALL
		mov	ax, MSG_ICON_COLOR_TRIGGER_GET_COLORS	; preserves bp
		call	ObjMessage		; returns in colors cx & dx
		pop	si
		
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		
		mov	ax, ds:[di].DBVI_currentIcon
		call	IdSetPreviewColors
		
		.leave
		ret
SavePreviewStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerRedrawCurrentIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw one vis-icon (same number as DBVI_currentIcon).

CALLED BY:	MSG_DB_VIEWER_REDRAW_CURRENT_ICON

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	6/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerRedrawCurrentIcon	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_REDRAW_CURRENT_ICON
		uses	ax, cx, dx, bp
		.enter
	;
	;  Find the appropriate vis-icon.
	;
		mov	cx, ds:[di].DBVI_currentIcon
		jcxz	done

		mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
		call	ObjCallInstanceNoLock		; ^lcx:dx = child
		jc	done				; not found
	;
	;  Tell the appropriate vis-icon to redraw its puny self.
	;
		movdw	bxsi, cxdx
		clr	di
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjMessage
done:
		.leave
		ret
DBViewerRedrawCurrentIcon	endm
		
		
DocSaveIcon	ends
