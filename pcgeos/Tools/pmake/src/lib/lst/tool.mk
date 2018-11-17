##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PMake System Library
# FILE: 	tool.mk
# AUTHOR: 	Adam de Boor, Jun 19, 1989
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
#	ardeb	6/19/89		Initial Revision
#
# DESCRIPTION:
#	Makefile for tools. Expected variables:
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
#	$Id: tool.mk,v 1.15 96/04/29 18:01:58 jacob Exp $
#
###############################################################################

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
.PATH.y		: $(INSTALL_DIR)
.PATH.l		: $(INSTALL_DIR)
#endif

#
# Specify gcc-include directory to deal with /usr/include.<mach> given by
# gcc -- there are certain things (like assert.h) that we want from the
# gcc include directory, not the standard one.
#
.PATH.h		: /usr/public/lib/gcc-include

#
# Bison-specific transformation rules -- Bison places the parser in
# a file whose base is the prefix of the grammar file, not just "y.tab.c"
# These rules also take care of creating a file <prefix>.h if YFLAGS tell
# Bison to produce a <prefix>.tab.h file. The <prefix>.h file is only
# modified if it is different from that produced by Bison.
#
# 3/18/92: added -b flag to specify prefix for Bison 1.16. w/o this the
# .tab.c and .tab.h files are generated in the installed directory if
# the source isn't in the development tree, which ain't what we want -- ardeb
#
#if $(YACC:T) == "bison"
#
# Delete .y -> .o transformation to allow 'parse.h : parse.c' rules to work
#
.y.o		:

.y.c		:
	$(YACC) -b $(.TARGET:R:T) $(YFLAGS) $(.IMPSRC)
	mv $(.TARGET:R).tab.c $(.TARGET)
# if !empty(YFLAGS:M-*d*)
	sh -c "cmp -s $(.TARGET:R).tab.h $(.TARGET:R).h || \
		cp $(.TARGET:R).tab.h $(.TARGET:R).h"
# endif

#endif

#
# Remove .EXPORTSAME restriction on compilations
#
.c.o		:
	$(CC) $(CFLAGS) -c $(.IMPSRC)

#
# Always use GCC in its optimizing mode for compilation, as that's the
# thing that knows about -m flags...
#
CC		= gcc -O
AS		= gcc -c

#
# Extra flags for gcc to specify the machine type (all targets are in a .md
# directory) and where to place the result. This works even for the final
# link.
# 
# The use of -I- is required to ensure that any header in a development
# directory is used rather than its corresponding installed version regardless
# of where the including file is located.
#
#if	defined(INSTALL_DIR)
CFLAGS		+= -g -Wall -o $(.TARGET) \
                   -I. -I$(INSTALL_DIR) \
                   -I$(.TARGET:H) -I$(INSTALL_DIR)/$(.TARGET:H) -I- \
                   -I$(.TARGET:H) -I$(INSTALL_DIR)/$(.TARGET:H) \
                   $(.INCLUDES) \
                   $(XCFLAGS)
#else
CFLAGS		+= -g -o $(.TARGET)  $(.INCLUDES) \
                   -I$(.TARGET:H) $(XCFLAGS)
#endif

AFLAGS		+=  $(XAFLAGS)
YFLAGS		+= $(XYFLAGS)
INSTFLAGS	+= -b $(XINSTFLAGS)
#
# Given multiple things to install, we need to get the md directory for
# only the first. Easiest way to do this is with the "set" command in
# the shell to break the thing into words, then using only $1
#
DEST		?= `set - $(.ALLSRC:H:S/.md//); echo /usr/public.$1`
#if defined(LIBS) && $(LIBS) == "-lkernel.lobj"
LIBS		= 
#else
LIBS		?=
#endif

#
# Variables for extra command-line flags, in case there are none...
#
XCFLAGS		?= 
XAFLAGS		?= 
XYFLAGS		?= 
XINSTFLAGS	?= 
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
	$(CC) $(CFLAGS) $(.LIBS) $(.LIBS:S,$,/$(.TARGET:H),g) $(.ALLSRC)
#endif
#if $(TYPE) != "library"

#
# Create an executable from the appropriate objects and libraries
#

$(MACHINES)	: ${.TARGET:S%$%.md/$(NAME)%}	    	    .JOIN
${MACHINES:S%$%.md/$(NAME)%g}	: MAKETOOL \
                  ${.TARGET:H:R:S/^/\$(/:S%$%OBJS)%} \
		  $(LIBS) \
                  ${.TARGET:H:R:S/^/\$(/:S%$%LIBS)%}

#else

#
# Archive the object files instead, using the MAKELIB rule to handle the
# object file management and removal.
#

many_libraries	= you bet your sweet behind...
#include    <makelib.mk>

.SUFFIXES	: .po

.c.po		: 
	$(CC) $(CFLAGS) -pg -c $(.IMPSRC)

.s.po		: 
	$(AS) $(AFLAGS) -o $(.TARGET) $(.IMPSRC)

$(MACHINES)	: ${.TARGET:S%$%.md/lib$(NAME).a%}
${MACHINES:S%$%.md/lib$(NAME).a%g}	: MAKELIB \
           $(.TARGET)(${.TARGET:H:R:S/^/\$(/:S%$%OBJS)%}) 

${MACHINES:S%$%.md/lib$(NAME)_p.a%g}	: MAKELIB \
           $(.TARGET)(${.TARGET:H:R:S/^/\$(/:S%$%OBJS:S,.o\$,.po,g)%}) 

#endif

#
# Harrier. Make the depend<mach> target depend on <mach>.md/dependencies.mk,
# then make that depend on $(<mach>SRCS), but replace .y and .l suffixes with
# .c so we've got a real C file on which we can run our script. In addition,
# the SRCS variable will contain header files, which we don't want, so
# we apply :N*.h: to remove them..
#
$(DEPENDALL)	: ${.TARGET:S%^depend%%:S%$%.md/dependencies.mk%}
${MACHINES:S%$%.md/dependencies.mk%g}	: .EXPORTSAME \
           ${.TARGET:H:R:S/^/\$(/:S/$/SRCS:S%.y\$%.c%g:S%.l\$%.c%g)/}
	-mv -f $(.TARGET) $(.TARGET)~
	echo "# DO NOT MODIFY THIS FILE; pmake depend will nuke it" >$(.TARGET)
#
# Form sed script to remove unwanted include paths (those pmake
# can find by itself)
#
	trap "rm -f /tmp/idirs$$$$; exit 0" 0 1 2 3 15
	sedfile=/tmp/idir$$$$
	:> $sedfile
	for i in $(.INCLUDES:N-I.); do
	    echo "s|"'"'`expr "$i" : '-I\(.*\)$$'`"/||" >> $sedfile
	done
#
# Run all source files through the preprocessor, using only
# # line "file" lines, placing the name of the file from which
# the line came at the front of each one. Then massage the resulting
# lines to remove extra . and .. path components, the quotation marks
# around the file names and leading paths that pmake can find.
# Run the result through an awk script to (1) make the sources
# for each object file unique and (2) format the results nicely
#
	for i in $(.ALLSRC:M*.[cS]); do
	    ip="`echo $i | sed -e 's,/,\\\\/,g'`"
	    $(CC) -E $(CFLAGS:M-[DI]*) $(CFLAGS:M-m*) $i | \
		sed -n -e "/^#[     ]*ident/d" \
		       -e "/^#[     ]*pragma/d" \
		       -e "/^#.*"'"'"$ip"'"'"/d" \
		       -e "/^#/s;^;$i ;p"
	done | sed -f $sedfile \
	    -e 's,/[^/.][^/]*/\.\./,/,g' -e 's,/\.[^.][^/]*/\.\./,/,g' \
	    -e 's,",,g' -e 's, \./, ,' | \
	    awk '
		$4 !~ /\/usr\/include/ {
		    n = split($1, comps, "/")
		    ofile = "$(.TARGET:H)/" substr (comps[n], 1, length (comps[n]) - 2) ".o"
		    if (srcs[ofile ":::" $4] == 0) {
	    	    	numfiles += 1
		    	srcs[ofile ":::" $4] = 1
		    	files[ofile] = files[ofile] " " $4
		    }
		}
		END {
	    	    if (numfiles != 0) {
			for (obj in files) {
#if $(TYPE) == "library"
	    	    	    ind = index(obj, ".o")
			    base = substr(obj,0,ind-1)
	    	    	    print base ".po \\"
#endif
			    ns = split(files[obj], srcs, " ")
			    line = sprintf("%-16s:", obj)
			    for (j = 1; j <= ns; j++) {
				if (length(line) + length(srcs[j]) > 75) {
				    printf "%s\\\n", line
				    line = sprintf("%17s", "")
				}
				line = line " " srcs[j]
			    }
			    print line
			}
	    	    }
		}' >> $(.TARGET)

		

#ifndef NO_SPEC_INSTALL
$(INSTALLALL)	: ${.TARGET:S/^install//}   	.NOEXPORT
# if $(TYPE) != "library"
	install $(INSTFLAGS) $(.ALLSRC) $(DEST)
# else
	: Libraries aren't usually installed
# endif
#endif

#
# Now the simple targets to run the proper thing for all machines
#
all		: $(MACHINES)
depend		: $(DEPENDALL)
#ifndef NO_INSTALL
install		:: $(INSTALLALL)
#endif

mkmf		::
	mkmf -f $(MAKEFILE)
