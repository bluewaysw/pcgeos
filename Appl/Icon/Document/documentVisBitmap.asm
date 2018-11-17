COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Icon	
FILE:		documentVisBitmap.asm

AUTHOR:		Steve Yegge, Aug 18, 1992

ROUTINES:

Name					Description
----					-----------
InvalidateDatabaseViewer		-- empties database viewer (no icons)

MESSAGE HANDLERS:

Name					Description
----					-----------
MSG_DB_VIEWER_SET_AREA_COLOR
MSG_DB_VIEWER_SET_LINE_COLOR
MSG_DB_VIEWER_SET_LINE_WIDTH
MSG_DB_VIEWER_SET_TEXT_COLOR
MSG_VIS_BITMAP_EDIT_BITMAP
MSG_DB_VIEWER_BITMAP_GET_COLOR_SCHEME

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/18/92		Initial revision

DESCRIPTION:
	
	This file has routines for letting the tools interact with
	the VisBitmap object.  This file will probably be replaced
	by color and line controllers written by Jon.

	This file also has stuff for the sublassed VisBitmap. (IconBitmap)

	$Id: documentVisBitmap.asm,v 1.1 97/04/04 16:05:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapEditBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Indicates that the icon has been dirtied from a user edit.

CALLED BY:	MSG_VIS_BITMAP_EDIT_BITMAP

PASS:		ss:[bp] - VisBitmapEditBitmapParams

		ss:[bp].VBEBP_routine protocol should look like:

			PASS:	di - gstate
				ax,bx,cx,dx - as passed with
					      MSG_VIS_BITMAP_EDIT_BITMAP in
					      VisBitmapEditBitmapParams

			RETURN:	nothing

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

SIDE EFFECTS/IDEAS:

	This routine relies on the fact that the BMO is run by
	the process thread (and lives in the same block as the
	document object).  If you change this, send classed
	events to the app model instead of using ObjCallInstanceNoLock

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	9/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapEditBitmap	method dynamic IconBitmapClass, 
					MSG_VIS_BITMAP_EDIT_BITMAP
		uses	cx, dx, bp
		.enter
	;	
	;  Let the superclass do its little thing.
	;
		mov	di, offset IconBitmapClass
		call	ObjCallSuperNoLock
	;
	;  Mark the database as being dirty (this seems kinda slow,
	;  but I can't think of another way to do it).
	;
		mov	si, offset IconDBViewerTemplate
		mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
		call	ObjCallInstanceNoLock

		mov	ax, MSG_DB_VIEWER_MARK_ICON_DIRTY
		call	ObjCallInstanceNoLock
		
		.leave
		ret
IconBitmapEditBitmap	endm

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconFatbitsStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass the target on to the bitmap object.

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	= IconFatbitsClass object
		ds:di	= IconFatbitsClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconFatbitsStartSelect	method dynamic IconFatbitsClass, 
					MSG_META_START_SELECT
		.enter
	;
	;  Call our superclass ...
	;
		mov	di, offset IconFatbitsClass
		call	ObjCallSuperNoLock
	;
	;  Tell the bitmap object's view to grab the target.
	;
		mov	ax, MSG_DB_VIEWER_TRANSFER_TARGET
		mov	si, offset IconDBViewerTemplate
		call	ObjCallInstanceNoLock
		
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
IconFatbitsStartSelect	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGetColorScheme
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the color scheme for the current bitmap in the BMO.

CALLED BY:	MSG_DB_VIEWER_BITMAP_GET_COLOR_SCHEME

PASS:		*ds:si = bitmap object
		ds:di  = bitmap instance data
		
RETURN:		al = color scheme
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	10/23/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGetColorScheme	method IconBitmapClass,
					MSG_ICON_BITMAP_GET_COLOR_SCHEME
		uses	ax, dx, bp
		.enter
		
		mov	al, ds:[di].VBI_bmFormat
		
		.leave
		ret
IconBitmapGetColorScheme	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapSetFatbits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Manually sets the optr of the fatbits in instance data.

CALLED BY:	MSG_ICON_BITMAP_SET_FATBITS

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data
		^lcx:dx	= VisFatbits optr

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapSetFatbits	method dynamic IconBitmapClass, 
					MSG_ICON_BITMAP_SET_FATBITS
		
		mov	ds:[di].VBI_fatbits.handle, cx
		mov	ds:[di].VBI_fatbits.chunk, dx
		
		ret
IconBitmapSetFatbits	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapCreateTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	nukes the selection ants.

CALLED BY:	MSG_VIS_BITMAP_CREATE_TOOL
PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapCreateTool	method dynamic IconBitmapClass, 
					MSG_VIS_BITMAP_CREATE_TOOL
		uses	ax
		.enter
	;
	; release the mouse because when you switch from the selection 
	; ants to another tool the mouse does not get released which 
	; was causing an EC only fatal error in VisBitmapCreateTool
	;
		mov     bp, VBMMRT_RELEASE_MOUSE
		mov     ax, MSG_VIS_BITMAP_MOUSE_MANAGER
		call    ObjCallInstanceNoLock

		mov	ax, MSG_VIS_BITMAP_KILL_SELECTION_ANTS
		call	ObjCallInstanceNoLock
		
		.leave
		mov	di, offset IconBitmapClass
		GOTO	ObjCallSuperNoLock
IconBitmapCreateTool	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGetTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the 

CALLED BY:	MSG_ICON_BITMAP_GET_TOOL
PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data
		ds:bx	= IconBitmapClass object (same as *ds:si)
		es 	= segment of IconBitmapClass
		ax	= message #

RETURN:		cx:dx = class of tool
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGetTool	method dynamic IconBitmapClass, 
					MSG_ICON_BITMAP_GET_TOOL

		mov	bx, ds:[di].VBI_tool.handle
		mov	si, ds:[di].VBI_tool.chunk
		
		mov	di, mask MF_CALL
		mov	ax, MSG_META_GET_CLASS		; get tool's class
		call	ObjMessage			; cx:dx = class

		ret
IconBitmapGetTool	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IBMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bits.

CALLED BY:	MSG_META_INITIALIZE

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
IBMetaInitialize	method dynamic IconBitmapClass, 
					MSG_META_INITIALIZE
		.enter
	;
	;  Call super first.
	;
		mov	di, offset IconBitmapClass
		call	ObjCallSuperNoLock
	;
	;  Clear flag => never compact the bitmap.
	;	
		mov	di, ds:[si]
		add	di, ds:[di].VisBitmap_offset
		andnf	ds:[di].VBI_flags, not mask VBF_COMPACT_BITMAP

		.leave
		ret
IBMetaInitialize	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGoSetLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routes the message from the GrObj controller to the bitmap.

CALLED BY:	MSG_GOLAC_SET_LINE_WIDTH

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data
		dx:cx	= WWFixed line width

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGoSetLineWidth	method dynamic IconBitmapClass, 
					MSG_GO_SET_LINE_WIDTH
		uses	ax, cx, dx, bp
		.enter
	;
	;  Send a MSG_VIS_BITMAP_SET_LINE_WIDTH to self.
	;
		push	cx
		mov	cx, dx
		mov	ax, MSG_VIS_BITMAP_SET_LINE_WIDTH
		call	ObjCallInstanceNoLock
		pop	cx
	;
	;  Create a notification block to hold the current line
	;  attributes, and initialize it.
	;
		call	CreateLineAttrNotifyBlock	 ; es = segment
		jc	done				 ; no notification

		movwwf	es:[GNLAC_lineAttr].GOBLAE_width, dxcx

		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount		; initialize reference count
	;
	;  Send the notification.
	;
		mov	cx, GWNT_GROBJ_LINE_ATTR_CHANGE
		mov	dx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE
		call	BitmapSendNotificationLow
done:
		.leave
		ret
IconBitmapGoSetLineWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGoSetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	routes the message to self as MSG_VIS_BITMAP_SET_COLOR

CALLED BY:	MSG_GO_SET_AREA_COLOR

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data
		cl - r
		ch - g
		dl - b

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGoSetAreaColor	method dynamic IconBitmapClass, 
				MSG_GO_SET_AREA_COLOR
		uses	ax, cx, dx, bp
		.enter
	;
	;  Send a MSG_VIS_BITMAP_SET_AREA_COLOR
	;
		mov	dh, dl				; blue
		mov	dl, ch				; green
		mov	ch, CF_RGB

		mov	ax, MSG_VIS_BITMAP_SET_AREA_COLOR
		call	ObjCallInstanceNoLock
	;
	;  Create a notification block with area attributes.
	;
		call	CreateAreaAttrNotifyBlock	; es = segment
		jc	done				; don't notify

		mov	es:[GNAAC_areaAttr].GOBAAE_r, cl
		mov	es:[GNAAC_areaAttr].GOBAAE_g, dl
		mov	es:[GNAAC_areaAttr].GOBAAE_b, dh

		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount
	;
	;  Send the notification
	;
		mov	cx, GWNT_GROBJ_AREA_ATTR_CHANGE
		mov	dx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE
		call	BitmapSendNotificationLow
done:
		.leave
		ret
IconBitmapGoSetAreaColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGoSetLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends a MSG_VIS_BITMAP_SET_LINE_COLOR to self

CALLED BY:	MSG_ICON_BITMAP_GO_SET_LINE_COLOR

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data

		cl - r
		ch - g
		dl - b

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGoSetLineColor	method dynamic IconBitmapClass, 
					MSG_GO_SET_LINE_COLOR
		uses	ax, cx, dx, bp
		.enter
	;
	;  Send message to self, after munging the parameters.
	;
		mov	dh, dl				; blue
		mov	dl, ch				; green
		mov	ch, CF_RGB
		
		mov	ax, MSG_VIS_BITMAP_SET_LINE_COLOR
		call	ObjCallInstanceNoLock
	;
	;  Create a notification block with area attributes.
	;
		call	CreateLineAttrNotifyBlock	; es = segment
		jc	done				; don't notify

		mov	es:[GNLAC_lineAttr].GOBLAE_r, cl
		mov	es:[GNLAC_lineAttr].GOBLAE_g, dl
		mov	es:[GNLAC_lineAttr].GOBLAE_b, dh

		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount
	;
	;  Send the notification
	;
		mov	cx, GWNT_GROBJ_LINE_ATTR_CHANGE
		mov	dx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE
		call	BitmapSendNotificationLow
done:
		.leave
		ret
IconBitmapGoSetLineColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGoSetAreaPattern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the area pattern in the editing gstate.

CALLED BY:	MSG_GO_SET_AREA_PATTERN

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data
		cx	= GraphicPattern

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGoSetAreaPattern	method dynamic IconBitmapClass, 
					MSG_GO_SET_AREA_PATTERN
		uses	ax, cx, dx, bp
		.enter
	;
	;  Set the pattern in the main gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
		call	ObjCallInstanceNoLock

		mov	di, bp
		mov	ax, cx
		call	GrSetAreaPattern
	;
	;  Set the pattern in the screen gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_SCREEN_GSTATE
		call	ObjCallInstanceNoLock

		mov	di, bp
		mov	ax, cx
		call	GrSetAreaPattern
	;
	;  Set the pattern in the backup gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_BACKUP_GSTATE
		call	ObjCallInstanceNoLock

		mov	di, bp
		mov	ax, cx
		call	GrSetAreaPattern
	;
	;  Create the area-attr notification block and initialize it.
	;
		call	CreateAreaAttrNotifyBlock
		jc	done

		mov	{word}es:[GNAAC_areaAttr].GOBAAE_pattern, cx
		call	MemUnlock
		mov	ax, 1			; reference count
		call	MemInitRefCount
	;
	;  Send the notification
	;
		mov	cx, GWNT_GROBJ_AREA_ATTR_CHANGE
		mov	dx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE
		call	BitmapSendNotificationLow
done:
		.leave
		ret
IconBitmapGoSetAreaPattern	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGoSetAreaMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the area mask in our gstate

CALLED BY:	MSG_GO_SET_AREA_MASK

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data
		cl	= SystemDrawMask

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGoSetAreaMask	method dynamic IconBitmapClass, 
					MSG_GO_SET_AREA_MASK
		uses	ax, cx, dx, bp
		.enter
	;
	;  Set the mask in the main gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
		call	ObjCallInstanceNoLock		; bp = gstate

		mov	di, bp
		mov	al, cl				; SystemDrawMask
		call	GrSetAreaMask
	;
	;  Set the mask in the screen gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_SCREEN_GSTATE
		call	ObjCallInstanceNoLock

		mov	di, bp
		mov	al, cl
		call	GrSetAreaMask
	;
	;  Set the mask in the backup gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_BACKUP_GSTATE
		call	ObjCallInstanceNoLock

		mov	di, bp
		mov	al, cl
		call	GrSetAreaMask
	;
	;  Create the area-attributes notification block.
	;
		call	CreateAreaAttrNotifyBlock
		jc	done

		mov	es:[GNAAC_areaAttr].GOBAAE_mask, cl
		call	MemUnlock
		mov	ax, 1			; reference count
		call	MemInitRefCount
	;
	;  Send the notification.
	;
		mov	cx, GWNT_GROBJ_AREA_ATTR_CHANGE
		mov	dx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE
		call	BitmapSendNotificationLow
done:		
		.leave
		ret
IconBitmapGoSetAreaMask	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGoSetLineMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the line mask in our gstate.

CALLED BY:	MSG_GO_SET_LINE_MASK

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data
		cl	= SystemDrawMask

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGoSetLineMask	method dynamic IconBitmapClass, 
					MSG_GO_SET_LINE_MASK
		uses	ax, cx, dx, bp
		.enter
	;
	;  Set the mask in the main gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
		call	ObjCallInstanceNoLock		; bp = gstate

		mov	di, bp
		mov	al, cl
		call	GrSetLineMask
	;
	;  Set the mask in the screen gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_SCREEN_GSTATE
		call	ObjCallInstanceNoLock

		mov	di, bp
		mov	al, cl
		call	GrSetLineMask
	;
	;  Set the mask in the backup gstate.
	;
		mov	ax, MSG_VIS_BITMAP_GET_BACKUP_GSTATE
		call	ObjCallInstanceNoLock

		mov	di, bp
		mov	al, cl
		call	GrSetLineMask
	;
	;  Create the line-attributes notification block.
	;
		call	CreateLineAttrNotifyBlock
		jc	done

		mov	es:[GNLAC_lineAttr].GOBLAE_mask, cl
		call	MemUnlock
		mov	ax, 1			; reference count
		call	MemInitRefCount
	;
	;  Send the notification.
	;
		mov	cx, GWNT_GROBJ_LINE_ATTR_CHANGE
		mov	dx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE
		call	BitmapSendNotificationLow
done:		
		.leave
		ret
IconBitmapGoSetLineMask	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateLineAttrNotifyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates & initializes the notification block.

CALLED BY:	INTERNAL

PASS: 		*ds:si	= IconBitmap object

RETURN:		bx	= block handle
		es	= segment

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/ 7/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateLineAttrNotifyBlock	proc	near
		uses	ax,cx
		.enter
	
		mov	ax, size GrObjNotifyLineAttrChange
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jc	done
		mov	es, ax

		call	GetBitmapLineAttrs	; initializes notify block
		clc
done:	
		.leave
		ret
CreateLineAttrNotifyBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmapLineAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the current line attributes in the passed structure.

CALLED BY:	INTERNAL

PASS:		*ds:si	= IconBitmap object
		es	- points to GrObjNotifyLineAttrChange

RETURN:		GrObjNotifyLineAttrChange initialized

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/ 7/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitmapLineAttrs	proc	near
		class	VisBitmapClass
		uses	ax,bx,cx,dx,di,bp
		.enter
	;
	;  Get the line mask and store it.
	;
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
		call	ObjCallInstanceNoLock		; bp = gstate

		tst	bp
		jz	noGState

		xchg	di, bp
		mov	al, GMT_ENUM			; ask for SysDrawMask
		call	GrGetLineMask			; al = SysDrawMask
		mov	es:[GNLAC_lineAttr].GOBLAE_mask, al
	;
	;  Get the line join and end, and store them.
	;
		call	GrGetLineJoin
		mov	es:[GNLAC_lineAttr].GOBLAE_join, al
		call	GrGetLineEnd
		mov	es:[GNLAC_lineAttr].GOBLAE_end, al
	;
	;  Get the line width and store it.
	;
		call	GrGetLineWidth
		mov	es:[GNLAC_lineAttr].GOBLAE_width.WWF_int, dx
		clr	es:[GNLAC_lineAttr].GOBLAE_width.WWF_frac
	;
	;  Get the line color and store it.
	;
		call	GrGetLineColor
		mov	es:[GNLAC_lineAttr].GOBLAE_r, al
		mov	es:[GNLAC_lineAttr].GOBLAE_g, bl
		mov	es:[GNLAC_lineAttr].GOBLAE_b, bh

done:
		.leave
		ret

	;
	;  If we didn't get a gstate back, then mark all the diff bits
	;
noGState:
		mov es:[GNLAC_lineAttrDiffs], mask GrObjBaseLineAttrDiffs
		jmp	done
GetBitmapLineAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAreaAttrNotifyBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a notification block, initializes it, and returns
		it (locked).

CALLED BY:	INTERNAL

PASS:		*ds:si	= IconBitmap object

RETURN:		bx	= block handle
		es	= segment of locked block
		block	- initialized
		carry	- set if error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/ 7/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAreaAttrNotifyBlock	proc	near
		uses	ax,cx,dx,si,di,bp
		.enter
	
		mov	ax, size GrObjNotifyAreaAttrChange
		mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jc	done
		mov	es, ax

		call	GetBitmapAreaAttrs	; initializes notify block
		clc
done:	
		.leave
		ret
CreateAreaAttrNotifyBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBitmapAreaAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the GrObjNotifyAreaAttrChange structure

CALLED BY:	INTERNAL

PASS:		*ds:si	= IconBitmap object
		es	= GrObjNotifyAreaAttrChange structure

RETURN:		GrObjNotifyAreaAttrChange initialized

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/ 7/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBitmapAreaAttrs	proc	near
		class	VisBitmapClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Get the area mask and store it.
	;
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_GSTATE
		call	ObjCallInstanceNoLock		; bp = gstate

		tst	bp
		jz	noGState

		mov	di, bp
		mov	al, GMT_ENUM			; ask for SysDrawMask
		call	GrGetAreaMask			; al = SysDrawMask
		mov	es:[GNAAC_areaAttr].GOBAAE_mask, al
	;
	;  Get the pattern & store it.
	;
		call	GrGetAreaPattern
		mov	es:[GNAAC_areaAttr].GOBAAE_pattern.GP_type, al
		mov	es:[GNAAC_areaAttr].GOBAAE_pattern.GP_data, ah
	;
	;  Get the mix mode.
	;
		call	GrGetMixMode
		mov	es:[GNAAC_areaAttr].GOBAAE_drawMode, al
	;
	;  Get the area color and store it.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisBitmap_offset
		movdw	cxdx, ds:[di].VBI_gStateStuff.VBGSS_areaColor
		mov	es:[GNAAC_areaAttr].GOBAAE_r, cl
		mov	es:[GNAAC_areaAttr].GOBAAE_g, dl
		mov	es:[GNAAC_areaAttr].GOBAAE_b, dh

done:
		.leave
		ret

	;
	;  If we didn't get a gstate back, then mark all the diff bits
	;
noGState:
		mov es:[GNAAC_areaAttrDiffs], mask GrObjBaseAreaAttrDiffs
		jmp	done
GetBitmapAreaAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotificationLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out notification block to an app GCN list.

CALLED BY:	INTERNAL

PASS:		*ds:si	= IconBitmap object
		bx	= handle of notification block
		cx	= GeoWorksNotificationType
		dx	= GeoWorksGenAppGCNListType

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	4/ 7/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BitmapSendNotificationLow	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Record the notification event
	;
		push	dx			; GeoWorksGenAppGCNListType
		mov	bp, bx			; bp = notification block handle
		mov	dx, cx			; GeoWorksNotificationType
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	di, mask MF_RECORD
		call	ObjMessage		; di = classed event
		pop	cx			; GeoWorksGenAppGCNListType
	;
	; Send the recorded notification event to the application object
	;
		mov	dx, size GCNListMessageParams
		sub	sp, dx
		mov	bp, sp			; ss:bp = stack frame
		mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLMP_ID.GCNLT_type, cx
		mov	ss:[bp].GCNLMP_block, bx
		mov	ss:[bp].GCNLMP_event, di
	;
	; Set appropriate flags
	;
		mov	ax, mask GCNLSF_SET_STATUS
		tst	bx
		jnz	afterTransitionCheck
		ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
afterTransitionCheck:
		mov	ss:[bp].GCNLMP_flags, ax
	;
	; Send the recorded event off to the GCN list in the app obj
	;
		mov	ax, MSG_META_GCN_LIST_SEND
		clr	bx			; use current process
		call	GeodeGetAppObject	; ^lbx:si <- OD of app object
		mov	di, mask MF_STACK
		call	ObjMessage
		add	sp, dx			; clean up stack

		.leave
		ret
BitmapSendNotificationLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapSendNotifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends new area & line attributes to app GCN lists.

CALLED BY:	MSG_ICON_BITMAP_SEND_NOTIFICATIONS

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapSendNotifications	method dynamic IconBitmapClass, 
					MSG_ICON_BITMAP_SEND_NOTIFICATIONS
		uses	ax, cx, dx, bp
		.enter
	;
	;  Create the line-attributes notification block.
	;
		call	CreateLineAttrNotifyBlock
		jc	done

		call	MemUnlock
		mov	ax, 1			; reference count
		call	MemInitRefCount
	;
	;  Send the notification.
	;
		mov	cx, GWNT_GROBJ_LINE_ATTR_CHANGE
		mov	dx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE
		call	BitmapSendNotificationLow
	;
	;  Create the line-attributes notification block.
	;
		call	CreateAreaAttrNotifyBlock
		jc	done

		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount
	;
	;  Send the notification.
	;
		mov	cx, GWNT_GROBJ_AREA_ATTR_CHANGE
		mov	dx, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE
		call	BitmapSendNotificationLow
done:
		.leave
		ret
IconBitmapSendNotifications	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMOVisContentKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the message along to the viewer.

CALLED BY:	MSG_META_KBD_CHAR

PASS:		*ds:si	= BMOVisContentClass object
		ds:di	= BMOVisContentClass instance data

		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMOVisContentKbdChar	method dynamic BMOVisContentClass, 
					MSG_META_KBD_CHAR
		.enter
	;
	;  Send it to the viewer.
	;
		mov	si, offset IconDBViewerTemplate
		call	ObjCallInstanceNoLock
	;
	;  Kill the selection ants, if any...
	;
		mov	si, offset BMO
		mov	ax, MSG_VIS_BITMAP_KILL_SELECTION_ANTS
		call	ObjCallInstanceNoLock
 
		.leave
		ret
BMOVisContentKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMOContentLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Horrible hack to fix a bug I can't find.

CALLED BY:	MSG_META_LOST_TARGET_EXCL

PASS:		*ds:si	= BMOVisContentClass object
		ds:di	= BMOVisContentClass instance data

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMOContentLostTargetExcl	method dynamic BMOVisContentClass, 
					MSG_META_LOST_TARGET_EXCL
		uses	ax, cx, dx, bp
		.enter
	;
	;  Are we shutting down?  If so, don't call the superclass.
	;
		cmp	ds:[di].BMOVCC_dying, BB_TRUE
		je	done
	;
	;  Call the superclass
	;
		mov	di, offset BMOVisContentClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
BMOContentLostTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BMOContentShuttingDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the instance data to BB_TRUE.

CALLED BY:	MSG_BMO_CONTENT_SHUTTING_DOWN

PASS:		*ds:si	= BMOVisContentClass object
		ds:di	= BMOVisContentClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	4/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BMOContentShuttingDown	method dynamic BMOVisContentClass, 
					MSG_BMO_CONTENT_SHUTTING_DOWN
		.enter
	;
	;  Just set it to TRUE.
	;
		mov	ds:[di].BMOVCC_dying, BB_TRUE
		
		.leave
		ret
BMOContentShuttingDown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerTransferTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer target to bitmap object (from document object)

CALLED BY:	MSG_DB_VIEWER_TRANSFER_TARGET

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerTransferTarget	method dynamic DBViewerClass, 
					MSG_DB_VIEWER_TRANSFER_TARGET
		.enter
if 0
	;
	;  Notify the edit control the old undo chain (if any) is
	;  not going to be used any more, since the target is about
	;  to change.
	;
		call	GeodeGetProcessHandle		; bx = handle
		mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	di, ds:[si]
		add	di, ds:[di].DBViewer_offset	; ds:di = instance
	;
	;  Send the grab-target message to the VIEW in which the
	;  bitmap object resides.  Otherwise the BMO will never
	;  get the target, and I will spend months trying to figure
	;  out why.
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset BMOView		; ^lbx:si = view
		mov	ax, MSG_META_GRAB_TARGET_EXCL
		mov	di, mask MF_CALL
		call	ObjMessage
endif
		.leave
		ret
DBViewerTransferTarget	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fix some problems with the undo chain.

CALLED BY:	MSG_META_GAINED_TARGET_EXCL

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapGainedTargetExcl	method dynamic IconBitmapClass, 
					MSG_META_GAINED_TARGET_EXCL
		uses	ax, cx, dx, bp
		.enter
if 0
	;
	;  Send a MSG_GEN_PROCESS_UNDO_END_CHAIN VBI_undoDepth times.
	;
		mov	cx, ds:[di].VBI_undoDepth
		jcxz	done
sendLoop:
		push	cx
		mov	cx, sp			; nonzero to delete chain
		call	GeodeGetProcessHandle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_PROCESS_UNDO_END_CHAIN
		call	ObjMessage
		pop	cx
		loop	sendLoop
done:
endif
		.leave
		mov	di, offset IconBitmapClass
		GOTO	ObjCallSuperNoLock
IconBitmapGainedTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapBecomeDormant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompact the main bitmap.

CALLED BY:	MSG_VIS_BITMAP_BECOME_DORMANT

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	I added a flag to the bitmap library so that this routine
	is no longer necessary.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0

IconBitmapBecomeDormant	method dynamic IconBitmapClass, 
					MSG_VIS_BITMAP_BECOME_DORMANT
		uses	ax, cx, dx, bp
		.enter
	;
	;  Call the superclass, which does its evil compacting thing.
	;
		mov	di, offset IconBitmapClass
		call	ObjCallSuperNoLock
	;
	;  Grab the main bitmap and check whether it's been compacted.
	;
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
		call	ObjCallInstanceNoLock
		tst	dx				; no bitmap?
		jz	done

		movdw	bxax, cxdx			; ^vbx:ax = bitmap
	;
	;  Lock the block and check the B_compact field for BMC_UNCOMPACTED.
	;
		call	VMLock
		mov	es, ax
		cmp	es:[(size HugeArrayDirectory)].CB_simple.B_compact, \
							BMC_UNCOMPACTED
		call	VMUnlock
		je	done				; uncompacted? done
	;
	;  Uncompact the bitmap and toss the compacted one.
	;
		mov_tr	ax, dx				; ax <- vm block
		mov	dx, cx				; dx <- vm file
		call	GrUncompactBitmap		; dx:cx <- uncompacted

		push	bp
		clr	bp
		call	VMFreeVMChain			; free compacted bitmap
		pop	bp
	;
	;  Dirty our block and store the vm block of the uncompacted bitmap
	;  away.
	;
		call	ObjMarkDirty			; dirty me!
		mov	di, ds:[si]
		add	di, ds:[di].VisBitmap_offset
		mov	ds:[di].VBI_mainKit.VBK_bitmap, cx
done:
		.leave
		ret
IconBitmapBecomeDormant	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IconBitmapCheckBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear our handle if invalid.

CALLED BY:	MSG_ICON_BITMAP_CHECK_BITMAP

PASS:		*ds:si	= IconBitmapClass object
		ds:di	= IconBitmapClass instance data

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	Call VMInfo on the thing and clear the field if it's a bad
	handle.  See attach-ui-to-document handler for more info.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IconBitmapCheckBitmap	method dynamic IconBitmapClass, 
					MSG_ICON_BITMAP_CHECK_BITMAP
		uses	ax, cx, dx, bp
		.enter
	;
	;  Get the bitmap.
	;
		mov	ax, MSG_VIS_BITMAP_GET_MAIN_BITMAP
		call	ObjCallInstanceNoLock
		tst	dx				; no bitmap?
		jz	done
	;
	;  Check it.
	;
		movdw	bxax, cxdx			; ^vbx:ax = bitmap
		call	VMInfo				; carry clear if OK
		jnc	done
	;
	;  Clear the handle.
	;
		mov	di, ds:[si]
		add	di, ds:[di].VisBitmap_offset
		clr	ds:[di].VBI_mainKit.VBK_bitmap
done:
		.leave
		ret
IconBitmapCheckBitmap	endm


BitmapCode	ends



