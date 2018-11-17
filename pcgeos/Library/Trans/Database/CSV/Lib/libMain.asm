COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CSV		
FILE:		libMain.asm

AUTHOR:		Ted Kim, June 10, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransLibraryEntry	Entry point for translation library
    GLB TransGetExportOptions	Return the handle of map list data block
    GLB TransGetImportOptions	Return the handle of map list data block
    GLB ImportGetFileInfo	Get number of fields from the source file
    INT SendNotificationDataBlock	Send notification data block to impex
    INT CreateDataBlock		Create a new notification data block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial revision

DESCRIPTION:
        This is the main assembly file for the library module of the
	CSV translation library.

	$Id: libMain.asm,v 1.1 97/04/07 11:42:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransCommonCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the handle of the block containing export options

CALLED BY:	GLOBAL

PASS:		dx	- handle of object block holding UI gadgetry
			  (zero if default options are desired)

RETURN:		dx	- handle of map list data block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransGetExportOptions 	proc	far 	uses	ax, bx, ds, si, di
	.enter
	
	tst	dx				; no object block?
	je	exit				; if none, exit

	mov	ax, MSG_IMC_MAP_GET_MAP_DATA		
	mov	bx, dx				; bx - block of UI
	mov	si, offset ExportOptions	; bx:si - OD of Map Controller 
	mov	di, mask MF_CALL 
	call	ObjMessage			; returns map block in dx
exit:
	.leave
	ret
TransGetExportOptions endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetImportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the handle of the block containing import options

CALLED BY:	GLOBAL

PASS:		dx	- handle of object block holding UI gadgetry

RETURN:		dx	- handle of map list data block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TransGetImportOptions proc	far
	.enter
	
	tst	dx				; no object block?
	je	exit				; if none, exit

	mov	ax, MSG_IMC_MAP_GET_MAP_DATA		
	mov	bx, dx				; bx - block of UI
	mov	si, offset ImportOptions	; bx:si - OD of Map Controller 
	mov	di, mask MF_CALL 
	call	ObjMessage			; returns map block in dx
exit:
	.leave
	ret
TransGetImportOptions endp

TransCommonCode	ends

Import	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportGetFileInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get number of fields in a record from the selected file.

CALLED BY:	MSG_IMPORT_EXPORT_FILE_SELECTION_INFO (Subclss of GenControl)

PASS:		DX:BP   = ImpexFileSelectionData

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportGetFileInfo	method	ImpexMappingControlClass, 
			MSG_IMPORT_EXPORT_FILE_SELECTION_INFO
	uses	ds, si, di
	fieldLength	local	word		; size of a field
	numFields	local	word		; highest number of
						;  fields in any record
	mov	bx, bp				; save bp in bx
	.enter

	push	bx, bp
	mov	ds, dx				; ds:bx-ImpexFileSelectionData
	mov	ax, ds:[bx].IFSD_type 		; ax - selection type
	and	ax, mask GFSEF_TYPE 		
	cmp	ax, GFSET_FILE shl offset GFSEF_TYPE	; is this a file?
	LONG	jne	exit			; if not, just exit
	
	call	FILEPUSHDIR			; save current dir. path

	mov	dx, bx
	push	dx
	add	dx, offset IFSD_path		; ds:dx - path name
	mov	bx, ds:[bx].IFSD_disk		; bx - disk handle
	call	FileSetCurrentPath		; set the path
	pop	dx
	LONG	jc	error2			; exit if error

	mov	al, FILE_ACCESS_R or FILE_DENY_W ; FileAccessFlags	
	add	dx, offset IFSD_selection	; ds:dx - file name
	call	FileOpen			; open this file
	LONG	jc	error2			; exit if error
	mov	bx, ax				; bx - file handle
	push	bx				; save the file handle
	call	InputCacheAttach		; set it up for reading
	jc	error				; exit if error
	clr	dx				; initialize numFields
	mov	ss:[numFields], dx
nextRecord:
	clr	cx				; initialize '"' counter
	clr	dx				; initialize field counter 
	clr	fieldLength			; initialize size of field
nextChar:
	; check to see if the field is too big 

	cmp	fieldLength, MAX_TEXT_FIELD_LENGTH
	je	error				; jump to error if too big

	call	InputCacheGetChar		; read in a character
	jc	error				; skip if error
	PrintMessage <ImportGetFileInfo - fieldLength   assume size>
	inc	fieldLength			; update the counter
DBCS <	inc	fieldLength			; update the counter	>

	; check for an illegal character in the file

	LocalIsNull	ax			; is this a null character?
	je	error				; if so, error

	LocalCmpChar	ax, '"'			; is it a double-quote?
	jne	checkComma			; if not, check for comma
	inc	cx				; if so, update the counter
	jmp	nextChar			; and check the next char
checkComma:
	LocalCmpChar	ax, ','			; is it a comma?
	jne	checkCR				; if not, check for CR
	test	cx, 1				; is '"' counter odd?
	jne	nextChar			; if so, ignore it
	inc	dx				; if not, update field counter
	clr	cx				; re-init quote counter
	clr	fieldLength			; re-init size of field
	jmp	nextChar			; and check the next character
checkCR:
	LocalCmpChar	ax, CR			; is this a carriage return?
    	jne 	checkEOF
	test	cx, 1				; is '"' counter odd?
	jne	nextChar			; if so, CR is part of field data
	;
	; Store the value of the field counter if it's the highest we've
	; seen so far. Then check the next record.
	;
	inc	dx				; add one to the field counter
	cmp	dx, ss:[numFields]
	jle	nextRecord
	mov	ss:[numFields], dx
	jmp	nextRecord
checkEOF:
	LocalCmpChar	ax, EOF			; is this end of file character?
	jne	nextChar			; if not, get the next char
	;
	; Store the value of the field counter if it's the highest we've
	; seen so far. We're done.
	;
	inc	dx				; add one to the field counter
	cmp	dx, ss:[numFields]
	jle	noError
	mov	ss:[numFields], dx
	jmp	noError
error:
	clr	dx				; no entry in source list
noError:
	call	InputCacheDestroy		; destroy cache block
	pop	bx				; bx - file handle
	call	FileClose			; close this file
	jmp	popDir
error2:
	clr	dx
popDir:
	call 	FILEPOPDIR			; restore the dir. path

	; Create a data block to send to the GCN list

	mov	dx, ss:[numFields]
        call    CreateDataBlock
	mov	ax, 1
	call	MemInitRefCount		; initialize the reference count to one
	call	SendNotificationDataBlock	; send data block to GCN list
exit:
	pop	bx, bp

	.leave
	mov	bp, bx				; restore bp
	ret
ImportGetFileInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNotificationDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the notification data block to the Impex Map Controller.

CALLED BY:	ImportGetFileInfo

PASS:		bx - handle of notification data block

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, bp

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendNotificationDataBlock	proc	near

	; Create the classed event

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS	; cx:dx - notification type
	mov	dx, GWNT_MAP_LIBRARY_CHANGE
	mov	bp, bx				; bp - handle of data block
	mov	di, mask MF_RECORD
	call	ObjMessage			; event handle => DI

	; Setup the GCNListMessageParams

	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp			; GCNListMessageParams => SS:BP
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, \
			GAGCNLT_APP_TARGET_NOTIFY_LIBRARY_CHANGE
	mov	ss:[bp].GCNLMP_block, bx	; bx - data block
	mov	ss:[bp].GCNLMP_event, di	; di - event handle
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_STACK
	call	ObjMessage
	add	sp, dx				; clean up the stack
	ret
SendNotificationDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new notification data block to be sent to impex.

CALLED BY:	ImportGetFileInfo

PASS:		dx - number of fields

RETURN:		bx - handle of a new notification data block

DESTROYED:	ax, cx, dx, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateDataBlock	proc	near	uses  ds
	.enter

	mov	ax, LMEM_TYPE_GENERAL		; ax - LMemType
	mov	cx, size ImpexMapFileInfoHeader	; cx - size of header  
	call	MemAllocLMem			; allocate a data block
	mov	ah, 0
	mov	al, mask HF_SHARABLE
	call	MemModifyFlags			; mark this block shareable
	call	MemLock				; lock this block
	mov	ds, ax
	clr	di				; ds:di - LMem header
	mov	ds:[di].IMFIH_fieldChunk, 0	; no field names for this lib.
	mov	ds:[di].IMFIH_numFields, dx	; save away number of fields
	call	MemUnlock			; unlock LMem block

	.leave
	ret
CreateDataBlock	endp

Import	ends
