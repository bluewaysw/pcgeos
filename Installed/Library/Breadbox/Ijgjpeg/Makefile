#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = ijgjpeg
COMP            = JFDCTFLT.c JCSAMPLE.c JCCOLOR.c JCMARKER.c JFDCTINT.c\
                  JCPHUFF.c JDATADST.c JCMASTER.c JCDCTMGR.c JIDCTFLT.c\
                  JFDCTFST.c JCPREPCT.c JCINIT.c JCHUFF.c JCCOEFCT.c\
                  JCMAINCT.c
ASMTOOLS        = asmtoolsManager.asm
DECOMP          = JDSAMPLE.c JQUANT2.c JDATASRC.c JDMARKER.c JIDCTFST.c\
                  JIDCTINT.c JDMASTER.c JDMAINCT.c JDCOLOR.c JQUANT1.c\
                  JIDCTFLT.c JDDCTMGR.c JDCOEFCT.c JDMERGE.c JIDCTRED.c\
                  JDINPUT.c JDHUFF.c JDPOSTCT.c JDPHUFF.c
API             = JCAPISTD.c JDTRANS.c JCAPIMIN.c JCOMAPI.c JCTRANS.c\
                  JDAPIMIN.c JDAPISTD.c JCPARAM.c
SUPPT           = JERROR.c JMEMMGR.c JUTILS.c JMEMGEOS.c
UI_TO_RDFS      =
OBJS            = JFDCTFLT.obj JCSAMPLE.obj JCCOLOR.obj JCMARKER.obj\
                  JFDCTINT.obj JCPHUFF.obj JDATADST.obj JCMASTER.obj\
                  JCDCTMGR.obj JIDCTFLT.obj JFDCTFST.obj JCPREPCT.obj\
                  JCINIT.obj JCHUFF.obj JCCOEFCT.obj JCMAINCT.obj\
                  JDSAMPLE.obj JQUANT2.obj JDATASRC.obj JDMARKER.obj\
                  JIDCTFST.obj JIDCTINT.obj JDMASTER.obj JDMAINCT.obj\
                  JDCOLOR.obj JQUANT1.obj JIDCTFLT.obj JDDCTMGR.obj\
                  JDCOEFCT.obj JDMERGE.obj JIDCTRED.obj JDINPUT.obj\
                  JDHUFF.obj JDPOSTCT.obj JDPHUFF.obj JCAPISTD.obj\
                  JDTRANS.obj JCAPIMIN.obj JCOMAPI.obj JCTRANS.obj\
                  JDAPIMIN.obj JDAPISTD.obj JCPARAM.obj JERROR.obj\
                  JMEMMGR.obj JUTILS.obj JMEMGEOS.obj
COMMON          = jerror.h jversion.h jpegint.h jchuff.h jdhuff.h jmemsys.h\
                  jdct.h jinclude.h
MODULES         = ASMTOOLS
CMODULES        = COMP DECOMP API SUPPT
SRCS            = $(COMP) $(ASMTOOLS) $(DECOMP) $(API) $(SUPPT) $(COMMON)
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
