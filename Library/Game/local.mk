#
#	Local makefile for: game
#
#	$Id: local.mk,v 1.1 97/04/04 18:04:39 newdeal Exp $
#
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref
.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#
# Compile/link option to play a sound on achieving a high score
#
ASMFLAGS	+= -DHIGH_SCORE_SOUND
LINKFLAGS	+= -DHIGH_SCORE_SOUND

#include <$(SYSMAKEFILE)>
