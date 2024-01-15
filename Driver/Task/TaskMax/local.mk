# $Id: local.mk,v 1.1 97/04/18 11:58:09 newdeal Exp $

#
# Add the Common directory in our parent directory as another place in which
# to search for .def, .asm and .ui files.
#
.PATH.def .PATH.asm .PATH.ui : ../Common $(INSTALL_DIR:H)/Common
UICFLAGS	+= -I../Common -I$(INSTALL_DIR:H)/Common

PROTOCONST	= TASK
LIBNAME		= task

#include    <$(SYSMAKEFILE)>
