#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = ijgjpeg
API             = JCAPIMIN.c JCAPISTD.c JCOMAPI.c JCPARAM.c JCTRANS.c\
                  JDAPIMIN.c JDAPISTD.c JDTRANS.c
ASMTOOLS        = asmtoolsManager.asm
COMP            = JCCOEFCT.c JCCOLOR.c JCDCTMGR.c JCHUFF.c JCINIT.c\
                  JCMAINCT.c JCMARKER.c JCMASTER.c JCPHUFF.c JCPREPCT.c\
                  JCSAMPLE.c JDATADST.c JFDCTFLT.c JFDCTFST.c JFDCTINT.c\
                  JIDCTFLT.c
DECOMP          = JDATASRC.c JDCOEFCT.c JDCOLOR.c JDDCTMGR.c JDHUFF.c\
                  JDINPUT.c JDMAINCT.c JDMARKER.c JDMASTER.c JDMERGE.c\
                  JDPHUFF.c JDPOSTCT.c JDSAMPLE.c JIDCTFLT.c JIDCTFST.c\
                  JIDCTINT.c JIDCTRED.c JQUANT1.c JQUANT2.c
SUPPT           = JERROR.c JMEMGEOS.c JMEMMGR.c JUTILS.c
UI_TO_RDFS      =
OBJS            = JCAPIMIN.obj JCAPISTD.obj JCOMAPI.obj JCPARAM.obj\
                  JCTRANS.obj JDAPIMIN.obj JDAPISTD.obj JDTRANS.obj\
                  JCCOEFCT.obj JCCOLOR.obj JCDCTMGR.obj JCHUFF.obj\
                  JCINIT.obj JCMAINCT.obj JCMARKER.obj JCMASTER.obj\
                  JCPHUFF.obj JCPREPCT.obj JCSAMPLE.obj JDATADST.obj\
                  JFDCTFLT.obj JFDCTFST.obj JFDCTINT.obj JIDCTFLT.obj\
                  JDATASRC.obj JDCOEFCT.obj JDCOLOR.obj JDDCTMGR.obj\
                  JDHUFF.obj JDINPUT.obj JDMAINCT.obj JDMARKER.obj\
                  JDMASTER.obj JDMERGE.obj JDPHUFF.obj JDPOSTCT.obj\
                  JDSAMPLE.obj JIDCTFLT.obj JIDCTFST.obj JIDCTINT.obj\
                  JIDCTRED.obj JQUANT1.obj JQUANT2.obj JERROR.obj\
                  JMEMGEOS.obj JMEMMGR.obj JUTILS.obj
COMMON          = jchuff.h jdct.h jdhuff.h jerror.h jinclude.h jmemsys.h\
                  jpegint.h jversion.h
MODULES         = ASMTOOLS
CMODULES        = API COMP DECOMP SUPPT
SRCS            = $(API) $(ASMTOOLS) $(COMP) $(DECOMP) $(SUPPT) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = ijgjpeg

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
