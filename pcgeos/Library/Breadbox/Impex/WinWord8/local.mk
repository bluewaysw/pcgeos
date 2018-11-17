PROTOCONST		= XLATLIB
LIBNAME         = winword8,xlatlib

.PATH.asm .PATH.def:	. $(LIBRARY_DIR)/Trans/Text/TextCommon \
			$(LIBRARY_DIR)/Trans/TransCommon

#
# set include file path
#
-IFLAGS	+= -I$(LIBRARY_DIR)/Trans/Text/TextCommon \
			-I$(LIBRARY_DIR)/Trans/TransCommon

#include	<$(SYSMAKEFILE)>
