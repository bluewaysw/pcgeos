.SUFFIXES	: .lib .a
win32LIBS		= $(.TARGET:H)/compat.lib $(.TARGET:H)/utils.lib
linuxLIBS		= $(.TARGET:H)/libcompat.a $(.TARGET:H)/libutils.a
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat \
			../utils $(INSTALL_DIR:H)/utils
.PATH.a		: ../compat $(INSTALL_DIR:H)/compat \
			../utils $(INSTALL_DIR:H)/utils

.PATH.h		:  #clear for now
.PATH.h		: . $(INSTALL_DIR) \
                  ../include $(INSTALL_DIR:H)/include \
                  ../utils $(INSTALL_DIR:H)/utils
		  
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
