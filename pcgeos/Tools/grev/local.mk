
#ifndef unix
.SUFFIXES	: .lib
LIBS		= $(.TARGET:H)/compat.lib
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat
#endif

#include <$(SYSMAKEFILE)>

# For testing getopt shme...  should be fine now.
##CFLAGS += -DTEST_ARGS

#need this library because of GetUserName
#CLINKFLAGS += advapi32.lib
