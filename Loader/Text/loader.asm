COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		loader.asm

AUTHOR:		Gene Anderson, Mar 21, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/21/94		Initial revision


DESCRIPTION:
	

	$Id: loader.asm,v 1.1 97/04/04 17:27:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode		segment para public 'CODE'
	cgroup	group	kcode, stack

include main.asm
include locate.asm
include strings.asm
include ini.asm
include load.asm
include heap.asm
include path.asm

ifndef NO_AUTODETECT
  include videoDetect.asm
endif

kcode ends

end	LoadGeos
