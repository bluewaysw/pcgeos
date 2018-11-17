COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cprocessLoadApp.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/15/92   	Initial version.

DESCRIPTION:
	

	$Id: cmainLoadApp.asm,v 1.2 98/06/03 13:38:33 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------

FixedCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopLoadApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call UserLoadApplication 

CALLED BY:	MSG_LOAD_APPLICATION

PASS:		dx - AppLaunchBlock
		cx - LoadAppData block (filename block in case error
					reporting is needed)

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/26/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DesktopLoadApplication	method	DesktopClass, MSG_DESKTOP_LOAD_APPLICATION
	call	ShowHourglass


	
	
	;
	; Lock down LoadAppData anf save the token away, unlocking the block
	; so it doesn't get in the way of loading the app, if it needs loading.
	; 
	push	cx				; save filename block

	mov	bx, cx
	call	MemLock
	mov	es, ax
	push	es:[LAD_token].GT_manufID,
		{word}es:[LAD_token].GT_chars[2],
		{word}es:[LAD_token].GT_chars[0]
	call	MemUnlock

	call	GetLoadAppGenParent		; stuff ALB_genParent

	;
	; we need to know if we are launching an app or a datafile
	;
	mov	bx, dx
	call	MemLock
	mov	es, ax
	mov	si, {word} es:[ALB_dataFile]	; get first word of dataFile
	call	MemUnlock			;  save it in si for error case

	;
	; Connect to the server, telling IACP to create it if it's not there.
	; 
	segmov	es, ss
	mov	di, sp
	mov	ax, mask IACPCF_FIRST_ONLY or mask IACPCF_OBEY_LAUNCH_MODEL or \
			(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	call	IACPConnect
	lea	sp, es:[di+size GeodeToken]
	jc	error

	mov	si, bx				; si = owner of server
	
	;
	; The connection is sufficient for our purposes. If it was running and
	; there was no document in the ALB, the app will raise itself to the
	; top. If there was a document, it will open it and raise it and the
	; app to the top.
	; 
	clr	cx, dx				; shutting down the client.
	call	IACPShutdown

	mov_tr	cx, bx				; CX - new app's proc handle
	pop	bx				; retrieve filename block
	call	MemFree				; free error filename block

	;
	; Check if we just started ourselves.  If so, don't MinimizeIfDesired.
	;	si = owner of server
	;
	cmp	si, handle 0
	je	noMin				; yes, don't minimize

	;
	; minimize File Manager, if user option set
	;
	call	MinimizeIfDesired
noMin:
	call	HideHourglass
	ret

error:
	;
	; report error loading application
	;
	pop	dx				; dx = error filename block
SBCS<	and	si, 0x00FF			; clear high byte	>
	tst	si
	jz	noDocument

	cmp	ax, GLE_FILE_NOT_FOUND
	jne	loadError

	mov	ax, ERROR_NO_PARENT_APPLICATION
	call	DesktopOKError
	jmp	done

noDocument:
	;   The IACPCE_CANNOT_FIND_SERVER error message is about a
	;   failure to open the document which is meaningless if
	;   there is no document. So use GLE_FILE_NOT_FOUND instead.
	;

	cmp	ax,IACPCE_CANNOT_FIND_SERVER
	jne	loadError
	mov	ax,GLE_FILE_NOT_FOUND

loadError:
	call	ReportLoadError

done:
	call	HideHourglass
	ret				; <-- EXIT HERE ALSO
DesktopLoadApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ReportLoadError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reports application load errors

CALLED BY:	DesktopLoadApplication, LoadApplicationAndPrint
PASS:		ax	- Error
		dx - filename block (in case error reporting is needed)

RETURN:		frees dx if mask DETF_USE_DX_BUFFER_NAME was passed
	
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/92		Pulled out into a subroutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReportLoadError	proc	far
	uses	si
	.enter

	segmov	ds, cs, si
	mov	si, offset GeodeLoadErrorTable
	call	DesktopErrorReporter

	.leave
	ret
ReportLoadError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MinimizeIfDesired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	iconify desktop when running new GEOS application

CALLED BY:	INTERNAL
			DesktopLoadApplication

PASS:		nothing

RETURN:		desktop iconify, is user has set this option

DESTROYED:	bx,cx,dx,si,di,es,ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/27/89	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MinimizeIfDesired	proc	near
	uses	ax
	.enter


	;
	; first, release application focus (as feedback)
	;
	mov	bx, handle Desktop
	mov	si, offset Desktop
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjMessageCall
	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	ObjMessageCall
if _GMGR			; NewDesk never minimizes.
if not _ZMGR
ifndef GEOLAUNCHER		; never minimize-on-run for GeoLauncher
	;
	; then, minimize if desired
	;
	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov	cx, mask OMI_MINIMIZE_ON_RUN
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCall
	jnc	done				; not set
	mov	bx, handle FileSystemDisplay
	mov	si, offset FileSystemDisplay
	mov	ax, MSG_GEN_DISPLAY_SET_MINIMIZED
	call	ObjMessageNone
done:
endif		; ifndef GEOLAUNCHER
endif		; if (not _ZMGR)
endif		; if _GMGR

	.leave
	ret
MinimizeIfDesired	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDefaultLauncher
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This will set the default launcher in the .ini file.

CALLED BY:	DesktopLoadApplication, DesktopOpenApplication.

PASS:		es:di - application name of default launcher. 
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CuongLe	4/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeodeLoadErrorTable	DesktopErrorTableEntry	\
	<GLE_FILE_NOT_FOUND,
	GleFileNotFoundError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
	mask DETF_SYS_MODAL>,

	<GLE_FILE_READ_ERROR,
	GleFileReadError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,


	<GLE_LIBRARY_NOT_FOUND,
	GleLibraryNotFound,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_ATTRIBUTE_MISMATCH,
	GleAttributeMismatch,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_MEMORY_ALLOCATION_ERROR,
	GleMemoryAllocationError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_PROTOCOL_IMPORTER_TOO_RECENT,
	GleProtocolErrorImporterTooRecent,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_PROTOCOL_IMPORTER_TOO_OLD,
	GleProtocolErrorImporterTooOld,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_NOT_MULTI_LAUNCHABLE,
	GleNotMultiLaunchable,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_LIBRARY_PROTOCOL_ERROR,
	GleLibraryProtocolError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_LIBRARY_LOAD_ERROR,
	GleLibraryLoadError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_DRIVER_INIT_ERROR,
	GleDriverInitError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_LIBRARY_INIT_ERROR,
	GleLibraryInitError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_FIELD_DETACHING,
	GleFieldDetachingError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<GLE_INSUFFICIENT_HEAP_SPACE,
	GleHeapSpaceError,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<IACPCE_CANNOT_FIND_SERVER,
	IACPCannotFindServer,
	mask DETF_SHOW_FILENAME or mask DETF_USE_DX_BUFFER_NAME or \
		mask DETF_SYS_MODAL>,

	<NIL>				; end of table

FixedCode	ends
