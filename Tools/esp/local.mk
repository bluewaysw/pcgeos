##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Esp -- special definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 19, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/19/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for Esp
#
#	$Id: local.mk,v 1.10 96/06/13 20:52:18 jacob Exp $
#
###############################################################################

CFLAGS		= -DYYDEBUG=1 -DLEXDEBUG=1
#if defined(unix)
CFLAGS	 	+= -fstrength-reduce -fcombine-regs \
		  -finline-functions -W -Wreturn-type -Wunused
LIBS		= $(.TARGET:H)/libutils.a
.PATH.a		: ../utils $(INSTALL_DIR:H)/utils
#else
.SUFFIXES	: .lib .a

linuxLIBS		:= $(.TARGET:H)/libutils.a $(.TARGET:H)/libcompat.a
win32LIBS		:= $(.TARGET:H)/utils.lib $(.TARGET:H)/compat.lib

.PATH.lib	: ../utils $(INSTALL_DIR:H)/utils \
	 	  ../compat $(INSTALL_DIR:H)/compat
.PATH.a	: ../utils $(INSTALL_DIR:H)/utils \
	 	  ../compat $(INSTALL_DIR:H)/compat
#endif
YFLAGS		= -dv

.PATH.h		:
.PATH.h		: . $(INSTALL_DIR) \
		  ../utils $(INSTALL_DIR:H)/utils

.SUFFIXES	: .gperf
.PATH.gperf	: $(INSTALL_DIR)

sun3OBJS	:= $(sun3OBJS:N*printobj.o)
isiOBJS		:= $(isiOBJS:N*printobj.o)
sparcOBJS	:= $(sparcOBJS:N*printobj.o)
win32OBJS	:= $(win32OBJS:N*printobj.obj)

#include    <$(SYSMAKEFILE)>

#
# Special rule to make sure parse.h exists before people try to include it
#
parse.h		: parse.c

TABLES		= opcodes.h keywords.h class.h segment.h cond.h dword.h \
                  model.h flopcode.h
$(MACHINES:S|$|.md/scan.o|g): $(TABLES)

#
# Initial values arrived at empirically -- best values < $(MAX)
#
#if 0
GPFLAGS		= -agSDptlTC

MAX		= 20
# -i5 gives 358
opcodes.h	: opcodes.gperf
	$(GPERF) -i8 -o -j1 $(GPFLAGS) -k1-3,'$$' -N findOpcode \
	    -H hashOpcode $(.ALLSRC) > $@
opcodes.opt	::
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) -k1-3,'$$' opcodes.gperf

# -i1 gives MAX_HASH_VALUE of 506
keywords.h	: keywords.gperf
	$(GPERF) -i1 -o -j1 $(GPFLAGS) -k1-4,6,8,'$$' -N findKeyword \
	    -H hashKeyword $(.ALLSRC) > $@
keywords.opt	:: 
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) -k1-4,6,8,'$$' keywords.gperf

# -i8 gives 10
class.h		: class.gperf
	$(GPERF) -i8 -o -j1 $(GPFLAGS) -N findClassToken \
	    -H hashClassToken $(.ALLSRC) > $@
class.opt	:: 
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) class.gperf

# -i16 gives 16
segment.h	: segment.gperf
	$(GPERF) -i16 -o -j1 $(GPFLAGS) -N findSegToken \
	    -H hashSegToken $(.ALLSRC) > $@
segment.opt	:: 
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) segment.gperf

# -i1 gives 32
cond.h	: cond.gperf
	$(GPERF) -i1 -o -j1 $(GPFLAGS) -k'*' -N findCondToken \
	    -H hashCondToken $(.ALLSRC) > $@
cond.opt	:: 
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) -k'*' cond.gperf

# -i1 gives 32
dword.h	: dword.gperf
	$(GPERF) -i1 -o -j1 $(GPFLAGS) -k'*' -N isDWordPart \
	    -H hashDWordPart $(.ALLSRC) > $@
dword.opt	:: 
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) -k'*' dword.gperf

# -i16 gives 12
model.h	: model.gperf
	$(GPERF) -i16 -o -j1 $(GPFLAGS) -k'*' -N findModelToken \
	    -H hashModelToken $(.ALLSRC) > $@
model.opt	:: 
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) -k'*' model.gperf

# -i14 gives 232
flopcode.h	: flopcodes.gperf
	$(GPERF) -i14 -o -j1 $(GPFLAGS) -k2-5,'$$' -N findFlopcode \
	    -H hashFlopcode $(.ALLSRC) > $@
flopcodes.opt	:: 
	MAX=$(MAX) opt -o -j1 $(GPFLAGS) -k2-5,'$$' flopcodes.gperf
#endif

allopt		: $(TABLES:S/.h$/.opt/g)

CFLAGS		:= $(CFLAGS:N-finline-functions)

.SUFFIXES	: .i

.c.i		:; $(CC) $(CFLAGS) -E $(.IMPSRC) 
.c.s		:; $(CC) $(CFLAGS) -S $(.IMPSRC)

sun3poOBJS	= sun3.md/printobj.o
isipoOBJS	= isi.md/printobj.o isi.md/isinf.o
sparcpoOBJS	= sparc.md/printobj.o
win32poOBJS	= win32.md/printobj.obj
linuxpoOBJS	= linux.md/printobj.o
win32pslsOBJS   = win32.md/printsls.obj
linuxpslsOBJS   = win32.md/printsls.o

#if defined(unix)
$(MACHINES)	: ${.TARGET:S%$%.md/printobj%}	    	    .JOIN
${MACHINES:S%$%.md/printobj%g}	: MAKETOOL \
                  ${.TARGET:H:R:S/^/\$(/:S%$%poOBJS)%} \
		  $(LIBS) 
#else

win32	: ${.TARGET:S%$%.md/printobj.exe%}    	    .JOIN
${MACHINES:S%$%.md/printobj.exe%g} : $(win32poOBJS) $(win32LIBS) 
	$(WLINK) $(CLINKFLAGS)  \
			DEBUG WATCOM ALL \
			$(.ALLSRC:M*.obj:S/^/file /g) \
			$(.ALLSRC:M*.lib:S/^/lib /g) \
			library kernel32 \
			SYSTEM NT_WIN \
			RU CON \
			$(XLINKFLAGS)

win32	: ${.TARGET:S%$%.md/printsls.exe%}    	    .JOIN
${MACHINES:S%$%.md/printsls.exe%g} : $(win32pslsOBJS) $(win32LIBS) 
	$(WLINK) $(CLINKFLAGS)  \
			DEBUG WATCOM ALL \
			$(.ALLSRC:M*.obj:S/^/file /g) \
			$(.ALLSRC:M*.lib:S/^/lib /g) \
			library kernel32 \
			SYSTEM NT_WIN \
			RU CON \
			$(XLINKFLAGS)

linux	: ${.TARGET:S%$%.md/printobj.%}    	    .JOIN
${MACHINES:S%$%.md/printobj.%g} : $(linuxpoOBJS) $(linuxLIBS) 
	$(WLINK) $(CLINKFLAGS)  \
			DEBUG ALL \
			$(.ALLSRC:M*.o:S/^/file /g) \
			$(.ALLSRC:M*.a:S/^/lib /g) \
			library $(WATCOM)/lib386/linux/clib3r.lib \
			library $(WATCOM)/lib386/math387r.lib \
			library $(WATCOM)/lib386/linux/emu387.lib \
			FORMAT ELF \
			$(XLINKFLAGS)
linux	: ${.TARGET:S%$%.md/printsls.%}    	    .JOIN
${MACHINES:S%$%.md/printsls.%g} : $(linuxpslsOBJS) $(linuxLIBS) 
	$(WLINK) $(CLINKFLAGS)  \
			DEBUG ALL \
			$(.ALLSRC:M*.o:S/^/file /g) \
			$(.ALLSRC:M*.a:S/^/lib /g) \
			library $(WATCOM)/lib386/linux/clib3r.lib \
			library $(WATCOM)/lib386/math387r.lib \
			library $(WATCOM)/lib386/linux/emu387.lib \
			FORMAT ELF \
			$(XLINKFLAGS)

#endif


