##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	PMake System Library -- Generic GEOS definitions
# FILE: 	geos.mk
# AUTHOR: 	Adam de Boor, Jul 23, 1989
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	ASSEMBLE    	    	Rule to assemble a module of a large-model
#	    	    	    	geode
#	LINK	    	    	Rule to link a set of object files (the
#	    	    	    	sources) to form a .exe file (the target)
# TRANSFORMATIONS:
#	.goc -> .gc		Run a file through the C pre-processor
#	.gc -> .c		Run goc on a file
#	.ui -> .rdef	    	Generate assembly language definitions from
#	    	    	    	a Generic UI description file
#	.rdef -> .rasm	    	Form a template assembly file that
#				includes the implied .rdef file
#	.rasm -> .geo	    	Create a geode from a .rasm file
#	.asm -> .obj	    	Create a non-error-checking object file
#	.asm -> .eobj	    	Create an error-checking object file
#	.eobj -> ec.exe	    	Link an error-checking object file into its
#	    	    	    	error-checking .exe file
#	.obj -> .exe	    	Link a non-error-checking object file into
#	    	    	    	its non-error-checking .exe file
#	.eobj -> ec.geo	    	Link an error-checking object file into its
#	    	    	    	error-checking .geo file
#	.obj -> .geo	    	Link a non-error-checking object file into
#	    	    	    	its non-error-checking .geo file
#	.obj -> .vm	    	Transform a .obj file into an PC/GEOS VM file
#	.obj -> .fnt		Transform a .obj file into an PC/GEOS font file
#	.obj -> .bin		Transform a .obj file into an binary file
#	.obj -> .com	    	Transform a .obj file into a DOS .com file.
#
# VARIABLES:
# 	Name			Description
#	----			-----------
#	SOURCE_PATHS	    	Paths to all modules of a large-model geode
#	LOBJS	    	    	Object files for which no source exists
#	OBJS	    	    	Module-objects for a large-model geode
#	EOBJS	    	    	Transformation of $(OBJS) to use .eobj suffix
#	-IFLAGS	    	    	-I flags passed to assembler when generating
#	    	    	    	a module for a large-model geode
#	SUFFS	    	    	Wildcard pairing of .eobj and .obj suffixes
#	CURRENT_DIR 	    	Current working directory
#	ROOT_DIR    	    	Root of PC/GEOS tree
#	KERNEL_DIR  	    	Installed source for kernel
#	APPL_DIR    	    	Root of installed source for applications
#	DRIVER_DIR  	    	Root of installed source for drivers
#	LIBRARY_DIR 	    	Root of installed source for libraries
#	INCLUDE_DIR 	    	Location of installed include files
#	CINCLUDE_DIR 	    	Location of installed C include files
#	LOBJ_DIR    	    	Location of library objects for linking
#	    	    	    	with applications
#	DEVEL_DIR   	    	Root of user's development tree.
#	SUBDIR	    	    	Piece of CURRENT_DIR below DEVEL_DIR
#	INSTALL_DIR 	    	Installed source directory for CURRENT_DIR
#	UICPP	    	    	Preprocessor for UIC
#	UIC 	    	    	Command for compiling .ui files
#	UICFLAGS    	    	Flags to pass same
#	XUICFLAGS   	    	Extra flags for same provided by user when
#				pmake was invoked
#	ASM	    	    	Assembler
#	ASMFLAGS   	    	Flags for same
#	ASMWARNINGS 	    	Default warning flags for same
#	XASMFLAGS  	    	Extra flags for same (See XUICFLAGS)
#	LINK	    	    	Object-file linker
#	LINKFLAGS   	    	Flags for same
#	XLINKFLAGS  	    	Extra flags for same (See XUICFLAGS)
#	OPTIONAL_LIB   	    	passes glue a math.lib file with the -l
#	    	    	    	flag so that it only gets linked in if it
#	    	    	    	is actually used
#	LIB 	    	    	Command to convert from .obj to .lobj (a
#	    	    	    	library object)
#	LIBFLAGS    	    	Flags for same
#	XLIBFLAGS   	    	Extra flags for same (See XUICFLAGS)
#	PCTAGS    	    	Command to make tags files
#	PCTAGSFLAGS    	    	Flags for same
#	PCXREF	    	    	Command to make xref files
#	PCXREFFLAGS 	    	Flags for same
#       GEOERRFL		Win32 DOS app to reformat error messages
#                               (Added to support MSDEV Studio)
#
#	_REL			Revision to pass to Esp and Glue
#	_PROTO			Revision to pass to Esp and Glue
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/23/89		Initial Revision
#
# DESCRIPTION:
#	This is a makefile to be included by all makefiles in the PC/GEOS
#	system. It provides the basic definitions of the various pieces
#	and transformation and .USE rules needed to create certain general
#	pieces.
#
#	$Id: geos.mk,v 1.1 97/04/04 14:20:27 newdeal Exp $
#
#
###############################################################################
#ifndef _GEOS_MK_
_GEOS_MK_	= 1

#
# First the suffixes we use...
#
.SUFFIXES	: ec.geo gcm.geo .geo ec.exe .exe .com .vm .fnt .ldf \
		  .eobj .gobj .obj .lobj .asm .def .rdef .grdef .ui .i .uih \
                  .rasm .gp .temp .bin .c .goc .egc .gc .nc .ec .goh .h
# .INCLUDES for geodes moved to geode.mk to avoid screwing up UNIX tools

#
# Make sure .PATH.h goes into $(.INCLUDES).  This should be in
# system.mk, but we don't have one under NT.
#
.INCLUDES	: .h

#
#	This variable makes life easier, in that it causes a target to expand
#	to its .obj and .eobj targets automatically. It is used as:
#	   Boot.$(SUFFS)
#	to expand to both Boot.obj and Boot.eobj
#
SUFFS		= {eobj,obj}

#
# Define LIBNAME to be empty now so it can be used in ASMFLAGS and GOCFLAGS
#
LIBNAME		?=

#
# The PRODUCT variable can be set by the local.mk file if the program being
# compiled is always product-specific. If it's not, it defaults to determining
# the product by looking at the first component of the target being made.
#
PRODUCT		?= $(.TARGET:X\\[*\\]/*)

#
# Define the pieces of the installed source tree. The including makefile can
# override these definitions, if it desires, but it probably shouldn't...
#
ROOT_DIR	:= $(ROOT_DIR:S,\\,/,g)
KERNEL_DIR	?= $(ROOT_DIR)/Kernel
APPL_DIR	?= $(ROOT_DIR)/Appl
DRIVER_DIR	?= $(ROOT_DIR)/Driver
LIBRARY_DIR	?= $(ROOT_DIR)/Library
INCLUDE_DIR	?= $(ROOT_DIR)/Include
CINCLUDE_DIR	?= $(ROOT_DIR)/CInclude
CANSI_DIR	?= $(ROOT_DIR)/CInclude/Ansi
TOOL_DIR	?= $(ROOT_DIR)/Tools

#if defined(GEOERRFL)
GEOERRFL	:= 2>&1 | $(GEOERRFL)
#else
GEOERRFL	:=
#endif

#
# We always want to find these scripts on the trunk.
#
# NOTE: the 2nd two only used in geode.mk.
#
PRODUCT_FLAGS	:= perl $(ROOT_DIR)/Tools/scripts/perl/product_flags
COMMAIZE	:= perl $(ROOT_DIR)/Tools/scripts/perl/pmake-comma
COPY_IF_DIFF	:= perl $(ROOT_DIR)/Tools/scripts/perl/copy-if-different


## XXX: fix for NT...
#if defined(PRODUCTS) && defined(EXEMPTPRODUCTS)
PRODUCTS	!= echo $(PRODUCTS) | tr ' ' '\012' | egrep -v "${EXEMPTPRODUCTS}" | (tr '\012' ' ' && echo)
#endif
#if defined(PRODUCT_LDFS) && defined(EXEMPTPRODUCTS)
PRODUCT_LDFS	!= echo $(PRODUCT_LDFS) | tr ' ' '\012' | egrep -v "${EXEMPTPRODUCTS}" | (tr '\012' ' ' && echo)
#endif
#if defined(PRODUCT_VMS) && defined(EXEMPTPRODUCTS)
PRODUCT_VMS	!= echo $(PRODUCT_VMS) | tr ' ' '\012' | egrep -v "${EXEMPTPRODUCTS}" | (tr '\012' ' ' && echo)
#endif

#
# Figure out where we are. Various other makefiles use this to determine
# which application/library/driver is being made. It's also useful to have
# anyway.
#
#if defined(linux)
CURRENT_DIR	!= pwd
#else
CURRENT_DIR	!= cd
CURRENT_DIR	:= $(CURRENT_DIR:S,\\,/,g)
#endif

##
## Deal with having pieces of the Installed tree on local disks, not under
## a pcgeos umbrella. e.g. /n/cs/Installed/Library needs to be transformed
## into $(ROOT_DIR)/Installed/Library
##
##if	empty(CURRENT_DIR:M*pcgeos*)
#CURRENT_DIR	!= expr $(CURRENT_DIR) : '/n/[a-z]*/\(.*\)'
#CURRENT_DIR	:= $(ROOT_DIR)/$(CURRENT_DIR)
##endif

#
# Figure out where the installed and development directories for the current
# thing are. DEVEL_DIR is simply the root directory followed by the
# first component of the current directory that follows the root (e.g.
# /staff/pcgeos/biff if CURRENT_DIR is /staff/pcgeos/biff/Appl/Calla).
# SUBDIR is set to everything in CURRENT_DIR but DEVEL_DIR (Appl/Calla
# in the above example). INSTALL_DIR is thus the current directory
# with the user's name clipped out of it.
#
#if $(CURRENT_DIR:H:T) == "$(ROOT_DIR:T)"
DEVEL_DIR	:= $(CURRENT_DIR)
SUBDIR		= .
INSTALL_DIR	= .

#else

# Not immediately below the root...
DEVEL_DIR	:= $(CURRENT_DIR:X\\[*/$(ROOT_DIR:T)/*\\]/*)
SUBDIR		:= $(CURRENT_DIR:X*$(DEVEL_DIR)/\\[*\\])
INSTALL_DIR	:= $(ROOT_DIR)/$(SUBDIR)

#endif

#if exists($(DEVEL_DIR)/BRANCH)
#	If this development tree is for an RCS branch, rather than the main
#	development trunk, switch the root directory to be for the branch.
#	This allows .ldf and .def files to be created in the right place, etc.
#
BRANCH		!= type $(DEVEL_DIR:S,/,\\,g)\BRANCH
ROOT_DIR	:= $(ROOT_DIR)/$(BRANCH)
INSTALL_DIR	:= $(ROOT_DIR)/$(SUBDIR)

#else

BRANCH		=

#endif

#
# This used to be up with the other stuff (APPL_DIR, et al), but it actually
# varies based on the branch... -- ardeb 5/31/94
#
LOBJ_DIR	?= $(ROOT_DIR)/Installed/Include


T		:= $(DEVEL_DIR:T)

#
# Deal with doing a make from within a branch directory (e.g. in the Installed
# tree of a branch). We need to get the proper INSTALL_DIR (the source directory
# in the branch-installed area), and set DEVEL_DIR to the directory below
# the root of the branch, for proper determination of what to send to grev
# Note that ROOT_DIR has already had $(BRANCH) stuck at its end...
#

#if $T == "$(BRANCH)"
SUBDIR		:= $(CURRENT_DIR:X*/$(ROOT_DIR:H:T)/$(BRANCH)/\\[*\\])
T		:= $(SUBDIR:X\\[*\\]/*)
DEVEL_DIR	:= $(ROOT_DIR)/$(T)
INSTALL_DIR	:= $(ROOT_DIR:H)/$(SUBDIR)

#endif

#
# Figure the real subdirectory and installed source directory if this is
# in the Installed tree of the trunk or a branch.
#
# If we're in the top-most directory of the Installed tree, just use . as
# the INSTALL_DIR, same as if we're in $(ROOT_DIR) or a source tree.
#
#if $T == "Installed"
# if $(SUBDIR) != "Installed" && $(SUBDIR) != "" && $(SUBDIR) != ". "
SUBDIR		:= $(CURRENT_DIR:X*/Installed/\\[*\\])
INSTALL_DIR	:= $(ROOT_DIR)/$(SUBDIR)
# else
SUBDIR		=
INSTALL_DIR	= .
# endif
#endif

#
# The kernel changed its name in version 1.2 to kernel.exe...
#
#if !empty(BRANCH:MRelease12*)
KERNEL_BASE	?= kernel
#else
KERNEL_BASE	?= geos
#endif

#######################################################################
# Figure how to invoke grev
#
#if $T == "Appl" || $T == "Kernel" || $T == "Driver" || $T == "Library"

GREVTREE	= -S

#
# Set the DEVEL_DIR to be the root one instead (helps pmake def and others)
#
DEVEL_DIR	= $(ROOT_DIR)
INSTALL_DIR	= $(CURRENT_DIR)

# if !make(depend) && !make(tags) && !make(ref) && !make(xref) && !make(def) && !exists($(ROOT_DIR)/.no_devel) && empty(CURRENT_DIR:M*Library/Math/Compiler*)
.BEGIN		:
	@pmake-error You are NOT supposed to create object files in the source tree

# endif

#endif

#
# If final component of INSTALL_DIR is ".", strip it off, so things look nicer
# and don't waste time.
#

#if $(INSTALL_DIR:T) == "."
INSTALL_DIR	:= $(INSTALL_DIR:H)
#endif

#
# Make PMake search for included makefiles in the installed tree too
#
# XXX: add "." to the path to, as PMake doesn't seem to search for sources that
# are paths under the current dir before searching along the path, otherwise.
# (e.g. a source like Library/Kernel is found in /staff/pcgeos/Release20X rather
# than one's development tree, even though it exists in the development tree)
#	    -- ardeb 1/17/94
#
# 1/19/93: removed b/c it causes other problems too icky to get into -- ardeb
.PATH		: $(INSTALL_DIR)
#

#
#	Obtain revision control information. Results are left in
#	$(_REL) and $(_PROTO).
#
# XXX: disabled until grev.c has branch stuff added to it...
#if	defined(GEODE) && exists($(INSTALL_DIR)/$(GEODE).rev)
REVFILE		= $(INSTALL_DIR)/$(GEODE).rev

#if $T == "Installed"
GREVTREE	= -I
#else
GREVTREE	= -D
#endif

_GEODE	:=	$(GEODE)

GREV		?= grev
GREVFLAGS	=
#if !empty(BRANCH)
GREVFLAGS	+= -B $(BRANCH)
#endif

_REL	!=	$(GREV) neweng $(REVFILE) $(GREVFLAGS) -R
_PROTO	!=	$(GREV) getproto $(REVFILE) $(GREVFLAGS) -P

#else

_REL	=	0.0.0.0
_PROTO	=	0.0

#endif
##############################################################################
#
#		     PROGRAM AND FLAG DEFINITIONS
#
##############################################################################

#
#				 GOC
#
GOC		?= goc
XGOCFLAGS	?=
GOCFLAGS	+= -D__GEOS__ $(-CIFLAGS) -I- $(-CIFLAGS) \
		   `$(PRODUCT_FLAGS) goc $(PRODUCT)` \
                   $(XGOCFLAGS) -w -l $(LIBNAME:S/^/-L /)


#
#	Path for goc include files
#
.PATH.goc	: $(INSTALL_DIR) $(DEVEL_DIR)/CInclude $(CINCLUDE_DIR) $(CANSI_DIR)

#
#				 UIC
#

#
# Under Win32, we have a special version of cpp, since Borland's
# is not capable of writing to stdout!  Borland's also tries
# to parse portions of the file that it ought to leave alone
# thereby causing spurious "compile" errors.
#
UICPP		?= uicpp
UIC		?= uic

# UIC used to use $(-IFLAGS) instead of $(-UICFLAGS), but too many
# -Iincludes blew out the shell capabilities in win32 (exceeded max
# command length...)
-UICFLAGS	+= -I$(INSTALL_DIR) -I$(INCLUDE_DIR) -I.
UICFLAGS	+= $(-UICFLAGS) `$(PRODUCT_FLAGS) uic $(PRODUCT)` $(XUICFLAGS) -l
XUICFLAGS	?=

#
#	Path for uic include files
#
.PATH.uih	: $(INSTALL_DIR) $(DEVEL_DIR)/Include $(INCLUDE_DIR)

#if exists( template.asm )
TEMPLATE_DIR	=	.
#elif exists( $(DEVEL_DIR)/Include/template.asm )
TEMPLATE_DIR	=	$(DEVEL_DIR)/Include
#else
TEMPLATE_DIR	=	$(INCLUDE_DIR)
#endif

#
#			      ASSEMBLER
#
# XASMFLAGS is intended to be filled on the command-line
#
ASM		?= esp

#if empty(BRANCH) || empty(BRANCH:MRelease1*)
# change lmem segment alignment to dword for 2.0 and later
ASMFLAGS	+= -L 4
#else
# tell Esp it's assembling 1.X stuff
ASMFLAGS	+= -G 1
#endif

# note that all paths containing /CInclude* are stripped out for
# the assembly stuff as well as sub directories of Include...
#
# 6/1/94: there is a quirk of pmake and the :X modifier when applied to
# a single-word variable, like .TARGET, that we take advantage of here: if
# the pattern fails to match, no further modifiers will actually take
# effect, not even :S|^|something|, because all the modifiers are defined
# as applying to the individual words of the string. If the pattern fails
# to match, there are no words in the string, so no further modifications
# happen. This allows us to pass -I<product> only when creating a product-
# specific object file, but also requires the funky second thing involving
# -DPRODUCT, which essentially replaces any .TARGET variable that has no
# slash in it (i.e. a non-product-specific target) with -DPRODUCT=, creating
# an empty PRODUCT string. -- ardeb
#
ASMWARNINGS	?= -Wall
ASMFLAGS	+= $(.TARGET:X\\[*\\]/*:S|^|-I|) \
                   $(.INCLUDES:N*Include/*:N*/CInclude*) $(ASMWARNINGS) \
		   `$(PRODUCT_FLAGS) esp $(PRODUCT)` \
                   $(XASMFLAGS) \
                   -DREL=$(_REL) -DPROTO=$(_PROTO) \
                   $(.TARGET:X*.\\[obj\\]:S/obj/-l $(.TARGET:R).rsc/) \
                   $(LIBNAME:S/^/-n /)
XASMFLAGS	?=

#
#				LINKER
#
# Same for XLINKFLAGS
#
LINK		?= glue
LINKFLAGS	?=
XLINKFLAGS	?=
LINKFLAGS	+= `$(PRODUCT_FLAGS) glue "$(PRODUCT)" $(DEVEL_DIR)/Include $(LOBJ_DIR)` \
                   -m -L$(DEVEL_DIR)/Include -L$(LOBJ_DIR) \
		   $(XLINKFLAGS)

#
# This is a file containing compiler specific routines for doing
# floating point math. It applies only to 2.0 and later revs.
#
OPTIONAL_LIB		?=
#OPTIONAL_LIB_TAIL	= Library/BorlandRTL/BORLAND.OBJ
OPTIONAL_LIB_TAIL	=
#if exists($(DEVEL_DIR)/$(OPTIONAL_LIB_TAIL))
#OPTIONAL_LIB		+= -l$(DEVEL_DIR)/$(OPTIONAL_LIB_TAIL)
#else
#OPTIONAL_LIB		+= -l$(ROOT_DIR)/Installed/$(OPTIONAL_LIB_TAIL)
#endif
#
#			      LIBRARIAN
#
# Same for XLIBFLAGS.
#
LIB		?= lib86 +u
LIBFLAGS	?= $(XLIBFLAGS)
XLIBFLAGS	?=

#
#				 TAGS
#
PCTAGS		?= pctags
PCTAGSFLAGS	?=

#
#			   CROSS-REFERENCE
#
PCXREF		?= pcxref
PCXREFFLAGS	?=

#
#			   HEADER CREATION
#
EXTRACT		?= docToHeader

#
#			      C COMPILER
#
# XCCOMFLAGS is intended to be filled on the command-line
#
#   -D__GEOS__ added to identify PC/GEOS usage.
#
#	-Ot: do inline structure copies rather than calling F_SCOPY@
#	-c: suppress link
#	-v: place debugging records in the output
#	-y: place line number records in the output
#	-ml: LARGE memory model
#       -i200:  identifiers are 200 characters long
#
# ***   -w-sus: Turn off suspicious pointer conversion warnings.  (Fix this in
#               GOC?  j- 5/9/96)
#
# New flags added 5/9/96.  Flags marked with a "***" indicate that the flag
# was added because of superfluous warnings generated by GOC.  We really need
# to clean these up so developers can use the "-w" flag alone.
#
#       -w: Turn on ALL warnings.
# ***   -g255: Allow 255 warnings before compilation fails.
# ***   -w-amp: Turn off "superfluous & with function" warnings
# ***   -w-pin: Turn off "initialization is only partially bracketed" warnings
# ***   -w-cln: Turn off "constant is long" warnings
# ***   -w-sig: Turn off "conversion may lose significant digits" warnings
#
# 32-bit regs compilation added 7/3/00:
#	-3:	Generate 16-bit 80386 instructions (ie. do 32-bit data
#		operations while still use 16-bit offsets in addresses.)
#		NOTE: This can be use only if SUPPORT_32BIT_DATA_REGS in
#		product.def is set to TRUE!
#
# Optimization flags added 7/3/00:  (These are the optimizations flags that
# have been tested and have showed improvements.  The other size optimization
# flags have been tested but have not showed improvements.  The other speed
# optimization flags have not been tested.  -- ayuen)
#	-Z:	Suppress redundant reloads
#	-k-:	Turn off standard stack frame
#	-Os:	Optimize for size
#	-O:	Jump optimizations
#	-Ol:	Loop optimizations
#
# The "dosfront" is there for pre-5.0 versions of bcc.exe, which
# were 16-bit DOS apps and required long command-lines to be
# stuffed into an argument file.
#
# mgroeber: removed "-w-amp" after GOC fixes 6/4/00
#
CCOM		?= wcc
CCOM_MODEL	?= -ml
# XXX: need 2 be diff. for Borland?
# Going to use Open Watcom 2.0 from now, so we reword the Borland
# setup if it comes to compile flags. This is the mapping
# used so far:
#CCOMFLAGS       += -D__GEOS__ -Ot -c -v -y -w -i200 \
#		   -Z -k- -Os -O -Ol
# v -> d3
# y -> d3
# w -> w4
# g255 ->
# i200 ->
# Ol -> ol ol+
# Os -> os
# k- ->
# Z ->
# O ->
#
# s -> no stack checking
#if defined(linux)
CCOMFLAGS       += -D__GEOS__ -D__WATCOM__ -Ot -d3 -w4 \
			-os -ol -ol+ -hc -s -ecc \
		   	$(CCOM_MODEL) \
            $(.INCLUDES:N*/Include*:S/\\/\//g:S/^-I/-i=/g) \
						-i="$(WATCOM)/h" \
		   	 		`$(PRODUCT_FLAGS) highc $(PRODUCT)` \
					$(XCCOMFLAGS)
#else
CCOMFLAGS       += -D__GEOS__ -D__WATCOM__ -Ot -d3 -w4 \
			-os -ol -ol+ -hc -s -ecc \
		   	$(CCOM_MODEL) \
            $(.INCLUDES:N*/Include*:S/\//\\/g:S/^-I/-i=/g) \
						-i="$(WATCOM)/h" \
		   	 		`$(PRODUCT_FLAGS) highc $(PRODUCT)` \
					$(XCCOMFLAGS)
#endif

#if $(PRODUCT) == "NDO2000"
#else
CCOMFLAGS	+= -3
#endif

XCCOMFLAGS	?=
GOCFLAGS	+= -cm

#
#	    	    LOCALIZATION INSTRUCTION COMPILER
#
LOC		?= loc
LOCFLAGS	?=
LOCFLAGS	+= `$(PRODUCT_FLAGS) loc $(PRODUCT)`


##############################################################################
#
#			SEARCH PATH DEFINITION
#
##############################################################################
#if	defined(LOBJS)
OBJS		+= $(LOBJS)
#endif

#ifdef	MODULES

#
#	Define object files used to make the geode based on the MODULES
#	variable.
#

#if	defined(OBJS)
OBJS		:= $(MODULES:S,$,.obj,g) $(OBJS)
#else
OBJS		:= $(MODULES:S,$,.obj,g)
#endif

#if !defined(CMODULES)
CMODULES	=
#endif

#
#	Define search paths to be all modules and their installed counterparts.
#	The .def files are also searched for in the directory of the geode.
#	Library search paths are dealt with in gpath.mk.
#
SOURCE_PATHS	= $(MODULES) $(MODULES:S,^,$(INSTALL_DIR)/,g)
CSOURCE_PATHS	= $(CMODULES) $(CMODULES:S,^,$(INSTALL_DIR)/,g)

.PATH.def	: $(SOURCE_PATHS)
.PATH.lobj	: $(SOURCE_PATHS) $(INSTALL_DIR)
.PATH.goh	: $(CSOURCE_PATHS)

.PATH.h		: $(CSOURCE_PATHS)
.PATH.asm	: $(SOURCE_PATHS)
.PATH.c		: $(CSOURCE_PATHS)
.PATH.goc	: $(CSOURCE_PATHS)
.PATH.ui	: $(INSTALL_DIR) $(SOURCE_PATHS)
#else

.PATH.ui	: $(INSTALL_DIR)
.PATH.lobj	: $(INSTALL_DIR)
#endif MODULES

.PATH.gp	: $(INSTALL_DIR)

.PATH.ldf	: $(DEVEL_DIR)/Include $(LOBJ_DIR)

#if	defined(OBJS)
EOBJS		:= $(OBJS:S,.obj$,.eobj,g)
GOBJS		:= $(OBJS:S,.obj$,.gobj,g)
#endif

#
#	Standard method for assembling a module. The location of the
#	target file defines which module is being assembled. ASM is
#	made to look for included files in:
#	     - the uninstalled directory for the module
#	     - the installed directory for the module
#	in that order.
#
#       The shell variable ef is set to -DDO_ERROR_CHECKING if the target is
#	a .eobj file. Otherwise it is empty.
#
-IFLAGS		+= -I$(.TARGET:R:T) -I$(INSTALL_DIR)/$(.TARGET:R:T) \
		  -I$(DEVEL_DIR)/Include -I$(INCLUDE_DIR) \
		  -I. -I$(INSTALL_DIR)

-CIFLAGS	+= -I$(.TARGET:R:T) -I$(INSTALL_DIR)/$(.TARGET:R:T) \
		  -I$(DEVEL_DIR)/CInclude -I$(CINCLUDE_DIR) -I$(CANSI_DIR)\
		  -I. -I$(INSTALL_DIR)

#
# Note we use :N-I?* instead of :N-I* because under NT :N is case-
# insensitive, and would thus nuke -i (used in the Kernel's local.mk).
#
ASSEMBLE	: .USE
	$(ASM) $(ASMFLAGS:N-I?*) \
	    $(.TARGET:X*\\[eobj\\]:S/eobj/-DDO_ERROR_CHECKING/) \
	    $(.TARGET:X*\\[gobj\\]:S/gobj/-DGCM/) \
	    $(.TARGET:X\\[*\\]/*:S|^|-I|) $(-IFLAGS) $(.ALLSRC:M*Manager.asm) \
	    -o $(.TARGET) 

#
# This is a general rule for linking things using glue. It uses the name of the
# target to decide what sort of output-specific flags to pass:
#
#	error-checking geode: 	give parameter file (which must be among the
#	    	    	    	sources), release, protocol and -E flag (so
#	    	    	    	permanent name can be modified appropriately)
#	non-ec geode: 	    	give parameter file, release and protocol
#	kernel:	    	    	give parameter file, release and protocol
#	vm file:    	    	give -Ov, release and protocol.
#	com file:   	    	give -Oc
#	font file:		give -Of
#	other .exe: 	    	give -Oe
#
# This rule is used by all the linking-related transformation rules, as
# anything built with such a rule acquires this thing as a source, thus
# acquiring the rules as well...
#
# If mucking with a grev file, we up the engineering release number only for
# the non-error-checking version of geodes or the kernel.
#

#
# 	If we are making a geode, define GPFILE
#
GPFILE		=

#if 	defined(GEODE)

# if 	(defined(GCM) || defined(GCM_ONLY)) && \
	(exists($(GEODE)gcm.gp) || exists($(INSTALL_DIR)/$(GEODE)gcm.gp))
GPFILE		= $(GEODE)gcm.gp
# else

#  if	(exists($(GEODE).gp) || exists($(INSTALL_DIR)/$(GEODE).gp))
GPFILE		= $(GEODE).gp
#  endif

# endif

#endif	defined(GEODE)


## XXX: I've removed the two lines below and inserted a mod'd one instead
## (the one starting "$(.TARGET:M*.VM")
## because this is the only way I could get Appl/Art/Decks/GeoDeck to build.
## I also haven't found any .VM files that need to be glued as geodes, so
## this change shouldn't break anything. -dhunter 2/14/2000
##
##  $(.TARGET:M$(GEODE).VM:S/$(.TARGET)/-Og $(.ALLSRC:M*.gp) -P $(_PROTO) -R $(_REL)/)\
##  $(.TARGET:M*.VM:N$(GEODE).VM:S/$(.TARGET)/-Ov -P $(_PROTO) -R $(_REL)/)\

# In order to eliminate glue crashing when no
# product directory is present, the following
# code was removed from after the LINK -z flag:
#           -F.\/$(PRODUCT)

SETLIBFLAG	?=
#if $(PRODUCT) != "NDO2000"
LINK		: .USE
#if defined(linux)
	rm -f $(.TARGET)
#else
	del -f $(.TARGET:S|/|\\|g)
#endif
	$(LINK) \
	  $(.TARGET:M*ec.geo:S/$(.TARGET)/-Og $(.ALLSRC:M*.gp) -P $(_PROTO) -R $(_REL) -E/)\
	  $(.TARGET:M*.geo:N*ec.geo:S/$(.TARGET)/-Og $(.ALLSRC:M*.gp) -P $(_PROTO) -R $(_REL) -z/)\
	  -F./$(PRODUCT) \
	  $(.TARGET:M*.vm:S/$(.TARGET)/-Ov -P $(_PROTO) -R $(_REL)/)\
	  $(.TARGET:M*.com:S/$(.TARGET)/-Oc/)\
	  $(.TARGET:M*.exe:S/$(.TARGET)/-Oe/)\
	  $(.TARGET:M*.fnt:S/$(.TARGET)/-Of/)\
	  $(.TARGET:M*.bin:S/$(.TARGET)/-Of/)\
	  $(SETLIBFLAG) \
	  $(LINKFLAGS) -o $(.TARGET) $(.ALLSRC:N*.gp:N*.ldf) $(OPTIONAL_LIB) $(GEOERRFL)
#else
LINK		: .USE
#if defined(linux)
	rm -f $(.TARGET)
#else
	del -f $(.TARGET:S|/|\\|g)
#endif
	$(LINK) \
	  $(.TARGET:M*EC.geo:S/$(.TARGET)/-Og $(.ALLSRC:M*.gp) -P $(_PROTO) -R $(_REL) -E/)\
	  $(.TARGET:M*.geo:N*EC.geo:S/$(.TARGET)/-Og $(.ALLSRC:M*.gp) -P $(_PROTO) -R $(_REL) -z/)\
	  $(.TARGET:M*.vm:S/$(.TARGET)/-Ov -P $(_PROTO) -R $(_REL)/)\
	  $(.TARGET:M*.com:S/$(.TARGET)/-Oc/)\
	  $(.TARGET:M*.exe:S/$(.TARGET)/-Oe/)\
	  $(.TARGET:M*.fnt:S/$(.TARGET)/-Of/)\
	  $(.TARGET:M*.bin:S/$(.TARGET)/-Of/)\
	  $(SETLIBFLAG) \
	  $(LINKFLAGS) -o $(.TARGET) $(.ALLSRC:N*.gp:N*.ldf) $(OPTIONAL_LIB) $(GEOERRFL)
#endif
## XXX: fix 4 NT
##if 0 && defined(PRODUCT_LDFS)
## if !empty(PRODUCT_LDFS)
##	for i in $(PRODUCT_LDFS)
##	do
##	    case "$(.TARGET)" in $i/*ec.geo|$i/*.geo) lf="-l";; esac
##	done
### endif
###endif
##	$(LINK) ${of} ${lf}
###if	defined(_GEODE) && $(GREVTREE) == "-I"
##	case "$(.TARGET)" in
##	    *ec.geo|*gcm.geo) : do nothing for error-checking/gcm versions ;;
##	    *.geo | $(KERNEL_BASE).exe) $(GREVCMD) -s neweng ;;
##	esac
###endif

##############################################################################
#
#			   TRANSFORMATIONS
#
##############################################################################

#
# Special rules to create a code-less application from a .ui file.
#
.rdef.rasm	: $(TEMPLATE_DIR)/template.asm $(TEMPLATE_DIR)/template.gp
	sed -e 's/FILENAME/$(.TARGET:R)/g' \
	    $(TEMPLATE_DIR)/template.asm  > $(.TARGET:R).rasm
	sed -e 's/FILENAME/$(.TARGET:R)/g' \
	    $(TEMPLATE_DIR)/template.gp > $(.TARGET:R).gp

.rasm.geo 	:
	$(ASM) $(ASMFLAGS) -o $(.TARGET:R).robj $(.IMPSRC)
	$(LINK) -Og $(.TARGET:R).gp $(LINKFLAGS) \
	    -o $(.TARGET) $(.TARGET:R).robj

.rasmec.geo 	:
	$(ASM) $(ASMFLAGS) -o $(.TARGET:R).reobj $(.IMPSRC)
	$(LINK) -Og $(.TARGET:R).gp -E $(LINKFLAGS) \
	    -o $(.TARGET) $(.TARGET:R).reobj

#
# Transformation rules to create the various pieces of an executable.
#
.asm.obj	:
	$(ASM) $(ASMFLAGS) -o $(.TARGET) $(.IMPSRC)

.asm.eobj	:
	$(ASM) -DDO_ERROR_CHECKING $(ASMFLAGS) -o $(.TARGET) $(.IMPSRC)

.asm.gobj	:
	$(ASM) -DGCM $(ASMFLAGS) -o $(.TARGET) $(.IMPSRC)

.eobjec.exe .eobjec.geo	.obj.exe .obj.geo .obj.vm .obj.fnt .obj.bin : LINK

.ui.rdef	:
	$(UIC) -p $(UICPP) $(UICFLAGS) -o $(.TARGET) $(.IMPSRC)

.ui.grdef	:
	$(UIC) -p $(UICPP) -DGCM $(UICFLAGS) -o $(.TARGET) $(.IMPSRC)


.obj.com	:
	$(LINK) -Oc $(LINKFLAGS) -o $(.TARGET) $(.IMPSRC)


.c.eobj		:
	$(CCOM) -DDO_ERROR_CHECKING $(CCOMFLAGS) -fo=$(.TARGET:S/\//\\/g) $(.IMPSRC:S/\//\\/g) $(GEOERRFL)

.c.obj		:
	$(CCOM) $(CCOMFLAGS) -fo=$(.TARGET:S/\//\\/g) $(.IMPSRC:S/\//\\/g) $(GEOERRFL)

.goc.obj	:
	$(GOC) $(GOCFLAGS) -o $(.TARGET:R).nc $(.IMPSRC) $(GEOERRFL)
	$(CCOM) $(CCOMFLAGS) -fo=$(.TARGET:S/\//\\/g) $(.TARGET:R:S/\//\\/g).nc $(GEOERRFL)
#if $(DEVEL_DIR:T) == "Installed"
#if defined(linux)
	rm $(.TARGET:R:S|/|\\|g).nc
#else
	del $(.TARGET:R:S|/|\\|g).nc
#endif
#endif

.goc.eobj	:
	$(GOC) -DDO_ERROR_CHECKING $(GOCFLAGS) -o $(.TARGET:R).ec $(.IMPSRC) $(GEOERRFL)
	$(CCOM) -DDO_ERROR_CHECKING $(CCOMFLAGS) -fo=$(.TARGET:S/\//\\/g) $(.TARGET:R:S/\//\\/g).ec $(GEOERRFL)
#if $(DEVEL_DIR:T) == "Installed"
#if defined(linux)
	rm $(.TARGET:R:S|/|\\|g).ec
#else
	del $(.TARGET:R:S|/|\\|g).ec
#endif
#endif

clean	: .NOTMAIN
	clean

#endif _GEOS_MK_
