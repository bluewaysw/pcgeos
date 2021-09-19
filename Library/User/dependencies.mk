Gen.obj \
Gen.eobj: Gen/genManager.asm \
                
Help.obj \
Help.eobj: Help/helpManager.asm \
                
IACP.obj \
IACP.eobj: IACP/iacpManager.asm \
                
Proc.obj \
Proc.eobj: Proc/procManager.asm \
                
Token.obj \
Token.eobj: Token/tokenManager.asm \
                
UI.obj \
UI.eobj: UI/uiManager.asm \
                
User.obj \
User.eobj: User/userManager.asm \
                
Vis.obj \
Vis.eobj: Vis/visManager.asm \
                
helpControl.rdef: generic.uih product.uih
uiManager.rdef: generic.uih product.uih Internal/prodFeatures.uih \
                UI/uiMain.ui UI/uiEdit.ui ./Art/mkrCut.ui \
                ./Art/mkrCopy.ui ./Art/mkrPaste.ui ./Art/mkrDelete.ui \
                ./Art/mkrUndo.ui ./Art/mkrSelectAll.ui UI/uiView.ui \
                ./Art/mkrAdjustAspect.ui ./Art/mkrApplyToAll.ui \
                ./Art/mkrNextPage.ui ./Art/mkrNormalScale.ui \
                ./Art/mkrPageDown.ui ./Art/mkrPageLeft.ui \
                ./Art/mkrPageRight.ui ./Art/mkrPageUp.ui \
                ./Art/mkrPreviousPage.ui ./Art/mkrScaleToFit.ui \
                ./Art/mkrShowHorizontal.ui ./Art/mkrShowVertical.ui \
                ./Art/mkrZoomIn.ui ./Art/mkrZoomOut.ui ./Art/mkrRedraw.ui \
                ./Art/mkrFirstPage.ui ./Art/mkrLastPage.ui UI/uiTool.ui \
                UI/uiPage.ui UI/uiDispCtrl.ui ./Art/mkrOverlapping.ui \
                ./Art/mkrFullSize.ui ./Art/mkrTile.ui UI/uiExpress.ui \
                UI/../Art/mkrApplicationsSC.ui \
                UI/../Art/mkrDocumentsSC.ui UI/../Art/mkrSettingsSC.ui \
                UI/../Art/mkrFindSC.ui UI/../Art/mkrHelpSC.ui \
                UI/../Art/mkrExitSC.ui UI/../Art/mkrApplicationsTC.ui \
                UI/../Art/mkrDocumentsTC.ui UI/../Art/mkrSettingsTC.ui \
                UI/../Art/mkrPreferencesTC.ui UI/../Art/mkrFindTC.ui \
                UI/../Art/mkrHelpTC.ui UI/../Art/mkrExitTC.ui \
                UI/../Art/mkrDialUpTC.ui
userManager.rdef: generic.uih product.uih User/userPassword.ui

uiEC.geo ui.geo : geos.ldf compress.ldf net.ldf sound.ldf wav.ldf 