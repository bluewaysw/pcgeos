#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = Html4Par
ASMTOOLS        = asmtoolsManager.asm
HTMLCLAS        = FORMSET.H HTMLCLAS.GOC HTMLCLRT.GOC HTMLCOL.GOC\
                  HTMLFDRW.GOC HTMLFEDI.GOC HTMLFORM.GOC HTMLFSIZ.GOC\
                  HTMLTABL.GOC HTMLTCEL.GOC HTMLTDRW.GOC HTMLTPOS.GOC\
                  HTMLTPRE.GOC
HTMLEXPT        = HTMLEXPT.GOC
HTMLPARS        = AWATCHER.GOC HTMLPARS.GOC OPENTAGS.GOC PARSINIT.GOC\
                  PARSTAGS.GOC stylesh.goc
WWWTOOLS        = DIALOGT.GOC NAMEPOOL.GOC WWWTOOLS.GOC
UI_TO_RDFS      =
OBJS            = HTMLCLAS.obj HTMLCLRT.obj HTMLCOL.obj HTMLFDRW.obj\
                  HTMLFEDI.obj HTMLFORM.obj HTMLFSIZ.obj HTMLTABL.obj\
                  HTMLTCEL.obj HTMLTDRW.obj HTMLTPOS.obj HTMLTPRE.obj\
                  HTMLEXPT.obj AWATCHER.obj HTMLPARS.obj OPENTAGS.obj\
                  PARSINIT.obj PARSTAGS.obj stylesh.obj DIALOGT.obj\
                  NAMEPOOL.obj WWWTOOLS.obj
COMMON          = DIALOGT.GOH ERRORS.H HTMLSTY.GOH INTERNAL.H OPTIONS.GOH\
                  RADIO0.GOH RADIO1.GOH REGIONT.H TABLEINT.H
MODULES         = asmtools
CMODULES        = HTMLCLAS HTMLEXPT HTMLPARS WWWTOOLS
SRCS            = $(ASMTOOLS) $(HTMLCLAS) $(HTMLEXPT) $(HTMLPARS)\
                  $(WWWTOOLS) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = html4par

PRODUCTS        = DBCS JS JSDBCS 

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

#if exists(DBCS/$(DEPFILE))
#include "DBCS/$(DEPFILE)"
#endif

#if exists(JS/$(DEPFILE))
#include "JS/$(DEPFILE)"
#endif

#if exists(JSDBCS/$(DEPFILE))
#include "JSDBCS/$(DEPFILE)"
#endif
