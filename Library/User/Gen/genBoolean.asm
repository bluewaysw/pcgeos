COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		GenBoolean.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenBooleanClass		Item object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/92		Initial version

DESCRIPTION:
	This file contains routines to implement the item class

	$Id: genBoolean.asm,v 1.1 97/04/07 11:45:31 newdeal Exp $

------------------------------------------------------------------------------@
	
UserClassStructures	segment resource

; Declare the class record

	GenBooleanClass

method GenItemGetIdentifier, GenBooleanClass, MSG_GEN_BOOLEAN_GET_IDENTIFIER
method GenItemSetIdentifier, GenBooleanClass, MSG_GEN_BOOLEAN_SET_IDENTIFIER

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenBooleanBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenBooleanClass

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

GenBooleanBuild	method	GenBooleanClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_BOOLEAN
	GOTO	GenQueryUICallSpecificUI

GenBooleanBuild	endm

Build ends
