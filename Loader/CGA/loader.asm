COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	Copyright (c) New Deal Office 1997 -- All Rights Reserved

PROJECT:	New Deal Office
MODULE:		
FILE:		loader.asm

AUTHOR:		Gene Anderson, Feb 24, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/24/94		Initial revision
	Tom	6/30/97		New Deal version


DESCRIPTION:
	

	$Id: loader.asm,v 1.2 97/10/15 10:19:31 newdeal Exp $

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

    include videoCGAImageLogo.asm

  endif
endif

kcode ends

end	LoadGeos
