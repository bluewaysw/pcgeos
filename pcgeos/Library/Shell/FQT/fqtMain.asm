COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- FQT
FILE:		fqtMain.asm

AUTHOR:		David Litwin, January 19, 1993

ROUTINES:
	Name				Description
	----				-----------
	ShellGetTrueDiskHandleFromFQT	Gets the True diskhandle of a FQT's
					(FileQuickTransfer) path.  This is
					used in the  QuickTransfer CIFI_extra1
					data field.
	ShellGetRemoteFlagFromFQT	Gets the remote flag (if any files are
					remote).  This is used in the 
					QuickTransfer CIFI_extra2 data field.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/19/93	Initial revision.

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: fqtMain.asm,v 1.1 97/04/07 10:45:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellGetTrueDiskHandleFromFQT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup for a call to ShellGetTrueDiskHandle.

CALLED BY:	GLOBAL

PASS:		es - FileQuickTransfer block

RETURN:		carry	- clear if OK
				cx = true disk handle of path
			- set on error
				ax = FileError

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/13/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellGetTrueDiskHandleFromFQT	proc	far
	uses	si, bx, ds
	.enter

	segmov	ds, es, si
	mov	si, offset FQTH_pathname
	mov	bx, ds:[FQTH_diskHandle]
	call	ShellGetTrueDiskHandle

	.leave
	ret
ShellGetTrueDiskHandleFromFQT	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellGetTrueDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take a path and return the true disk that it is on (the true
		diskhandle.  Basically calls FileConstructActualPath.

CALLED BY:	GLOBAL
			ShellGetTrueDiskHandleFromFQTHandle, 
			ShellGetTrueDiskHandleFromFQTSegment

PASS:		bx	- diskhandle of path
		ds:si	- path

RETURN:		carry	- clear if OK
				cx = true disk handle of path
			- set on error
				ax = FileError

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/13/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellGetTrueDiskHandle	proc	near
	uses	bx, dx, di, es
tempPath	local	PathName
	.enter

	clr	dx				; no <drivename:> requested
	segmov	es, ss, di
	lea	di, ss:[tempPath]		; es:di is temp path buffer
	mov	cx, size PathName		; cx is size of temp buffer
	call	FileConstructActualPath
	mov	cx, bx

	.leave
	ret
ShellGetTrueDiskHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellGetRemoteFlagFromFQT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the files in the FQT and if any of them are remote
		it sets the remote flag.

CALLED BY:	GLOBAL

PASS:		es - segment of the locked down FileQuickTransfer block
		
RETURN:		ax = zero if local, non-zero if remote
DESTROYED:	none

SIDE EFFECTS:	none
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	1/8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellGetRemoteFlagFromFQT	proc	far
		uses	cx, si

		.enter

	;
	; check the local/remote bit of all files, exiting if 
	; any file is remote
	;
		clr	ax
		mov	cx, es:[FQTH_numFiles]
		jcxz	done
		mov	si, offset FQTH_files + offset FOIE_pathInfo
startLoop:
		
		test	es:[si], mask DPI_EXISTS_LOCALLY
		jz	foundRemote
		add	si, size FileOperationInfoEntry
		loop	startLoop

done:
		.leave
		ret
foundRemote:
		dec	ax
		jmp	done
		
ShellGetRemoteFlagFromFQT	endp
