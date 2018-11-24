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
#.PATH.h		: c:/progra~1/devstudio/vc/include c:/watcom-v2/h c:/watcom-v2/h/nt

.SUFFIXES	: .o

#if defined(linux)
CC_IMPSRC = $(.IMPSRC)
#else
CC_IMPSRC = $(.IMPSRC:S/\//\\/g)
#endif

#
# Remove .EXPORTSAME restriction on compilations
#
.c.obj		:
	$(CC) -bt=nt $(CFLAGS) \
									 "$(CC_IMPSRC)" \
									 -i="$(WATCOM)/h/nt" \
									 -i="$(WATCOM)/h" 
.c.o		:
	$(CC) -D_LINUX -bt=linux $(CFLAGS) \
									 "$(CC_IMPSRC)" \
									 -i="$(WATCOM)/lh" \
									 -i="$(WATCOM)/h" 

#CC		= wcc386 -zq -zlf -ei
CC		= wcc386 -zq -zlf -ei -d9 

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
#if defined(linux)
CFLAGS		+= $(CFLAGS_COMMON) -fo=$(.TARGET) \
				$(.INCLUDES:S/^-I/-i=/g) \
                   -i=$(.TARGET:H) -i=. $(XCFLAGS)
#else
CFLAGS		+= $(CFLAGS_COMMON) -fo=$(.TARGET:S/\//\\/g) \
				$(.INCLUDES:S/^-I/-i=/g:S/\//\\/g) \
                   -i=$(.TARGET:H) -i=. $(XCFLAGS)
#endif

#
# Flags to pass to cl WHEN LINKING.
#
CLINKFLAGS	+=  name $(.TARGET)

YFLAGS		+= $(XYFLAGS)

DEST		?= $(ROOT_DIR)/bin

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

#if $(TYPE) != "library"

#
# Create an executable from the appropriate objects and libraries
#

win32	: ${.TARGET:S%$%.md/$(NAME).exe%}    	    .JOIN
${MACHINES:S%$%.md/$(NAME).exe%g} : $(win32OBJS) $(win32LIBS) 
	$(WLINK) $(CLINKFLAGS)  \
			DEBUG WATCOM ALL \
			$(.ALLSRC:M*.obj:S/^/file /g) \
			$(.ALLSRC:M*.lib:S/^/lib /g) \
			library kernel32 \
			SYSTEM NT_WIN \
			RU CON \
			$(XLINKFLAGS)

linux	: ${.TARGET:S%$%.md/$(NAME).%}    	    .JOIN
${MACHINES:S%$%.md/$(NAME).%g} : $(linuxOBJS) $(linuxLIBS) 
	$(WLINK) $(CLINKFLAGS)  \
			DEBUG ALL \
			$(.ALLSRC:M*.o:S/^/file /g) \
			$(.ALLSRC:M*.a:S/^/lib /g) \
			library $(WATCOM)/lib386/linux/clib3r.lib \
			library $(WATCOM)/lib386/math387r.lib \
			library $(WATCOM)/lib386/linux/emu387.lib \
			FORMAT ELF \
			$(XLINKFLAGS)


#else

#
# Same as above for executable, except use tlib for making the library
# instead of relying on ar stuff.  Also, tlib expects \ instead of /.
#

linux	: ${.TARGET:S%$%.md/lib$(NAME).a%}  .JOIN
${MACHINES:S%$%.md/lib$(NAME).a%g} : ${.TARGET:H:R:S/^/\$(/:S%$%OBJS)%} \
		 		$(LIBS) \
                ${.TARGET:H:R:S/^/\$(/:S%$%LIBS)%} 
	wlib "$(.TARGET)" $(linuxOBJS)

win32	: ${.TARGET:S%$%.md/$(NAME).lib%}  .JOIN
${MACHINES:S%$%.md/$(NAME).lib%g} : ${.TARGET:H:R:S/^/\$(/:S%$%OBJS)%} \
		 		$(LIBS) \
                ${.TARGET:H:R:S/^/\$(/:S%$%LIBS)%} 
	wlib "$(.TARGET)" $(win32OBJS)


#endif

#
# Now the simple target to run the proper thing
#
all		: $(MACHINES)

#ifndef NO_SPEC_INSTALL
$(INSTALLALL)	: ${.TARGET:S/^install//}   	.NOEXPORT
# if $(TYPE) != "library"
#if defined(linux)
	for i in $(.ALLSRC:S/.$//g) ; \
	do cp $(echo "$i." | sed 's/.exe.$/.exe/') $(DEST)/$(basename "$i") ; done
#else
	for %I in ($(.ALLSRC:S/\//\\/g)) do copy /Y %I $(DEST:S/\//\\/g)
#endif
# else
	: Libraries aren't usually installed
# endif
#endif

#ifndef NO_INSTALL
install		:: $(INSTALLALL)
#endif

mkmf		::
	mkmf -f $(MAKEFILE)
