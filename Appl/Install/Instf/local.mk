#
#       Local makefile for: Universal Installer
#
#

# Pass the -r flag for (somewhat) unsafe resource fixups for multi-launchability
# But, because of we have set the flag "single" for type (Life.gp), our program
# is not multi lauchable. Therfore, we have not to pass this flag. R.B.
# LINKFLAGS       += -r

# Do not Create any EC version
NO_EC = 1



# Create a Copyrigth-notice
LINKFLAGS += -N "(c) by RABE-Soft 10/99-05/2023"

#include <$(SYSMAKEFILE)>
