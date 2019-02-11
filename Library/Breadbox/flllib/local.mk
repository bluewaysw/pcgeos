#include <$(SYSMAKEFILE)>

GOCFLAGS += -L flllib
LINKFLAGS += -N "Copyright Breadbox Comp 1998"

#GREV ?= grev
#REVFILE = $(GEODE).rev
#_REL    !=      $(GREV) neweng $(REVFILE) -R -s
#_PROTO  !=      $(GREV) getproto $(REVFILE) -P
