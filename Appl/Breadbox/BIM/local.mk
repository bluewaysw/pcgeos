#include <$(SYSMAKEFILE)>

# Define the SHOW_MESSAGES flags to display an independent text window
# containing all of the messages sent from and to the server.

#XGOCFLAGS  += -DSHOW_MESSAGES
#XCCOMFLAGS += -DSHOW_MESSAGES

# Define the USE_SIMULATOR flag to test AIM without having to attach to a live
# server.  The login procedure always succeeds, and a dialog is provided to
# generate simulated messages from the server.

#XGOCFLAGS  += -DUSE_SIMULATOR
#XCCOMFLAGS += -DUSE_SIMULATOR

# Temp define for use of the ExtUI tree list for both the online and offline
# buddy lists.

#XGOCFLAGS   += -DUSE_TREE
#XCCOMFLAGS  += -DUSE_TREE
#XLINKFLAGS  += -DUSE_TREE

#GREV ?= grev
#REVFILE = $(GEODE).rev
#_REL    !=      $(GREV) neweng $(REVFILE) -R -s
#_PROTO  !=      $(GREV) getproto $(REVFILE) -P

