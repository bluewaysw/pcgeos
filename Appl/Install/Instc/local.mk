#
#       Local makefile for: Install Creator
#
#

# -zc    compiles strings defined in the code into the code segment instead of
# 	 into the dgroup (watcom compiler). For Borland compiler use -dc.
XCCOMFLAGS += -zc

# Do not Create any EC version
 NO_EC = 1


# Create a Copyrigth-notice
LINKFLAGS += -N "(c) by RABE-Soft 8/99-01/2023"

#include <$(SYSMAKEFILE)>
