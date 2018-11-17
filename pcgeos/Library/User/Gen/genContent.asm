COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genContent.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenContentClass		Content object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/89		Initial version
	Doug	11/90		Converted to esp object declaration

DESCRIPTION:
	This file contains routines to implement the Content class

	$Id: genContent.asm,v 1.1 97/04/07 11:45:08 newdeal Exp $
	
------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenContent.doc

UserClassStructures	segment resource

	; Declare the class record for GenContentClass.  
	; Esp will generate a relocation table for us.

	GenContentClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenContentBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenContentClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenContentClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenContentBuild	method	GenContentClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS

				; See if determining superclass for Gen
				; master class
	cmp	cx, offset Gen_offset
	jne	GCB_NotBuildingGen

	mov	ax, SPIR_BUILD_CONTENT
	GOTO	GenQueryUICallSpecificUI

GCB_NotBuildingGen:
				; Send to specific master class, instead
	mov	di, offset GenClass
	GOTO	ObjCallSuperNoLock

GenContentBuild	endm

Build ends

      
BuildUncommon	segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenContentSetAttrs -- 
		MSG_GEN_CONTENT_SET_ATTRS for GenContentClass

DESCRIPTION:	Sets attributes for the GenContent.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_CONTENT_SET_ATTRS
		cl	- VisContentAttrs to set
		ch	- VisContentAttrs to clear

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/ 5/91		Initial Version

------------------------------------------------------------------------------@

GenContentSetAttrs	method dynamic	GenContentClass, \
					MSG_GEN_CONTENT_SET_ATTRS
	mov	bl, cl					;put horiz attrs in bl
	and	bl, ds:[di].GCI_attrs
	cmp	bl, cl					;anything changing?
	jnz	10$					;yes, go do it
	mov	bl, ch					;get attrs to clear
	and	bl, ds:[di].GCI_attrs			;anything to clear?
	jnz	20$					;yes, go do it
	jmp	short exit				;else exit
10$:
	or	ds:[di].GCI_attrs, cl			;set bits
20$:
	not	ch
	and	ds:[di].GCI_attrs, ch			;clear bits
	not 	ch
	call	ObjMarkDirty				;mark stuff as dirty
	
	mov	ax, MSG_VIS_CONTENT_SET_ATTRS
	call	GenCallSpecIfGrown			;call specific UI if
							;   grown
exit:
	Destroy	ax, cx, dx, bp
	ret
GenContentSetAttrs	endm


BuildUncommon	ends

;
;---------------
;
		
GetUncommon	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenContentGetAttrs -- 
		MSG_GEN_CONTENT_GET_ATTRS for GenContentClass

DESCRIPTION:	Returns attributes for the content.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_CONTENT_GET_ATTRS

RETURN:		cl -- VisContentAttrs
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	12/ 5/91		Initial Version

------------------------------------------------------------------------------@

GenContentGetAttrs	method dynamic	GenContentClass, \
				MSG_GEN_CONTENT_GET_ATTRS
	Destroy	ax, cx, dx, bp
	mov	cl, ds:[di].GCI_attrs
	ret
GenContentGetAttrs	endm

GetUncommon ends
