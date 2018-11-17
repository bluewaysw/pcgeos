#
# Definitions for compiling PIZZA geodes
#	$Id: pizza.mk,v 1.1 97/04/04 14:26:09 newdeal Exp $

ASMFLAGS	+= -2 -DDO_DBCS -DDO_PIZZA
LINKFLAGS	:= -2 -DDO_DBCS -DDO_PIZZA -L$(DEVEL_DIR)/Include/PIZZA -L$(LOBJ_DIR)/PIZZA -L$(DEVEL_DIR)/Include/DBCS -L$(LOBJ_DIR)/DBCS $(LINKFLAGS)
UICFLAGS	+= -2 -DDO_DBCS -DDO_PIZZA
LOCFLAGS	+= -2
