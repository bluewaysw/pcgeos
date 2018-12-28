###########################################################################
#
#   Copyright (C) 1999  Breadbox Computer Company
#                       All Right Reserved
#
#   PROJECT:    Automatic Decoder Library
#   FILE:       local.mk
#   AUTHOR:     FR, 26th April, 1999
#
#   DESCRIPTION:
#       This is the Automatic Decoder Library additional compiler
#       options.
#
###########################################################################

#include <$(SYSMAKEFILE)>

GOCFLAGS += -DPRODUCT_$(PRODUCT) -L inetmsg
LINKFLAGS += -DPRODUCT_$(PRODUCT) 
#LINKFLAGS += -N \(C\)99\20Breadbox\20Computer\20Company
CCOMFLAGS += -DPRODUCT_$(PRODUCT)


###########################################################################
