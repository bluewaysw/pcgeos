
.PATH.h		:
.PATH.h		: . $(INSTALL_DIR) \
		  ../include $(INSTALL_DIR:H)/include \
		  ../pmake/src/lib/lst $(INSTALL_DIR:H)/pmake/lib/lst \
		  ../pmake/src/lib/include $(INSTALL_DIR:H)/pmake/src/lib/include

#ifndef unix
.SUFFIXES	: .lib .a
win32LIBS		= $(.TARGET:H)/compat.lib lst.lib \
	 	  $(.TARGET:H)/utils.lib
linuxLIBS		= $(.TARGET:H)/libcompat.a liblst.a \
  	 	  $(.TARGET:H)/libutils.a
.PATH.lib	: ../compat $(INSTALL_DIR:H)/compat \
		  ../pmake/lib/lst $(INSTALL_DIR:H)/pmake/lib/lst \
		  ../utils $(INSTALL_DIR:H)/utils \
		  ../../pmake/lib/lst $(INSTALL_DIR:H:H)/pmake/lib/lst
.PATH.a		: ../compat $(INSTALL_DIR:H)/compat \
		  ../pmake/lib/lst $(INSTALL_DIR:H)/pmake/lib/lst \
		  ../utils $(INSTALL_DIR:H)/utils \
		  ../../pmake/lib/lst $(INSTALL_DIR:H:H)/pmake/lib/lst
#endif


#include    <$(SYSMAKEFILE)>

#
# Nuke the .asm.obj rule.
#
# I don't know why, but somehow the .asm.obj rule from geos.mk
# (which is not applicable to tools) overrides the .c.obj rule
# in tool.mk.  I have no idea why this is happening, because it
# doesn't happen for any of the other tools, just mkmf.
# I love makefile problems.
#
.asm.obj:

