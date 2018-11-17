##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	System Makefiles -- Geode creation
# FILE: 	geode.mk
# AUTHOR: 	Adam de Boor, Jan 26, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	$(GEODE).geo	    	Non-error-checking version of a geode
#	$(GEODE)ec.geo	    	Error-checking version
#	depend	    	    	Generate dependencies for object files
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/26/89		Initial Revision
#
# DESCRIPTION:
#	This is a makefile that will create any type of geode. It expects
#	to have the following variables defined:
#  	    UI_TO_RDFS  .ui files to run through UIC
#	    OBJS    	.obj files from which the geode is to be created
#	    SRCS    	all .asm and .def files that make up the geode
#	    GEODE   	name of the .geo file (i.e. w/o the .geo)
#	    NO_EC   	If no error-checking version should be created.
#	    GCM		If geode has a GCM version that should be made.
#	    GCM_ONLY	If geode only has a GCM version that should be made.
#	    LIBOBJ  	Name of .ldf file to create if this is a library.
#	    MERGE_FILES	Files from which class or other declarations should
#	    	    	be extracted to form the library header file.
#	    LIBHDR  	Name of the library's header file, it not just
#	    	    	$(LIBOBJ:R).def (as it ought to be for all real
#	    	    	libraries).
#	    LIBTEMP 	Name of template file for creating the LIBHDR
#	    PROTOCONST	Base name of protocol constant. The major number for
#			the driver protocol is $(PROTOCONST)_PROTO_MAJOR, and
#			the minor number is $(PROTOCONST)_PROTO_MINOR. These
#			constants must be defined with the EQU directive and
#			cannot be inside a library segment (e.g. they should
#			not be inside StartKernel/EndKernel pairs)
#
#	The typical makefile will thus look like this:
# 
#       UI_TO_RDFS  = ...
#	OBJS	    = ...
#	SRCS	    = ...
#	GEODE	    = ...
#
#	#include <geos.mk>
#	#include <geode.mk>
#
#	This will make both an error-checking and a non-error-checking version
#	unless NO_EC is defined.
#
#	$Id: geode.mk,v 1.1 97/04/04 15:57:33 newdeal Exp $
#
###############################################################################

#
# Set up path for .h files now we know we're creating a geode, not a UNIX tool
#
.PATH.H         : . $(INSTALLED_SOURCE) $(DEVEL_DIR)\INCLUDE $(LOCAL_CINCLUDE) $(CINCLUDE_DIR) $(CANSI_DIR) 
#
# Mark the important things as files being included so their paths make it
# into .INCLUDES
#
.INCLUDES	: .DEF .GOH .H .UIH .RDF .UI

#
# Mangle the flags given to UIC to tell it to not look in the directory
# containing the file performing an #include "file". Rather, it should look
# in all the directories we've specified in the order in which we've specified
# them. Rather than burden the user with this, we simply mangle the UICFLAGS
# variable to have all the non-I flags at the front, followed by all the -I
# flags twice, with the magic -I- separating the two lists.
#
# NOTE: NOTHING SHOULD BE ADDED TO UICFLAGS AFTER THIS FILE IS INCLUDED
#
UICFLAGS        := $(UICFLAGS:N-I*) $(UICFLAGS:M-I*) -I- $(UICFLAGS:M-I*)

GSUFF		?= GEO

#
# Tell the linker the type of geode it's creating so Swat knows where to look
#
#if $(GSUFF) == "GEO"
#if !empty(CURRENT_DIR:M*\\\\APPL\\\\*)
LINKFLAGS	+= -T 1
# elif !empty(CURRENT_DIR:M*\\\\LIBRARY\\\\*)
LINKFLAGS	+= -T 2
# elif !empty(CURRENT_DIR:M*\\\\DRIVER\\\\*)
LINKFLAGS	+= -T 3
# elif !empty(CURRENT_DIR:M*\\\\LOADER\\\\*)
LINKFLAGS	+= -T 4
# else
LINKFLAGS	+= -T 5
# endif
#endif

###############################################################################
#
#	Handle driver protocols. Glue takes symbolic constant names as valid
#	protocol numbers, so adjust _PROTO to be the proper major and minor
#	constant names, separated by the requisite decimal point.
#

#if defined(PROTOCONST)
_PROTO		:= $(PROTOCONST)_PROTO_MAJOR.$(PROTOCONST)_PROTO_MINOR
#endif


#if	defined(GEODE)

##############################################################################
# 	Define the main, part and full targets. "part" only creates the
#	most-used version. If NO_EC is defined, this means a non-errorchecking
#	version, else it's the error-checking version. "full" always makes
#	both.
#
# ifndef GCM_ONLY
#  ifndef NO_EC
.MAIN		: $(GEODE)EC.$(GSUFF)
part		:: $(GEODE)EC.$(GSUFF)
full		:: $(GEODE)EC.$(GSUFF)
#  else
.MAIN		: $(GEODE).$(GSUFF)
part		:: $(GEODE).$(GSUFF)
#  endif NO_EC
full		:: $(GEODE).$(GSUFF)
# endif GCM_ONLY


##############################################################################
#
#	Define assembly rules for the various modules. The things on which
#	they depend are taken care of by the depend rule....
#
#	All modules depend on the library definition file if this thing
#	has one.
#
# ifdef MODULES
#  ifndef GCM_ONLY
$(MODULES:S/$/.$(SUFFS)/g)	: ASSEMBLE
#  endif
#  if defined(GCM) || defined(GCM_ONLY)
$(MODULES:S/$/.GBJ/g)		: ASSEMBLE
#  endif
# endif MODULES

##############################################################################
#
#	Make sure any geode parameter file makes it as a source for the
#	geode...
#

# if (defined(GCM) || defined(GCM_ONLY)) && \
	(exists($(GEODE)GCM.GP))
$(GEODE)GCM.$(GSUFF): $(GEODE)GCM.GP
# endif

# if exists($(GEODE).GP)
$(GEODE)EC.$(GSUFF) : $(GEODE).GP
$(GEODE).$(GSUFF)   : $(GEODE).GP
# elif exists($(INSTALLED_SOURCE)\$(GEODE).GP)
$(GEODE)EC.$(GSUFF) : $(INSTALLED_SOURCE)\$(GEODE).GP
$(GEODE).$(GSUFF)   : $(INSTALLED_SOURCE)\$(GEODE).GP
#endif


##############################################################################
#
#	Deal with library definition file created by the linker.

# if 	defined(LIBOBJ)
#
# Tell link to create the .ldf file at the right time. If no error-checking
# version will be made, we just always pass -l. Else we only do it for
# the error-checking version
#
#  ifndef NO_EC
####this will actually accept *.gee, *.gxo etc but who cares....
LIBFLAG		= $(.TARGET:M*EC.[GE][EX][OE]:S/$(.TARGET)/-l/)
#  else
LIBFLAG		= -l
#  endif



#### if there is a local root we need to see if we are making stuff in the
# installed tree or the local tree to see where the LDF file goes
# I have to convert all the backslashes to forward slashes (or anything else)
# so that the :X operator can do its thing
#if defined(LOCAL_ROOT)
RD	 = $(ROOT_DIR:S|\\|/|g)
CD	 = $(CURRENT_DIR:S|\\|/|g)
ISINROOT = $(CD:X*\\[$(RD)\\]*)
#if $(ISINROOT) == ""
LIB_DEST = $(LOCAL_ROOT)\INCLUDE\LDF\$(LIBOBJ:T)
#else
LIB_DEST = $(ROOT_DIR)\INCLUDE\LDF\$(LIBOBJ:T)
#endif
#else
LIB_DEST = $(.TARGET)
#endif

# must escape any ':' that might be in the name
$(LIBOBJ:S|:|\:|g)       : $(LIBOBJ:T) .NOEXPORT .IGNORE
	`copy $(LIBOBJ:T) $(LIB_DEST)

#  if	defined(NO_EC)
$(LIBOBJ:T)	: $(GEODE).$(GSUFF)
#  else
$(LIBOBJ:T)	: $(GEODE)EC.$(GSUFF)
#  endif

part full	:: $(LIBOBJ)
lib		: $(LIBOBJ)					.JOIN

# elif	!defined(GCM_ONLY)
#  if	defined(NO_EC)
lib		: $(GEODE).$(GSUFF)
#  else
lib		: $(GEODE)EC.$(GSUFF)
#  endif
# else
lib		: $(GEODE)GCM.$(GSUFF)
# endif	defined(LIBOBJ)

##############################################################################
#
#	Rules for creating the geode(s)
#
#
# Make the geode(s) depend on the list of objects and use the LINK rule
# to create them.
#
# if !empty(OBJS)
#  if !defined(GCM_ONLY)
$(GEODE).$(GSUFF)   : $(OBJS)					LINK

#   if !defined(NO_EC)
$(GEODE)EC.$(GSUFF) : $(EOBJS)					LINK
#   endif
#  endif GCM_ONLY

#  if defined(GCM) || defined(GCM_ONLY)
$(GEODE)GCM.$(GSUFF): $(GOBJS)					LINK
#  endif
# endif

# if !defined(NO_LOC) && $(GSUFF) == "GEO"
#  if !defined(LOC)
LOC		= loc
#endif
$(GEODE).VM	: $(GEODE).$(GSUFF)
	$(LOC) -o $(GEODE).VM 

full		:: $(GEODE).VM
# endif

#endif defined(GEODE)


##############################################################################
#
# Automatic dependency generation. 
#
# For the large-model geode, each module Module must have a manager file
# Module/manager.asm for this to work.
#
# Talk to adam if you really need to know what this thing is doing. If you
# don't *really* need to know, you *really* don't want to look at this code.
# It's enough to make you....well, I can't think of anything quite as
# horrible :)
#
# DEPFILE holds the name of the file in which to store the dependencies. A
# typical alternative would be Makefile
#
# DEPFLAGS are passed to Esp
#
#
DEPFILE		?= DEPENDS.MK
DEPFLAGS	?=

depend   depends	: $(DEPFILE)

# ----------------------------------------------------------------------------#

##############################################################################
#
#		      LOCATE IMPORTED LIBRARIES
#
##############################################################################
#
#if defined(GEODE)
# if !defined(GCM_ONLY)
GEODES := $(GEODE).$(GSUFF)
#  if !defined(NO_EC)
GEODES := $(GEODE)EC.$(GSUFF) $(GEODES)
#  endif
# endif
# if defined(GCM) || defined(GCM_ONLY)
GEODES := $(GEODE)GCM.$(GSUFF) $(GEODES)
# endif
#endif


#if !empty(SRCS:M*.GOC)
GOCDEPENDS	:= GOC GOC $(GOC) -M $(GOCFLAGS) ENDFLAGS
#else
GOCDEPENDS	?=
#endif

#if !empty(SRCS:M*.C) || !empty(SRCS:M*.GOC) || (defined(UI_TO_RDFS) && !empty(UI_TO_RDFS))
CDEPENDS	:= $(COMPILER_DEPENDS) ENDFLAGS 
#else
CDEPENDS	?= 
#endif

#if defined(MODULES) && !empty(MODULES)
ASMDEPENDS	:= ASM ESP $(ASM) -M $(ASMFLAGS:N-[Ww]*) ENDFLAGS
#elif defined(ASM_TO_OBJS) && ! empty(ASM_TO_OBJS)
ASMDEPENDS	:= ASM ESP $(ASM) -M $(ASMFLAGS:N-[Ww]*) ENDFLAGS
#else
ASMDEPENDS	?=
#endif

#ifndef MAKEDPND
MAKEDPND	= makedpnd
#endif

$(DEPFILE)	: $(SRCS)
##	-del $(.TARGET:X\\[*\\].*).BAK
##	-copy $(.TARGET) $(.TARGET:X\\[*\\].*).BAK
	$(MAKEDPND) $(CMODULES) ENDCMODULES $(MODULES) ENDASMMODULES $(GOCDEPENDS) $(CDEPENDS) $(ASMDEPENDS) $(SRCS:M*.GOC) $(SRCS:M*.C) $(UI_TO_RDFS) $(ASM_TO_OBJS) ENDFILES
# if exists($(GEODE).GP)
	findlbdr $(GEODE).GP $(DEPFILE) $(GEODES)
# elif exists($(INSTALLED_SOURCE)\$(GEODE).GP)
	findlbdr $(INSTALLED_SOURCE)\$(GEODE).GP $(DEPFILE) $(GEODES)
# endif

##############################################################################
# Help out Makefile.top -- make "all" be an alias for "full"
#
all	: full
