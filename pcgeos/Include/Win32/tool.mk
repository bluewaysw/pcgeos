##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PMake System Library
# FILE: 	tool.mk
# AUTHOR: 	Tim Bradley, September 5, 1996
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	<mach>	    	    	Where <mach> is one of the known machines,
#	    	    	    	creates the tool in the directory <mach>.md
#	depend<mach>	    	Creates dependencies for the <mach> version
#	    	    	    	of the tool
#	install<mach>	    	Installs the tool in /usr/public.<mach>
#	all 	    	    	Creates the tool for all known machines
#	depend	    	    	Generates dependencies for all known machines
#	install	    	    	Installs the tool for all known machines
#	MAKETOOL    	    	.USE rule to create a machine-dependent version
#	    	    	    	of a tool -- you must still perform a
#	    	    	    	transformation on $(MACHINES) to generate all
#	    	    	    	the targets, but this rule will compile it
#	    	    	    	for you...
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	tbradley 9/05/96	Initial Revision
#
# DESCRIPTION:
#	Makefile for NT tools. Expected variables:
#
#	    MACHINES	    list of all possible machines
#	    DEFTARGET	    default target to make
#	    NAME    	    name of final executable
#	    TYPE    	    contains "library" if the tool is actually a
#	    	    	    library.
#	    INSTFLAGS	    Flags for the "install" program
#	    DEST    	    Place in which to install executable/library.
#	    	    	    Defaults to /usr/public.<mach>
#	    LIBS    	    Any libraries required for all machine
#	    	    	    architectures (the link uses the appropriate
#			    machine-dependent subdirectory for each directory
#			    in the .LIBS variable)
#
#	For each machine <mach>:
#
#	    <mach>SRCS	    list of sources for machine
#	    <mach>OBJS	    list of object files for <mach> (with <mach>.md/
#	    	    	    at the front of each...)
#	    <mach>LIBS	    list of machine-specific libraries
#
#	The directory /usr/public.<mach> should exist for each <mach>
#	that can be made, as executables will be installed there (they
#	will probably be links to the appropriate directory on the main
#	binary server for the architecture).
#
#	$Id: tool.mk,v 1.5 1996/10/12 00:07:54 jacob Exp $
#
###############################################################################

#
# This really belongs in system.mk, but until we figure out a good
# place to put NT's system.mk, this'll have to do.
#
.INCLUDES	: .h

.MAIN		: $(DEFTARGET)

#if	defined(INSTALL_DIR)
#
# Define search paths for the various types of files we might be compiling.
# This is conditional to allow non-geos tools to be compiled with this
# makefile.
#
.PATH.h		: . $(INSTALL_DIR) \
                  $(DEVEL_DIR)/Tools/include $(ROOT_DIR)/Tools/include
.PATH.c		: $(INSTALL_DIR)
#endif

#
# This is a temporary fix so that pmake can find stuff like assert.h.
# The problem here is that if you have some other version of Borland
# installed (or have it installed in a different directory), then
# this won't be correct.  But for now...
#
.PATH.h		: c:/progra~1/devstudio/vc/include c:/watcom-v2/h c:/watcom-v2/h/nt

#
# Remove .EXPORTSAME restriction on compilations
#
.c.obj		:
	$(CC) $(CFLAGS) $(.IMPSRC)

CC		= wcc386 -D_LINUX -zq -bt=linux -zlf -ei
AS		= wlink -c
WLINK = wlink

#
# Flags for cl that are okay for both compiling and linking.
#
# 	-Z7	- turn debugging info on (like -g in Unix)
#	-Zp4	- align to 4-byte boundaries (needed in some apps)
#	-W3	- turn on warning level 3 (highest is 4)
#
CFLAGS_COMMON	=  -hd -d2 -w3 -zp4 -j

#
# Extra flags for cl to specify the machine type (all targets are in a .md
# directory) and where to place the result.  Under NT, this DOES NOT WORK
# for the final link.
#
CFLAGS		+= $(CFLAGS_COMMON) -fo=$(.TARGET) \
				$(.INCLUDES:N*/Include*:S/^-I/-i=/g) \
                   -i=$(.TARGET:H) -i=. $(XCFLAGS) \
									 -i=/home/frehwagen/watcom-v2/lh \
									 -i=/home/frehwagen/watcom-v2/h

#
# Flags to pass to cl WHEN LINKING.
#
CLINKFLAGS	+=  name $(.TARGET)

YFLAGS		+= $(XYFLAGS)

#if defined(LIBS) && $(LIBS) == "-lkernel.lobj"
LIBS		=
#else
LIBS		?=
#endif

#
# Variables for extra command-line flags, in case there are none...
#
XCFLAGS		?=
XYFLAGS		?=
XLINKFLAGS	?=
#
# Define variables for the various multi-targets to make the rules look a
# little nicer.
#
CLEANALL	:= $(MACHINES:S/^/clean/g)
DEPENDALL	:= $(MACHINES:S/^/depend/g)
INSTALLALL	:= $(MACHINES:S/^/install/g)

#if !target(MAKETOOL)
#
# To make the CFLAGS definition work, we have to make <mach> depend on
# <mach>.md/$(NAME), then use that to create the executable.
# For <mach>.md/$(NAME), we use dynamic sources to make it depend on
# $(<mach>OBJS) (i.e. the objects for the executable on that machine).
#
MAKETOOL	: .USE
	$(WLINK) $(CLINKFLAGS) $(.LIBS) $(.LIBS:S,$,/$(.TARGET:H),g) \
			$(.ALLSRC:M*.obj:S/^/file /g) \
			$(.ALLSRC:M*.lib:S/^/lib /g) \
			library /home/frehwagen/watcom-v2/lib386/linux/clib3r.lib \
			library /home/frehwagen/watcom-v2/lib386/math387r.lib \
			library /home/frehwagen/watcom-v2/lib386/linux/emu387.lib \
			FORMAT ELF \
			$(XLINKFLAGS)
#endif
#if $(TYPE) != "library"

#
# Create an executable from the appropriate objects and libraries
#

$(MACHINES)	: ${.TARGET:S%$%.md/$(NAME).exe%}    	    .JOIN
${MACHINES:S%$%.md/$(NAME).exe%g} : $(win32OBJS) $(LIBS) $(win32LIBS) \
				  MAKETOOL

#else

#
# Same as above for executable, except use tlib for making the library
# instead of relying on ar stuff.  Also, tlib expects \ instead of /.
#

MAKELIB		: .USE .PRECIOUS
	wlib "$(.TARGET)" $(win32OBJS)

$(MACHINES)	: ${.TARGET:S%$%.md/$(NAME).lib%}  .JOIN
${MACHINES:S%$%.md/$(NAME).lib%g} : $(win32OBJS) $(LIBS) $(win32LIBS) \
		MAKELIB
#endif

#
# Now the simple target to run the proper thing
#
all		: $(MACHINES)

mkmf		::
	mkmf -f $(MAKEFILE)
