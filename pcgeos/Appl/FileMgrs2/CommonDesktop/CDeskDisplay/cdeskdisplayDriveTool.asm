COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		deskdisplayDriveTool.asm

AUTHOR:		Adam de Boor, Jan 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/30/92		Initial revision


DESCRIPTION:
	Implementation of DriveToolClass
		

	$Id: cdeskdisplayDriveTool.asm,v 1.4 98/08/20 05:10:33 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


if not _GMGR
PrintMessage <Only GeoManager should include this file>
endif

PseudoResident segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveToolTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle click on drive icon

CALLED BY:	MSG_GEN_TRIGGER_SEND_ACTION (button release)

PASS:		usual object stuff

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveToolTrigger	method	DriveToolClass, MSG_GEN_TRIGGER_SEND_ACTION
	mov	di, offset DriveToolClass
	call	ObjCallSuperNoLock		; call superclass to flash icon
	jc	error				; button not enabled, etc.
	;
	; start input ignore
	;
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	;
	; call desktop process to do all the work
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cl, ds:[di].DT_driveNumber
	mov	bx, handle 0 			; bx = desktop process
	mov	ax, MSG_DRIVETOOL_INTERNAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	;
	; turn off input ignore, indirectly
	;
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenSendToApplicationViaProcess

error:
	ret
DriveToolTrigger	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	provide feedback during direct-manipulation

CALLED BY:	MSG_META_PTR

PASS:		*ds:si - DriveTool
		ds:di = DriveTool instance data
		es - segment of DriveToolClass
		bp - UIFA flags
			UIFA_IN - set mouse pointer if in bounds of this object

RETURN:		ax = MouseReturnFlags

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/11/91		Initial version for 2.0 quick-transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveToolPtr	method	DriveToolClass, MSG_META_PTR
	add	di, offset DvT_flags		; ds:di = flags
	mov	bx, offset Callback_DriveToolPtr
	mov	ax, offset DriveToolClass
	call	ToolPtrCommon
	ret
DriveToolPtr	endm

DriveToolLostGadgetExcl	method	DriveToolClass, MSG_VIS_LOST_GADGET_EXCL
	add	di, offset DvT_flags
	call	ToolLostGadgetExclCommon
	ret
DriveToolLostGadgetExcl	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Callback_DriveToolPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback for DriveToolPtr that determines the quick
		transfer default for move/copy.

CALLED BY:	ToolPtrCommon

PASS:		*ds:si - DriveTool object

RETURN:		ax = CQTF_MOVE, CQTF_COPY or CQTF_CLEAR

DESTROYED:	???
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE:	All we can do here is check if it is the same drive number
		as we may not have a disk handle for the disk in the drive


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/17/93	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Callback_DriveToolPtr	proc	near
	class	DriveToolClass
	uses	bx, si
	.enter

	call	CheckQuickTransferType		; check if TIF_FILES supported
	jnc	supported

	mov	ax, CQTF_CLEAR			; nope, just clear cursor
	jmp	done	

supported:
	tst	bx
	mov	bx, ax				; put diskhandle in bx
	mov	ax, CQTF_COPY			; copy if source is remote
	jnz	done
						; bx = true disk handle
	call	DiskGetDrive			; al = drive number
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	cmp	al, ds:[si].DT_driveNumber	; check drive number
	mov	ax, CQTF_MOVE			; assume same
	je	done				; yes, indicate move
	mov	ax, CQTF_COPY			; else, indicate copy
done:
	.leave
	ret
Callback_DriveToolPtr	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveToolEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle direct-manipulation

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		usual object stuff
		es - segment of DriveToolClass
		bp - UIFA flags

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveToolEndMoveCopy	method	DriveToolClass, \
							MSG_META_END_MOVE_COPY
	uses	ax, cx, dx, bp, si
	.enter
	call	DriveToolLostGadgetExcl		; release mouse, if needed
	mov	di, MSG_DRIVETOOL_QT_INTERNAL
	call	ToolQuickTransfer
	.leave
	mov	di, offset DriveToolClass
	call	ObjCallSuperNoLock
	ret
DriveToolEndMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveToolEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle direct-manipulation for ZMGR

CALLED BY:	MSG_META_END_SELECT

PASS:		usual object stuff
		es - segment of DriveToolClass
		bp - UIFA flags

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _PEN_BASED
DriveToolEndSelect	method	DriveToolClass, MSG_META_END_SELECT
	uses	ax, cx, dx, bp, si
	.enter
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_MOVECOPY
	pop	es
	jz	done
	call	DriveToolLostGadgetExcl		; release mouse, if needed
	mov	di, MSG_DRIVETOOL_QT_INTERNAL
	call	ToolQuickTransfer
done:
	.leave
	mov	di, offset DriveToolClass
	call	ObjCallSuperNoLock
	ret
DriveToolEndSelect	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveToolSetDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set drive number and letter for this drive

CALLED BY:	MSG_DRIVE_TOOL_SET_DRIVE

PASS:		usual object stuff
		bp - drive nubmer

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveToolSetDrive	method	dynamic DriveToolClass, MSG_DRIVE_TOOL_SET_DRIVE
	mov	ax, bp				; al = drive number
	mov	ds:[di].DT_driveNumber, al
	ret
DriveToolSetDrive	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveToolSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the passed drive tool visually, setting the moniker
		to hold the proper drive name and cached size.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= DriveTool object, with drive number set
		ds:di	= DriveToolInstance
		es	= segment of DriveToolClass 
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp all possible

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _TINY

TinyMonoBitmaps	optr	\
	FiveInchDiskYMBitmap,
	ThreeInchDiskYMBitmap,
	HardDiskYMBitmap,
	RamDiskYMBitmap,
	CDRomYMBitmap,
	NetDiskYMBitmap,
	PCMCIAYMBitmap

.assert (length TinyMonoBitmaps eq DriveToolType)
endif

if _CGA

CGABitmaps	optr	\
	FiveInchDiskSCGABitmap,
	ThreeInchDiskSCGABitmap,
	HardDiskSCGABitmap,
	RamDiskSCGABitmap,
	CDRomSCGABitmap,
	NetDiskSCGABitmap,
	PCMCIASCGABitmap,
	RemovableDiskSCGABitmap

.assert (length CGABitmaps eq DriveToolType)

endif

if _STANDARD_MONO

StandardMonoBitmaps	optr	\
	FiveInchDiskSMBitmap,
	ThreeInchDiskSMBitmap,
	HardDiskSMBitmap,
	RamDiskSMBitmap,
	CDRomSMBitmap,
	NetDiskSMBitmap,
	PCMCIASMBitmap,
	RemovableDiskSMBitmap

.assert (length StandardMonoBitmaps eq DriveToolType)

endif

if _STANDARD_COLOR

StandardColorBitmaps	optr	\
	FiveInchDiskSCBitmap,
	ThreeInchDiskSCBitmap,
	HardDiskSCBitmap,
	RamDiskSCBitmap,
	CDRomSCBitmap,
	NetDiskSCBitmap,
	PCMCIASCBitmap,
	RemovableDiskSCBitmap

.assert (length StandardColorBitmaps eq DriveToolType)

endif


DRIVETOOL_MONIKER_FIXED_SIZE	equ size OpSetFont + \
					size OpDrawTextAtCP + \
					size OpDrawBitmapOptr
DRIVETOOL_NAME_START		equ offset VM_data + offset VMGS_gstring + \
					size OpSetFont + size OpDrawTextAtCP

ifndef GEOLAUNCHER
DRIVETOOL_MIN_HEIGHT		equ	30
DRIVETOOL_MIN_TINY_HEIGHT	equ	20
DRIVETOOL_MIN_CGA_HEIGHT	equ	14
else
DRIVETOOL_MIN_HEIGHT		equ	42
DRIVETOOL_MIN_TINY_HEIGHT	equ	32
DRIVETOOL_MIN_CGA_HEIGHT	equ	26
endif

DriveToolSpecBuild method dynamic DriveToolClass, MSG_SPEC_BUILD
		.enter
	;
	; Let our superclass deal with resolving the moniker list.
	; 
		mov	di, offset DriveToolClass
		CallSuper	MSG_SPEC_BUILD
		
		mov	di, ds:[si]
		add	di, ds:[di].DriveTool_offset

		mov	bx, ds:[di].GI_visMoniker
		ChunkSizeHandle	ds, bx, ax
	;
	; check if it is empty, or just a VisMoniker with a gstring that
	; immediately ends
	;
		cmp	ax, size VisMoniker + size VisMonikerGString + \
					size OpEndGString
		LONG	jne	exit		; if already built, exit

	;
	; Figure the number of bytes needed by the drive name
	; 
		mov	al, ds:[di].DT_driveNumber
EC <		cmp	al, -1						>
EC <		ERROR_E	DRIVE_TOOL_BUILT_BEFORE_DRIVE_NUMBER_SET	>
   		clr	cx		; give buffer size of 0 so we get length
					;  of name back always
		call	DriveGetName
haveNameLen::
		tst	cx		;If the drive is going away for some
		LONG jz exit		; reason, don't bother making a moniker
					; for it

   	;
	; Adjust the moniker to make room for the real gstring elements:
	;	GSSetFont DRIVETOOL_LABEL_FONT, DRIVETOOL_LABEL_POINTSIZE
	;	GSDrawTextAtCP <drive_name>
	;	GSDrawBitmapOptr <drive_name_width, 0, drive_type_bitmap>
	;
		mov	ah, ds:[di].DT_driveType	; get and save drive
		push	ax				;  type while we've got
							;  the object in ds:di
SBCS <		add	cx, DRIVETOOL_MONIKER_FIXED_SIZE-1	; -1 b/c we >
DBCS <		add	cx, DRIVETOOL_MONIKER_FIXED_SIZE-2	; -1 b/c we >
								;  don't need
								;  null-term in
								;  drive name
		mov	ax, ds:[di].GI_visMoniker

	; moniker must be real gstring moniker for this to work...
EC <		mov	bx, ax						>
EC <		mov	bx, ds:[bx]					>
EC <		test	ds:[bx].VM_type, mask VMT_MONIKER_LIST		>
EC <		ERROR_NZ	DESKTOP_FATAL_ERROR			>
EC <		test	ds:[bx].VM_type, mask VMT_GSTRING		>
EC <		ERROR_Z		DESKTOP_FATAL_ERROR			>

		mov	bx, offset VM_data + offset VMGS_gstring
		call	LMemInsertAt
	;
	; Point to the start of the gstring.
	; 
		mov_tr	di, ax
		mov	di, ds:[di]
		pop	ax		; recover drive # & type
		push	di		; save start of moniker for other fun
					;  things
		add	di, bx		; ds:di <- start of gstring
	;
	; Setup the OpSetFont
	; 
		mov	ds:[di].OSF_opcode, GR_SET_FONT
		mov	ds:[di].OSF_size.WBF_int, DRIVETOOL_LABEL_POINTSIZE
		mov	ds:[di].OSF_size.WBF_frac, 0
		mov	ds:[di].OSF_id, DRIVETOOL_LABEL_FONT
		add	di, size OpSetFont
	;
	; Setup the OpDrawTextAtCP
	;
		mov	ds:[di].ODTCP_opcode, GR_DRAW_TEXT_CP
		sub	cx, DRIVETOOL_MONIKER_FIXED_SIZE
DBCS <		shr	cx, 1						>
		mov	ds:[di].ODTCP_len, cx
DBCS <		shl	cx, 1						>
		add	di, size OpDrawTextAtCP
		push	es
		segmov	es, ds
		call	DriveGetName
haveNameCopy::
		pop	es
	;
	; Setup the OpDrawBitmapOptr. ODBOP_x will be filled in when we
	; know how wide the text is.
	;
		mov	ds:[di].ODBOP_opcode, GR_DRAW_BITMAP_OPTR
		mov	ds:[di].ODBOP_y, 0		

	;
	; Figure which bitmap to use based on the info in the VisMoniker that
	; our superclass decided to use and on the current display type.
	;
		mov	bl, ah
		clr	bh
		pop	si
		push	si		; save again for setting cached width
					;  and height...

		mov	al, ds:[si].VM_type		
		mov	ah, al

	; EC code to make sure we choose a bitmap!
		
EC <		mov	si, -1						>

if _CGA
		
	;
	; If aspect ratio is verySquished, use standard CGA
	;
		andnf	al, mask VMT_GS_ASPECT_RATIO
		mov	si, offset CGABitmaps
		mov	dx, DRIVETOOL_MIN_CGA_HEIGHT
		cmp	al, DAR_VERY_SQUISHED shl offset VMT_GS_ASPECT_RATIO
		je	haveBMOffset
endif ; _CGA
		
if _TINY
	;
	; If application is compiled to run on a "tiny" screen (ie,
	; Zoomer), then always use the tiny bitmaps, regardless of
	; the screen size
	; 
		mov	dx, DRIVETOOL_MIN_TINY_HEIGHT
		mov	si, offset TinyMonoBitmaps
		jmp	short haveBMOffset

endif	; _TINY

if _STANDARD_MONO
		
	;
	; If size is standard and display class is gray1, use standard Mono
	; 
		mov	dx, DRIVETOOL_MIN_HEIGHT
		mov	si, offset StandardMonoBitmaps
		andnf	ah, mask VMT_GS_COLOR
		cmp	ah, DC_GRAY_1 shl offset VMT_GS_COLOR
		je	haveBMOffset
endif

if _STANDARD_COLOR
		
	;
	; Else use standard Color
	; 
		mov	si, offset StandardColorBitmaps
endif
		
haveBMOffset:
EC <		cmp	si, -1						>
EC <		ERROR_E DESKTOP_FATAL_ERROR				>
EC <		cmp	bx, DriveToolType				>
EC <		ERROR_AE NO_BITMAP_AVAILABLE_FOR_DRIVE_TYPE		>

	;
	; Convert drive type to optr offset
	;
		
		shl	bx		; *2
		shl	bx		; *4

		mov	ax, ({optr}cs:[bx][si]).chunk
		mov	ds:[di].ODBOP_optr.chunk, ax
		mov	bx, ({optr}cs:[bx][si]).handle
		mov	ds:[di].ODBOP_optr.handle, bx
		
	;
	; Now lock down the bitmap and get its dimensions.
	; 
		mov_tr	si, ax
		call	ObjLockObjBlock
		mov	es, ax
		mov	si, es:[si]
		mov	ax, es:[si].B_height
		mov	cx, es:[si].B_width
		call	MemUnlock
		pop	si
		
		cmp	ax, dx			; bitmap taller than min?
		jae	setWidthAndHeight
		
		xchg	ax, dx			; ax <- min height, dx <- bm
						;  height
		sub	dx, ax			; now center the bitmap
		neg	dx			;  in the minimum height
		shr	dx
		mov	ds:[di].ODBOP_y, dx
setWidthAndHeight:
	;
	; Set them as the current cached width and height for the moniker. We
	; assume the bitmap is taller than the text, so the cached height
	; will remain the height of the bitmap. The width we'll adjust in a
	; moment.
	; 
		mov	ds:[si].VM_data+VMGS_height, ax
		mov	ds:[si].VM_width, cx
		
	;
	; Figure the width of the drive-name label.
	; 
		push	di
		clr	di
		call	GrCreateState	; get us a calculation gstate open to
					;  no window

		mov	cx, DRIVETOOL_LABEL_FONT
		mov	dx, DRIVETOOL_LABEL_POINTSIZE
		clr	ah
		call	GrSetFont
		
		add	si, DRIVETOOL_NAME_START	; ds:si <- text
		mov	cx, ds:[si-size OpDrawTextAtCP].ODTCP_len
		call	GrTextWidth	; dx <- width, in points
		call	GrDestroyState
		pop	di		; ds:di <- OpDrawBitmapOptr
	;
	; Set that, plus the gutter between the two, as the X coordinate
	; for drawing the bitmap.
	; 
		add	dx, DRIVETOOL_LABEL_GUTTER
		mov	ds:[di].ODBOP_x, dx
	;
	; Add the same amount into the cached width, too.
	; 
		add	ds:[si-DRIVETOOL_NAME_START].VM_width, dx

exit:
		.leave
		ret
DriveToolSpecBuild endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveToolGetDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get drive number for this drive

CALLED BY:	MSG_DRIVE_TOOL_GET_DRIVE

PASS:		usual object stuff

RETURN:		bp - drive nubmer
		dx - disk handle

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveToolGetDrive	method	dynamic DriveToolClass, MSG_DRIVE_TOOL_GET_DRIVE
	mov	al, ds:[di].DT_driveNumber	; get drive number
	clr	ah
	mov	bp, ax				; bp = drive number
	mov	dx, ds:[di].DT_disk		; dx = disk handle
	ret
DriveToolGetDrive	endm

PseudoResident	ends
