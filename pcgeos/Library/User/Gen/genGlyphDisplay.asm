COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genGenGlyphClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenGlyphClass		GlyphDisplay object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/89		Initial version

DESCRIPTION:
	This file contains routines to implement the GlyphDisplay class

	$Id: genGlyphDisplay.asm,v 1.1 97/04/07 11:45:18 newdeal Exp $

-------------------------------------------------------------------------------@

; see documentation in /staff/pcgeos/Library/User/Doc/GenGlyph.doc
	
UserClassStructures	segment resource

; Declare the class record

	GenGlyphClass

UserClassStructures	ends

;---------------------------------------------------

Build segment resource



COMMENT @----------------------------------------------------------------------

METHOD:		GenGlyphBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenGlyphClass

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

GenGlyphBuild	method	GenGlyphClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	mov	ax, SPIR_BUILD_GLYPH_DISPLAY
	GOTO	GenQueryUICallSpecificUI

GenGlyphBuild	endm

Build ends
