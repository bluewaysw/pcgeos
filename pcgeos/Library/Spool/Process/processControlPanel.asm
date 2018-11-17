COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		processControlPanel.asm
AUTHOR:		Steve Scholl, 8 October 1990

ROUTINES			DESCRIPTION


    INT SpoolBuildPrinterListFromInitFile Build list of printers that are
				stored in the geos.ini file. The list is
				store in a chunk array associated with the
				PrinterControlPanelBlock

    INT SpoolAddPrinterFromInitFile Adds printer to printer list from init
				file category

    INT SpoolGetPortNumberType	Determine port type from port string

    INT SpoolCalcMonikerSizes	Calculate the various sizes needed for the
				control panel monikers that will be
				displayed later

    GLB SpoolCheckInterfaceLevel Modify the UI based upon the interface
				level

    INT SpoolPanelJobRemoved	Called when job is removed from a queue.
				Update the job list if this job is in the
				current queue.

    INT SpoolPanelJobAdded	Called when job added to a queue. Update
				the job list if this job is in the current
				queue.

    INT SpoolCalcSelectedJobInfoFromID Determine selectedJobInfo given the
				job id of the selected job

    INT SpoolInitPrinterControlPanel Initialize data structures for printer
				control panel

    INT SpoolSetPrinterTextAsCurrent Sets the printer text display field to
				the printer name and port the current
				printer

    INT SpoolSetPrinterText	Set text in printer text display field in
				control panel

    INT SpoolSetStateOfNextPrinterTrigger Set the Next Printer Trigger to
				enabled if there are at least two printers

    INT SpoolPanelSetStateOfJobTriggers Set the Next Printer Trigger to
				enabled if there are at least two printers

    INT SpoolPanelTriggerEnableDisable Set the Next Printer Trigger to
				enabled if there are at least two printers

    INT SpoolAdvanceCurrentPrinter Advance current printer to next printer
				in printer list

    INT SpoolGetNumberOfPrinters Return number of printers in printer list

    INT SpoolInitPrinterIndex	Initialize the printer index (current printer)

    INT SpoolSetPrinterIndex	Set the printer index

    INT SpoolGetPrinterIndex	Get the printer index

    INT SpoolAddPrinterToList	Add a printer to the printer list

    INT SpoolGetCurrentPrinterPortInfo Return port information for current
				printer

    INT SpoolGetPortInfoByIndex Return PrintPortInfo for printer in list

    INT SpoolInitPrinterList	Initialize the printer list stored in the
				PCPB

    INT SpoolDestroyPrinterList Destroy chunk array of printers if it
				exists

    INT SpoolGetPtrToPrinterElement Return ptr to an element in printer
				list

    INT SpoolGetNumberOfJobs	Return number of jobs in jobs list

    INT SpoolSelectJobInList	Select an job in the list. And update the
				state of the job triggers. When setting the
				list entry the resulting apply will set the
				triggers unless nothing is set then it is
				one by hand.

    INT SpoolSetSelectedJobInfo Set selected job info in control panel

    INT SpoolDestroyJobQueueList Destroy all entries in the JobList

    INT SpoolPanelStartTimer	Start or stop the Control Panel timer

    INT SpoolPanelStopTimer	Start or stop the Control Panel timer

    INT SpoolBuildJobQueueListForCurrentPrinter Build up list of
				information about jobs printing or queued
				on the current printer

    GLB SpoolCreateTitleString	Create the title string (above the list of
				jobs)

    INT SpoolSetNoDocumentsInJobList Create an entry of the jobs list that
				says no documents. Put in the list and set
				the triggers correctly.

    INT SpoolAppendJobEntryFromID Added a job to the job list given it's
				job id

    INT SpoolCreateJobEntry	Create an job entry in the job list

    INT SpoolCopyVisMoniker	Copy a passed moniker into a generic object

    INT SpoolRemoveJobEntry	Remove job list entry from current job list

    INT SpoolCreateJobStringFromID Create string describing job from the
				job id

    INT SpoolCreateNonJobString Create string describing job from the job
				id

    INT SpoolPushMonikerOffsets Push the moniker offsets onto the stack

    INT SpoolTitleCallBack	Callback routine to create a spool title
				moniker

    INT SpoolEmptyCallBack	Callback routine to create a spool title
				moniker

    INT SpoolCopyStringToMoniker Copy a string into the moniker structure,
				after determining the length of the string.

    INT SpoolCopyNumberToMoniker Copy a string into the moniker structure,
				after determining the length of the string.

    INT SpoolCopyMinutesToMoniker Create a string with the number of
				minutes the job has been in the queue

    INT SpoolCopyPrintingToMoniker Copy the printing string to a moniker

    INT SpoolCopyStringsString	Copy in a string from the Strings resource

    INT SpoolBuildJobQueueListByIndex Build up list of information about
				jobs printing or queued

    INT SpoolGetQueueInfoForPrinter Look up specific queue information for
				the printer in question

    INT SpoolControlPanelAccessBlock Lock the PrinterControlPanelBlock, and
				set the segment


DESCRIPTION:
	This file contains all the code necessary to display and
	maintain the Printer Control Panel, which is accessible from
	the Express Menu.

	$Id: processControlPanel.asm,v 1.1 97/04/07 11:11:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANEL
SpoolerApp	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolBuildPrinterListFromInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build list of printers that are stored in the geos.ini
		file. The list is store in a chunk array associated with
		the PrinterControlPanelBlock

CALLED BY:	SpoolShowPrinterControlPanel

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolBuildPrinterListFromInitFile		proc	near
		uses	ax, bx, cx, dx, bp, di, si, ds, es
		.enter

		; Destroy the last list, and re-create one
		;
		call	SpoolDestroyPrinterList
		call	SpoolInitPrinterList

		; Get number of printers and printer names string
		;
		mov	cl, PDT_PRINTER			;get all driver names
		clr	ch
		call	SpoolGetNumPrinters
		tst	ax
		jz	exit
		mov_tr	cx, ax				;number of printers=>CX
		sub	sp, GEODE_MAX_DEVICE_NAME_SIZE
		mov	di, sp
		mov	si, sp
		segmov	es, ss, ax			;buffer => ES:DI
		mov	ds, ax				;buffer => DS:SI

		; Now load all the printers, one by one
		;
		clr	ax				;first printer
nextPrinter:
		push	cx, ax				;number of, printer num
		call	SpoolGetPrinterString		;fill buffer in ES:DI
		jc	noMorePrintersPop
		cmp	dl, PDT_PRINTER			;if not a printer
		jne	skipPrinter			;...then skip the sucker
		call	SpoolAddPrinterFromInitFile
		pop	cx, ax				;number of, printer num
		inc	ax				;go to the next printer
		loop	nextPrinter			;go through all printers

		; If any printers were added, then also add a printer
		; for "Print-to-File". We also check to see if the
		; "Print to File" option has been disabled, in which
		; case we don't list that queue as being available.
addPrintToFile:
		mov	ax, dgroup
		mov	ds, ax
		test	ds:[uiOptions], mask SUIO_PRINT_TO_FILE
		jz	done
		call	SpoolGetNumberOfPrinters
		jcxz	done
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		assume	ds:Strings
		mov	si, ds:[toFilePrinterName]
		mov	ax, PPT_FILE
		call	SpoolAddPrinterToList
		assume	ds:dgroup
		call	MemUnlock
done:
		add	sp, GEODE_MAX_DEVICE_NAME_SIZE	;remove stack buffer
	;
	; Initialize our printer list (a GenDynamicList), even if we
	; have no printers (we may have had some before). Also select
	; one of the printers.
	;
exit:
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call	SpoolGetNumberOfPrinters
		tst	cx			; if we have no printers,
		jnz	initList		; ...still create one item
		inc	cx			; ...for "No Printers" item
initList:
		mov	bx, handle PrinterList
		mov	si, offset PrinterList
		call	ObjMessage_near_send

		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	SpoolInitPrinterIndex
		jnc	sendStatus
		clr	cx			; no printers, but still 1 item
sendStatus:
		clr	dx			; determinate
		call	ObjMessage_near_send
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		call	ObjMessage_near_send

		.leave
		ret

noMorePrintersPop:
		add	sp,4			; clean up stack (CX, AX)
		jmp	addPrintToFile		; we're outta here

skipPrinter:
		pop	cx, ax			; number of, printer num
		inc	ax			; go to the next printer
		jmp	nextPrinter
SpoolBuildPrinterListFromInitFile		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolAddPrinterFromInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds printer to printer list from init file category

CALLED BY:	SpoolBuildPrinterListFromInitFile

PASS:		ds:si - null terminated printer category string (DBCS)

RETURN:		carry	- set if some sort of error (ignore entry)

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
portKey 		char	"port",0

PORT_STRING_LENGTH = 32

SpoolAddPrinterFromInitFile		proc	near
SBCS <portString	local	PORT_STRING_LENGTH dup(char)		>
DBCS <portString	local	PORT_STRING_LENGTH dup(wchar)		>
		uses	di
		.enter

		ConvPrinterNameToIniCat

		; Get port string from initfile
		;
		mov	cx, cs
		mov	dx, offset portKey
		segmov	es, ss, ax
		lea	di, ss:portString
		push	bp				;stack frame
SBCS <		mov	bp, PORT_STRING_LENGTH or INITFILE_UPCASE_CHARS>
DBCS <		mov	bp, PORT_STRING_LENGTH*(size wchar) or INITFILE_UPCASE_CHARS>
		call	InitFileReadString
		pop	bp				;stack frame
		ConvPrinterNameDone
		jc	done				;return carry set on err

		; Grab port type, and add printer to list
		;
		call	SpoolGetPortNumberType
		cmp	ax, PPT_FILE			;if this printer can
		stc					;...only print to file,
		je	done				;...don't display here
		call	SpoolAddPrinterToList
		clc
done:
		.leave
		ret
SpoolAddPrinterFromInitFile		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPortNumberType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine port type from port string

CALLED BY:	SpoolAddPrinterFromInitFile

PASS:		ES:DI	= null terminated port string (LPT1)

RETURN:		AX	= PrinterPortType
		BX	= port number enumerated type

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/90	Initial version
	don	04/08/91	Fixed to accomodate "to file" printing
	chrisb	5/93		added "custom".  What a hack!

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(PARALLEL_LPT2-PARALLEL_LPT1) eq 2>
CheckHack <(SERIAL_COM2-SERIAL_COM1) eq 2>

SpoolGetPortNumberType		proc	near
		uses	cx
		.enter

	; Determine the port number (as enumerated type)
	;

SBCS <		mov	bl, {byte}es:[di+3]				>
DBCS <		mov	bl, {byte}es:[di+3*(size wchar)]		>
		sub	bl, '0'
		dec	bl
		shl	bl, 1
		clr	bh

	; Now determine the type of port (serial, parallel, file)
	;

		mov	ax, PPT_PARALLEL		; assume parallel
		add	bx, PARALLEL_LPT1
SBCS <		cmp	{byte} es:[di], 'L'				>
DBCS <		cmp	{wchar} es:[di], 'L'				>
		je	done

	;
	; Compare 2nd byte against "U" for CUSTOM.  Gene will hate this!
	; 					You're right -- I do.
	;
		
SBCS <		cmp	{byte} es:[di]+1, 'U'				>
DBCS <		cmp	{byte} es:[di][1*(size wchar)], 'U'		>
		je	custom
		
		mov	ax, PPT_SERIAL
		add	bx, SERIAL_COM1 - PARALLEL_LPT1
		cmp	{byte} es:[di], 'C'
		je	done
		clr	bx				; port number is zero
		mov	ax, PPT_FILE	
		cmp	{byte} es:[di], 'F'
		je	done
		mov	ax, PPT_NOTHING	
done:
		.leave
		ret

custom:
		mov	ax, PPT_CUSTOM
		clr	bx
		jmp	done
		
SpoolGetPortNumberType		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCalcMonikerSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the various sizes needed for the control panel
		monikers that will be displayed later

CALLED BY:	SpoolShowPrinterControlPanel
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/09/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCalcMonikerSizes	proc	near
		uses	ax, bx, cx, dx, di, si, bp
		.enter

		; First we need to create a caluclation gstate
		;
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjMessage_PCP_call		; GState => BP
EC <		ERROR_NC	CONTROL_PANEL_CALC_MONIKER_SIZES_FAIL	>

		; Now store some information about the font we're using
		;
		mov	di, bp				; GState => DI
		mov	si, GFMI_MAX_ADJUSTED_HEIGHT or GFMI_ROUNDED
		call	GrFontMetrics			; font box height => DX
		mov	ds:[monikerHeight], dx
		mov	si, GFMI_AVERAGE_WIDTH	or GFMI_ROUNDED
		call	GrFontMetrics			; avg char width => DX
PZ <		shr	dx, 1				; HACK for Pizza >
		mov	ds:[avgFontWidth], dx
	
		; Clean up
		;
		call	GrDestroyState			; destroy the GState

		.leave
		ret
SpoolCalcMonikerSizes	endp




;/////////////////////////////////////////////////////////////////////////////
;
;  	Control Panel Interface Routines
;
;/////////////////////////////////////////////////////////////////////////////



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolExpressMenuControlItemCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the creation of the express menu control panel
		item we requested.

CALLED BY:	MSG_EMOM_INITIALIZE_ITEM
PASS:		es	= DGroup
		^lcx:dx	= EMTrigger object created for us
		bp	= response data (always 0 and ignored)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/10/92	broke out from SpoolExpressMenuChange

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolExpressMenuControlItemCreated method dynamic SpoolEMOMClass, 
				MSG_EMOM_INITIALIZE_ITEM
	;
	; Set its moniker properly.
	;
		movdw	bxsi, cxdx		; ^lbx:si <- trigger
		mov	cx, handle Strings		
		mov	dx, offset Strings:pcpTriggerMonikerShort
		test	es:[uiOptions], mask SUIO_SIMPLE
		jnz	setMoniker		; if simple UI, jump
		mov	dx, offset Strings:pcpTriggerMoniker
setMoniker:
		mov	bp, VUM_MANUAL
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Tell it to send us a message to bring up the control panel.
	; 
		mov	cx, MSG_SPOOL_SHOW_PRINTER_CONTROL_PANEL		
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		
		mov	cx, handle 0
		clr	dx
		mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Mark it as bringing up a window.
	; 
		mov	dx, size AddVarDataParams
		mov	ax, HINT_TRIGGER_BRINGS_UP_WINDOW
		push	ax
			CheckHack <AVDP_dataType eq AddVarDataParams-2>
		clr	ax
			CheckHack <AVDP_dataSize eq AddVarDataParams-4>
			CheckHack <AVDP_data eq 0>
		push	ax, ax, ax
		mov	bp, sp
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	di, mask MF_FIXUP_DS or mask MF_STACK
		call	ObjMessage
		add	sp, size AddVarDataParams
	;
	; Set it usable, finally.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		clr	di
		GOTO	ObjMessage
SpoolExpressMenuControlItemCreated	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolShowPrinterControlPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring control panel up onto screen

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/12/90	Initial version
	don	04/09/91	Cleaned up code a little

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolShowPrinterControlPanel method	dynamic SpoolProcClass, \
					MSG_SPOOL_SHOW_PRINTER_CONTROL_PANEL
		.enter

		mov	ax, MSG_GEN_SYSTEM_MARK_BUSY
		call	UserCallSystem
	;
	;  Request space for the UI.
	;
		call	GeodeGetProcessHandle
		mov	cx, SPOOL_CONTROL_PANEL_RESERVATION
		call	GeodeRequestSpace
		mov	ds:[controlPanelReserve], bx
	;
	; Initalize the dialog box & data structures
	;
		call	SpoolCheckInterfaceLevel
		call	SpoolCalcMonikerSizes
		call	SpoolCreateTitleString
		call	SpoolPanelStartTimer
		call	SpoolInitPrinterControlPanel
		call	SpoolBuildPrinterListFromInitFile
	;
	; Dispaly the dialog box
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage_PCP
	;
	; This segmov is to allow the MF_FIXUP_DS something to sink
	; its teeth into.  Urghgh.
	;
		segmov	ds, dgroup, ax		
		mov	ax, MSG_GEN_SYSTEM_MARK_NOT_BUSY
		call	UserCallSystem

		.leave
		ret
SpoolShowPrinterControlPanel		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCheckInterfaceLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify the UI based upon the interface level

CALLED BY:	GLOBAL

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/27/93		Initial version
		SH	4/28/94		XIP'ed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

smallSpecSize		label	word
			SpecWidth  <SST_AVG_CHAR_WIDTHS, 32>
			SpecHeight <SST_LINES_OF_TEXT, 3>
			word	3
smallSpecSizeSize	equ	$-smallSpecSize

SpoolCheckInterfaceLevel	proc	near
if FULL_EXECUTE_IN_PLACE
		uses	ax, bx, cx, dx, di, si, es, bp
else
		uses	ax, bx, cx, dx, di, si, bp
endif
		.enter
	
		; Check to see if we should disable the 
		; "Make Next" and "Make Last" triggers
		;
		test	ds:[uiOptions], mask SUIO_NO_MAKE_NEXT_OR_LAST
		jz	checkSimple
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	bx, handle PrinterControlPanelUI
		mov	si, offset FrontJobTrigger
		call	ObjMessage_near_send
		mov	si, offset BackJobTrigger
		call	ObjMessage_near_send

		; See if we are operating in simple mode
checkSimple:
		test	ds:[uiOptions], mask SUIO_SIMPLE
		jz	done

		; Change the name of the dialog box
		;
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	bx, handle PrinterControlPanel
		mov	si, offset PrinterControlPanel
		mov	cx, offset PanelTitleShort
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjMessage_near_send

		; For now, reset the width to something that will fit
		; on the Zoomer. Eventually, this should chek to see
		; what the width of the screen is, or something like that.
		;
if FULL_EXECUTE_IN_PLACE
		; Here we have to copy the sammlSpecSize data to the stack
		; since we can't pass a movable-code-segment-fptr to 
		; MSG_META_ADD_VAR_DATA 
		;
		segmov	es, cs
		mov	di, offset smallSpecSize
		mov	cx, smallSpecSizeSize
		call	SysCopyToStackESDI	; es:di <- stack
endif
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	dx, size AddVarDataParams
		sub	sp, dx
		mov	bp, sp			; AddVarDataParams => SS:BP
NOFXIP<		mov	ss:[bp].AVDP_data.segment, cs			>
NOFXIP<		mov	ss:[bp].AVDP_data.offset, offset smallSpecSize	>
FXIP<		mov	ss:[bp].AVDP_data.segment, es			>
FXIP<		mov	ss:[bp].AVDP_data.offset, di			>
		mov	ss:[bp].AVDP_dataSize, smallSpecSizeSize
		mov	ss:[bp].AVDP_dataType, HINT_FIXED_SIZE
		mov	di, mask MF_STACK or mask MF_CALL
		call	ObjMessage_JL
		add	sp, size AddVarDataParams

		; If XIP'ed remove the smallSpecSize data from the stack
		;	
FXIP<		call	SysRemoveFromStack				>

done:
		.leave
		ret
SpoolCheckInterfaceLevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelRequestPrinterMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to the request for a moniker for a given printer

PASS:		CX:DX	= GenDynamicList to respond to
		BP	= Printer #

RETURN:		Nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/2/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPanelRequestPrinterMoniker	method	dynamic	SpoolProcClass, \
					MSG_SPOOL_PANEL_REQUEST_PRINTER_MONIKER
		.enter
	;
	; Access the printer's name, and then set that as the moniker
	;
		mov	si, dx
		xchg	cx, bp
		call	SpoolGetPtrToPrinterElement	; element=> DS:DI
		jc	noPrinters
		add	di, offset BPI_nameString	; printer name => DS:DI
common:
		push	bx			; save string memory handle
		mov	bx, bp			; GenDynamicList OD => BX:SI
		mov	bp, cx			; item # => BP
		mov	cx, ds
		mov	dx, di			
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
		call	ObjMessage_near_call
	;
	; Clean up
	;
		pop	bx
		call	MemUnlock

		.leave
		ret

		; Set text to "No Printers" String
		;
noPrinters:
		call	MemUnlock		; unlock block from above
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		assume	ds:Strings
		mov	di, ds:[noPrintersString]	; string => DS:DI
		assume	ds:dgroup
		jmp	common
SpoolPanelRequestPrinterMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelShowPrinterQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a specific printer's queue

PASS:		CX	= Printer #

RETURN:		Nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/2/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPanelShowPrinterQueue	method	dynamic	SpoolProcClass, \
					MSG_SPOOL_PANEL_SHOW_PRINTER_QUEUE
		.enter
	;
	; Set the printer # and the build the list
	;
		call	SpoolSetPrinterIndex
		call	SpoolBuildJobQueueListForCurrentPrinter

		.leave
		ret
SpoolPanelShowPrinterQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelCancelQueuedJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent by Remove Document button in control panel.
		Cancel job that is currently selected.

PASS:		
		nothing
RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolPanelCancelQueuedJob	method	dynamic	SpoolProcClass, \
					MSG_SPOOL_PANEL_CANCEL_QUEUED_JOB
		.enter

		; Get job id for list entry with excl
		;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage_JL_call
		jc	done			; if none selected, abort
		mov_tr	cx, ax			; Job ID => CX

		; Delete that job
		;
		call	SpoolDelJob
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		jne	done

		; Remove that job now from the list to give the user
		; some feed back
		;
		call	SpoolGetCurrentPrinterPortInfo
		call	SpoolPanelJobRemoved
done:
		.leave
		ret
SpoolPanelCancelQueuedJob		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelMakeJobFirst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current job the next job to be printed.

CALLED BY:	UI (MSG_SPOOL_PANEL_MAKE_JOB_FIRST)
	
PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPanelMakeJobFirst	method	dynamic SpoolProcClass,	\
					MSG_SPOOL_PANEL_MAKE_JOB_FIRST
		.enter

		; Get job id for list entry with excl
		;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage_JL_call
		jc	done			; if none selected, abort
		mov_tr	cx, ax			; Job ID => CX

		; Move the job to the front
		;
		call	SpoolHurryJob
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		jne	done

		; Now fixup the jobs list
		;
		call	SpoolBuildJobQueueListForCurrentPrinter
done:
		.leave
		ret
SpoolPanelMakeJobFirst	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelMakeJobLast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the current job the last job to be printed

CALLED BY:	UI (MSG_SPOOL_PANEL_MAKE_JOB_LAST)
	
PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPanelMakeJobLast	method	dynamic	SpoolProcClass,	\
					MSG_SPOOL_PANEL_MAKE_JOB_LAST
		.enter

		; Get job id for list entry with excl
		;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage_JL_call
		jc	done			; if none selected, abort
		mov_tr	cx, ax			; Job ID => CX

		; Move the job to the front
		;
		call	SpoolDelayJob
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		jne	done

		; Now fixup the jobs list
		;
		call	SpoolBuildJobQueueListForCurrentPrinter
done:
		.leave
		ret
SpoolPanelMakeJobLast	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelJobRemoved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when job is removed from a queue. Update the job
		list if this job is in the current queue.

CALLED BY:	SpoolJobRemoved

PASS:		AX	= PrinterPortType
		BX	= ParallelPortNum or SerialPortNum
		CX	= Job ID

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolPanelJobRemoved		proc	far
		uses	ax, bx, cx, dx, bp, ds
		.enter

		call	CheckPanelBlock
		jz	done

		call	SpoolBuildJobQueueListForCurrentPrinter
done:
		.leave
		ret
SpoolPanelJobRemoved		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelJobAdded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called when job added to a queue. Update the job
		list if this job is in the current queue.

CALLED BY:	SpoolJobAdded

PASS:		
		cx - job id
		ax - PrinterPortType 
		bx - ParallelPortNum or SerialPortNum

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolPanelJobAdded		proc	far
		uses	ax,bx,cx,dx,bp,ds
		.enter

		call	CheckPanelBlock
		jz	done		

	;
	; We have no way of knowing from the port info which printer
	; the job is headed for, since there can be multiple printers
	; for a queue, so just rebuild the list for the
	; currently displayed printer.
	;
		
		call	SpoolBuildJobQueueListForCurrentPrinter
done:
		.leave
		ret
SpoolPanelJobAdded		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCloseControlPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dismiss the control panel and vaporize its data structures

CALLED BY:	

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolCloseControlPanel	method dynamic SpoolProcClass, \
					MSG_SPOOL_PANEL_CLOSE
		.enter

		call	SpoolPanelStopTimer

	;
	; Close the dialog box
	;
		
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	cx, IC_DISMISS
		clr	di
		call	ObjMessage_PCP
		call	SpoolDestroyJobQueueList

	;
	; Destory printer control panel block
	;
		
		segmov	ds, dgroup, ax
		clr	bx
		xchg	bx, ds:[printerControlPanelBlock]
		call	MemFree
	;
	;  Free the requested heapspace.
	;
		clr	bx
		xchg	bx, ds:[controlPanelReserve]
		call	GeodeReturnSpace

		.leave
		ret
SpoolCloseControlPanel		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelJobList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent when the user selects an item in the jobs list
		Set selectedJobInfo and update state of job buttons

PASS:		DS	= DGroup
		CX	= Job ID

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolPanelJobList	method dynamic SpoolProcClass, \
					MSG_SPOOL_PANEL_JOB_LIST
		.enter

		call	CheckPanelBlock
		jz	done
		
		call	SpoolCalcSelectedJobInfoFromID
		call	SpoolSetSelectedJobInfo
		call	SpoolPanelSetStateOfJobTriggers
done:
		.leave
		ret
SpoolPanelJobList	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPanelBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there's a PrinterControlPanel block

CALLED BY:	lots of places

PASS:		nothing 

RETURN:		DS - dgroup
		ZERO flag set if no panel block

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/30/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckPanelBlock	proc near
		uses	ax
		.enter

		segmov	ds, dgroup, ax
		tst	ds:[printerControlPanelBlock]
		.leave
		ret
CheckPanelBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCalcSelectedJobInfoFromID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine selectedJobInfo given the job id of the selected job

CALLED BY:	SpoolPanelJobList

PASS:		CX	= Job ID

RETURN:		DL	= SelectedJobInfo

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolCalcSelectedJobInfoFromID		proc	near
		uses	ax, bx, cx, di, si, ds
		
currentJobID	local	word	push	cx
portInfo	local	PrintPortInfo
		.enter

		cmp	cx, GIGS_NONE
		je	noJobs
	;
	; Fetch the port type and number for the current printer
	;

		call	SpoolGetCurrentPrinterPortInfo
		jc	noJobs

	;
	; Get the list of ALL jobs for this queue, not just those for
	; this printer (there may be multiple printers servicing the
	; same queue).
	;
		mov	ss:[portInfo].PPI_type, ax
		mov	ss:[portInfo].PPI_params.PP_serial.SPP_portNum, bx
		mov	cx, SIT_QUEUE_INFO
		mov	dx, ss
		lea	si, ss:[portInfo]
		
		call	SpoolInfo
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		jne	noJobs

		jcxz	noJobs

	;
	; Search the list for the passed job ID.  If it's the head of
	; the list (si=2 after the first lodsw), then set SJI_PRINTING.
	; If it's the second item (si=4), set SJI_NEXT.
	; If it's the last item (cx=1, since cx is being decremented),
	; set SJI_LAST
	;
		
		call	MemLock
		
		mov	ds, ax

		clr	si, dx		; si - next ID.  dl = flags
startLoop:

	;
	; Keep looking until we find the job.  SI points 2 past the
	; current entry, and CX is the number, counting backwards from
	; the end of the list (1-based).
	;
		
		lodsw
		cmp	ax, ss:[currentJobID]
		je	checkFlags
		loop	startLoop

	;
	; It's not in the list.  This should never happen, but rather
	; than fatal error, just set the NONE flag, and bail (?)
	;
		mov	dl, mask SJI_NONE
		jmp	free

checkFlags:
		cmp	si, 2		; Is it the first job?
		jne	afterPrinting
		ornf	dl, mask SJI_PRINTING

afterPrinting:
		cmp	si, 4		; how about the second job?
		jne	afterNext
		ornf	dl, mask SJI_NEXT

afterNext:
		cmp	cx, 1		; or the last job?
		jne	free
		ornf	dl, mask SJI_LAST

free:
		call	MemFree

done:
		.leave
		ret
noJobs:
		mov	dl, mask SJI_NONE
		jmp	done
SpoolCalcSelectedJobInfoFromID		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInitPrinterControlPanel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize data structures for printer control panel

CALLED BY:	SpoolAttach

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		allocate PrinterControlDataBlock
		call	BuildPrinterList
		initialize PrinterControlData

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolInitPrinterControlPanel		proc	near
		uses	ax, bx, cx, ds
		.enter


		; Allocate lmem block for printer control data and save
		; its handle in dgroup
		;
		mov	ax, dgroup
		mov	ds, ax
		mov	ax, LMEM_TYPE_GENERAL	; LMemType => AX
		mov	cx, size PrinterControlPanelLMemHeader
		call	MemAllocLMem		; allocate & initialize heap
		mov	ds:[printerControlPanelBlock], bx

		; Initialize our data structures
		;
		call	MemLock
		mov	ds, ax
		mov	ds:[PCPLH_data].PCP_selectedJobInfo, mask SJI_NONE
		mov	ds:[PCPLH_data].PCP_currentPrinter, -1
		clr	ds:[PCPLH_data].PCP_printerList
		call	MemUnlock

		.leave
		ret
SpoolInitPrinterControlPanel		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelSetStateOfJobTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the Next Printer Trigger to enabled if there are
		at least two printers

CALLED BY:	SpoolPanelJobList

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPanelSetStateOfJobTriggers		proc	near
		uses	ax, bx, cx, dx, si, di, ds
		.enter
	
	; Grab the Control Panel block
	;

		call	SpoolControlPanelAccessBlock
		push	bx
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE

	; Set the state of the "Make Next" trigger
	;

		mov	cl, mask SJI_NEXT or mask SJI_NONE or mask SJI_PRINTING
		mov	si, offset FrontJobTrigger
		call	SpoolPanelTriggerEnableDisable

	; Set the state of the "Make Last" trigger
	;

		mov	cl, mask SJI_LAST or mask SJI_NONE or mask SJI_PRINTING
		mov	si, offset BackJobTrigger
		call	SpoolPanelTriggerEnableDisable

	; Set the state of the "Cancel" trigger
	;

		mov	dl, VUM_NOW
		mov	cl, mask SJI_NONE
		mov	si, offset CancelJobTrigger
		call	SpoolPanelTriggerEnableDisable

	; Clean up
	;

		pop	bx
		call	MemUnlock

		.leave
		ret
SpoolPanelSetStateOfJobTriggers		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanelTriggerEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the passed trigger.  If any of the
		passed flags are set, then disable it, Otherwise
		enable it.

CALLED BY:	SpoolPanelSetStateOfJobTriggers

PASS:		cl - SelectedJobInfo flags to check
		^lbx:si - trigger to set

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/30/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolPanelTriggerEnableDisable	proc	near
		
		mov	bx, handle PrinterControlPanelUI
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		test	ds:[PCPLH_data].PCP_selectedJobInfo, cl
		jnz	setStatus
		mov	ax, MSG_GEN_SET_ENABLED
setStatus:
		GOTO	ObjMessage_near_send
SpoolPanelTriggerEnableDisable	endp


;/////////////////////////////////////////////////////////////////////////////
;
;  	Printer List Data Structure Interface Routines
;
;/////////////////////////////////////////////////////////////////////////////


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetNumberOfPrinters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of printers in printer list

CALLED BY:	SpoolSetStateOfNextPrinterTrigger

PASS:		Nothing

RETURN:		CX	= number of printers

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolGetNumberOfPrinters	proc	near
		uses	ax, bx, ds
		.enter

		; Access printer control panel block
		;
		call	SpoolControlPanelAccessBlock
		mov	cx, ds:[PCPLH_data].PCP_numberOfPrinters
		call	MemUnlock

		.leave
		ret
SpoolGetNumberOfPrinters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInitPrinterIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer index

CALLED BY:	BuildListOfPrintersFromInitFile

PASS:		Nothing

RETURN:		Carry	= clear (sucess)
		CX	= Printer index
			- or -
		Carry	= set (no printers)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolInitPrinterIndex	proc	near
		uses	ax, bx, dx, di, si, ds
		.enter
	;
	; Access printer control panel block
	;
		call	SpoolControlPanelAccessBlock
		push	bx			; save PrintControlPanel block
	;
	; If there are no printers, we're done
	;
		tst	ds:[PCPLH_data].PCP_numberOfPrinters
		stc				; failure!
		jz	done
	;
	; Choose the first printer with jobs to be the current printer,
	; or else use the default printer.
	;
		call	SpoolGetDefaultPrinter
		mov	ds:[PCPLH_data].PCP_currentPrinter, ax
		mov	di, ds:[PCPLH_data].PCP_numberOfPrinters
		cmp	di, 1
		jle	success			; if zero or one printers, done
		clr	cx			; else start with first printer
printerLoop:
		push	cx
		call	SpoolGetQueueInfoForPrinter
		jc	next
		jcxz	next
	;
	; OK, we found a printer with jobs. Clean up and exit
	;
		call	MemFree
		pop	ds:[PCPLH_data].PCP_currentPrinter
		jmp	success
next:
		pop	cx			; restore printer index
		inc	cx			; go to the next printer
		cmp	cx, di			; done with all the printers ??
		jl	printerLoop		; no, so loop again
success:
		clc				; success!
done:		
		mov	cx, ds:[PCPLH_data].PCP_currentPrinter
		pop	bx			; restore PCP block handle
		pushf
		call	MemUnlock
		popf

		.leave
		ret
SpoolInitPrinterIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSetPrinterIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the printer index to the passed value

CALLED BY:	

PASS:		CX	= Printer #

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolSetPrinterIndex	proc	near
		uses	ax, bx, ds
		.enter
	;
	; Store the value away
	;
		call	SpoolControlPanelAccessBlock
		mov	ds:[PCPLH_data].PCP_currentPrinter, cx
		call	MemUnlock

		.leave
		ret
SpoolSetPrinterIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPrinterIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return current printer index.

CALLED BY:	INTERNAL

PASS:		Nothing

RETURN:		CX	= Printer index (-1 if no printers)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolGetPrinterIndex		proc	near
		uses	ax, bx, ds
		.enter
	;
	; Simply get the current printer index
	;
		call	SpoolControlPanelAccessBlock
		mov	cx, ds:[PCPLH_data].PCP_currentPrinter
		call	MemUnlock

		.leave
		ret
SpoolGetPrinterIndex		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolAddPrinterToList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a printer to the printer list

CALLED BY:	SpoolAddPrinterFromInitFile

PASS:		
		ds:si - printer name string
		ax - PrinterPortType
		bx - ParallelPortNum or SerialPortNum
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/90	Initial version
	chrisb	6/93		changed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolAddPrinterToList		proc	near
		uses	ax,bx,cx,dx,si,di,ds,es
		
		.enter

		push	si			; string
		push	ax			; PrinterPortType
		push	bx			; port num
		segmov	es, ds			;printer string

	;
	; Access printer list
	;
		
		call	SpoolControlPanelAccessBlock
		mov	si, ds:[PCPLH_data].PCP_printerList

		call	ChunkArrayAppend

	;
	; Copy data to new element
	;
		
		pop	ds:[di].BPI_portInfo.PPI_params.\
						PP_parallel.PPP_portNum

		pop	ds:[di].BPI_portInfo.PPI_type

		pop	si
		
		segxchg	ds, es			;ds <- printer string	
						;es <- new element
		add	di, offset BPI_nameString

		LocalCopyString

	;
	; Update number of printers and unlock printer control panel
	;

		inc	es:[PCPLH_data].PCP_numberOfPrinters
		mov	bx, es:[LMBH_handle]
		call	MemUnlock

		.leave
		ret

SpoolAddPrinterToList		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetCurrentPrinterPortInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return port information for current printer

CALLED BY:	

PASS:		Nothing

RETURN:		Carry	= Clear
				AX = PrinterPortType
				BX = Port number enumerated type
			= Set
				error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolGetCurrentPrinterPortInfo		proc	near
		uses	cx
		.enter

		call	SpoolGetPrinterIndex
		call	SpoolGetPortInfoByIndex

		.leave
		ret
SpoolGetCurrentPrinterPortInfo		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPortInfoByIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return PrintPortInfo for printer in list

CALLED BY:	INTERNAL

PASS:		CX	= Element number

RETURN:		Carry	= Clear
				AX = PrinterPortType
				BX = Port number enumerated type
			= Set
				error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolGetPortInfoByIndex		proc	near
		uses	cx, di, ds
		.enter

		call	SpoolGetPtrToPrinterElement
		jc	done			; if error, done
		add	di, BPI_portInfo
		mov	ax, ds:[di].PPI_type
		mov	cx, ds:[di].PPI_params.PP_serial.SPP_portNum
		clc

		; Unlock printer control panel block
		;
done:
		call	MemUnlock
		mov	bx, cx		

		.leave
		ret
SpoolGetPortInfoByIndex		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolInitPrinterList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the printer list stored in the PCPB

CALLED BY:	SpoolBuildPrinterListFromInitFile

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		create chunk array
		set number of printers to 0
		set current printer to -1

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 9/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolInitPrinterList		proc	near
		uses	ax,bx,cx,dx,si,ds
		.enter

		call	SpoolControlPanelAccessBlock
		push	bx
		clr	al				;no ObjChunkFlags
		mov	bx, size BasicPrinterInfo
		clr	cx
		mov	si, cx
		call	ChunkArrayCreate
		mov	ds:[PCPLH_data].PCP_printerList, si

		mov	ds:[PCPLH_data].PCP_numberOfPrinters, 0
		mov	ds:[PCPLH_data].PCP_currentPrinter, -1
		
		pop	bx
		call	MemUnlock

		.leave
		ret
SpoolInitPrinterList		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolDestroyPrinterList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy chunk array of printers if it exists

CALLED BY:	SpoolInitPrinterControlPanel

PASS:		
		nothing
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolDestroyPrinterList		proc	near
		uses	ax,bx,si,ds
		.enter

		; Access printer list chunk array
		;
		call	SpoolControlPanelAccessBlock
		push	bx
		mov	si, ds:[PCPLH_data].PCP_printerList
		tst	si
		jz	unlock

		call	ChunkArrayZero
		mov	ax, si
		call	LMemFree
		clr	ds:[PCPLH_data].PCP_printerList
unlock:
		pop	bx
		call	MemUnlock		

		.leave
		ret
SpoolDestroyPrinterList		endp


;/////////////////////////////////////////////////////////////////////////////
;
;  	Printer List Data Structure Internal Routines
;	Routines should only be called by Interface Routines
;
;/////////////////////////////////////////////////////////////////////////////




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetPtrToPrinterElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return ptr to an element in printer list

CALLED BY:	Internal

PASS:		CX	= Element number

RETURN:		Carry	= Clear
				DS:DI	= Ptr to element
				BX	= Block to unlock when done
			= Set
				DS:DI	= Last element in list
				BX	= Block to unlock

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolGetPtrToPrinterElement		proc	near
		uses	ax, si
		.enter

		; Access Printer list chunk array
		; 
		call	SpoolControlPanelAccessBlock
		mov	si, ds:[PCPLH_data].PCP_printerList

		; Access requested printer from chunk array	
		;
		mov	ax, cx
		call	ChunkArrayElementToPtr

		.leave
		ret
SpoolGetPtrToPrinterElement		endp



;/////////////////////////////////////////////////////////////////////////////
;
;  	Job Queue Interface Routines
;
;/////////////////////////////////////////////////////////////////////////////




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetNumberOfJobs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of jobs in jobs list

CALLED BY:	

PASS:		
		nothing
RETURN:		
		cx - number of jobs

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolGetNumberOfJobs		proc	near
		uses	ax,bx,ds
		.enter
		
		call	SpoolControlPanelAccessBlock
		mov	cx, ds:[PCPLH_data].PCP_numberOfJobs
		call	MemUnlock

		.leave
		ret
SpoolGetNumberOfJobs		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSelectJobInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a job in the list.  Have the list send out its
		status message.

CALLED BY:	SpoolBuildJobQueueListForCurrentPrinter

PASS:		CX	= Element to select (0 is first)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolSelectJobInList		proc	near
		uses	ax, bx, di, si
		.enter

	;
	; Set the item to be selected
	;

		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		mov	di, mask MF_CALL
		call	ObjMessage_JL		; OD of child => CX:DX
		jc	done			; if not found, abort
		
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
		mov	di, mask MF_CALL
		call	ObjMessage		; identifier => AX

		mov_tr	cx, ax
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx, di	
		call	ObjMessage_JL	

	;
	; Send it MSG_GEN_APPLY, which will make it update the
	; triggers. In order to do this, it first has to be set
	; modified, so pass SP, on the assumption that it's nonzero.
	;

		mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
		mov	cx, sp
		clr	di
		call	ObjMessage_JL
		
		mov	ax, MSG_GEN_APPLY
		clr	cx, di
		call	ObjMessage_JL
done:
		.leave
		ret
SpoolSelectJobInList		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSetSelectedJobInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set selected job info in control panel

CALLED BY:	SpoolSelectJobInList

PASS:		dl - SelectedJobInfo

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolSetSelectedJobInfo		proc	near
		uses	ax, bx, ds
		.enter

		call	SpoolControlPanelAccessBlock
		mov	ds:[PCPLH_data].PCP_selectedJobInfo, dl
		call	MemUnlock

		.leave
		ret
SpoolSetSelectedJobInfo		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolDestroyJobQueueList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy all entries in the JobList

CALLED BY:	

PASS:		
		nothing
RETURN:		
		nothing
DESTROYED:	
		none

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolDestroyJobQueueList		proc	near
		uses	ax,bx,cx,dx,bp,di,si,ds
		.enter

		segmov	ds, dgroup, ax
		mov	bx, ds:[printerControlPanelBlock]
		tst	bx
		jz	destroy

		call	MemLock
		mov	ds, ax
		mov	ds:[PCPLH_data].PCP_selectedJobInfo, mask SJI_NONE
		clr	ds:[PCPLH_data].PCP_numberOfJobs
		call	MemUnlock

	; Remove children from job list
destroy:
		mov	ax, MSG_GEN_DESTROY
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		clr	bx, si, bp
		mov	di, mask MF_RECORD
		call	ObjMessage
		mov	cx, di

		mov	ax, MSG_GEN_SEND_TO_CHILDREN
		call	ObjMessage_JL_call	;child's OD => CX:DX

		.leave
		ret
SpoolDestroyJobQueueList		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPanel[Start, Stop]Timer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start or stop the Control Panel timer

CALLED BY:	INTERNAL
	
PASS: 		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPanelStartTimer	proc	near
		uses	ax, bx, cx, dx, di
		.enter

		mov	ax, dgroup
		mov	ds, ax
		mov	al, TIMER_EVENT_CONTINUAL
		call	GeodeGetProcessHandle		; process => BX
		mov	cx, 3600			; 1 minute until timeout
		mov	dx, MSG_SPOOL_PANEL_TIMER_TICK
		mov	di, 3600			; go off every minute
		call	TimerStart
		mov	ds:[timerHandle], bx		; store the timer handle

		.leave
		ret
SpoolPanelStartTimer	endp

SpoolPanelStopTimer	proc	near
		uses	bx
		.enter

		mov	bx, dgroup
		mov	ds, bx
		clr	bx, ax
		xchg	bx, ds:[timerHandle]
		call	TimerStop

		.leave
		ret
SpoolPanelStopTimer	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolControlPanelTimerTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the monikers for the spool jobs

CALLED BY:	Timer (MSG_SPOOL_PANEL_TIMER_TICK)
	
PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolControlPanelTimerTick	method	dynamic SpoolProcClass,	\
					MSG_SPOOL_PANEL_TIMER_TICK

		call	CheckPanelBlock
		jz	done

		call	SpoolBuildJobQueueListForCurrentPrinter
done:
		ret
SpoolControlPanelTimerTick	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolBuildJobQueueListForCurrentPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build up list of information about jobs printing or
		queued on the current printer

CALLED BY:	INTERNAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing


PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolBuildJobQueueListForCurrentPrinter		proc	near
		uses	ax, bx, cx, di, es
		.enter

	; Destroy the old queue, and build the current one
	;

		call	SpoolDestroyJobQueueList
		call	SpoolGetPrinterIndex
		cmp	cx, -1
		je	noJobs			; display no jobs moniker

		call	SpoolBuildJobQueueListByIndex
		jc	noJobs

	; Select first job in list
	;
		
		clr	cx
		call	SpoolSelectJobInList
done:
		.leave
		ret

	; Handle case of no jobs for printer list
	;
noJobs:
		call	SpoolSetNoDocumentsInJobList
		jmp	done
SpoolBuildJobQueueListForCurrentPrinter		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreateTitleString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the title string (above the list of jobs)

CALLED BY:	GLOBAL
	
PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/09/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCreateTitleString	proc	near
		uses	ax, cx, dx
		.enter

		mov	ax, SPOOL_TITLE_JOB_ID
		mov	cx, offset SpoolTitleCallBack
		mov	dx, FALSE
		call	SpoolAppendJobEntryFromID

		.leave
		ret
SpoolCreateTitleString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSetNoDocumentsInJobList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an entry of the jobs list that says no documents.
		Put in the list and set the triggers correctly.

CALLED BY:	Internal

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/90	Initial version
	don	04/03/91	Now uses moniker, not string

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolSetNoDocumentsInJobList		proc	near
		uses	ax, bx, cx, dx, di, si, bp
		.enter

		; First ensure an item like this doesn't already exist
		;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
		mov	cx, SPOOL_INVALID_JOB_ID
		mov	di, mask MF_CALL
		call	ObjMessage_JL		; carry = set if found
		jc	done			; already exists, so abort

		; Create the bogus job entry
		;
		mov	ax, SPOOL_INVALID_JOB_ID
		mov	cx, offset SpoolEmptyCallBack
		mov	dx, FALSE
		call	SpoolAppendJobEntryFromID

		; Clean up triggers, etc.
		;
		mov	dl,mask SJI_NONE
		call	SpoolSetSelectedJobInfo
		call	SpoolPanelSetStateOfJobTriggers
done:
		.leave
		ret
SpoolSetNoDocumentsInJobList		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolAppendJobEntryFromID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Added a job to the job list given it's job id

CALLED BY:	SpoolBuildQueueListByIndex

PASS:		AX	= Job ID		
		CX	= Callback routine if AX =
				SPOOL_INVALID_JOB_ID
				SPOOL_TITLE_JOB_ID
		DX	= TRUE to select job to add

RETURN:		Carry	= Clear -  no problem
			= Set - error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/18/90	Initial version
	don	04/04/91	Modified to pass size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PCPMonikerStart	label	byte
	VisMoniker< VisMonikerType<0, 1, DAR_NORMAL, DC_TEXT>, 0>
	VisMonikerGString <0>
	GSBeginString
PCPMDocName	label	byte
	GSSetClipRect		<PCT_REPLACE>, 0, 0, 0, 0
	GSDrawText		0, 0, <>
SBCS <	byte			FILE_LONGNAME_LENGTH dup (GR_NULL_OP)	>
DBCS <	byte			2*FILE_LONGNAME_LENGTH dup (GR_NULL_OP) >
PCPParentName	label	byte
	GSSetClipRect		<PCT_REPLACE>, 0, 0, 0, 0
	GSDrawText		0, 0, <>
SBCS <	byte			FILE_LONGNAME_LENGTH dup (GR_NULL_OP) >
DBCS <	byte			2*FILE_LONGNAME_LENGTH dup (GR_NULL_OP) >
PCPNumPages	label	byte
	GSSetClipRect		<PCT_REPLACE>, 0, 0, 0, 0
	GSDrawText		0, 0, <>
SBCS <	byte			PRINTER_STATUS_MAX_LEN dup (GR_NULL_OP)	>
DBCS <	byte			2*PRINTER_STATUS_MAX_LEN dup (GR_NULL_OP)>
PCPTimeInQueue	label	byte
	GSSetClipRect		<PCT_REPLACE>, 0, 0, 0, 0
	GSDrawText		0, 0, <>
SBCS <	byte			PRINTER_STATUS_MAX_LEN dup (GR_NULL_OP)	>
DBCS <	byte			2*PRINTER_STATUS_MAX_LEN dup (GR_NULL_OP)>
	GSEndString
PCPMonikerEnd	label	byte

PCPM_DOC_NAME_OFFSET		= offset PCPMDocName    - offset PCPMonikerStart
PCPM_PARENT_NAME_OFFSET		= offset PCPParentName  - offset PCPMonikerStart
PCPM_NUM_PAGES_OFFSET		= offset PCPNumPages    - offset PCPMonikerStart
PCPM_TIME_IN_QUEUE_OFFSET	= offset PCPTimeInQueue - offset PCPMonikerStart
PCPM_MONIKER_SIZE		= offset PCPMonikerEnd  - offset PCPMonikerStart

SIMPLE_UI_WIDTH			= 160

SpoolAppendJobEntryFromID		proc	near
jobString	local	PCPM_MONIKER_SIZE dup(byte)
		uses	bx, cx, di, si, ds, es
		.enter

		; Copy the moniker template
		;
		push	cx			; save callback value
		segmov	es, ss
		lea	di, jobString		; buffer => ES:DI
		segmov	ds, cs
		mov	si, offset PCPMonikerStart
		mov	cx, PCPM_MONIKER_SIZE
		rep	movsb			; copy the structure
		pop	cx			; restore callback value

		; Initialize some sizes
		;
		push	ax			; save the job ID
		lea	di, jobString		; buffer => ES:DI
		mov	ax, dgroup
		mov	ds, ax
		mov	ax, ds:[monikerHeight]
		mov	es:[di][PCPM_DOC_NAME_OFFSET].OSCR_rect.R_bottom, ax
		mov	es:[di][PCPM_PARENT_NAME_OFFSET].OSCR_rect.R_bottom, ax
		mov	es:[di][PCPM_NUM_PAGES_OFFSET].OSCR_rect.R_bottom, ax
		mov	es:[di][PCPM_TIME_IN_QUEUE_OFFSET].OSCR_rect.R_bottom,ax
		pop	ax			; restore the job ID

		; If we are displaying simple UI, cut the width of the moniker
		;
		test	ds:[uiOptions], mask SUIO_SIMPLE
		jz	createString
		mov	es:[di].VM_width, SIMPLE_UI_WIDTH
		
		; Now create the string and the job entry
createString:
		call	SpoolCreateJobStringFromID
		jc	done
		push	bp			; save local data
		mov	cx, PCPM_MONIKER_SIZE
		mov	bp,CCO_LAST 
		call	SpoolCreateJobEntry
		pop	bp			; restore local data
		clc
done:
		.leave
		ret
SpoolAppendJobEntryFromID		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreateJobEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an job entry in the job list

CALLED BY:	SpoolAppendJobEntry

PASS:		ES:DI	= Moniker structure
		AX	= Job ID
				SPOOL_INVALID_JOB_ID
				SPOOL_TITLE_JOB_ID				
		CX	= Size of moniker structure
		DX	= TRUE, if job should be selected
		BP	= CompChildFlags

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/15/90	Initial version
	don	04/03/91	Changed to use moniker, not string

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolCreateJobEntry		proc	near
		uses	ax, bx, cx, dx, di, si, bp, ds
		.enter
		
		; Up the count of jobs in the list if the passed id
		; is a valid job id
		;
		cmp	ax, SPOOL_TITLE_JOB_ID
		je	doTitle
		push	ax, dx, cx, es, di, ax
		cmp	ax, SPOOL_INVALID_JOB_ID
		je	copy
		call	SpoolControlPanelAccessBlock
		mov	ax, dgroup
		inc	ds:[PCPLH_data].PCP_numberOfJobs
		call	MemUnlock

		; Create the new GenItem
copy:
		mov	ax, segment GenItemClass
		mov	es, ax
		mov	di, offset GenItemClass		; ClassStruct => ES:DI
		mov	bx, handle JobList
		call	ObjInstantiate			; instantiate a GenItem

		; Set list entry method to job id
		;
		mov	ax, MSG_GEN_ITEM_SET_IDENTIFIER
		pop	cx				; JobID => CX
		call	ObjMessage_near_call

		; Set vis moniker to the passed moniker
		;
		pop	es, di				; moniker => ES:DI
		pop	cx				; moniker size => CX
		mov	al, VUM_MANUAL
		call	SpoolCopyVisMoniker

		; Make the GenItem a child of the GenItemGroup
		;
		mov	ax, MSG_GEN_ADD_CHILD
		mov	cx, bx
		mov	dx, si
		mov	bp, CCO_LAST		
		clr	di
		call	ObjMessage_JL

		; Set the GenItem usable
		;	
		mov	si, dx				; GenItem OD => BX:SI
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage_near_send

		; if TRUE passed, then send method to list to
		; select the new list entry
		;
		pop	ax				; Boolean => AX
		pop	cx				; JobID => CX
		cmp	ax, FALSE
		je	done
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	di
		call	ObjMessage_JL
done:
		.leave
		ret

		; Copy in the moniker
doTitle:
		mov	bx, handle JobList
		mov	si, offset JobList
		mov	al, VUM_DELAYED_VIA_UI_QUEUE
		call	SpoolCopyVisMoniker
		jmp	done
SpoolCreateJobEntry		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCopyVisMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a passed moniker into a generic object

CALLED BY:	INTERNAL
	
PASS:		BX:SI	= OD of generic object whose moniker we are setting
		ES:DI	= Moniker structure
		CX	= Length of the moniker
		AL	= VisUpdateMode

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/09/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCopyVisMoniker	proc	near
		.enter

		mov	dx, size ReplaceVisMonikerFrame
		sub	sp, dx				; allocate stack buffer
		mov	bp, sp
		mov	ss:[bp].RVMF_source.segment, es
		mov	ss:[bp].RVMF_source.offset, di
		mov	ss:[bp].RVMF_sourceType, VMST_FPTR
		mov	ss:[bp].RVMF_dataType, VMDT_VIS_MONIKER
		mov	ss:[bp].RVMF_updateMode, al
		mov	ss:[bp].RVMF_length, cx
		clr	ss:[bp].RVMF_width
		clr	ss:[bp].RVMF_height
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, size ReplaceVisMonikerFrame	; free stack buffer

		.leave
		ret
SpoolCopyVisMoniker	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreateJobStringFromID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create string describing job from the job id

CALLED BY:	SpoolBuildJobQueueListByIndex

PASS:		AX	= Job ID
		ES:DI	= PCPMoniker template (PCPM_MONIKER_LENGTH)
		CX	= Callback routine

RETURN:		Carry	= Clear (moniker is completed)
			= Set (error)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/15/90	Initial version
	don	04/03/91	Uses a GString Moniker now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolCreateJobStringFromID		proc	near
		uses	ax, bx, cx, dx, di, si, bp, ds
		.enter

		; See if we should be here, or elsewhere
		;
		cmp	ax, SPOOL_INVALID_JOB_ID
		je	nonJob
		cmp	ax, SPOOL_TITLE_JOB_ID
		jne	realJob
nonJob:
		call	SpoolCreateNonJobString
		clc
		jmp	done
		
		; Grab the job information
		;
realJob:
		mov	dx, ax
		mov	cx, SIT_JOB_INFO
		call	SpoolInfo
		cmp	ax, SPOOL_JOB_NOT_FOUND
		stc				; assume an error
		je	done			; if so, then return carry set
		push	bx			; save the JobStatus block

		; Determine the various offsets (use only AX, CX, DX)
		;
		clr	ax			; HACK HACK HACK HACK
		call	SpoolPushMonikerOffsets

		; Now include the document name
		;
		call	MemLock			
		mov	ds, ax			; JobStatus segment => DS
		clr	dx			; left side
		pop	bx			; right side
		mov	si, JS_documentName
		mov	ax, PCPM_DOC_NAME_OFFSET
		call	SpoolCopyStringToMoniker

		; Write the application who created the document
		;
		mov	dx, bx			; left side
		pop	bx			; right side
		mov	si, JS_parent
		mov	ax, PCPM_PARENT_NAME_OFFSET
		call	SpoolCopyStringToMoniker
		
		; Write the number of pages
		;
		mov	dx, bx			; left side
		pop	bx			; right side
		mov	si, ds:[JS_numPages]
		mov	ax, PCPM_NUM_PAGES_OFFSET
		clr	cx			; don't append a string
		call	SpoolCopyNumberToMoniker

		; Write the time its been in the queue
		;
		cmp	ds:[JS_printing], SJP_NOT_PRINTING
		jne	statusPrinting
		push	bx
		call	TimerGetDateAndTime	; values => AX, BX, CX, DX
		sub	ch, ds:[JS_time].STS_hour
		jge	convertHours
		add	ch, 24			; assume day has changed
convertHours:
		mov	al, 60			; 60 minutes in an hour
		mul	ch
		xchg	ax, si			; raw minutes => SI
		sub	dl, ds:[JS_time].STS_minute		
		mov	al, dl
		cbw				; sign-extend minutes
		add	si, ax			; raw minutes in queue => SI
		pop	dx			; left side
		pop	bx			; right side
		add	bx, CLIP_SPACE-1
		mov	ax, PCPM_TIME_IN_QUEUE_OFFSET
		mov	cx, 1			; append "min" string
		call	SpoolCopyNumberToMoniker
		jmp	cleanUp

		; We are currently printing
		;
statusPrinting:
		mov	dx, bx			; left side
		pop	bx			; right side
		add	bx, CLIP_SPACE-1
		mov	ax, PCPM_TIME_IN_QUEUE_OFFSET
		mov	si, offset Strings:printingString
		call	SpoolCopyPrintingToMoniker

		; Clean up
		;
cleanUp:
		pop	bx
		call	MemFree
		clc
done:
		.leave
		ret
SpoolCreateJobStringFromID		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCreateNonJobString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create string describing job from the job id

CALLED BY:	SpoolShowPrinterControlPanel

PASS:		ES:DI	= PCPMMoniker template

RETURN:		Carry	= Clear

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	04/09/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolCreateNonJobString		proc	near
callBack	local	nptr			; call back for string \
		push	cx
		uses	ax, bx, cx, dx, di, si, ds, es
		.enter

		; Access the Strings resource
		;
		mov	ax, 2			; HACK HACK HACK HACK
		call	SpoolPushMonikerOffsets
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax			; Strings segment => DS
		assume	ds:Strings

		; Write the document string
		;
		clr	dx			; left side
		pop	bx			; right side
		clr	si			; zero'th string
		call	ss:[callBack]
		mov	ax, PCPM_DOC_NAME_OFFSET
		call	SpoolCopyStringToMoniker

		; Write the application who created the document
		;
		mov	dx, bx			; left side
		pop	bx			; right side
		mov	si, 1
		call	ss:[callBack]
		mov	ax, PCPM_PARENT_NAME_OFFSET
		call	SpoolCopyStringToMoniker
		
		; Write the number of pages
		;
		mov	dx, bx			; left side
		pop	bx			; right side
		mov	si, 2
		call	ss:[callBack]
		mov	ax, PCPM_NUM_PAGES_OFFSET
		call	SpoolCopyStringToMoniker

		; Write the time its been in the queue
		;
		mov	dx, bx			; left side
		pop	bx			; right side
		add	bx, CLIP_SPACE-1
		mov	si, 3
		call	ss:[callBack]
		mov	ax, PCPM_TIME_IN_QUEUE_OFFSET
		call	SpoolCopyStringToMoniker

		; Clean up
		;
		mov	bx, handle Strings
		call	MemUnlock
		assume	ds:dgroup

		.leave
		ret
SpoolCreateNonJobString		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolPushMonikerOffsets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push the moniker offsets onto the stack

CALLED BY:	SpoolCreateJobStringFromID, SpoolCreateNonJobString
	
PASS:		AX	= Offset in horizontal direction (HACK)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, SI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Plays with the return address, so I can return with the
		values on the stack. Must be a near routine!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/09/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolPushMonikerOffsets	proc	near

		; Determine the various offsets (use only AX, CX)
		;
		pop	si			; save the return address
		xchg	ax, dx
		mov	ax, dgroup
		mov	ds, ax
		mov	ax, ds:[avgFontWidth]	; single character width => AX
		mov	cl, 60
		mul	cl
		add	dx, ax
		push	dx			; far right (60 x)
		mov	ax, ds:[avgFontWidth]	; single character width => AX
		mov	cl, 3
		shl	ax, cl			; 8 times average => AX
		sub	dx, ax		
		push	dx			; 4th column (52 x)
		sub	dx, ax
		push	dx			; 3rd column (44 x)
		shl	ax, 1
		sub	dx, ax
		push	dx			; 2nd column (26 x)
		push	si			; save the return address
		ret
SpoolPushMonikerOffsets	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTitleCallBack, SpoolEmptyCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to create a spool title moniker

CALLED BY:	SpoolCreateNonJobString
	
PASS:		DS	= Segment of strings resource
		SI	= String required (0 - 3)

RETURN:		DS:SI	= Pointer to string to use

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/09/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

spoolTitleTable	label	word
	nptr	offset documentString
	;
	; But for other stuff, we do display other titles.
	;
	nptr	offset applicationString
	nptr	offset pagesString
	nptr	offset waitingString

spoolEmptyTable	label	word
	nptr	offset noDocumentsString
	nptr	offset blankString
	nptr	offset blankString
	nptr	offset blankString


SpoolTitleCallBack	proc	near
	shl	si, 1
	mov	si, cs:[spoolTitleTable][si]
	mov	si, ds:[si]
	ret
SpoolTitleCallBack	endp


SpoolEmptyCallBack	proc	near
	shl	si, 1
	mov	si, cs:[spoolEmptyTable][si]
	mov	si, ds:[si]
	ret
SpoolEmptyCallBack	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCopyStringToMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string into the moniker structure, after determining
		the length of the string.

CALLED BY:	SpoolCreateJobStringFromID

PASS:		DS:SI	= Source string
		ES:DI	= Moniker structure
		AX	= Start of GR_DRAW_TEXT_CP field
		DX	= Left position of text
		BX	= Left position of next column

RETURN:		Nothing

DESTROYED:	AX, DX

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	04/03/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CLIP_SPACE		= 5
DRAW_TEXT_OFFSET	= (size OpSetClipRect)
ODT_string		= (size OpDrawText) + DRAW_TEXT_OFFSET

SpoolCopyStringToMoniker	proc	near
		uses	cx, bp
		.enter
		
		; Store the clip rectangle information
		;
		xchg	ax, bp
		mov	es:[di][bp].OSCR_rect.R_left, dx
		mov	es:[di][bp].OSCR_rect.R_right, bx
		sub	es:[di][bp].OSCR_rect.R_right, CLIP_SPACE

		; This is a HACK for small-screen UI. If the start of
		; this field is beyond our width, then draw nothing
		;
		push	ax, ds
		mov	ax, dgroup
		mov	ds, ax
		test	ds:[uiOptions], mask SUIO_SIMPLE ; carry is cleared
		jz	doneHack		; if not set, do nothing
		cmp	dx, SIMPLE_UI_WIDTH
		clc				; assume things are OK
		jl	doneHack
		stc				; else skip draw
doneHack:
		pop	ax, ds
		jc	spewNullOps		; if too far right, skip it!

		; Copy the string, keeping track of its length
		;
		push	di
		lea	di, es:[di][bp].ODT_string
		clr	cx			; clear count
nextChar:
		LocalGetChar ax, dssi
		LocalIsNull ax
		jz	endString
		LocalPutChar esdi, ax
		inc	cx
		jmp	nextChar

endString:
		; If empty string, use a '-'
		;
		tst	cx
		jnz	notEmpty
		LocalLoadChar	ax, '-'
		LocalPutChar	esdi, ax
		mov	cx, 1
notEmpty:

		pop	di

		; Fill in the rest of the structure
		;
		clr	es:[di][bp].DRAW_TEXT_OFFSET.ODT_y1
		mov	es:[di][bp].DRAW_TEXT_OFFSET.ODT_x1, dx
		mov	es:[di][bp].DRAW_TEXT_OFFSET.ODT_len, cx
exit:
		.leave
		ret

		; Spew GR_NULL_OP opcodes
spewNullOps:
		push	di
		mov	al, GR_NULL_OP
		mov	cx, (size OpSetClipRect) + (size OpDrawText)		
		add	di, bp
		rep	stosb
		pop	di
		jmp	exit
SpoolCopyStringToMoniker	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCopyNumberToMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a string into the moniker structure, after determining
		the length of the string.

CALLED BY:	SpoolCreateJobStringFromID

PASS:		SI	= Value
		ES:DI	= Moniker structure
		AX	= Start of GR_DRAW_TEXT_CP field
		DX	= Right position of next column
		BX	= Right position of text
		CX	= 0 - append nothing
			= other - append "min" string

RETURN:		Nothing

DESTROYED:	AX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/03/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS <NUMBER_BUFFER_SIZE	= 12					>
DBCS <NUMBER_BUFFER_SIZE	= 24					>

SpoolCopyNumberToMoniker	proc	near
		uses	cx, bp, ds
		.enter

		; Allocate a buffer on the stack, and create the string
		;
		sub	sp, NUMBER_BUFFER_SIZE
		mov	bp, sp
		push	es, di, dx, ax, cx
		mov	di, bp
		segmov	es, ss				; buffer => ES:DI
		mov	ax, si
		clr	dx				; value to DX:AX
		mov	cx, mask UHTAF_NULL_TERMINATE	; UtilHexToAsciiFlags
		call	UtilHex32ToAscii		; destroys nothing

		; Now stuff it in the moniker structure
		;
		pop	cx				; append min ??
		jcxz	copyString
		call	SpoolCopyMinutesToMoniker
copyString:
		segmov	ds, es
		mov	si, di				; string => DS:SI
		pop	es, di, dx, ax
		call	SpoolCopyStringToMoniker
		add	sp, NUMBER_BUFFER_SIZE		; clean up stack

		.leave
		ret
SpoolCopyNumberToMoniker	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCopyMinutesToMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a string with the number of minutes the job has
		been in the queue

CALLED BY:	SpoolCopyNumberToMoniker

PASS:		ES:DI	= String to hold "min"

RETURN:		Nothing

DESTROYED:	AX, CX, SI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCopyMinutesToMoniker	proc	near
		uses	di
		.enter

		; Lock the strings resource - copy the string
		;
		mov	cx, -1
		LocalClrChar ax
		LocalFindChar			; find NULL
SBCS <		mov	{char} es:[di-1], ' '	; add in a space	>
DBCS <		mov	{wchar} es:[di-2], ' '	; add in a space	>
		mov	si, offset Strings:minutesString
		call	SpoolCopyStringsString

		.leave
		ret
SpoolCopyMinutesToMoniker	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCopyPrintingToMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the printing string to a moniker

CALLED BY:	SpoolCreateJobStringFromID

PASS: 		ES:DI	= Moniker structure
		AX	= Start of GR_DRAW_TEXT_CP field
		DX	= Right position of next column
		BX	= Right position of text

RETURN:		Nothing

DESTROYED:	AX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCopyPrintingToMoniker	proc	near
		uses	cx, bp, ds
		.enter

		; Allocate a buffer on the stack, and create the string
		;
		sub	sp, NUMBER_BUFFER_SIZE
		mov	bp, sp
		push	es, di, dx, ax
		mov	di, bp
		segmov	es, ss				; buffer => ES:DI
		mov	si, offset Strings:printingString
		call	SpoolCopyStringsString

		segmov	ds, es
		mov	si, di				; string => DS:SI
		pop	es, di, dx, ax
		call	SpoolCopyStringToMoniker
		add	sp, NUMBER_BUFFER_SIZE		; clean up stack

		.leave
		ret
SpoolCopyPrintingToMoniker	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolCopyStringsString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy in a string from the Strings resource

CALLED BY:	SpoolCopyMinutesToMoniker, SpoolCreateJobStringFromID
	
PASS:		ES:DI	= Destination buffer
		SI	= Chunk handle of string

RETURN:		Nothing

DESTROYED:	AX, CX, DS, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolCopyStringsString	proc	near
		uses	bx, di
		.enter

		mov	bx, handle Strings
		call	MemLock	; Lock the Strings resource
		mov	ds, ax			; Strings segment => DS
		assume	ds:Strings
		mov	si, ds:[si]
		ChunkSizePtr	ds, si, cx
		rep	movsb			; copy the NULL-terminated str
		call	MemUnlock		; unlock the Strings resource
		assume	ds:dgroup

		.leave
		ret
SpoolCopyStringsString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolBuildJobQueueListByIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build up list of information about jobs printing or
		queued 

CALLED BY:	SpoolBuildJobQueueListForCurrentPrinter

PASS:		
		cx - element number of printer

RETURN:		
		clc - cool
		stc - error

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolBuildJobQueueListByIndex		proc	near
		uses	ax, bx, cx, dx, si, di, ds, es
		.enter

	;
	; Get the list of job IDs for the current printer
	;

		call	SpoolGetQueueInfoForPrinter
		jc	done

	;
	; Add list entries for each job id returned
	; cx hold number of jobs to add. 
	;
		call	MemLock			; lock the spool information
		mov	ds, ax
		clr	si
		mov	dx, FALSE
nextID:
		lodsw				;get job id
		call	SpoolAppendJobEntryFromID
		loop	nextID
		call	MemFree			; free the spool information

	; It is possible that one of the jobs returned by
	; SpoolGetQueueInfoForPrinter had actually been aborted and so
	; no jobs may actually be in the list. So check number of
	; jobs.
	;

		call	SpoolGetNumberOfJobs
		tst	cx			; clears carry
		jnz	done			; if some jobs, done
		stc				; else indicate error
done:
		.leave
		ret
SpoolBuildJobQueueListByIndex		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolGetQueueInfoForPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up specific queue information for the printer in question

CALLED BY:	SpoolBuildJobQueueListByIndex, SpoolInitPrinterIndex
	
PASS:		CX	= Index of printer

RETURN:		BX	= Handle of spool queue with job ID's
		CX	= Number of jobs in queue
		Carry	= Clear if queue was found

DESTROYED:	AX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolGetQueueInfoForPrinter	proc	near
		uses	di, si, ds, es
		.enter
	;
	; Get the list of print jobs for this printer / port combination
	; We want:	DX:SI	= PrintPortInfo
	;		ES:DI	= Printer name
	;
		call	SpoolGetPtrToPrinterElement
		push	bx
		jc	done			; if error, done

		CheckHack <offset BPI_nameString eq 0>
		segmov	es, ds, dx		; ES:DI = Printer name
		mov	si, di
		add	si, BPI_portInfo	; DX:SI = PrintPortInfo
		call	SpoolInfoQueueForPrinter
	;
	; Return the data, or an error indicating that there are no jobs
	;
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		stc				; assume an error
		jne	done			; if queue empty, we're done
		clc
done:
		mov_tr	ax, bx
		pop	bx
		call	MemUnlock
		mov_tr	bx, ax

		.leave
		ret
SpoolGetQueueInfoForPrinter	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolControlPanelAccessBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the PrinterControlPanelBlock, and set the segment

CALLED BY:	INTERNAL
	
PASS:		Nothing

RETURN:		DS	= Segment of PrinterControlPanelBlock
		BX	= Handle of PrinterControlPanelBlock

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/09/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolControlPanelAccessBlock	proc	near
		.enter

		; Grab the Control Panel block
		;
		mov	ax, dgroup
		mov	ds, ax
		mov	bx, ds:[printerControlPanelBlock]
EC <		tst	bx						>
EC <		ERROR_Z	SPOOL_MISSING_PANEL_BLOCK			>
		call	MemLock
		mov	ds, ax

		.leave
		ret
SpoolControlPanelAccessBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_PCP, ObjMessage_PCP_call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the PrinterControlPanel object

CALLED BY:	INTERNAL

PASS:		AX	 = Message
		CX,DX,BP = Data
		DI	 = MessageFlags (if not _call)

RETURN:		see ObjMessage

DESTROYED:	see ObjMessage

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_PCP_call	proc	near
		mov	di, mask MF_CALL
		FALL_THRU	ObjMessage_PCP
ObjMessage_PCP_call	endp

ObjMessage_PCP	proc	near
		mov	bx, handle PrinterControlPanel
		mov	si, offset PrinterControlPanel
		call	ObjMessage
		ret
ObjMessage_PCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_JL, ObjMessage_JL_call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the JobList object

CALLED BY:	INTERNAL

PASS:		AX	 = Message
		CX,DX,BP = Data
		DI	 = MessageFlags (if not _call)

RETURN:		see ObjMessage

DESTROYED:	see ObjMessage

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_JL_call	proc	near
		mov	di, mask MF_CALL
		FALL_THRU	ObjMessage_JL
ObjMessage_JL_call	endp

ObjMessage_JL	proc	near
		mov	bx, handle JobList
		mov	si, offset JobList
		call	ObjMessage
		ret
ObjMessage_JL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_near, ObjMessage_near_call
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message an object

CALLED BY:	INTERNAL

PASS:		AX	 = Message
		BX:SI	 = Object OD
		CX,DX,BP = Data

RETURN:		see ObjMessage

DESTROYED:	see ObjMessage

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_near_send	proc	near
		clr	di
		call	ObjMessage
		ret
ObjMessage_near_send	endp

ObjMessage_near_call	proc	near
		mov	di, mask MF_CALL
		call	ObjMessage
		ret
ObjMessage_near_call	endp

SpoolerApp	ends
else
SpoolerApp	segment	resource
SpoolerApp	ends
endif
