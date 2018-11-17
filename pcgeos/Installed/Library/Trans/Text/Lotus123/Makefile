#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Lotus123
EXPORT          = exportMain.asm exportManager.asm
EXPORTC         = trtns20t.c w4w20t.c
IMPORTC         = getFormat.c trtnx20f.c w4w20f.c ieeestr.c tran20f.c\
                  trtns20f.c
IMPORT          = importMain.asm importManager.asm
LIB             = libFormat.asm libManager.asm
TEXTCOMMONC	= commonf.c biortns.c compub.c errexit.c biotemp.goc\
		  pcrev.c dsprtns.c icfcodes.c comfntb.c comdos.goc \
		  comtntb.c
UI_TO_RDFS      =
OBJS            = trtns20t.obj w4w20t.obj getFormat.obj trtnx20f.obj\
                  w4w20f.obj ieeestr.obj tran20f.obj trtns20f.obj\
		  commonf.obj compub.obj commont.obj errexit.obj\
		  biortns.obj biotemp.obj pcrev.obj dsprtns.obj\
		  icfcodes.obj comfntb.obj comtntb.obj comdos.obj
COMMON          = lotus123Geode.def lotus123Global.def
MODULES         = Export Import Lib
CMODULES        = ExportC ImportC ../TextCommonC
SRCS            = $(EXPORT) $(EXPORTC) $(IMPORTC) $(IMPORT) $(LIB)\
                  $(COMMON) $(TEXTCOMMONC)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = lot123

SYSMAKEFILE     = geode.mk

#include <geos.mk>
#include <gpath.mk>

#if exists(local.mk)
#include "local.mk"
#else
#include <$(SYSMAKEFILE)>
#endif

#if exists($(DEPFILE))
#include "$(DEPFILE)"
#endif
