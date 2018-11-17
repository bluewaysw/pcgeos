COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefFileSelector.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/27/92   	Initial version.

DESCRIPTION:
	

	$Id: prefFileSelector.asm,v 1.1 97/04/04 17:50:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefFileSelectorLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save the original selection

PASS:		*ds:si	= PrefFileSelectorClass object
		ds:di	= PrefFileSelectorClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFileSelectorLoadOptions	method	dynamic	PrefFileSelectorClass, 
					MSG_GEN_LOAD_OPTIONS
	uses	ax,cx,dx,bp
	.enter

	sub	sp, size FileLongName
	mov	di, sp

	mov	cx, ss
	mov	ds, cx
	mov	es, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key
	call	InitFileReadString
	jc	done


	.leave
	ret
PrefFileSelectorLoadOptions	endm

