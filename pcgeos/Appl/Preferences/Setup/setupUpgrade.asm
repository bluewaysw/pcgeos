COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GEOS
MODULE:	        Graphical Setup -- Document upgrade
FILE:		setupUpgrade.asm

AUTHOR:		Cassie Hartzong, Apr 15, 1993

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cassie	4/15/93		Initial revision


DESCRIPTION:
	Upgrades documents and backgrounds copied from 1.X to 2.0

	$Id: setupUpgrade.asm,v 1.1 97/04/04 16:28:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUpgradeAllDocuments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has chosen to upgrade all 1.x documents to 2.0
		format.

CALLED BY:	MSG_SETUP_UPGRADE_ALL_DOCUMENTS
PASS:		nothing
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <document	char	'DOCUMENT', 0					>
DBCS <document	wchar	'DOCUMENT', 0					>
SetupUpgradeAllDocuments 	method SetupClass, 
				MSG_SETUP_UPGRADE_ALL_DOCUMENTS


	;
	; Create a block containing a FileQuickTransferHeader structure and
	; one FileOperationInfoEntry, which will contain Info about the
	; Document directory.  When the block is processed, the directory
	; is enumerated for us.  
	;
		mov	ax, size FileQuickTransferHeader + size FileOperationInfoEntry
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc			; ^hbx <- block
		mov	es, ax		
		mov	es:[FQTH_numFiles], 1	
		mov	es:[FQTH_diskHandle], SP_TOP
		mov	es:[FQTH_files].FOIE_type, GFT_DIRECTORY
		mov	es:[FQTH_files].FOIE_attrs, mask FA_SUBDIR

		segmov	ds, cs, si
		mov	si, offset document
		lea	di, es:[FQTH_files].FOIE_name
		mov	cx, size document
		rep	movsb

	; everything else zero-initialized, so just unlock the block

		call	MemUnlock

	; do the conversion

		call	SetupUpgradeLow

	; now convert the old backgrounds

		call	SetupUpgradeBackgrounds

		ret
SetupUpgradeAllDocuments		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUpgradeBackgrounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upgrade all 1.X backgrounds to 2.0

CALLED BY:	
PASS:		nothing
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <background	char	'BACKGRND', 0				>
DBCS <background	wchar	'BACKGRND', 0				>
SetupUpgradeBackgrounds		proc	near
	.enter

	;
	; Create a block containing a FileQuickTransferHeader structure and
	; one FileOperationInfoEntry, which will contain Info about the
	; Document directory.  When the block is processed, the directory
	; is enumerated for us.  
	;
		mov	ax, size FileQuickTransferHeader + size FileOperationInfoEntry
		mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc			; ^hbx <- block
		mov	es, ax		
		mov	es:[FQTH_numFiles], 1	
		mov	es:[FQTH_diskHandle], SP_USER_DATA
		mov	es:[FQTH_files].FOIE_type, GFT_DIRECTORY
		mov	es:[FQTH_files].FOIE_attrs, mask FA_SUBDIR

		segmov	ds, cs, si
		mov	si, offset background
		lea	di, es:[FQTH_files].FOIE_name
		mov	cx, size document
		rep	movsb

	; everything else zero-initialized, so just unlock the block

		call	MemUnlock

	; do the conversion

		call	SetupUpgradeLow

	.leave
	ret
SetupUpgradeBackgrounds		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupUpgradeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upgrade all 1.x VM files in the given path

CALLED BY:	SetupUpgradeAllDocuments
PASS:		^hbx	- FileQuickTransferHeader 
RETURN:		FQTH block freed
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupUpgradeLow		proc	near

	; 
	; Call the sucker.  It will destroy the block for us.
	; 	

		mov	dx, bx			; dx <- FQTH block
		mov	cx, handle 0		; us, "in case" it has UI
						;  to put up

		call	SetupUpgradeLoadLibrary	; bx <- library handle
		jc	loadError
		mov	ax, CTET_TOOL_ACTIVATED_NO_FILE_MANAGER
		call	ProcGetLibraryEntry	; ax:bx <- entry point
		call	ProcCallFixedOrMovable

done:
		ret
loadError:
		mov	si, offset LoadCvtToolLibraryError
		mov	bp, CustomDialogBoxFlags<1,CDT_ERROR,GIT_NOTIFICATION,0>
		clr	cx, dx
		call	SetupPrinterDoDialog	; ax <- InteractionCommand
		jmp	done

SetupUpgradeLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SetupUpgradeLoadLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the cvttool library.

CALLED BY:	SetupUpgradeAllDocuments
PASS:		nothing
RETURN:		carry set on error:
			ax	= GeodeLoadError
		carry clear on success:
			bx	= handle of library
DESTROYED:	nothing else
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if DBCS_PCGEOS
libDir		wchar	CVTTOOL_LIB_DIR
libPath		wchar	CVTTOOL_LIB_PATH
else
libDir		char	CVTTOOL_LIB_DIR
libPath		char	CVTTOOL_LIB_PATH
endif

SetupUpgradeLoadLibrary	proc	near
		uses	ds, dx, si
		.enter
	;
	; Push to the directory that holds the library.
	; 
		call	FilePushDir
		mov	bx, CVTTOOL_LIB_DISK_HANDLE
		segmov	ds, cs
		mov	dx, offset libDir
		call	FileSetCurrentPath
		mov	ax, GLE_FILE_NOT_FOUND
		jc	done

	;
	; Load the library.
	; 
		mov	si, offset libPath	; ds:si <- library long name
		mov	ax, CVTTOOL_PROTO_MAJOR
		mov	bx, CVTTOOL_PROTO_MINOR
		call	GeodeUseLibrary		; ^hbx <- library 

	;
	; Return to previous directory.
	; 
		call	FilePopDir
done:
		.leave
		ret
SetupUpgradeLoadLibrary		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupDocumentUpgradeComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Time to go to the next screen.

CALLED BY:	MSG_SETUP_DOCUMENT_UPGRADE_COMPLETE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SetupScreenClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupDocumentUpgradeComplete	method dynamic SetupClass,
					MSG_SETUP_DOCUMENT_UPGRADE_COMPLETE

		call	SetupAskForSerialNumber?	
		jnc	setupComplete			; don't ask, done

		mov	bx, handle SerialNumberScreen	; else ask for serial#
		mov	si, offset SerialNumberScreen
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage

done:
		ret
setupComplete:
	;
	; Advance to the...DoneScreen! Da daaaaa!
	;
		mov	si, offset InstallDoneText
		call	SetupComplete
		jmp	done
		
SetupDocumentUpgradeComplete		endm
