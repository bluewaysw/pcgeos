COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cfolderPrinter.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/25/92   	Initial version.

DESCRIPTION:
	

	$Id: cfolderPrinter.asm,v 1.2 98/06/03 13:10:17 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderObscure	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrinterCheckTransferEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if we can print this puppy, and if so, print it.
		Remove it from the FQTB, because it ain't a move, and
		it ain't a copy.

PASS:		*ds:si	= NDPrinterClass object
		ds:di	= NDPrinterClass instance data
		es	= dgroup

		dx:bp   - FileOperationInfoEntry to check

RETURN:		carry set

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDPrinterCheckTransferEntry	method	dynamic	NDPrinterClass, 
					MSG_SHELL_OBJECT_CHECK_TRANSFER_ENTRY
	uses	ax,cx,dx,bp
	.enter

	
	;
	; First, ask the superclass what it has to say
	;
	mov	di, offset NDPrinterClass
	call	ObjCallSuperNoLock
	jc	done

	mov	ds, dx			; ds:bp - FileOperationInfoEntry
	mov	si, bp
	call	PrepFilenameForError

	;
	; set up AppLaunchBlock for UserLoadApplication
	;
	mov	ax, size AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE or \
					ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jnc	memOK				; if no error, continue
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	error				; else, report it

memOK:
	mov	dx, bx				; dx = AppLaunchBlock
	mov	es, ax				; es <- ALB

	mov	ax, ds:[FQTH_diskHandle]
	mov	es:[ALB_diskHandle], ax		; set up starting directory
	mov	si, offset FQTH_pathname
	mov	di, offset ALB_path
	call	CopyNullTermString

	mov	si, bp
		CheckHack <offset FOIE_name eq 0>
	mov	di, offset ALB_dataFile
	call	CopyNullTermString

	mov	ax, {word} ds:[bp].FOIE_creator.GT_chars[0]
	mov	bx, {word} ds:[bp].FOIE_creator.GT_chars[2]
	mov	si, ds:[bp].FR_creator.GT_manufID
	mov	es:[ALB_appRef].AIR_diskHandle, 0	; Tell IACP to look

	ornf	es:[ALB_launchFlags], mask ALF_OVERRIDE_MULTIPLE_INSTANCE or \
				      mask ALF_OPEN_FOR_IACP_ONLY


	xchg	bx, dx				; unlock AppLaunchBlock
	call	MemUnlock			;	before running
	xchg	bx, dx


	call	GetErrFilenameBuffer		; cx = error filename buffer
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; assume error
	jcxz	error

	;
	; Load the app and print it.  Do it via the queue, so that we
	; have fewer blocks locked when printing starts
	;

	mov	ax, MSG_DESKTOP_PRINT_FILE
	mov	bx, handle 0
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done

error:
	call	DesktopOKError
done:

	stc
	.leave
	ret
NDPrinterCheckTransferEntry	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrinterDoOptionsDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Determine the # of available printers, set the
		dynamic list, and set the original setting

PASS:		*ds:si	= NDPrinterClass object
		ds:di	= NDPrinterClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	DON'T call superclass, 'cause we don't want to do a file enum

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDPrinterDoOptionsDialog	method	dynamic	NDPrinterClass, 
				MSG_ND_PRINTER_DO_OPTIONS_DIALOG

	.enter

if _NEWDESKBA
	call	LoadBannerText
	call	LoadBannerStatus
endif

	;
	; Initiate the dialog
	;

	LoadBXSI	NDPrinterOptionsDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageNone


	;
	; Set the number of printers
	;

	mov	cx, PDT_PRINTER
	call	SpoolGetNumPrinters
	mov_tr	cx, ax
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	LoadBXSI	NDPrinterList
	call	ObjMessageNone

	;
	; Get the default printer from the spool library and make it
	; our current printer
	;

	call	SpoolGetDefaultPrinter
	mov_tr	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx			; no indeterminates
	LoadBXSI	NDPrinterList
	call	ObjMessageNone

	.leave
	ret
NDPrinterDoOptionsDialog	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrinterRequestItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the moniker for the requested printer #

PASS:		*ds:si	= NDPrinterClass object
		ds:di	= NDPrinterClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDPrinterRequestItemMoniker	method	dynamic	NDPrinterClass, 
					MSG_ND_PRINTER_REQUEST_ITEM_MONIKER

printerNum	local	word	push	bp
buffer	local	GEODE_MAX_DEVICE_NAME_SIZE dup (char)

	.enter
	mov	bx, cx
	mov	si, dx			; caller's OD

	segmov	es, ss
	lea	di, ss:[buffer]
	mov	ax, ss:[printerNum]
	call	SpoolGetPrinterString
	jc	done
	
	push	bp
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	cx, ss
	mov	dx, di
	mov	bp, ss:[printerNum]
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
done:
	.leave
	ret
NDPrinterRequestItemMoniker	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrinterSetPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save the printer type

PASS:		*ds:si	= NDPrinterClass object
		ds:di	= NDPrinterClass instance data
		es	= dgroup
		cx	= printer number

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDPrinterSetPrinter	method	dynamic	NDPrinterClass, 
					MSG_ND_PRINTER_SET_PRINTER

	.enter

	;
	; Set the system default
	;

	mov_tr	ax, cx
	call	SpoolSetDefaultPrinter

	.leave
	ret
NDPrinterSetPrinter	endm


if _NEWDESKBA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrinterRunPConsole
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Run PCONSOLE

PASS:		*ds:si	= NDPrinterClass object
		ds:di	= NDPrinterClass instance data
		es	= dgroup

RETURN:		Doesn't return.  Will cause a shutdown.

DESTROYED:	ax,cx,dx,bp  (but who cares? :)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/13/92   	Initial version.
	chungl	8/26/93		changed to use CTEMP.BAT instead of DosExec.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
pconsole char "Z:\\PUBLIC\\PCONSOLE.EXE"
nullStr	char	0			; MUST follow pconsole

zDirStr	char	"Z:\\PUBLIC\\", 0
else
pconsole 	char	"Z:", C_CR, C_LF, "PCONSOLE", C_CR, C_LF, "H:", C_CR, C_LF
endif

NDPrinterRunPConsole	method	dynamic	NDPrinterClass, 
					MSG_ND_PRINTER_RUN_PCONSOLE
	.enter

; we can run PCONSOLE either via a DosExec or by creating a
; CTEMP.BAT and shutting down.  The DosExec way is easier, but
; unfortunately IBM in Boca has been reporting a bug that we 
; cannot reproduce here, where when returning from a DosExec,
; the message "Could not find the loader file..." would come up, 
; instead of returning to GEOS.  Thus I'm rewriting this to use
; the CTEMP.BAT method.  See bug #21408 -Chung
if 0
	;run PCONSOLE via DosExec

	clr	bx
	segmov	ds, cs, dx
	mov	si, offset pconsole	;ds:si = command to run

	segmov	es, dx			;es:di = arguments to run
	mov	di, offset nullStr

	clr	ax			;ax = drive handle for current dir
	mov	bp, offset zDirStr	;dx:bp = current dir to use

	mov	cx, mask DEF_FORCED_SHUTDOWN
	call	DosExec
else
	;run PCONSOLE by using CTEMP.BAT
	mov	cx, length pconsole
	segmov	ds, cs
	mov	dx, offset cs:[pconsole]
	call	IclasExecString
endif
	.leave
	ret
NDPrinterRunPConsole	endm

endif		; if _NEWDESKBA



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			NDBringUpPrinterControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Brings up the printer control panel.

CALLED BY:	INTERNAL - FileOpenESDI

PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDBringUpPrinterControl	proc	far
		.enter

BA <		call	BABringUpPrinterControl				>
		mov	ax, MSG_SPOOL_SHOW_PRINTER_CONTROL_PANEL
		mov	bx, handle spool
		call	ObjMessageForce

		.leave
		ret
NDBringUpPrinterControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrinterBannerStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	status message for the status on-off group

PASS:		*ds:si	- NDPrinterClass object
		ds:di	- NDPrinterClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _NEWDESKBA
NDPrinterBannerStatus	method	dynamic	NDPrinterClass, 
					MSG_ND_PRINTER_BANNER_STATUS
		.enter

; I really shouldn't do things like this...
CheckHack <MSG_GEN_SET_NOT_ENABLED eq (MSG_GEN_SET_ENABLED+1)>

		cmp	cx, TRUE
		mov	ax, MSG_GEN_SET_ENABLED
		je	sendIt
		inc	ax
sendIt:
		mov	dl, VUM_NOW
		LoadBXSI	NDPrinterBannerText
		call	ObjMessageNone		


		.leave
		ret
NDPrinterBannerStatus	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrinterSetBannerOnOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Turn banner printing ON/OFF.

PASS:		*ds:si	- NDPrinterClass object
		ds:di	- NDPrinterClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/17/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDPrinterSetBannerOnOff	method	dynamic	NDPrinterClass, 
					MSG_ND_PRINTER_SET_BANNER_ON_OFF
		mov_tr	ax, cx		
		call	NetPrintSetBannerStatus
		ret
NDPrinterSetBannerOnOff	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadBannerText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the banner text into the text object

CALLED BY:	

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadBannerText	proc near

		.enter

		sub	sp, size NetBannerText
		mov	si, sp
		segmov	ds, ss
		call	NetPrintGetBanner

		mov	bp, sp
		mov	dx, ss
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		LoadBXSI	NDPrinterBannerText
		call	ObjMessageCall

		add	sp, size NetBannerText

		.leave
		ret
LoadBannerText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDPrinterSetBannerText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- NDPrinterClass object
		ds:di	- NDPrinterClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 4/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NDPrinterSetBannerText	method	dynamic	NDPrinterClass, 
					MSG_ND_PRINTER_SET_BANNER_TEXT
		.enter

		sub	sp, size NetBannerText
		mov	bp, sp
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		LoadBXSI	NDPrinterBannerText
		call	ObjMessageCall


		segmov	ds, ss
		mov	si, sp
		call	NetPrintSetBanner

		add	sp, size NetBannerText

		.leave
		ret
NDPrinterSetBannerText	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadBannerStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the banner on/off item group

CALLED BY:	NDPrinterDoOptionsDialog

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadBannerStatus	proc near

		.enter

		call	NetPrintGetBannerStatus
		clr	dx
		mov_tr	cx, ax		; true/false
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		LoadBXSI	NDPrinterBannerOnOff
		call	ObjMessageNone

		clr	cx
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		call	ObjMessageNone

		.leave
		ret
LoadBannerStatus	endp
endif

FolderObscure	ends


