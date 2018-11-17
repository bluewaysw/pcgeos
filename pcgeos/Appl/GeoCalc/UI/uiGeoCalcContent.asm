COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		uiGeoCalcContent.asm

AUTHOR:		Gene Anderson, Mar 21, 1991

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/21/91		Initial revision

DESCRIPTION:
	GeoCalc subclass of VisContent

	$Id: uiGeoCalcContent.asm,v 1.1 97/04/04 15:48:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcClassStructures	segment	resource
	GeoCalcContentClass
GeoCalcClassStructures	ends


if _SPLIT_VIEWS

Document	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcContentSetMaster
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	set the "master" field in the instance data

PASS:		*ds:si	- GeoCalcContentClass object
		ds:di	- GeoCalcContentClass instance data
		es	- dgroup

RETURN:		nothing 

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/24/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcContentSetMaster	method	dynamic	GeoCalcContentClass, 
					MSG_GEOCALC_CONTENT_SET_MASTER

		movdw	ds:[di].GCCI_master, cxdx
		ret
GeoCalcContentSetMaster	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcContentDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw the content

PASS:		*ds:si	- GeoCalcContentClass object
		ds:di	- GeoCalcContentClass instance data
		bp	- gstate

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/29/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcContentDraw	method	dynamic	GeoCalcContentClass,
				MSG_VIS_DRAW

	;
	; For Ruler content -- just send this message to the master.
	; For document contents, send the special draw message
	;
		cmp	ds:[di].GCCI_type, GCCT_RULER
		je	sendIt

		mov	ax, MSG_GEOCALC_DOCUMENT_DRAW_RANGE
sendIt:
		movdw	bxsi, ds:[di].GCCI_master
		mov	di, mask MF_CALL
		GOTO	ObjMessage
		
GeoCalcContentDraw	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcContentVisVupCreateGstate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Do the same machinations that RulerContentClass does

PASS:		*ds:si	- GeoCalcContentClass object
		ds:di	- GeoCalcContentClass instance data
		es	- segment of GeoCalcContentClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/30/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcContentVisVupCreateGstate	method	dynamic	GeoCalcContentClass, 
					MSG_VIS_VUP_CREATE_GSTATE

		mov	di, offset GeoCalcContentClass
		call	ObjCallSuperNoLock

		mov	di, ds:[si]			
		add	di, ds:[di].Vis_offset
		cmp	ds:[di].GCCI_type, GCCT_RULER
		jne	done
		
	;
	; Now do the same stuff that RulerContentClass does.  This is
	; a hack.
	;

		movdw	bxax, ds:[di].VCNI_scaleFactor.PF_y
		movdw	dxcx, 0x10000			;get 1/scale
		call	GrUDivWWFixed			;dxcx = y factor
		pushdw	dxcx

		movdw	bxax, ds:[di].VCNI_scaleFactor.PF_x
		movdw	dxcx, 0x10000			;get 1/scale
		call	GrUDivWWFixed			;dxcx = x factor
		popdw	bxax

		mov	di, bp
		call	GrApplyScale			;scales back to 1.0
done:
		stc
		ret
GeoCalcContentVisVupCreateGstate	endm



Document	ends

endif


