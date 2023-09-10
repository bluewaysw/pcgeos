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
#	tags	    	    	Generate tags file
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/26/89		Initial Revision
#
# DESCRIPTION:
#	This is a makefile that will create any type of geode. It expects
#	to have the following variables defined:
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
#	    COMMAIZE
#	    COPY_IF_DIFF
#			Perl scripts that help out NT Pmake, which can't
#			rely on having a decent shell to work with.
#	    GOC_COMPILER_DIR
#			$(GOC_COMPILER_DIR)/include should be
#			the include directory for the C compiler
#			used with GOC (e.g., C:/BC5).
#
#
#	The typical makefile will thus look like this:
#
#	OBJS	    = ...
#	SRCS	    = ...
#	GEODE	    = ...
#
#	#include <geos.mk>
#	#include <gpath.mk>
#	#include <geode.mk>
#
#	This will make both an error-checking and a non-error-checking version
#	unless NO_EC is defined.
#
#	$Id: geode.mk,v 1.1 97/04/04 14:20:26 newdeal Exp $
#
###############################################################################

#
# Set up path for .h files now we know we're creating a geode, not a UNIX tool
#
#
# GOC_COMPILER_DIR is expected to be set by the setup app.  It
# should point at the directory where Borland is installed.
#
GOC_COMPILER_DIR ?= c:/watcom-v2
GOC_COMPILER_DIR := $(GOC_COMPILER_DIR:S,\\,/,g)

.PATH.h         : . $(DEVEL_DIR)/CInclude $(CINCLUDE_DIR) $(CANSI_DIR) $(INSTALL_DIR) \
		  $(GOC_COMPILER_DIR)/h

#
# Mark the important things as files being included so their paths make it
# into .INCLUDES
#
.INCLUDES	: .def .rdef .uih .goh

#
# Mangle the flags given to UIC/CPP to tell it to not look in the directory
# containing the file performing an #include "file". Rather, it should look
# in all the directories we've specified in the order in which we've specified
# them. Rather than burden the user with this, we simply mangle the UICFLAGS
# variable to have all the non-I flags at the front, followed by all the -I
# flags twice, with the magic -I- separating the two lists.
#
# NOTE: NOTHING SHOULD BE ADDED TO UICFLAGS AFTER THIS FILE IS INCLUDED
#
UICFLAGS	:= $(UICFLAGS:N-I*) $(UICFLAGS:M-I*) -I- $(UICFLAGS:M-I*)

GSUFF		?= geo


#
# Tell the linker the type of geode it's creating so Swat knows where to look
#
## XXX: ditto
#if $(GSUFF) == "geo" || $(GSUFF) == "GEO"
# if !empty(INSTALL_DIR:M*/Appl/*)
LINKFLAGS	+= -T 1
# elif !empty(INSTALL_DIR:M*/Library/*)
LINKFLAGS	+= -T 2
# elif !empty(INSTALL_DIR:M*/Driver/*)
LINKFLAGS	+= -T 3
# else
LINKFLAGS	+= -T 4
# endif
#endif

###############################################################################
#
#	Handle driver protocols. Glue takes symbolic constant names as valid
#	protocol numbers, so adjust _PROTO to be the proper major and minor
#	constant names, separated by the requisite decimal point.
#

#if defined(PROTOCONST) && empty(BRANCH:MRelease1*)
_PROTO		:= $(PROTOCONST)_PROTO_MAJOR.$(PROTOCONST)_PROTO_MINOR
#endif

##############################################################################
#
#	Deal with ui-only applications. These puppies have no objects listed,
#	since they consist of only a .ui file. It makes no sense (and in
#	fact breaks things) to try and make an error-checking version of
#	the sucker, so if the OBJS variable is empty, automatically set NO_EC
#
#if	defined(OBJS) && empty(OBJS)
NO_EC		=
#endif

#if	defined(GEODE)

##############################################################################
#
# 	Define the main, part and full targets. "part" only creates the
#	most-used version. If NO_EC is defined, this means a non-errorchecking
#	version, else it's the error-checking version. "full" always makes
#	both.
#
# ifndef GCM_ONLY
#  ifdef NO_EC
.MAIN		: $(GEODE).$(GSUFF)
part		:: $(GEODE).$(GSUFF)
full		:: $(GEODE).$(GSUFF)
#  elifdef NO_NEC
.MAIN		: $(GEODE)ec.$(GSUFF)
part		:: $(GEODE)ec.$(GSUFF)
full		:: $(GEODE)ec.$(GSUFF)
#  else
.MAIN		: $(GEODE)ec.$(GSUFF)
part		:: $(GEODE)ec.$(GSUFF)
full		:: $(GEODE)ec.$(GSUFF)
full		:: $(GEODE).$(GSUFF)
#  endif NO_EC
# endif GCM_ONLY

# if defined(GCM) || defined(GCM_ONLY)
#  if defined(GCM_ONLY)
.MAIN		: $(GEODE)gcm.$(GSUFF)
#  endif
full		:: $(GEODE)gcm.$(GSUFF)
# endif GCM

#
# Make full depend on the ec and non-ec geodes for all the products, too
# if defined(PRODUCTS)
_COMMAPRODS	!= $(COMMAIZE) $(PRODUCTS)
#  ifndef NO_NEC
full		:: $(PRODUCTS:S|$|/$(GEODE).$(GSUFF)|g)
#  endif
#  ifndef NO_EC
full		:: $(PRODUCTS:S|$|/$(GEODE)ec.$(GSUFF)|g)
#  endif
# endif

#
# List of products with product-specific .ldf files
# if defined(PRODUCT_LDFS)
_COMMALDFS	!= $(COMMAIZE) $(PRODUCT_LDFS)
# endif

##############################################################################
#
#	Handle a library header. A regular library need only define LIBOBJ
#	and MERGE_FILES, but LIBHDR and LIBTEMP are provided in case a user
#	wants to do something different.
#
#	The library header is created from a template and a set of source
#	files with a declarations section in a known format. See docToHeader
#	for more information.
#
#	LIBTEMP normally ends in the suffix .temp, in which case it may reside
#	either in the current directory or in the library's installed source
#	directory. If LIBTEMP does not end in .temp, however, it must contain
#	the full path to the template file.
#
# if	defined(LIBOBJ) && !defined(LIBHDR)
LIBHDR		:= $(LIBOBJ:R:T).def
# endif

# if	defined(LIBHDR) && defined(MERGE_FILES)

.SUFFIXES	: .temp
.PATH.temp	: $(INSTALL_DIR)

LIBTEMP		?= $(LIBHDR:R).temp
XDCFLAGS	?=

#  if !empty(LIBHDR:M/*)
LIBHDRPATH	= $(LIBHDR)
#  elif $(DEVEL_DIR:T) == "Installed"
LIBHDRPATH	= $(INCLUDE_DIR)/$(LIBHDR)
#  else
LIBHDRPATH	= $(DEVEL_DIR)/Include/$(LIBHDR)
#  endif

def		: $(LIBHDRPATH)    	    		.NOTMAIN .JOIN

$(LIBHDRPATH)	: $(MERGE_FILES)    	    		.NOTMAIN
#  if	$(LIBTEMP:E) != "temp"
	rm -f $(.TARGET)
	$(EXTRACT) -t $(LIBTEMP) $(XDCFLAGS) $(.ALLSRC) > $(.TARGET)
	chmod -w $(.TARGET)
#  else
$(LIBHDRPATH)	: $(LIBTEMP)
	rm -f $(.TARGET)
	$(EXTRACT) -t $(.ALLSRC:M*.temp) $(XDCFLAGS) \
	    $(.ALLSRC:N*.temp) > $(.TARGET)
	chmod -w $(.TARGET)
#  endif

#  if	make(full)
full		:: def
DEFDEP		= def
#  else
DEFDEP		=
#  endif

# else no def to be made
DEFDEP		=
# endif


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
$(MODULES:S/$/.$(SUFFS)/g)	: ASSEMBLE $(DEFDEP)

#   ifdef PRODUCTS
$(MODULES:S|^|$(_COMMAPRODS)/|g:S|$|.$(SUFFS)|g) : ASSEMBLE $(DEFDEP)
#   endif

#  endif
#  if defined(GCM) || defined(GCM_ONLY)
$(MODULES:S/$/.gobj/g)		: ASSEMBLE $(DEFDEP)
#  endif
# else
$(GOBJS) $(EOBJS) $(OBJS)	: $(DEFDEP)
# endif MODULES

##############################################################################
#
#	Make sure any geode parameter file makes it as a source for the
#	geode...
#

# if (defined(GCM) || defined(GCM_ONLY)) && \
	(exists($(GEODE)gcm.gp) || exists($(INSTALL_DIR)/$(GEODE)gcm.gp))
$(GEODE)gcm.$(GSUFF): $(GEODE)gcm.gp
#endif

## XXX: change back to just comparing against "geo" once case-insensitivity
##      added
# if ($(GSUFF) == "geo") || ($(GSUFF) == "GEO")
$(GEODE)ec.$(GSUFF) : $(GEODE).gp
$(GEODE).$(GSUFF)   : $(GEODE).gp
#  ifdef PRODUCTS
$(_COMMAPRODS)/$(GEODE)ec.geo : $(GEODE).gp
$(_COMMAPRODS)/$(GEODE).geo : $(GEODE).gp
#  endif
# endif


##############################################################################
#
#	Deal with library definition file created by the linker.

# if 	defined(LIBOBJ)
#
# Tell link to create the .ldf file at the right time. If no error-checking
# version will be made, we just always pass -l. Else we only do it for
# the error-checking version
#
# Note that we *never* pass -l if the target is in a subdirectory (as the
# flavors of the kernel are -- we want geos.ldf to come from the main, desktop
# version of the kernel)
#
#  ifndef NO_EC
SETLIBFLAG	= $(.TARGET:N*/*:M*ec.geo:S/$(.TARGET)/-l/) $(.TARGET:N*/*:N*ec.geo:M*ec.exe:S/$(.TARGET)/-l/)
#  else
SETLIBFLAG	= -l
#  endif

#
# The :S in the LIBOBJ's below is to prevent a colon in there from getting
# interpreted as a separator between target and dependencies.
#
# XXX: under Unix, this section does a cool cmp first to see if it
# really needs to copy the .ldf file (if the .ldf's are exactly
# the same, then it needn't do the copy).  That would be cool, because
# it means that you won't get spurious remakes when you compile
# other things that depend on the .ldf.  Unfortunately, the NT
# cmd shell is too lame to handle the construct, and also there
# is no "cmp" under NT by default.  We'd have to write a perl
# script or something, say, called "diffcopy".  For now, we just
# copy the file over.
#
$(LIBOBJ:S/:/\\:/g)       : $(LIBOBJ:T) .NOEXPORT .IGNORE
	$(COPY_IF_DIFF) $(LIBOBJ:T) $(.TARGET)
#  ifdef PRODUCT_LDFS
$(LIBOBJ:H:S/:/\\:/g)/$(_COMMALDFS)/$(LIBOBJ:T)	: $(.TARGET:H:T)/$(LIBOBJ:T) .NOEXPORT .IGNORE
	$(COPY_IF_DIFF) $(.TARGET:H:T)/$(LIBOBJ:T) $(.TARGET)
#  endif

#$(LIBOBJ)	: $(GEODE).ldf .NOEXPORT .IGNORE
#	cmp -s $(GEODE).ldf $(.TARGET) || cp $(GEODE).ldf $(.TARGET)

#  if	defined(NO_EC)
$(LIBOBJ:T)	: $(GEODE).$(GSUFF)
#   ifdef PRODUCT_LDFS
$(_COMMALDFS)/$(LIBOBJ:T)	: $(.TARGET:H)/$(GEODE).$(GSUFF)
#   endif
#  else
$(LIBOBJ:T)	: $(GEODE)ec.$(GSUFF)
#   ifdef PRODUCT_LDFS
$(_COMMALDFS)/$(LIBOBJ:T)	: $(.TARGET:H)/$(GEODE)ec.$(GSUFF)
#   endif
#  endif

#  ifdef PRODUCT_LDFS
#   if !empty(PRODUCT_LDFS)
part full	:: $(LIBOBJ) $(LIBOBJ_PRODS)
lib		: $(LIBOBJ) $(LIBOBJ_PRODS)			.JOIN
#   else
part full	:: $(LIBOBJ)
lib		: $(LIBOBJ)					.JOIN
#   endif
#  else
part full	:: $(LIBOBJ)
lib		: $(LIBOBJ)					.JOIN
#  endif

# elif	!defined(GCM_ONLY)
#  if	defined(NO_EC)
lib		: $(GEODE).$(GSUFF)
#  else
lib		: $(GEODE)ec.$(GSUFF)
#  endif
# else
lib		: $(GEODE)gcm.$(GSUFF)
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
$(GEODE).$(GSUFF)   : $(OBJS)	    	    	    	    	LINK

#   ifdef PRODUCTS
$(_COMMAPRODS)/$(GEODE).$(GSUFF) : $(OBJS:S|^|$(.TARGET:H)/|g)	LINK
#    ifdef NO_EC
$(PRODUCTS) 	    :: $(.TARGET)/$(GEODE).$(GSUFF)
#    else
$(PRODUCTS:S/$/_full/g) :: $(.TARGET:S/_full//)/$(GEODE).$(GSUFF)
#    endif
#   endif

#   if !defined(NO_EC)
$(GEODE)ec.$(GSUFF) : $(EOBJS)	    	    	    	    	LINK

#    ifdef PRODUCTS
$(_COMMAPRODS)/$(GEODE)ec.$(GSUFF) : $(EOBJS:S|^|$(.TARGET:H)/|g) LINK

$(PRODUCTS:S/$/_full/g) :: $(.TARGET:S/_full//)/$(GEODE)ec.$(GSUFF)
$(PRODUCTS) 	    :: $(.TARGET)/$(GEODE)ec.$(GSUFF)
#    endif

#   endif
#  endif GCM_ONLY

#  if defined(GCM) || defined(GCM_ONLY)
$(GEODE)gcm.$(GSUFF): $(GOBJS)					LINK
#  endif
# endif

## XXX: ditto
# if !defined(NO_LOC) && ($(GSUFF) == "geo" || $(GSUFF) == "GEO")
$(GEODE).vm	: $(GEODE).$(GSUFF) 
# if defined(linux)
	$(LOC) $(LOCFLAGS) -o $(.TARGET) `ls *.rsc `
# else
	$(LOC) $(LOCFLAGS) -o $(.TARGET) *.rsc
# endif

#   ifdef PRODUCTS
$(_COMMAPRODS)/$(GEODE).vm : $(.TARGET:R).$(GSUFF)
	$(LOC) $(LOCFLAGS) -o $(.TARGET) $(.TARGET:H)/*.rsc
$(PRODUCTS:S/$/_full/g) :: $(.TARGET:S/_full//)/$(GEODE).vm

#   endif

#  ifndef NO_NEC
full		:: $(GEODE).vm

#   ifdef PRODUCTS
full		:: $(PRODUCTS:S|$|/$(GEODE).vm|g)
#   endif
#  endif NO_NEC

# endif


#endif defined(GEODE)


##############################################################################
#
# Create the tags file from all the sources in their current locations.
#
tags		: $(SRCS) $(GPFILE)
	$(PCTAGS) $(PCTAGSFLAGS) $(.ALLSRC)

ref		: $(SRCS)
	makeRef -r -n $(.ALLSRC) > ref

mkmf		::
	mkmf -f $(MAKEFILE)

xref		: $(SRCS)
	$(PCXREF) $(PCXREFFLAGS) $(.ALLSRC:M*.asm) > $(.TARGET)

#if 0
# Disabled under Win32, because we have not ported pctags
full		:: tags
#endif

##############################################################################
#
# Automatic dependency generation. Uses asap in its makedepend mode to get all
# the files included by each of the modules.
#
# For the large-model geode, each module Module must have a manager file
# Module/moduleManager.asm for this to work.
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
# TAGLINE is the line after which the dependencies are placed in $(DEPFILE).
#
DEPFILE		?= dependencies.mk
DEPFLAGS	?=

TAGLINE		?= \# DO NOT DELETE THIS LINE
#ifdef PRODUCTS
depend		: $(DEPFILE) $(PRODUCTS:S|$|/$(DEPFILE)|g)
#else
depend		: $(DEPFILE)
#endif

#-----------------------------------------------------------------------------#

$(DEPFILE)	: $(SRCS)

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


#if !empty(SRCS:M*.GOC) || !empty(SRCS:M*.goc) 
GOCDEPENDS      = GOC GOC $(GOC) -M $(GOCFLAGS) ENDFLAGS
#else
GOCDEPENDS	?=
#endif

#ifndef COMPILER_DEPENDS
## The asmflags are needed because cpp is used to do dependencies
## for .ui files (thus needing to be able to find the .uih files
## in CInclude).
COMPILER_DEPENDS       = CPP BORLAND $(CPP) $(CCOMFLAGS:M-I*) $(CCOMFLAGS:M-i=*) $(CCOMFLAGS:M-D*) $(ASMFLAGS:M-I*)
#endif

#if !empty(SRCS:M*.C) || !empty(SRCS:M*.GOC) || !empty(SRCS:M*.c) || !empty(SRCS:M*.goc) ||  (defined(UI_TO_RDFS) && !empty(UI_TO_RDFS))
## Remove -ml and -dc because cpp32 can't handle it, and it doesn't make
## any difference as far as generating dependencies goes.
CDEPENDS        = $(COMPILER_DEPENDS:N-[md]?:S/\\/\//g:S/-i=/-I/g) ENDFLAGS
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

#ifndef CMODULES
CMODULES =
#endif

#ifndef MODULES
MODULES =
#endif MODULES

##ifndef CPP
## Use cpp32 instead of cpp so that it can find include files in
## directories that are longer than 8.3 (e.g.,
## -Is:\pcgeos\LongProductName\Include).  cpp.exe from bc45 and earlier
## can't handle that...
CPP	= uicpp -M
#wcc -pcl 
##endif

#ifndef ASM_TO_OBJS
## This won't be defined for large model.
ASM_TO_OBJS =
#endif

# In the MAKEDPND command, I use $(.TARGET:S|DEPENDENCIES.MK|dependencies.mk|)
# instead of just $(.TARGET) to make sure that the dependency file is generated
# with a lowercase name, even if NT forces it to be upper. -- mgroeber 10/12/00
#ifdef PRODUCTS
$(PRODUCTS:S|$|/$(DEPFILE)|g) $(DEPFILE) : $(SRCS) $(GPFILE)
#else
$(DEPFILE) : $(SRCS) $(GPFILE)
#endif
##	-del $(.TARGET:X\\[*\\].*).BAK
##	-copy $(.TARGET) $(.TARGET:X\\[*\\].*).BAK
	$(MAKEDPND) $(ROOT_DIR) $(DEVEL_DIR) $(INSTALL_DIR) -o$(.TARGET:S|DEPENDENCIES.MK|dependencies.mk|) `$(PRODUCT_FLAGS) goc $(PRODUCT)` $(CMODULES) ENDCMODULES $(MODULES) ENDASMMODULES $(GOCDEPENDS) $(CDEPENDS) $(ASMDEPENDS) $(SRCS:M*.GOC) $(SRCS:M*.goc) $(SRCS:M*.C) $(SRCS:M*.c) $(UI_TO_RDFS) $(ASM_TO_OBJS) ENDFILES
#if exists($(.ALLSRC:M*.gp))
	findlbdr $(.ALLSRC:M*.gp) $(.TARGET) $(GEODES)
#elif exists($(.ALLSRC:M*.GP))
	findlbdr $(.ALLSRC:M*.GP) $(.TARGET) $(GEODES)
#elif exists($(INSTALL_DIR)/$(GEODE).GP)
	findlbdr $(INSTALL_DIR)/$(GEODE).GP $(.TARGET) $(GEODES)
#elif exists($(INSTALL_DIR)/$(GEODE).gp)
	findlbdr $(INSTALL_DIR)/$(GEODE).gp $(.TARGET) $(GEODES)
#elif exists($(GEODE).GP)
	findlbdr $(GEODE).GP $(.TARGET) $(GEODES)
#elif exists($(GEODE).gp)
	findlbdr $(GEODE).gp $(.TARGET) $(GEODES)
#endif
