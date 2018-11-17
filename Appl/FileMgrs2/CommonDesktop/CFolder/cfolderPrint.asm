COMMENT @----------------------------------------------------------------------
	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		folderPrint.asm
AUTHOR:		Doug Fults

ROUTINES:

------------ FolderPrint segment ----------
	METHOD	FolderStartPrint 	- MSG_FM_START_PRINT


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/92		Initial version

DESCRIPTION:
	This file contains desktop print code

	$Id: cfolderPrint.asm,v 1.2 98/06/03 13:36:13 joon Exp $

------------------------------------------------------------------------------@

FolderObscure	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print selected files

CALLED BY:	MSG_FM_START_PRINT

PASS:		*ds:si - instance handle of Folder object
		ds:bx	- ptr to object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString spoolerName <"SPOOLEC.GEO",0>			>
NEC <LocalDefNLString spoolerName <"SPOOL.GEO",0>			>

FolderStartPrint	method	FolderClass, MSG_FM_START_PRINT
	.enter
if _FAX_CAPABILITY
	mov	ss:[outputType], cl
endif		
	mov	ss:[doingMultiFileLaunch], TRUE	; init flag

GM<	cmp	ds:[bx].FOI_selectList, NIL	; no selected files?	>
GM<	je	done				; yes, do nothing	>
ND<	call	NDCheckForNoSelection					>
ND<	jc	done							>
	;
	mov	di, ds:[bx].FOI_selectList	; di = selection list head
ND<	call	NDGetSelectionIntoDI 					>
ND<	jc	done				; if whitespace click	>

	;
	; check if any printers installed
	;
	push	ds, si
	call	FilePushDir
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	segmov	ds, cs
	mov	si, offset spoolerName
	clr	ax, bx
	call	GeodeUseLibrary			; bx = spooler handle
	call	FilePopDir
	pop	ds, si
	jc	done				; couldn't load spooler?!?!
	push	bx
	mov	ax, enum SpoolGetNumPrinters
	call	ProcGetLibraryEntry		; bx:ax = virtual fptr
	mov	cx, PDT_ALL and 0xff		; all local/remote printers
	call	ProcCallFixedOrMovable		; ax = num printers
	pop	bx				; bx = library handle
	call	GeodeFreeLibrary
	tst	ax				; any printers?
	jnz	havePrinters			; have printers
	mov	ax, ERROR_NO_PRINTER
	call	DesktopOKError
	jmp	done

havePrinters:
	call	FolderLockBuffer
	jz	done

next:
	; *ds:si - FolderClass object
	; es:di = folder buffer entry of file to open

	push	ds, si, es, di

	call	FilePrintESDI			; print es:di

	pop	ds, si, es, di

	call	checkIfDetaching
	jc	noMore

	mov	di, es:[di].FR_selectNext	; es:di = next selection
	cmp	di, NIL
	jne	next

noMore:
	call	FolderUnlockBuffer

	mov	ax, MSG_GEN_BRING_TO_TOP	; bring ourselves back to top.
	call	GenCallApplication

done:
	mov	ss:[doingMultiFileLaunch], FALSE	; clear flag
	.leave
	ret

checkIfDetaching	label	near
	push	si, di
	mov	ax, MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
	mov	cx, segment GenFieldClass
	mov	dx, offset GenFieldClass
	call	UserCallApplication
	cmc					; carry set if no answer
	jc	haveAnswer			; no field, detaching
	movdw	bxsi, cxdx
	mov	ax, MSG_META_GET_VAR_DATA
	mov	dx, size GetVarDataParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GVDP_bufferSize, 0
	mov	ss:[bp].GVDP_dataType, DETACH_DATA
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GetVarDataParams
	cmp	ax, -1
	je	haveAnswer			; not found (carry clear)
	stc					; indicate detaching
haveAnswer:
	pop	si, di
	retn

FolderStartPrint	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilePrintESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to print file; supports PCGEOS applications only
		at present.

CALLED BY:	INTERNAL
			FolderStartPrint

PASS:		ds:si - folder object instance data
		es:di - FolderRecord of file to open

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,bp,ds

PSEUDO CODE/STRATEGY:
	Save the OD of the opened folder or application in the FolderRecord

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilePrintESDI	proc	far
	class	FolderClass

if _NEWDESK
	cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_LOGOUT
	je	done
	cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_PRINTER
	je	done
endif		; if _NEWDESK

	test	es:[di].FR_fileAttrs, mask FA_SUBDIR
	jnz	done
	cmp	es:[di].FR_fileType, GFT_NOT_GEOS_FILE
	je	nonGeosFile			; try special handling
	cmp	es:[di].FR_fileType, GFT_EXECUTABLE
	je	done				; not supported

tryPrint:
	test	es:[di].FR_fileAttrs, mask FA_LINK
	jz	notLink
	;XXX set up openFileDiskHandle?
	call	ValidateExecutableLink
	jc	done				; error reported

notLink:
	call	PrintGeosFile			; GEOS or datafile

done:
	ret			; <-- EXIT HERE

nonGeosFile:
	test	es:[di].FR_state, mask FRSF_DOS_FILE_WITH_CREATOR
	jnz	tryPrint
	jmp	short done

FilePrintESDI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGeosFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	attempt to launch GEOS application or datafile

CALLED BY:	FilePrintESDI

PASS:		es:di - FileOperationInfoEntry (or FolderRecord) of
		file to print.

RETURN:		nothing 

DESTROYED:	bx,cx,dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGeosFile	proc	near
	class	FolderClass
	uses	es, di, ds, si, ax
	.enter

	call	PrepESDIForError		; setup filenames for error
	;
	; set up AppLaunchBlock for UserLoadApplication
	;
	call	LaunchCreateAppLaunchBlock
	tst	ax
	jnz	error
	mov	ax, cx				; move token to ax:bx:si

	; Any alterations to AppLaunchBlock are done here.
	;
	xchg	bx, dx
	push	ax, ds
	call	MemLock
	mov	ds, ax

	; Don't bother user with silly dialog box, set flag for print
	; launching only.
	;
	ornf	ds:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE or \
				      mask ALF_OPEN_FOR_IACP_ONLY

	call	MemUnlock
	pop	ax, ds
	xchg	bx, dx

	; dx = AppLaunchBlock
	; ax:bx:si = token of application (creator or double-clicked file)
	;
	; send method to our process to launch application
	;
	call	GetErrFilenameBuffer		; cx = error filename buffer
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; assume error
	jcxz	error				; (cx = 0 for MemAlloc err)
	call	LoadApplicationAndPrint
	jmp	done
error:
	call	DesktopOKError
done:
	.leave
	ret
PrintGeosFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadApplicationAndPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load application for printing only.

CALLED BY:	PrintGeosFile

PASS:		dx - AppLaunchBlock
		cx - filename block (in case error reporting is needed)

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadApplicationAndPrint	proc	far
	call	ShowHourglass
	push	cx			; save filename block for ERROR handler
					; at end

	push	cx
	call	GetLoadAppGenParent	; stuff ALB_genParent
	pop	cx

	;
	; Lock down LoadAppData anf save the token away, unlocking the block
	; so it doesn't get in the way of loading the app, if it needs loading.
	; 

	; Connect/Launch/Open the app + document combo
	;
	call	PrintConnect		; call IACPConnect w/correct info
	jc	error
	
	; NOW, get the PrintControl to do dirty deeds for us...

	call	PrintInitiatePrint	; Request print via IACPConnection in bp

	; Close document just printed, if we opened it
	;
	push	si, di
	mov	ax, MSG_GEN_DOCUMENT_CLOSE_IF_OPEN_FOR_IACP_ONLY
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	bx, di
	pop	si, di
	clr	cx			; no completion msg nececssary
	mov	dx, TO_APP_MODEL
	mov	ax, IACPS_CLIENT
	call	IACPSendMessage		; Send to IACPConnection in bp

	clr	cx, dx				; shutting down the client.
	call	IACPShutdown

	mov_tr	cx, bx				; CX - new app's proc handle

	pop	bx				; retrieve filename block
	call	MemFree				; free error filename block

	call	HideHourglass
	ret

error:
	;
	; report error loading application
	;
	pop	dx				; dx = error filename block
	call	ReportLoadError
	call	HideHourglass
	ret				; <-- EXIT HERE ALSO

LoadApplicationAndPrint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common IACPConnect-calling routine for desktop

CALLED BY:	PrintGeosFile

PASS:		dx - AppLaunchBlock (or 0 for none)
		cx - filename block (containing token)

RETURN:         carry set on error:
                        ax      = IACPConnectError/GeodeLoadError
			bx, cx, bp - destroyed
                carry clear if successful connection made:
                        bp      = IACPConnection
                        cx      = number of servers connected to
                        bx      = owner of first server object connected to
                        ax      = destroyed
                AppLaunchBlock freed, if passed non-zero

DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintConnect	proc	near	uses	es, di
	.enter
	mov	bx, cx
	call	MemLock
	mov	es, ax
	push	es:[LAD_token].GT_manufID,
		{word}es:[LAD_token].GT_chars[2],
		{word}es:[LAD_token].GT_chars[0]
	call	MemUnlock

	;
	; Connect to the server, telling IACP to create it if it's not there.
	; 
	segmov	es, ss
	mov	di, sp
	mov	bx, dx
	mov	ax, mask IACPCF_FIRST_ONLY or \
			(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	call	IACPConnect
	lea	sp, es:[di+size GeodeToken]
	.leave
	ret
PrintConnect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			PrintInitiatePrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform actual print job -- don't return until "done"

CALLED BY:	PrintGeosFile
PASS:		bp	- IACPConnection
RETURN:
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInitiatePrint	proc	near	uses	si, di
	.enter

	; 1) allocate a queue

	call	GeodeAllocQueue

	; OK, first, before trying to print, make sure the document has 
	; finished opening.  Send the document a bogus message, w/a completion
	; message so we know when its done being opened/aborted somehow(?)
	; We can't "call" the server, only send it a message, and it can
	; send us one back. However, we can't go on until we're sure the
	; document is ready.  Through the magic of the IACP completion message,
	; we can do all this.
	;
	; 2) record a junk message to be send to this queue; this is the
	;    completion message we give to IACP
	; 3) Build the dummy message
	; 4) call IACPSendMessage to send the request. When it's done, the
	;    server (or IACP if the server has decided to vanish) will send
	;    the message recorded in #2 to our unattached event queue.
	; 5) call QueueGetMessage to pluck the first message from the head
	;    of the queue. This will block until the server has done its thing.
	; 6) nuke the junk message.
	;
					; bx = queue (dest for completion msg)

	push	bx			; save queue handle
	mov	ax, MSG_META_NOTIFY 
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_DOCUMENT_OPEN_COMPLETE
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; cx <- completion msg

	push	cx, bp
	mov	ax, MSG_META_DUMMY
	mov	bx, segment GenDocumentClass	; ClassedEvent
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	cx, bp
	mov	bx, di			; bx <- msg to send
	mov	dx, TO_APP_MODEL	; send to model document
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
	pop	bx			; get queue handle
	call	QueueGetMessage		; wait for junk completion msg to arrive
	push	bx
	mov_tr	bx, ax			; bx <- junk completion msg
	call	ObjFreeMessage		; nuke it
	pop	bx

	;
	; Send the target app's PrintControl a message to print. There's a
	; bit of fun, here, as we need to block until the server has
	; processed the request. We can't "call" the server, only send it
	; a message, and it can send us one back. However, we're not supposed
	; to return from this routine until the print has either finished or
	; been aborted.  Through the magic of the IACP completion message,
	; we can do all this.
	;
	; 2) record a junk message to be send to this queue; this is the
	;    completion message we give to IACP
	; 3) Build the Print message
	; 4) call IACPSendMessage to send the request. When it's done, the
	;    server (or IACP if the server has decided to vanish) will send
	;    the message recorded in #2 to our unattached event queue.
	; 5) call QueueGetMessage to pluck the first message from the head
	;    of the queue. This will block until the server has done its thing.
	; 6) nuke the the junk message.
	;
					; bx = queue (dest for completion msg)

	push	bx			; save queue handle
	mov	ax, MSG_META_NOTIFY 
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_SPOOL_PRINTING_COMPLETE
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; cx <- completion msg

	push	cx, bp
	mov	ax, MSG_PRINT_CONTROL_INITIATE_OUTPUT_UI
if _FAX_CAPABILITY
	mov	cl, ss:[outputType]
else
	mov	cl, PDT_PRINTER
endif
	mov	bx, segment PrintControlClass	; ClassedEvent
	mov	si, offset PrintControlClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	cx, bp
	mov	bx, di			; bx <- msg to send
	mov	dx, TO_PRINT_CONTROL	; send to PrintControl, if there
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
	pop	bx			; get queue handle
	call	QueueGetMessage		; wait for junk completion msg to arrive
	push	bx
	mov_tr	bx, ax			; bx <- junk completion msg
	call	ObjFreeMessage		; nuke it
	pop	bx

	; 7) nuke the queue
					; bx = queue
	call	GeodeFreeQueue		; nuke the queue (no further need)
	.leave
	ret
PrintInitiatePrint	endp

FolderObscure	ends

