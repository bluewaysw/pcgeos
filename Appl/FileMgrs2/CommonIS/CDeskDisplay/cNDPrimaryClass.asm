COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/DeskDisplay
FILE:		cNDPrimaryClass.asm
AUTHOR:		David Litwin

ROUTINES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/15		Initial version

DESCRIPTION:
	This file contains routines for the NDPrimary.

	$Id: cNDPrimaryClass.asm,v 1.2 98/06/03 13:06:57 joon Exp $

------------------------------------------------------------------------------@

if _NEWDESK

NDPrimaryCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrimaryFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept F4.  Don't pass F4 on to superclass so that SpecUI
		won't close our folders.

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= NDPrimaryClass object
		ds:di	= NDPrimaryClass instance data
		ds:bx	= NDPrimaryClass object (same as *ds:si)
		es 	= segment of NDPrimaryClass
		ax	= message #
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code
RETURN:		carry set if character was handled by someone (and should
		not be used elsewhere).
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/30/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC_ONLY
NDPrimaryFupKbdChar	method dynamic NDPrimaryClass, 
					MSG_META_FUP_KBD_CHAR
SBCS <	cmp	cx, (VC_ISCTRL shl 8) or VC_F4				>
DBCS <	cmp	cx, C_SYS_F4						>
	jne	callSuper

	tst	dh				; test for ShiftState
	jnz	callSuper			; callSuper if ShiftState

	stc					; swallow it
	ret

callSuper:
	mov	di, offset NDPrimaryClass
	GOTO	ObjCallSuperNoLock

NDPrimaryFupKbdChar	endm
endif	; GPC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrimaryClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pass the close to the associated FolderClass

CALLED BY:	GLOBAL

PASS:		*ds:si	= NDPrimaryClass object
	
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/16/92		Initial version
	martin	11/25/92	added ability to save window position/size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPrimaryClose	method NDPrimaryClass, MSG_GEN_DISPLAY_CLOSE

ifdef SMARTFOLDERS		; compilation flag, see local.mk

	;
	; Calculate current size and position as ratio of parent.
	;

		call	VisGetBounds		; (ax, bx)	= position
		sub	cx, ax	
		sub	dx, bx			; dx		= height
		mov	di, cx			; di		= width

		push	bx, si
		call	VisFindParent
		tst	bx
		pop	bx, si
		jz	noConvert		; no parent, garbage values
						; won't be used

		clr	cl
		call	VisConvertCoordsToRatio

		xchg	di, ax
		xchg	dx, bx			; (di, dx) 	= position
		call	VisConvertCoordsToRatio	; ax 		= width
						; bx		= height


noConvert:
		sub	sp, size FolderWindowInfo
		mov	bp, sp
		mov	ss:[bp].FWI_position.SWSP_x, di		; X coord.
		mov	ss:[bp].FWI_position.SWSP_y, dx		; Y coord.
		mov	ss:[bp].FWI_size.SWSP_x, ax		; width
		mov	ss:[bp].FWI_size.SWSP_y, bx		; height

	;
	; Tell associated folder to close.
	;

		mov	ax, MSG_GEN_VIEW_GET_CONTENT
		mov	si, FOLDER_VIEW_OFFSET		; common offset
		push	bp
		call	ObjCallInstanceNoLock
		pop	bp

		mov	bx, cx
		mov	si, dx				; ^lbx:si = folder

		mov	di, mask MF_STACK
		mov	ax, MSG_FOLDER_CLOSE_AND_SAVE
		mov	dx, size FolderWindowInfo
		call	ObjMessage
		add	sp, size FolderWindowInfo

else 	; ifdef SMARTFOLDERS

		mov	ax, MSG_GEN_VIEW_GET_CONTENT
		mov	si, FOLDER_VIEW_OFFSET		; common offset
		call	ObjCallInstanceNoLock
		mov	ax, MSG_FOLDER_CLOSE
		mov	bx, cx
		mov	si, dx
		clr	di
		call	ObjMessage

endif 	; ifdef SMARTFOLDERS

	;
	; Set window not usable to prevent user from using this window.
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		GOTO	ObjCallInstanceNoLock

NDPrimaryClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrimaryBringToTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the layer to the top of its LayerID before calling
		superclass

CALLED BY:	MSG_GEN_BRING_TO_TOP

PASS:		usual method stuff

RETURN:		nothing

DESTROYED:	Whatever the superclass destroys

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPrimaryBringToTop	method NDPrimaryClass, MSG_GEN_BRING_TO_TOP

	push	ax, si			; save for later superclass call

	mov	dx, ds:[LMBH_handle]	; LayerID is block handle of obj.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance
	mov	di, ds:[di].VCI_window
	tst	di
	jz	callSuper		; just call superclass if no window

	mov	si, WIT_PARENT_WIN
	call	WinGetInfo
	mov	di,  ax			; put parent window into di

	mov	ax, mask WPF_LAYER
		; WPF_PLACE_LAYER_BEHIND is left clear indicating to place
		; in FRONT of other layers
	call	WinChangePriority

callSuper:
	pop	ax, si			; restore for superclass call

	mov	di, offset NDPrimaryClass
	GOTO	ObjCallSuperNoLock

NDPrimaryBringToTop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrimaryLowerToBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lower the layer to the bottom of its LayerID before calling
		superclass

CALLED BY:	MSG_GEN_LOWER_TO_BOTTOM

PASS:		usual method stuff

RETURN:		nothing

DESTROYED:	Whatever the superclass destroys

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPrimaryLowerToBottom	method NDPrimaryClass,
						MSG_GEN_LOWER_TO_BOTTOM
	push	ax, si			; save for later superclass call

	mov	dx, ds:[LMBH_handle]	; LayerID is block handle of obj.
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance
	mov	di, ds:[di].VCI_window
	tst	di
	jz	callSuper

	mov	si, WIT_PARENT_WIN
	call	WinGetInfo
	mov	di,  ax			; put parent window into di

	mov	ax, mask WPF_LAYER or mask WPF_PLACE_LAYER_BEHIND
	call	WinChangePriority

callSuper:
	pop	ax, si			; restore for superclass call

	mov	di, offset NDPrimaryClass
	GOTO	ObjCallSuperNoLock

NDPrimaryLowerToBottom	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrimaryUpdateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When re-attaching from state, send a dummy message to the
		FolderClass object (output of GenView) so that it will get
		relocated and add itself to the folder tracking table.
		(Needed in case the folder is minimized and off screen.)

CALLED BY:	MSG_META_UPDATE_WINDOW
PASS:		*ds:si	= NDPrimaryClass object
		ds:di	= NDPrimaryClass instance data
		ds:bx	= NDPrimaryClass object (same as *ds:si)
		es 	= segment of NDPrimaryClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	1/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPrimaryUpdateWindow	method dynamic NDPrimaryClass, 
					MSG_META_UPDATE_WINDOW

	;
	; When restoring from state, reset our control menu button moniker
	;
	test	cx, mask UWF_RESTORING_FROM_STATE
	jz	noIcon
	push	cx, es
	mov	bp, si				; *ds:bp = primary
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, {word}ds:[di].NDPI_token.GT_chars[0]
	mov	bx, {word}ds:[di].NDPI_token.GT_chars[2]
	mov	si, ds:[di].NDPI_token.GT_manufID

	push	ds:[LMBH_handle]		; save lmem blk handle
	GetResourceSegmentNS	dgroup, es
	mov	dh, es:[desktopDisplayType]
	mov	cx,	(VMS_TOOL shl offset VMSF_STYLE) or	\
			mask VMSF_GSTRING
	push	cx, cx		; VisMonikerSearchFlags, any old bogus size 
	clr	cx				; return us a block
	call	TokenLoadMoniker		; block returned in di, 
	pop	bx				;  cx is length in bytes
	call	MemDerefDS			; fixup ds
	mov	si, bp				; *ds:si = primary
	jc	noIconPop			;  exit if no icon found
	push	di				; save vis moniker block handle
	mov	dx, size ReplaceVisMonikerFrame
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].RVMF_source.high, di		; block's handle
	mov	ss:[bp].RVMF_source.low, 0		; no offset
	mov	ss:[bp].RVMF_sourceType, VMST_HPTR
	mov	ss:[bp].RVMF_dataType, VMDT_VIS_MONIKER
	mov	ss:[bp].RVMF_length, cx
	clr	ss:[bp].RVMF_width
	clr	ss:[bp].RVMF_height
	mov	ss:[bp].RVMF_updateMode, VUM_NOW
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	call	ObjCallInstanceNoLock
	add	sp, size ReplaceVisMonikerFrame
	pop	bx				; restore vismoniker block
	call	MemFree
noIconPop:
	pop	cx, es
noIcon:
		
	push	cx
	mov	ax, MSG_META_UPDATE_WINDOW
	mov	di, offset NDPrimaryClass
	call	ObjCallSuperNoLock
	pop	cx

	test	cx, mask UWF_RESTORING_FROM_STATE
	jz	done

	;
	; Send dummy message to the FolderClass object, so that it
	; relocates itself (why?)
	;

	call	ObjBlockGetOutput
	mov	ax, MSG_META_DUMMY
	clr	di
	GOTO	ObjMessage
done:
	ret
NDPrimaryUpdateWindow	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrimaryInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the icon bounds from which the GenPrimary is
		opened from.

CALLED BY:	GLOBAL

PASS:		*ds:si	= NDPrimaryClass object
		cx:dx	= fptr to icon bounds (Rectangle)

RETURN:		nothing
DESTROYED:	ax, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/16/92   	Initial version
	martin	11/25/92	added ability to save window position/size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPrimaryInitialize	method dynamic NDPrimaryClass, 
					MSG_ND_PRIMARY_INITIALIZE
		uses	bp
		.enter

	;
	; Put the bounds of the icon that this primary came from into
	; vardata, so that the zoom lines know where to start from. 
	;

		movdw	esdi, cxdx

		mov	ax, HINT_PRIMARY_OPEN_ICON_BOUNDS
		mov	cx, size Rectangle
		call	ObjVarAddData

		mov	ax, es:[di].R_left
		mov	ds:[bx].R_left, ax
		mov	ax, es:[di].R_top
		mov	ds:[bx].R_top, ax
		mov	ax, es:[di].R_right
		mov	ds:[bx].R_right, ax
		mov	ax, es:[di].R_bottom
		mov	ds:[bx].R_bottom, ax

ifdef SMARTFOLDERS		; compilation flag, see local.mk

	;
	; Get the initial bounds of this primary from the DIRINFO file.
	;

BA <		call	UtilAreWeInEntryLevel?				>
BA <		jc	done						>
		
	;
	; Set current path, and open DIRINFO
	;

		mov	ax, ATTR_GEN_PATH_DATA
		mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath

		call	UtilCheckReadDirInfo
		jc	doneJC

		push	ds, si
;		call	FolderGetDirInfoName
;routine doesn't exist, use filename string in dgroup
NOFXIP<		segmov	ds, dgroup, dx		; ds:dx - filename to open >
FXIP	<	GetResourceSegmentNS dgroup, ds				>
		mov	dx, offset dirinfoFilename
		call	ShellOpenDirInfo
		segmov	es, ds, ax		; es:0	= DirInfoFileHeader
		pop	ds, si
doneJC:
		jc	done

		push	bx

	;
	; skip if not set in .ini file
	;
		push	es
		GetResourceSegmentNS	dgroup, es
		cmp	es:[saveWinPosSize], TRUE
		pop	es
		jne	skipPosSize
	;
	; Now add some hints, so window comes up with the corrent size
	; and position.
	;

		mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_PARENT or \
				mask VDF_SAVE_TO_STATE
		
		mov	cx, size SpecWinSizePair
		call	ObjVarAddData
		movdw	ds:[bx], es:[DIFH_winSize], ax

		mov	ax, HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT or \
				mask VDF_SAVE_TO_STATE

		call	ObjVarAddData
		movdw	ds:[bx], es:[DIFH_winPosition], ax

skipPosSize:
	;
	; Save sort and view modes associated with this folder.
	;
		cmp	es:[DIFH_protocol], 3
		jbe	noModes
		mov	ax, ATTR_ND_PRIMARY_SAVED_DISPLAY_OPTIONS
		mov	cx, size NDPSavedDisplayOptions
		call	ObjVarAddData
		movdw	axcx, es:[DIFH_displayOptions]
		mov	ds:[bx].NDPSDO_types, ah
		mov	ds:[bx].NDPSDO_attrs, al
		mov	ds:[bx].NDPSDO_sort, ch
		mov	ds:[bx].NDPSDO_mode, cl
noModes:

		pop	bx
		call	ShellCloseDirInfo
done:

endif 	; ifdef SMARTFOLDERS	

		.leave
		ret
NDPrimaryInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrimarySetToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the token.

CALLED BY:	GLOBAL

PASS:		*ds:si	= NDPrimaryClass object
		cx:dx = TokenChars
		bp = manufacturer ID

RETURN:		nothing
DESTROYED:	ax, cx, dx

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/19/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPrimarySetToken	method dynamic NDPrimaryClass, 
					MSG_ND_PRIMARY_SET_TOKEN
		mov	{word}ds:[di].NDPI_token.GT_chars[0], cx
		mov	{word}ds:[di].NDPI_token.GT_chars[2], dx
		mov	ds:[di].NDPI_token.GT_manufID, bp
		ret
NDPrimarySetToken	endm

NDPrimaryCode	ends

endif		; if _NEWDESK




