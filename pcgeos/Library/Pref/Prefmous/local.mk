# $Id: local.mk,v 1.1 97/04/05 01:38:03 newdeal Exp $

PROTOCONST	= PREF_MODULE

#
# Different App icon
#

# let's see if I can rem all this out 
# by putting spaces after the # - jfh 12/19/01

# ifdef $(PRODUCT) == "NDO2000"
# else
# ASMFLAGS	+= -DGPC_VERSION
# UICFLAGS	+= -DGPC_VERSION
# LINKFLAGS	+= -DGPC_VERSION
# endif

#include <$(SYSMAKEFILE)>
