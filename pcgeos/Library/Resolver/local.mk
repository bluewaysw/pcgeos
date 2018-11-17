#
# local.mk for resolver library
# jang	95/10/17
#
# Required compiler flags
#
# TESTF=0|-1	      : this may activate some modules for testing only
#
# TEST_TRACE=0|-1     : shows trace of program by generating
# 		    	warnings on swat when set

# $Id: local.mk,v 1.1 97/04/07 10:42:22 newdeal Exp $
#

ASMFLAGS	+= -DTESTF=0
ASMFLAGS	+= -DTEST_TRACE=0

#include <$(SYSMAKEFILE)>

