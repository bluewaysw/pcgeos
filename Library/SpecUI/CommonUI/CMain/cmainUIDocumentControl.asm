COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainUIDocumentControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDocumentControl	Open look document control class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:

	$Id: cmainUIDocumentControl.asm,v 1.1 97/04/07 10:51:57 newdeal Exp $

-------------------------------------------------------------------------------@
; un-comment this one to make a non-saving version for demo
;PRODUCT_WIN_DEMO = TRUE

OLDC_DEFAULT_FEATURES		= GDC_SUGGESTED_ADVANCED_FEATURES
OLDC_DEFAULT_TOOLBOX_FEATURES	= mask GDCToolboxFeatures

OLDCFileSelectorFlags	record
    OLDCFSF_SAVE:1		;save, save as template or copy to
    OLDCFSF_TEMPLATE:1		;open template or save as template
    :14
OLDCFileSelectorFlags	end

;---------------------------------------------------

CommonUIClassStructures segment resource

	OLDocumentControlClass	mask CLASSF_NEVER_SAVED or \
				mask CLASSF_DISCARD_ON_SAVE

CommonUIClassStructures ends


;---------------------------------------------------

Build segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecInitDocumentControl

DESCRIPTION:	Initialize the document control code (by looking up various
		system settings in the geos.ini file)

CALLED BY:	OLFieldAttach

PASS:
	ds:si - field specific category string

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/10/92		Initial version

------------------------------------------------------------------------------@

SpecInitDocumentControl	proc	far	uses si, ds
	.enter

	mov	bx, segment docControlOptions
	mov	es, bx

	mov	cx, cs
	mov	dx, offset docControlOptionsString
	call	InitFileReadInteger
	jc	afterOptions
	mov	es:[docControlOptions], ax
afterOptions:

	mov	dx, offset docControlFSLevelString
	call	InitFileReadInteger
	jc	afterFSLevel
	mov	es:[docControlFSLevel], ax
afterFSLevel:

	; get backupDir

	mov	dx, offset backupDirString
	clr	bp				;allocate block
	call	InitFileReadData		;bx = block, cx = length
	jc	afterBackupDir
	jcxz	pathError			;error if zero length
		
	; Lock down the saved data and skip past the path (we don't want to
	; copy the path until we know that DiskRestore is successful)

	call	MemLock
	mov	ds, ax
	clr	si
skipPathLoop:
	LocalGetChar ax, dssi
	LocalIsNull ax				; hit null-terminator?
	loopne	skipPathLoop			; nope...

EC <	ERROR_NE	OL_DOCUMENT_PATH_STORED_INCORRECTLY	>

	; ds:si = start of data for saved disk handle; restore the beast.

	clr	cx
	call	DiskRestore
	jc	pathError
	mov	es:[backupDirDisk], ax

	clr	si
	mov	di, offset backupDirPath
pathCopyLoop:
	LocalGetChar ax, dssi
	LocalPutChar esdi, ax
	LocalIsNull ax				; hit null-terminator?
	jnz	pathCopyLoop			; nope...

pathError:
	call	MemFree
afterBackupDir:

	.leave
	ret

SpecInitDocumentControl	endp

docControlOptionsString		char	"docControlOptions", 0

docControlFSLevelString		char	"docControlFSLevel", 0

backupDirString			char	"backupDir", 0

Build ends

;-----------------

Resident segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SpecGetDocControlOptions

DESCRIPTION:	Get DocControlOptions

CALLED BY:	SpecInit

PASS:
	none

RETURN:
	al - DocControlOptions

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Should only be called after SpecInitDocumentControl

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/2/92		Initial version

------------------------------------------------------------------------------@
global SpecGetDocControlOptions:far
SpecGetDocControlOptions	proc	far
	uses	ds
	.enter
	mov	ax, segment docControlOptions
	mov	ds, ax
	mov	ax, ds:[docControlOptions]
	.leave
	ret
SpecGetDocControlOptions	endp

Resident ends

;---------------------------------------------------

DocInit segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlAppStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform preliminary startup work, like grabbing the model
		exclusive.

CALLED BY:	MSG_META_APP_STARTUP
PASS:		*ds:si	= GenDocumentControl object
		^hdx	= AppLaunchBlock
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Just grab the model and tell the GenDocumentGroup about it.

		We quite pointedly do *not* open the document mentioned in
		the AppLaunchBlock, as we need to know the IACP connection
		requesting the open, if any, and that's something only
		the GenApplication object can tell us, once it gets 
		MSG_META_IACP_NEW_CONNECTION.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentControlAppStartup method dynamic OLDocumentControlClass,
			    			MSG_META_APP_STARTUP
	.enter
	; Grab "Model" exclusive, to make sure that any messages sent
	; via "TO_MODEL" come our way.
	;
	call	MetaGrabModelExclLow

	; Forward to GenDocumentGroup
	; 
	call	SendToAppDCRegs
	.leave
	ret
OLDocumentControlAppStartup endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlAttach -- MSG_META_ATTACH for
						OLDocumentControlClass

DESCRIPTION:	Attach UI document control by opening any documents that are
		children

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_META_ATTACH

	cx	- AppAttachFlags
	dx	- Handle of AppLaunchBlock, or 0 if none.
		  This block contains the name of any document file passed
		  into the application on invocation.
	bp	- Handle of extra state block, or 0 if none.
		  This is the same block as returned from
		  MSG_GET_STATE_TO_SAVE, in some previous MSG_META_DETACH

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (path is null) {
		set path to document directory
	}
	send MSG_META_ATTACH to all children

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

UIDCAttachDefFileParams	struct
    UIDCADFP_path	char PATH_BUFFER_SIZE dup (?)
    UIDCADFP_category	char INI_CATEGORY_BUFFER_SIZE dup (?)
UIDCAttachDefFileParams	ends

OLDocumentControlAttach	method dynamic OLDocumentControlClass,
					MSG_META_ATTACH


	; Mark no document as existing.  If a document does exist we will
	; find out soon enough

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf 	ds:[di].GDCI_attrs, not mask GDCA_DOCUMENT_EXISTS

	; mark ourselves dirty as we're pretty much guaranteed to change
	; during the life of the application.

	call	ObjMarkDirty

	;
	; check if we have an AppLaunchBlock, if so, then use it
	;
	tst	dx				; any launch block?
	jz	noLaunchBlock
	mov	bx, dx
	call	MemLock				; lock AppLaunch block
	mov	es, ax
	cmp	es:[ALB_dataFile][0], 0		; any datafile?
	je	unlockNoBlock			; no
	;
	; use info in AppLaunchBlock
	;
	push	bx				; save AppLaunchBlock
	mov	cx, es				; cx:dx = path
	mov	dx, offset ALB_path
	mov	bp, es:[ALB_diskHandle]		; bp = disk handle
	mov	ax, MSG_GEN_PATH_SET
	call	ObjCallInstanceNoLock

	mov	ax, MSG_META_ATTACH
	call	SendToAppDCRegs			; prepare App DC for the
						;  onslaught

	clr	bx				; start w/default DocOpenParams
	;
	; If we're printing, pass that fact on to document
	;
	test	es:[ALB_launchFlags], mask ALF_OPEN_FOR_IACP_ONLY
	jz	afterPrintFlag
	ornf	bx, mask DOF_OPEN_FOR_IACP_ONLY
afterPrintFlag:
	;
	; If the document is under SP_TEMPLATE, then open as a template
	;
	push	ds
	clr	ax
	mov	ds, ax
	mov	cx, SP_TEMPLATE			; path 1 => CX
	mov	dx, es:[ALB_diskHandle]		; path 2 => DX, ES:DI
	mov	di, offset ALB_path
	call	FileComparePaths
	pop	ds
	cmp	al, PCT_SUBDIR			; = PCT_EQUAL or PCT_SUBDIR ?
	ja	afterTemplate
	ornf	bx, mask DOF_FORCE_TEMPLATE_BEHAVIOR
afterTemplate:
	mov	ax, MSG_GEN_DOCUMENT_GROUP_OPEN_DOC	; ax = method
	clr	cx				; use object's path (which we
						;  just set...)
	mov	bp, offset ALB_dataFile		; es:bp = filename
	call	OpenCommon
	pop	bx
	call	MemUnlock
	jmp	done

unlockNoBlock:
	call	MemUnlock
noLaunchBlock:

	mov	ax, MSG_META_ATTACH
	call	SendToAppDCRegs			; prepare App DC for the
						;  onslaught
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	; if we are restoring from state then we don't do anything

	mov	bx, ds:[di].GDCI_attrs
	andnf	ds:[di].GDCI_attrs, not mask GDCA_CURRENT_TASK

	mov	ax, MSG_OLDC_REMOVE_OLD_AND_TEST_FOR_DISPLAY_MAIN_DIALOG

	; If we're being resurrected following a quit, then there will be no
	; open docs.  Just act like we do when starting up for the first time.
	; -- Doug 5/15/93
	;
	test	cx, mask AAF_RESTORING_FROM_QUIT
	jnz	startFresh
	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	initiateCommon

startFresh:

	; if a default file exists then open it

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_OPEN_DEFAULT_DOC
	tst	ds:[di].GDCI_defaultFile
	jnz	initiateCommon

if _DUI
	;
	; if no list screen, don't open it
	;
	push	bx
	mov	ax, HINT_DOCUMENT_CONTROL_NO_FILE_LIST
	call	ObjVarFindData
	pop	bx
	jc	done
endif

	; if we're not bypassing the big dialog then put it up

	mov	ax, seg dgroup
	mov	es, ax
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	test	es:[docControlOptions], mask DCO_BYPASS_BIG_DIALOG
	jz	initiateCommon

	; if any dialog boxes opened previously then re-open

bypass::
	and	bx, mask GDCA_CURRENT_TASK
	jz	done
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_NEW_DOC
	cmp	bx, GDCT_NEW shl offset GDCA_CURRENT_TASK
	jz	initiateCommon
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_OPEN_DOC
	cmp	bx, GDCT_OPEN shl offset GDCA_CURRENT_TASK
	jz	initiateCommon
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC
	cmp	bx, GDCT_USE_TEMPLATE shl offset GDCA_CURRENT_TASK
	jz	initiateCommon
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_SAVE_AS_DOC
	cmp	bx, GDCT_SAVE_AS shl offset GDCA_CURRENT_TASK
	jz	initiateCommon
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
EC <	cmp	bx, GDCT_DIALOG shl offset GDCA_CURRENT_TASK		>
EC <	ERROR_NZ	OL_ERROR					>

initiateCommon:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov     bx, ds:[di].GDCI_documentGroup.handle
	call	ObjTestIfObjBlockRunByCurThread
	jne	twoThreaded
	;
	; Not just yet -- whether checking for no file open, putting up
	; a dialog, or opening a new/default document, do this after
	; the MSG_META_ATTACH in pogress finishes in one-threaded apps,
	; so that the app can finish coming up on screen first before
	; we potentially do a UserDoDialog, either to get the document
	; password, or to report an error opening the document. -- Doug 4/30/93
	;
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	short done

twoThreaded:
	call	ObjCallInstanceNoLock

done:

	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlAttach	endm

DocumentInit_DefaultKey	char	"defaultDocument", 0

COMMENT @----------------------------------------------------------------------

FUNCTION:	OpenCommon

DESCRIPTION:	Open a file for OLDocumentControlAttach (either a default
		file or a file passed in an AppLaunchBlock)

CALLED BY:	OLDocumentControlAttach

PASS:
	*ds:si = OLDocumentControl instance
	es:bp = filename
	cx = disk handle where file is located (0 => use object's current
	bx = DocumentOpenFlags to use (0 for default)
	ax = method to sent to OLDocumentGroup

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/90		Initial version
	Doug	1/5/93		Added ability to pass in DocumentOpenFlags,
				filename changed to be passed in es:bp

------------------------------------------------------------------------------@
OpenCommon	proc	near
	class	OLDocumentControlClass

EC <	call	AssertIsUIDocControl					>

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	mov	di, cx				; di <- disk handle
EC <	LocalGetChar cx, esbp, NO_ADVANCE	; cx <- 1st char of name >
	mov	dx, bp				; es:dx = filename

	sub	sp, size DocumentCommonParams
	mov	bp, sp

	push	ax, si, ds		; save method, and obj

	mov	ss:[bp].DCP_docAttrs, 0
	mov	ss:[bp].DCP_flags, bx
	mov	ss:[bp].DCP_connection, 0	; user-initiated
	tst	di			; any disk handle?
	jz	useObjectPath
	
	mov	ss:[bp].DCP_diskHandle, di

EC <	test	di, DISK_IS_STD_PATH_MASK				>
EC <	jnz	passedFileOK						>
EC <	LocalCmpChar cx, C_BACKSLASH					>
EC <	ERROR_NE	OLDC_PATH_MUST_BE_ABSOLUTE			>
EC <passedFileOK:							>

	;
	; Copy the passed path into DCP_path, tracking the location of the
	; last backslash in the path, as following that is the actual file
	; name that we need to copy into DCP_name.
	;
	; For the loop, bx holds the location+1 of the final backslash. If
	; no backslash in the path, it remains as bp+DCP_path
	; 
	mov	bx, es
	segmov	es, ss
	lea	di, ss:[bp].DCP_path	; es:di <- dest
	mov	si, dx			; ds:si <- source full path
	mov	ds, bx
saveBSPosition:
	mov	bx, di
splitPathLoop:
	LocalGetChar ax, dssi
	LocalPutChar esdi, ax
	LocalCmpChar ax, C_BACKSLASH
	je	saveBSPosition
	LocalIsNull ax			; end of string stored?
	jnz	splitPathLoop		; nope -- keep looping

	;
	; Now copy the filename into the DCP_name buffer. We always start
	; the copy from ss:bx, regardless of whether there was a backslash,
	; since it's either right after the backslash, or it's the start of
	; the path, which is actually just a filename.
	; 
	mov	si, bx

	lea	di, ss:[bp].DCP_path
	cmp	bx, di		; any backslash in the path (bx moved from the
				;  start of the path)?
	jne	copyNameFromSI	; yes -- copy from SI
	LocalNextChar dsbx	; set so we'll make DCP_path empty after
				;  copying the name (ds:bx-1 == DCP_path)
copyNameFromSI:
	lea	di, ss:[bp].DCP_name	; es:di <- bp.DCP_name
	mov	cx, length DCP_name
	segmov	ds, es			; ds:si <- source
	LocalCopyNString		; rep movsb/movsw
SBCS <	mov	{char}ds:[bx-1], 0	; null out final backslash, or entire>
DBCS <	mov	{wchar}ds:[bx-2], 0	; null out final backslash, or entire>
					;  path, as appropriate

	jmp	sendMessage
	

useObjectPath:
EC <	LocalCmpChar cx, C_BACKSLASH					>
EC <	ERROR_E	OLDC_PATH_MAY_NOT_BE_ABSOLUTE				>

	; copy default name
	
	lea	di, ss:[bp].DCP_name
	mov	bx, es
	segmov	es, ss			; es:di <- DCP_name
	push	si
	mov	si, dx			; ds:si <- source full path
	mov	ds, bx
	mov	cx, length DCP_name
	LocalCopyNString		; rep movsb/movsw
	pop	si

	pop	ds			; recover object segment both for
					;  call and possible fixup
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	lea	di, ss:[bp].DCP_path
	segmov	es, ss			; es:di <- path buffer
	mov	cx, size DCP_path
	call	GenPathGetObjectPath
	push	ds			; save again for common pop

	mov	ss:[bp].DCP_diskHandle, cx

sendMessage:
	pop	ax, si, ds			;recover method and object
						;popping ds safe here

	mov	dx, size DocumentCommonParams
	;
	; we always want to force queue this guy to match the behavior
	; of single thread apps on MSG_OLDG_ATTACH - brianc 6/8/93
	;
	mov	di, mask MF_STACK or mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	SendToAppDCCommonFar
	add	sp, size DocumentCommonParams

	ret

OpenCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlOpenDefaultDoc --
		MSG_GEN_DOCUMENT_CONTROL_OPEN_DEFAULT_DOC
						for OLDocumentControlClass

DESCRIPTION:	Open the default document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	10/ 7/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlOpenDefaultDoc	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_OPEN_DEFAULT_DOC

	; try and restore the path for the default document from the .ini file

	sub	sp, size PathName
	mov	bp, sp
	mov	cx, cs
	mov	dx, offset DocumentInit_DefaultKey
	call	OLDocumentFetchPathFromIniFile
	mov	bx, ss
	jnc	defaultCommon
	
	; failed: use the default filename bound to our object (relative
	; to SP_DOCUMENT)

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bp, ds:[di].GDCI_defaultFile

	tst	bp
	jz	doDialogInstead	; XXX: hack for IACP

	clr	bx		; signal in obj block
	mov	cx, SP_DOCUMENT	; default always relative to document

defaultCommon:
	call	OLDCRemoveSummons

	tst	bx		; do we need to deref a chunk in this block?
	jnz	havePath	; => no, path is on stack at bx:bp
	mov	bx, ds
	mov	bp, ds:[bp]

havePath:
	mov	es, bx		; es:bp <- path of file
	mov	ax, MSG_GEN_DOCUMENT_GROUP_OPEN_DEFAULT_DOC
	clr	bx		; default DocumentOpenFlags
	call	OpenCommon
done:
	add	sp, size PathName
	ret

doDialogInstead:
	mov	ax, MSG_OLDC_REMOVE_OLD_AND_TEST_FOR_DISPLAY_MAIN_DIALOG
	call	ObjCallInstanceNoLock
	jmp	done

OLDocumentControlOpenDefaultDoc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentFetchPathFromIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore a file's path from a key in the .ini file. The
		key is passed, but the category is obtained via query

CALLED BY:	OLDocumentControlAttach
PASS:		*ds:si	= generic object
		cx:dx	= key string
		ss:bp	= PathName buffer		
RETURN:		carry set if couldn't obtain the path
		carry clear if could:
			ss:bp	= filled with path to file
			cx	= disk handle
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentFetchPathFromIniFile proc	near
		class	OLDocumentClass
category	local	INI_CATEGORY_BUFFER_SIZE dup(char)
		uses	es, di
		.enter
	;
	; Obtain the .ini file category from which to get the data.
	; 
		push	cx, dx
		lea	dx, ss:[category]
		mov	cx, ss
		mov	ax, MSG_META_GET_INI_CATEGORY
		call	GenCallApplication
		pop	cx, dx
	;
	; Have the category, now go for the data, fetching it into a block.
	; 
		push	ds, si, bp
		lea	si, ss:[category]
		segmov	ds, ss
		clr	bp
		call	InitFileReadData
		pop	bp
		jc	done		; => key not found
		
	;
	; Lock down the saved data and copy out the string that is the path,
	; stored at the block's start.
	; 
		call	MemLock
		mov	ds, ax
		clr	si
		mov	di, ss:[bp]
		segmov	es, ss
pathCopyLoop:
		LocalGetChar ax, dssi
		LocalPutChar esdi, ax
		LocalIsNull ax		; hit null-terminator?
		loopne	pathCopyLoop	; nope...
EC <		ERROR_NE	OL_DOCUMENT_PATH_STORED_INCORRECTLY	>
	;
	; ds:si = start of data for saved disk handle; restore the beast.
	; 
		call	UserDiskRestore
		jc	doneFree
		
		mov_tr	cx, ax		; return disk handle in CX
doneFree:
		lahf			; preserve error code
		call	MemFree		; free data block
		sahf
done:
		pop	ds, si
		.leave
		ret
OLDocumentFetchPathFromIniFile		endp

DocInit ends

;---

DocExit segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlDetach -- MSG_META_DETACH for
						OLDocumentControlClass

DESCRIPTION:	Detach UI document control by closing any documents that are
		children

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_META_DETACH

	cx - caller's ID
	dx:bp - OD for MSG_META_ACK

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (path is null) {
		set path to document directory
	}
	send MSG_META_DETACH to all children

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentControlDetach	method dynamic OLDocumentControlClass,
					MSG_META_DETACH

	; start the detach process

	push	ax, cx, dx, bp
	call	ObjInitDetach

	; force the current task to none

	call	OLDCRemoveSummons


	; force down the import and export dialog boxes

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	pushdw	ds:[di].GDCI_exportGroup
	movdw	cxdx, ds:[di].GDCI_importGroup
	call	removeCXDXFromWindowsList
	popdw	cxdx
	call	removeCXDXFromWindowsList

	mov	ax, MSG_META_DETACH
	mov	dx, ds:[LMBH_handle]
	mov	bp, si				;dx:bp = OD for ACK
	call	SendToAppDCRegs

	call	ObjIncDetach			;app dc will clear this

	pop	ax, cx, dx, bp
	mov	di, offset OLDocumentControlClass
	call	ObjCallSuperNoLock

	call	ObjEnableDetach

	ret

;---

removeCXDXFromWindowsList:
	push	si
	sub	sp, size GCNListParams
	mov	bp, sp
	movdw	ss:[bp].GCNLP_optr, cxdx
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ax, MSG_META_GCN_LIST_REMOVE
	clr	bx				; use current thread
	call	GeodeGetAppObject		; ^lbx:si = app object
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListParams
	pop	si
	retn

OLDocumentControlDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlAppShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shutdown the document control subsystem

CALLED BY:	MSG_META_APP_SHUTDOWN
PASS:		*ds:si	= OLDocumentControl object.
		cx	= caller's data
		^ldx:bp	= ack OD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentControlAppShutdown method dynamic OLDocumentControlClass, 
					    MSG_META_APP_SHUTDOWN
	uses	ax, cx, dx, bp
	.enter
	;
	; Begin counter for shutting down GenDocumentGroup and remaining
	; documents.
	; 
	call	ObjInitDetach

	; Release "Model" exclusive, which we grabbed back in MSG_META_ATTACH.
	;
	call	MetaReleaseModelExclLow
	
	;
	; Tell GenDocumentGroup to shut down.
	; 
	call	ObjIncDetach

	mov	dx, ds:[LMBH_handle]
	mov	bp, si			; ^ldx:bp <- od for SHUTDOWN_ACK
	call	SendToAppDCRegs

	.leave
	;
	; Let our superclass do what it must.
	; 
	mov	di, offset OLDocumentControlClass
	call	ObjCallSuperNoLock	
	;
	; Allow ourselves to finish shutdown, when appropriate.
	; 
	call	ObjEnableDetach
	ret
OLDocumentControlAppShutdown endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlQuit -- MSG_META_QUIT for
						OLDocumentControlClass

DESCRIPTION:	Handle a user request to quit.

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_META_DETACH

	cx:dx - OD for MSG_META_QUIT_ACK

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (path is null) {
		set path to document directory
	}
	send MSG_META_DETACH to all children

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentControlQuit	method dynamic OLDocumentControlClass, MSG_META_QUIT

	; save OD

	movdw	ds:[di].OLDCI_quitOD, cxdx

	mov	ax, MSG_META_QUIT
	call	SendToAppDCRegs

	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlQuit	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlQuitAck -- MSG_META_QUIT_ACK for
						OLDocumentControlClass

DESCRIPTION:	Handle a user request to quit.

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_META_QUIT_ACK

RETURN:
	cx - abort flag (non-zero if you want to abort the quit)

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (path is null) {
		set path to document directory
	}
	send MSG_META_DETACH to all children

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentControlQuitAck	method dynamic OLDocumentControlClass,
						MSG_META_QUIT_ACK
	; get OD and set it to 0

	clrdw	bxsi
	xchgdw	bxsi, ds:[di].OLDCI_quitOD

	; sent the MSG_META_QUIT_ACK on, passing the abort flag (cx)

	mov	ax, MSG_META_QUIT_ACK
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

OLDocumentControlQuitAck	endm

DocExit ends

;---

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for OLDocumentControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
OLDocumentControlGetInfo	method dynamic \
					OLDocumentControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset OLDC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret

OLDocumentControlGetInfo	endm

OLDC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SPECIFIC_UI or mask GCBF_CUSTOM_ENABLE_DISABLE \
	    		or mask GCBF_ALWAYS_UPDATE or \
			mask GCBF_ALWAYS_INTERACTABLE or \
			mask GCBF_IS_ON_ACTIVE_LIST,	; GCBI_flags
	OLDC_IniFileKey,		; GCBI_initFileKey
	OLDC_gcnList,			; GCBI_gcnList
	length OLDC_gcnList,		; GCBI_gcnCount
	OLDC_notifyTypeList,		; GCBI_notificationList
	length OLDC_notifyTypeList,	; GCBI_notificationCount
	OLDCName,			; GCBI_controllerName

	handle OLDocumentControlUI,	; GCBI_dupBlock
	OLDC_childList,			; GCBI_childList
	length OLDC_childList,		; GCBI_childCount
	OLDC_featuresList,		; GCBI_featuresList
	length OLDC_featuresList,	; GCBI_featuresCount
	OLDC_DEFAULT_FEATURES,		; GCBI_features

	handle OLDocumentControlToolboxUI, ; GCBI_toolBlock
	OLDC_toolList,			; GCBI_toolList
	length OLDC_toolList,		; GCBI_toolCount
	OLDC_toolFeaturesList,		; GCBI_toolFeaturesList
	length OLDC_toolFeaturesList,	; GCBI_toolFeaturesCount
	OLDC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if _FXIP
ControlInfoXIP	segment resource
endif

OLDC_IniFileKey	char	"documentControl", 0

OLDC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE>

OLDC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_DOCUMENT_CHANGE>

;---

OLDC_childList	GenControlChildInfo	\
	<offset NewTrigger, mask GDCF_NEW,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset OpenTrigger, mask GDCF_OPEN_CLOSE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset CloseTrigger, mask GDCF_OPEN_CLOSE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SaveTrigger, mask GDCF_SAVE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SaveAsTrigger, mask GDCF_SAVE_AS,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset BackupSubMenu, mask GDCF_QUICK_BACKUP,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset OptionsSubMenu, mask GDCF_COPY or \
				mask GDCF_EXPORT or \
				mask GDCF_REVERT or \
				mask GDCF_RENAME or \
				mask GDCF_EDIT_USER_NOTES or \
				mask GDCF_SET_TYPE or \
				mask GDCF_SET_PASSWORD or \
				mask GDCF_SAVE_AS_TEMPLATE or \
				mask GDCF_SET_EMPTY_DOCUMENT or \
				mask GDCF_SET_DEFAULT_DOCUMENT, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

OLDC_featuresList	GenControlFeaturesInfo	\
	<offset SetDefaultDocumentTrigger, SetDefaultDocumentName, 0>,
	<offset SetEmptyDocumentTrigger, SetEmptyDocumentName, 0>,
	<offset SaveAsTemplateTrigger, SaveAsTemplateName, 0>,
	<offset SetPasswordTrigger, SetPasswordName, 0>,
	<offset SetTypeTrigger, SetTypeName, 0>,
	<offset EditUserNotesTrigger, EditUserNotesName, 0>,
	<offset RenameTrigger, RenameName, 0>,
	<offset RevertTrigger, RevertName, 0>,
	<offset ExportTrigger, ExportName, 0>,
	<offset CopyMoveTriggers, CopyMoveName, 0>,
	<offset SaveAsTrigger, SaveAsName, 0>,
	<offset SaveTrigger, SaveName, 0>,
	<offset QuickBackupTrigger, QuickBackupName, 0>,
	<offset OpenTrigger, OpenCloseName, 0>,
	<offset NewTrigger, NewName, 0>

;---

OLDC_toolList	GenControlChildInfo	\
	<offset NewEmptyToolTrigger, mask GDCTF_NEW_EMPTY,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset OpenToolTrigger, mask GDCTF_OPEN,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset UseTemplateToolTrigger, mask GDCTF_USE_TEMPLATE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset CloseToolTrigger, mask GDCTF_CLOSE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SaveToolTrigger, mask GDCTF_SAVE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset QuickBackupToolTrigger, mask GDCTF_QUICK_BACKUP,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

OLDC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset QuickBackupToolTrigger, QuickBackupName, 0>,
	<offset SaveToolTrigger, SaveName, 0>,
	<offset CloseToolTrigger, CloseName, 0>,
	<offset OpenToolTrigger, OpenName, 0>,
	<offset UseTemplateToolTrigger, UseTemplateName, 0>,
	<offset NewEmptyToolTrigger, NewName, 0>

if _FXIP
ControlInfoXIP	ends
endif

if	ERROR_CHECK

AssertIsUIDocControl	proc	far	uses di, es
	.enter
	pushf

	call	GenCheckGenAssumption
	mov	di, segment GenDocumentControlClass
	mov	es, di
	mov	di, offset GenDocumentControlClass
	call	ObjIsObjectInClass
	ERROR_NC	OBJECT_NOT_A_GEN_UI_DOC_CONTROL

	popf
	.leave
	ret
AssertIsUIDocControl	endp

endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlScanFeatureHints --
		MSG_GEN_CONTROL_SCAN_FEATURE_HINTS for OLDocumentControlClass

DESCRIPTION:	Return feature flags

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

	cx - GenControlUIType
	dx:bp - GenControlScanInfo structure

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 3/92		Initial version
	chrisb	10/93		Removed code that nukes GDCF_NEW if a
				default document exists.
------------------------------------------------------------------------------@
OLDocumentControlScanFeatureHints	method dynamic	OLDocumentControlClass,
					 MSG_GEN_CONTROL_SCAN_FEATURE_HINTS

	; by the time we are called GenControl has already filled the structure

	pushdw	dxbp
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	dx, ds:[di].GDCI_attrs		;dx = attrs
	mov	bp, dx
	and	bp, mask GDCA_MODE		;bp = mode

if _DUI
	;
	; prohibit everything for _DUI, we have a custom setup
	;
	mov	ax, mask GDCFeatures
	mov	bx, mask GDCToolboxFeatures
else
	clr	ax			;ax = features to prohibit
	clr	bx			;bx = toolbox features to prohibit
endif

ifdef PRODUCT_WIN_DEMO
	ornf	ax, mask GDCF_SAVE or mask GDCF_SAVE_AS
	ornf	bx, mask GDCTF_SAVE
endif

	tst	ds:[di].GDCI_exportGroup.handle
	jnz	allowsExport
	ornf	ax, mask GDCF_EXPORT
allowsExport:

	mov	di, ds:[di].GDCI_features	;di = features

	; if viewer mode then make all editing things off-limits

	cmp	bp, GDCM_VIEWER shl offset GDCA_MODE
	jnz	notViewer
	ornf	ax, mask GDCF_NEW or mask GDCF_QUICK_BACKUP or \
		    mask GDCF_SAVE or mask GDCF_SAVE_AS or \
		    mask GDCF_COPY or mask GDCF_REVERT or mask GDCF_RENAME or \
		    mask GDCF_EDIT_USER_NOTES or mask GDCF_SET_TYPE or \
		    mask GDCF_SET_PASSWORD or mask GDCF_SET_EMPTY_DOCUMENT
	ornf	bx, mask GDCTF_NEW_EMPTY or mask GDCTF_USE_TEMPLATE or \
		    mask GDCTF_SAVE or mask GDCTF_QUICK_BACKUP
notViewer:

	; if no backup then don't allow "save as" and "revert"

	test	dx, mask GDCA_SUPPORTS_SAVE_AS_REVERT
	jnz	allowsBackup
	ornf	ax, mask GDCF_SAVE_AS or mask GDCF_REVERT
allowsBackup:

	; disallow various stuff if not supported

	test	dx, mask GDCA_VM_FILE
	jnz	afterNotGeos
	ornf	ax, mask GDCF_EDIT_USER_NOTES or mask GDCF_SET_PASSWORD
afterNotGeos:
	test	di, mask GDCF_SUPPORTS_USER_SETTABLE_EMPTY_DOCUMENT
	jnz	afterEmpty
	ornf	ax, mask GDCF_SET_EMPTY_DOCUMENT
afterEmpty:
	test	di, mask GDCF_SUPPORTS_TEMPLATES
	jnz	afterTemplates
	ornf	ax, mask GDCF_SAVE_AS_TEMPLATE
	ornf	bx, mask GDCTF_USE_TEMPLATE
afterTemplates:
	test	di, mask GDCF_SUPPORTS_USER_SETTABLE_DEFAULT_DOCUMENT
	jnz	afterDefault
	ornf	ax, mask GDCF_SET_DEFAULT_DOCUMENT
afterDefault:

	popdw	dssi

	; ax = normal features to prohibit
	; bx = tool features to prohibit

	push	es
	segmov	es, dgroup, dx			;es = dgroup
	; calculate the required features
	mov	dx, mask GDCF_NEW or mask GDCF_OPEN_CLOSE or mask GDCF_SAVE
							;assume not transparent
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es			
	jz	common

	; transparent doc...
	push	es
	segmov	es, dgroup, dx			;es = dgroup
	mov	dx, mask GDCF_NEW or mask GDCF_SAVE
						; assume confirm save
	test	es:[docControlOptions], mask DCO_USER_CONFIRM_SAVE
	pop	es
	jnz	standardTransparent		

	; prohibit user save

	ornf	ax, mask GDCF_SAVE_AS or mask GDCF_REVERT
	mov	dx, mask GDCF_NEW

standardTransparent:
	ornf	bx, mask GDCTF_OPEN or mask GDCTF_CLOSE or mask GDCTF_SAVE \
		    or mask GDCTF_USE_TEMPLATE	;prohibit these
common:
	; turn off New/Open..., Close, and Save As for single document
	; unless DCO_SINGLE_DOCUMENT_OVERRIDE
	test	di, mask GDCF_SINGLE_DOCUMENT
	jz	notSingleDocument
	push	ax, es
	segmov	es, dgroup, ax
	test	es:[docControlOptions], mask DCO_SINGLE_DOCUMENT_OVERRIDE
	pop	ax, es
	jnz	notSingleDocument
	andnf	dx, not (mask GDCF_NEW or mask GDCF_OPEN_CLOSE or mask GDCF_SAVE_AS)
notSingleDocument:

	; dx = required normal features

	cmp	cx, GCUIT_NORMAL
	je	normalFeatures

	; *** toolbox ***

	ornf	ds:[si].GCSI_appProhibited, bx
	jmp	done

	; *** normal ***

normalFeatures:
	ornf	ds:[si].GCSI_appProhibited, ax
	ornf	ds:[si].GCSI_appRequired, dx

done:
	ret

OLDocumentControlScanFeatureHints	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for OLDocumentControlClass

DESCRIPTION:	Update the UI for the document control

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentControlUpdateUI	method dynamic OLDocumentControlClass,
					MSG_GEN_CONTROL_UPDATE_UI

	; lock data block and set our instance data as needed

	push	si
	mov	bx, ss:[bp].GCUUIP_dataBlock
	clr	ax
	clr	cx
	clr	dx
	push	dx
	tst	bx
	jz	gotFlags

	pop	dx
	call	MemLock
	mov	es, ax
	mov	ax, es:NDC_attrs
	mov	cx, es:NDC_type
	mov	dx, es:NDC_fileHandle
	push	{word} es:NDC_emptyExists
	call	MemUnlock
gotFlags:
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDCI_docAttrs, ax
	mov	ds:[di].GDCI_docType, cx
	mov	ds:[di].GDCI_docFileHandle, dx
	pop	{word} ds:[di].GDCI_emptyExists

	mov	ax, ss:[bp].GCUUIP_features
	or	ax, ss:[bp].GCUUIP_toolboxFeatures
	LONG jz	done

	call	GenerateEnabledFlags			;ax = features
							;bl = "close"
							;cx = toolbox features
	push	cx
	push	ax

	; handle copy specially

	test	ss:[bp].GCUUIP_features, mask GDCF_COPY
	jz	afterCopy
	test	ax, mask GDCF_COPY
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	4$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
4$:
	push	bx, si
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset MoveTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	; do the Copy Trigger too.  not sure why this was left out jfh 11/17/03
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset CopyTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, si

afterCopy:

	; handle "revert quick backup" specially

	test	ss:[bp].GCUUIP_features, mask GDCF_QUICK_BACKUP
	jz	afterRevertQuick
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDCI_docAttrs, mask GDA_BACKUP_EXISTS
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	5$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
5$:
	push	bx, si
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset RecoverFromQuickBackupTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, si
afterRevertQuick:

	; handle close specially

	test	ss:[bp].GCUUIP_features, mask GDCF_OPEN_CLOSE
	jz	afterClose
	mov	ax, MSG_GEN_SET_ENABLED
	tst	bl
	jnz	6$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
6$:
	push	si
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset CloseTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
afterClose:

	; handle clear empty specially

	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ss:[bp].GCUUIP_features, mask GDCF_SET_EMPTY_DOCUMENT
	jz	afterEmpty
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GDCI_emptyExists
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	7$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
7$:
	push	si
	mov	si, offset ClearEmptyDocumentTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
afterEmpty:

	; handle clear default specially

	test	ss:[bp].GCUUIP_features, mask GDCF_SET_DEFAULT_DOCUMENT
	jz	afterDefault
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GDCI_defaultExists
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	8$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
8$:
	push	si
	mov	si, offset ClearDefaultDocumentTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
afterDefault:


	pop	ax

	; features

	mov	dx, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	di, offset triggerTable
	mov	cx, length triggerTable
	call	enableLoop

	; toolbox features

	pop	ax
	mov	dx, ss:[bp].GCUUIP_toolboxFeatures
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	di, offset toolTriggerTable
	mov	cx, length toolTriggerTable
	call	enableLoop

done:
	pop	si
	mov	ax, MSG_OLDC_TEST_FOR_DISPLAY_MAIN_DIALOG
	GOTO	ObjCallInstanceNoLock

;---

	;cs:di = table
	;cx = length
	;ax = features enabled
	;dx = features existing
	;bx = block

enableLoop:
	tst	bx
	jz	enableLoopDone
	shr	dx
	push	ax, dx
	jnc	next
	shr	ax
	mov	ax, MSG_GEN_SET_ENABLED
	jc	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	dl, VUM_NOW
	mov	si, cs:[di]
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
next:
	pop	ax, dx
	shr	ax
	add	di, size word
	loop	enableLoop
enableLoopDone:
	retn

OLDocumentControlUpdateUI	endm

triggerTable	word	\
	offset SetDefaultDocumentTrigger,
	offset SetEmptyDocumentTrigger,
	offset SaveAsTemplateTrigger,
	offset SetPasswordTrigger,
	offset SetTypeTrigger,
	offset EditUserNotesTrigger,
	offset RenameTrigger,
	offset RevertTrigger,
	offset ExportTrigger,
	offset CopyMoveTriggers,
	offset SaveAsTrigger,
	offset SaveTrigger,
	offset QuickBackupTrigger,
	offset OpenTrigger,
	offset NewTrigger

toolTriggerTable	word	\
	offset QuickBackupToolTrigger,
	offset SaveToolTrigger,
	offset CloseToolTrigger,
	offset OpenToolTrigger,
	offset UseTemplateToolTrigger,
	offset NewEmptyToolTrigger

COMMENT @----------------------------------------------------------------------

FUNCTION:	GenerateEnabledFlags

DESCRIPTION:	Generate flags for whether stuff is enabled

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

RETURN:
	ax - feature flags
	bx - close state
	cx - toolbox feature flags

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/30/92		Initial version

------------------------------------------------------------------------------@
GenerateEnabledFlags	proc	far	uses dx, si, bp
	class	OLDocumentControlClass
	.enter

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	dx, ds:[di].GDCI_attrs		;dx = attrs
	mov	bp, ds:[di].GDCI_docAttrs
	mov	si, ds:[di].GDCI_features	;si = features

	mov	ax, seg dgroup
	mov	es, ax

	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	jz	notTranparentMode
	mov	ax, mask GDCF_NEW or mask GDCF_QUICK_BACKUP
	clr	bx
	mov	cx, mask GDCToolboxFeatures
	jmp	noAllowNewOpen

notTranparentMode:

	clr	ax
	clr	bx
	clr	cx

	; multiple files allowed ?

	test	dx, mask GDCA_MULTIPLE_OPEN_FILES
	jnz	allowNewOpen

	; no multiple files, are there any existing ?

	test	dx, mask GDCA_DOCUMENT_EXISTS
	jz	allowNewOpen

	; if the file is not dirty, allow new and open, even if multiple
	; documents are not allowed

	test	si, mask GDCF_SINGLE_FILE_CLEAN_CAN_NEW_OPEN
	jz	noAllowNewOpen
	test	bp, mask GDA_DIRTY
	jnz	noAllowNewOpen
allowNewOpen:

	; Limit number of documents that can be opened.


	; a file can be opened

	ornf	ax, mask GDCF_NEW or mask GDCF_OPEN_CLOSE
	ornf	cx, mask GDCTF_NEW_EMPTY or mask GDCTF_OPEN or \
		    mask GDCTF_USE_TEMPLATE
noAllowNewOpen:

	; does a document exist ?

	test	dx, mask GDCA_DOCUMENT_EXISTS
	jz	noTargetDoc

	ornf	ax, mask GDCF_SET_EMPTY_DOCUMENT or \
		    mask GDCF_SET_DEFAULT_DOCUMENT

	; deal with various attribute changes
	; rename enabled in writable, !multiUser, (!readOnly or !dirty), !untit

	test	bp, mask GDA_ON_WRITABLE_MEDIA 
	jz	noAttrChange
	test	bp, mask GDA_UNTITLED or mask GDA_SHARED_MULTIPLE
	jnz	noAttrChange

	; The type of a document opened read-only can only be changed if the
	; document is really read-only

	test	bp, mask GDA_READ_ONLY
	jz	canChangeType
	test	bp, mask GDA_DIRTY		;dirty read-only documents
	jnz	afterChangeType			;cannot change type
	cmp	ds:[di].GDCI_docType, GDT_READ_ONLY
	jnz	afterChangeType
canChangeType:
	ornf	ax, mask GDCF_SET_TYPE
afterChangeType:

	test	bp, mask GDA_READ_ONLY
	jnz	noAttrChange
	ornf	ax, mask GDCF_EDIT_USER_NOTES or mask GDCF_SET_PASSWORD or \
		mask GDCF_RENAME
noAttrChange:

	; a target document exists

	;	save and revert require the document be dirty
	;	save, save as and revert require the document be not readOnly
	;	if (!multiple files && !dirty && tempName) -> allow open

	ornf	ax, mask GDCF_QUICK_BACKUP or mask GDCF_SAVE_AS or \
		    mask GDCF_COPY or mask GDCF_EXPORT or \
		    mask GDCF_SAVE_AS_TEMPLATE
	mov	bl, 1				;save enabled
	ornf	cx, mask GDCTF_CLOSE or mask GDCTF_QUICK_BACKUP

	test	bp, mask GDA_SHARED_MULTIPLE
	jnz	notDirty
	test	bp, mask GDA_DIRTY
	jz	notDirty
	ornf	ax, mask GDCF_SAVE or mask GDCF_REVERT
	ornf	cx, mask GDCTF_SAVE
	;
	; If "save" failed, then revert is not possible
	;
	test	bp, mask GDA_SAVE_FAILED
	jz	notDirty
	andnf	ax, not mask GDCF_REVERT
notDirty:

	;
	; Read-only files cannot be saved
	; Editable read-only files can be reverted and save-as'ed
	;
	test	bp, mask GDA_READ_ONLY
	jz	notReadOnly

	test	si, mask GDCF_READ_ONLY_SUPPORTS_SAVE_AS_REVERT
	jnz	noTargetDoc

	andnf	ax, not (mask GDCF_SAVE or mask GDCF_SAVE_AS or \
			 mask GDCF_REVERT)
	andnf	cx, not mask GDCTF_SAVE
notReadOnly:

noTargetDoc:

	.leave
	ret

GenerateEnabledFlags	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlGenerateUI --
		MSG_GEN_CONTROL_GENERATE_UI for OLDocumentControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	This method handler exists only because this can't be done in the
	TWEAK handler -- the GenControl itself may set the Open trigger 
	USABLE after the TWEAK handler is called, thereby undoing any
	SET_NOT_USABLE.  So, alas, we still have to intercept
	MSG_GEN_CONTROL_GENERATE_UI.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/12/92		Initial version
	Doug	1/93		Moved most to TWEAK handler. 

------------------------------------------------------------------------------@
OLDocumentControlGenerateUI	method dynamic	OLDocumentControlClass,
					MSG_GEN_CONTROL_GENERATE_UI

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarFindData
	mov	bp, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock

	test	bp, mask GDCF_OPEN_CLOSE
	jz	afterOpen
	segmov	es, dgroup, si			;es = dgroup
	test	es:[docControlOptions], mask DCO_HAVE_FILE_OPEN
	jnz	afterOpen
	mov	si, offset OpenTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjMessage
afterOpen:

	ret
OLDocumentControlGenerateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Modify duplicated UI as needed

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI

		cx	- block
		dx	- features

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	1/93		Initial version
	martin	8/3/93		Added DCO_NO_DOC_PASSWORD

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLDocumentControlTweakDuplicatedUI	method dynamic	OLDocumentControlClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	push	es
	segmov	es, dgroup, bp			;es = dgroup
	mov	bp, dx		; bp - features
	mov	bx, cx		; bx - block

	; if in transparent mode then switch "New" to "Switch Document"
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es
	jz	afterNew
	test	bp, mask GDCF_NEW
	jz	afterNew
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	si, offset NewTrigger
	mov	cx, offset SwitchDocumentMoniker
	call	sendMessage
afterNew:
	;
	; Enable document passwords if appropriate
	;
	push	es, si
	segmov	es, dgroup, si			; es = dgroup
	test	es:[docControlOptions], mask DCO_NO_DOC_PASSWORD
	pop	es, si
	jz	afterOptions
	mov	si, offset SetPasswordTrigger
	call	setNotUsable

afterOptions:
;	Change the "Other" submenu from a submenu to a subgroup, if it
;	exists, and if the option is set
	push	es, ax
	segmov	es, dgroup, ax
	test	es:[docControlOptions], mask DCO_NO_OTHER_SUBMENU
	pop	es, ax
	jz	afterOptionsSubMenu
	test	bp,mask GDCF_COPY or \
				mask GDCF_EXPORT or \
				mask GDCF_REVERT or \
				mask GDCF_RENAME or \
				mask GDCF_EDIT_USER_NOTES or \
				mask GDCF_SET_TYPE or \
				mask GDCF_SET_PASSWORD or \
				mask GDCF_SAVE_AS_TEMPLATE or \
				mask GDCF_SET_EMPTY_DOCUMENT or \
				mask GDCF_SET_DEFAULT_DOCUMENT
	jz	afterOptionsSubMenu
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	si, offset OptionsSubMenu
	mov	cl, GIV_SUB_GROUP
	call	sendMessage

afterOptionsSubMenu:

	; nuke the Empty sub-menu if it exists but is not needed

	test	bp, mask GDCF_COPY or \
		    mask GDCF_EXPORT or \
		    mask GDCF_REVERT or \
		    mask GDCF_RENAME or \
		    mask GDCF_EDIT_USER_NOTES or \
		    mask GDCF_SET_TYPE or \
		    mask GDCF_SET_PASSWORD or \
		    mask GDCF_SAVE_AS_TEMPLATE or \
		    mask GDCF_SET_EMPTY_DOCUMENT or \
		    mask GDCF_SET_DEFAULT_DOCUMENT
	jz	afterEmptyMenu
	test	bp, mask GDCF_SET_EMPTY_DOCUMENT or \
		    mask GDCF_SET_DEFAULT_DOCUMENT
	jnz	afterEmptyMenu
	mov	si, offset OptionsEmptyPopup
	call	setNotUsable
afterEmptyMenu:

	ret

;---

setNotUsable:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
sendMessage:
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	retn

OLDocumentControlTweakDuplicatedUI	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlGetAttrs --
	MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS for OLDocumentControlClass

DESCRIPTION:	Get the DocumentControlAttrs

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS

RETURN:
	ax - GenDocumentControlAttrs
	cx, dx, bp - unchanged

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentControlGetAttrs	method OLDocumentControlClass,
					MSG_GEN_DOCUMENT_CONTROL_GET_ATTRS

	push	di
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDCI_attrs
	pop	di
	ret

OLDocumentControlGetAttrs	endm

;---
OLDocumentControlGetFeatures	method OLDocumentControlClass,
					MSG_GEN_DOCUMENT_CONTROL_GET_FEATURES

	push	di
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDCI_features
	pop	di
	ret

OLDocumentControlGetFeatures	endm

;---

SendToTargetDocRegs	proc	far	uses di
	.enter

	mov	di, mask MF_RECORD
	call	SendToTargetCommon

	.leave
	ret

SendToTargetDocRegs	endp

;---

SendToTargetCommon	proc	far	uses ax, cx, dx, bp
	.enter

	push	bx, si
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	call	ObjMessage		;di = message
	pop	bx, si

	mov	cx, di
	mov	dx, TO_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	ObjCallInstanceNoLock

	.leave
	ret

SendToTargetCommon	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlSendClassedEvent

DESCRIPTION:	Relays all messages destined for owner of Model excl to app DC

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_META_DELIVER_SEND_EVENT

	cx	- handle of classed event
	dx	- TargetObject

RETURN:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

------------------------------------------------------------------------------@
OLDocumentControlSendClassedEvent	method	OLDocumentControlClass,
						MSG_META_SEND_CLASSED_EVENT

	cmp	dx, TO_MODEL
	je	sendToAppDocumentControl

	mov	di, offset OLDocumentControlClass
	GOTO	ObjCallSuperNoLock

sendToAppDocumentControl:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDCI_documentGroup.handle
	mov	bp, ds:[di].GDCI_documentGroup.chunk
	clr	di
	call	FlowDispatchSendOnOrDestroyClassedEvent

	Destroy	ax, cx, dx, bp
	ret

OLDocumentControlSendClassedEvent	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToAppDCFrame

DESCRIPTION:	Send a method (with data on the stack) to the associated app
		document control

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocumentControl
	ax - method
	cx, dx, bp - parameters

RETURN:
	from method

DESTROYED:
	from method

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SendToAppDCFrame	proc	far	uses di
	.enter

EC <	call	AssertIsUIDocControl					>

	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	SendToAppDCCommon

	.leave
	ret

SendToAppDCFrame	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToAppDCRegs

DESCRIPTION:	Send a method to the associated app document control

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocumentControl
	ax - method
	cx, dx, bp - parameters

RETURN:
	from method

DESTROYED:
	from method

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SendToAppDCRegs	proc	far	uses bx, si, di
	.enter

EC <	call	AssertIsUIDocControl					>

	mov	di, mask MF_FIXUP_DS
	call	SendToAppDCCommon

	.leave
	ret

SendToAppDCRegs	endp

;-------

SendToAppDCCommonFar	proc	far
	call	SendToAppDCCommon
	ret
SendToAppDCCommonFar	endp

SendToAppDCCommon	proc	near	uses bx, si
	class	GenDocumentControlClass
	.enter

EC <	call	AssertIsUIDocControl					>

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	mov	bx, ds:[si].GDCI_documentGroup.handle
	mov	si, ds:[si].GDCI_documentGroup.chunk
	call	ObjMessage

	.leave
	ret

SendToAppDCCommon	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlVupAlterFTVMCExcl

DESCRIPTION:	Re-route message which normally travels up visual tree
		to our generic parent, since we're not in the visual tree.

PASS:		*ds:si 	- instance data
		es     	- segment of class
		ax 	- MSG_META_MUP_ALTER_FTVMC_EXCL
		^lcx:dx	- object making request
		bp	- OLDocumentControlAlterExclFlags

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	10/91		Initial Version

------------------------------------------------------------------------------@

; This isn't needed, as the default handler sends MODEL alterations up the
; generic linkage anyway. -- In fact, now that we're a controller, this is
; downright wrong, as we now *are* in the visual tree when build out,
; & triggers below should be getting the focus from the first *visible* node
; up the tree.  (We've been lucky in that VisParent = GenParent here to date)
; -- Doug 2/5/93
;
;OLDocumentControlVupAlterFTVMCExcl method dynamic OLDocumentControlClass,
;				MSG_META_MUP_ALTER_FTVMC_EXCL
;
;	and	bp, not mask MAEF_NOT_HERE	; clear "not here" flag, since
;						; we're safely past the first
;						; object
;	GOTO	GenCallParent
;
;OLDocumentControlVupAlterFTVMCExcl	endm

OLDocumentControlChangedModelExcl method dynamic OLDocumentControlClass,
				MSG_META_GAINED_MODEL_EXCL,
				MSG_META_LOST_MODEL_EXCL,
				MSG_META_GAINED_SYS_MODEL_EXCL,
				MSG_META_LOST_SYS_MODEL_EXCL
	GOTO	SendToAppDCRegs
OLDocumentControlChangedModelExcl	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlGetTemplateDir --
		MSG_GEN_DOCUMENT_CONTROL_GET_TEMPLATE_DIR
					for OLDocumentControlClass

DESCRIPTION:	Get the template directory

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

	cxdx - buffer

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 7/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlGetTemplateDir	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_GET_TEMPLATE_DIR

EC <	call	GenCheckGenAssumption					>

if	not _USE_DESIGN_ASSISTANT_FOR_TEMPLATES or _NDO2000
	call	EnsureTemplateDir
endif
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, ds:[di].GDCI_templateDir	;dssi = source
	movdw	esdi, cxdx			;esdi = dest
SBCS <	mov	{char} es:[di], 0					>
DBCS <	mov	{wchar} es:[di], 0					>
if	not _USE_DESIGN_ASSISTANT_FOR_TEMPLATES or _NDO2000
	tst	si
	jz	done
	mov	si, ds:[si]
SBCS <	clr	ax							>
copyLoop:
	LocalGetChar ax, dssi
	LocalPutChar esdi, ax
	LocalIsNull ax
	jnz	copyLoop
done:
endif
	ret

OLDocumentControlGetTemplateDir	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	EnsureTemplateDir

DESCRIPTION:	Ensure that a template directory exists

CALLED BY:	INTERNAL

PASS:
	*ds:si - document control

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 7/93		Initial version

------------------------------------------------------------------------------@
if	not _USE_DESIGN_ASSISTANT_FOR_TEMPLATES or _NDO2000
EnsureTemplateDir	proc	far	uses ax, bx, cx, dx, di
	class	OLDocumentControlClass
	.enter
EC <	call	AssertIsUIDocControl					>

	mov	ax, TEMP_OLDC_TEMPLATE_DIR_ENSURED
	call	ObjVarFindData
	jc	done
	clr	cx
	call	ObjVarAddData

	call	FilePushDir
	mov	ax, SP_TEMPLATE
	call	FileSetStandardPath
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GDCI_templateDir
	tst	di
	jz	templateDone
	mov	dx, ds:[di]
	call	FileCreateDir
templateDone:
	call	FilePopDir

done:
	.leave
	ret
EnsureTemplateDir	endp
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlEnableDisable --
		MSG_GEN_CONTROL_ENABLE_DISABLE for OLDocumentControlClass

DESCRIPTION:	Enable/disable stuff as needed

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

	cx - message: MSG_GEN_SET_ENABLED or MSG_GEN_SET_NOT_ENABLED
	dl - VisualUpdateMode

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 1/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlEnableDisable method dynamic OLDocumentControlClass,
						MSG_GEN_CONTROL_ENABLE_DISABLE

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GDCI_attrs, mask GDCA_DOCUMENT_EXISTS
	cmp	cx, MSG_GEN_SET_ENABLED
	jz	checkDialog

	; we're disabling -- we must also clearout the file name
	andnf	ds:[di].GDCI_attrs, not mask GDCA_DOCUMENT_EXISTS
	push	cx, dx
	sub	sp, size DocumentFileChangedParams
	mov	bp, sp
	mov	ss:[bp].DFCP_name[0], 0
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_FILE_CHANGED
	call	ObjCallInstanceNoLock
	add	sp, size DocumentFileChangedParams
	pop	cx, dx
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

10$:
	mov_tr	ax, cx				;ax = message

	mov	di, ds:[di].GDCI_enableDisableList
	tst	di
	jz	done
	clr	bp
	ChunkSizeHandle	ds, di, cx
	jcxz	done
	shr	cx
	shr	cx				;get number of optrs
sendLoop:
	push	cx, di
	mov	di, ds:[di]
	add	di, bp

	; the optrs in the list are unrelocated -- we must handle this

	push	ax
	mov	bx, ds:[LMBH_handle]
	mov	cx, ds:[di].handle
	mov	al, RELOC_HANDLE
	call	ObjDoRelocation
	pop	ax
	mov	bx, cx

	mov	si, ds:[di].chunk
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, di
	add	bp, size optr
	loop	sendLoop

done:
	Destroy	ax, cx, dx, bp

	ret

checkDialog:
	;
	; If setting enabled and have main dialog up, take it down and
	; switch curren task to none.
	; 
	mov	ax, ds:[di].GDCI_attrs
	andnf	ax, mask GDCA_CURRENT_TASK
	cmp	ax, GDCT_DIALOG shl offset GDCA_CURRENT_TASK
	jne	10$

	call	OLDCRemoveSummons
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
		CheckHack <GDCT_NONE eq 0>
	andnf	ds:[di].GDCI_attrs, not mask GDCA_CURRENT_TASK
	jmp	10$

OLDocumentControlEnableDisable	endm

DocCommon ends

;---

DocMisc segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlRebuildNormalUI --
		MSG_GEN_CONTROL_REBUILD_NORMAL_UI for OLDocumentControlClass

DESCRIPTION:	Check for redoing the main dialog when rebuilding UI

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

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
	Tony	10/27/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlRebuildNormalUI	method dynamic	OLDocumentControlClass,
					MSG_GEN_CONTROL_REBUILD_NORMAL_UI

	call	OLDCRemoveSummons

	mov	di, offset OLDocumentControlClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_OLDC_REMOVE_OLD_AND_TEST_FOR_DISPLAY_MAIN_DIALOG
	GOTO	ObjCallInstanceNoLock

OLDocumentControlRebuildNormalUI	endm

DocMisc ends

;---

DocNewOpen segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentControlFileChanged --
		MSG_GEN_DOCUMENT_CONTROL_FILE_CHANGED
				for OLDocumentControlClass

DESCRIPTION:	Handle notification that the file has changed

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - The message

	ss:bp - DocumentFileChangedParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/ 1/92		Initial version

------------------------------------------------------------------------------@
OLDocumentControlFileChanged	method dynamic	OLDocumentControlClass,
				MSG_GEN_DOCUMENT_CONTROL_FILE_CHANGED

	; get the long term moniker

	; copy name & path to instance data (for file selectors)

	cmp	ss:[bp].DFCP_name[0], 0
	jz	noCopyToFileSelector

	push	bp
	lea	dx, ss:[bp].DFCP_path
	mov	cx, ss
	mov	bp, ss:[bp].DFCP_diskHandle
	mov	ax, MSG_GEN_PATH_SET
	call	ObjCallInstanceNoLock
	pop	bp
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	push	si, ds
	segmov	es, ds
	lea	di, ds:[di].GDCI_targetDocName
	segmov	ds, ss
	lea	si, ss:[bp].DFCP_name
	mov	cx, length GDCI_targetDocName
	LocalCopyNString			;rep movsb/movsw
	pop	si, ds

noCopyToFileSelector:
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset

	tst	ss:[bp].DFCP_display.handle
if _DUI
	;
	; in _DUI we update both the display and the primary name
	;
	jz	updatePrimary
	call	updateDisplay
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
updatePrimary:
else
	jnz	updateDisplay
endif
	test	ds:[di].GDCI_features, mask GDCF_NAME_ON_PRIMARY
	jz	done

	; display document name if GDGA_DISPLAY_NAME

	cmp	ss:[bp].DFCP_name[0], 0
if _DUI
	mov	dl, VMDT_TEXT			; moniker type
endif
	jnz	gotName

	; copy "no file" name out

if _DUI
	;
	; just clear long term moniker for DUI
	;
	mov	dl, VMDT_NULL
else
	push	bp
	mov	cx, ss				;cx:dx = destination
	mov	dx, bp
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bp, ds:[di].GDCI_noNameText
EC <	tst	bp							>
EC <	ERROR_Z OLDC_MUST_HAVE_NO_NAME_TEXT				>
	clr	ax				;copy entire chunk
	clr	di
	call	UserCopyChunkOut
	pop	bp
endif
gotName:

	mov	ax, bp
	sub	sp, size ReplaceVisMonikerFrame
	mov	bp, sp
	mov	ss:[bp].RVMF_source.segment, ss
	mov	ss:[bp].RVMF_source.offset, ax
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
if _DUI
	mov	ss:[bp].RVMF_dataType, dl	; store moniker type
else
	mov	ss:[bp].RVMF_dataType, VMDT_TEXT
endif
	mov	ss:[bp].RVMF_length, 0		; null-terminated
	mov	ss:[bp].RVMF_updateMode, VUM_NOW
	mov	dx, size ReplaceVisMonikerFrame
 	mov	ax, MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER
	mov	di, mask MF_RECORD or mask MF_STACK
	push	si
	mov	bx, segment GenPrimaryClass
	mov	si, offset GenPrimaryClass
	call	ObjMessage
	pop	si
	add	sp, size ReplaceVisMonikerFrame

	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent			;call the primary -- returns
						;ax = new chunk
done:
	ret

	; update the associated GenDisplay

if _DUI
updateDisplay	label	far
else
updateDisplay:
endif
	cmp	ss:[bp].DFCP_name[0], 0
	jz	done

	push	si
	mov	bx, ss:[bp].DFCP_display.handle
	mov	si, ss:[bp].DFCP_display.chunk
	mov	ax, MSG_GEN_DISPLAY_UPDATE_FROM_DOCUMENT
	mov	dx, size DocumentFileChangedParams
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	ret

OLDocumentControlFileChanged	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlGetToken --
		MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN
						for OLDocumentControlClass

DESCRIPTION:	Get the token

PASS:
	*ds:si - instance data
	es - segment of OLDocumentControlClass

	ax - MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN
	cx:dx - address to store token

RETURN:
	cx, dx, bp - unchanged

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentControlGetToken	method dynamic OLDocumentControlClass,
					MSG_GEN_DOCUMENT_CONTROL_GET_TOKEN

	mov	ax, offset GDCI_documentToken
	mov	si, ds:[si]			;ds:si = source
	add	si, ds:[si].Gen_offset
	add	si, ax

	mov	es, cx				;es:di = dest
	mov	di, dx

	push	cx
	mov	cx, size GeodeToken
	rep	movsb
	pop	cx

	ret

OLDocumentControlGetToken	endm

DocNewOpen ends

;---

DocNew segment resource

OLDocumentControlGetCreator	method dynamic OLDocumentControlClass,
					MSG_GEN_DOCUMENT_CONTROL_GET_CREATOR

	;
	; Return the token of the app that owns us.
	; 
	mov	es, cx
	mov	di, dx
	mov	bx, ds:[LMBH_handle]
	call	MemOwner
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo

	ret

OLDocumentControlGetCreator	endm

DocNew ends

;---

DocSaveAsClose segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToTargetDocFrame

DESCRIPTION:	Send a message to the target document

CALLED BY:	INTERNAL

PASS:
	ax - message
	ss:bp - paramters

RETURN:
	none

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 4/92		Initial version

------------------------------------------------------------------------------@
SendToTargetDocFrame	proc	far	uses di
	.enter

	mov	di, mask MF_RECORD or mask MF_STACK
	call	SendToTargetCommon

	.leave
	ret

SendToTargetDocFrame	endp

DocSaveAsClose ends

;---

DocObscure segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentControlGetModelExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the model exclusive for this app.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		cx:dx - model object
		carry set
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentControlGetModelExcl	method	OLDocumentControlClass, 
				MSG_META_GET_MODEL_EXCL
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	cxdx, ds:[di].GDCI_documentGroup
	stc
	.leave
	ret
OLDocumentControlGetModelExcl	endp





COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentControlQuerySaveDocuments -- 
		MSG_META_QUERY_SAVE_DOCUMENTS for OLDocumentControlClass

DESCRIPTION:	Save documents on an app switch.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_QUERY_SAVE_DOCUMENTS
		cx	- event

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/26/93         	Initial Version

------------------------------------------------------------------------------@

if VOLATILE_SYSTEM_STATE

OLDocumentControlQuerySaveDocuments method dynamic OLDocumentControlClass, \
					MSG_META_QUERY_SAVE_DOCUMENTS

	push	ax, cx
	mov	ax, MSG_META_GET_MODEL_EXCL
	call	ObjCallInstanceNoLock		;in ^lcx:dx, no doubt
	movdw	bxsi, cxdx			;send on to document control
	pop	ax, cx

	tst	si				;no model, we'll give up and
	jz	returnQuery			; allow app switching.

	clr	di				;else send on to model
	GOTO	ObjMessage

returnQuery:
	mov	bx, cx
	mov	di, mask MF_FORCE_QUEUE		
	call	MessageDispatch	
	ret
OLDocumentControlQuerySaveDocuments	endm

endif

DocObscure ends


