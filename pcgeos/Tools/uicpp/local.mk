.SUFFIXES	: .lib
LIBS		= $(.TARGET:H)/compat.lib
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat

XCFLAGS = -DGCC_INCLUDE_DIR=\"unused\" \
	  -DGPLUSPLUS_INCLUDE_DIR=\"unused\"
#  	  -w-pro

#include <$(SYSMAKEFILE)>
