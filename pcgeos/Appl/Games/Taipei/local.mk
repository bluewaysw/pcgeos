#
#	Local makefile for: Taipei
#
#	$Id: local.mk,v 1.1 97/04/04 15:14:55 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

# .PATH.ldf	: /staff/pcgeos/Installed/Include

# define the name of the app since it is not the same as the directory name 
GEODE		= tiles

#include <$(SYSMAKEFILE)>


