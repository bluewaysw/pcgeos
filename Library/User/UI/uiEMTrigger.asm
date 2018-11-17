COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ui	
FILE:		uiEMTriggerClass.asm

AUTHOR:		Ian Porteous, Jun 15, 1994

ROUTINES:
	Name			Description
	----			-----------
	EMTriggerClass		This is a subclass of GenTrigger that
				with EMObjectManager Class.
				EMTriggerClass returns MSG_EMOM_ACK
				back to the EMOM object that created
				it.  This functionality is needed for
				the EMObjectManager detach mechanism. 
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/15/94   	Initial revision


DESCRIPTION:
	routines for the EMTrigger class
		

	$Id: uiEMTrigger.asm,v 1.1 97/04/07 11:47:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserClassStructures	segment	resource
	EMTriggerClass
UserClassStructures	ends


EMTriggerCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMTSetEmomAckDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the EMTI_ackDestination to the optr of the object
		that should receive MSG_EMOM_ACK when this object is
		freed 

CALLED BY:	MSG_EMT_SET_EMOM_ACK_DEST
PASS:		*ds:si	= EMTriggerClass object
		ds:di	= EMTriggerClass instance data
		ds:bx	= EMTriggerClass object (same as *ds:si)
		es 	= segment of EMTriggerClass
		ax	= message #
		^lcx:dx	= optr of object to receive MSG_EMOM_ACK
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMTSetEmomAckDest	method dynamic EMTriggerClass, 
					MSG_EMT_SET_EMOM_ACK_DEST
	.enter
	movdw	ds:[di].EMTI_ackDestination, cxdx
	.leave
	ret
EMTSetEmomAckDest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EMTMetaFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the EMOM object whose optr is in
		EMTI_ackDestination to inform it that you have gone away

CALLED BY:	MSG_META_FINAL_OBJ_FREE
PASS:		*ds:si	= EMTriggerClass object
		ds:di	= EMTriggerClass instance data
		ds:bx	= EMTriggerClass object (same as *ds:si)
		es 	= segment of EMTriggerClass
		ax	= message #
RETURN:		nothing	
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	6/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EMTMetaFinalObjFree	method dynamic EMTriggerClass, 
					MSG_META_FINAL_OBJ_FREE
	.enter
	push	si
	movdw	bxsi, ds:[di].EMTI_ackDestination
	mov	ax, MSG_EMOM_ACK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	ax, MSG_META_FINAL_OBJ_FREE
	mov	di, offset EMTriggerClass
	call	ObjCallSuperNoLock
	
	.leave
	ret
EMTMetaFinalObjFree	endm

EMTriggerCommon	ends























