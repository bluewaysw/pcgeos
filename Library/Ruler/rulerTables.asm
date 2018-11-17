COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		rulerTables.asm

AUTHOR:		Gene Anderson, Jun 18, 1991

ROUTINES:
	Name
	----
	pointsScaleTable	- 100 points / interval
	picasScaleTable		- 6 picas = 1 inch / interval
	inchScaleTable		- 1 inch / interval
	metricScaleTable	- 1 cm / interval
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/18/91		Initial revision

DESCRIPTION:
	

	$Id: rulerTables.asm,v 1.1 97/04/07 10:42:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment	resource

;------------------------------------------------------------------------------
;			points
;------------------------------------------------------------------------------

pointsTickTable	RulerTick \
	<<MIT_POINT MPM_100_POINT>, MAX_TICK_HEIGHT>,
	<<MIT_POINT MPM_25_POINT>, MAX_TICK_HEIGHT/4>,
	<<MIT_POINT MPM_50_POINT>, MAX_TICK_HEIGHT/2>,
	<<MIT_POINT MPM_25_POINT>, MAX_TICK_HEIGHT/4>

pointsScaleTable RulerScale <\
<	<0,25>,					;size (100 points)/4
	100,					;value (100 points)
	length pointsTickTable,			;# of entries
	offset pointsTickTable,			;offset of table
<	<<0x8000,0>, 100, <MIT_POINT MPM_50_POINT>>,	;50%: 50 point incs
	<<0x4000,0>, 500, <MIT_POINT MPM_100_POINT>>,	;25%: 100 point incs
	<>
>>

;------------------------------------------------------------------------------
;			picas
;------------------------------------------------------------------------------

picasTickTable	RulerTick \
	<<MIT_PICA MPM_INCH>, MAX_TICK_HEIGHT>,
	<<MIT_PICA MPM_PICA>, MAX_TICK_HEIGHT/2>,
	<<MIT_PICA MPM_PICA>, MAX_TICK_HEIGHT/2>,
	<<MIT_PICA MPM_PICA>, MAX_TICK_HEIGHT/2>,
	<<MIT_PICA MPM_PICA>, MAX_TICK_HEIGHT/2>,
	<<MIT_PICA MPM_PICA>, MAX_TICK_HEIGHT/2>

picasScaleTable RulerScale <\
<	<0,12>,					;size (12 points = 1 pica)
	6,					;value (6 picas = 1 inch)
	length picasTickTable,			;# of entries
	offset picasTickTable,			;offset of table
<	<<0x5555,0>, 1, <MIT_PICA MPM_INCH>>,	;33%: 1" incs, 5" labels
	<>,
	<>
>>

;------------------------------------------------------------------------------
;			inches
;------------------------------------------------------------------------------

inchTickTable	RulerTick \
	<<MIT_US MUSM_ONE_INCH>, MAX_TICK_HEIGHT>,
	<<MIT_US MUSM_EIGHTH_INCH>, 1>,
	<<MIT_US MUSM_QUARTER_INCH>, MAX_TICK_HEIGHT/4+1>,
	<<MIT_US MUSM_EIGHTH_INCH>, 1>,
	<<MIT_US MUSM_HALF_INCH>, MAX_TICK_HEIGHT/2+1>,
	<<MIT_US MUSM_EIGHTH_INCH>, 1>,
	<<MIT_US MUSM_QUARTER_INCH>, MAX_TICK_HEIGHT/4+1>,
	<<MIT_US MUSM_EIGHTH_INCH>, 1>

inchScaleTable RulerScale <\
<	<0,9>,					;size (72 points)/8
	1,					;value (1 inch)
	length inchTickTable,			;# of entries
	offset inchTickTable,			;offset of table
<	<<0xc000,0>, 1, <MIT_US MUSM_QUARTER_INCH>>,	;75%: 1/4" incs, 1" lbls
	<<0x8000,0>, 2, <MIT_US MUSM_HALF_INCH>>,	;50%: 1/2" incs, 2" lbls
	<<0x5555,0>, 5, <MIT_US MUSM_ONE_INCH>>		;33%: 1" incs, 5" lbls
>>

;------------------------------------------------------------------------------
;			metric
;------------------------------------------------------------------------------

metricTickTable	RulerTick \
	<<MIT_METRIC MMM_CENTIMETER>, MAX_TICK_HEIGHT>,
	<<MIT_METRIC MMM_MILLIMETER>, 1>,
	<<MIT_METRIC MMM_MILLIMETER>, 1>,
	<<MIT_METRIC MMM_MILLIMETER>, 1>,
	<<MIT_METRIC MMM_MILLIMETER>, 1>,
	<<MIT_METRIC MMM_HALF_CENTIMETER>, MAX_TICK_HEIGHT/2+1>,
	<<MIT_METRIC MMM_MILLIMETER>, 1>,
	<<MIT_METRIC MMM_MILLIMETER>, 1>,
	<<MIT_METRIC MMM_MILLIMETER>, 1>,
	<<MIT_METRIC MMM_MILLIMETER>, 1>

metricScaleTable RulerScale <\
<	<0xd5ab,0x2>,				;size (28.3464576 points)/10
	1,					;value (1 centimeter)
	length metricTickTable,			;# of entries
	offset metricTickTable,			;offset of table
<	<<0xe666,0>, 2, <MIT_METRIC MMM_HALF_CENTIMETER>>,	;90%: 5mm incs
	<<0x8000,0>, 5, <MIT_METRIC MMM_CENTIMETER>>,		;50%: 1cm incs
	<>
>>

RulerBasicCode	ends
