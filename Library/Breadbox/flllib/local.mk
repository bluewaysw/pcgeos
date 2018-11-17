#include <$(SYSMAKEFILE)>

GOCFLAGS += -L flllib
LINKFLAGS += -N Copyright\20Breadbox\20Comp\201998

#GREV ?= grev
#REVFILE = $(GEODE).rev
#_REL    !=      $(GREV) neweng $(REVFILE) -R -s
#_PROTO  !=      $(GREV) getproto $(REVFILE) -P
