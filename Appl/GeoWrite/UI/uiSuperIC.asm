if _BATCH_RTF
include writeBatchExport.def

idata	segment
	SuperImpexExportControlClass
	SuperImpexImportControlClass
	appExportImportSucceeded	byte	(BB_FALSE)
	global	batchInfo:hptr
idata	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableExportFinishNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns ON the export finish notification flag

CALLED BY:	MSG_SUPER_IMPEX_ENABLE_EXPORT_FINISH_NOTIFICATION

PASS:		*ds:si	= SuperImpexExportControlClass object
		ds:di	= SuperImpexExportControlClass instance data
		ds:bx	= SuperImpexExportControlClass object (same as *ds:si)
		es 	= segment of SuperImpexExportControlClass
		ax	= message #
RETURN:		nada.
DESTROYED:	zip.
SIDE EFFECTS:	zero.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/04/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableExportFinishNotification	method dynamic SuperImpexExportControlClass, 
				MSG_SUPER_IMPEX_ENABLE_EXPORT_FINISH_NOTIFICATION
	mov	ds:[di].SIEC_notifyExportFinish, BB_TRUE
	ret
EnableExportFinishNotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableImportFinishNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn ON the import finish notification flag.

CALLED BY:	MSG_SUPER_IMPEX_ENABLE_IMPORT_FINISH_NOTIFICATION

PASS:		*ds:si	= SuperImpexImportControlClass object
		ds:di	= SuperImpexImportControlClass instance data
		ds:bx	= SuperImpexImportControlClass object (same as *ds:si)
		es 	= segment of SuperImpexImportControlClass
		ax	= message #
RETURN:		nada.
DESTROYED:	zilch.
SIDE EFFECTS:	fuggeda' 'bout it.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableImportFinishNotification	method dynamic SuperImpexImportControlClass, 
					MSG_SUPER_IMPEX_ENABLE_IMPORT_FINISH_NOTIFICATION
	mov	ds:[di].SIEC_notifyImportFinish, BB_TRUE
	ret
EnableImportFinishNotification	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableExportFinishNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns OFF the export finish notification flag

CALLED BY:	MSG_SUPER_IMPEX_DISABLE_EXPORT_FINISH_NOTIFICATION

PASS:		*ds:si	= SuperImpexExportControlClass object
		ds:di	= SuperImpexExportControlClass instance data
		ds:bx	= SuperImpexExportControlClass object (same as *ds:si)
		es 	= segment of SuperImpexExportControlClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/04/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableExportFinishNotification	method dynamic SuperImpexExportControlClass, 
					MSG_SUPER_IMPEX_DISABLE_EXPORT_FINISH_NOTIFICATION
	mov	ds:[di].SIEC_notifyExportFinish, BB_FALSE
	ret
DisableExportFinishNotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableImportFinishNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn OFF the import finish notification flag.

CALLED BY:	MSG_SUPER_IMPEX_DISABLE_IMPORT_FINISH_NOTIFICATION

PASS:		*ds:si	= SuperImpexImportControlClass object
		ds:di	= SuperImpexImportControlClass instance data
		ds:bx	= SuperImpexImportControlClass object (same as *ds:si)
		es 	= segment of SuperImpexImportControlClass
		ax	= message #
RETURN:		zip.
DESTROYED:	nuthin'.
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableImportFinishNotification	method dynamic SuperImpexImportControlClass, 
					MSG_SUPER_IMPEX_DISABLE_IMPORT_FINISH_NOTIFICATION
	mov	ds:[di].SIEC_notifyImportFinish, BB_FALSE
	ret
DisableImportFinishNotification	endm
endif		; _BATCH_RTF

ifdef PRODUCT_TOOLS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuperImpexImportControlImportOperationComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The Impex library has reported that the import is complete.
		We handle this message in order to send notification to the
		user that the import is complete.

CALLED BY:	MSG_IMPORT_EXPORT_OPERATION_COMPLETED

PASS:		*ds:si	= SuperImpexImportControlClass object
		ds:di	= SuperImpexImportControlClass instance data
		ds:bx	= SuperImpexImportControlClass object (same as *ds:si)
		es 	= segment of SuperImpexImportControlClass
		ax	= message #
		CX	= BB_TRUE if impex operation successful, BB_FALSE
			  otherwise
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuperImpexImportControlImportOperationComplete	method dynamic SuperImpexImportControlClass, 
					MSG_IMPORT_EXPORT_OPERATION_COMPLETED
	uses	ax, bx, cx, dx, bp
	.enter

	;
	; Apply style sheet if one has been set
	;
	push	ds, si, di, cx, dx, bp
	segmov	ds, cs, ax
	lea	si, cs:[writerCategory]		; ds:si <- category
	mov	cx, cs
	lea	dx, cs:[styleSheetKey]		; cx:dx <- key
	clr	bp				; allocate memory
	call	InitFileReadString		; bx <- memHandle of string
	jcxz	NoStyleSheet	
	call	MemLock				; ax <- seg. of mem.
	push	bx				; save memhandle

	;
	; Set the style sheet filename on the File Selector
	;
	mov	es, ax
	clr	di
	clr	bx		; path contains drive specifier
	call	FileParseStandardPath		; ax <- standard path, es:di <- path tail
	GetResourceHandleNS	HelpEditUI, bx
	mov	si, offset StyleSheetFileSelector		
	mov	cx, es
	mov	dx, di		; cx:dx <- path tail
	mov	bp, ax		; bp <- standard path
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_FULL_SELECTION_PATH
	mov	di, mask MF_CALL
	call	ObjMessage
	jc	NoStyleSheetPopBX	; file not found; don't do anything

	;
	; Load the style sheet.
	;
	mov	ax, MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET
	sub	sp, size SSCLoadStyleSheetParams
	mov	bp, sp
	GetResourceHandleNS	HelpEditUI, cx
	mov	dx, offset StyleSheetFileSelector
	movdw	ss:[bp].SSCLSSP_fileSelector, cxdx
	mov	bx, segment WriteDocumentClass
	mov	si, offset WriteDocumentClass
	movdw	ss:[bp].SSCLSSP_styledClass, bxsi
	mov	di, mask MF_RECORD or mask MF_STACK
	mov	dx, size SSCLoadStyleSheetParams
	call	ObjMessage		; packed up and ready to go in DI. . .
	add	sp, size SSCLoadStyleSheetParams

	mov	ax, MSG_META_SEND_CLASSED_EVENT
	mov	cx, di		; cx <- classed event handle
	mov	dx, TO_APP_MODEL
	GetResourceHandleNS	ApplicationUI, bx
	mov	si, offset WriteApp
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	bx			; bx <- MemHandle of memory alloc'ed by InitFileReadString
	call	MemFree
	jmp	NoStyleSheet

NoStyleSheetPopBX:
	pop	bx

NoStyleSheet:
	pop	ds, si, di, cx, dx, bp

if _BATCH_RTF
	;
	; continue batch ONLY if notification is on.
	;
	GetResourceSegmentNS	dgroup, es, bx
	mov	bx, es:[batchInfo]
	tst	bx
	jz	done

	cmp	ds:[di].SIEC_notifyImportFinish, BB_TRUE
	jne	done

	call	OperationCompleteCommon
endif

done:
	.leave
	ret
writerCategory	char	"write", 0
styleSheetKey	char	"autoStyleSheet", 0

SuperImpexImportControlImportOperationComplete	endm
endif	; PRODUCT_TOOLS

if _BATCH_RTF

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuperImpexExportControlExportOperationComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The Impex library has reported that the export is complete.
		We handle this message in order to send notification to the
		user that the export is complete.
CALLED BY:	GLOBAL (MSG_IMPORT_EXPORT_OPERATION_COMPLETED)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		SS:BP	= ImpexTranslationParams
		CX	= BB_TRUE if impex operation successful, BB_FALSE
			  otherwise
RETURN:		Nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		dmedeiros 10/05/00	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SuperImpexExportControlExportOperationComplete	method dynamic	SuperImpexExportControlClass,
				MSG_IMPORT_EXPORT_OPERATION_COMPLETED
	uses	ax, bx, cx, dx, bp
	.enter
	
	;
	; continue batch ONLY if notification is on.
	;
	GetResourceSegmentNS	dgroup, es, bx
	mov	bx, es:[batchInfo]
	tst	bx
	jz	done

	cmp	ds:[di].SIEC_notifyExportFinish, BB_TRUE
	jne	done

	call	OperationCompleteCommon
done:
	.leave
	ret
SuperImpexExportControlExportOperationComplete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OperationCompleteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for the Import/Export operation complete method
		handlers (MSG_IMPORT_EXPORT_OPERATION_COMPLETED)

CALLED BY:	SuperImpexExportControlExportOperationComplete,
		SuperImpexImportControlImportOperationComplete
PASS:		CX	= BB_TRUE if impex operation successful, BB_FALSE
			  otherwise
RETURN:		nothing
DESTROYED:	ax, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OperationCompleteCommon	proc	near
	;
	; if the last impex operation failed, then
	; don't do anything else with the batch.
	;
	cmp	cx, BB_FALSE
	je	opFailed

	;
	; NEXT!
	;
	call	GeodeGetProcessHandle
	clr	si, di
	mov	ax, MSG_WRITE_PROCESS_NEXT_IN_BATCH
	call	ObjMessage
	jmp	done

opFailed:
	call	GeodeGetProcessHandle
	clr	si, di
	mov	ax, MSG_WRITE_PROCESS_CLEAN_UP_AFTER_BATCH
	call	ObjMessage		
done:
	ret
OperationCompleteCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlExportComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handled when the application reports that its part of the
		export process (converting to a transfer item) is complete.
		We intercept this message so that we can set a flag that the
		process will read and see if the export succeeded.  This
		determines whether to output a "Success" or a "Failed" message
		on the batch log.

CALLED BY:	MSG_EXPORT_CONTROL_EXPORT_COMPLETE

PASS:		*ds:si	= SuperImpexExportControlClass object
		ds:di	= SuperImpexExportControlClass instance data
		ds:bx	= SuperImpexExportControlClass object (same as *ds:si)
		es 	= segment of SuperImpexExportControlClass
		ax	= message #
RETURN:		nothing.
DESTROYED:	nothing.
SIDE EFFECTS:	nothing.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	10/11/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlExportComplete	method dynamic SuperImpexExportControlClass, 
					MSG_EXPORT_CONTROL_EXPORT_COMPLETE
	uses	ax, cx, dx, bp
	.enter

	;
	; Notify process that the export succeeded.
	;
	push	ds
	call	ThreadGetDGroupDS
	mov	ds:[appExportImportSucceeded], BB_TRUE
	pop	ds
	mov	di, offset SuperImpexExportControlClass
	call	ObjCallSuperNoLock

	.leave
	ret
ExportControlExportComplete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlImportComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_IMPORT_CONTROL_IMPORT_COMPLETE

PASS:		*ds:si	= SuperImpexImportControlClass object
		ds:di	= SuperImpexImportControlClass instance data
		ds:bx	= SuperImpexImportControlClass object (same as *ds:si)
		es 	= segment of SuperImpexImportControlClass
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
ImportControlImportComplete	method dynamic SuperImpexImportControlClass, 
					MSG_IMPORT_CONTROL_IMPORT_COMPLETE
	uses	ax, cx, dx, bp
	.enter
	;
	; Notify process that the export succeeded.
	;
	push	ds
	call	ThreadGetDGroupDS
	mov	ds:[appExportImportSucceeded], BB_TRUE
	pop	ds
	mov	di, offset SuperImpexImportControlClass
	call	ObjCallSuperNoLock
	.leave
	ret
ImportControlImportComplete	endm


CommonCode	ends
endif
