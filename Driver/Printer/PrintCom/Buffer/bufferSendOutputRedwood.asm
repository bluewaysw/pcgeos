

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		common buffer routines
FILE:		bufferSendOutputRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name		Description
	----		-----------

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Dave	2/93	initial version

DESCRIPTION:

	$Id: bufferSendOutputRedwood.asm,v 1.1 97/04/18 11:50:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrSendOutputBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	send the output buffer out the port. There must be at least 1 byte in
	the buffer for this to work.

CALLED BY:	Rotate

PASS:		es	- pointer to locked PState
		di	- pointer to byte after last load of output buffer
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
	Dave	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrSendOutputBuffer	proc	near
	uses	cx,si,ds
	.enter

	call	WaitForNoDiskAndLock	;we can't send a swath unless the disk
					;  has stopped spinning.


	mov	ds,es:[PS_redwoodSpecific].RS_outputBuffer
	mov	cx,di		;get byte count into cx

		;Do the DMA process here.....
	mov	si,offset GPB_outputBuffer	;ds:si --> buffer cx = length	
	mov	di,si
	call	PrintDMADataOut		;set up the DMA controller.
        jc      exit                    ;propogate errors out.
        call    PrSendGraphicControlCode ;send the graphics code for this band
					;this will start the dma count going.
exit:
	call	SysUnlockBIOS		;done now, allow disk access (flags OK)

	.leave
	ret
PrSendOutputBuffer	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	WaitForNoDiskAndLock

SYNOPSIS:	Waits for disk to stop spinning, and locks access to it.

CALLED BY:	PrintSwath

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/19/93       	Initial version

------------------------------------------------------------------------------@

BIOS_DATA_SEG		equ	40h		;from dos.def
BIOSMotorStatus		=	003fh

BiosMotorStatusBits	record
	BMSB_CURRENTLY_WRITING:1
	:1
	BMSB_DRIVE_SELECT_STATE:2
	:2
	BMSB_DRIVE_1_MOTOR_ON:1
	BMSB_DRIVE_0_MOTOR_ON:1
BiosMotorStatusBits	end


WaitForNoDiskAndLock	proc	near

	call	SysLockBIOS			; lock disk access the easy way
	push	ds, ax

motorWaitLoop:
	;
	; Wait for floppy to spin down
	;
	mov	ax,BIOS_DATA_SEG		;address BIOS variables
	mov	ds,ax
	test	{byte} ds:[BIOSMotorStatus], mask BMSB_DRIVE_1_MOTOR_ON or \
					     mask BMSB_DRIVE_0_MOTOR_ON
	jz	done
	mov	ax, 1
	call	TimerSleep			;sleep for a moment
	jmp	short motorWaitLoop
done:
	pop	ds, ax
	ret
WaitForNoDiskAndLock	endp




