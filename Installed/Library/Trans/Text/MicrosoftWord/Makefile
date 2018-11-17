##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	MicrosoftWord -- Makefile
# FILE: 	Makefile
# AUTHOR: 	, Mon Apr  7 22:12:09 PDT 1997
#
# TARGETS:
# 	Name			Description
#	----			-----------
#	microsoftwordec.geo		create an error-checking version
#	microsoftword.geo		create a non error-checking version
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

GEODE           = microsoftword

EXPORT          = exportMain.asm exportManager.asm
EXPORTC         = tran05t.c trchr05t.c trdiv05t.c trhdr05t.c trhdx05t.c\
                  trpar05t.c trtns05t.c w4w05t.c
IMPORT          = importMain.asm importManager.asm
IMPORTC         = getFormat.c tran05f.c trchr05f.c trdiv05f.c trhdr05f.c\
                  trhdx05f.c trpar05f.c trsty05f.c trtns05f.c w4w05f.c
LIB             = libFormat.asm libManager.asm
OBJS            = tran05t.obj trchr05t.obj trdiv05t.obj trhdr05t.obj\
                  trhdx05t.obj trpar05t.obj trtns05t.obj w4w05t.obj\
                  getFormat.obj tran05f.obj trchr05f.obj trdiv05f.obj\
                  trhdr05f.obj trhdx05f.obj trpar05f.obj trsty05f.obj\
                  trtns05f.obj w4w05f.obj\
		  biortns.obj commonf.obj compub.obj errexit.obj\
		  biotemp.obj pcrev.obj  dsprtns.obj icfcodes.obj\
		  comfntb.obj comdos.obj comtntb.obj commont.obj\
		  ptrnum.obj hextran.obj stci_d.obj throwawy.obj\
		  comtstm.obj except.obj stcd_i.obj strstri.obj\
		  comfxcs.obj comtxcs.obj comxcs.obj comtllen.obj\
		  comfctx.obj bldcols.obj stch_i.obj stcl_d.obj\
		  comfsnl.obj

TEXTCOMMONC	= commonf.c biortns.c compub.c errexit.c biotemp.goc\
		  pcrev.c dsprtns.c icfcodes.c comfntb.c comdos.goc \
		  comtntb.c commont.c ptrnum.c hextran.c stci_d.c \
		  throwawy.c comtstm.c except.c stcd_i.c strstri.c\
	          comfxcs.c comtxcs.c comxcs.c comtllen.c comfctx.c\
		  bldcols.c stch_i.c stcl_d.c comfsnl.c

COMMON          = microsoftWordGeode.def microsoftWordGlobal.def
LOBJS           =
MODULES         = Export Import Lib
CMODULES        = ExportC ImportC ../TextCommonC
SRCS            = $(EXPORT) $(EXPORTC) $(IMPORT) $(IMPORTC) $(LIB)\
                  $(COMMON) $(TEXTCOMMONC)
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = msword
SUBDIRS         = CommonH Export ExportC Import ImportC Lib

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
