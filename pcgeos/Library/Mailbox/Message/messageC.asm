COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Message
FILE:		messageC.asm

AUTHOR:		Chung Liu, Nov 21, 1994

ROUTINES:
	Name			Description
	----			-----------
	MAILBOXREGISTERMESSAGE
	MAILBOXCHANGEBODYFORMAT
	MAILBOXGETBODYFORMAT
	MAILBOXGETBODYREF
	MAILBOXDONEWITHBODY
	MAILBOXSTEALBODY
	MAILBOXGETMESSAGEFLAGS
	MAILBOXGETSUBJECTLMEM
	MAILBOXGETSUBJECTBLOCK
	MAILBOXACKNOWLEDGEMESSAGERECEIPT
	MAILBOXGETDESTAPP
	MAILBOXGETSTORAGETYPE
	MAILBOXSETTRANSADDR
	MAILBOXGETTRANSADDR
	MAILBOXGETNUMTRANSADDRS
	MAILBOXREPORTPROGRESS
	MAILBOXGETCANCELFLAG
	MAILBOXGETTRANSDATA
	MAILBOXSETTRANSDATA
	MAILBOXGETBODYMBOXREFBLOCK
	MAILBOXGETSTARTBOUND
	MAILBOXGETENDBOUND
	MAILBOXDELETEMESSAGE
	MAILBOXREPLYTOMESSAGE
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/21/94   	Initial revision


DESCRIPTION:
	C interface.
		

	$Id: messageC.asm,v 1.1 97/04/05 01:20:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Mailbox	segment resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxRegisterMessage

C DECLARATION:	MailboxError (MailboxRegisterMessageArgs *mrmArgs,
				MailboxMessage *msg)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXREGISTERMESSAGE	proc	far		mrmArgs:fptr,
						msg:fptr
	.enter
	movdw	cxdx, mrmArgs
	call	MailboxRegisterMessage
	jc	exit				;return ax = MailboxError
	les	bx, msg
	movdw	es:[bx], dxax	
	mov	ax, ME_SUCCESS
exit:
	.leave
	ret
MAILBOXREGISTERMESSAGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxChangeBodyFormat

C DECLARATION:	MailboxError (MailboxMessage msg, 
				MailboxChangeBodyFormatArgs *mcbfArgs)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXCHANGEBODYFORMAT	proc	far		msg:dword,
						mcbfArgs:fptr
	uses es, di
	.enter
	movdw	cxdx, msg
	les	di, mcbfArgs
	call	MailboxChangeBodyFormat
	jc	exit				;return ax = MailboxError
	mov	ax, ME_SUCCESS
exit:
	.leave
	ret
MAILBOXCHANGEBODYFORMAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxBodyReformatted
  
C DECLARATION:	MailboxError (MailboxMessage msg, MailboxDataFormat format,
				MailboxMessageFlags newBodyFlags)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXBODYREFORMATTED	proc	far		msg:dword,
						format:MailboxDataFormat,
						newBodyFlags:MailboxMessageFlags
	.enter
	movdw	cxdx, msg
	movdw	axbx, format
	push	bp
	mov	bp, newBodyFlags
	call	MailboxBodyReformatted
	pop	bp
	jc	exit				;return ax = MailboxError
	mov	ax, ME_SUCCESS
exit:
	.leave
	ret
MAILBOXBODYREFORMATTED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetBodyFormat

C DECLARATION:	MailboxError (MailboxMessage msg, MailboxDataFormat *dataFormat)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETBODYFORMAT	proc	far		msg:dword,
						dataFormat:fptr
	.enter
	movdw	cxdx, msg
	call	MailboxGetBodyFormat
	jc	exit				;return ax = MailboxError
	mov_tr	cx, bx
	les	bx, dataFormat
	movdw	es:[bx], cxax
	mov	ax, ME_SUCCESS
exit:
	.leave
	ret
MAILBOXGETBODYFORMAT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetBodyRef

C DECLARATION:	MailboxError (MailboxMessage msg, void *appRefBuf, 
				word *appRefBufLen)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETBODYREF	proc	far		msg:dword,
						appRefBuf:fptr,
						appRefBufLen:fptr
	uses	ds,si,di
	.enter
	movdw	cxdx, msg
	les	di, appRefBuf
	lds	si, appRefBufLen
	mov	ax, ds:[si]
	call	MailboxGetBodyRef
	jc	exit				;return ax = MailboxError
	mov	ds:[si], ax			;# bytes used in buffer
	mov	ax, ME_SUCCESS
exit:
	.leave
	ret
MAILBOXGETBODYREF	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxDoneWithBody

C DECLARATION:	void (MailboxMessage msg, const void *appRef, word appRefSize)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXDONEWITHBODY	proc	far		msg:dword,
						appRef:fptr,
						appRefSize:word
	uses	ax, es, di
	.enter
	movdw	cxdx, msg
	les	di, appRef
	mov	ax, appRefSize
	call	MailboxDoneWithBody
	.leave
	ret
MAILBOXDONEWITHBODY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxStealBody

C DECLARATION:	MailboxError (MailboxMessage msg, void *appRefBuf, 
				word *appRefBufSize)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXSTEALBODY	proc	far		msg:dword,
						appRef:fptr,
						appRefSize:fptr
	uses ds, si, di
	.enter
	movdw	cxdx, msg
	les	di, appRef
	lds	si, appRefSize	
	mov	ax, ds:[si]
	call	MailboxStealBody
	jc	exit				;return ax = MailboxError
	mov	ds:[si], ax			;# bytes used in buffer
	mov	ax, ME_SUCCESS
exit:
	.leave
	ret
MAILBOXSTEALBODY	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetMessageFlags

C DECLARATION:	MailboxError (MailboxMessage msg, MailboxMessageFlags *flags)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETMESSAGEFLAGS	proc	far		msg:dword,
						msgFlags:fptr
	.enter
	movdw	cxdx, msg	
	call	MailboxGetMessageFlags
	jc	exit
	les	bx, msgFlags
	mov	es:[bx], ax			;return message flags
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETMESSAGEFLAGS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetSubjectLMem

C DECLARATION:	MailboxError (MailboxMessage msg, MemHandle lmemBlock, 
				ChunkHandle *subjectChunk)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETSUBJECTLMEM	proc	far		msg:dword,
						lmbh:hptr,
						subjChunk:fptr
	.enter
	movdw	cxdx, msg
	mov	bx, lmbh
	call	MailboxGetSubjectLMem
	jc	exit
	les	bx, subjChunk
	mov	es:[bx], ax
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETSUBJECTLMEM	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetSubjectBlock

C DECLARATION:	MailboxError (MailboxMessage msg, MemHandle *subjHandle)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETSUBJECTBLOCK	proc	far		msg:dword,
						subj:fptr.hptr
	.enter
	movdw	cxdx, msg
	call	MailboxGetSubjectBlock
	jc	exit
	mov_tr	ax, bx
	les	bx, subj
	mov	es:[bx], ax
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETSUBJECTBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxAcknowledgeMessageReceipt

C DECLARATION:	void (MailboxMessage msg)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXACKNOWLEDGEMESSAGERECEIPT	proc	far	msg:dword
	.enter
	movdw	cxdx, msg
	call	MailboxAcknowledgeMessageReceipt
	.leave
	ret
MAILBOXACKNOWLEDGEMESSAGERECEIPT	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetDestApp

C DECLARATION:	MailboxError (MailboxMessage msg, GeodeToken *tokenBuf)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETDESTAPP	proc	far		msg:dword,
						tokenBuf:fptr.GeodeToken
	uses	es, di
	.enter
	movdw	cxdx, msg
	les	di, tokenBuf
	call	MailboxGetDestApp
	jc	exit
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETDESTAPP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetStorageType

C DECLARATION:	MailboxError (MailboxMessage msg, MailboxStorage *storage)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETSTORAGETYPE	proc	far		msg:dword,
						storage:fptr.MailboxStorage
	.enter
	movdw	cxdx, msg
	call	MailboxGetStorageType
	jc	exit
	mov_tr	cx, bx
	les	bx, storage
	movdw	es:[bx], cxax
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETSTORAGETYPE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxSetTransAddr

C DECLARATION:	MailboxError (MailboxMessage msg, const void *newAddress,
				word bufSize, word addrNumber)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXSETTRANSADDR	proc	far		msg:dword,
						addrNumber:word,
						newAddr:fptr,
						addrSize:word
	uses	di
	.enter
	movdw	cxdx, msg
	les	di, newAddr
	mov	bx, addrNumber
	mov	ax, addrSize
	call	MailboxSetTransAddr
	jc	exit
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXSETTRANSADDR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetTransAddr

C DECLARATION:	Boolean (MailboxMessage msg, word addrNumber, void *addrBuf,
  			 word *bufSizePtr)
		returns FALSE if error.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETTRANSADDR	proc	far		msg:dword,
						addrNum:word,
						addrBuf:fptr,
						bufSizePtr:fptr.word
	uses	ds, si, di
	.enter
	movdw	cxdx, msg
	les	di, addrBuf
	lds	si, bufSizePtr
	mov	ax, ds:[si]
	mov	bx, addrNum
	call	MailboxGetTransAddr
	mov	ds:[si], ax
	mov	ax, 0
	jc	exit				;return 0 if error
	dec 	ax
exit:
	.leave
	ret
MAILBOXGETTRANSADDR	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetUserTransAddrLMem

C DECLARATION:	MailboxError (MailboxMessage msg, word addrNumber,
			      MemHandle lmemBlock, ChunkHandle *addrChunk)


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SSH	08/95		Initial version

------------------------------------------------------------------------------@
MAILBOXGETUSERTRANSADDRLMEM	proc	far		msg:dword,
							addrNumber:word,
							lmbh:hptr,
							addrChunk:fptr
	.enter
	mov	ax, addrNumber	
	movdw	cxdx, msg
	mov	bx, lmbh
	call	MailboxGetUserTransAddrLMem
	jc	exit
	les	bx, addrChunk
	mov	es:[bx], ax
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETUSERTRANSADDRLMEM	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetNumTransAddrs

C DECLARATION:	MailboxError (MailboxMessage msg, word *numAddresses)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETNUMTRANSADDRS	proc	far		msg:MailboxMessage,
						numAddr:fptr.word
	.enter
	movdw	cxdx, msg
	call	MailboxGetNumTransAddrs
	jc	exit				;return ax = MailboxError
	les	bx, numAddr
	mov	es:[bx], ax
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETNUMTRANSADDRS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxReportPercentage

C DECLARATION:	void (MailboxProgressType type, dword data, MailboxProgressAction action)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
ife MAILBOX_PERSISTENT_PROGRESS_BOXES
    MailboxProgressType type word
    MailboxProgressAction type word
endif

MAILBOXREPORTPROGRESS	proc	far	ptype:MailboxProgressType,
					data:dword,
					action:MailboxProgressAction
if	MAILBOX_PERSISTENT_PROGRESS_BOXES

	.enter
	mov	ax, ss:[ptype]
	movdw	cxdx, ss:[data]
	mov	bp, ss:[action]		; (can nuke bp b/c we have no local
					;  vars, so Esp won't generate
					;  mov sp, bp)
	call	MailboxReportProgress
	.leave
	ret
else
	ForceRef	ptype
	ForceRef	data
	ForceRef	action
	.enter	inherit			; tell Esp not to whine, but don't
					;  bother to actually set up the frame
	.leave
	ret	@ArgSize		; clear the args from the stack, please
					;  (doesn't happen for inherited frame)

endif	; MAILBOX_PERSISTENT_PROGRESS_BOXES

MAILBOXREPORTPROGRESS	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetCancelFlag

C DECLARATION:	word * (void)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETCANCELFLAG	proc	far		
	.enter
	call	MailboxGetCancelFlag
	.leave
	ret
MAILBOXGETCANCELFLAG	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxSetTransData

C DECLARATION:	MailboxError (MailboxMessage msg, dword transData)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXSETTRANSDATA	proc	far		msg:dword,
						transData:dword
	.enter
	movdw	cxdx, msg
	movdw	bxax, transData
	call	MailboxSetTransData
	.leave
	ret
MAILBOXSETTRANSDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetTransData

C DECLARATION:	MailboxError (MailboxMessage msg, dword *transData)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETTRANSDATA	proc	far		msg:dword,
						transData:fptr
	.enter
	movdw	cxdx, msg
	call	MailboxGetTransData
	jc	exit			;return ax = MailboxError
	mov_tr	cx, bx
	les	bx, transData
	movdw 	es:[bx], cxax
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETTRANSDATA	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetBodyMboxRefBlock

C DECLARATION:	MailboxError (MailboxMessage msg, MemHandle *mboxRefHan)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETBODYMBOXREFBLOCK	proc	far		msg:dword,
							mboxRefHan:fptr
	.enter
	movdw	cxdx, msg
	call	MailboxGetBodyMboxRefBlock
	jc	exit			;return ax = MailboxError
	mov_tr	ax, bx
	les	bx, mboxRefHan
	mov 	es:[bx], ax
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETBODYMBOXREFBLOCK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetStartBound

C DECLARATION:	MailboxError (MailboxMessage msg, FileDateAndTime *dateTime)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETSTARTBOUND	proc	far

	mov	ax, offset MailboxGetStartBound
	jmp	messageGetStartEndBoundCommon

MAILBOXGETSTARTBOUND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxGetEndBound

C DECLARATION:	MailboxError (MailboxMessage msg, FileDateAndTime *dateTime)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXGETENDBOUND	proc	far		msg:dword,
						dateTime:fptr.FileDateAndTime

	mov	ax, offset MailboxGetEndBound

messageGetStartEndBoundCommon	label	near
	.enter
		CheckHack <seg MailboxGetStartBound eq seg MailboxGetEndBound>
	mov	bx, vseg MailboxGetStartBound
	movdw	cxdx, msg
	call	ProcCallFixedOrMovable	; axbx = FileDateAndTime
	jc	exit
	push	di
	les	di, dateTime
	xchg	ax, bx			; ax = FDAT_date
	stosw
	mov_tr	ax, bx			; ax = FDAT_time
	stosw
	pop	di
		CheckHack <ME_SUCCESS eq 0>
	clr	ax
exit:
	.leave
	ret
MAILBOXGETENDBOUND	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxDeleteMessage

C DECLARATION:	void (MailboxMessage msg)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CHL	11/94		Initial version

------------------------------------------------------------------------------@
MAILBOXDELETEMESSAGE	proc	far		msg:dword
	.enter
	movdw	cxdx, msg
	call	MailboxDeleteMessage
	.leave
	ret
MAILBOXDELETEMESSAGE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	MailboxReplyToMessage

C DECLARATION:	MailboxError (MailboxReplyToMessageArgs *mrtmArgs,
				MailboxMessage *msg)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	2/9/95		Initial version

------------------------------------------------------------------------------@
MAILBOXREPLYTOMESSAGE	proc	far		mrtmArgs:fptr,
						msg:fptr
	.enter

	movdw	cxdx, ss:[mrtmArgs]
	call	MailboxReplyToMessage
	jc	exit			; return ax = MailboxError
	push	es, di
	les	di, ss:[msg]
	stosw
	mov_tr	ax, dx
	stosw
	pop	es, di
		CheckHack <ME_SUCCESS eq 0>
	clr	ax			; ax = ME_SUCCESS
exit:
	.leave
	ret
MAILBOXREPLYTOMESSAGE	endp

C_Mailbox	ends

	SetDefaultConvention
