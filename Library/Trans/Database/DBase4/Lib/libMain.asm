COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	dBase IV
MODULE:		Lib		
FILE:		libMain.asm

AUTHOR:		Ted Kim, September 14, 1992

ROUTINES:
	Name			Description
	----			-----------
    GLB TransGetExportOptions	Return the handle of map list data block
    GLB TransGetImportOptions	Return the handle of map list data block
    GLB ImportGetFileInfo	Get number of fields from the source file
    INT SendNotificationDataBlock	Send notification data block to impex
    INT CreateDataBlock		Create a new notification data block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/92		Initial revision

DESCRIPTION:
        This is the main assembly file for the library module of the
	dBase IV translation library.

	$Id: libMain.asm,v 1.1 97/04/07 11:43:34 newdeal Exp $

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
	je	exit				; exit if none

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
	je	exit				; exit if none

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
	.enter

	mov	ds, dx				; ds:bp-ImpexFileSelectionData
	mov	ax, ds:[bp].IFSD_type 		; ax - selection type
	and	ax, mask GFSEF_TYPE 		
	cmp	ax, GFSET_FILE shl offset GFSEF_TYPE	; is this a file?
	jne	exit				; if not, just exit
	
	call	FILEPUSHDIR			; save current dir. path

	mov	bx, ds:[bp].IFSD_disk		; bx - disk handle
	mov	dx, bp
	add	dx, offset IFSD_path		; ds:dx - path name
	call	FileSetCurrentPath		; set the path
	jc	quit				; exit if error

	mov	al, FILE_ACCESS_R or FILE_DENY_W ; FileAccessFlags	
	mov	dx, bp
	add	dx, offset IFSD_selection	; ds:dx - file name
	call	FileOpen			; open this file
	jc	quit				; exit if error
	mov	bx, ax				; bx - file handle
	push	bx				; save the file handle
	clr	cx				; initialize '"' counter
	clr	dx				; initialize field counter 
	call	InputCacheAttach		; set it up for reading
	jc	error				; exit if error

        call	InputCacheGetChar		; al - version number		
	jc	error				; exit if error

	cmp	al, DBASE4_NO_MEMO
	je	okay
	cmp	al, DBASE4_MDX
	je	okay
	cmp	al, DBASE4_MEMO
	jne	destroy
okay:
	; Create a data block to send to the GCN list

	call	InputCacheUnGetChar
	push	bx
        call    CreateDataBlock
	jc	skip				; skip if there was an error	
	mov	ax, 1
	call	MemInitRefCount		; initialize the reference count to one
	call	SendNotificationDataBlock	; send data block to GCN list
skip:
	pop	bx
destroy:
	call	InputCacheDestroy		; destroy cache block
error:
	pop	bx				; bx - file handle
	call	FileClose			; close this file
quit:
	call 	FILEPOPDIR			; restore the dir. path
exit:
	.leave
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

PASS:		bx - handle of cache block

RETURN:		bx - handle of a new notification data block
		carry set if there was an error

DESTROYED:	ax, cx, dx, di

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateDataBlock	proc	near	uses  ds
	cacheBlock	local	word
	dataBlock	local	word
	numFields	local	word
	.enter

	; skip the 1st 32 bytes of dBase IV header

	clr	numFields
	mov	cacheBlock, bx
	mov	cx, size DBaseHeader		; cx - # of bytes to skip
nextChar:
	call	InputCacheGetChar		
	LONG	jc	exit			; exit if file error
	loop	nextChar

	; create a data block and mark it as lmem block

	mov	ax, LMEM_TYPE_GENERAL		; ax - LMemType
	mov	cx, size ImpexMapFileInfoHeader	; cx - size of header  
	call	MemAllocLMem			; allocate a data block
	mov	dataBlock, bx			; save the handle
	mov	ah, 0
	mov	al, mask HF_SHARABLE
	call	MemModifyFlags			; mark this block shareable
	call	MemLock				; lock this block
	mov	ds, ax
	clr	di				; ds:di - LMem header

	; create a new chunk array to store field names

	mov	bx, FIELD_NAME_SIZE+1		; bx - element size 
	clr	cx				; use default ChunkArrayHeader
	clr	si				; allocate a chunk handle
	clr	al				; no ObjChunkFlags passed
	call	ChunkArrayCreate	
	mov	ds:[di].IMFIH_fieldChunk, si	; save chunk handle

	; check to see if there are any more field descriptors

	mov	bx, cacheBlock
nextField:
	call	InputCacheGetChar		
	jc	exit				; exit if file error
	cmp	al, CR				; if none, done
	je	done

	call	InputCacheUnGetChar
	call	ChunkArrayAppend		; ds:di - ptr to new element

	; copy the field name to the chunk array

	mov	cx, FIELD_NAME_SIZE 		; cx - element size
next2:
	call	InputCacheGetChar		
	jc	exit				; exit if file error
	mov	ds:[di], al
	inc	di
	loop	next2

	; make sure we null terminate the string

	tst	al
	je	zero
	mov	byte ptr ds:[di], 0
zero:
	; skip to the end of field descriptor

	mov	cx, size FieldDescriptor
	sub	cx, FIELD_NAME_SIZE
next3:
	call	InputCacheGetChar		
	jc	exit				; exit if file error
	loop	next3
	inc	numFields			; increment the field counter
	jmp	nextField			; read in the next field name
done:
	clr	di
	mov	ax, numFields
	mov	ds:[di].IMFIH_numFields, ax	; save away number of fields
	mov	bx, dataBlock
	call	MemUnlock			; unlock LMem block
	clc					; return with no error
exit:
	.leave
	ret
CreateDataBlock	endp

Import	ends
