COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		GenItem.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenItemClass		Item object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

DESCRIPTION:
	This file contains routines to implement the item class

	$Id: genItem.asm,v 1.1 97/04/07 11:45:22 newdeal Exp $

------------------------------------------------------------------------------@
	
UserClassStructures	segment resource

; Declare the class record

	GenItemClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenItemBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenItemClass

DESCRIPTION:	Return the correct specific class for an object

PASS:
	*ds:si - instance data (for object in a GenXXXX class)
	es - segment of GenClass

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
	Doug	5/89		Initial version

------------------------------------------------------------------------------@

GenItemBuild	method	GenItemClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_ITEM
	GOTO	GenQueryUICallSpecificUI

GenItemBuild	endm

Build ends

ItemCommon segment resource




COMMENT @----------------------------------------------------------------------

METHOD:		GenItemGetIdentifier -- 
		MSG_GEN_ITEM_GET_IDENTIFIER for GenItemClass

DESCRIPTION:	Returns current identifier.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_GET_IDENTIFIER

RETURN:		ax	- identifier
		cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemGetIdentifier	method dynamic	GenItemClass, \
				MSG_GEN_ITEM_GET_IDENTIFIER

	mov	ax, ds:[di].GII_identifier
	Destroy	cx, dx, bp
	ret
GenItemGetIdentifier	endm





COMMENT @----------------------------------------------------------------------

METHOD:		GenItemSetIdentifier -- 
		MSG_GEN_ITEM_SET_IDENTIFIER for GenItemClass

DESCRIPTION:	Sets a new identifier.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_ITEM_SET_IDENTIFIER

		cx	- new id

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
	chris	2/20/92		Initial Version

------------------------------------------------------------------------------@

GenItemSetIdentifier	method dynamic	GenItemClass, \
				MSG_GEN_ITEM_SET_IDENTIFIER
	mov	bx, offset GII_identifier
	call	GenSetWord
	Destroy	ax, cx, dx, bp
	ret
GenItemSetIdentifier	endm




ItemCommon ends


