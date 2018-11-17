

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Oki Microline buffer routines
FILE:		bufferOkiSendOutput.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	3/92	initial version

DESCRIPTION:

	$Id: bufferOkiSendOutput.asm,v 1.1 97/04/18 11:50:21 newdeal Exp $

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
        If sending 03h to the stupide oki9 printer then we have to
        escape it with another 03h character.  So after we've built
        out the buffer of chars to send, then we'll search it for
        03h chars and when we find them. We'll send out that amount
        of stuff and then send another 03h.

        register usage:
        dx      =       count for the remaining bytes to test in buffer.
        ds      =       Segment address of output buffer.
        es      =       Segment address of PState

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrSendOutputBuffer	proc	near
	uses	cx,dx,si
	.enter
	mov	cx,di		;get byte count into cx
	jcxz	exit		;if no data, just return.
	mov	dx,cx		;get byte count into dx
	mov	di,offset GPB_outputBuffer	;reset pointer to beginning of
				;output buffer.
searchBuf:
        mov     si, di                  ;save ptr to start of string
        mov     cx, dx                  ;get buffer size into the limit count.
                                        ;dx is the storage register for the
                                        ;remaining bytes in this band to test.
        push    es                      ;save PState address.
        segmov  es,ds,ax                ;output buffer into es
        mov     al, C_ETX               ;search for 'C_ETX'
        repne   scasb
        pop     es                      ;recover PState address.
        jnz     sendBuf
        xchg    cx, dx                  ;calc #chars to send
        sub     cx, dx                  ;=remaining - current.
        call    PrintStreamWrite        ; the C_ETX found
        jc      exit
        mov     cl, C_ETX               ; send another C_ETX out
        call    PrintStreamWriteByte    ;
        jc      exit
        tst     dx
        jnz     searchBuf
        jmp     resetPointer

        ;after sacnning to the end of the band, every thing winds up here.
sendBuf:
        mov     cx, dx                  ;get buffer size
        call    PrintStreamWrite        ;send them out.
resetPointer:
	mov	di,offset GPB_outputBuffer	;reset pointer to beginning of
exit:
        .leave
        ret
PrSendOutputBuffer	endp
