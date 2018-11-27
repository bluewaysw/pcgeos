.SUFFIXES	: .lib .a
win32LIBS		= $(.TARGET:H)/compat.lib
linuxLIBS		= $(.TARGET:H)/libcompat.a
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat
.PATH.a		: ../compat $(INSTALL_DIR:H)/compat

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
