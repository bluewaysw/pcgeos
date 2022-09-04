COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		copenGaugeData.asm

AUTHOR:		Jennifer Wu, May  5, 1994

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	5/ 5/94		Initial revision

DESCRIPTION:
	



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------
;	Color gauges
;---------------------------------------
if not _ASSUME_BW_ONLY

if _FXIP 
DrawColorRegions segment resource
else
DrawColor segment resource
endif

; Left and top outline of gauge

gaugeCRBorderLT	label	Region
	word	0, 0, PARAM_2, PARAM_3	;bounds

	word	-1,						EOREGREC
	word	0,		3, PARAM_2-4,			EOREGREC
	word	1,		2, 2, PARAM_2-3, PARAM_2-3,	EOREGREC
	word	2,		1, 1, 				EOREGREC
	word	3,		0, 0, 4, PARAM_1,     		EOREGREC
	word	PARAM_3-5, 	0, 0, 3, PARAM_1,		EOREGREC
	word	PARAM_3-4,  	0, 0, 4, PARAM_1,		EOREGREC
	word	PARAM_3-3, 	1, 1,				EOREGREC
	word	EOREGREC

; Right and bottom outline of gauge

gaugeCRBorderRB	label	Region
	word	0, 0, PARAM_2, PARAM_3	;bounds

	word	1,						EOREGREC
	word	2, 		PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-4, 	PARAM_2-1, PARAM_2-1,		EOREGREC
	word	PARAM_3-3,	PARAM_2-2, PARAM_2-2,		EOREGREC
	word	PARAM_3-2,	2, 2, PARAM_2-3, PARAM_2-3,   EOREGREC
	word	PARAM_3-1, 	3, PARAM_2-4, 			EOREGREC
	word	EOREGREC

gaugeMercData	label	Region
	word	0, 		0, PARAM_1, PARAM_3
	word	2,						EOREGREC
	word	3, 		5, PARAM_1+1,      	       	EOREGREC
	word	4, 		4, 6, PARAM_1-1, PARAM_1,    	EOREGREC
	word	5, 		4, PARAM_1,		       	EOREGREC
	word	PARAM_3-6, 	4, PARAM_1,       		EOREGREC
	word	PARAM_3-5, 	4, PARAM_1,			EOREGREC
	word	PARAM_3-4, 	5, PARAM_1+1,			EOREGREC
	word	EOREGREC

gaugeLineData	label	Region
	word	0, 0, PARAM_1, PARAM_3
	word	3,						EOREGREC
	word	4, 6, PARAM_1-1,				EOREGREC
	word	EOREGREC

gaugeTickBData	label 	Region
	word	PARAM_3, PARAM_3+6, PARAM_2, PARAM_2+2
	word	PARAM_3+3,					EOREGREC
	word	PARAM_3+5, PARAM_2+1, PARAM_2+1,		EOREGREC
	word	PARAM_3+6, PARAM_2,   PARAM_2+1,		EOREGREC
	word	EOREGREC

gaugeTickWData	label 	Region
	word	PARAM_3, PARAM_3+6, PARAM_2, PARAM_2+2
	word	PARAM_3+2,					EOREGREC
	word	PARAM_3+5, PARAM_2, PARAM_2,			EOREGREC
	word	EOREGREC

if _FXIP 
DrawColorRegions ends
else
DrawColor ends
endif

endif		; if not _ASSUME_BW_ONLY
