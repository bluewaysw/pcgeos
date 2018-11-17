#
# THIS FILE HAS BEEN GENERATED AUTOMATICALLY.
#
# If you edit it, you will lose your changes, should it be regenerated.
#
GEODE           = spline
BLEND           = blend.asm blendManager.asm blendData.def blendGlobal.def\
                  blendMacros.def
SPLINE          = splineAttrs.asm splineControls.asm splineCutPaste.asm\
                  splineData.asm splineDragRect.asm splineDragSelect.asm\
                  splineDraw.asm splineEC.asm splineEndSelect.asm\
                  splineGoto.asm splineGState.asm splineGString.asm\
                  splineInsertDelete.asm splineKeyboard.asm\
                  splineManager.asm splineMarker.asm splineMath.asm\
                  splineMethods.asm splineMode.asm splineMove.asm\
                  splineOperate.asm splinePtr.asm splineScratch.asm\
                  splineSelect.asm splineSplitJoin.asm\
                  splineStartSelect.asm splineSuspend.asm splineTarget.asm\
                  splineUI.asm splineUndo.asm splineUtils.asm\
                  splineVisBounds.asm splineVariables.def
UI              = uiControl.asm uiManager.asm uiMarker.asm uiOpenClose.asm\
                  uiPoint.asm uiPolyline.asm uiSmoothness.asm uiMain.ui\
                  uiMarker.ui uiOpenClose.ui uiPoint.ui uiPolyline.ui\
                  uiSmoothness.ui uiStrings.ui
UI_TO_RDFS      = uiMain.ui
OBJS            =
COMMON          = splineConstant.def splineGeode.def splineGlobal.def\
                  splineMacros.def
MODULES         = Blend Spline UI
CMODULES        =
SRCS            = $(BLEND) $(SPLINE) $(UI) $(COMMON)
LOBJS           =
LIBOBJ          = $(DEVEL_DIR)/Include/$(GEODE).ldf
LIBNAME         = spline

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
