#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = flatfile
FIELDPROPERTIES = ffFpText.goc ffFieldEdges.goc ffFieldProperties.goc
GROBJ           = ffGrObjBody.goc
LOCALIZATION    = ffStrings.goc
FFMANAGER       = ffmanagerManager.asm
DATABASE        = ffDExtrn.h ffDatabaseMeta.goc ffDatabaseFieldOrder.goc\
                  ffDatabasePaste.goc ffDatabaseLayout.goc\
                  ffDatabaseSubset.goc ffPageLayoutRect.goc\
                  ffDatabaseImpex.goc ffDatabaseParse.goc\
                  ffDatabaseFloatController.goc ffDatabaseFields.goc\
                  ffDatabaseLabels.goc ffDatabaseRCP.goc ffDatabaseText.goc\
                  ffDatabaseSort.goc ffDatabaseCreate.goc ffDatabase.goc
TREASURECHEST   = ffTreasureChest.goc
EXPRBUILDER     = ffExprBuilder.goc
RECORDCONTROL   = ffRecordControl.goc ffRCPValue.goc ffRecordControlUI.goc
UI_TO_RDFS      =
OBJS            = ffFpText.obj ffFieldEdges.obj ffFieldProperties.obj\
                  ffGrObjBody.obj ffStrings.obj ffDatabaseMeta.obj\
                  ffDatabaseFieldOrder.obj ffDatabasePaste.obj\
                  ffDatabaseLayout.obj ffDatabaseSubset.obj\
                  ffPageLayoutRect.obj ffDatabaseImpex.obj\
                  ffDatabaseParse.obj ffDatabaseFloatController.obj\
                  ffDatabaseFields.obj ffDatabaseLabels.obj\
                  ffDatabaseRCP.obj ffDatabaseText.obj ffDatabaseSort.obj\
                  ffDatabaseCreate.obj ffDatabase.obj ffTreasureChest.obj\
                  ffExprBuilder.obj ffRecordControl.obj ffRCPValue.obj\
                  ffRecordControlUI.obj
COMMON          = ffFatal.h extern.h
MODULES         = FFManager
CMODULES        = FieldProperties GrObj Localization Database TreasureChest\
                  ExprBuilder RecordControl
SRCS            = $(FIELDPROPERTIES) $(GROBJ) $(LOCALIZATION) $(FFMANAGER)\
                  $(DATABASE) $(TREASURECHEST) $(EXPRBUILDER)\
                  $(RECORDCONTROL) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = ffile

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
