COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NewDesk
MODULE:		Folder
FILE:		cnddesktopfolderClass.asm

AUTHOR:		Joon Song, Nov  1, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/ 1/92   	Initial revision


DESCRIPTION:
	This file contains the class routines of the NDDesktopClass
		

	$Id: cnddesktopfolderClass.asm,v 1.3 98/06/03 13:10:27 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopMetaExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw the desktop

PASS:		*ds:si	= NDDesktopClass object
		^hcx	= Window
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	4/4/98   	Initial version copied from DeskVisExposed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopMetaExposed	method	dynamic	NDDesktopClass, 
					MSG_META_EXPOSED
	mov	bp, ds:[si]			; deref. instance handle
	mov	ds:[bp].DVI_window, cx		; save window for later
	mov	di, ds:[bp].DVI_gState		; get gState
	tst	di				; check if gState created yet
	jnz	DVE_gotGState			; if so, don't create again
	mov	di, cx				; else, 
	call	GrCreateState 		; create gState for window
	mov	cx, ss:[desktopFontID]		; set default font in gState
	mov	dx, ss:[desktopFontSize]
	clr	ah				; no fractional part
	call	GrSetFont
	mov	ds:[bp].DVI_gState, di		; save global gState
DVE_gotGState:
	call	GrBeginUpdate

	; Have the field draw the background in our gstate
	push	si, di				; save gState handle
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	ax, MSG_VIS_DRAW
	mov	cl, mask DF_EXPOSED
	mov	bp, di
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	mov	cx, di
	call	UserCallApplication
	pop	si, di				; restore gState handle

	mov	ax, MSG_DV_DRAW			; draw ourselves
	mov	bp, di
	call	ObjCallInstanceNoLock

	call	GrEndUpdate

	; we need some way to update the background color.  we'll check the
	; .ini file every time we do an expose.  this sucks, but what else
	; can we do?

	mov	di, ds:[si]
	mov	bx, ds:[di].FOI_windowBlock
	mov	si, FOLDER_VIEW_OFFSET
	mov	ax, MSG_ND_DESKTOP_VIEW_UPDATE_BG_COLOR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage

NDDesktopMetaExposed		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	The Desktop folder is never closed, so we have a stub
		routine to keep the superclass behavior from closing it,
		should the desktop ever receive a MSG_FOLDER_CLOSE (it
		happens when someone wants to close all folders with
		a single call).

PASS:		*ds:si	= NDDesktopClass object
RETURN:		nothing 
DESTROYED:	nothing 

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopClose	method	dynamic	NDDesktopClass, MSG_FOLDER_CLOSE
	ret
NDDesktopClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- NDDesktopClass object
		ds:di	- NDDesktopClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDDesktopViewSizeChanged	method	dynamic	NDDesktopClass, 
					MSG_META_CONTENT_VIEW_SIZE_CHANGED

		uses	ax,cx,dx,bp
		.enter

	;
	; Invalidate the window.  This may cause things to flash, but
	; it will keep the horrible "icons show up in the wrong place"
	; bug from happening, I think...
	;
		
		mov	ax, MSG_REDRAW
		call	ObjCallInstanceNoLock
		
	;
	; Convert all icon positions back to percentages, so that the
	; icons will move properly to accommodate scrollbars.
	;

		call	NDDesktopConvertPositionsToPercentages

		.leave
		mov	di, offset NDDesktopClass
		GOTO	ObjCallSuperNoLock
		
NDDesktopViewSizeChanged	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopConvertPositionsToPercentages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert icon positions for the desktop to percentages

CALLED BY:	NDDesktopViewSizeChanged, NDDesktopSaveIconPositions

PASS:		*ds:si - NDDesktopClass object

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopConvertPositionsToPercentages	proc near

		class	NDDesktopClass

		uses	di

viewSize	local	Point

		.enter

	;
	; See if things are already as percentages
	;
		DerefFolderObject	ds, si, di
		test	ds:[di].FOI_positionFlags, mask FIPF_PERCENTAGES
		jnz	done

	;
	; Set the percentages and the RECALC flags, so next time we
	; get a DRAW message, we'll convert back to positions!
	;

		ornf	ds:[di].FOI_positionFlags, mask FIPF_PERCENTAGES \
				or mask FIPF_RECALC

		movP	ss:[viewSize], ds:[di].FOI_winBounds, ax

		mov	ax, cs
		mov	bx, offset ConvertPositionToPercentageCB
		mov	di, FCT_POSITIONED
		call	FolderSendToChildren
done:
		.leave
		ret
NDDesktopConvertPositionsToPercentages	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertPositionToPercentageCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to convert this object's position to
		a percentage

CALLED BY:	NDDesktopConvertPositionsToPercentages via
		FolderSendToDisplayList 

PASS:		ss:bp - inherited local vars
		ds:di - FolderRecord

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	We assume that the passed position coordinates are within the
	range -2048<=N<=2047. This is good enough to handle almost anything
	that would happen on a 1024x768 screen.

	Next, we multiple this value by 16384, which will ensure that the
	quotient has a great deal of fractional information built-into it.
	(Remember that the divide instruction returns an integer.)

	16384 is the maximum scale factor that we can use when you consider
	the range of input values, and the fact that the signed dividend has to
	fit into the 32-bit register pair DX:AX, in order for the quotient
	to fit in the to 16-bit AX register.

	It is not necessary to round the resulting value, since that would
	only affect the least-significant digit of the quotient (which would
	improve out accuracy by .06% at best.

	However, note that when converting this "percentage" back to
	a screen coordinate, rounding is ESSENTIAL, since you will
	end up with position values like 45.99996.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertPositionToPercentageCB	proc far

		.enter	inherit	NDDesktopConvertPositionsToPercentages

	;
	; If the bounds are larger than the view size, then just bail.
	;
		mov	ax, ds:[di].FR_iconBounds.R_right
		cmp	ax, ss:[viewSize].P_x
		ja	done

		mov	ax, ds:[di].FR_iconBounds.R_bottom
		cmp	ax, ss:[viewSize].P_y
		ja	done

		
		mov	dx, ds:[di].FR_iconBounds.R_left
		clr	ax
		sardw	dxax
		sardw	dxax
		div	ss:[viewSize].P_x
		mov	ds:[di].FR_iconBounds.R_left, ax

		mov	dx, ds:[di].FR_iconBounds.R_top
		clr	ax
		sardw	dxax
		sardw	dxax
		div	ss:[viewSize].P_y
		mov	ds:[di].FR_iconBounds.R_top, ax
		ornf	ds:[di].FR_state, mask FRSF_PERCENTAGE
done:
		clc
		.leave
		ret
ConvertPositionToPercentageCB	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopSaveIconPositions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Convert positions to percentages before calling superclass

PASS:		*ds:si	- NDDesktopClass object
		ds:di	- NDDesktopClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDDesktopSaveIconPositions	method	dynamic	NDDesktopClass, 
					MSG_FOLDER_SAVE_ICON_POSITIONS
		uses	ax,cx,dx,bp
		.enter

		call	NDDesktopConvertPositionsToPercentages

		.leave

		mov	di, offset NDDesktopClass
		GOTO	ObjCallSuperNoLock
NDDesktopSaveIconPositions	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopSetDisplayOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- NDDesktopClass object
		ds:di	- NDDesktopClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDDesktopSetDisplayOptions	method	dynamic	NDDesktopClass, 
					MSG_SET_DISPLAY_OPTIONS

		uses	ax,cx,dx,bp

		.enter

	;
	; Mark all the FolderRecords as unpositioned
	;
		mov	ax, cs
		mov	bx, offset MarkUnpositionedCB
		mov	di, FCT_ALL
		call	FolderSendToChildren

		.leave
		mov	di, offset NDDesktopClass
		GOTO	ObjCallSuperNoLock
NDDesktopSetDisplayOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopRedrawWastebasket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	redraw wastebasket icon

PASS:		*ds:si	- NDDesktopClass object
		ds:di	- NDDesktopClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       brianc	12/28/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopRedrawWastebasket	method	dynamic	NDDesktopClass, 
					MSG_ND_DESKTOP_REDRAW_WASTEBASKET
	;
	; lock folder buffer and find wastebasket
	;
		call	FolderLockBuffer
		jz	done
		DerefFolderObject	ds, si, di
		mov	bp, ds:[di].DVI_gState
		mov	di, ds:[di].FOI_displayList
findLoop:
		cmp	di, NIL
		je	notFound
		cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_WASTEBASKET
		je	gotIt
		mov	di, es:[di].FR_displayNext
		jmp	short findLoop
	;
	; invalidate it
	;
gotIt:
		push	ds
		segmov	ds, es
		call	FolderRecordInvalRect
		pop	ds
	;
	; unlock folder buffer
	;
notFound:
		call	FolderUnlockBuffer
done:
		ret
NDDesktopRedrawWastebasket	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MarkUnpositionedCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to mark the FolderRecord unpositioned

CALLED BY:	NDDesktopSetDisplayOptions via FolderSendToChildren

PASS:		ds:di - FolderRecord

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MarkUnpositionedCB	proc far
		or	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		ret
MarkUnpositionedCB	endp




FolderCode	ends

;--------------------

FolderAction	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopStartOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If both left and right mouse buttons are pressed,
		then bring up the Window List Dialog.
		(but only if we are not in the middle of a move copy.)

CALLED BY:	MSG_META_START_OTHER

PASS:		*ds:si	= NDDesktopClass object
		ds:di	= NDDesktopClass instance data
		ds:bx	= NDDesktopClass object (same as *ds:si)
		es 	= segment of NDDesktopClass
		ax	= message #
		bp low  - ButtonInfo		(In input.def)
			  mask BI_PRESS		- set if press
			  mask BI_DOUBLE_PRESS	- set if double-press
			  mask BI_B3_DOWN	- state of button 3
			  mask BI_B2_DOWN	- state of button 2
			  mask BI_B1_DOWN	- state of button 1
			  mask BI_B0_DOWN	- state of button 0
			  mask BI_BUTTON	- for non-PTR events, is
						  physical button which has
						  caused this event to be
						  generated.
		bp high - UIFunctionsActive	(In Objects/uiInputC.def)

RETURN:		ax	- MouseReturnFlags	(In Objects/uiInputC.def)
 			  mask MRF_PROCESSED - if event processed by gadget.
 			  mask MRF_REPLAY    - causes a replay of the button
					       to the modified implied/active
					       grab.
			  mask MRF_SET_POINTER_IMAGE - sets the PIL_GADGET
			  level cursor based on the value of cx:dx:
			  cx:dx	- optr to PointerDef in sharable memory block,
			  OR cx = 0, and dx = PtrImageValue (Internal/im.def)
			  mask MRF_CLEAR_POINTER_IMAGE - Causes the PIL_GADGET
						level cursor to be cleared
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/ 3/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopStartOther	method dynamic NDDesktopClass, 
					MSG_META_START_OTHER
	test	ss:[fileDragging], mask FDF_MOVECOPY or mask FDF_DRAG_STARTED
	jnz	callSuper

	mov	di, bp
	andnf	di, mask BI_PRESS or mask BI_B0_DOWN or mask BI_B2_DOWN
	cmp	di, mask BI_PRESS or mask BI_B0_DOWN or mask BI_B2_DOWN
	je	bringUpDialog

callSuper:
	mov	di, offset NDDesktopClass
	GOTO	ObjCallSuperNoLock

bringUpDialog:
	mov	ax, MSG_GEN_GUP_QUERY
	mov	cx, GUQT_FIELD
	call	UserCallApplication		; ^lcx:dx = field
	jnc	done				; exit if no field

	mov	ax, MSG_GEN_FIELD_OPEN_WINDOW_LIST
	movdw	bxsi, cxdx
	mov	di, mask MF_CALL
	call	ObjMessage			; bring up window list dialog
done:
	mov	ax, mask MRF_PROCESSED
	ret
NDDesktopStartOther	endm

FolderAction	ends

;--------------------

if _NEWDESKBA
NDFolderCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopCheckTransferEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns carry clear, because the generic folderclass accepts 
		everything and has no special behavior.

CALLED BY:	MSG_SHELL_OBJECT_CHECK_TRANSFER_ENTRY

PASS:		ds:si - handle of NDDesktopClass instance data
		dx:0  - FileQuickTransferHeader
		dx:bp - FileOperationInfoEntry in the FileQuickTransfer
		cx    - number of transfer entry to process (ordered
			from num_files down to 1)
		current directory is the destination directory (dest. object)

RETURN:		carry - clear, if no special handling is necessary.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/25/92		Initial version
	joon	11/2/92		Handle student utility drive

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopCheckTransferEntry	method	NDDesktopClass,
					MSG_SHELL_OBJECT_CHECK_TRANSFER_ENTRY
	uses	ax, cx, dx
	.enter
	;
	; If this is a list operation, abort
	;
	push	ds
	mov	ds, dx
	tstListTransfer ds
	pop	ds
	jz	regularTransfer	

	cmp	cx, 1					; put up error box
	jne	specialHandling				;  for last item only

	push	ds
	mov	ds, dx
	cmp	ds:[FQTH_UIFA].low, mask BATT_LIST_OPERATION or \
					(BLT_PEOPLE shl offset BATT_LIST_TYPE)
	pop	ds

	mov	ax, ERROR_CANT_CREATE_STUDENT_UTILITY_FROM_LIST
	je	haveError
	mov	ax, ERROR_DESKTOP_UNSUPPORTED_TRANSFER_OPERATION
haveError:
	call	DesktopOKError
	jmp	short specialHandling

regularTransfer:
	DerefFolderObject	ds, si, di
	mov	bx, ds:[di].FOI_fileCount
	mov	di, ds:[di].FOI_buffer

	mov	ds, dx					; ds = transfer block
	mov	ax, ds:[bp].FOIE_info
	cmp	ax, WOT_STUDENT_HOME_TVIEW
	je	createSUD
	cmp	ax, WOT_FOLDER
	je	done					; allow it
	cmp	ax, WOT_DOCUMENT
	je	done					; allow it
	cmp	ax, WOT_EXECUTABLE
	je	done					; allow it
NDONLY<	mov	ax, ERROR_ND_OBJECT_NOT_ALLOWED>
BA <	mov	ax, ERROR_DESKTOP_UNSUPPORTED_TRANSFER_OPERATION >
errorSUD:
	mov	si, bp					; ds:si is FOIE
	segmov	es, ss, di
	mov	di, offset fileOperationInfoEntryBuffer	; es:di is buff.
	mov	cx, size FileOperationInfoEntry
	rep	movsb
	call	DesktopOKError
	jmp	short specialHandling

createSUD:
	cmp	cx, 1					; deal with last item
	jne	specialHandling				;  only

	mov	dx, bp					; ds:dx = FOIE_name
	mov	ax, WARNING_CREATING_STUDENT_UTILITY_DRIVE
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES			; delete?
	jne	specialHandling

	mov	cx, bx					; cx <= FOI_fileCount
	call	NDDesktopCreateStudentUtilityDrive
	jnc	specialHandling

	cmp	ax, -1
	je	genericStudentError
	mov	ax, ERROR_CREATING_STUDENT_UTILITY
	jmp	errorSUD
genericStudentError:
	mov	ax, ERROR_GENERICS_CANT_BE_STUDENT_UTILITY
	jmp	errorSUD

specialHandling:
	stc
done:
	.leave
	ret
NDDesktopCheckTransferEntry	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopCreateStudentUtilityDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a student utility drive on the teacher's DESKTOP

CALLED BY:	NDDesktopCheckTransferEntry

PASS:		ds:0	- FileQuickTransferHeader
		ds:bp	- FileOperationInfoEntry in the FileQuickTransfer
		di	- memory block containing FolderRecords (FOI_buffer)
		cx	- number of FolderRecords (FOI_fileCount)

RETURN:		carry set - if error an occurred,
		            ax - FileError or -1 if the passed student is a
				generic

DESTROYED:	ax, bx, cx, dx, si, di, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/1/92    	Initial version
	dloft	3/5/93		Changed to use new WOT_STUDENT_UTILITY and
				added multi-volume support.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
genericDir	char	C_BACKSLASH, 'GENERICS', C_NULL

NDDesktopCreateStudentUtilityDrive	proc	near
passedBP	local	word	push	bp
FQTBlock	local	sptr	push	ds
driveName	local	word
actualPath	local	PathName
pathWithVolume	local	PathName

	uses	ds
	.enter

	jcxz	createSUD
	call	NDDesktopDeleteStudentUtilityDrive
	LONG jc	done

createSUD:
	;
	; Construct the path of the student link
	;	
	mov	si, offset FQTH_pathname
	segmov	es, ss
	lea	di, ss:[pathWithVolume]
	LocalCopyString
	mov	{byte} es:[di-1], '\\'
	mov	si, ss:[passedBP]
	LocalCopyString
copyDone::
	;
	; Construct the path of the student's home
	;	
	mov	bx, ds:[FQTH_diskHandle]
	clr	dx				; no drive label
	segmov	ds, ss
	lea	si, ss:[pathWithVolume]		; ds:si -> student link
	lea	di, ss:[actualPath]		; es:di -> buffer
	mov	cx, size PathName
	call	FileConstructActualPath		; bx <- disk handle of student's
						; home dir
	jc	done
	;
	; See if this is a valid path
	;	
	segmov	ds, cs
	mov	si, offset genericDir
	clr	cx
	call	LocalCmpStrings
	jz	genericError
	;
	; Overwrite pathWithVolume using the disk name and the student's home dir
	;
	lea	di, ss:[pathWithVolume]
	call	DiskGetVolumeName		; fill in volume name
	mov	al, C_NULL
	mov	cx, -1
	repne	scasb
	dec	di

	mov	al, ':'
	stosb

	segmov	ds, ss
	lea	si, ss:[actualPath]
	call	FolderStrlen
	call	FolderCopyMem			; append actual path to disk
						; name
	mov	ds, ss:[FQTBlock]
	mov	dx, ss:[passedBP]		; ds:dx = student name
	lea	di, ss:[actualPath]
	mov	ax, WOT_STUDENT_UTILITY
	call	IclasCreateSpecialLink
	jc	done

	mov	al, 'S' - 'A'			; drive S:
	call	FSDDeleteDrive

	mov	{word} ss:[driveName], 'S'

	mov	cx, ss
	lea	dx, ss:[driveName]
	mov	ds, cx
	lea	si, ss:[pathWithVolume]
	mov	bl, 'S'
	call	NetMapDrive
done:
	.leave
	ret
genericError:
	mov	ax, -1
	stc
	jmp	done
NDDesktopCreateStudentUtilityDrive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopDeleteStudentUtilityDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all existing files of type WOT_STUDENT_UTILITY

CALLED BY:	NDDesktopCreateStudentUtilityDrive

PASS:		di	- memory block containing FolderRecords (FOI_buffer)
		cx	- number of FolderRecords (FOI_fileCount)

RETURN:		carry set - if an error occurred,
				ax - FileError

DESTROYED:	ax, bx, cx, dx, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	11/ 1/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopDeleteStudentUtilityDrive	proc	near
	uses	ds
	.enter

	mov	bx, di
	call	MemLock
	mov	ds, ax

	mov	di, offset FBH_buffer

fileLoop:
	cmp	ds:[di].FR_desktopInfo.DI_objectType, WOT_STUDENT_UTILITY
	jne	nextRecord

	lea	dx, ds:[di].FR_name
	push	cx			;cx is destroyed by FileDelete
	call	FileDelete
	pop	cx			;tell ChrisB
	jc	unlock

nextRecord:
	add	di, size FolderRecord
	loop	fileLoop

unlock:
	call	MemUnlock
	.leave
	ret
NDDesktopDeleteStudentUtilityDrive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- NDDesktopClass object
		ds:di	- NDDesktopClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/13/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDDesktopScan	method	dynamic	NDDesktopClass, 
					MSG_SCAN
		.enter
	;
	; Grab (and then release) the desktop, so that the folder scan
	; happens AFTER desktop verification is finished.  Keeps weird
	; hooey from happening on the desktop.
	;
		call	IclasGrabDesktop
		call	IclasReleaseDesktop

		.leave
		mov	di, offset NDDesktopClass
		GOTO	ObjCallSuperNoLock

NDDesktopScan	endm

NDFolderCode ends

endif		; if _NEWDESKBA
