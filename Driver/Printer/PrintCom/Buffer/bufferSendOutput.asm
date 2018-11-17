

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferSendOutput.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/92	initial version

DESCRIPTION:

	$Id: bufferSendOutput.asm,v 1.1 97/04/18 11:50:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendOutputBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	send the output buffer out the port. There must be at least 1 byte in
	the buffer for this to work.

CALLED BY:	PrintSwath

PASS:		es	- pointer to locked PState
		ds:di	- pointer to byte after last load of output buffer
RETURN:	
		di	- offset GPB_outputBuffer
		carry   - set if not all bytes were written
                          (PS_error field in PState also set to 1)
DESTROYED:	
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrSendOutputBuffer	proc	near
	uses	cx,si
	.enter
	mov	cx,di		;get byte count into cx
	jcxz	exit		;if no data, just return.
	mov	si,offset GPB_outputBuffer	;reset pointer to beginning of
				;output buffer.
	mov	di,si
	call	PrintStreamWrite
exit:
	.leave
	ret
PrSendOutputBuffer	endp
