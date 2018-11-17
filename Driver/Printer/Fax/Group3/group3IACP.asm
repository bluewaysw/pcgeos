COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3IACP.asm

AUTHOR:		Andy Chiu, Jan 28, 1994

ROUTINES:
	Name			Description
	----			-----------
        IACP_NotifySpooler      notify the spooler when a new fax file is 
				created in the standard directory

	CheckOnFaxSpooler	Checks to see if the fax spooler is running.
				If it isn't it then launches it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/28/94   	Initial revision


DESCRIPTION:
	Contains IACP code to call the fax spooler.
		
	$Id: group3IACP.asm,v 1.1 97/04/18 11:53:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                IACP_NotifySpooler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       notify the spooler when a new fax file is created in
                the standard directory

CALLED BY:      PrintEndJob
PASS:           ds:si		= file name 
		bxax		= faxSpoolID
		dx		= either GWNT_FAX_NEW_JOB_CREATED
				  or GWNT_FAX_NEW_JOB_COMPLETED or
				  GeoworksNotificationType
RETURN:         carry set on error
DESTROYED:      si
SIDE EFFECTS:   
                the block allocated will be free on the other side.
PSEUDO CODE/STRATEGY:
                

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        CL      9/17/93         Initial version
	AC	9/21/93		Minor changes for my sanity :)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACP_NotifySpooler      proc    near
        uses    ax,bx,cx,dx,di,bp,ds,es
        .enter
	;
        ; alloc a block to store the fax file name
        ;
		pushdw	bxax			; save fax spool ID

		mov	ax, size FaxIACPBlock
	        mov     cl, mask HF_SHARABLE
        	mov     ch, mask HAF_LOCK
		mov	bx, handle ui
        	call    MemAllocSetOwner                ; bx <- block handle
	                                                ; ax <- seg of the block
		LONG	jc	errorAndRestoreStack

	;
	; copy fax file name to the block
	;
	        mov     es, ax                  ; es <- seg ptr to the block
	        mov	di, FIB_fileName	; es:di <- str destination

		LocalCopyString			; es:di <- str buffer filled
						; with FaxFile name
	;
	; Copy the FaxSpoolID into the block
	;
		mov	di, FIB_faxSpoolID	; es:di <- buffer to fill
		popdw	es:[di]			; restore fax spool ID
	;
	; Unlock the block and set the ref count
	;
	        call    MemUnlock
        	push    bx                              ; save block handle
        	mov     ax, 1
	        call    MemInitRefCount                 ; set ref count to 1

        ;
        ; make the connection with spooler
        ;
	; If the faxspooler is not already running, launch it.
	;
		push	dx				; save message to pass
		mov 	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		segmov	ds, cs
		mov	si, offset FaxSpoolFileName
		call	IACPCreateDefaultLaunchBlock
		mov	bx, dx
		call	MemLock
		mov	es, ax
		lea	di, es:[ALB_appRef].AIR_fileName
		mov	es:[ALB_launchFlags], mask ALF_NO_ACTIVATION_DIALOG
		LocalCopyString

		segmov	es, cs
        	mov     di, offset cs:[SpoolerToken]    ; es:di <- GeodeToken

	        mov     ax, mask IACPCF_FIRST_ONLY
        	call    IACPConnect                     ; bp <- IACPConnection
		pop	dx				; restore message to pass
		jc	errorAndRestoreStack

        ;
	; prepare a message for spooler
	;

        	XchgTopStack    bp                      ; save IACPConnection and
	                                                ; bp <- block handle
        	mov     ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
        	mov     cx, MANUFACTURER_ID_GEOWORKS    ; parameter to pass
        	clr     bx, si                           ; send to process
        	mov     di, mask MF_RECORD
	        call    ObjMessage                  	; ^hdi <- msg to send
	        pop     bp                              ; restore IACPConnection
	;
	; send the message
	;
	        mov     bx, di                          ; ^hbx <- msg to send
	        clr     cx                              ; no completion msg
        	mov     dx, TO_PROCESS                  ; set TravelOption
	        mov     ax, IACPS_CLIENT                ; side sending
        	call    IACPSendMessage
	;
	; Shut down connection
	;
	        clr     cx, dx
	        call    IACPShutdown
		clc
exit:
        .leave
        ret

errorAndRestoreStack:
		pop	ax,dx				; restore stack

	;
	; Display a dialog box to tell the user that we couldn't
	; connect to the fax spooler.
	;
		mov	ax, \
			CustomDialogBoxFlags <1,CDT_ERROR,GIT_NOTIFICATION,0>
		mov	si, offset SpoolerConnectError
		call	DoDialog

		stc	
		jmp	short exit

IACP_NotifySpooler      endp

FaxSpoolFileName	char	"faxspool.geo",0
