COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		mainProcess.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for WriteProcessClass

	$Id: mainProcess.asm,v 1.1 97/04/04 15:57:08 newdeal Exp $

------------------------------------------------------------------------------@

ifdef _VS150
include	rolodex.def
endif

ifdef _SUPER_IMPEX
include fileEnum.def
include library.def
include Internal\xlatLib.def
endif

GeoWriteClassStructures	segment	resource
	WriteProcessClass
GeoWriteClassStructures	ends

idata	segment
miscSettings	WriteMiscSettings
if _BATCH_RTF
batchInfo		hptr	(NULL)
endif
idata ends

AppInitExit segment resource


COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteProcessUIInstallToken -- MSG_GEN_PROCESS_INSTALL_TOKEN
						for WriteProcessClass

DESCRIPTION:	Install the tokens for GeoWrite

PASS:
	*ds:si - instance data
	es - segment of WriteProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/18/92		Initial version

------------------------------------------------------------------------------@
WriteProcessUIInstallToken	method dynamic	WriteProcessClass,
						MSG_GEN_PROCESS_INSTALL_TOKEN
	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset WriteProcessClass
	call	ObjCallSuperNoLock

	; install datafile token

	mov	ax, ('W') or ('D' shl 8)	; ax:bx:si = token used for
	mov	bx, ('A') or ('T' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
	mov	cx, handle DatafileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset DatafileMonikerList
	clr	bp				; list is in data resource, so
						;  it's already relocated
	call	TokenDefineToken		; add icon to token database
done:

	ret

WriteProcessUIInstallToken	endm

ifdef GPC
WriteProcessOpenApplication	method dynamic	WriteProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION
	;
	; Call our superclass to get the ball rolling...
	;
	mov	di, offset WriteProcessClass
	call	ObjCallSuperNoLock
	;
	; set View to 125% if TV. If we're not on the TV, then look at
	; the .INI file to determine what value to use, and by default
	; use 100%.
	;
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	UserCallApplication
	and	ah, mask DT_DISP_ASPECT_RATIO
	cmp	ah, DAR_TV shl offset DT_DISP_ASPECT_RATIO
	mov	dx, 125			; 125%
	je	setView
	;
	; OK - we're not on the TV. Check the .INI file. Note that
	; we use the category key defined in the application object,
	; which must *always* be defined!
	;
	sub	sp, MAX_INITFILE_CATEGORY_LENGTH
	mov	cx, ss
	mov	dx, sp
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	UserCallApplication
EC <	ERROR_NC WRITE_INTERNAL_LOGIC_ERROR				>

	mov	ds, cx			; category => DS:SI
	mov	si, dx
	mov	cx, cs
	mov	dx, offset defaultZoomKey
	mov	ax, 100			; default to 100%
	call	InitFileReadInteger
	add	sp, MAX_INITFILE_CATEGORY_LENGTH
	mov_tr	dx, ax			; default zoom value => DX
	;
	; Finally - set the view scale factor
	;
setView:
	GetResourceHandleNS	WriteViewControl, bx
	mov	si, offset WriteViewControl
	mov	ax, MSG_GVC_SET_SCALE
	clr	di
	GOTO	ObjMessage
WriteProcessOpenApplication	endm

defaultZoomKey	char	"defaultZoom", 0
endif

AppInitExit ends

;---

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteProcessInsertColumnBreak --
		MSG_WRITE_PROCESS_INSERT_COLUMN_BREAK for WriteProcessClass

DESCRIPTION:	Insert a C_COLUMN_BREAK character

PASS:
	*ds:si - instance data
	es - segment of WriteProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 9/92		Initial version

------------------------------------------------------------------------------@
WriteProcessInsertColumnBreak	method dynamic	WriteProcessClass,
					MSG_WRITE_PROCESS_INSERT_COLUMN_BREAK

SBCS <	mov	cx, (VC_ISCTRL shl 8) or VC_ENTER			>
DBCS <	mov	cx, C_SYS_ENTER						>
	mov	dx, (mask SS_LCTRL) shl 8
	mov	ax, MSG_META_KBD_CHAR

	mov	di, mask MF_RECORD
	call	EncapsulateToTargetVisText
	ret

WriteProcessInsertColumnBreak	endm

;---

EncapsulateToTargetVisText	proc	far

	;
	; Encapsulate the message the caller wants, sending it to a VisText
	; object.
	; 
	push	si
	mov	bx, segment VisTextClass
	mov	si, offset VisTextClass
	call	ObjMessage
	pop	si

	;
	; Now queue the thing to the app target, since we can't rely on the
	; model hierarchy to match the target hierarchy (e.g. when editing
	; a master page, the WriteDocument still has the model, but the
	; WriteMasterPageContent object has the target). This bones anything
	; that must be synchronous, but such is life.
	; 
	mov	cx, di
	mov	dx, TO_APP_TARGET
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_FORCE_QUEUE		;keep that stack usage down
	call	ObjMessage
	ret

EncapsulateToTargetVisText	endp

DocCommon ends

DocDrawScroll segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNowAsTimeStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the current date and time into two 16-bit records
		(FileDate and FileTime)

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ax	= FileDate
		bx	= FileTime
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/4/92		Stolen from primary IFS drivers (hence the
				formatting)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNowAsTimeStamp	proc	far
		uses	cx, dx
		.enter
		call	TimerGetDateAndTime
	;
	; Create the FileDate record first, as we need to use CL to the end...
	; 
		sub	ax, 1980	; convert to fit in FD_YEAR
			CheckHack <offset FD_YEAR eq 9>
		mov	ah, al
		shl	ah		; shift year into FD_YEAR
		mov	al, bh		; install FD_DAY in low 5 bits
		
		mov	cl, offset FD_MONTH
		clr	bh
		shl	bx, cl		; shift month into place
		or	ax, bx		; and merge it into the record
		xchg	dx, ax		; dx <- FileDate, al <- minutes,
					;  ah <- seconds
		xchg	al, ah
	;
	; Now for FileTime. Need seconds/2 and both AH and AL contain important
	; stuff, so we can't just sacrifice one. The seconds live in b<0:5> of
	; AL (minutes are in b<0:5> of AH), so left-justify them in AL and
	; shift the whole thing enough to put the MSB of FT_2SEC in the right
	; place, which will divide the seconds by 2 at the same time.
	; 
		shl	al
		shl	al		; seconds now left justified
		mov	cl, (8 - width FT_2SEC)
		shr	ax, cl		; slam them into place, putting 0 bits
					;  in the high part
	;
	; Similar situation for FT_HOUR as we need to left-justify the thing
	; in CH, so just shift it up and merge the whole thing.
	; 
		CheckHack <(8 - width FT_2SEC) eq (8 - width FT_HOUR)>
		shl	ch, cl
		or	ah, ch
		mov_tr	bx, ax		; bx <- time
		mov_tr	ax, dx		; ax <- date
		.leave
		ret
GetNowAsTimeStamp	endp

DocDrawScroll ends

DocMiscFeatures segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteProcessInsertTextualDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a textual representation of the current date or
		time into the document at the current insertion point.

CALLED BY:	MSG_WRITE_PROCESS_INSERT_TEXTUAL_DATE_TIME
PASS:		cx	= DateTimeFormat to use
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteProcessInsertTextualDateTime method dynamic WriteProcessClass, 
				MSG_WRITE_PROCESS_INSERT_TEXTUAL_DATE_TIME
	.enter
	;
	; Allocate a block into which we can put the text, since we can't
	; make this call synchronous.
	; 
	push	cx
	mov	ax, DATE_TIME_BUFFER_SIZE
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	pop	si			; si <- DateTimeFormat
	jc	done
	
	;
	; Format the current time appropriately.
	; 
	mov	es, ax
	push	bx
	clr	di			; es:di <- destination
	call	TimerGetDateAndTime	; get now
	call	LocalFormatDateTime	; format now
	pop	dx		; dx <- handle
	mov	bx, dx
	call	MemUnlock	; guess what?

	;
	; Now send the block off to the target text object to replace the
	; current selection.
	; 
	mov	ax, 1
	call	MemInitRefCount		; set reference count to 1 so when the
					;  target vistext decrements it for us
					;  it will go away
	mov	ax, MSG_VIS_TEXT_REPLACE_SELECTION_BLOCK
	mov	di, mask MF_RECORD
	push	dx
	call	EncapsulateToTargetVisText
	pop	cx
	
	;
	; Send a message to the same place to decrement the reference count
	; for that block so it goes away when the text object is done with it.
	; 
	mov	ax, MSG_META_DEC_BLOCK_REF_COUNT
	clr	dx			; no second handle
	mov	di, mask MF_RECORD
	call	EncapsulateToTargetVisText
done:
	.leave
	ret
WriteProcessInsertTextualDateTime endm

if _INDEX_NUMBERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteProcessTOCContextListVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_PROCESS_TOC_CONTEXT_LIST_VISIBLE
PASS:		^lcx:dx	= list
		bp	= non-zero if visible
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteProcessTOCContextListVisible		method dynamic WriteProcessClass, MSG_WRITE_PROCESS_TOC_CONTEXT_LIST_VISIBLE
		.enter
		tst	bp
		jz	done
		mov	ax, MSG_WRITE_DOCUMENT_TOC_CONTEXT_LIST_VISIBLE
		mov	bx, es
		mov	si, offset WriteDocumentClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	dx, TO_MODEL
		GetResourceHandleNS	WriteDocumentGroup, bx
		mov	si, offset WriteDocumentGroup
		mov	di, mask MF_CALL
		call	ObjMessage
done:
		.leave
		ret
WriteProcessTOCContextListVisible		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteProcessInsertContextNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_PROCESS_INSERT_CONTEXT_NUMBER
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteProcessInsertContextNumber		method dynamic WriteProcessClass, MSG_WRITE_PROCESS_INSERT_CONTEXT_NUMBER
		mov	si, offset InsertContextNumberNumberList
		mov	di, offset InsertContextNumberFormatList
		GOTO	WriteProcessInsertVariableCommon
WriteProcessInsertContextNumber		endm

endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteProcessInsertNumber -- MSG_WRITE_PROCESS_INSERT_NUMBER
							for WriteProcessClass

DESCRIPTION:	Insert a number

PASS:
	*ds:si - instance data
	es - segment of WriteProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
WriteProcessInsertNumber	method dynamic	WriteProcessClass,
						MSG_WRITE_PROCESS_INSERT_NUMBER

	mov	si, offset NumberTypeList
	mov	di, offset NumberFormatList
	GOTO	WriteProcessInsertVariableCommon
WriteProcessInsertNumber	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteProcessInsertNumber -- MSG_WRITE_PROCESS_INSERT_DATE
							for WriteProcessClass

DESCRIPTION:	Insert a date

PASS:
	*ds:si - instance data
	es - segment of WriteProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
WriteProcessInsertDate	method dynamic	WriteProcessClass,
						MSG_WRITE_PROCESS_INSERT_DATE

	mov	si, offset DateTypeList
	mov	di, offset DateFormatList
	GOTO	WriteProcessInsertVariableCommon
WriteProcessInsertDate	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteProcessInsertTime -- MSG_WRITE_PROCESS_INSERT_TIME
							for WriteProcessClass

DESCRIPTION:	Insert a time

PASS:
	*ds:si - instance data
	es - segment of WriteProcessClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
WriteProcessInsertTime	method dynamic	WriteProcessClass,
						MSG_WRITE_PROCESS_INSERT_TIME

	mov	si, offset TimeTypeList
	mov	di, offset TimeFormatList
	FALL_THRU	WriteProcessInsertVariableCommon
WriteProcessInsertTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteProcessInsertVariableCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to handle inserting a number, date, or time

CALLED BY:	(INTERNAL) WriteProcessInsertNumber,
			   WriteProcessInsertDate,
			   WriteProcessInsertTime
PASS:		^lbx:si	= GenItemGroup with selected number/date/time
		^lbx:di = GenItemGroup with selected format
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteProcessInsertVariableCommon proc	far
		CheckHack <segment NumberTypeList eq segment DateTypeList>
		CheckHack <segment NumberTypeList eq segment TimeTypeList>

	GetResourceHandleNS	NumberTypeList, bx
	push	di
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = type
	pop	si
	push	ax

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = format
	mov_tr	bp, ax				;bp = format
	pop	dx
	mov	cx, MANUFACTURER_ID_GEOWORKS

	FALL_THRU	WriteProcessInsertVariableGraphic
WriteProcessInsertVariableCommon endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteProcessInsertVariableGraphic --
		MSG_WRITE_PROCESS_INSERT_VARIABLE_GRAPHIC for WriteProcessClass

DESCRIPTION:	Insert a variable type graphic

PASS:
	*ds:si - instance data
	es - segment of WriteProcessClass

	ax - The message

	cx - manufacturer ID
	dx - VisTextVariableType
	bp - data

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
WriteProcessInsertVariableGraphic	method WriteProcessClass,
				MSG_WRITE_PROCESS_INSERT_VARIABLE_GRAPHIC

	mov	bx, bp				;bx = data

	sub	sp, size ReplaceWithGraphicParams
	mov	bp, sp

	; zero out the structure

	segmov	es, ss
	mov	di, bp
	push	cx
	mov	cx, size ReplaceWithGraphicParams
	clr	ax
	rep	stosb
	pop	cx

	mov	ss:[bp].RWGP_graphic.VTG_type, VTGT_VARIABLE
	mov	ss:[bp].RWGP_graphic.VTG_flags, mask VTGF_DRAW_FROM_BASELINE
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_manufacturerID,
									cx
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_type, dx
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData, bx

	mov	ax, VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].RWGP_range.VTR_start.high, ax
	mov	ss:[bp].RWGP_range.VTR_end.high, ax

	;
	; If it's MANUFACTURER_ID_GEOWORKS:VTVT_STORED_DATE_TIME, we need to get
	; the current date and time and store them in the 2d and 3d words of
	; private data.
	; 
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	doReplace
	cmp	dx, VTVT_STORED_DATE_TIME
if _INDEX_NUMBERS
	jne	checkContext
else
	jne	doReplace
endif
	call	GetNowAsTimeStamp
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[2],
			ax	; date
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[4],
			bx	; time
doReplace:
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	mov	dx, size ReplaceWithGraphicParams
	mov	di, mask MF_RECORD or mask MF_STACK
	call	EncapsulateToTargetVisText

	add	sp, size ReplaceWithGraphicParams
	ret

if _INDEX_NUMBERS
checkContext:
	;
	; If it's a context thing, we have to get the context to use.
	; 
	cmp	dx, VTVT_CONTEXT_PAGE
	jb	doReplace
	cmp	dx, VTVT_CONTEXT_SECTION
	ja	doReplace

	GetResourceHandleNS	InsertContextNumberContextList, bx
	mov	si, offset InsertContextNumberContextList
	push	bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = type index
	
	;
	; Find the current document from the document group by asking it for the
	; model.
	; 
	GetResourceHandleNS	WriteDocumentGroup, bx
	mov	si, offset WriteDocumentGroup
	push	ax
	mov	ax, MSG_META_GET_MODEL_EXCL
	mov	di, mask MF_CALL
	call	ObjMessage
	movdw	bxsi, cxdx
	pop	cx

	;
	; Map the index to the token via that document.
	; 
	mov	ax, MSG_WRITE_DOCUMENT_GET_TOKEN_FOR_CONTEXT
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
	
	mov	{word} \
		ss:[bp].RWGP_graphic.VTG_data.VTGD_variable.VTGV_privateData[2],
			cx
	jmp	doReplace
endif

WriteProcessInsertVariableGraphic	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteProcessPrintDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_PROCESS_PRINT_DIALOG
PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	9/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150

WriteProcessPrintDialog	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_PRINT_DIALOG
	uses	ax, cx, dx, bp
	.enter
	GetResourceHandleNS	WritePrintControl, bx
	mov	si, offset WritePrintControl
	mov	ax, MSG_PRINT_CONTROL_INITIATE_PRINT
	clr	di
	call	ObjMessage
	.leave
	ret
WriteProcessPrintDialog	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteProcessMergeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_PROCESS_MERGE_FILE
PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	6/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150

GeoDexTokens 	char	"ADBK", 0, 0

WriteProcessMergeFile	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_MERGE_FILE
	uses	ax, cx, dx, bp
	.enter
	push	si
	mov	cx, IC_DISMISS
	CallObject	MSG_GEN_GUP_INTERACTION_COMMAND, MergeFileSelector
	pop	si
	;
	; Create a launch block so IACP can launch the app if it's not
	; around yet.
	; 
	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	CreateAppLaunchBlock
	jc	exit
	;
	; Connect to the server, telling IACP to create it if it's not there.
	; 
	segmov	es, cs
	mov	di, offset GeoDexTokens
	mov	ax, mask IACPCF_FIRST_ONLY or \
		(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	call	IACPConnect
	jc	exit

	clr	cx
	push	cx, bp
	mov	ax, MSG_ROLODEX_MERGE_DIALOG
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	cx, bp
	mov	bx, di			; bx <- msg to send
	mov	dx, TO_PROCESS
	mov	ax, IACPS_CLIENT
	;
	; PASS:           bp      = IACPConnection
	;                 bx      = recorded message to send
	;                 dx      = TravelOption, -1 if recorded message
	;				contains the proper destination already
	;                 cx      = completionMsg, 0 if none
	;                 ax      = IACPSide doing the sending.
	; RETURN:         ax      = number of servers to which message was sent
	;
	call	IACPSendMessage

	; That's it, we're done.  Shut down the connection we opened up, so
	; that GeoDex is allowed to exit.  -- Doug 2/93
	;
	clr	cx, dx			; shutting down the client
	call	IACPShutdown
	clc	
exit:		
	.leave
	ret
WriteProcessMergeFile	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			CreateAppLaunchBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates AppLaunchBlock for launching GeoDex.

CALLED BY:	
PASS:
RETURN:		bx	- handle of AppLaunchBlock

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BCHOW	6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150

CreateAppLaunchBlock	proc	far	uses	bp, di, ds, es
	.enter
	;
	; set up AppLaunchBlock for UserLoadApplication
	;
	mov	ax, size AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE or \
					ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	mov	es, ax
	jc	error
	;
	; enough memory to allocate block
	;
	; bx = AppLaunchBlock
	;
	mov	es:[ALB_appRef.AIR_fileName], 0
	mov	es:[ALB_appRef.AIR_stateFile], 0
	mov	es:[ALB_appRef.AIR_diskHandle], 0
	mov	es:[ALB_appRef.AIR_savedDiskData], 0
	;
	; launching datafile
	;
	mov	es:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION
	clr	es:[ALB_launchFlags]
	;
	; get the name of the file selected into ALB_dataFile
	;
	push	si, bx
	mov	cx, es
	lea	dx, es:[ALB_dataFile]
	mov     si, offset MergeFileSelector
	GetResourceHandleNS     MergeFileSelector, bx
	mov     ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov     di, mask MF_CALL
	call    ObjMessage
	;
	; get the path name of the datafile into ALB_path, and the
	; disk handle into ALB_diskHandle
	;
	mov	dx, es
	lea	bp, es:[ALB_path]
	mov     si, offset MergeFileSelector
	mov	cx, PATH_BUFFER_SIZE
	GetResourceHandleNS     MergeFileSelector, bx
	mov     ax, MSG_GEN_PATH_GET
	mov     di, mask MF_CALL
	call    ObjMessage
	mov	es:[ALB_diskHandle], cx
	pop	si, bx
	;
	; bx = AppLaunchBlock
	;
	call	MemUnlock
	clc
error:
	.leave
	ret
CreateAppLaunchBlock	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MergeFileCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current selection is a directory or
		a normal file and enables or disables the "OK"
		button accordingly.  Also edits or creates double-clicked file.

CALLED BY:	GLOBAL
PASS:	 	cx:dx - OD of GenFileSelector (will be needed later when
				default-action support is added)
		bp - 	GenFileSelectorEntryFlagsh       record

RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/11/92		Stole from wTrans

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150

MergeFileCheck	method WriteProcessClass, MSG_WRITE_PROCESS_MERGE_FILE_CHECK
	.enter

	GetResourceHandleNS	MergeTrigger, bx
	mov	si, offset MergeTrigger

objectSet:
	mov	ax, MSG_GEN_SET_NOT_ENABLED	;Assume its NOT a normal file
	push	bp
	test	bp, mask GFSEF_NO_ENTRIES	;If nothing selected, treat
	jne	common				; like directory
	and	bp, mask GFSEF_TYPE 
	cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
	jne	common				;Branch if not a file
	mov	ax, MSG_GEN_SET_ENABLED	;Not a dir, so is a normal file
common:
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	pop	bp
	cmp	ax, MSG_GEN_SET_ENABLED
	jne	exit
	test	bp, mask GFSEF_OPEN		;If double click, activate 
	je	exit				; default button
	mov	ax, MSG_GEN_ACTIVATE
	mov	di, mask MF_CALL
	call	ObjMessage
exit:
	.leave
	ret
MergeFileCheck	endm

endif

ifdef	PRODUCT_TOOLS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetImportStyleSheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the style sheet to apply when importing
		from RTF format.  The Writer file which the style sheet
		is taken from is selected on the StyleSheetFileSelector.
		(TOOLS only)

CALLED BY:	MSG_WRITE_PROCESS_SET_IMPORT_STYLE_SHEET

PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	The selected style sheet is automatically applied to any
		RTF document imported from this moment forward.  The style
		sheet path/filename is saved in the INI file under the [write]
		category as the autoStyleSheet key.

PSEUDO CODE/STRATEGY:

	1. Get the file and pathname from the file selector.
	2. Set the autoStyleSheet key with the acquired path/filename.	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	11/17/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetImportStyleSheet	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_SET_IMPORT_STYLE_SHEET
	styleSheetPathname	local	(FILE_LONGNAME_BUFFER_SIZE + PATH_BUFFER_SIZE) dup (char)
	fullPath		local	(FILE_LONGNAME_BUFFER_SIZE + PATH_BUFFER_SIZE) dup (char)
	uses	ax, cx, dx, di, si, bp
	.enter
	
	;
	; Get file and pathname from selector
	;
	GetResourceHandleNS	HelpEditUI, bx
	mov	si, offset StyleSheetFileSelector	; ^lbx:si <= fileselector optr
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	mov	cx, ss
	lea	dx, ss:[styleSheetPathname]		; cx:dx <= dest. buffer for selection
	mov	di, mask MF_CALL
	push	bp					; save Mr. Stack Frame	
	call	ObjMessage

	;
	; Ensure the selection is a file
	;
	and	bp, mask GFSEF_TYPE
	cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
	pop	bp
	jnz	notAFile

	;
	; Construct the full pathname from the drive handle returned
	;
	mov	dx, 1			; dx should be non-zero to return drive letter
	mov	bx, ax			; bx <- disk handle
	segmov	ds, ss, ax
	lea	si, ss:[styleSheetPathname]	; ds:si <- tail of path being constructed
	segmov	es, ss, ax
	lea	di, ss:[fullPath]	; es:di <- dest buffer
	mov	cx, FILE_LONGNAME_BUFFER_SIZE + PATH_BUFFER_SIZE	; cx <- buffer size
	call	FileConstructFullPath

	;
	; Set the "autoStyleSheet" INI key
	;
	segmov	es, ss, ax
	lea	di, ss:[fullPath]		; es:di <- body string (pathname)
	segmov	ds, cs, ax
	mov	si, offset writerCategory	; ds:si <- category
	mov	cx, cs
	mov	dx, offset autoStyleSheetKey	; cx:dx <- key
	call	InitFileWriteString
	call	InitFileCommit

notAFile:

	.leave
	ret
autoStyleSheetKey	char	"autoStyleSheet", 0
writerCategory		char	"write", 0
SetImportStyleSheet	endm


endif

if	_BATCH_RTF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitiateBatchExportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shows the BatchHelpFilesInteraction and then initiates
		a batch export.

CALLED BY:	MSG_WRITE_PROCESS_INITIATE_BATCH_EXPORT_UI

PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/13/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitiateBatchExportUI	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_INITIATE_BATCH_EXPORT_UI
	uses	ax
	.enter
	;
	; Setup the batch process
	;	
	mov	ax, BST_EXPORT		; setup for export
	call	BatchSetupCommon
	jc	done			; error condition in setup -- exit

	;
	; Do the export
	;
	call	ExportFileList
	
done:
	.leave
	ret
InitiateBatchExportUI	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitiateBatchImportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shows the BatchHelpFilesInteraction and then initiates
		a batch import.

CALLED BY:	MSG_WRITE_PROCESS_INITIATE_BATCH_IMPORT_UI

PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/13/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitiateBatchImportUI	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_INITIATE_BATCH_IMPORT_UI
	uses	ax
	.enter
	;
	; Setup the batch process
	;	
	mov	ax, BST_IMPORT		; setup for import
	call	BatchSetupCommon
	jc	done			; error condition in setup -- exit

	;
	; Do the import
	;
	call	ImportFileList

done:
	.leave
	ret
InitiateBatchImportUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BatchSetupCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for setting up a batch process.

CALLED BY:	InitiateBatchExportUI, InitiateBatchImportUI
PASS:		ax -- BatchSetupType
RETURN:		carry set -- error occurred (or user cancelled)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/13/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BatchSetupCommon	proc	near
	uses	ax,bx,cx,dx,si,di,bp,es
	.enter
	mov_tr	dx, ax	; preserve BatchSetupType

	;
	; Put up the batch directory selector interaction.
	;
	call	InitiateBatchInteraction
	cmp	ax, IC_OK
	jnz	userCancelled

	;
	; Allocate memory for BatchParams
	;
	call	AllocMemoryForBatchParams		; bx => new memhandle
							; ax => address of memblock
	jc	outOfMemory
	mov	es, ax					; get ready to access the data

	;
	; Get the batch path.
	;
	mov	cx, ax
	push	dx					; preserve BatchSetupType
	lea	dx, es:BEP_batchParams.DCP_path		; cx:dx => path ptr.	
	call	GetBatchPath				; bx => disk handle
	mov	es:BEP_batchParams.DCP_diskHandle, bx

	;
	; Change to selected directory.
	;
	push	ds
	mov	ds, cx					; ds:dx => path ptr.
	call	FileSetCurrentPath
	pop	ds

	;
	; Get the list of files to batch through
	;
	pop	ax				; ax <= BatchSetupType
	call	GetFileList			; cx <= number of matching files
						; bx <= memory handle of file list
	jcxz	noFiles

	mov	es:BEP_batchType, ax		; save batch type (import or export?)
	mov	es:BEP_numMatchingFiles, cx	; save num of matching files for Export/ImportFileList call
	mov	es:BEP_fileListHandle, bx	; save handle to list

	;
	; Lock down the list of files
	;
	call	MemLock
	mov	es:BEP_fileList.segment, ax
	clr	es:BEP_fileList.offset		; save the pointer to the list

	;
	; Set DocumentCommonParam fields.
	;
	mov	es:[BEP_batchParams].DCP_docAttrs, 0
	mov	es:[BEP_batchParams].DCP_flags, 0
	mov	es:[BEP_batchParams].DCP_connection, 0

	;
	; Turn off stopping flag
	;
	mov	es:[BEP_stopping], BB_FALSE

	call	SetupCommonUI	

	clc				; no errors
	jmp	done			; All ready!

noFiles:
	mov	ax, offset NoFilesToBatchString
	call	DisplayError
	stc
	jmp	done
outOfMemory:
	mov	ax, offset OutOfMemoryString
	call	DisplayError
	stc
	jmp	done
userCancelled:
	stc	
done:
	.leave
	ret
BatchSetupCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a list of files in the current directory.  If we're
		importing, it gets a list of all .RTF files in the current
		directory.  If we're exporting, it gets a list of all Writer
		files in the current directory.

CALLED BY:	BatchSetupCommon
PASS:		ax -- BatchSetupType
RETURN:		bx -- list of matching files (MemHandle)
		cx -- number of matching files
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/13/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
rtfMask			char	"*.RTF", 0
writerFileToken		GeodeToken	<"WDAT", MANUFACTURER_ID_GEOWORKS>
GetFileList	proc	near
fileEnumMatchAttrsEnd	local   FileExtAttrDesc
fileEnumMatchAttrs	local	FileExtAttrDesc
fileEnumParams		local   FileEnumParams
	uses	ax,dx,si,di,bp
	.enter
	;
	; Setup structures for FileEnum, which will return the
	; list of files we'll be acting on.
	;
	clr	bx
	mov	ss:[fileEnumParams].FEP_returnAttrs.segment, bx
	mov	ss:[fileEnumParams].FEP_returnAttrs.offset, \
			FESRT_NAME
	mov	ss:[fileEnumParams].FEP_returnSize, \
			size FileLongName	
	mov	ss:[fileEnumParams].FEP_bufSize, \
			FE_BUFSIZE_UNLIMITED
	mov	ss:[fileEnumParams].FEP_skipCount, bx
	mov     ss:[fileEnumMatchAttrsEnd].FEAD_attr, FEA_END_OF_LIST

	;
	; Are we setting up for export or import?
	;
	cmp	ax, BST_EXPORT
	jz	exportSetup

EC <	cmp	ax, BST_IMPORT	>
EC <	ERROR_NZ INVALID_BATCH_SETUP_TYPE_SPECIFIED >

	; IMPORT SETUP
	;
	; Look only for RTF files.  We'll use a callback procedure to
	; determine if a file has an RTF extension.
	;
	mov	ss:[fileEnumParams].FEP_matchAttrs.segment, 0
	mov	ss:[fileEnumParams].FEP_searchFlags, mask FESF_NON_GEOS or mask FESF_CALLBACK
	mov	ss:[fileEnumParams].FEP_callback.segment, 0
	mov	ss:[fileEnumParams].FEP_callback.offset, FESC_WILDCARD
	mov	ss:[fileEnumParams].FEP_callbackAttrs.segment, 0
	mov	ss:[fileEnumParams].FEP_cbData2.low, 1	; do the matching case-insensitive
	mov	ss:[fileEnumParams].FEP_cbData1.segment, cs
	mov	ss:[fileEnumParams].FEP_cbData1.offset, offset rtfMask	; *.RTF		
	jmp	contSetup

exportSetup:
	; EXPORT SETUP
	;
	; Look only for Writer files, which will export to RTF
	;	
	mov	ss:[fileEnumParams].FEP_matchAttrs.segment, ss
	lea	bx, ss:fileEnumMatchAttrs
	mov	ss:[fileEnumParams].FEP_matchAttrs.offset, bx
	mov	ss:[fileEnumParams].FEP_searchFlags, \
			mask FESF_GEOS_NON_EXECS
	mov	ss:[fileEnumMatchAttrs].FEAD_attr, FEA_TOKEN
	mov     ss:[fileEnumMatchAttrs].FEAD_value.offset, \
			offset writerFileToken
	mov     ss:[fileEnumMatchAttrs].FEAD_value.segment, cs
	mov     ss:[fileEnumMatchAttrs].FEAD_size, size GeodeToken

contSetup:
	;
	; Build the file list
	;
	push	ds
	segmov	ds, ss, ax
	lea	si, ss:[fileEnumParams]		; ds:si => fileEnumParams
	call	FileEnumPtr			; bx = list of matching files.
						; cx = number of matching files.
	pop	ds
	.leave
	ret
GetFileList	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitiateBatchInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiates BatchHelpFilesInteraction.

CALLED BY:	InitiateBatchExportUI, InitiateBatchImportUI
PASS:		nothing
RETURN:		ax = InteractionCommand
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/13/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitiateBatchInteraction	proc	near
	uses	bx, si
	.enter
	GetResourceHandleNS	HelpEditUI, bx
	mov	si, offset BatchHelpFilesInteraction	; ^lbx:si => BatchHelpFilesInteraction	
	call	UserDoDialog				; ax => InteractionCommand
	.leave
	ret
InitiateBatchInteraction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocMemoryForBatchParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates memory for a BatchExportParams structure and
		saves the handle in the global batchInfo.

CALLED BY:	InitiateBatchExportUI, InitiateBatchImportUI
PASS:		nothing
RETURN:		ax = address of newly allocated structure
		bx = MemHandle of newly allocated structure
		carry set if error (not enough memory)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/13/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocMemoryForBatchParams	proc	near
	uses	cx
	.enter
	;
	; Allocate memory for BatchParams
	;
	mov	ax, size BatchParams
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_FIXED 
	call	MemAlloc			; bx => new memhandle
						; ax => address of memblock
	jc	done				; don't destroy batchInfo if error
	mov	ss:[batchInfo], bx		; save the handle for later use
done:
	.leave
	ret
AllocMemoryForBatchParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBatchPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the path of the directory holding Writer/RTF files to
		batch.

CALLED BY:	
PASS:		cx:dx	-- fptr to buffer to hold directory path
RETURN:		cx:dx	-- fptr to buffer, preserved, with relative directory path
		bx	-- disk handle of directory path
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/13/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBatchPath	proc	near
	uses	ax, bp, si, di
	.enter

	;
	; Get the path of the directory holding files to batch.
	;
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	GetResourceHandleNS	HelpEditUI, bx
	mov	si, offset WriterBatchDirSelector 
	mov	di, mask MF_CALL 
	call	ObjMessage	; ax => disk handle
	mov	bx, ax		; bx => disk handle (return value)
	.leave
	ret
GetBatchPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupCommonUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the common UI elements for the batch process
		features.

CALLED BY:	BatchSetupCommon
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/13/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupCommonUI	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Clear the batch log and current filename (UI stuff)
	;
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	GetResourceHandleNS	PrimaryUI, bx
	mov	si, offset BatchStatusText
	mov	di, mask MF_CALL 
	call	ObjMessage

	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	GetResourceHandleNS	PrimaryUI, bx		
	mov	si, offset BatchStatusCurrentFileName
	mov	di, mask MF_CALL 
	call	ObjMessage

	;
	; Set the "Stop" trigger enabled. (UI stuff)
	;
	mov	ax, MSG_GEN_SET_ENABLED
	GetResourceHandleNS	PrimaryUI, bx
	mov	si, offset BatchStatusStopTrigger
	mov	di, mask MF_CALL 
	mov	dl, VUM_NOW
	call	ObjMessage

	;
	; Put up the batch log window. (UI stuff)
	;		
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	si, offset BatchStatusDialog
	call	ObjMessage
	.leave
	ret
SetupCommonUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does an export for a list of files.
		

CALLED BY:	
PASS:		
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/03/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportFileList		proc	near
	;
	; Set up es with our BatchParams
	;
	mov	bx, ss:[batchInfo]
	call	MemDerefES	

	;
	; Turn on export finish notification, so that we know
	; when to start exporting the next document.
	;
	mov	ax, MSG_SUPER_IMPEX_ENABLE_EXPORT_FINISH_NOTIFICATION
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset WriteExportControl		; bx:si => WriteExportControl optr
	mov	di, mask MF_CALL 
	call	ObjMessage

	;
	; Start handling documents
	;
	clr	es:[BEP_currFile]			; start at doc. 0
	call	HandleNextDocumentExport

	ret

ExportFileList		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the ball rolling on the import of the file list placed
		in the memory location specified by batchInfo.

CALLED BY:	InitiateBatchImportUI
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportFileList	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	;
	; Set up es with our BatchParams
	;
	mov	bx, ss:[batchInfo]
	call	MemDerefES	

	;
	; Turn on import finish notification, so that we know
	; when to start exporting the next document.
	;
	mov	ax, MSG_SUPER_IMPEX_ENABLE_IMPORT_FINISH_NOTIFICATION
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset WriteImportControl		; bx:si => WriteExportControl optr
	mov	di, mask MF_CALL 
	call	ObjMessage

	;
	; Start handling documents
	;
	clr	es:[BEP_currFile]				; start at doc. 0
	call	HandleNextDocumentImport

	.leave
	ret
ImportFileList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNextDocumentExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		

CALLED BY:	
PASS:		
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/03/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleNextDocumentExport	proc	far
	call	HandleNextDocumentCommon
	jnc	cont					; common routine hit last document, so don't branch

	;
	; quit
	;
	.leave
	ret	

cont:
	mov	bx, ss:[batchInfo]
	call	MemDerefES

	;
	; Copy DocumentCommonParams to the stack
	;
	sub	sp, size DocumentCommonParams		; alloc the space on the stack
	mov	bp, sp					; ss:bp => stack frame for MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
	push	ds
	mov	cx, size DocumentCommonParams		; set ctr.
	segmov	ds, es, ax
	mov	si, offset es:BEP_batchParams		; ds:si => source
	push	es
	segmov	es, ss, ax
	mov	di, bp					; es:di => dest
	rep	movsb					; copy!	
	pop	es

	;
	; Open the document
	;
	mov	ax, MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
	GetResourceHandleNS	AppDCUI, bx
	mov	si, offset WriteDocumentGroup		; bx:si => WriteDocumentGroup optr
	mov	dx, size DocumentCommonParams
	pop	ds
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage				; cx:dx => new document object

	;
	; Set the current document optr
	;
	movdw	es:[BEP_currDocumentOptr], cxdx

	;
	; Add "exporting" message to batch log
	;
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	GetResourceHandleNS	PrimaryUI, dx
	push	bp
	mov	bp, offset ExportingText		; dx:bp => optr to text
	mov	bx, dx
	clr	cx
	mov	si, offset BatchStatusText		; bx:si => optr to BatchStatusText
	mov	di, mask MF_CALL 
	call	ObjMessage
	pop	bp

	;
	; Export the document
	;
	mov	cx, WDFT_RTF
	call	ExportDocTransparently
	add	sp, size DocumentCommonParams		; throw away stack fraem

	ret
HandleNextDocumentExport	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNextDocumentImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleNextDocumentImport	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	call	HandleNextDocumentCommon
	jnc	cont					; common routine hit last document, so don't branch

	;
	; quit
	;
	.leave
	ret	

cont:
	mov	bx, ss:[batchInfo]
	call	MemDerefES

	;
	; Copy DocumentCommonParams to the stack
	;
	sub	sp, size DocumentCommonParams		; alloc the space on the stack
	mov	bp, sp					; ss:bp => stack frame for MSG_GEN_DOCUMENT_GROUP_OPEN_DOC
	push	ds
	mov	cx, size DocumentCommonParams		; set ctr.
	segmov	ds, es, ax
	mov	si, offset es:BEP_batchParams		; ds:si => source
	push	es
	segmov	es, ss, ax
	mov	di, bp					; es:di => dest
	rep	movsb					; copy!	
	pop	es
	pop	ds

	;
	; Import the document
	;
	call	ImportDocTransparently
	add	sp, size DocumentCommonParams		; bye bye stack frame!
	
	.leave
	ret
HandleNextDocumentImport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleNextDocumentCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleNextDocumentCommon	proc	near
	mov	bx, ss:[batchInfo]
	call	MemDerefES
	inc	es:BEP_currFile

	;
	; If we're on the last document, then quit
	;
	mov	bx, es:BEP_currFile
	cmp	es:BEP_numMatchingFiles, bx
	jb	endItAll

	;
	; Are we stopping?
	;
	cmp	es:BEP_stopping, BB_FALSE
	jz	cont

	;
	; STOP!
	;
	jmp	endItAll

cont:

	;
	; Copy the current filename as the current document	
	;
	mov	ax, size FileLongName
	dec	bx
	mul	bx						; ax => offset in file list of current filename
	push	ds
	lds	si, es:BEP_fileList
	add	si, ax						; ds:si => source filename
	lea	di, es:BEP_batchParams.DCP_name			; es:di => dest
	call	strcpy
	pop	ds

	;
	; Display the filename in the current filename text field
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, es
	push	bp
	lea	bp, es:BEP_batchParams.DCP_name			; dx:bp => pointer to filename
	clr	cx						; null terminated
	GetResourceHandleNS	PrimaryUI, bx
	mov	si, offset BatchStatusCurrentFileName		; bx:si => BatchStatusCurrentFileName optr
	mov	di, mask MF_CALL
	call	ObjMessage	

	;
	; Add a cute little underline above the filename
	;
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	GetResourceHandleNS	PrimaryUI, dx
	mov	bp, offset FileUnderlineText			; dx:bp => optr to text
	mov	bx, dx			
	mov	si, offset BatchStatusText			; bx:si => optr to BatchStatusText
	clr	cx
	mov	di, mask MF_CALL
	call	ObjMessage

	;
	; Add the filename to the batch log
	;
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	mov	dx, es
	lea	bp, es:BEP_batchParams.DCP_name			; dx:bp => pointer to filename
	clr	cx
	GetResourceHandleNS	PrimaryUI, bx
	mov	si, offset BatchStatusText
	mov	di, mask MF_CALL
	call	ObjMessage
	
	;
	; Add a cute little underline below the filename
	;
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	GetResourceHandleNS	PrimaryUI, dx
	mov	bp, offset FileUnderlineText			; dx:bp => optr to text	
	clr	cx
	mov	bx, dx
	mov	si, offset BatchStatusText
	mov	di, mask MF_CALL
	call	ObjMessage

	;
	; Add "Opening. . ."
	;
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	GetResourceHandleNS	PrimaryUI, dx
	mov	bp, offset OpeningText
	clr	cx
	mov	bx, dx
	mov	si, offset BatchStatusText
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
	clc		; success
	jmp	done

endItAll:
	call	GeodeGetProcessHandle
	clr	si, di
	mov	ax, MSG_WRITE_PROCESS_END_BATCH_JOB
	call	ObjMessage
	stc
done:
	ret
HandleNextDocumentCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NextInBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_PROCESS_NEXT_IN_BATCH

PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/05/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NextInBatch	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_NEXT_IN_BATCH
	uses	ax, bx, cx, dx, bp, ds
	.enter

	;
	; Add export "success" or "failure" message to the
	; batch log.
	;	
	mov	si, offset BatchStatusText		
	GetResourceHandleNS	PrimaryUI, bx		; bx:si => BatchStatusText optr
	mov	di, mask MF_CALL
	clr	cx					; null terminated string
	mov	dx, bx					; dx => resource handle for success & failure messages
	push	bp					; save stack frame!!!!
	push	ds
	call	ThreadGetDGroupDS
	mov	ah, ds:[appExportImportSucceeded]
	pop	ds
	cmp	ah, BB_FALSE	
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR	
	jne	exportImportSuccess

	;
	; "failed"
	;
	mov	bp, offset ExportFailedText		; dx:bp => optr of ExportFailedText
	call	ObjMessage
	jmp	cont

exportImportSuccess:
	;
	; "success"
	;
	mov	bp, offset ExportSuccessText		; dx:bp => optr of ExportSuccessText
	call	ObjMessage
	push	ds
	call	ThreadGetDGroupDS
	mov	ds:[appExportImportSucceeded], BB_FALSE	; reset appExportSucceeded flag
	pop	ds

cont:
	pop	bp

	mov	bx, ss:[batchInfo]
	call	MemDerefES

	cmp	es:[BEP_batchType], BST_IMPORT
	jz	finishImport

EC	<cmp	es:[BEP_batchType], BST_EXPORT	>
EC	<ERROR_NZ INVALID_BATCH_SETUP_TYPE_SPECIFIED	>

	;
	; Get current document optr
	;
	movdw	cxdx, es:[BEP_currDocumentOptr]

	;
	; Close the currently open document
	;
	push	bp
	clr	bp
	mov	ax, MSG_GEN_DOCUMENT_CLOSE
	movdw	bxsi, cxdx			; bx:si => curr document optr
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	;
	; Export the next document
	;
	.leave
	GOTO	HandleNextDocumentExport

finishImport:
	;
	; Hack off the RTF extension on the filename.
	;
	lea	di, es:[BEP_batchParams].DCP_name		; es:di => string
	mov	al, '.'
	cld

extNotFound:
	scasb
	jnz	extNotFound
		; es:di = "xxx" extension
	dec	di
	mov	word ptr es:[di], 0				; null terminate the string
	
	;
	; Allocate new DocumentCommonParams on the stack so that we can
	; specify information for the new document filename.  Then copy
	; the information from our current DocumentCommonParams to the new
	; one.
	;
	segmov	ds, es, ax
	lea	si, es:[BEP_batchParams]	; ds:si => DocumentCommonParams to copy	

	push	bp
	sub	sp, size DocumentCommonParams	; set up stack frame
	mov	di, sp
	segmov	es, ss, ax			; es:di => Destination DocumentCommonParams on stack
	mov	cx, size DocumentCommonParams
	rep	movsb				; copy!
	mov	bp, sp				; bp => stack frame

	;
	; Output "Saving document" messages to batch log
	;
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	; cx is already zero from the rep instruction above
	GetResourceHandleNS	PrimaryUI, dx
	push	bp
	mov	bp, offset ImportSavingText	; ^ldx:bp = optr to text
	mov	di, mask MF_CALL 
	mov	bx, dx
	mov	si, offset BatchStatusText	; ^lbx:si = BatchStatusText optr
	call	ObjMessage

	;
	; Add the filename
	;
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	pop	di
	lea	bp, [di].DCP_name
	push	di
	segmov	dx, ss, cx
	clr	cx
	GetResourceHandleNS	PrimaryUI, bx
	mov	si, offset BatchStatusText
	mov	di, mask MF_CALL 
	call	ObjMessage

	;
	; Add an ellipis
	;
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	GetResourceHandleNS	PrimaryUI, dx
	mov	bp, offset EllipseText		; ^ldx:bp = optr to text
	mov	bx, dx
	mov	si, offset BatchStatusText
	mov	di, mask MF_CALL 
	call	ObjMessage
	pop	bp

	;
	; Save the imported document as a Writer file with the
	; new filename, then close it.
	;
	mov	ax, MSG_GEN_DOCUMENT_CLOSE
	push	bp
	clr	bp
	mov	di, mask MF_RECORD 
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	call	ObjMessage	; di <= handle of ClassedEvent
	pop	bp
	push	di		; save it

	mov	ax, MSG_GEN_DOCUMENT_SAVE_AS
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	dx, size DocumentCommonParams
	mov	di, mask MF_RECORD or mask MF_STACK 
	call	ObjMessage	; di <= handle of ClassedEvent

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	GetResourceHandleNS	AppDCUI, bx
	mov	si, offset WriteDocumentGroup	
	mov	cx, di
	mov	dx, TO_MODEL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	pop	cx		; MSG_GEN_DOCUMENT_CLOSE ClassedEvent
	mov	dx, TO_MODEL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	add	sp, size DocumentCommonParams	; seeya' stack frame.
	pop	bp
	
	;
	; Import the next document
	;
	.leave
	GOTO	HandleNextDocumentImport
NextInBatch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AbortBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_PROCESS_ABORT_BATCH

PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AbortBatch	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_ABORT_BATCH
	uses	ax, bx, cx, dx, bp
	.enter

	;
	; Make sure we're running a batch
	;
	mov	bx, ss:[batchInfo]
	tst	bx
	jz	done

	;
	; Weeeeeeeeeeeeeeeeeeeeeeeeee'rrrrrrrrrrrrrrreeeeeeeee stopping!
	;
	call	MemDerefES
	mov	es:[BEP_stopping], BB_TRUE

	;
	; Disable the "Stop" trigger.
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	GetResourceHandleNS	PrimaryUI, bx
	mov	si, offset BatchStatusStopTrigger
	mov	di, mask MF_CALL 
	mov	dl, VUM_NOW
	call	ObjMessage

done:
	.leave
	ret
AbortBatch	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndBatchJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_PROCESS_END_BATCH_JOB

PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/05/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndBatchJob	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_END_BATCH_JOB
	uses	ax, cx, dx, bp
	.enter

	;
	; Clean up. . .
	;
	call	CleanUpAfterBatch	
	.leave
	ret
EndBatchJob	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CleanUpAfterBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_WRITE_PROCESS_CLEAN_UP_AFTER_BATCH

PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/11/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CleanUpAfterBatch	method WriteProcessClass, 
				MSG_WRITE_PROCESS_CLEAN_UP_AFTER_BATCH
	uses	ax, cx, dx, bp
	.enter

	;
	; Make sure some BatchInfo exists
	;
	mov	ax, ss:[batchInfo]
	tst	ax
	jz	done

	mov	bx, ss:[batchInfo]
	call	MemDerefES

	cmp	es:[BEP_batchType], BST_EXPORT
	jz	cleanUpExport

EC	<cmp	es:[BEP_batchType], BST_IMPORT	>
EC	<ERROR_NZ INVALID_BATCH_SETUP_TYPE_SPECIFIED	>
	
	;
	; Turn off import finish notification
	;
	mov	ax, MSG_SUPER_IMPEX_DISABLE_IMPORT_FINISH_NOTIFICATION
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset WriteImportControl		; bx:si => WriteImportControl optr
	mov	di, mask MF_CALL 
	call	ObjMessage

	jmp	cont

cleanUpExport:
	;
	; Turn off export finish notification, since
	; we're done with our batch.
	;
	mov	ax, MSG_SUPER_IMPEX_DISABLE_EXPORT_FINISH_NOTIFICATION
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset WriteExportControl		; bx:si => WriteExportControl optr
	mov	di, mask MF_CALL 
	call	ObjMessage

cont:
	;
	; Free the matching file list
	;
	mov	bx, es:BEP_fileListHandle
	call	MemFree	

	;
	; Free BatchExportParams
	;
	mov	bx, ss:[batchInfo]
	call	MemFree
	clr	ss:[batchInfo]

done:

	;
	; Output the "Done" string to the batch log
	;
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	GetResourceHandleNS	PrimaryUI, dx
	mov	bp, offset ExportDoneText
	clr	cx
	mov	bx, dx
	mov	si, offset BatchStatusText
	call	ObjMessage

	;
	; Change the caption of the "Stop" trigger to "OK"
	;
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	cx, offset BatchProcessingDoneTriggerText
	mov	dl, VUM_NOW
	GetResourceHandleNS	PrimaryUI, bx
	mov	si, offset BatchStatusStopTrigger
	mov	di, mask MF_CALL 
	call	ObjMessage

	;
	; Change the action message so that it closes the batch
	; log window.
	;
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_WRITE_PROCESS_REMOVE_BATCH_LOG
	call	ObjMessage

	;
	; Set the trigger enabled
	;
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessage

	.leave
	ret
CleanUpAfterBatch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveBatchLog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the batch log window from the screen and resets
		the functionality of the "Stop" trigger.

CALLED BY:	MSG_WRITE_PROCESS_REMOVE_BATCH_LOG

PASS:		*ds:si	= WriteProcessClass object
		ds:di	= WriteProcessClass instance data
		ds:bx	= WriteProcessClass object (same as *ds:si)
		es 	= segment of WriteProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	Batch log window set not usable.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/17/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveBatchLog	method dynamic WriteProcessClass, 
					MSG_WRITE_PROCESS_REMOVE_BATCH_LOG
	;
	; Dismiss the interaction.
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	GetResourceHandleNS	PrimaryUI, bx
	mov	si, offset BatchStatusDialog
	mov	di, mask MF_CALL
	call	ObjMessage
	
	;
	; Reset the message and moniker for the Stop trigger.
	;
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_WRITE_PROCESS_ABORT_BATCH
	mov	si, offset BatchStatusStopTrigger
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	cx, offset BatchProcessingStopTriggerText
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage

	ret
RemoveBatchLog	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		strcpy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copies a string (null-terminated)

CALLED BY:	GLOBAL
PASS:		ds:si - src
		es:di - dest
RETURN:		ax - # of chars copied including null
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	es:di must have space to fit ds:si string
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	3/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
strcpy	proc	far
	uses	cx,si,di
	.enter
; 	GET LENGTH OF SRC STRING

	segxchg	ds,es
	push	di
	mov	di,si			;es:di - src
	mov	cx, -1
	clr	ax
	repne	scasb
	not	cx			;CX <- # chars + null in src str
	mov	ax,cx
	segxchg	ds,es
	pop	di			;ds:si - src buf  es:di - dest buf
	shr	cx, 1
	jnc	5$
	movsb
5$:
	rep	movsw			;strcpy
	.leave
	ret
strcpy	endp

endif

DocMiscFeatures ends



