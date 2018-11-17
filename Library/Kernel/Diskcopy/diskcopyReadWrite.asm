COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Diskcopy
FILE:		diskcopyReadWrite.asm

AUTHOR:		Cheng, 5/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial revision

DESCRIPTION:
		
	$Id: diskcopyReadWrite.asm,v 1.1 97/04/05 01:18:17 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReadSource

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	while space exists in the buffers
	    if cluster is good then
		status = good
		read cluster into buffer
	    	if read was bad then
		    report bad read
		endif
	    else
		status = bad
	    endif
	    note status in status entry
	end

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	WriteDest

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	while clusters remain unwritten
	    if status for cluster = good then
		write cluster
		if write is bad then
		    return(disk copy fail)
		endif
	    endif
	    next cluster
	end

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetSourceFAT

DESCRIPTION:	Buffer the source disk's FAT so that we can tell which
		sectors are needed.

CALLED BY:	INTERNAL ()

PASS:		es - dgroup

RETURN:		carry clear if successful

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@

GetSourceFAT	proc	near
	mov	ax, es:[sourceFATSize]
	mov	dx, es:[sourceSectorSize]
	mul	dx			;dx:ax <- number of bytes per FAT
					;dx = 0
	mov	cx, HAF_STANDARD_LOCK shl 8
	call	MemAlloc
	jc	exit
	mov	es:[fatBufHan], bx
	mov	es:[fatBufSegAddr], ax
	mov	ds, ax
	clr	si			;ds:si <- buffer

	mov	al, es:[sourceDrive]
	mov	cx, es:[sourceFATSize]
	clr	bx
	mov	dx, es:[sourceFATStart]
	call	DriveReadSectors
	jc	exit
exit:
	ret
GetSourceFAT	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	IsCurClusterGood

DESCRIPTION:	Returns a boolean telling whether the current cluster
		is marked as good in the FAT.

CALLED BY:	INTERNAL ()

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@

IsCurClusterGood	proc	near
	ret
IsCurClusterGood	endp
