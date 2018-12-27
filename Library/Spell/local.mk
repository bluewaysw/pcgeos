#
#	Local makefile for: Spell library
#
#	$Id: local.mk,v 1.1 97/04/07 11:07:34 newdeal Exp $
#
GEODE		= spell
ASMFLAGS	+= -Wall
LINKFLAGS	+= -Wunref

#CCOM_MODEL	= -Mb
CCOM_MODEL	= -ml

ASMFLAGS        += $(.TARGET:X\\[XIP\\]/*:S|XIP| -DFULL_EXECUTE_IN_PLACE=TRUE |g)

#CCOMFLAGS	+= -DGEOS -Hon=Char_is_rep -Hoff=Prototype_override_warnings
CCOMFLAGS	+= -DGEOS

#
# DBCS/PIZZA flags
#
ASMFLAGS	+= $(.TARGET:X\\[PIZZA\\]/*:S|PIZZA| -DFORCE_SBCS |g)
ASMFLAGS	+= $(.TARGET:X\\[DBCS\\]/*:S|DBCS| -DFORCE_SBCS |g)
CCOMFLAGS	+= $(.TARGET:X\\[PIZZA\\]/*:S|PIZZA| -DFORCE_SBCS -UDO_DBCS |g)
CCOMFLAGS	+= $(.TARGET:X\\[DBCS\\]/*:S|DBCS| -DFORCE_SBCS -UDO_DBCS |g)

.SUFFIXES	: .lib

.PATH.uih .PATH.ui: UI $(INSTALL_DIR)/UI
UICFLAGS	+= -IUI -I$(INSTALL_DIR)/UI

#include <$(SYSMAKEFILE)>

#
# Use the big-model emulating FP library from HighC
#
#not needed for BorlandC?
#.PATH.lib	: $(ROOT_DIR)/Tools/highc/big
#$(GEODE)ec.$(GSUFF) $(GEODE).$(GSUFF) : hcbe.lib

#
# HighC version used case-folding for ASM routines called from C.  BorlandC
# doesn't support this, so we do it manually.
#
ASMFLAGS	+= -D__BORLANDC__

#
# eat HighC macros for putting constants in code segment, the BorlandC
# equivalent doesn't seem to do the right thing with the generate code that
# references the constants
#
CCOMFLAGS	+= -D_pragma_const_in_code=
CCOMFLAGS	+= -D_pragma_end_const_in_code=

#
# resource name nonsense for BorlandC version
#
LINKFLAGS	+= -D__BORLANDC__

#
# GPC changes for Spell dialog
#
ASMFLAGS	+= -DGPC_SPELL
UICFLAGS	+= -DGPC_SPELL
LINKFLAGS	+= -DGPC_SPELL
