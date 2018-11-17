COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Spool/Process
FILE:		processC.asm

AUTHOR:		Jenny Greenwood, Aug 17, 1993

ROUTINES:
	Name			Description
	----			-----------
	SPOOLDELJOB 	    	Delete a job from the spooler queue.
	SPOOLINFO   	    	Check for active queues or get a list of
    		    	    	all job ID's in a queue *OR* get the
    	    	    	    	JobStatus structure for a job.
	SPOOLHURRYJOB	    	Push a job to the front of the print queue.
	SPOOLDELAYJOB	    	Push a job to the end of the print queue.
	SPOOLMODIFYPRIORITY 	Modify the priority of a queue's thread.
	SPOOLVERIFYPRINTERPORT	Verify the existence of a printer port.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/17/93		Initial version

DESCRIPTION:
	This file contains C interface routines for the spool library

	$Id: processC.asm,v 1.1 97/04/07 11:11:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Spool	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLDELJOB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a job from the spooler queue.

CALLED BY:	GLOBAL
PARAMETERS:	SpoolOpStatus (word jobID)
RETURN:		status of operation:
			SPOOL_OPERATION_SUCCESSFUL
			SPOOL_JOB_NOT_FOUND
			SPOOL_QUEUE_EMPTY
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLDELJOB	proc	far
		C_GetOneWordArg cx,  ax, dx	; cx <- jobID
		call SpoolDelJob
    	    	ret
SPOOLDELJOB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLINFO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:   	Check for active queues or get a list of all job ID's in a
    		queue *OR* get the JobStatus structure for a job.

CALLED BY:	GLOBAL
PARAMETERS:	SpoolOpStatus (SpoolInfoType infoType,
			       SpoolInfoParams *params)

RETURN:	    	If infoType = SIT_QUEUE_INFO
       	    	    if SIQP_activityQuery != 0, returns
 		    	SPOOL_QUEUE_NOT_EMPTY if at least one queue is active
 		    	SPOOL_QUEUE_EMPTY if no queues are active
 
   	    	    if SIQP_activityQuery = 0, then on success returns
 		    	SPOOL_OPERATION_SUCCESSFUL and
 		    	(params->SIP_queueParams).SIQP_retBlock
    	    	    	    	    	 	= handle of block holding
 			    	    	      	  ID's of all jobs in queue,
   	    	    	    	    	    	  listed in the order they
   	    	    	    	    	    	  sit in the queue, currently
   	    	    	    	    	    	  active job first.

 		    	(params->SIP_queueParams).SIQP_retNumJobs	
    	    	    	    	    	    	= # ID's in block
 
 		    if SIQP_activityQuery = 0, then on failure returns one of
 			SPOOL_QUEUE_NOT_FOUND
 			SPOOL_QUEUE_EMPTY
 
   	    	*************************************************************
 
 	    	If infoType = SIT_JOB_INFO,
 	    	    on success returns
    	    	    	SPOOL_OPERATION_SUCCESSFUL and
     	    	    	(params->SIP_jobParams).SIJP_retBlock
    	    	    	    	    	    	= handle of block holding
 				    	    	  JobStatus structure
 		    on failure, returns one of
 			SPOOL_JOB_NOT_FOUND
 			SPOOL_QUEUE_EMPTY
 
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Parameters for SpoolInfoQueue (called by SpoolInfo).
;
SpoolInfoQueueParams	struct
	SIQP_activityQuery  word
	SIQP_portInfo	    fptr.PrintPortInfo
	SIQP_retBlock	    hptr
	SIQP_retNumJobs	    word
SpoolInfoQueueParams	ends

;
; Parameters for SpoolInfoJob (called by SpoolInfo).
;
SpoolInfoJobParams	struct
	SIJP_jobID	word
	SIJP_retBlock	hptr
SpoolInfoJobParams	ends

;
; Parameters to pass to SpoolInfo.
;
SpoolInfoParams		union
	SIP_queueParams	SpoolInfoQueueParams	
	SIP_jobParams	SpoolInfoJobParams	
SpoolInfoParams		ends

SPOOLINFO	proc	far	infoType:SpoolInfoType,
				params:fptr.SpoolInfoParams
		uses	ds, si
		.enter
		lds	si, ss:[params]
		push	si
		mov	cx, ss:[infoType]
	;
	; SpoolInfo will call either SpoolInfoQueue or SpoolInfoJob
	; depending on the SpoolInfoType now in cx. We set up the
	; parameters for either.
	;
    	CheckHack <offset SIJP_jobID eq offset SIQP_activityQuery>
    	    	mov 	dx, ds:[si].SIJP_jobID
    	    	push	dx  	    	    	    	; save in case it's an
							;  activity query
		cmp	cx, SIT_QUEUE_INFO
		jne	doCall
		tst	dx  	    	    	    	; check for active queues?
		jnz	doCall	    	    	    	; yes
		movdw	dxsi, ds:[si].SIQP_portInfo
doCall:		
    	    	push 	cx
		call	SpoolInfo
	;
	; Now we store the return value(s) from...
	;
    	    	pop 	dx    	    	    	    	; dx <- infoType
    	    	cmp	dx, SIT_QUEUE_INFO
    	    	pop	dx  	    	    	    	; dx <- SIQP_activityQuery
		pop	si			    	; *ds:si <- params
    	    	jne 	jobInfo
    	;
    	; ... SpoolInfoQueue.
    	;
		tst	dx  	    	    	    	; check for active queues?
		jne	done	    	    	    	; yes
		mov	ds:[si].SIQP_retBlock, bx
		mov	ds:[si].SIQP_retNumJobs, cx						; that's ok
done:
		.leave
		ret
jobInfo:
    	;
    	; ... SpoolInfoJob.
    	;
    	    	mov	ds:[si].SIJP_retBlock, bx
    	    	jmp 	done
SPOOLINFO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLHURRYJOB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a job to the front of the print queue.

CALLED BY:	GLOBAL
PARAMETERS:	SpoolOpStatus (word jobID)
RETURN:		status of operation
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLHURRYJOB	proc	far
		C_GetOneWordArg cx,  ax, dx	; cx <- jobID
		call	SpoolHurryJob
		ret
SPOOLHURRYJOB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLDELAYJOB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a job to the end of the print queue.

CALLED BY:	GLOBAL
PARAMETERS:	SpoolOpStatus (word jobID)
RETURN:		status of operation
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLDELAYJOB	proc	far
		C_GetOneWordArg cx,  ax, dx	; cx <- jobID
		call	SpoolDelayJob
		ret
SPOOLDELAYJOB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLMODIFYPRIORITY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify the priority of a queue's thread.

CALLED BY:	GLOBAL
PARAMETERS:	SpoolOpStatus (word jobID, ThreadPriority priority)
RETURN:		status of operation
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLMODIFYPRIORITY	proc	far	jobID:word,
					priority:ThreadPriority
    	    	.enter
		mov	cx, ss:[jobID]
		mov	dl, ss:[priority]
		call	SpoolModifyPriority
    	    	.leave
		ret
SPOOLMODIFYPRIORITY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SPOOLVERIFYPRINTERPORT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the existence of a printer port.

CALLED BY:	GLOBAL
PARAMETERS:	SpoolOpStatus (PrintPortInfo *portInfo)
RETURN:		status of operation
			either	SPOOL_OPERATION_SUCCESSFUL
			or	SPOOL_CANT_VERIFY_PORT
SIDE EFFECTS:
	currently will always return success for custom ports

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	8/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SPOOLVERIFYPRINTERPORT	proc	far	portInfo:fptr

		uses	ds, si
		.enter
		lds	si, ss:[portInfo]		; ds:si <- ptr
		call	SpoolVerifyPrinterPort
		.leave
		ret
SPOOLVERIFYPRINTERPORT	endp

C_Spool	    ends

	SetDefaultConvention
