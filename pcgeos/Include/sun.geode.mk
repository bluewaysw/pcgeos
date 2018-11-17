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
#	$Id: geode.mk,v 1.1 97/04/04 14:21:55 newdeal Exp $
#
###############################################################################

#
# Set up path for .h files now we know we're creating a geode, not a UNIX tool
#
.PATH.h         : . $(DEVEL_DIR)/CInclude $(CINCLUDE_DIR) $(INSTALL_DIR) \
                  /staff/pcgeos/Tools/highc/inc
#
# Mark the important things as files being included so their paths make it
# into .INCLUDES
#
.INCLUDES	: .def .rdef .uih .goh

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
UICFLAGS	:= $(UICFLAGS:N-I*) $(UICFLAGS:M-I*) -I- $(UICFLAGS:M-I*)

GSUFF		?= geo


#
# Tell the linker the type of geode it's creating so Swat knows where to look
#
#if $(GSUFF) == "geo"
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
#  ifndef NO_EC
.MAIN		: $(GEODE)ec.$(GSUFF)
part		:: $(GEODE)ec.$(GSUFF)
full		:: $(GEODE)ec.$(GSUFF)
#  else
.MAIN		: $(GEODE).$(GSUFF)
part		:: $(GEODE).$(GSUFF)
#  endif NO_EC
full		:: $(GEODE).$(GSUFF)
# endif GCM_ONLY

# if defined(GCM) || defined(GCM_ONLY)
#  if defined(GCM_ONLY)
.MAIN		: $(GEODE)gcm.$(GSUFF)
#  endif
full		:: $(GEODE)gcm.$(GSUFF)
# endif GCM

#
# Make full depend on the ec and non-ec geodes for all the products, too
#
# if defined(PRODUCTS)
_COMMAPRODS	!= echo $(PRODUCTS) | tr ' ' ',' | (read foo; echo {$${foo}})
full		:: $(PRODUCTS:S|$|/$(GEODE).$(GSUFF)|g)
#  ifndef NO_EC 
full		:: $(PRODUCTS:S|$|/$(GEODE)ec.$(GSUFF)|g)
#  endif
# endif

#
# List of products with product-specific .ldf files
#
# if defined(PRODUCT_LDFS)
_COMMALDFS	!= echo $(PRODUCT_LDFS) | tr ' ' ',' | (read foo; echo {$${foo}})
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

# if ($(GSUFF) == "geo")
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
SETLIBFLAG	= case "$(.TARGET)" in */*) : ;; *ec.geo|*ec.exe) lf="-l";; esac
#  else
SETLIBFLAG	= lf=-l
#  endif

# test me -- ardeb 5/21/91
$(LIBOBJ)       : $(LIBOBJ:T) .NOEXPORT .IGNORE
	cmp -s $(LIBOBJ:T) $(.TARGET) || cp $(LIBOBJ:T) $(.TARGET)
#  ifdef PRODUCT_LDFS
$(LIBOBJ:H)/$(_COMMALDFS)/$(LIBOBJ:T)	: $(.TARGET:H:T)/$(LIBOBJ:T) .NOEXPORT .IGNORE
	cmp -s $(.TARGET:H:T)/$(LIBOBJ:T) $(.TARGET) || cp $(.TARGET:H:T)/$(LIBOBJ:T) $(.TARGET)
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

# if !defined(NO_LOC) && $(GSUFF) == "geo"
$(GEODE).vm	: $(GEODE).$(GSUFF)
	$(LOC) $(LOCFLAGS) -o $(.TARGET) *.rsc

#   ifdef PRODUCTS
$(_COMMAPRODS)/$(GEODE).vm : $(.TARGET:R).$(GSUFF)
	$(LOC) $(LOCFLAGS) -o $(.TARGET) $(.TARGET:H)/*.rsc
$(PRODUCTS:S/$/_full/g) :: $(.TARGET:S/_full//)/$(GEODE).vm

#   endif

full		:: $(GEODE).vm

#   ifdef PRODUCTS
full		:: $(PRODUCTS:S|$|/$(GEODE).vm|g)
#   endif

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

full		:: tags

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
depend		: $(DEPFILE)

#-----------------------------------------------------------------------------#

$(DEPFILE)	: $(SRCS)					.SILENT
#
# Clean up on interrupt or exit
#
	trap "rm -f /tmp/depend.$$$$ /tmp/dependlines.$$$$ /tmp/idir$$$$; exit 0" 0 1 2 3 15
#
# Back up the current file using cp so anything the user placed at the end of
# the tag line is maintained...
#
	rm -f $(.TARGET).bak
	-mv -f $(.TARGET) $(.TARGET).bak
#
# Make sure the file has the tag line (so ed won't die)
#
	echo '$(TAGLINE)' >> $(.TARGET)
#if	defined(SHOWDEP)
#
# Set -x causes commands to be printed as executed, to give the user a better
# idea of what's going on
#
	set -x
#endif
	: > /tmp/dependlines$$$$
##############################################################################
#
#			   PROCESS UI FILES
#
##############################################################################
#if	!empty(SRCS:M*.ui)
#
# Generate dependencies for all .ui files to cause proper regeneration of .rdef
# files...
#
# Form sed script to remove unwanted include paths (those pmake can find by
# itself)
#
	sedfile=/tmp/idir$$$$
	:> $sedfile
	for i in $(UICFLAGS:M-I*:N-I.); do
	    echo "s|"'"'`expr x"$i" : x'-I\(.*\)$$'`"/||" >> $sedfile
	done
#
# Run all source files through the preprocessor, using only
# # line "file" lines, placing the name of the file from which
# the line came at the front of each one. Then massage the resulting
# lines to remove extra . and .. path components, the quotation marks
# around the file names and leading paths that pmake can find.
# Run the result through an awk script to (1) make the sources
# for each object file unique and (2) format the results nicely.
# $ip is the file in question with all /'s quoted properly. I need
# to use 4 backslashes so sed gets two of them so the \ in the replacement
# is taken as literal, rather than an unnecessary quoting of /.
#
	for i in $(.ALLSRC:M*.ui); do
	    ip="`echo $i | sed -e 's,/,\\\\/,g'`"
# if !defined(GCM_ONLY)
#  if	!defined(SHOWDEP)
	    echo Processing $i... >&2
#  endif
	    of=`basename $i .ui`.rdef
	    $(UICPP) $(UICFLAGS:M-[DI]*) $i | \
		sed -n -e "/^#[	    ]*ident/d" \
		       -e "/^#.*"'"'"$ip"'"'"/d" \
		       -e "/^#/s;^;$of ;p"
# endif
# if	defined(GCM) || defined(GCM_ONLY)
#  if	!defined(SHOWDEP)
	    echo Processing $i with GCM... >&2
#  endif
	    of=`basename $i .ui`.grdef
	    $(UICPP) -DGCM $(UICFLAGS:M-[DI]*) $i | \
		sed -n -e "/^#[	    ]*ident/d" \
		       -e "/^#.*"'"'"$ip"'"'"/d" \
		       -e "/^#/s;^;$of ;p"
# endif
	done | sed -f $sedfile \
	    -e 's,/[^/.][^/]*/\.\./,/,g' -e 's,/\.[^.][^/]*/\.\./,/,g' \
	    -e 's,",,g' -e 's, \./, ,' | \
	    nawk '
		$3 ~ /[0-9]+/ { print }
		$3 !~ /[a-zA-Z]+/ { print } ' | \
	    nawk '	
		$4 !~ /\/usr\/include/ {
		    if (srcs[$1 ":::" $4] == 0) {
			numfiles += 1
			srcs[$1 ":::" $4] = 1
			files[$1] = files[$1] " " $4
		    }
		}
		END {
		    if (numfiles != 0) {
#if	defined(PRODUCTS)
			split("$(PRODUCTS)", prods)
#endif
			for (obj in files) {
			    ns = split(files[obj], srcs, " ")
#if	defined(PRODUCTS)
			    for (p in prods) {
				printf "%s/%s \\\n", prods[p], obj
			    }
#endif
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
		}' >>	/tmp/dependlines.$$$$
#endif	!empty(SRCS:M*.ui)

##############################################################################
#
#			   PROCESS GOC FILES
#
##############################################################################
#if	!empty(SRCS:M*.goc)
#
#	run the goc files through GOC creating _e.c files
#	then, the dependency info will be gleaned from these files
#	under the PROCESS C FILES section

	allc="$(.ALLSRC:M*.goc:S,^./,,g)"
	for i in $allc; do
# if	!defined(SHOWDEP)
	    echo Processing $i... >&2
# endif
#
# get the name of the file up to the .goc and replace it with _e.c
# and the -o flag to GOC to tell it what file to output to

	    j=`expr $i : "\(.*\)\.goc"`
	    $(GOC) -o ${j}_e.c $(GOCFLAGS) $i
	done 

#endif	!empty(SRCS:M*.goc)

##############################################################################
#
#			   PROCESS C FILES
#
##############################################################################
#if	!empty(SRCS:M*.c) || !empty(SRCS:M*.goc)
#
# Form sed script to remove unwanted include paths (those pmake
# can find by itself)
#
	trap 'rm -f /tmp/idirs$$$$;
#if	!defined(SAVE_GENERATED_CFILES)
	    tallc="$(.ALLSRC:M*.goc:S,^./,,g:S,.goc,_e.c,g)";
	    for ti in $tallc; do
		echo Deleting $ti
		rm $ti;
	    done;
#endif
	exit 0' 0 1 2 3 15
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
	allc="$(.ALLSRC:M*.c:S,^./,,g) $(.ALLSRC:M*.goc:S,^./,,g:S,.goc,_e.c,g)"
	for i in $allc; do
	
# if	!defined(SHOWDEP)
	    echo Processing $i... >&2
# endif
	    ip="`echo $i | sed -e 's,/,\\\\/,g'`"
#
# Don't use the stupid C-compiler since it ignores all non "*.c" files
#
	    $(UICPP) $(CCOMFLAGS:M-[DI]*) $(CCOMFLAGS:M-m*) $i | \
		sed -n -e "/^#[	    ]*ident/d" \
		       -e "/^#[	    ]*pragma/d" \
		       -e "/^#.*"'"'"$ip"'"'"/d" \
		       -e "/^#/s;^;$i ;p"
	done | sed -f $sedfile \
	    -e 's,/[^/.][^/]*/\.\./,/,g' -e 's,/\.[^.][^/]*/\.\./,/,g' \
	    -e 's,",,g' -e 's, \./, ,g' | \
	    nawk '
		$4 ~ /\/usr\/include/ 
		    {
		    n = split($1, comps, "/")
		    ofile = substr (comps[n], 1, length (comps[n])-2) ".obj"
		    if (srcs[ofile ":::" $4] == 0) {
			numfiles += 1
			srcs[ofile ":::" $4] = 1
			files[ofile] = files[ofile] " " $4
		    }
		}
		END {
		    if (numfiles != 0) {
#if	defined(PRODUCTS)
			split("$(PRODUCTS)", prods)
#endif
			for (obj in files) {
# we need to watch out for the _e.c files,
# for _e.c files we want to get rid of the _e in the dependencies file 
			    ind = index(obj, "_e.obj");
			    if (ind == 0)
			    {
				ind = index(obj, ".obj");
			    }
				
			    base = substr(obj,0,ind - 1)
#if	defined(PRODUCTS)
			    for (p in prods) {
				printf "%s/%s.obj \\\n", prods[p], base
# if	!defined(NO_EC)		    
				printf "%s/%s.eobj \\\n", prods[p], base
# endif
			    }
#endif
#if	!defined(NO_EC)
			    printf "%s.eobj \\\n", base
#endif
			    realobj = sprintf("%s.obj", base);
			    ns = split(files[obj], srcs, " ")
			    line = sprintf("%-16s:", realobj )
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
		}' >> /tmp/dependlines.$$$$

#endif	!empty(SRCS:M*.c) || !empty(SRCS:M*.goc)


##############################################################################
#
#			   PROCESS ASM FILES
#
##############################################################################
#if	!empty(SRCS:N*.ui:N*.[ch]:N*.go[ch]) && !defined(GCM_ONLY)
#
# Run all the modules through esp and place the results in a temp file.
#
	{
# if	defined(MODULES)
#
# Figure names of all known managers from SRCS variable for use in locating
# manager for a specific module, below.
#
	    mgrs="$(SRCS:M*Manager.asm)"
	    for i in $(MODULES); do
#  if	!defined(SHOWDEP)
		echo Processing $i... >&2
#  endif
		bi=`basename $i`
		mgr=`echo $bi | tr A-Z a-z`Manager.asm
		mgr=`echo $mgrs | tr ' ' '\012' | egrep '^c?'$mgr`
		$(ASM) -M -o $bi.obj -DDO_ERROR_CHECKING $(ASMFLAGS:N-[IWw]*) \
		    -I$i -I$(INSTALL_DIR)/$bi \
		    $(-IFLAGS:N*dependencies*) $(DEPFLAGS) $mgr
	    done
# else
#
# Transform the object files into assembly files for locating dependencies,
# as there could be many assembly files in the .ALLSRC list that get
# included. Note we don't care where the .asm files actually lie, as ASAP
# will locate the proper one due to the -I flags we give it. Need to make
# sure the .obj file isn't for a .c file, however, and we don't want to
# use "if" as that'll cause us to abort early...
#
	    for i in $(OBJS:S|.obj$|.asm|g:N*.lobj); do
		cfile=`basename $i .asm`.c
		expr " $(SRCS:M*.c) " : ".* $cfile " > /dev/null ||
		{
		    gocfile=`basename $i .asm`.goc
		    expr " $(SRCS:M*.goc) " : ".* $gocfile " > /dev/null ||
		    {
#  if	!defined(SHOWDEP)
			echo Processing $i... >&2
#  endif
			$(ASM) -M -DDO_ERROR_CHECKING $(ASMFLAGS:N-[Ww]*) \
			    $(DEPFLAGS) $i
		    }
		}
	    done
# endif
	} | sort -u | \
	    nawk 'NF == 3 {
		numfiles += 1
		files[$1] = files[$1] " " $3
	    }
	    END {
		if (numfiles != 0) {
#if	defined(PRODUCTS)
		    split("$(PRODUCTS)", prods)
#endif
		    for (obj in files) {
			ns = split(files[obj], srcs, " ")
			base=substr(obj,0,index(obj,".obj"))
#if	defined(PRODUCTS)
			for (p in prods) {
			    printf "%s/%sobj \\\n", prods[p], base
# if	!defined(NO_EC)		    
			    printf "%s/%seobj \\\n", prods[p], base
# endif
			}
#endif
# if	!defined(NO_EC)
			printf "%seobj \\\n", base
# endif
			line=sprintf("%-16s:", obj)
			hasrdef=0
			for (j=1; j <= ns; j++) {
			    if (srcs[j] !~ /\.rdef$/) {
				if (length(line) + length(srcs[j]) + 1 > 75) {
				    printf "%s\\\n", line, ""
				    line=sprintf("%17s", "")
				}
				line = line " " srcs[j]
			    } else {
				hasrdef=1
			    }
			}
			print line
			if (hasrdef) {
# if defined(PRODUCTS)
			    for (p in prods) {
#  if !defined(NO_EC)
				printf "%s/%seobj \\\n", prods[p], base
#  endif
				line=sprintf("%s/%sobj: ", prods[p], base)
				for (j=1; j <= ns; j++) {
				    if (srcs[j] ~ /\.rdef$/) {
	    	    	    	    	s=prods[p] "/" srcs[j]
					if (length(line) + length(s) + 1 > 75) {
					    printf "%s\\\n", line, ""
					    line=sprintf("%17s", "")
					}
					line = line " " s
				    }
				}
				print line
			    }
# endif
# if !defined(NO_EC)
			    printf "%seobj \\\n", base
# endif
			    line=sprintf("%sobj: ", base)
			    for (j=1; j <= ns; j++) {
				if (srcs[j] ~ /\.rdef$/) {
				    if (length(line) + length(srcs[j]) + 1 > 75) {
					printf "%s\\\n", line, ""
					line=sprintf("%17s", "")
				    }
				    line = line " " srcs[j]
				}
			    }
			    print line
	    	    	}
		    }
		}
	    }' >> /tmp/dependlines.$$$$
#endif
##############################################################################
#
#			   PROCESS GCM ASM FILES
#
##############################################################################
#if	!empty(SRCS:N*.ui:N*.[ch]:N*.go[ch]) && (defined(GCM) || defined(GCM_ONLY))
#
# Run all the modules through esp and place the results in a temp file.
#
	{
# if	defined(MODULES)
#
# Figure names of all known managers from SRCS variable for use in locating
# manager for a specific module, below.
#
	    mgrs="$(SRCS:M*Manager.asm)"
	    for i in $(MODULES); do
#  if	!defined(SHOWDEP)
		echo Processing $i with GCM... >&2
#  endif
		bi=`basename $i`
		mgr=`echo $bi | tr A-Z a-z`Manager.asm
		mgr=`echo $mgrs | tr ' ' '\012' | egrep '^c?'$mgr`
		$(ASM) -M -o $bi.obj -DGCM $(ASMFLAGS:N-[IWw]*) \
		    -I$i -I$(INSTALL_DIR)/$bi \
		    $(-IFLAGS:N*dependencies*) $mgr
	    done
# else
#
# Transform the object files into assembly files for locating dependencies,
# as there could be many assembly files in the .ALLSRC list that get
# included. Note we don't care where the .asm files actually lie, as ASAP
# will locate the proper one due to the -I flags we give it.
#
	    for i in $(OBJS:S|.obj$|.asm|g:N*.lobj); do
#  if	!defined(SHOWDEP)
		echo Processing $i with GCM... >&2
#  endif
		$(ASM) -M -DGCM $(ASMFLAGS:N-[Ww]*) $(DEPFLAGS) $i
	    done
# endif
	} | \
	    nawk 'NF == 3 {
		numfiles += 1
		files[$1] = files[$1] " " $3
	    }
	    END {
		if (numfiles != 0) {
		    for (obj in files) {
			ns = split(files[obj], srcs, " ")
			base=substr(obj,0,index(obj,".obj"))
			line=sprintf("%-16s:", base "gobj")
			for (j=1; j <= ns; j++) {
			    if (length(line) + length(srcs[j]) + 1 > 75) {
				printf "%s\\\n", line, ""
				line=sprintf("%17s", "")
			    }
			    line = line " " srcs[j]
			}
			print line
		    }
		}
	    }' >> /tmp/dependlines.$$$$
#endif
##############################################################################
#
#		      LOCATE IMPORTED LIBRARIES
#
##############################################################################
#
# Invoke another instance of the shell to avoid stupidity in BSD shells where
# the non-zero exit of a command used in a conditional causes the exit of the
# shell when invoked with -e. If there's no .gp file around, the shell will
# produce no output, giving sed nothing on which to perform its substitution.
# Else, it will preface the line of output produced by the egrep/awk pair
# with the names of the geodes and a : to indicate dependence...
#
#if defined(GEODE)
	(
# if defined(PRODUCTS)
	    echo PRODUCTS $(PRODUCTS)
# endif
	    if [ -f $(GEODE).gp ]; then
		egrep -e '^[    ]*(driver|library|ifdef|ifndef|endif|else)' $(GEODE).gp 
	    elif [ -f $(INSTALL_DIR)/$(GEODE).gp ]; then
		egrep -e '^[    ]*(driver|library|ifdef|ifndef|endif|else)' $(INSTALL_DIR)/$(GEODE).gp 
	    fi
	) | \
	    (
	    	prod=
	    	set +e
	    	set - ""
		while read cmd obj junk; do
		    case "$cmd" in
			PRODUCTS)   set - "" $obj $junk;;
			ifdef)
				prod=`expr $obj : 'PRODUCT_\(.*\)$'`
				negate=
				;;
			ifndef)
				prod=`expr $obj : 'PRODUCT_\(.*\)$'`
				negate=yes
				;;
			"else")
				if [ "$negate" ]; then
				    negate=
				else
				    negate=yes
				fi
				;;
			endif)
				prod=
				;;
			driver | library )
				if [ "$prod" ]; then
				    for i do
#
# There are times when a "product" is actually a variant of a real
# product. For example, "HELLODEMO" is a variant of product "HELLO". So, we
# use 'product_flags' to find out the real product of "HELLODEMO" (in this
# case, "PRODUCT_HELLO") before comparing with $prod.
#
					for j in `product_flags glue $i`; do
					    prodFlag=`expr $j : '-DPRODUCT_\(.*\)'`
					    if [ "$prodFlag" ]; then
						break
					    fi
					done
					if [ "$negate" ]; then
					    case "$prod" in
						$i | $prodFlag)
						    ;;
						*)
						    eval deps_$i=\"\$deps_$i $obj.ldf\"
						    ;;
					    esac
					else
					    case "$prod" in
						$i | $prodFlag)
						    eval deps_$i=\"\$deps_$i $obj.ldf\"
						    ;;
						*)
						    ;;
					    esac
					fi
				    done
				else
				    for i do
					eval deps_$i=\"\$deps_$i $obj.ldf\"
				    done
				fi
				;;
		    esac
	    	done
		for i do
		    if [ "$i" ]; then
# if !defined(NO_EC)
			echo -n "$i/$(GEODE)ec.$(GSUFF) "
# endif
			echo -n "$i/$(GEODE).$(GSUFF): "
		    else
# if !defined(NO_EC)
			echo -n "$(GEODE)ec.$(GSUFF) "
# endif
			echo -n "$(GEODE).$(GSUFF): "
		    fi
		    eval echo \$deps_$i
		done
	    ) >> /tmp/dependlines.$$$$
#endif
##############################################################################
#
#		       CREATE DEPENDENCIES FILE
#
##############################################################################
# Use ed to save the current tag line, nuke the lines to the end of the
# file, then fetch the tag and the dependencies back in again.
	ed - $(.TARGET) << END_OF_ED_SCRIPT
	/^$(TAGLINE)/w /tmp/depend.$$$$
	/^$(TAGLINE)/,\$d
	\$r /tmp/depend.$$$$
	\$r /tmp/dependlines.$$$$
	w
	q
	END_OF_ED_SCRIPT

#
# Help out Makefile.top -- make "all" be an alias for "full"
#
all	: full

XGBFLAGS	?=

getbranch	::
	mkdir -p $(INSTALL_DIR)
	cd $(INSTALL_DIR)
	getbranch $(XGBFLAGS) -q
