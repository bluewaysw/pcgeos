COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecPrimary.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildPrimary		Convert a generic primary window to the OL
				equivalent
   INT	DoSimpleWinBuild	Create and initialize a temporary block for a
				window object.  This routine is called at
				MSG_META_RESOLVE_VARIANT_SUPERCLASS time.  The temporary chunk is
				used at SpecBuild.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
of a generic primary window.

	$Id: cspecPrimary.asm,v 2.17 94/11/28 22:15:21 clee Exp $

------------------------------------------------------------------------------@

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	OLBuildPrimary

DESCRIPTION:	Return the specific UI class for a GenPrimary

CALLED BY:	GLOBAL

PASS:
	*ds:si - instance data
	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx, dx, bp - ?

RETURN:
	cx:dx - class (cx = 0 for no conversion)

DESTROYED:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@


;PLACE HINT TABLE HERE TO ALLOW FALL-THROUGH BELOW

OLPrimaryHintHandlers	VarDataHandler \
	<HINT_WIN_ICON, offset Build:OLPrimaryHintWinIcon>

OLPrimaryHintWinIcon	proc	far

ifndef NO_WIN_ICONS
	mov	dx, offset OLWinIconClass
endif
	ret
OLPrimaryHintWinIcon	endp


OLBuildPrimary	proc	far

	; Use the standard routine DoSimpleWinBuild to set up the temporary
	; chunk needed by SpecBuild.

	; Default to OLBaseWinClass

	mov	dx, offset OLBaseWinClass

	;A hint can cause us to be a OLWinIconClass

	mov	di, cs
	mov	es, di
	mov	di, offset cs:OLPrimaryHintHandlers
	mov	ax, length (cs:OLPrimaryHintHandlers)
	call	ObjVarScanData			;returns dx = class offset

	; Pass the query type to use with GUP_QUERY to find the visual
	; parent for the object

	mov	cx, SQT_VIS_PARENT_FOR_PRIMARY
	FALL_THRU	DoSimpleWinBuild

OLBuildPrimary	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	DoSimpleWinBuild

DESCRIPTION:	Create and initialize a temporary block for a window object.
		This routine is called at MSG_META_RESOLVE_VARIANT_SUPERCLASS time.  The temporary
		chunk is used at SpecBuild.

CALLED BY:	OLBuildPrimary, OLBuildDisplay

PASS:
	cx - GUP_QUERY type used to find vis parent
	dx - offset of specific class

RETURN:
	variable data with OLMapGroupData structure created
	cx:dx - specific class

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

DoSimpleWinBuild	proc	far
	class	OLCtrlClass
	
	;Store data for SpecBuild -- first find our visual parent

	push	dx
	mov	ax, MSG_SPEC_GUP_QUERY_VIS_PARENT
	call	GenCallParent		;returns ^lcx:dx = VisParent
ife _JEDIMOTIF
EC <	ERROR_NC	WINDOW_REQUIRES_PARENT_OBJECT			>
EC <	call	ECCheckODCXDX						>
endif
	;Allocate a temporary chunk

	call	AllocMapChunk

; Ptr to entry returned from AllocMapChunk
;	call	FindMapChunk		;ds:bx = OLMapGroupDataEntry
	
	mov	ds:[bx].OLMGDE_visParent.handle, cx
	mov	ds:[bx].OLMGDE_visParent.chunk, dx

	;return class (all classes in idata)

	mov	cx, segment CommonUIClassStructures
	pop	dx
	ret

DoSimpleWinBuild	endp


Build ends
