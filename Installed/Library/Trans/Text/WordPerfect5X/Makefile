##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	WordPerfect5X -- Makefile
# FILE: 	Makefile
# AUTHOR: 	, Mon Apr  7 22:10:57 PDT 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	wordperfect5xec.geo		create an error-checking version
#	wordperfect5x.geo		create a non error-checking version
#	full			create both of the above, plus tags
#	part			create only the error-checking version
#	tags			create a tags file from all the sources
#	depend			generate source file dependencies
#
# DESCRIPTION:
#	This makefile was automatically generated from:
#	    /staff/pcgeos/Tools/mkmf/Makefile.geode
#
#	DO NOT EDIT IT, AS YOU MAY LOSE YOUR CHANGES WHEN IT IS REGENERATED
#
#	$Id: Makefile.geode,v 1.4 92/01/03 20:17:45 johnm Exp $
#
###############################################################################

GEODE           = wordperfect5x

COMMONC         = wp5tran.c
EXPORT          = exportMain.asm exportManager.asm
EXPORTC         = tran07t.c trtns07t.c trtnx07t.c trtny07t.c trtnz07t.c\
                  w4w07t.c
IMPORT          = importMain.asm importManager.asm
IMPORTC         = getFormat.c tran07f.c trtns07f.c trtnx07f.c trtny07f.c\
                  trtnz07f.c w4w07f.c wp5tran.c
LIB             = libFormat.asm libManager.asm
OBJS            = wp5tran.obj tran07t.obj trtns07t.obj trtnx07t.obj\
                  trtny07t.obj trtnz07t.obj w4w07t.obj getFormat.obj\
                  tran07f.obj trtns07f.obj trtnx07f.obj trtny07f.obj\
                  trtnz07f.obj w4w07f.obj wp5tran.obj\
		  biortns.obj commonf.obj compub.obj errexit.obj\
		  biotemp.obj pcrev.obj  dsprtns.obj icfcodes.obj\
		  comfntb.obj comdos.obj comtntb.obj commont.obj\
		  ptrnum.obj hextran.obj stci_d.obj throwawy.obj\
		  comtstm.obj except.obj stcd_i.obj strstri.obj\
		  comfxcs.obj comtxcs.obj comxcs.obj

TEXTCOMMONC	= commonf.c biortns.c compub.c errexit.c biotemp.goc\
		  pcrev.c dsprtns.c icfcodes.c comfntb.c comdos.goc \
		  comtntb.c commont.c ptrnum.c hextran.c stci_d.c \
		  throwawy.c comtstm.c except.c stcd_i.c strstri.c\
	          comfxcs.c comtxcs.c comxcs.c

COMMON          = wordPerfect5XGeode.def wordPerfect5XGlobal.def
LOBJS           =
MODULES         = Export Import Lib
CMODULES        = CommonC ExportC ImportC ../TextCommonC
SRCS            = $(COMMONC) $(EXPORT) $(EXPORTC) $(IMPORT) $(IMPORTC)\
                  $(LIB) $(COMMON) $(TEXTCOMMONC)
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = wperf5
SUBDIRS         = CommonC CommonH Export ExportC Import ImportC Lib

#include	<geos.mk>		# system directory definitions
#include	<gpath.mk>		# set search paths for files

MAKEFILE	= Makefile
SYSMAKEFILE	= geode.mk

#if exists(local.mk)
#	include	"local.mk"
#else
#	include	<$(SYSMAKEFILE)>
#endif

#if 	exists($(DEPFILE))
#include	"$(DEPFILE)"
#endif

# Allow mkmf
