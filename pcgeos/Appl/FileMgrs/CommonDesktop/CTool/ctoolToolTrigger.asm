COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		ctoolToolTrigger.asm

AUTHOR:		Adam de Boor, Aug 25, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	8/25/92		Initial revision


DESCRIPTION:
	Implementation of ToolTrigger object.
		

	$Id: ctoolToolTrigger.asm,v 1.1 97/04/04 15:02:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ToolCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTSetFileSelectionState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable ourselves, if appropriate, to reflect
		whether there's anything on which this tool can operate.

CALLED BY:	MSG_TT_SET_FILE_SELECTION_STATE
PASS:		*ds:si	= ToolTrigger object
		ds:di	= ToolTriggerInstance
		cx	= non-zero if anything's selected
RETURN:		nothing
DESTROYED:	allowed: ax, cx, dx, bp
SIDE EFFECTS:	object may be enabled or disabled

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTSetFileSelectionState method dynamic ToolTriggerClass, MSG_TT_SET_FILE_SELECTION_STATE
		.enter
		test	ds:[di].TTI_flags, mask FMTF_SELECTED_ONLY
		jz	done
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		jcxz	enableDisable
		mov	ax, MSG_GEN_SET_ENABLED
enableDisable:
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
TTSetFileSelectionState endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize various aspects of this trigger from the table
		entry in the library.

CALLED BY:	MSG_TT_SETUP
PASS:		*ds:si	= ToolTrigger object
		ds:di	= ToolTriggerInstance
		ss:bp	= ToolTriggerSetupArgs
		dx	= size ToolTriggerSetupArgs
RETURN:		nothing
DESTROYED:	allowed: ax, cx, dx, bp
SIDE EFFECTS:	moniker is set for the object

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTSetup		method dynamic ToolTriggerClass, MSG_TT_SETUP
		.enter
	;
	; Fetch the library index and tool number and store them away.
	; 
		mov	ax, ss:[bp].TTSA_library
		mov	ds:[di].TTI_library, ax
		mov	ax, ss:[bp].TTSA_number
		mov	ds:[di].TTI_number, ax
	;
	; Dereference the pointer to the tool descriptor and copy in the
	; routine number and flags.
	; 
		les	bx, ss:[bp].TTSA_toolStruct
		mov	ax, es:[bx].FMTS_routineNumber
		mov	ds:[di].TTI_routine, ax
		mov	ax, es:[bx].FMTS_flags
		mov	ds:[di].TTI_flags, ax
	;
	; Set the moniker as our moniker.
	; 
		movdw	cxdx, es:[bx].FMTS_moniker
		mov	bp, VUM_MANUAL
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		call	ObjCallInstanceNoLock
	;
	; Set HINT_TRIGGER_BRINGS_UP_WINDOW if the tool is marked as a dialog.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].ToolTrigger_offset
		mov	ax, ds:[di].TTI_flags
		andnf	ax, mask FMTF_TYPE
		cmp	ax, FMTT_DIALOG shl offset FMTF_TYPE
		jne	done
		
		mov	ax, HINT_TRIGGER_BRINGS_UP_WINDOW
		clr	cx
		call	ObjVarAddData
done:
		.leave
		ret
TTSetup		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with being activated by the user.

CALLED BY:	MSG_GEN_TRIGGER_TRIGGER
PASS:		*ds:si	= ToolTrigger object
		ds:di	= ToolTriggerInstance
RETURN:		nothing
DESTROYED:	allowed: ax, cx, dx, bp
SIDE EFFECTS:	the routine bound to the object is called within the
		    tool's library

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTTrigger	method dynamic ToolTriggerClass, MSG_GEN_OUTPUT_ACTION
		.enter
	;
	; Tell our process thread to call the library for us, indirecting
	; through the Tool Manager to get the library handle.
	; 
		mov	cx, ds:[di].TTI_library
		mov	bp, ds:[di].TTI_routine
		mov	dx, ds:[di].TTI_number
		mov	ax, MSG_TM_ACTIVATE_TOOL_ON_PROCESS_THREAD
		call	GenCallParent
		.leave
		ret
TTTrigger	endm

ToolCode	ends
