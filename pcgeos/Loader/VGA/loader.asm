COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		vgaLoader.asm

AUTHOR:		Gene Anderson, Feb 24, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/24/94		Initial revision


DESCRIPTION:
	

	$Id: loader.asm,v 1.1 97/04/04 17:27:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LOADER_DEFAULT_GRAPHIC_BACKGROUND_COLOR equ     (0xff shl 8) or C_BLACK


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
  ifndef NO_SPLASH_SCREEN
    include videoDisplay.asm
    include videoVGA.asm
    include videoSVGA.asm
    include videoEGA.asm
    include videoMCGA.asm
    include videoCGA.asm
    include videoHGC.asm

    include videoVGAImageLogo.asm

  endif
endif

kcode ends

end	LoadGeos
