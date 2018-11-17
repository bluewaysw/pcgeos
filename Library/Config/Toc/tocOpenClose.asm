COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Config Library
FILE:		tocOpenClose.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------
	TocOpenFile		Open the TOC file.
	TocCreateFile		Create a new TOC file -- create the
				map block and the "categories" and
				"disks" arrays.  The file's handle 
				will be stored in dgroup, with its
				owner set to the config library.
	TocCloseFile		Close the file.
	TocCreateNewFile	Create a new TOC file in the current
				working directory.  All subsequent TOC
				routines will operate on this new
				file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

DESCRIPTION:
	

	$Id: tocOpenClose.asm,v 1.1 97/04/04 17:50:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocOpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the TOC file.

CALLED BY:	ConfigEntry

PASS:		nothing 

RETURN:		if error
			carry set
		else
			carry clear

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

PSEUDO CODE/STRATEGY:	
	If file doesn't exist, create a new one.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.
	PJC	1/23/95		Added .ini deletion code.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
deleteTocFileCategory	char	'pref',0
deleteTocFileKey	char	'forceDeleteTocOnceOnly',0

TocOpenFile	proc near

	;
	; Borrow stack space for the call to VMOpen.  We have to do it before
	; ".enter" because we have local variables.
	;
		mov	di, 500		; ensure 500 bytes of stack space
		call	ThreadBorrowStackSpace	; di = token

locals	local	ProtocolNumber
		uses	di
		.enter
		call	LoadDSDGroup
		clr	ds:[tocFileHandle]

	; Move to PRIVDATA standard directory

		call	FilePushDir
		mov	ax, SP_PRIVATE_DATA
		call	FileSetStandardPath

	; Try to change into our own private directory under PRIVDATA

		mov	dx, offset tocPath	; "PREF"
		clr	bx			; Use current disk handle.
		call	FileSetCurrentPath
		jnc	gotPath

	; If directory doesn't exist, create it, and then move into
	; it. We might not be able to create it on a read-only file
	; system, so just bail if so.

		call	FileCreateDir
		jc	done
		call	FileSetCurrentPath

gotPath:

	; Now the directory exists, try to open the file.
	
		clr	cx
		mov	dx, offset tocFileName
		mov	ax, (VMO_OPEN shl 8) or mask VMAF_FORCE_READ_WRITE
		call	VMOpen
		jnc	checkIniValue

create:

	; File did not exist.  Create a new one.

		call	TocCreateFile
		jc	done
		jmp	createOpenOK

checkIniValue:

 	; Check if the .ini file tells us to delete the TOC file. Then
 	; delete the key, so we won't mistakenly delete the TOC file again.
 
 		push	ds, dx
 		mov	cx, cs
 		mov	ds, cx
 		mov	si, offset deleteTocFileCategory
 		mov	dx, offset deleteTocFileKey
 		clr	ax			; assume FALSE
 		call	InitFileReadBoolean
 		mov	dx, si
 		call	InitFileDeleteEntry
 		pop	ds, dx
 		tst	ax
 		jnz	closeAndDelete		; .ini says nuke, so nuke.

checkProtocol::

	; Check the major protocol.  If it's an old version of the
	; file, nuke it.

		mov	ax, FEA_PROTOCOL
		segmov	es, ss, di
		lea	di, locals
		mov	cx, size locals
		call	FileGetHandleExtAttributes

		cmp	locals.PN_major, TOC_FILE_MAJOR_PROTOCOL
		jne	closeAndDelete

createOpenOK:
	
	; Major protocol number is OK -- save the file handle and
	; exit.  Flush the thing to disk in case GEOS crashes soon.
		
		call	VMUpdate		

		mov	ds:[tocFileHandle], bx
		mov	ax, handle 0		; config's handle
		call	HandleModifyOwner
		clc				; indicate success

done:
		call	FilePopDir

		.leave
	;
	; Return stack space.
	;
		call	ThreadReturnStackSpace

		Destroy ax,bx,cx,dx,si,di,bp
		ret

closeAndDelete:

	; Close the TOC file we opened, delete it, and jump to the
	; code to create a new one.

		mov	al, FILE_NO_ERRORS
		call	VMClose
		call	FileDelete
		jmp	create

TocOpenFile	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocCreateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new TOC file -- create the map block and the
		"categories" and "disks" arrays.  The file's handle
		will be stored in dgroup, with its owner set to the
		config library.

CALLED BY:	TocOpenFile

PASS:		ds:dx - filename
		(ds = dgroup)

RETURN:		if error
			carry set
		else
			carry clear
			bx - file handle

DESTROYED:	ax,cx,dx,si,di,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

tocProtocol	ProtocolNumber	<TOC_FILE_MAJOR_PROTOCOL,
					TOC_FILE_MINOR_PROTOCOL> 

TocCreateFile	proc near

		uses	ds

tocMap	local	TocMap

		.enter
	
		mov	ax, VMO_CREATE_TRUNCATE shl 8 or \
				(mask VMAF_FORCE_READ_WRITE)
		clr	cx
		call	VMOpen
EC <		WARNING_C	CANNOT_CREATE_TOC_FILE			>
		jc	done
	
	; Even though our caller does this, too -- we have to do this
	; here because TocAllocNameArray needs it.  Grr.
	
		mov	ds:[tocFileHandle], bx
	
	; Set the protocol

		segmov	es, cs
		mov	di, offset tocProtocol
		mov	cx, size tocProtocol
		mov	ax, FEA_PROTOCOL
		call	FileSetHandleExtAttributes

	; Allocate the disk array
	
		push	bx				; file handle
	
		mov	bx, size TocDiskStruct
		call	TocAllocNameArray
		movdw	ss:[tocMap].TM_disks, axdi

	; Allocate the category array

		mov	bx, size TocCategoryStruct
		call	TocAllocChunkArray
		movdw	ss:[tocMap].TM_categories, axdi

	; Now, create the map block, and copy the tocMap structure in

		mov	cx, size TocMap
		call	TocAllocDBItem
		pop	bx				; file handle
		call	DBSetMap

		mov	di, ds:[si]
		segmov	es, ds
		segmov	ds, ss
		lea	si, ss:[tocMap]
		mov	cx, size tocMap
		rep	movsb

	; Dirty & unlock it (segment is in ES)

		call	DBDirty
		call	DBUnlock
		clc

done:
		.leave
		ret
TocCreateFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocCloseFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the file

CALLED BY:	ConfigEntry

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	bx,ds

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocCloseFile	proc near	uses ax
		.enter
		call	LoadDSDGroup
		clr	bx
		xchg	bx, ds:[tocFileHandle]
		tst	bx
		jz	done
		mov	al, FILE_NO_ERRORS
		call	VMClose
done:
		.leave
		ret
TocCloseFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCCREATENEWFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new TOC file in the current directory and set other
		Toc routines to access it.

CALLED BY:	GLOBAL
PARAMETERS:	Boolean (void)
RETURN:		TRUE if successful
SIDE EFFECTS:	Previous TOC file is closed.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TOCCREATENEWFILE proc	far
	call	TocCreateNewFile
	mov	ax, 0
	jc	done
	dec	ax
done:
	ret
TOCCREATENEWFILE endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocCreateNewFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a new TOC file in the current working
		directory.  All subsequent TOC routines will operate
		on this new file.

CALLED BY:	GLOBAL (diskmaker)

PASS:		nothing 

RETURN:		if error
			carry set
			ax - FileError
		else
			carry clear
			ax - destroyed


DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocCreateNewFile	proc far

		uses	ax,bx,cx,dx,si,di,bp,ds,es

		.enter

	; Close the existing TOC file

		call	TocCloseFile

	; Now, create a new one.

		call	LoadDSDGroup
		mov	dx, offset tocFileName
		call	TocCreateFile

		call	VMUpdate		

		mov	ax, handle 0		; config's handle
		call	HandleModifyOwner

		.leave
		ret
TocCreateNewFile	endp

