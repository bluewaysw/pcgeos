COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		taskUtils.asm

AUTHOR:		Adam de Boor, Oct  4, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/4/91		Initial revision


DESCRIPTION:
	Switcher-independent utility routines.
		



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource
if _BNF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskChunkError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up an error box given error strings in the TaskStrings
		resource.

CALLED BY:	?
PASS:		bp	= chunk handle of format string
		dx	= chunk handle of arg 1
		si	= chunk handle of arg 2
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskChunkError proc	near
		.enter
		mov	ax, CustomDialogBoxFlags <
			1,			; CDBF_SYSTEM_MODAL
			CDT_ERROR,		; CDBF_TYPE
			GIT_NOTIFICATION,0	; CDBF_RESPONSE_TYPE
		>
		mov	di, handle TaskStrings
		mov	cx, di
		mov	bx, di
		call	TaskDoStandardChunkDialog
		.leave
		ret
TaskChunkError endp

endif


if	_BNF

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TaskDoStandardChunkDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call UserStandardDialog passing strings described by
		optrs, rather than fptrs.

CALLED BY:	TaskChunkError and others
PASS:		al	= StandardDialogBoxType
		if al == SDBT_CUSTOM:
			ah	= CustomDialogBoxFlags

		^ldi:bp	= format string (always passed)
		^lcx:dx	= first string argument
		^lbx:si	= second string argument
RETURN:		ax	= InteractionCommand
DESTROYED:	bx, cx, dx, si, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TaskDoStandardChunkDialog	proc	near
		.enter

	CheckHack <SDOP_customFlags eq 0>
	CheckHack <SDOP_customString eq 2>
	CheckHack <SDOP_stringArg1 eq 6>
	CheckHack <SDOP_stringArg2 eq 10>
	CheckHack <SDOP_customTriggers eq 14>
	CheckHack <SDOP_helpContext eq 18>
	CheckHack <size StandardDialogOptrParams eq 22>

		push	ax, ax,			; SDOP_helpContext
			ax, ax,			; SDOP_customTriggers (n/a)
			bx, si,			; SDOP_stringArg2
			cx, dx,			; SDOP_stringArg1
			di, bp,			; SDOP_customString
			ax			; SDOP_customFlags, SDOP_type
		mov	bp, sp
		mov	ss:[bp].SDP_customTriggers.handle, 0
		call	UserStandardDialogOptr

		.leave
		ret
TaskDoStandardChunkDialog	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TDCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent attaching to/creating any state file

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		ds = es	= dgroup
		ax	= MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		cx	= AppAttachMode
		dx	= Block handle of AppInstanceReference
RETURN:		ax	= file handle of state file (=== 0)
DESTROYED:	oh, you know. The usual.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TDCreateNewStateFile method TaskDriverClass,
				  MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		.enter
		clr	ax
		.leave
		ret
TDCreateNewStateFile endm

Movable		ends
