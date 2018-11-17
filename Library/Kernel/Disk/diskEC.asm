COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Disk tracking
FILE:		diskEC.asm

AUTHOR:		Adam de Boor, Feb 25, 1990

ROUTINES:
	Name			Description
	----			-----------
    INT	AssertDSKdata		Make sure DS points at idata
    INT	AssertDiskHandle	Make sure bx is a valid disk handle
    INT	AssertValidDrive	Make sure al is a valid drive number
    INT	AssertSIBootBuf		Make sure ds:si points at the bootBuf
    INT	AssertBootSector	Make sure ds:si is a valid boot sector
    INT	AssertSISectorBuf	Make sure ds:si points at the sectorBuf

    INT	CheckTblAddr		Make sure es = the disk handle table
    INT	CheckTblOffset		Make sure di is a valid offset in the disk table
    INT	CheckTblStruct		Make sure the disk table is ok
    INT AssertDSKdataAndValidDrive	Combination of AssertDSKdata and
    					AssertValidDrive

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	2/25/90		Initial revision


DESCRIPTION:
	Error-checking routines for the Disk module
		

	$Id: diskEC.asm,v 1.1 97/04/05 01:11:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IF	ERROR_CHECK	;*******************************************************

COMMENT @-----------------------------------------------------------------------

FUNCTION:	AssertDSKdata

DESCRIPTION:	Assert that ds = idata.

CALLED BY:	INTERNAL (error checking code)

PASS:		ds

RETURN:		nothing, dies if assertion fails

DESTROYED:	nothing,
		dies if assertions fail

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@

AssertDSKdata	proc	far
	pushf
	push	ax
	mov	ax, ds
	cmp	ax, idata
	je	done
	ERROR	BAD_DS
done:
	pop	ax
	popf
	ret
AssertDSKdata	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertDiskHandleSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert that the handle passed in si is indeed a disk handle

CALLED BY:	INTERNAL
PASS:		es	= FSIR
		si	= disk handle
RETURN:		nothing
DESTROYED:	nothing but flags

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssertDiskHandleSI proc	near
		uses	bx
		.enter
		mov	bx, si
		call	AssertDiskHandle
		.leave
		ret
AssertDiskHandleSI endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	AssertDiskHandle

DESCRIPTION:	Assert that the handle passed is indeed a disk handle.

CALLED BY:	INTERNAL (error checking code)

PASS:		es - FSInfoResource
		bx - disk handle

RETURN:		nothing,
		dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@

AssertDiskHandle	proc	far		;Filepath needs it
	uses	ax, si
	.enter

	call	FSDDerefInfo
	mov	si, es
	cmp	ax, si
	ERROR_NE ILLEGAL_SEGMENT
	
	mov	si, offset FIH_diskList - offset DD_next
checkLoop:
	mov	si, es:[si].DD_next
	tst	si
	ERROR_Z	BAD_DISK_HANDLE		; => hit end of list w/o finding it,
					;  so choke.
	cmp	bx, si
	jne	checkLoop
	.leave
	ret
AssertDiskHandle	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	AssertValidDrive

DESCRIPTION:	Assert that the drive number passed is legal.

CALLED BY:	INTERNAL (error checking code)

PASS:		al - 0 based drive number (0=A, 1=B, ...)

RETURN:		nothing,
		dies if assertions fail

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	9/89		Initial version

-------------------------------------------------------------------------------@

if 0
AssertValidDrive	proc	near
	push	ax
	call	DriveGetStatus
	ERROR_C	BAD_DRIVE_NUMBER
	pop	ax
	ret
AssertValidDrive	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertDSKdataAndValidDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Two for the price of one...

CALLED BY:	INTERNAL
PASS:		ds 	= dgroup
		al	= valid drive number
RETURN:		only if things are good.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
AssertDSKdataAndValidDrive	proc	near
	call	AssertDSKdata
	jmp	AssertValidDrive
AssertDSKdataAndValidDrive	endp
endif

ENDIF	;**********************************************************************
