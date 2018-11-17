COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992-1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC/GEOS
MODULE:		uiGeoCalcApplication.asm
FILE:		uiGeoCalcApplication.asm

AUTHOR:		Gene Anderson, Jun  8, 1992

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEOCALC_APPLICATION_SET_TARGET_LAYER 
				Notify the app of the target layer
				(spreadsheet or graphics)

    MTD MSG_GEOCALC_APPLICATION_GET_TARGET_LAYER 
				Get the app's current target layer
				(spreadsheet or graphics)

    MTD MSG_META_GAINED_FULL_SCREEN_EXCL 
				Primarily, we use the method to enable the
				Delete trigger in the app menu in the List
				Screen of the GeoCalc.

    MTD MSG_GEN_DISPLAY_CLOSE   user exits from edit -- return to list
				screen

    INT GeoCalcInitEditControl  We want the Delete trigger is enable in the
				Edit control.

    MTD MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION 
				Handle groups becoming visible or not
				visible

    MTD MSG_GEOCALC_APPLICATION_SET_DOCUMENT_STATE 
				Set document state

    INT GeoCalcUpdateDocumentUI Update document related UI

    INT GeoCalcUpdateImportExportUI 
				Create a notification data block and send
				it to map controller.

    INT SendNotification        Sends a notification

    INT CreateColumnNamesDataBlock 
				Create a data block that will be sent to
				the GCN list.

    MTD MSG_META_NOTIFY_WITH_DATA_BLOCK 
				Handle notification from a controller

    INT GetDataRangeOrSelection Get the data range or selection, as
				appropriate

    INT GCA_ObjMessageSend      Get the data range or selection, as
				appropriate

    INT GCA_ObjMessageCall      Get the data range or selection, as
				appropriate

    MTD MSG_META_ATTACH         Handle attach for application object

    INT SendBitmapNotification  Send a notification to the bitmap tool
				control so that will be enabled

    MTD MSG_META_LOAD_OPTIONS   Handle loading options from geos.ini file

    INT SetBarState             Set the state of the show toolbars options

    MTD MSG_GEOCALC_APPLICATION_UPDATE_BARS 
				Update toolbar states

    MTD MSG_GEN_APPLICATION_UPDATE_APP_FEATURES 
				Update features for GeoCalc

    MTD MSG_GEOCALC_APPLICATION_SET_USER_LEVEL 
				Set the user level

    MTD MSG_GEOCALC_APPLICATION_CHANGE_USER_LEVEL 
				User change to the user level

    MTD MSG_GEOCALC_APPLICATION_CANCEL_USER_LEVEL 
				Cancel User change to the user level

    MTD MSG_GEOCALC_APPLICATION_QUERY_RESET_OPTIONS 
				Make sure that the user wants to reset
				options

    MTD MSG_GEOCALC_APPLICATION_USER_LEVEL_STATUS 
				Update the "Fine Tune" trigger

    MTD MSG_GEOCALC_APPLICATION_INITIATE_FINE_TUNE 
				Bring up the fine tune dialog box

    MTD MSG_GEOCALC_APPLICATION_FINE_TUNE 
				Set fine tune settings

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 8/92		Initial revision
	witt	11/11/93	DBCS-ized

DESCRIPTION:
	GeoCalc subclass of application 

	$Id: uiGeoCalcApplication.asm,v 1.1 97/04/04 15:48:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcClassStructures	segment	resource
	GeoCalcApplicationClass			;declare the class
GeoCalcClassStructures	ends

Document	segment resource


if _CHARTS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationSetTargetLayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the app of the target layer (spreadsheet or graphics)

CALLED BY:	MSG_GEOCALC_APPLICATION_SET_TARGET_LAYER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

		cl - GeoCalcTargetLayer

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationSetTargetLayer	method dynamic GeoCalcApplicationClass,
				MSG_GEOCALC_APPLICATION_SET_TARGET_LAYER

		mov	ds:[di].GAI_targetLayer, cl
if _TOOL_BAR
	;
	; Set the appropriate charting tools usable and the others not
	;
		GetResourceHandleNS MakeChartTools, bx
		mov	si, offset MakeChartTools
		mov	di, offset ChartTypeTools
		cmp	cl, GCTL_SPREADSHEET
		je	isSSheet		;branch if ssheet is target
		xchg	si, di			;grobj is target - use
						; other tool
isSSheet:
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
ifdef GPC_ONLY
		mov	ax, MSG_GEN_SET_ENABLED
else
		mov	ax, MSG_GEN_SET_USABLE
endif

		push	di
		clr	di
		call	ObjMessage
		pop	si
		
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
ifdef GPC_ONLY
		mov	ax, MSG_GEN_SET_NOT_ENABLED
else
		mov	ax, MSG_GEN_SET_NOT_USABLE
endif
		clr	di
		call	ObjMessage
endif		
		ret
GeoCalcApplicationSetTargetLayer		endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationGetTargetLayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the app's current target layer (spreadsheet or graphics)

CALLED BY:	MSG_GEOCALC_APPLICATION_GET_TARGET_LAYER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

RETURN:		cl - GeoCalcTargetLayer
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationGetTargetLayer	method dynamic GeoCalcApplicationClass,
					MSG_GEOCALC_APPLICATION_GET_TARGET_LAYER
	mov	cl, ds:[di].GAI_targetLayer
	ret
GeoCalcApplicationGetTargetLayer		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicactionGainedFullScreenExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Primarily, we use the method to enable the Delete
		trigger in the app menu in the List Screen of the
		GeoCalc.

CALLED BY:	MSG_META_GAINED_FULL_SCREEN_EXCL
PASS:		*ds:si	= GeoCalcApplicationClass object
		ds:di	= GeoCalcApplicationClass instance data
		es 	= segment of GeoCalcApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcAppFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't handle FN-F5.

CALLED BY:	MSG_META_FUP_KBD_CHAR

PASS:		*ds:si	= GeoCalcApplicationClass object
		ds:di	= GeoCalcApplicationClass instance data
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

  In reality we should have figured out why it's crashing and
  fixed it, but we don't have time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/29/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JGeoCalcPrimaryClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	user exits from edit -- return to list screen

CALLED BY:	MSG_GEN_DISPLAY_CLOSE
PASS:		*ds:si	= JGeoCalcPrimaryClass object
		ds:di	= JGeoCalcPrimaryClass instance data
		ds:bx	= JGeoCalcPrimaryClass object (same as *ds:si)
		es 	= segment of JGeoCalcPrimaryClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcInitEditControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We want the Delete trigger is enable in the Edit control.

CALLED BY:	GeoCalcOpenApplication(),
		GeoCalcApplicactionGainedFullScreenExcl()
PASS:		ds	= ptr to some lmem or obj block
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Document	ends

DocumentPrint	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationVisibilityNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle groups becoming visible or not visible

CALLED BY:	MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

		cx - GeoCalcGroupsVisible
		dx - no data (for now)
		bp - non-zero if group opending

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationVisibilityNotification method dynamic GeoCalcApplicationClass,
				MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION
	tst	bp
	jz	groupClosing
	;
	; The group is opening -- update the UI
	;
	ornf	ds:[di].GAI_visibility, cx	;set visiblity bits
	mov	ax, cx				;ax <- GeoCalcGroupsVisible
	call	GeoCalcUpdateDocumentUI
	ret

	;
	; The group is closing
	;
groupClosing:
	not	cx
	andnf	ds:[di].GAI_visibility, cx	;clear visibility bits
	ret
GeoCalcApplicationVisibilityNotification		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationSetDocumentState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set document state

CALLED BY:	MSG_GEOCALC_APPLICATION_SET_DOCUMENT_STATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

		cx:dx - ptr to GeoCalcDocumentUpdateData

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationSetDocumentState	method dynamic GeoCalcApplicationClass,
				MSG_GEOCALC_APPLICATION_SET_DOCUMENT_STATE
	mov	ax, ds:[di].GAI_visibility
	push	ds, si
	;
	; If the document state has changed...
	;
	segmov	es, ds
	add	di, offset GAI_documentState	;es:di <- ptr to dest
	movdw	dssi, cxdx			;ds:si <- ptr to source
	mov	cx, (size GeoCalcDocumentUpdateData)
	push	cx, si, di
	repe	cmpsb				;compare me jesus
	pop	cx, si, di
	jne	dataChanged

	pop	ds, si
	ret

dataChanged:
	rep	movsb				;copy me jesus
	pop	ds, si
	call	GeoCalcUpdateDocumentUI
	ret
GeoCalcApplicationSetDocumentState		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcUpdateDocumentUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update document related UI

CALLED BY:	GeoCalcApplicationSetDocumentState()
PASS:		*ds:si - GeoCalcApplication object
		ax - groups to update (GeoCalcGroupsVisible)
RETURN:		none
DESTROYED:	bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcUpdateDocumentUI		proc	near
	class	GeoCalcApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:di <- instance data
	;
	; Update Page Setup
	;
	test	ax, mask GCGV_PAGE_SETUP
	jz	afterPageSetup

	push	ax, si
	GetResourceHandleNS	GCPrintStartPage, bx
	mov	si, offset GCPrintStartPage
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	cx, ds:[di].GAI_documentState.GCDUD_pageSetup.CPSD_startPage
	clr	bp				;bp <- not indeterminate
	call	messageSend

	GetResourceHandleNS	GCSetupOptionsGroup, bx
	mov	si, offset GCSetupOptionsGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	cx, ds:[di].GAI_documentState.GCDUD_pageSetup.CPSD_flags
	clr	dx				;dx <- no indeterminates
	call	messageSend
	;
	; Tell the page setup DB there are no user changes
	;
	GetResourceHandleNS	GCPageSetup, bx
	mov	si, offset GCPageSetup
	mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
	call	messageSend
	pop	ax, si
afterPageSetup:
if _USE_IMPEX
	test	ax, mask GCGV_IMPORT		; file import DB?
	je	checkExport			; if not, skip

	; if import DB, send a notification data block to map controller 

	mov	ax, mask GCGV_IMPORT	; ax - GeoCalcGroupsVisible
	clr	cx			; cx - Column of first cell in extent
	clr	bx 			; bx - Column of last cell in extent
	call	GeoCalcUpdateImportExportUI
	jmp	afterPrint		; jump to exit	
checkExport:
	test	ax, mask GCGV_EXPORT	; file export DB?
	jne	getRange		; if so, skip
	test	ax, mask GCGV_PRINT
	jz	afterPrint
getRange:
endif
	; DO THIS FOR BOTH PRINT AND EXPORT DB
	;
	; Update the Print DB by telling the target spreadsheet to
	; send a notification block out
	;
	push	si
	mov	ax, MSG_META_UI_FORCE_CONTROLLER_UPDATE
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_SPREADSHEET_DATA_RANGE_CHANGE
	mov	bx, segment SpreadsheetClass
	mov	si, offset SpreadsheetClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si
	mov	cx, di				;cx <- recorded event handle
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_APP_TARGET		;dx <- TravelOption
	call	ObjCallInstanceNoLock		;send to ourselves

afterPrint::
	.leave
	ret

messageSend:
	push	di, bp, dx, cx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di, bp, dx, cx
	retn
GeoCalcUpdateDocumentUI		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationUpdateSplitState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update split state

CALLED BY:	MSG_GEOCALC_APPLICATION_UPDATE_SPLIT_STATE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

		cx - GeoCalcMapFlags

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/18/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _SPLIT_VIEWS
ifdef GPC
GeoCalcApplicationUpdateSplitState	method dynamic GeoCalcApplicationClass,
				MSG_GEOCALC_APPLICATION_UPDATE_SPLIT_STATE
		test	cx, mask GCMF_SPLIT
		jnz	split
	;
	; Enable freeze button, disable unfreeze button
	;
		GetResourceHandleNS	LockTrigger, bx
		mov	si, offset LockTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		GetResourceHandleNS	UnlockTrigger, bx
		mov	si, offset UnlockTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		ret

split:
	;
	; Disable freeze button, enable unfreeze button
	;
		GetResourceHandleNS	LockTrigger, bx
		mov	si, offset LockTrigger
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		GetResourceHandleNS	UnlockTrigger, bx
		mov	si, offset UnlockTrigger
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		ret
GeoCalcApplicationUpdateSplitState	endm
endif
endif

if _USE_IMPEX

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcUpdateImportExportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a notification data block and send it to map controller.

CALLED BY:	(INTERNAL) GeoCalcUpdateDocumentUI

PASS:		cx - Column of first cell in extent
		bx - Column of last cell in extent
		ax - GeoCalcGroupsVisible

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	1/14/93		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcUpdateImportExportUI	proc	near	
	uses	ax,bx,cx,dx,si,di,ds,es,bp 
	.enter

	; create a notification data block with field names

	call	CreateColumnNamesDataBlock

	; initialize the reference count to one

	mov     ax, 1
	call    MemInitRefCount         

	mov	ax, GAGCNLT_APP_TARGET_NOTIFY_APP_CHANGE
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_MAP_APP_CHANGE		; cx:dx - notificatoin type
	call	SendNotification

	.leave
	ret
GeoCalcUpdateImportExportUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a notification

CALLED BY:	GeoCalcUpdateImportExportUI, GeoCalcApplicationLoadOptions
PASS:		ax - GCNList type
		cx - ManufacturerID
		dx - notification type
		^hbx - notification block
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendNotification		proc	far
	uses	bp, si
	.enter
		
	; Create the classed event

	push	ax
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	bp, bx
	mov	di, mask MF_RECORD
	call	ObjMessage			; event handle => DI
	pop	ax

	; Setup the GCNListMessageParams

	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp				; GCNListMessageParams => SS:BP
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, cx
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, ax
	mov	ss:[bp].GCNLMP_block, bx	; bx - handle of data block
	mov	ss:[bp].GCNLMP_event, di	; di - even handle
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_STACK
	call	ObjMessage			; send it!!
	add	sp, dx				; clean up the stack

	.leave
	ret
SendNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateColumnNamesDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a data block that will be sent to the GCN list.

CALLED BY:	(INTERNAL) GeoCalcUpdateDocumentUI

PASS:		bx - ending column number
		cx - beginning column number
		ax - GeoCalcGroupsVisible

RETURN:		bx - handle of data block

DESTROYED:	ax, cx, dx, si, di, es, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	1/93		Initial version
	witt	11/93		DBCS-ized and tightend string copies

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS<	COL_NAME_BUF	equ	32				>
DBCS<	COL_NAME_BUF	equ	32*(size wchar)  		>

CreateColumnNamesDataBlock	proc	near	uses	ds 

	CLNDB_begColNum	local	word	push	cx
	CLNDB_endColNum	local	word	push	bx
	CLNDB_curColNum	local	word	push	cx
	CLNDB_buffer	local	COL_NAME_BUF	dup	(byte)
	CLNDB_dataBlock	local	hptr
	CLNDB_chunk	local	word

	.enter

	; make sure we have reasonable column numbers

EC <	cmp	cx, bx							>
EC <	ERROR_A ILLEGAL_COLUMN_NUMBER					>
EC <	cmp	bx, GEOCALC_MAX_COLUMN					>
EC <	ERROR_A ILLEGAL_COLUMN_NUMBER					>

	push	ax				;save GeoCalcGroupsVisible
	; allocate a LMem block

	mov	ax, LMEM_TYPE_GENERAL		; ax - LMemType
	mov	cx, size ImpexMapFileInfoHeader	; cx - size of header  
	call	MemAllocLMem			; allocate a data block
	mov	CLNDB_dataBlock, bx		; save memory handle

	; mark this block as a sharable block

	mov	ax, mask HF_SHARABLE or (0 shl 8)
	call	MemModifyFlags			; mark this block shareable
	call	MemLock				; lock this block

	; create a new chunk array

	mov	ds, ax

	; check to see we are doing import or export

	pop	ax				;ax <- GeoCalcGroupsVisible
	test	ax, mask GCGV_EXPORT
	jne	createChunk			; if export, skip

	; we are importing a file.  no need to create a new chunk array
	; the only information that map controller needs is IMFIH_flag

	clr	di				; ds:di - ptr to LMem header
	mov	ds:[di].IMFIH_fieldChunk, 0	; no chunk handle
	mov	ds:[di].IMFIH_numFields, 0	; no field names
	mov	ds:[di].IMFIH_flag, DFNU_COLUMN	; use "column" for default name 
	call	MemUnlock
	jmp	exit
createChunk:
	;
	; bx - variable element size
	; cx - default ChunkArrayHeader
	; si - allocate chunk, please
	;
	clr	bx, cx, si			; bx - variable element size
	clr	al				; no ObjChunkFlags passed
	call	ChunkArrayCreate		; create a chunk array

	; update the LMem header

	clr	di				; ds:di - ptr to LMem header
	mov	ds:[di].IMFIH_fieldChunk, si	; save the chunk handle
	mov	CLNDB_chunk, si			
	mov	ax, CLNDB_endColNum
	sub	ax, CLNDB_begColNum
	inc	ax
	mov	ds:[di].IMFIH_numFields, ax	; number of columns names
	mov	ds:[di].IMFIH_flag, DFNU_COLUMN	; use "column" for default name 

	; lock the resource block with the string, "Column"

	GetResourceHandleNS	StringsUI, bx	
	call	MemLock				; lock the strings block
	mov	es, ax
	mov	di, offset DefaultColumn	; *ds:si - DefaultColumn
	mov	di, es:[di]			; dereference it

	; copy "Column" into stack frame buffer

	lea	si, CLNDB_buffer		; ss:si - colum name buffer
nextChar:
	LocalGetChar ax, esdi, NO_ADVANCE	; read in a character
	LocalIsNull	ax			; end of string
	je	done				; if so, skip
	LocalPutChar sssi, ax, NO_ADVANCE	; copy it to the buffer
	LocalNextChar	esdi
	LocalNextChar	dssi			; update indices
	jmp	nextChar			; get the next character
done:
SBCS<	mov	{char}ss:[si], C_SPACE		; add a space character	>
DBCS<	mov	{wchar}ss:[si], C_SPACE		; add a space character	>
	LocalNextChar	dssi
	call	MemUnlock			; unlock StringsUI block

	; now convert the hex column number to column letters
	; i.e. convert "4" to "E"
mainLoop:
	push	si				; save the offset 
	mov	di, si
	segmov	es, ss				; es:di - ptr to buffer
	mov	cx, COL_NAME_BUF		; cx - size of buffer
	mov	ax, CLNDB_curColNum		; ax - number to convert
	call	ParserFormatColumnReference	; conver the number

	; count the number of bytes in CLNDB_buffer

	lea	di, CLNDB_buffer
	segmov	es, ss
	call	LocalStringSize			; cx <- size w/o NULL
	LocalNextChar escx			; cx <- size w/ NULL

	; copy this string to chunk array

	mov	si, CLNDB_chunk			; ds:si - chunk array
	mov	ax, cx				; ax - element size
	call	ChunkArrayAppend		; add a new element
	segmov	es, ds				; es:di - destination

	push	ds
	lea	si, CLNDB_buffer		
	segmov	ds, ss				; ds:si - source string
	rep	movsb				; copy the bytes
	pop	ds

	; check to see if we are done

	inc	CLNDB_curColNum
	mov	ax, CLNDB_curColNum
	cmp	ax, CLNDB_endColNum		; are we done?
	pop	si
	jle	mainLoop			; if not, continue

	; unlock the data block

	mov	bx, CLNDB_dataBlock
	call	MemUnlock
exit:
	.leave
	ret
CreateColumnNamesDataBlock	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle notification from a controller

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

		cx:dx - NotificationType
			cx - NT_manuf (MANUFACTURER_ID_GEOWORKS)
			dx - NT_type (GWNT_SPREADSHEET_DATA_RANGE_CHANGE)
		^hbp - SHARABLE data block having a "reference count" 
				NotifySSheetDataRangeChange

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationNotifyWithDataBlock	method dynamic GeoCalcApplicationClass,
						MSG_META_NOTIFY_WITH_DATA_BLOCK
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	LONG jne	sendToSuper
	cmp	dx, GWNT_SPREADSHEET_DATA_RANGE_CHANGE
	LONG jne	sendToSuper
	tst	bp				;empty notification?
	LONG jz		sendToSuper		;send to superclass
	push	ax, bp, cx, dx, si, es
	;
	; Get data range or selection as appropriate
	;
if _USE_IMPEX
	mov	ax, ds:[di].GAI_visibility	;ax <- GeoCalcGroupsVisible
	test	ax, mask GCGV_EXPORT
	jz	afterExportDB			;branch if export not up
	call	GetDataRangeOrSelection
	jz	afterExportDB			;branch if no data range
	mov	ax, ds:[di].GAI_visibility	;ax <- GeoCalcGroupsVisible
	call	GeoCalcUpdateImportExportUI
afterExportDB:
endif
	;
	; We forcibly exclude GCGV_EXPORT so that GetDataRangeOrSelection()
	; will do the right thing w.r.t. data vs. selected range
	;
	mov	ax, ds:[di].GAI_visibility	;ax <- GeoCalcGroupsVisible
	andnf	ax, not (mask GCGV_EXPORT)
	test	ax, mask GCGV_PRINT
	jz	afterPrintDB			;branch if print not up
	call	GetDataRangeOrSelection
	;
	; Make a buffer, and format the range into it
	;
	sub	sp, MAX_RANGE_REF_SIZE
	mov	di, sp
	segmov	es, ss
	call	ParserFormatRangeReference	;cx <- length w/out NULL
	;
	; Set the text to the range
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bp, di
	mov	dx, ss				;dx:bp <- ptr to text
	GetResourceHandleNS GCPrintRange, bx
	mov	si, offset GCPrintRange
	mov	di, mask MF_CALL
	call	ObjMessage
	add	sp, MAX_RANGE_REF_SIZE
	;
	; Send on to our superclass for eventual destruction
	;
afterPrintDB::
	pop	ax, bp, cx, dx, si, es
sendToSuper:
	mov	di, offset GeoCalcApplicationClass
	call	ObjCallSuperNoLock
	ret
GeoCalcApplicationNotifyWithDataBlock		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDataRangeOrSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the data range or selection, as appropriate

CALLED BY:	GeoCalcApplicationNotifyWithDataBlock()
PASS:		ax - GeoCalcGroupsVisible
		bp - handle of notification
RETURN:		(ax,cx),(dx,bx) - data range or selection
		z flag - set (jz) if no data
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDataRangeOrSelection		proc	near
	uses	bp, ds
	.enter

	mov	dx, ax				;dx <- GeoCalcGroupsVisible
	;
	; Lock the notification block
	;
	mov	bx, bp				;bx <- handle of notification
	call	MemLock
	mov	ds, ax				;ds <- seg addr of notification
	;
	; If this is for export, always use the data range
	;
	test	dx, mask GCGV_EXPORT
	jnz	useData
	;
	; Any selection?  If so, use it for the range
	;
	mov	ax, ds:NSSDRC_selection.CR_start.CR_row
	cmp	ax, ds:NSSDRC_selection.CR_end.CR_row
	jne	useSelection
	mov	ax, ds:NSSDRC_selection.CR_start.CR_column
	cmp	ax, ds:NSSDRC_selection.CR_end.CR_column
	je	useData
	;
	; Use the selection range
	;
useSelection:
	mov	ax, ds:NSSDRC_selection.CR_start.CR_row
	mov	cx, ds:NSSDRC_selection.CR_start.CR_column
	mov	dx, ds:NSSDRC_selection.CR_end.CR_row
	mov	bp, ds:NSSDRC_selection.CR_end.CR_column
	jmp	gotRange

	;
	; Use the data range
	;
useData:
	;
	; Any data?  If not, use the selection.
	;
	mov	ax, ds:NSSDRC_range.CR_start.CR_row
	cmp	ax, -1				;any data range?
	je	useSelection
	mov	cx, ds:NSSDRC_range.CR_start.CR_column
	mov	dx, ds:NSSDRC_range.CR_end.CR_row
	mov	bp, ds:NSSDRC_range.CR_end.CR_column
gotRange:
	cmp	ds:NSSDRC_range.CR_start.CR_row, -1 ;set z flag for no data
	call	MemUnlock			;done with notification
	mov	bx, bp				;bx <- end column

	.leave
	ret
GetDataRangeOrSelection		endp

DocumentPrint	ends

InitCode segment resource

GCA_ObjMessageSend		proc	near
	uses	di
	.enter

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GCA_ObjMessageSend		endp

GCA_ObjMessageCall	proc	near
	uses	di
	.enter

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
GCA_ObjMessageCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle attach for application object

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationAttach		method dynamic GeoCalcApplicationClass,
						MSG_META_ATTACH
	push	ax, cx, dx, si, bp

	;
	; force the edit menu to be built (so that the added UI can
	; correctly produce its tools), if it hasn't already been built.
	;
	mov	ax, GCAC_UI_ALREADY_BUILT
	call	ObjVarFindData
	jc	alreadyBuiltUI

	;
	; Set a flag indicating that we've built the UI.
	;
	mov	cx, 1				; add just a byte
	call	ObjVarAddData

	push	si
	GetResourceHandleNS	GCEditControl, bx
	mov	si, offset GCEditControl
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	GCA_ObjMessageSend
	pop	si

alreadyBuiltUI:
	;
	; Set things that are solely dependent on the interface level
	;
	call	UserGetInterfaceOptions
	test	ax, mask UIIO_OPTIONS_MENU
	jnz	keepOptionsMenu

	push	si
	GetResourceHandleNS OptionsMenu, bx
	mov	si, offset OptionsMenu
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	GCA_ObjMessageSend
	pop	si
keepOptionsMenu::

	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	keepUserLevel
	push	si
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	GCA_ObjMessageSend
	pop	si
ifdef GPC_ONLY
	;
	; CUI: set view mode to 150%
	;
if _VIEW_CTRL
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = GenInstance
	test	ds:[di].GAI_attachFlags, mask AAF_RESTORING_FROM_STATE
	jnz	noView
	push	si
	GetResourceHandleNS	GCViewControl, bx
	mov	si, offset GCViewControl
	mov	ax, MSG_GVC_SET_SCALE
	mov	dx, 150
	call	GCA_ObjMessageSend
	pop	si
noView:
endif
endif
keepUserLevel:

	;
	; and also change the .ini file category based on interfaceLevel.
	;
	mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
	mov	cx, 9				;'geocalc0' + NULL
	call	ObjVarAddData
	mov	{word}ds:[bx+0], 'ge'
	mov	{word}ds:[bx+2], 'oc'
	mov	{word}ds:[bx+4], 'al'
	mov	{word}ds:[bx+6], 'c'		;'geocalc' + NULL
	
	call	UserGetDefaultUILevel		;ax = UIInterfaceLevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	categorySet
	mov	{word}ds:[bx+7], '0'		;'geocalc0' + NULL
categorySet:

if _CHARTS
	; send a null notification to the GrObjBitmapToolControl so that
	; can be enabled even before GrObjTools are shown.

	call	SendBitmapNotification
endif
	;
	; Send on to our superclass
	;
	pop	ax, cx, dx, si, bp
	mov	di, offset GeoCalcApplicationClass
	GOTO	ObjCallSuperNoLock
GeoCalcApplicationAttach		endm

if _CHARTS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendBitmapNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a notification to the bitmap tool control so that
		will be enabled

CALLED BY:	GeoCalcApplicationLoadOptions()
PASS:		none
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/19/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendBitmapNotification		proc	near
	uses	si, es
	.enter
		
	mov	ax, size VisBitmapNotifyCurrentTool
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax

	movdw	es:[VBNCT_toolClass], -1
	call	MemUnlock
	mov	ax, 1
	call	MemInitRefCount

	mov	ax, GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_TOOL_CHANGE
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_BITMAP_CURRENT_TOOL_CHANGE
	call	SendNotification

	.leave
	ret
SendBitmapNotification		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle loading options from geos.ini file

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SettingTableEntry	struct
    STE_showBars	GeoCalcToolbarStates
    STE_features	GeoCalcFeatures
SettingTableEntry	ends

settingsTable	SettingTableEntry	\
 <INTRODUCTORY_BAR_STATES, INTRODUCTORY_FEATURES>,
 <BEGINNING_BAR_STATES, BEGINNING_FEATURES>,
 <INTERMEDIATE_BAR_STATES, INTERMEDIATE_FEATURES>,
 <ADVANCED_BAR_STATES, ADVANCED_FEATURES>

featuresKey	char	"features", 0

GeoCalcApplicationLoadOptions		method dynamic GeoCalcApplicationClass,
						MSG_META_LOAD_OPTIONS,
						MSG_META_RESET_OPTIONS
	mov	di, offset GeoCalcApplicationClass
	call	ObjCallSuperNoLock

	; if no features settings are stored then use
	; defaults based on the system's user level

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	movdw	cxdx, sssp

	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock
	mov	ax, sp
	push	si, ds
	segmov	ds, ss
	mov_tr	si, ax
	mov	cx, cs
	mov	dx, offset featuresKey
	call	InitFileReadInteger
	pop	si, ds
	mov	bp, sp
	lea	sp, ss:[bp+INI_CATEGORY_BUFFER_SIZE]
	jnc	done

	;
	; no geos.ini file settings -- set objects based on level
	;
	call	UserGetDefaultLaunchLevel	;ax <- user level (0-3)
	mov	bl, (size SettingTableEntry)
	mul	bl
	mov_tr	di, ax				;di <- table offset

	GetResourceHandleNS UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	GCA_ObjMessageCall		;ax <- selection

	mov	cx, cs:settingsTable[di].STE_features
	cmp	ax, cx
	je	afterSetUserLevel
	;
	; The user level is different -- update the list
	;
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				;dx <- no indeterminates
	call	GCA_ObjMessageSend
	mov	cx, 1				;cx <- mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	GCA_ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	GCA_ObjMessageSend
afterSetUserLevel:

if _TOOL_BAR
	mov	cx, cs:settingsTable[di].STE_showBars
	call	SetBarState

endif

done:
	ret
GeoCalcApplicationLoadOptions		endm



if _TOOL_BAR
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBarState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the state of the show toolbars options

CALLED BY:	GeoCalcApplicationLoadOptions()
PASS:		cx - new state (GeoCalcToolbarStates)
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBarState		proc	near
	.enter

	push	cx
	GetResourceHandleNS	ShowBarList, bx
	mov	si, offset ShowBarList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	GCA_ObjMessageCall		;ax <- bits set
	pop	cx

	xor	ax, cx				;ax <- bits changed
	jz	done
	;
	; The toolbars are different -- update the list
	;
	push	ax
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx				;dx <- no indeterminates
	call	GCA_ObjMessageSend
	pop	cx				;cx <- bits changed
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	GCA_ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	GCA_ObjMessageSend
done:
	.leave
	ret
SetBarState		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationUpdateBars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update toolbar states

CALLED BY:	MSG_GEOCALC_APPLICATION_UPDATE_BARS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

		cx - currently selected Booleans
		bp - modified Booleans

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationUpdateBars	method dynamic GeoCalcApplicationClass,
					MSG_GEOCALC_APPLICATION_UPDATE_BARS

	;
	; Save new toolbar state
	;
	mov	ds:[di].GAI_toolbarStates, cx
	mov_tr	ax, cx
	;
	; For each toolbar, update its state
	;
	test	bp, mask GCTS_SHOW_STYLE_BAR
	jz	noStyleBarChange
	GetResourceHandleNS GCStyleBar, bx
	mov	di, offset GCStyleBar
	test	ax, mask GCTS_SHOW_STYLE_BAR
	call	updateToolbarState
noStyleBarChange:
	test	bp, mask GCTS_SHOW_FUNCTION_BAR
	jz	noFunctionBarChange
	GetResourceHandleNS GCFunctionBar, bx
	mov	di, offset GCFunctionBar
	test	ax, mask GCTS_SHOW_FUNCTION_BAR
	call	updateToolbarState
noFunctionBarChange:
	test	bp, mask GCTS_SHOW_GRAPHICS_BAR
	jz	noGraphicsBarChange
	GetResourceHandleNS GCGraphicsBar, bx
	mov	di, offset GCGraphicsBar
	test	ax, mask GCTS_SHOW_GRAPHICS_BAR
	call	updateToolbarState
noGraphicsBarChange:
if _CHARTS
	test	bp, mask GCTS_SHOW_DRAWING_TOOLS
	jz	noDrawingToolsBarChange
	GetResourceHandleNS GCDrawingToolsBar, bx
	mov	di, offset GCDrawingToolsBar
	test	ax, mask GCTS_SHOW_DRAWING_TOOLS
	call	updateToolbarState
noDrawingToolsBarChange:
if _BITMAP_EDITING
	test	bp, mask GCTS_SHOW_BITMAP_TOOLS
	jz	noBitmapToolsBarChange
	GetResourceHandleNS GCBitmapToolsBar, bx
	mov	di, offset GCBitmapToolsBar
	test	ax, mask GCTS_SHOW_BITMAP_TOOLS
	call	updateToolbarState
noBitmapToolsBarChange:
endif
endif

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	test	ds:[si].GAI_states, mask AS_ATTACHING
	jnz	exit			; no change when attaching
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	UserCallApplication
	pop	ax, cx, dx, bp
exit:

	ret

	;
	; Pass:
	;	*ds:si - application object
	;	^lbx:di - toolbar
	;	z flag - clear (jnz) for usable
	; Destroy:
	;	di
	;
updateToolbarState:
	push	ax, si
	mov	ax, MSG_GEN_SET_USABLE
	jnz	gotMessage
	mov	ax, MSG_GEN_SET_NOT_USABLE
gotMessage:
	;
	; If we are not attaching, delay the update
	;
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	dl, VUM_NOW
	test	ds:[si].GAI_states, mask AS_ATTACHING
	jnz	gotMode
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
gotMode:
	mov	si, di				;^lbx:si <- OD of toolbar
	mov	di, mask MF_FIXUP_DS		;di <- MessageFlags
	call	ObjMessage
	pop	ax, si

	retn
GeoCalcApplicationUpdateBars		endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationUpdateAppFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update features for GeoCalc

CALLED BY:	MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

		ss:bp - GenAppUpdateFeaturesParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FULL_EXECUTE_IN_PLACE
UsabilityTableXIP	segment	lmem	LMEM_TYPE_GENERAL
endif

;
; This table has an entry corresponding to each feature bit in the
; GeoCalcFeatures record.  The entry is a pointer to the list of
; objects to turn on/off for that feature.
;
if _CHARTS

usabilityTable	fptr \
		chartingList,			;GCF_CHARTING
		simpleOptionsList,		;GCF_SIMPLE_OPTIONS
		clearList,			;GCF_CLEAR
		pageSetupList,			;GCF_PAGE_SETUP
		namesList,			;GCF_NAMES
		notesList,			;GCF_NOTES
		advancedSpreadsheetList,	;GCF_ADVANCED_SSHEET
		simpleCellAttributesList,	;GCF_SIMPLE_CELL_ATTRIBUTES
		complexCellAttributesList,	;GCF_COMPLEX_CELL_ATTRIBUTES
		searchList,			;GCF_SEARCH
		graphicsList,			;GCF_GRAPHICS
		complexGraphicsList		;GCF_COMPLEX_GRAPHICS
else

if _TEXT_OPTS
usabilityTable	fptr \
		simpleOptionsList,		;GCF_SIMPLE_OPTIONS
		clearList,			;GCF_CLEAR
		pageSetupList,			;GCF_PAGE_SETUP
		namesList,			;GCF_NAMES
		notesList,			;GCF_NOTES
		advancedSpreadsheetList,	;GCF_ADVANCED_SSHEET
		simpleCellAttributesList,	;GCF_SIMPLE_CELL_ATTRIBUTES
		complexCellAttributesList,	;GCF_COMPLEX_CELL_ATTRIBUTES
		searchList,			;GCF_SEARCH
		graphicsList,			;GCF_GRAPHICS
		complexGraphicsList		;GCF_COMPLEX_GRAPHICS
else
usabilityTable	fptr \
		simpleOptionsList,		;GCF_SIMPLE_OPTIONS
		clearList,			;GCF_CLEAR
		pageSetupList,			;GCF_PAGE_SETUP
		namesList,			;GCF_NAMES
		notesList,			;GCF_NOTES
		advancedSpreadsheetList,	;GCF_ADVANCED_SSHEET
		simpleCellAttributesList,	;GCF_SIMPLE_CELL_ATTRIBUTES
		complexCellAttributesList,	;GCF_COMPLEX_CELL_ATTRIBUTES
		searchList,			;GCF_SEARCH
		graphicsList			;GCF_GRAPHICS
endif

endif

if _CHARTS

if _TOOL_BAR
chartingList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ChartMenu
	GenAppMakeUsabilityTuple MakeChartTools, end
else
chartingList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ChartMenu, end
endif

endif		; if _TOOL_BAR

if _TOOL_BAR
simpleOptionsList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowToolsPopup
	GenAppMakeUsabilityTuple RulerSubMenu
	GenAppMakeUsabilityTuple GCRulerShowControl
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
else

simpleOptionsList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RulerSubMenu
	GenAppMakeUsabilityTuple GCRulerShowControl
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end

endif		; if _TOOL_BAR

clearList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSSEditControl, recalc, end

if _HEADER_FOOTER
pageSetupList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc
	GenAppMakeUsabilityTuple GCOptionsFoo, popup
	GenAppMakeUsabilityTuple GCHeaderFooterControl
	GenAppMakeUsabilityTuple GCPageSetup, end

else
pageSetupList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc
	GenAppMakeUsabilityTuple GCOptionsFoo, popup
	GenAppMakeUsabilityTuple GCPageSetup, end
endif		; if _HEADER_FOOTER

namesList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCDefineNameControl
	GenAppMakeUsabilityTuple GCChooseNameControl, end

if _CELL_NOTE
notesList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc
	GenAppMakeUsabilityTuple GCNoteControl, end
else
notesList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
endif		; if _CELL_NOTE

if _TOOL_BAR
advancedSpreadsheetList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCToolControl
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc
	GenAppMakeUsabilityTuple GCSortControl
	GenAppMakeUsabilityTuple GCRowHeightControl
	GenAppMakeUsabilityTuple GCRecalcControl, end
else
advancedSpreadsheetList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc
	GenAppMakeUsabilityTuple GCSortControl
	GenAppMakeUsabilityTuple GCRowHeightControl
	GenAppMakeUsabilityTuple GCRecalcControl, end
endif		; if _TOOL_BAR

if _PT_SIZE

if _TEXT_OPTS
simpleCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCTextStyleControl, recalc
	GenAppMakeUsabilityTuple GCTextFontControl
	GenAppMakeUsabilityTuple GCTextSizeControl
	GenAppMakeUsabilityTuple GCTextStyleControl, popup
	GenAppMakeUsabilityTuple GCTextJustificationControl, popup
	GenAppMakeUsabilityTuple GCTextFGColorControl
	GenAppMakeUsabilityTuple TextStyleTools
	GenAppMakeUsabilityTuple TextFontTools
	GenAppMakeUsabilityTuple TextSizeTools
	GenAppMakeUsabilityTuple TextJustificationTools
	GenAppMakeUsabilityTuple TextColorTools, end

if _BORDER_C
complexCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCColumnWidthControl, recalc
	GenAppMakeUsabilityTuple GCTextStyleControl, recalc
	GenAppMakeUsabilityTuple GCTextFontControl, recalc
	GenAppMakeUsabilityTuple GCTextSizeControl, recalc
	GenAppMakeUsabilityTuple GCSSBorderControl
	GenAppMakeUsabilityTuple GCSSBorderAttrInteraction
	GenAppMakeUsabilityTuple GCTextFGColorControl, recalc
	GenAppMakeUsabilityTuple GCTextBGColorControl, end
else
complexCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCColumnWidthControl, recalc
	GenAppMakeUsabilityTuple GCTextStyleControl, recalc
	GenAppMakeUsabilityTuple GCTextFontControl, recalc
	GenAppMakeUsabilityTuple GCTextSizeControl, recalc
	GenAppMakeUsabilityTuple GCSSBorderControl
	GenAppMakeUsabilityTuple GCTextFGColorControl, recalc
	GenAppMakeUsabilityTuple GCTextBGColorControl, end
endif		; _BORDER_C

else

;simpleCellAttributesList	label	GenAppUsabilityTuple
;	GenAppMakeUsabilityTuple GCTextSizeControl
;	GenAppMakeUsabilityTuple GCTextJustificationControl, popup
;	GenAppMakeUsabilityTuple TextSizeTools
;	GenAppMakeUsabilityTuple TextJustificationTools, end

if _BRODER_C
complexCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCColumnWidthControl, recalc
	GenAppMakeUsabilityTuple GCTextSizeControl, recalc
	GenAppMakeUsabilityTuple GCSSBorderControl
	GenAppMakeUsabilityTuple GCSSBorderAttrInteraction, end
else
complexCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCColumnWidthControl, recalc
	GenAppMakeUsabilityTuple GCTextSizeControl, recalc
	GenAppMakeUsabilityTuple GCSSBorderControl, end
endif		; _BORDER_C

endif		; _TEXT_OPTS

else

if _TEXT_OPTS
simpleCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCTextStyleControl, recalc
	GenAppMakeUsabilityTuple GCTextFontControl
	GenAppMakeUsabilityTuple GCTextStyleControl, popup
	GenAppMakeUsabilityTuple GCTextJustificationControl, popup
	GenAppMakeUsabilityTuple GCTextFGColorControl
	GenAppMakeUsabilityTuple TextStyleTools
	GenAppMakeUsabilityTuple TextFontTools
	GenAppMakeUsabilityTuple TextJustificationTools
	GenAppMakeUsabilityTuple TextColorTools, end

if _BORDER_C
complexCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCColumnWidthControl, recalc
	GenAppMakeUsabilityTuple GCTextStyleControl, recalc
	GenAppMakeUsabilityTuple GCTextFontControl, recalc
	GenAppMakeUsabilityTuple GCSSBorderControl
	GenAppMakeUsabilityTuple GCSSBorderAttrInteraction
	GenAppMakeUsabilityTuple GCTextFGColorControl, recalc
	GenAppMakeUsabilityTuple GCTextBGColorControl, end
else
complexCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCColumnWidthControl, recalc
	GenAppMakeUsabilityTuple GCTextStyleControl, recalc
	GenAppMakeUsabilityTuple GCTextFontControl, recalc
	GenAppMakeUsabilityTuple GCSSBorderControl
	GenAppMakeUsabilityTuple GCTextFGColorControl, recalc
	GenAppMakeUsabilityTuple GCTextBGColorControl, end
endif		; if _BORDER_C

else

;simpleCellAttributesList	label	GenAppUsabilityTuple
;	GenAppMakeUsabilityTuple GCTextJustificationControl, popup, end

if _BORDER_C
complexCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCColumnWidthControl, recalc
	GenAppMakeUsabilityTuple GCSSBorderControl
	GenAppMakeUsabilityTuple GCSSBorderAttrInteraction, end
else

complexCellAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCColumnWidthControl, recalc
	GenAppMakeUsabilityTuple GCSSBorderControl, end

endif		; if _BORDER_C

endif		; if _TEXT_OPTS

endif


searchList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSearchControl, end



if _CHARTS

if _TOOL_BAR
graphicsList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RulerSubMenu, popup
	GenAppMakeUsabilityTuple GCRulerTypeControl
	GenAppMakeUsabilityTuple ShowGraphicBarEntry, toolbar
	GenAppMakeUsabilityTuple ShowDrawingToolsEntry, toolbar
ifndef GPC_ONLY
	GenAppMakeUsabilityTuple ShowBitmapToolsEntry, toolbar
endif
	GenAppMakeUsabilityTuple GCGrObjToolControl, restart
	GenAppMakeUsabilityTuple GraphicsMenu, end
else
graphicsList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RulerSubMenu, popup
	GenAppMakeUsabilityTuple GCRulerTypeControl
	GenAppMakeUsabilityTuple GCGrObjToolControl, restart
	GenAppMakeUsabilityTuple GraphicsMenu, end
endif		; if _TOOL_BAR

else

graphicsList			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RulerSubMenu, popup
	GenAppMakeUsabilityTuple GCRulerTypeControl, end

endif		; if _CHARTS


if _CHARTS

if _TEXT_OPTS
complexGraphicsList	label	GenAppUsabilityTuple
; removed for Wizard
;	GenAppMakeUsabilityTuple GCGrObjObscureAttrControl
	GenAppMakeUsabilityTuple GCFontAttrControl
	GenAppMakeUsabilityTuple ParagraphMenu
	GenAppMakeUsabilityTuple GCGrObjToolControl, recalc
	GenAppMakeUsabilityTuple GradientDialog
	GenAppMakeUsabilityTuple GCGrObjStyleSheetControl
	GenAppMakeUsabilityTuple PolylinePopup
	GenAppMakeUsabilityTuple GrOptionsPopup
	GenAppMakeUsabilityTuple GCTransformControl
	GenAppMakeUsabilityTuple GCArcControl
	GenAppMakeUsabilityTuple PasteInsidePopup
	GenAppMakeUsabilityTuple GCHideShowControl
	GenAppMakeUsabilityTuple GCCustomDuplicateControl
	GenAppMakeUsabilityTuple AttributesPopup
	GenAppMakeUsabilityTuple GCSkewControl
	GenAppMakeUsabilityTuple GCConvertControl
	GenAppMakeUsabilityTuple GCHandleControl
	GenAppMakeUsabilityTuple GCInstructionPopup, end

else
complexGraphicsList	label	GenAppUsabilityTuple
; removed for Wizard
;	GenAppMakeUsabilityTuple GCGrObjObscureAttrControl
	GenAppMakeUsabilityTuple GCGrObjToolControl, recalc
	GenAppMakeUsabilityTuple GradientDialog
	GenAppMakeUsabilityTuple GCGrObjStyleSheetControl
	GenAppMakeUsabilityTuple PolylinePopup
	GenAppMakeUsabilityTuple GrOptionsPopup
	GenAppMakeUsabilityTuple GCTransformControl
	GenAppMakeUsabilityTuple GCArcControl
	GenAppMakeUsabilityTuple PasteInsidePopup
	GenAppMakeUsabilityTuple GCHideShowControl
	GenAppMakeUsabilityTuple GCCustomDuplicateControl
	GenAppMakeUsabilityTuple AttributesPopup
	GenAppMakeUsabilityTuple GCSkewControl
	GenAppMakeUsabilityTuple GCConvertControl
	GenAppMakeUsabilityTuple GCHandleControl
	GenAppMakeUsabilityTuple GCInstructionPopup, end
endif

else

if _TEXT_OPTS
complexGraphicsList	label	GenAppUsabilityTuple
; removed for Wizard
;	GenAppMakeUsabilityTuple GCGrObjObscureAttrControl
	GenAppMakeUsabilityTuple GCFontAttrControl
	GenAppMakeUsabilityTuple ParagraphMenu, end
endif

endif


if _CHARTS

if _VIEW_CTRL

if _WIN_MENU
levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCViewControl, recalc
	GenAppMakeUsabilityTuple GCGrObjToolControl, recalc
	GenAppMakeUsabilityTuple GCSearchControl, recalc
	GenAppMakeUsabilityTuple GCDisplayControl, recalc
	GenAppMakeUsabilityTuple GCDocumentControl, recalc
	GenAppMakeUsabilityTuple GCFloatFormatControl, recalc
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
else
levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCViewControl, recalc
	GenAppMakeUsabilityTuple GCGrObjToolControl, recalc
	GenAppMakeUsabilityTuple GCSearchControl, recalc
	GenAppMakeUsabilityTuple GCDocumentControl, recalc
	GenAppMakeUsabilityTuple GCFloatFormatControl, recalc
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
endif

else

if _WIN_MENU
levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCGrObjToolControl, recalc
	GenAppMakeUsabilityTuple GCSearchControl, recalc
	GenAppMakeUsabilityTuple GCDisplayControl, recalc
	GenAppMakeUsabilityTuple GCDocumentControl, recalc
	GenAppMakeUsabilityTuple GCFloatFormatControl, recalc
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
else
levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCGrObjToolControl, recalc
	GenAppMakeUsabilityTuple GCSearchControl, recalc
	GenAppMakeUsabilityTuple GCDocumentControl, recalc
	GenAppMakeUsabilityTuple GCFloatFormatControl, recalc
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
endif

endif

else

if _VIEW_CTRL

if _WIN_MENU
levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCViewControl, recalc
	GenAppMakeUsabilityTuple GCSearchControl, recalc
	GenAppMakeUsabilityTuple GCDisplayControl, recalc
	GenAppMakeUsabilityTuple GCDocumentControl, recalc
	GenAppMakeUsabilityTuple GCFloatFormatControl, recalc
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
else
levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCViewControl, recalc
	GenAppMakeUsabilityTuple GCSearchControl, recalc
	GenAppMakeUsabilityTuple GCDocumentControl, recalc
	GenAppMakeUsabilityTuple GCFloatFormatControl, recalc
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
endif

else

if _WIN_MENU
levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSearchControl, recalc
	GenAppMakeUsabilityTuple GCDisplayControl, recalc
	GenAppMakeUsabilityTuple GCDocumentControl, recalc
	GenAppMakeUsabilityTuple GCFloatFormatControl, recalc
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
else
levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GCSearchControl, recalc
	GenAppMakeUsabilityTuple GCDocumentControl, recalc
	GenAppMakeUsabilityTuple GCFloatFormatControl, recalc
	GenAppMakeUsabilityTuple GCSSOptionsControl, recalc, end
endif	; if _WIN_MENU

endif

endif

if FULL_EXECUTE_IN_PLACE
UsabilityTableXIP	ends
endif
GeoCalcApplicationUpdateAppFeatures	method dynamic GeoCalcApplicationClass,
					MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
if FULL_EXECUTE_IN_PLACE
	;
	; Call General Tsuo -- um -- general routine to update usability
	;
	mov	bx, handle UsabilityTableXIP	;bx = table block handle
	call	MemLock				;ax = block seg
	mov	ss:[bp].GAUFP_table.segment, ax
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable
	mov	ss:[bp].GAUFP_levelTable.segment, ax
	mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable

	mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	call	ObjCallInstanceNoLock
	mov	bx, handle UsabilityTableXIP	;unlock the block
	call	MemUnlock
	ret
else
	;
	; Call General Tsuo -- um -- general routine to update usability
	;
	mov	ss:[bp].GAUFP_table.segment, cs
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable

	mov	ss:[bp].GAUFP_levelTable.segment, cs
	mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable

	mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	GOTO	ObjCallInstanceNoLock
endif
GeoCalcApplicationUpdateAppFeatures		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationSetUserLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the user level

CALLED BY:	MSG_GEOCALC_APPLICATION_SET_USER_LEVEL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message

		cx - user level

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationSetUserLevel		method dynamic GeoCalcApplicationClass,
					MSG_GEOCALC_APPLICATION_SET_USER_LEVEL
	mov	ax, cx				;ax <- new features
	;
	; find the corresponding bar states and level
	;
	push	si
	clr	di, bp
	mov	cx, (length settingsTable)	;cx <- # entries
	mov	dl, UIIL_INTRODUCTORY		;dl <- UIInterfaceLevel
	mov	dh, dl				;dh <- nearest so far (level)
	mov	si, 16				;si <- nearest so far (# bits)
findLoop:
	cmp	ax, cs:settingsTable[di].STE_features
	je	found
	push	ax, cx
	;
	; See how closely the features match what we're looking for
	;
	mov	bx, ax
	xor	bx, cs:settingsTable[di].STE_features
	clr	ax				;no bits on
	mov	cx, 16
countBits:
	ror	bx, 1
	jnc	nextBit				;bit on?
	inc	ax				;ax <- more bit
nextBit:
	loop	countBits

	cmp	ax, si				;fewer differences?

	ja	nextEntry			;branch if not fewer difference
	;
	; In the event we don't find a match, use the closest
	;
	mov	si, ax				;si <- nearest so far (# bits)
	mov	dh, dl				;dh <- nearest so far (level)
	mov	bp, di				;bp <- corresponding entry
nextEntry:
	pop	ax, cx
	inc	dl				;dl <- next UIInterfaceLevel
	add	di, (size SettingTableEntry)
	loop	findLoop
	;
	; No exact match -- set the level to the closest
	;
	mov	dl, dh				;dl <- nearest level
	mov	di, bp				;di <- corresponding entry
	stc					;carry set = no exact match
	;
	; Set the app features and level
	;
found:
	pop	si

	pushf					;carry set = no exact match
	clr	dh				;dx <- UIInterfaceLevel
	push	dx
	mov	cx, ax				;cx <- features to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_FEATURES
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- UIInterfaceLevel to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_LEVEL
	call	ObjCallInstanceNoLock
	popf					;carry set = no exact match
	jc	done				;don't set bar state if no
						; exact match
if _TOOL_BAR
	mov	cx, cs:settingsTable[di].STE_showBars
	call	SetBarState
endif

	;
	; hack to fix 'R' mnemonic for 'Show Rulers' on user level 2
	;
	GetResourceHandleNS	RulerSubMenu, bx
	mov	si, offset RulerSubMenu
	mov	ax, MSG_GEN_INTERACTION_GET_VISIBILITY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; cl = GIV
	cmp	cl, GIV_POPUP
	mov	cx, offset RulerSubMenuPopupMoniker
	je	haveMoniker
	mov	cx, 0				; no moniker for subgroup
haveMoniker:
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

done:
ifdef GPC_ONLY
	;
	; if not attaching, save after user level change
	;
	mov	si, offset GCAppObj
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	exit
	mov	ax, MSG_META_SAVE_OPTIONS
	call	UserCallApplication
exit:
endif

	ret
GeoCalcApplicationSetUserLevel		endm

GeoCalcApplicationSetTemplateUserLevel	method	dynamic	GeoCalcApplicationClass,
				MSG_GEN_APPLICATION_SET_TEMPLATE_USER_LEVEL
	mov	dx, INTRODUCTORY_FEATURES
	cmp	cx, UIIL_INTRODUCTORY
	je	gotFeatures
	mov	dx, BEGINNING_FEATURES
	cmp	cx, UIIL_BEGINNING
	je	gotFeatures
	mov	dx, INTERMEDIATE_FEATURES
	cmp	cx, UIIL_INTERMEDIATE
	je	gotFeatures
	mov	dx, ADVANCED_FEATURES
gotFeatures:
	mov	ax, MSG_GEOCALC_APPLICATION_SET_USER_LEVEL
	mov	cx, dx
	push	cx
	call	ObjCallInstanceNoLock
	; update list
	pop	cx
	GetResourceHandleNS UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				;dx <- no indeterminates
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
GeoCalcApplicationSetTemplateUserLevel	endm

if 0
/* code to reset recalc options to default if recalc settings are not
   available -- problem is that recalc options of document are altered */
GeoCalcApplicationSetFeatures	method	dynamic	GeoCalcApplicationClass,
					MSG_GEN_APPLICATION_SET_APP_FEATURES
	push	cx
	mov	di, offset GeoCalcApplicationClass
	call	ObjCallSuperNoLock
	pop	cx
	test	cx, mask GCF_ADVANCED_SSHEET
	jnz	done				; feature enabled, done
	;
	; if GCF_ADVANCED_SSHEET is not enabled, make sure we are doing
	; auto-recalc (use default calc settings)
	;
	mov	dx, size SpreadsheetRecalcParams
	sub	sp, dx
	mov	bp, sp
	clr	ax
	mov	ss:[bp].SRP_flags, ax
	mov	ss:[bp].SRP_circCount, 1
	mov	ss:[bp].SRP_converge.F_mantissa_wd0, ax
	mov	ss:[bp].SRP_converge.F_mantissa_wd1, ax
	mov	ss:[bp].SRP_converge.F_mantissa_wd2, ax
	mov	ss:[bp].SRP_converge.F_mantissa_wd3, ax
	mov	ss:[bp].SRP_converge.F_exponent, ax
	mov	ax, MSG_SPREADSHEET_CHANGE_RECALC_PARAMS
	push	si
	mov	bx, segment SpreadsheetClass
	mov	si, offset SpreadsheetClass
	mov	di, mask MF_STACK or mask MF_RECORD
	call	ObjMessage			; di = event
	pop	si
	add	sp, dx
	mov	cx, di
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	dx, TO_APP_TARGET
	call	ObjCallInstanceNoLock
done:
	ret
GeoCalcApplicationSetFeatures	endm
endif


if _LEVELS

COMMENT @----------------------------------------------------------------------

MESSAGE:	GeoCalcApplicationChangeUserLevel --
		MSG_GEOCALC_APPLICATION_CHANGE_USER_LEVEL
						for GeoCalcApplicationClass

DESCRIPTION:	User change to the user level

PASS:
	*ds:si - instance data
	es - segment of GeoCalcApplicationClass

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
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
GeoCalcApplicationChangeUserLevel	method dynamic	GeoCalcApplicationClass,
					MSG_GEOCALC_APPLICATION_CHANGE_USER_LEVEL

	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	ret

GeoCalcApplicationChangeUserLevel	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	GeoCalcApplicationCancelUserLevel --
		MSG_GEOCALC_APPLICATION_CANCEL_USER_LEVEL
						for GeoCalcApplicationClass

DESCRIPTION:	Cancel User change to the user level

PASS:
	*ds:si - instance data
	es - segment of GeoCalcApplicationClass

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
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
GeoCalcApplicationCancelUserLevel	method dynamic	GeoCalcApplicationClass,
					MSG_GEOCALC_APPLICATION_CANCEL_USER_LEVEL

	mov	cx, ds:[di].GAI_appFeatures

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	ret

GeoCalcApplicationCancelUserLevel	endm


endif 


COMMENT @----------------------------------------------------------------------

MESSAGE:	GeoCalcApplicationQueryResetOptions --
		MSG_GEOCALC_APPLICATION_QUERY_RESET_OPTIONS
						for GeoCalcApplicationClass

DESCRIPTION:	Make sure that the user wants to reset options

PASS:
	*ds:si - instance data
	es - segment of GeoCalcApplicationClass

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
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
GeoCalcApplicationQueryResetOptions	method dynamic	GeoCalcApplicationClass,
				MSG_GEOCALC_APPLICATION_QUERY_RESET_OPTIONS

	; ask the user if she wants to reset the options

	push	ds:[LMBH_handle]
	clr	ax
	pushdw	axax				;SDOP_helpContext
	pushdw	axax				;SDOP_customTriggers
	pushdw	axax				;SDOP_stringArg2
	pushdw	axax				;SDOP_stringArg1
	GetResourceHandleNS	ResetOptionsQueryString, bx
	mov	ax, offset ResetOptionsQueryString
	pushdw	bxax
	mov	ax, CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION,0>
	push	ax
	call	UserStandardDialogOptr
	pop	bx
	call	MemDerefDS
	cmp	ax, IC_YES
	jnz	done

	mov	ax, MSG_META_RESET_OPTIONS
	call	ObjCallInstanceNoLock
done:
	ret

GeoCalcApplicationQueryResetOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GeoCalcApplicationUserLevelStatus --
		MSG_GEOCALC_APPLICATION_USER_LEVEL_STATUS
						for GeoCalcApplicationClass

DESCRIPTION:	Update the "Fine Tune" trigger

PASS:
	*ds:si - instance data
	es - segment of GeoCalcApplicationClass

	ax - The message

	cx - current selection

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
if 0
GeoCalcApplicationUserLevelStatus	method dynamic	GeoCalcApplicationClass,
				MSG_GEOCALC_APPLICATION_USER_LEVEL_STATUS

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, ADVANCED_FEATURES
	jz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	dl, VUM_NOW
	GetResourceHandleNS	FineTuneTrigger, bx
	mov	si, offset FineTuneTrigger
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

GeoCalcApplicationUserLevelStatus	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationInitiateFineTune
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the fine tune dialog box

CALLED BY:	MSG_GEOCALC_APPLICATION_INITIATE_FINE_TUNE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationInitiateFineTune	method dynamic GeoCalcApplicationClass,
				MSG_GEOCALC_APPLICATION_INITIATE_FINE_TUNE
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	GCA_ObjMessageCall			;ax = features

	mov_tr	cx, ax
	clr	dx
	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	GCA_ObjMessageSend

	GetResourceHandleNS	FineTuneDialog, bx
	mov	si, offset FineTuneDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	GCA_ObjMessageSend
	ret
GeoCalcApplicationInitiateFineTune		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcApplicationFineTune
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set fine tune settings

CALLED BY:	MSG_GEOCALC_APPLICATION_FINE_TUNE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcApplicationFineTune		method dynamic GeoCalcApplicationClass,
					MSG_GEOCALC_APPLICATION_FINE_TUNE

	;
	; get fine tune settings
	;
	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	GCA_ObjMessageCall		;ax <- new features

	;
	; update the level list
	;
	mov_tr	cx, ax				;cx <- new features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	GCA_ObjMessageSend
	mov	cx, 1				;cx <- mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	GCA_ObjMessageSend

ifdef GPC_ONLY
	;
	; if not attaching, always save after fine tune
	;
	mov	si, offset GCAppObj
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
	mov	ax, MSG_META_SAVE_OPTIONS
	call	UserCallApplication
done:
endif

	ret
GeoCalcApplicationFineTune		endm

InitCode	ends

