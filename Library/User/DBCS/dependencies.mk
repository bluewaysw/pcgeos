DBCS/Gen.obj \
DBCS/Gen.eobj: Gen/genManager.asm \
                
DBCS/Help.obj \
DBCS/Help.eobj: Help/helpManager.asm \
                
DBCS/IACP.obj \
DBCS/IACP.eobj: IACP/iacpManager.asm \
                
DBCS/Proc.obj \
DBCS/Proc.eobj: Proc/procManager.asm \
                
DBCS/Token.obj \
DBCS/Token.eobj: Token/tokenManager.asm \
                
DBCS/UI.obj \
DBCS/UI.eobj: UI/uiManager.asm \
                
DBCS/User.obj \
DBCS/User.eobj: User/userManager.asm \
                
DBCS/Vis.obj \
DBCS/Vis.eobj: Vis/visManager.asm \
                
DBCS/helpControl.rdef: generic.uih product.uih
DBCS/uiManager.rdef: generic.uih product.uih Internal/prodFeatures.uih \
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
DBCS/userManager.rdef: generic.uih product.uih User/userPassword.ui

DBCS/uiEC.geo DBCS/ui.geo : geos.ldf compress.ldf net.ldf sound.ldf wav.ldf 