.SUFFIXES	: .lib
LIBS		= $(.TARGET:H)/compat.lib
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat

#if defined(linux)
XCFLAGS = -dGCC_INCLUDE_DIR=\"unused\" \
	  -dGPLUSPLUS_INCLUDE_DIR=\"unused\"
#  	  -w-pro
#else
XCFLAGS = -dGCC_INCLUDE_DIR="unused" \
	  -dGPLUSPLUS_INCLUDE_DIR="unused"
#  	  -w-pro
#endif

#include <$(SYSMAKEFILE)>
