COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tocDisk.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

DESCRIPTION:
	

	$Id: tocDisk.asm,v 1.1 97/04/04 17:50:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCADDDISK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a disk to the disk array

CALLED BY:	GLOBAL
PARAMETERS:	word (const char *, const TocDiskStruct *)
RETURN:		element # of disk in array
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <TOCADDDISK	proc	far	diskName:fptr.char, diskDesc:fptr.TocDiskStruct>
DBCS <TOCADDDISK	proc	far	diskName:fptr.wchar, diskDesc:fptr.TocDiskStruct>
	uses	ds, si
	.enter
	lds	si, ss:[diskName]
	movdw	cxdx, ss:[diskDesc]
	call	TocAddDisk
	mov_tr	ax, bx
	.leave
	ret
TOCADDDISK	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocAddDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a disk to the disk array

CALLED BY:	GLOBAL

PASS:		ds:si - full name of disk 
		cx:dx - TocDiskStruct structure

RETURN:		bx - disk token (element number in array)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocAddDisk	proc far

	uses	ax, di

	.enter

	push	ds, si
	call	TocDBLockMap
	mov	si, ds:[si]
	movdw	axdi, ds:[si].TM_disks
	pop	ds, si

	call	TocNameArrayAdd

	.leave
	ret
TocAddDisk	endp

