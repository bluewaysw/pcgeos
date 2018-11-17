.SUFFIXES	: .lib
LIBS		= $(.TARGET:H)/compat.lib
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat

XCFLAGS = -dGCC_INCLUDE_DIR="unused" \
	  -dGPLUSPLUS_INCLUDE_DIR="unused"
#  	  -w-pro

#include <$(SYSMAKEFILE)>
