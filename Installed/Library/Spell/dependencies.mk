ET.obj \
ET.eobj: ET/etManager.asm \
                
UI.obj \
UI.eobj: UI/uiManager.asm \
                
ICS.obj \
ICS.eobj: ICS/icsManager.asm \
                
IH.obj \
IH.eobj: IH/ihManager.asm \
                
spellopen.obj \
spellopen.eobj: Open/openlex.inc Open/openlex.h Open/geosbridge.inc \
                Open/geosbridge.h geos.h file.h heap.h geode.h initfile.h \
                Open/icgeos.inc sem.h sllang.h Internal/icbuff.h \
                Open/openht.inc
uiManager.rdef: generic.uih product.uih spell.uih \
                Internal/prodFeatures.uih ./spellFeatures.h \
                UI/uiEditUserDict.ui UI/uiSpell.ui ./Art/mkrSpell.ui \
                UI/thesCtrl.ui

spellEC.geo spell.geo : geos.ldf ansic.ldf ui.ldf text.ldf 