##############################################################################
#
#       Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:      System Makefiles
# MODULE:       Generic PC/GEOS definitions
# FILE:         geos.mk
# AUTHOR:       Adam de Boor, Jul 23, 1989
#
# TARGETS:
#       Name                    Description
#       ----                    -----------
#       ASSEMBLE                Rule to assemble a module of a large-model
#                               geode
#       LINK                    Rule to link a set of object files (the
#                               sources) to form an executable file (the
#                               target)
# TRANSFORMATIONS:
#       .goc -> .c              Run a file through the GOC pre-processor
#       .ui -> .i               Run a file throught the C pre-processor
#       .i -> .rdf              Generate assembly language definitions from
#                               a Generic UI description file
#       .asm -> .obj            Create a non-error-checking object file
#       .asm -> .ebj            Create an error-checking object file
#       .ebj -> ec.exe          Link an error-checking object file into its
#                               error-checking .exe file
#       .obj -> .exe            Link a non-error-checking object file into
#                               its non-error-checking .exe file
#       .ebj -> ec.geo          Link an error-checking object file into its
#                               error-checking .geo file
#       .obj -> .geo            Link a non-error-checking object file into
#                               its non-error-checking .geo file
#       .obj -> .vm             Transform a .obj file into an PC/GEOS VM file
#       .obj -> .fnt            Transform a .obj file into a PC/GEOS font file
#       .obj -> .bin            Transform a .obj file into an binary file
#       .obj -> .com            Transform a .obj file into a DOS .com file.
#
# INPUT VARIABLES:
#       Name                    Description
#       ----                    -----------
#       LOBJS                   Object files for which no source exists
#       OBJS                    Module-objects for a large-model geode
# INTERNAL VARIABLES:
#       Name                    Description
#       ----                    -----------
# OUTPUT VARIABLES:
#       Name                    Description
#       ----                    -----------
#       SOURCE_PATHS            Paths to all modules of a large-model geode
#       EOBJS                   Transformation of $(OBJS) to use .ebj suffix
#       -IFLAGS                 -I flags passed to assembler when generating
#                               a module for a large-model geode
#       SUFFS                   Wildcard pairing of .ebj and .obj suffixes
#       CURRENT_DIR             Current working directory
#       ROOT_DIR                Root of PC/GEOS tree (usually passed in 
#                               environment)
#       APPL_DIR                Root of installed source for applications
#       DRIVER_DIR              Root of installed source for drivers
#       LIBRARY_DIR             Root of installed source for libraries
#       INCLUDE_DIR             Location of installed include files for Esp
#       CINCLUDE_DIR            Location of installed C include files
#       CANSI_DIR               Location of ansic H files
#       LOBJ_DIR                Location of library objects (.LDF files) for
#                               linking with clients of the library.
#       SUBDIR                  Piece of CURRENT_DIR below DEVEL_DIR
#       UIC                     Command for compiling .ui files
#       UICFLAGS                Flags to pass same
#       XUICFLAGS               Extra flags for same provided by user when
#                               pmake was invoked
#       ASM                     Assembler
#       ASMFLAGS                Flags for same
#       ASMWARNINGS             Default warning flags for same
#       XASMFLAGS               Extra flags for same (See XUICFLAGS)
#       LINK                    Object-file linker
#       LINKFLAGS               Flags for same
#       XLINKFLAGS              Extra flags for same (See XUICFLAGS)
#       BORLANDLIB              passes Glue a borland.obj file with the -l
#                               flag so that it only gets linked in if it
#                               is actually used
#
#       _REL                    Revision to pass to Esp and Glue
#       _PROTO                  Revision to pass to Esp and Glue
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       ardeb   7/23/89         Initial Revision
#
# DESCRIPTION:
#       This is a makefile to be included by all makefiles in the PC/GEOS
#       system. It provides the basic definitions of the various pieces
#       and transformation and .USE rules needed to create certain general
#       pieces.
#
#	$Id: geos.mk,v 1.1 97/04/04 15:56:40 newdeal Exp $
#
#
###############################################################################
#ifndef _GEOS_MK_
_GEOS_MK_       = 1

#
# First the suffixes we use...
#
.SUFFIXES       : EC.GEO GCM.GEO .GEO EC.EXE .EXE .COM .VM .FNT .LDF \
		  .EBJ .GBJ .OBJ .LBJ .ASM .DEF .RDF .GDF .UIH .UI .I \
		  .GP .TMP .BIN .C .GOC .GOH .H .LIB .EC .NC

# .INCLUDES for geodes moved to geode.mk to avoid screwing up UNIX tools

#
#       This variable makes life easier, in that it causes a target to expand
#       to its .obj and .ebj targets automatically. It is used as:
#          BOOT.$(SUFFS)
#       to expand to both BOOT.OBJ and BOOT.EBJ
#
SUFFS           = {EBJ,OBJ}

#
# Define LIBNAME to be empty now so it can be used in ASMFLAGS and GOCFLAGS
#
LIBNAME		?=

#
# Figure out where we are. Various other makefiles use this to determine
# which application/library/driver is being made. It's also useful to have
# anyway.
#
CURRENT_DIR     != `cd

#
# Define the pieces of the installed source tree. The including makefile can
# override these definitions, if it desires, but it probably shouldn't...
# Note that ROOT_DIR is usually defined in the environment for the PC-based
# SDK, but the definition here can be changed for site-wide development.
#
ROOT_DIR        ?= T:\PCGEOS
APPL_DIR        ?= $(ROOT_DIR)\APPL
DRIVER_DIR      ?= $(ROOT_DIR)\DRIVER
LIBRARY_DIR     ?= $(ROOT_DIR)\LIBRARY
INCLUDE_DIR     ?= $(ROOT_DIR)\INCLUDE
CINCLUDE_DIR    ?= $(ROOT_DIR)\INCLUDE 
CANSI_DIR       ?= $(ROOT_DIR)\INCLUDE\ANSI
LOBJ_DIR        ?= $(ROOT_DIR)\INCLUDE\LDF

#if defined(LOCAL_ROOT)
# when there is a local root we need to see if we are making stuff in the
# installed tree or the local tree to see where the LDF file goes
# I have to convert all the backslashes to forward slashes (or anything else)
# so that the :X operator can do its thing
RD       = $(ROOT_DIR:S|\\|/|g)
CD       = $(CURRENT_DIR:S|\\|/|g)
ISINROOT = $(CD:X*\\[$(RD)\\]*)

#if $(ISINROOT) == ""
LOCAL_LOBJ = $(LOCAL_ROOT)\INCLUDE\LDF
LOCAL_LOBJ_FLAG = -L$(LOCAL_LOBJ)
LOCAL_INCLUDE = $(LOCAL_ROOT)\INCLUDE
LOCAL_INCLUDE_FLAG = -I$(LOCAL_INCLUDE)
LOCAL_CINCLUDE = $(LOCAL_ROOT)\INCLUDE
LOCAL_CINCLUDE_FLAG = -I$(LOCAL_CINCLUDE)
INSTALLED_SOURCE = $(CURRENT_DIR:S|$(LOCAL_ROOT)|$(ROOT_DIR)|g)
INSTALLED_SOURCE_FLAG = -I$(INSTALLED_SOURCE)
#endif

#endif


# Figure out where the installed and development directories for the current
# thing are. DEVEL_DIR is simply the root directory followed by the
# first component of the current directory that follows the root (e.g.
# /staff/pcgeos/biff if CURRENT_DIR is /staff/pcgeos/biff/Appl/Calla).
# SUBDIR is set to everything in CURRENT_DIR but DEVEL_DIR (Appl/Calla
# in the above example). 
#
#if $(CURRENT_DIR:H) == "$(ROOT_DIR)"
DEVEL_DIR       := $(CURRENT_DIR)
SUBDIR          = . 

#else

# Not immediately below the root... DEVEL_DIR gets $(ROOT_DIR) plus the
# component that folows ROOT_DIR
DEVEL_DIR    := $(CURRENT_DIR:X\\[*\\\\$(ROOT_DIR:T)\\\\*\\]\\\\*)
SUBDIR       := $(CURRENT_DIR:X*$(DEVEL_DIR:S|\\|\\\\|g)\\\\\\[*\\])

#endif


T               := $(DEVEL_DIR:T)

#
#       Obtain revision control information. Results are left in
#       $(_REL) and $(_PROTO).
#
REVFILE :=      $(GEODE).REV
#if     !exists($(REVFILE))
REVFILE :=      $(INSTALLED_SOURCE)\$(GEODE).REV
#endif

#if     defined(GEODE) && exists($(REVFILE))

_GEODE  :=      $(GEODE)

GREV            ?= grev
GREVCMD         := $(GREV) 

_REL    !=      $(GREVCMD) neweng $(REVFILE) -R
# if    defined(NPM) || exists(NPM)
_PROTO  !=      $(GREVCMD) newprotomajor $(REVFILE) -P
# elif  defined(npm) || exists(npm)
_PROTO  !=      $(GREVCMD) newprotominor $(REVFILE) -P
# else
_PROTO  !=      $(GREVCMD) getproto $(REVFILE) -P
# endif

#else

_REL    =       0.0.0.0
_PROTO  =       0.0

#endif
##############################################################################
#
#                    PROGRAM AND FLAG DEFINITIONS
#
##############################################################################

#
#                                GOC
#
GOC             ?= goc
XGOCFLAGS       ?= 
GOCFLAGS        += -D__GEOS__ $(-CIFLAGS) -I- $(-CIFLAGS) \
		   $(XGOCFLAGS) -w -l $(LIBNAME:S/^/-L /)
#
#                                CPP
#
CPP             ?= cpp
XCPPFLAGS       ?= 
CPPFLAGS        += -I. $(INSTALLED_SOURCE_FLAG) $(LOCAL_INCLUDE_FLAG) -I$(INCLUDE_DIR) -P- -i200 $(XCPPFLAGS)

#
#                                UIC
#
UIC             ?= uic
XUICFLAGS       ?= 
UICFLAGS        += $(XUICFLAGS) -l

#
#                             ASSEMBLER
#
# XASMFLAGS is intended to be filled on the command-line
#
ASM             ?= esp

ASMFLAGS        += -L 4

ASMWARNINGS     ?= -Wall
ASMFLAGS        += $(.INCLUDES) $(ASMWARNINGS) $(XASMFLAGS) \
		   -DREL=$(_REL) -DPROTO=$(_PROTO) \
                   $(.TARGET:X*.\\[obj\\]:S/obj/-l $(.TARGET:R).rsc/) \
                   $(LIBNAME:S/^/-n /)
XASMFLAGS       ?=

#
#                               LINKER
#
# Same for XLINKFLAGS
#
LINK            ?= glue
LINKFLAGS       += -m $(LOCAL_LOBJ_FLAG) -L$(LOBJ_DIR) $(XLINKFLAGS)
XLINKFLAGS      ?=

OPTIONAL_LIB    = 
#
#                             C COMPILER
#
#include        <compiler.mk>

XCCOMFLAGS      ?=

##############################################################################
#
#                       SEARCH PATH DEFINITION
#
##############################################################################
#if     defined(LOBJS)
OBJS            += $(LOBJS)
#endif

#ifdef  MODULES

#                           LARGE-MODEL GEODE
#
#       Define object files used to make the geode based on the MODULES
#       variable.
#

# if    defined(OBJS)
OBJS            := $(MODULES:S/$/.OBJ/g) $(OBJS)
# else
OBJS            := $(MODULES:S/$/.OBJ/g)
# endif

CMODULES        ?=


#
#       Define search paths to be all modules.
#       The .def files are also searched for in the directory of the geode.
#       Library search paths are dealt with in gpath.mk.
#
SOURCE_PATHS    = $(MODULES)
CSOURCE_PATHS   = $(CMODULES)
INSTALLED_SOURCE_PATHS = $(MODULES:S|^|$(INSTALLED_SOURCE)\\|g) $(INSTALLED_SOURCE)
INSTALLED_CSOURCE_PATHS = $(CMODULES:S|^|$(INSTALLED_SOURCE)\\|g) $(INSTALLED_SOURCE)
#if defined(LOCAL_ROOT) && $(ISINROOT) == ""
SOURCE_PATHS += $(INSTALLED_SOURCE_PATHS)
CSOURCE_PATHS += $(INSTALLED_CSOURCE_PATHS)
#endif
 
.PATH.DEF       : $(SOURCE_PATHS) $(LOCAL_INCLUDE) $(INCLUDE_DIR)
.PATH.UIH       : $(SOURCE_PATHS) $(LOCAL_INCLUDE) $(INCLUDE_DIR)
.PATH.LBJ       : $(SOURCE_PATHS) 
.PATH.GOH       : $(CSOURCE_PATHS) $(LOCAL_CINCLUDE) $(CINCLUDE_DIR)
.PATH.H         : $(CSOURCE_PATHS) $(LOCAL_CINCLUDE) $(CINCLUDE_DIR) $(CANSI_DIR)
.PATH.ASM       : $(SOURCE_PATHS)
.PATH.C         : $(CSOURCE_PATHS)
.PATH.GOC       : $(CSOURCE_PATHS)
.PATH.UI        : $(SOURCE_PATHS)
#else
#
#                       SMALL/MEDIUM MODEL GEODE
#
# Search for source files only in the current directory and an installed one
# when there is one
# 
.PATH.LBJ       : . $(INSTALLED_SOURCE)
.PATH.ASM       : . $(INSTALLED_SOURCE)
.PATH.C         : . $(INSTALLED_SOURCE)
.PATH.GOC       : . $(INSTALLED_SOURCE)
.PATH.UI        : . $(INSTALLED_SOURCE)
.PATH.DEF       : . $(INSTALLED_SOURCE)
#endif MODULES

#                       COMMON GEODE THINGS
#
#       NOTE that '.' is not always checked first and is necessary in the
#       search paths.
#
#       NOTE: DO NOT DEFINE A PATH FOR .h FILES HERE. It hoses things
#       in Tools. The path for .h files for geodes is defined in geode.mk
#
.PATH.GP        : $(CURRENT_DIR) $(INSTALLED_SOURCE) 
.PATH.LDF       : $(LOCAL_LOBJ) $(LOBJ_DIR)
.PATH.DEF       : . $(LOCAL_INCLUDE) $(INCLUDE_DIR) $(INSTALLED_SOURCE)
.PATH.GOH       : . $(LOCAL_CINCLUDE) $(CINCLUDE_DIR) $(INSTALLED_SOURCE)
.PATH.UIH       : . $(LOCAL_INCLUDE) $(INCLUDE_DIR) $(INSTALLED_SOURCE)

#
# Define variables to hold the error-checking and gcm versions of the same
# object files that make up the non-error-checking version.
#
#if     defined(OBJS)
EOBJS           := $(OBJS:S,.OBJ$,.EBJ,g)
GOBJS           := $(OBJS:S,.OBJ$,.GBJ,g)
#endif

#
#       Standard method for assembling a module. The root (i.e. non-extension
#       part) of the target file defines which module is being assembled. 
#       ASM is made to look for included files in the directory for the 
#       module and in the top-level directory for the geode.
#
#       If the target ends in .EBJ, the rule passes -DDO_ERROR_CHECKING to the
#       assembler. If the target ends in .GBJ, the rule passes -DGCM to the 
#       assembler. These allow conditional assembly for the different object
#       files.
#
INSTALLED_TARGETR = -I$(INSTALLED_SOURCE)\$(.TARGET:R)
CSOURCE_PATHS_FLAG = $(CSOURCE_PATHS:S|^|-I|g) 

-IFLAGS         += -I$(.TARGET:R) $(INSTALLED_TARGETR) -I. $(INSTALLED_SOURCE_FLAG) $(LOCAL_CINCLUDE_FLAG) -I$(INCLUDE_DIR)

-CIFLAGS        += -I$(.TARGET:R) $(INSTALLED_TARGETR) -I. $(CSOURCE_PATHS_FLAG) $(LOCAL_CINCLUDE_FLAG) $(INSTALLED_SOURCE_FLAG) -I$(CINCLUDE_DIR) -I$(CANSI_DIR) 

ASSEMBLE        : .USE
	$(ASM) $(ASMFLAGS:N-I*)\
		$(.TARGET:M*.EBJ:S|$(.TARGET)|-DDO_ERROR_CHECKING|)\
		$(.TARGET:M*.GBJ:S|$(.TARGET)|-DGCM|)\
		$(-IFLAGS) $(.ALLSRC:M*MANAGER.ASM) -o $(.TARGET)

#
# This is a general rule for linking things using glue. It uses the name of 
# the target to decide what sort of output-specific flags to pass:
#
#       error-checking geode:   give parameter file (which must be among the
#                               sources), release, protocol and -E flag (so
#                               permanent name can be modified appropriately)
#       non-ec geode:           give parameter file, release and protocol
#       kernel:                 give parameter file, release and protocol
#       vm file:                give -Ov, release and protocol.
#       com file:               give -Oc
#       font file:              give -Of
#       other .exe:             give -Oe
#
# This rule is used by all the linking-related transformation rules, as
# anything built with such a rule acquires this thing as a source, thus
# acquiring the rules as well...
#
# The various $(.TARGET:M*.ext:S/$(.TARGET)/mumble/) things serve to pass the
# above sets of flags based on the extension of the target. Since .TARGET is
# always just a single word, the :M yields either the value of the .TARGET
# variable, if the target of the rule has the given extension, or nothing. If
# it yields nothing, the substitution does nothing. If it yields $(.TARGET),
# the entire result is replaced by the appropriate set of flags.
#

GPFILE = $(.ALLSRC:M*.GP)
#if !empty(GPFILE)
#if !exists(GPFILE) && exists($(INSTALLED_SOURCE)\$(.ALLSRC:M*.GP))
GPFILE = $(INSTALLED_SOURCE)\$(.ALLSRC:M*.GP)
#endif
#endif

LINK            : .USE  
	$(LINK) \
	  $(.TARGET:M*EC.GEO:S/$(.TARGET)/-Og $(GPFILE) -P $(_PROTO) -R $(_REL) -E -z/)\
	  $(.TARGET:M*.GEO:N*EC.GEO:S/$(.TARGET)/-Og $(GPFILE) -P $(_PROTO) -R $(_REL) -z/)\
	  $(.TARGET:M$(GEODE).VM:S/$(.TARGET)/-Og $(GPFILE) -P $(_PROTO) -R $(_REL) -z/)\
	  $(.TARGET:M*.VM:N$(GEODE).VM:S/$(.TARGET)/-Ov -P $(_PROTO) -R $(_REL)/)\
	  $(.TARGET:M*.COM:S/$(.TARGET)/-Oc/)\
	  $(.TARGET:M*.EXE:S/$(.TARGET)/-Oe/)\
	  $(.TARGET:M*.FNT:S/$(.TARGET)/-Of/)\
	  $(.TARGET:M*.BIN:S/$(.TARGET)/-Of/)\
	  $(LIBFLAG)\
	  $(LINKFLAGS) -o $(.TARGET) $(.ALLSRC:N*.GP:N*.LDF)\
	  $(OPTIONAL_LIB)

	  


##############################################################################
#
#                          TRANSFORMATIONS
#
##############################################################################


#
# Transformation rules to create the various pieces of an executable.
#
.ASM.OBJ        :
	$(ASM) $(ASMFLAGS) -o $(.TARGET) $(.IMPSRC)

.ASM.EBJ        : 
	$(ASM) -DDO_ERROR_CHECKING $(ASMFLAGS) -o $(.TARGET) $(.IMPSRC)

.ASM.GBJ        : 
	$(ASM) -DGCM $(ASMFLAGS) -o $(.TARGET) $(.IMPSRC)

.EBJEC.EXE .EBJEC.GEO   .OBJ.EXE .OBJ.GEO .OBJ.VM .OBJ.FNT .OBJ.BIN : LINK


.OBJ.COM        : 
	$(LINK) -Oc $(LINKFLAGS) -o $(.TARGET) $(.IMPSRC)

.GOC.NC         :
	$(GOC) $(GOCFLAGS) -o $(.TARGET:R).NC $(.IMPSRC)

.GOC.EC         :
	$(GOC) -DDO_ERROR_CHECKING $(GOCFLAGS) -o $(.TARGET:R).EC $(.IMPSRC)

.UI.I           :
	$(CPP) $(CPPFLAGS) $(UICFLAGS:M-D*) -o$(.TARGET:R).I $(.IMPSRC)

.I.RDF          :
	$(UIC) $(UICFLAGS) -o $(.TARGET) $(.IMPSRC)
#endif _GEOS_MK_
