##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- Special PMake definitions
# FILE: 	local.mk
# AUTHOR: 	Adam de Boor, Jun 22, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	6/22/89		Initial Revision
#
# DESCRIPTION:
#	Special definitions for Swat
#
#	$Id: local.mk,v 4.19 97/05/23 12:54:38 adam Exp $
#
###############################################################################
HOSTNAME	!= hostname
PMAKE		= $(ROOT_DIR)/Tools/pmake
LIBDIRS		= tcl sys

YFLAGS		= -vt

#
# Special suffix handling -- need to locate .tcl files for MAKEDOC
#
.SUFFIXES	: .tcl

#
# Common C flags
# 
CFLAGS		= -DISSWAT


.PATH.h		: 

#
# Extra search paths
#
#ifdef unix
.NULL		: .out
LIBDIRS		+= curses
#
# Lots of optimizations...
#
CFLAGS		+= -W -Wreturn-type -Wunused -fcombine-regs -DMEM_TRACE
#
# All the libraries we use...
# 
LIBS		= $(.TARGET:H)/libtcl.a $(.TARGET:H)/liblst.a \
                  $(.TARGET:H)/libcurses.a -ltermcap \
                  $(.TARGET:H)/libutils.a -lm
.PATH.a		: $(PMAKE)/lib/lst $(LIBDIRS) $(LIBDIRS:S,^,$(INSTALL_DIR)/,g) \
                  ../utils $(INSTALL_DIR:H)/utils
#else
LIBDIRS		+= ntcurses
.SUFFIXES	: .lib
LIBS		= $(.TARGET:H)/tcl.lib $(.TARGET:H)/lst.lib \
                  $(.TARGET:H)/ntcurses.lib \
                  $(.TARGET:H)/utils.lib \
                  $(.TARGET:H)/compat.lib \
		  $(.TARGET:H)/winutil.lib
.PATH.lib	: $(PMAKE)/lib/lst $(LIBDIRS) \
		  $(LIBDIRS:S,^,$(INSTALL_DIR)/,g) \
                  ../utils $(INSTALL_DIR:H)/utils \
                  ../winutil $(INSTALL_DIR:H)/winutil \
                  ../compat $(INSTALL_DIR:H)/compat
#endif
.PATH.h		: $(PMAKE)/src/lib/lst $(LIBDIRS:Nsys) \
                  $(LIBDIRS:Nsys:S,^,$(INSTALL_DIR)/,g) \
                  ../include $(INSTALL_DIR:H)/include \
                  ../utils $(INSTALL_DIR:H)/utils \
                  $(PMAKE)/src/lib/include \
		  . $(INSTALL_DIR) 
.PATH.tcl	: lib.new lib.new/Internal lib.new/Extra $(INSTALL_DIR)/lib.new\
                  $(INSTALL_DIR)/lib.new/Internal $(INSTALL_DIR)/lib.new/Extra
.PATH.c		: tcl $(INSTALL_DIR)/tcl

#
# Tcl sources whose doc strings are to be extracted
#
TCLSRCS		= *.tcl tclCmdAH.c tclCmdIZ.c tclProc.c

 
sun3LIBS	= -lsys
isiLIBS		= -lsys

#if make(prof)
CFLAGS		+= -pg
LIBS		:= $(LIBS:S/$/_p/g:S/.a_p/_p.a/g)

prof		: sparc.md/swat
#endif

#
# makedoc isn't part of the package...
#
sun3OBJS	:= $(sun3OBJS:N*syn.o:N*makedoc.o:N*/x11.o)
isiOBJS		:= $(isiOBJS:N*syn.o:N*makedoc.o:N*/x11.o)
sparcOBJS	:= $(sparcOBJS:N*syn.o:N*makedoc.o:N*/x11.o)
win32OBJS	:= $(win32OBJS:N*syn.obj:N*makedoc.obj:N*/x11.obj:N*/serial.obj)

#
# Finally, include the system makefile
#
#include    <$(SYSMAKEFILE)>

#
# Create new documentation file under Unix only
#
#ifdef unix
$(MACHINES)	: lib.new/DOC.new
lib.new/DOC.new	: .NOEXPORT .INVISIBLE $(MISRCS) $(TCLSRCS) \
		  $(DEFTARGET).md/makedoc
	$(DEFTARGET).md/makedoc $(.ALLSRC:N*makedoc) > $(.TARGET)

lib.new/synopsis.new	: .NOEXPORT .INVISIBLE $(MISRCS) $(TCLSRCS) \
		  $(DEFTARGET).md/syn
	cat $(.ALLSRC:N*/syn) | $(DEFTARGET).md/syn > $(.TARGET)

install		:: installdoc
installdoc	: lib.new/DOC.new lib.new/synopsis.new
	install -c -m 444 lib.new/DOC.new $(ROOT_DIR)/Tools/swat/lib.new/DOC
	install -c -m 444 lib.new/synopsis.new \
		$(ROOT_DIR)/Tools/swat/lib.new/synopsis

$(MACHINES:S,$,.md/makedoc,g) : $(.TARGET:H)/makedoc.o -lutils MAKETOOL
#endif

#
# Special rule for the version file -- needs to be remade each time and
# have special macros defined telling who compiled it...
#
#ifdef unix
$(MACHINES:S,$,.md/version.o,g)	! version.c
#else
$(MACHINES:S,$,.md/version.obj,g) ! version.c
#endif
	$(CC) $(CFLAGS) -c -DUSERNAME=\"$(USER)\" \
	    -DHOSTNAME=\"$(HOSTNAME)\" $(.ALLSRC:M*.c)

#
# Initial values arrived at empirically -- best values < $(MAX)
#
GPFLAGS		= -agSDptlC
OPT		= /n/ne/pcgeos/adam/Tools/esp/opt

.SUFFIXES	: .gperf
.PATH.gperf	: $(INSTALL_DIR)

MAX		= 20
# -i1 gives 41
tokens.h	: tokens.gperf
	$(GPERF) -i1 -o -k1,2,'$$' -j1 $(GPFLAGS) $(.ALLSRC) > $@
tokens.opt	::
	MAX=$(MAX) $(OPT) -o -k1,2,'$$' -j1 $(GPFLAGS) tokens.gperf

expr.c		: tokens.h

#
# XSWAT stuff
#
#
# Create an executable from the appropriate objects and libraries
#
#ifdef unix
.PATH.a		: x11 $(INSTALL_DIR)/x11 
.PATH.h		: x11 $(INSTALL_DIR)/x11 /usr/include/X11

$(MACHINES:S|^|x|g) : ${.TARGET:S|^x||:S%$%.md/x$(NAME)%}    	    .JOIN
${MACHINES:S%$%.md/x$(NAME)%g}	: MAKETOOL \
                  ${.TARGET:H:R:S/^/\$(/:S%$%OBJS:N*nox11.o)%} \
		  ${.TARGET:H}/x11.o \
		  -lx11 -lXaw -lXmu -lXt -lX11\
		  $(LIBS) \
                  ${.TARGET:H:R:S/^/\$(/:S%$%LIBS)%}

.c.s:; $(CC) $(CFLAGS) -S $(.IMPSRC)

.SUFFIXES: .i

.c.i:; $(CC) $(CFLAGS) -E $(.IMPSRC)
#endif


#ifndef unix
#
# Evil hack
#
.PATH.h		: k:\lib\gcc-include
#
# another Evil hack
#
win32.md/npipe.obj: win32.md/npipe.c
win32.md/ntserial.obj: win32.md/ntserial.c
#endif
