COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	DataStore
MODULE:		PipePort
FILE:		pipeportAppl.asm

AUTHOR:		Taylor Gautier, Jan 13, 1997

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tgautier	1/13/97   	Initial revision


DESCRIPTION:
		
	

	$Id: pipeportAppl.asm,v 1.1 97/04/04 17:54:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DSPipePortCustomRoutines segment lmem LMEM_TYPE_GENERAL

DSPipePortRoutineTable	chunk.RoutineTableEntry \
	<DXIW_DEFAULT_BEHAVIOR, DataStorePipePortDefault>,
	<DXIW_DONE, DataStorePipePortDone>,
	<DXIW_INITIALIZE, DataStorePipePortInitialize>, 
	<DXIW_IMPORT, DataStorePipePortImport>, 
	<DXIW_EXPORT, DataStorePipePortExport>, 
	<DXIW_SINGLE_RECORD_EXPORT, DataStorePipePortSingleRecordExport>,
	<DXIW_CLEAN_SHUTDOWN, DataStorePipePortShutdown>, 
	<0,(size DSPipePortData)>

DSPipePortCustomRoutines ends

PipePort 	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DSAMetaIacpDataExchange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept and set some params.  Since we're not an app
		we can't statically define our instance data.

CALLED BY:	MSG_META_IACP_DATA_EXCHANGE
PASS:		*ds:si	= DTApplicationClass object
		ds:di	= DTApplicationClass instance data
		ds:bx	= DTApplicationClass object (same as *ds:si)
		es 	= segment of DTApplicationClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	tgautier	1/13/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DSAMetaIacpDataExchange	method dynamic DSApplicationClass, 
					MSG_META_IACP_DATA_EXCHANGE
	.enter

	mov	ds:[di].DXA_iacpInitParameters.low, offset \
						    DSPipePortRoutineTable
	mov	ds:[di].DXA_iacpInitParameters.high, handle \
						     DSPipePortRoutineTable
	mov	di, offset DSApplicationClass		; call parent
	call	ObjCallSuperNoLock			; class msg handler

	.leave
	ret
DSAMetaIacpDataExchange	endm

PipePort ends
