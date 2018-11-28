
#ifndef unix
.SUFFIXES	: .lib .a
win32LIBS		= $(.TARGET:H)/compat.lib
linuxLIBS		= $(.TARGET:H)/libcompat.a
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat
.PATH.a		: ../compat $(INSTALL_DIR:H)/compat
#endif

#include <$(SYSMAKEFILE)>

# For testing getopt shme...  should be fine now.
##CFLAGS += -DTEST_ARGS

#need this library because of GetUserName
#CLINKFLAGS += advapi32.lib
