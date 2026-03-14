COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CWin
FILE:		winScreen.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_INITIALIZE     Initialize instance data for a screen
				object

    MTD MSG_SPEC_BUILD          Visually build the screen

    MTD MSG_VIS_OPEN_WIN        Open the screen window and register it with
				the screen manager.

    MTD MSG_VIS_VUP_QUERY       Respond to a query travaeling up the
				visible composite tree

    MTD MSG_SPEC_GUP_QUERY      Answer a generic query or two.

    INT AppCommonFarRet         Answer a generic query or two.

    MTD MSG_SPEC_GUP_QUERY_VIS_PARENT 
				Respond to a query travaeling up the
				generic composite tree

    MTD MSG_SPEC_VUP_GET_WIN_SIZE_INFO 
				Returns margins for use with windows that
				wish to avoid extending over icon areas in
				the parent window.  Also size of window
				area.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:

	$Id: cwinScreen.asm,v 1.1 97/04/07 10:53:01 newdeal Exp $

-----------------------------------------------------------------------------@


CommonUIClassStructures segment resource

	OLScreenClass	mask CLASSF_DISCARD_ON_SAVE or \
				mask CLASSF_NEVER_SAVED
CommonUIClassStructures ends


;---------------------------------------------------

Init	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLScreenInitialize -- MSG_META_INITIALIZE for OLScreenClass

DESCRIPTION:	Initialize instance data for a screen object

PASS:	*ds:si - instance data (for object in OLScreen class)
	es - segment of OLScreenClass

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@
OLScreenInitialize	method dynamic	OLScreenClass, MSG_META_INITIALIZE

	CallMod	VisCompInitialize

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di is VisInstance
					; Mark this object as being a window
					; & win group
	or	ds:[di].VI_typeFlags, mask VTF_IS_WINDOW or mask VTF_IS_WIN_GROUP
					; Make realizable (not yet USABLE,
					; so don't need to update)
	or	ds:[di].VI_specAttrs, mask SA_REALIZABLE
	ret

OLScreenInitialize	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLScreenSpecBuild -- MSG_SPEC_BUILD for OLScreenClass

DESCRIPTION:	Visually build the screen

PASS:
	*ds:si - instance data (for object in OLScreen class)
	es - segment of OLScreenClass

	ax - MSG_SPEC_BUILD

	cx - ?
	dx - ?
	bp - ?

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

OLScreenSpecBuild	method dynamic	OLScreenClass, MSG_SPEC_BUILD

	; Add screen object as visual child of system object
	push	si
	call	GenFindParent		; Get parent (sys obj) in ^lbx:si
	mov	cx, bx			; copy to ^lcx:dx
	mov	dx, si
	pop	si

	push	si
	xchg	dx, si			; add screen to parent object
					; call method to add as child
	mov	ax, MSG_VIS_ADD_CHILD
	mov	bp, CCO_LAST	; put in back
	call	ObjCallInstanceNoLock
	pop	si

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
					; get handle of video driver
	mov	bx, ds:[di].GSCI_videoDriver
					; See if video driver to build for
					; is set up.
EC <	tst	bx		>	
EC <	ERROR_Z	OL_ERROR	>

	push	si
	push	ds
					; Get info about driver
	call	GeodeInfoDriver		; puts structure in ds:si

	mov	ax, ds:[si].VDI_pageW	; x size
	mov	bx, ds:[si].VDI_pageH	; y size

	pop	ds
	pop	si

EC<	call	VisCheckVisAssumption	; Make sure vis data exists >
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance
					; Store new bounds data
	mov	ds:[di].VI_bounds.R_right, ax
	mov	ds:[di].VI_bounds.R_bottom, bx

					; Neither image nor window is valid
	or	ds:[di].VI_optFlags, mask VOF_IMAGE_INVALID or mask VOF_WINDOW_INVALID
					; Children should NOT be geometrically
					;	managed.
	or	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_HOST_NOTIFICATIONS
	call	GCNListAdd

	ret

OLScreenSpecBuild	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLMenuedWinVisUnbuild -- MSG_SPEC_UNBUILD
		for OLMenuedWinClass

DESCRIPTION:	Visibly unbuilds & destroys a menued window

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		di 	- MSG_SPEC_UNBUILD

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds, es, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

OLScreenSpecUnbuild	method dynamic OLScreenClass,
						MSG_SPEC_UNBUILD

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_HOST_NOTIFICATIONS
	call	GCNListRemove

	mov	di, offset OLScreenClass
	GOTO	ObjCallSuperNoLock

OLScreenSpecUnbuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScreenNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification that a GWNT_HARD_ICON_BAR_FUNCTION or
		GWNT_STARTUP_INDEXED_APP has occurred - do a
		NukeExpressMenu.

CALLED BY:	MSG_META_NOTIFY, MSG_META_NOTIFY_WITH_DATA_BLOCK

PASS:		*ds:si	= OLApplicationClass object
		ds:di	= OLApplicationClass instance data
		es 	= segment of OLApplicationClass
		ax	= MSG_META_NOTIFY, MSG_META_NOTIFY_WITH_DATA_BLOCK

		cx	= ManufacturerId
		dx	= NotificationType
		bp	= data

RETURN:		nothing

ALLOWED TO DESTROY:
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/22/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
global screenWidth:word
global screenHeight:word
idata	ends

OLScreenNotify	method	dynamic	OLScreenClass, MSG_META_NOTIFY
	;
	; make sure we've got what we're looking for
	;
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_HOST_DISPLAY_SIZE_CHANGE
	jne	callSuper

	push 	si, ds, di
	; set the video mode again
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GSCI_videoDriver	

	; get driver strategy
	push	bx
	call	GeodeInfoDriver		; ds:si = DriverInfoStruct

	push    ax,bx,cx,dx,si,di,bp,es
	mov	di, DR_VID_HIDEPTR
	call	ds:[si].DIS_strategy
	pop  	ax,bx,cx,dx,si,di,bp,es

	; call update escape function
	mov	di, VID_ESC_UPDATE_DEVICE 
	call	ds:[si].DIS_strategy

	; update screen coordinates
	pop	bx
	pop	si, ds, di

	push	si
	push	ds
					; Get info about driver
	call	GeodeInfoDriver		; puts structure in ds:si

	mov	cx, ds:[si].VDI_pageW	; x size
	mov	dx, ds:[si].VDI_pageH	; y size

	push	ds
	mov	ax, segment screenWidth
	mov	ds, ax
	mov	ds:[screenWidth], cx
	mov	ds:[screenHeight], dx
	pop	ds

	pop	ds
	pop	si

	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

	;
	; record a message
	;
	push	ax, cx, dx, di, bx, bp
	push	si
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjMessage
	pop	si

	;
	; send it to all our children
	;
	push	cx
	mov	cx, di				;cx <- recorded message
	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	call	ObjCallInstanceNoLock
	pop	cx
	pop	ax, cx, dx, di, bx, bp

	push	ax, cx, dx, di, bx, bp
	push	si
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	ax, MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_IMAGE_INVALID or mask VOF_WINDOW_INVALID or mask VOF_IMAGE_UPDATE_PATH or mask VOF_GEOMETRY_INVALID or mask VOF_GEO_UPDATE_PATH
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	;
	; send it to all our children
	;
	push	cx
	mov	cx, di				;cx <- recorded message
	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	call	ObjCallInstanceNoLock
	pop	cx
	pop	ax, cx, dx, di, bx, bp

	push	ax, cx, dx, di, bx, bp
	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_HOST_SCREEN_FIELD_SIZE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage

	; Send it to the GCN list
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_HOST_NOTIFICATIONS
	mov	cx, di		; event handle
	clr	dx, bp		; no additional block sent
				; not set status flag
	call	GCNListSend
	pop	ax, cx, dx, di, bx, bp

	mov	ax, MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_IMAGE_INVALID or mask VOF_WINDOW_INVALID or mask VOF_IMAGE_UPDATE_PATH
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GSCI_videoDriver	
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].VCI_window
	mov	cx, 0
	mov	dx, 0
	;ax	- handle of driver for window
	;bx	- handle of window on which mouse moves
	;cx	- x coordinate of pointer in window
	;dx	- y coordinate of pointer in window
	call	ImSetPtrWin

	;
	; if there is a mouse driver, make the pointer visible
	;
	mov	ax, GDDT_MOUSE
	call	GeodeGetDefaultDriver
	tst	ax
	jz	done				; no mouse driver, no pointer


	push 	si, ds, di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GSCI_videoDriver	

	; get driver strategy
	call	GeodeInfoDriver		; ds:si = DriverInfoStruct

	push    ax,bx,cx,dx,si,di,bp
	mov	di, DR_VID_SHOWPTR
	call	ds:[si].DIS_strategy
	mov	di, DR_VID_SHOWPTR
	call	ds:[si].DIS_strategy
	pop    ax,bx,cx,dx,si,di,bp
	pop 	si, ds, di

done:


callSuper:
	mov	di, offset OLScreenClass
	GOTO	ObjCallSuperNoLock

OLScreenNotify	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLScreenOpenWin -- MSG_VIS_OPEN_WIN for OLScreenClass

DESCRIPTION:	Open the screen window and register it with the screen
		manager.

PASS:
	*ds:si - instance data (for object in OLScreen class)
	es - segment of OLScreenClass

	ax - MSG_VIS_OPEN_WIN

	cx - ?
	dx - ?
	bp - window to make parent of this window (will be 0, since won't
	     be found.  We have to use driver handle, anyway)

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/89		Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

------------------------------------------------------------------------------@

OLScreenOpenWin	method dynamic	OLScreenClass, MSG_VIS_OPEN_WIN

	tst	ds:[di].VCI_window	; already have a window?
	jnz	GSOW_90			; if so, can't open a new one
	
				; Get bounds of window
	push	si				; just saving this reg, not
						; passing to WinOpen...

	; push owner on stack as second parameter to WinOpen, so that same
	; owner will own window.

	clr	bx			; LayerID not needed, pass 0
	push	bx			; Push layer ID to use
	call	GeodeGetProcessHandle	; Get owner for window
	push	bx			; Push owner of window on stack

	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset	; ds:bx = GenInstance

	push	ds:[bx].GSCI_videoDriver	;stack param:  pass parent

	clr	ax				;stack param:  pass region
						;		(rectangular)
	push	ax
	push	ax

	clr	cl				;normal bounds
	call	OpenGetLineBounds		;stack param: pass bounds
	push	dx				;  (as screen coords)
	push	cx
	push	bx
	push	ax

	;Set for WCF_PLAIN and WCF_TRANSPARENT, since there will always
	;be a GenField object fully obscuring the GenScreen object.
	;Eliminates a full-screen redraw.	EDS 3/1/93

if not RECTANGULAR_ROTATION
	mov	ax, ((mask WCF_PLAIN or mask WCF_TRANSPARENT) shl 8)
else
	clr	ax		; plain, color=black
endif
	mov	bp, si		; set up chunk of this object in bp
	mov	di, ds:[0]	; pass obj descriptor of this object
	mov	cx, di		; pass enter/leave OD same
	mov	dx, bp
	mov	si, mask WPF_ROOT	; open a root window
				; pass handle of video driver
	call	WinOpen

	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance
	mov	ds:[di].VCI_window, bx	; store window handle


	;
	; Register this window and driver with the screen manager
	;
	mov	cx, bx
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	dx, ds:[di].GSCI_videoDriver
	call	UserScreenRegister
GSOW_90:
	ret

OLScreenOpenWin	endm


Init	ends

;-------------------------

AppCommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLScreenVupQuery -- MSG_VIS_VUP_QUERY
					for OLScreenClass

DESCRIPTION:	Respond to a query travaeling up the visible composite tree

PASS:
	*ds:si - instance data
	es - segment of OLScreenClass

	ax - MSG_VIS_VUP_QUERY

	cx - VisUpwardQueryType
	dx -?
	bp -?
RETURN:
	carry - set if query acknowledged, clear if not


	If cx = VUQ_VIDEO_DRIVER:
	returns	ax = handle of video driver

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version
	Doug	11/89		Moved into using general VUP_QUERY

------------------------------------------------------------------------------@

OLScreenVupQuery	method dynamic	OLScreenClass, MSG_VIS_VUP_QUERY
	cmp	cx, VUQ_VIDEO_DRIVER
	je	videoDriver
				; Send query on to superclass to handle
	mov	di, offset OLScreenClass
	GOTO	ObjCallSuperNoLock

videoDriver:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
				; return video driver handle
	mov	ax, ds:[di].GSCI_videoDriver
	stc			; return query acknowledged
	ret

OLScreenVupQuery	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScreenGupQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Answer a generic query or two.

CALLED BY:	MSG_SPEC_GUP_QUERY
PASS:		*ds:si	= instance data
		cx	= query type (GenQueryType or SpecGenQueryType)
RETURN:		carry	= set if acknowledged, clear if not
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLScreenGupQuery	method dynamic OLScreenClass, MSG_SPEC_GUP_QUERY
	cmp	cx, GUQT_FIELD			;For apps such as UI sitting
	je	screenObject			;	directly on screen
	cmp	cx, GUQT_SCREEN
	je	screenObject

	mov	di, offset OLScreenClass	;Pass the buck to our superclass
	GOTO	ObjCallSuperNoLock

screenObject:
	; return our OD, in cx:dx, & window handle in bp
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, ds:[di].VCI_window
	stc
	ret

OLScreenGupQuery	endp


AppCommonFarRet	proc	far
	ret
AppCommonFarRet	endp

AppCommon ends

HighCommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		OLScreenGupQueryVisParent -- MSG_SPEC_GUP_QUERY_VIS_PARENT for
					   OLScreenClass

DESCRIPTION:	Respond to a query travaeling up the generic composite tree

PASS:
	*ds:si - instance data
	es - segment of OLScreenClass
	ax - MSG_SPEC_GUP_QUERY_VIS_PARENT

	cx - GenQueryVisParentType
RETURN:
	carry - set if query acknowledged, clear if not
	cx:dx - object discriptor of object to use for vis parent, null if none
	bp    - window handle of field, IF realized (Valid for all attached
		applications of this field, as field can't be closed until
		all applications are detached)

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version

------------------------------------------------------------------------------@

OLScreenGupQueryVisParent	method	dynamic OLScreenClass, 
					MSG_SPEC_GUP_QUERY_VIS_PARENT
	; Return our OD, in cx:dx, & window handle in bp, for ALL requests.
	; We're the window of last resort, if no one else wants to be a 
	; parent.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, ds:[di].VCI_window
	stc				; return query acknowledged
	ret
OLScreenGupQueryVisParent	endm


COMMENT @----------------------------------------------------------------------

METHOD:		OLScreenGetWinSizeInfo -- 
		MSG_SPEC_VUP_GET_WIN_SIZE_INFO for OLScreenClass

DESCRIPTION:	Returns margins for use with windows that wish to avoid
		extending over icon areas in the parent window.  Also
		size of window area.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_SPEC_VUP_GET_WIN_SIZE_INFO

RETURN:		cx, dx  - size of window area
		bp low  - margins at bottom edge of object
		bp high - margins to the right edge of object
		ax, cx, dx - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/1?/92	Initial version
				(needed for dialogs from UIApp)

------------------------------------------------------------------------------@

OLScreenGetWinSizeInfo	method dynamic	OLScreenClass, \
				MSG_SPEC_VUP_GET_WIN_SIZE_INFO
	call	VisGetSize		;return current size
	
	;return margin info in bp - is used for staggered windows which
	;want to extend ALMOST to their parent's limits - so that they don't
	;cover the icon area, etc.

	mov	bp, (EXTEND_NEAR_PARENT_MARGIN_X shl 8) or \
		     NON_CGA_EXTEND_NEAR_PARENT_MARGIN_Y
	call	OpenMinimizeIfCGA		;if CGA, change Y value
	jnc	exit
	sub	bp, NON_CGA_EXTEND_NEAR_PARENT_MARGIN_Y - \
			CGA_EXTEND_NEAR_PARENT_MARGIN_Y
exit:
	ret
OLScreenGetWinSizeInfo	endm

HighCommon	ends
