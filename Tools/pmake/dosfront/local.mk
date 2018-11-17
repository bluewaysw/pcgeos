LIBS		= $(.TARGET:H)/utils.lib  $(.TARGET:H)/compat.lib 
.SUFFIXES	: .lib
.PATH.lib	: ../../utils $(INSTALL_DIR:H)/utils \
		  ../../compat $(INSTALL_DIR:H)/compat

.PATH.h		: # clear this out for now
.PATH.h		: . $(INSTALL_DIR) \
                  ../../include $(INSTALL_DIR:H)/include \
                  ../../utils $(INSTALL_DIR:H)/utils


#include <$(SYSMAKEFILE)>
