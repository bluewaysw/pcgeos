truetype.obj \
truetype.eobj: geos.def heap.def geode.def resource.def ec.def driver.def \
                lmem.def graphics.def fontID.def font.def color.def \
                gstring.def text.def char.def sem.def file.def \
                localize.def sllang.def system.def fileEnum.def \
                Internal/fontDr.def Internal/tmatrix.def \
                Internal/grWinInt.def Internal/gstate.def \
                Internal/window.def win.def Internal/threadIn.def \
                truetypeConstant.def truetypeVariable.def \
                truetypeMacros.def truetypeWidths.asm fontcomUtils.asm \
                truetypeChars.asm truetypeMetrics.asm truetypePath.asm \
                truetypeInit.asm truetypeEscape.asm fontcomEscape.asm \
                truetypeEC.asm

truetypeEC.geo truetype.geo : geos.ldf 