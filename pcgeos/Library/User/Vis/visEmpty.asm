COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Vis -- VisEmpty definitions
FILE:		visEmpty.asm

AUTHOR:		Adam de Boor, Jul 23, 1989

ROUTINES:
	Name			Description
	----			-----------
   GLB	VisEmptyClass		Placeholder for master offsets
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/23/89		Initial revision


DESCRIPTION:
	This file contains the VisEmptyClass things.
		

	$Id: visEmpty.asm,v 1.1 97/04/07 11:44:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

VisEmptyClass:

Synopsis
--------

	VisEmptyClass is a shell class (having no instance data, & no methods)
for use by  objects that require the Vis master part to be allocated, but
don't actually use VisClass.  An example of this is the specific-UI versions
of GenApplicationClass, which need not be visual, but requires the Vis master
class to be allocated so that the Spec & Gen master classes end up in the
right place.

------------------------------------------------------------------------------@


UserClassStructures	segment resource

; Define the class record
	VisEmptyClass	mask CLASSF_DISCARD_ON_SAVE

UserClassStructures	ends
