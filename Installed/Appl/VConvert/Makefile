#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = vconvert
ASMTOOLS        = asmtoolsManager.asm
CGM             = cgm.h cgm.goc cgmraw.goc
EXPORT          = expobj.goc export.goc
GROBJ           = grobj.goc
HPGL            = hpgl.goc
VCONV           = vconv.goc vconv_ui.goh
UI_TO_RDFS      =
OBJS            = cgm.obj cgmraw.obj expobj.obj export.obj grobj.obj\
                  hpgl.obj vconv.obj
COMMON          = VCExport.h VConvert.h vconv_ui.h
MODULES         = asmtools
CMODULES        = CGM export grobj HPGL vconv
SRCS            = $(ASMTOOLS) $(CGM) $(EXPORT) $(GROBJ) $(HPGL) $(VCONV)\
                  $(COMMON)
LOBJS           =

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
