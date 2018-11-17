COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Gen
FILE:		genGadget.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenGadgetClass		Gadget object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the GenGadget class

	$Id: genGadget.asm,v 1.1 97/04/07 11:45:29 newdeal Exp $

-------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenGadget.doc

UserClassStructures	segment resource

; Declare the class record

	GenGadgetClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenGadgetBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenClass

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
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenGadgetBuild	method	GenGadgetClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_GADGET
	GOTO	GenQueryUICallSpecificUI

GenGadgetBuild	endm

Build ends
