#
# Definitions for creating PC GEOS test files. These things are single-file
# applications. The ALL variable contains all the applications to be made
# during a full install. If some are to be made during a partial one, the
# "part" target should be defined by the including makefile.
#
#	$Id: test.mk,v 1.1 97/04/04 14:24:48 newdeal Exp $
#
#
SUBDIR		:= $(APPL_DIR)

#include	<gpath.mk>

.MAIN		:  $(ALL)
full		:: $(ALL)

AINCPATHS	:= $(INCPATHS)

.obj.exe	: .M68020
	$(LINK) $(LINKFLAGS) $(.IMPSRC) $(.ALLSRC:N*.obj) -o $(.TARGET)
$(ALL:S/.geo/.exe/g)	: $(LIBS)

#
# Redefine .asm.obj rule to produce a .tcl file for each application
#
.asm.obj	:  .M68020
	$(MASM) $(MASMFLAGS) $(.IMPSRC) -o $(.TARGET)
	$(ASAP) -o - $(MASMFLAGS:M-[ID]*) $(.IMPSRC) | \
	    sed -f $(ROOT_DIR)/Tools/gTrimTcl.sed > $(.PREFIX).tcl
