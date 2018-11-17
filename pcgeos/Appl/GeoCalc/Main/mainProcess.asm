COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		mainProcess.asm
FILE:		mainProcess.asm

AUTHOR:		Gene Anderson, Jun 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/12/92		Initial revision

DESCRIPTION:
	

	$Id: mainProcess.asm,v 1.1 97/04/04 15:49:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PROTECT_CELL
DisplayCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcProcessSetProtectionTrigVal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the vardata of the cell protection trigger to the
		corresponding SpreadsheetProtectionOptions.

CALLED BY:	MSG_GEOCALC_PROCESS_SET_PROTECTION_TRIG_VAL
PASS:		ds = dgroup
		es = segment of the GeoCalcProcessClass
		cl = SpreadsheetProtectionOptions
		bp = # of selections
		dl = GenItemGroupStateFlags
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:
PSEUDO CODE/STRATEGY:

	* Set up the values of the parameter on stack.
	* Send the message to both cell protection triggers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcProcessSetProtectionTrigVal	method dynamic GeoCalcProcessClass ,
				MSG_GEOCALC_PROCESS_SET_PROTECTION_TRIG_VAL
varData		local	word			push cx
varDataParams	local	AddVarDataParams		
		.enter

	;
	; Set up the parameters to pass
	;
		mov	varDataParams.AVDP_data.segment, ss
		lea	ax, varData
		mov	varDataParams.AVDP_data.offset, ax
		mov	varDataParams.AVDP_dataSize, \
				size SpreadsheetProtectionOptions
		mov	varDataParams.AVDP_dataType, \
				ATTR_GEN_TRIGGER_ACTION_DATA
		or	varDataParams.AVDP_dataType, mask VDF_SAVE_TO_STATE
	;
	; Send the message to both cell protection triggers
	;
		GetResourceHandleNS ProtectTrigger, bx
		mov	si, offset ProtectTrigger	;^lbx:si = trigger obj
		call	callSetVarData			;ax,cx,dx trashed
		mov	si, offset UnprotectTrigger	;^lbx:si = trig obj
		call	callSetVarData			;ax,cx,dx trashed
		
		.leave
		ret
callSetVarData:
	;
	;	^lbx:si = trigger obj
	;	ax, cx, dx - destroyed
	;
		push	bp
		lea	bp, varDataParams
		mov	dx, size AddVarDataParams
		mov	di, mask MF_CALL or mask MF_STACK
		mov	ax, MSG_META_ADD_VAR_DATA
		call	ObjMessage
		pop	bp
		retn
GeoCalcProcessSetProtectionTrigVal		endm
DisplayCode	ends
endif		; if _PROTECT_CELL

