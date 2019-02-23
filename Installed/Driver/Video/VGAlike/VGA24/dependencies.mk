vga24Manager.obj \
vga24Manager.eobj: vidcomGeode.def geos.def heap.def geode.def resource.def \
                ec.def driver.def lmem.def Internal/semInt.def \
                graphics.def fontID.def font.def color.def win.def \
                char.def localize.def sllang.def system.def \
                Internal/heapInt.def sysstats.def Internal/gstate.def \
                Internal/tmatrix.def Internal/fontDr.def file.def \
                Internal/window.def Internal/interrup.def \
                Internal/threadIn.def Internal/videoDr.def hugearr.def \
                vga24Constant.def vidcomConstant.def vga24Macro.def \
                vidcomMacro.def vga24DevInfo.asm vidcomTables.asm \
                vga24Table.asm vidcomVariable.def vga24Variable.def \
                vga24StringTab.asm vidcomEntry.asm vidcomOutput.asm \
                vidcomChars.asm vidcomFont.asm vga24Under.asm \
                vidcomUtils.asm vidcomRegion.asm vidcomXOR.asm \
                vidcomInfo.asm vidcomEscape.asm vidcomPalette.asm \
                vga24Output.asm vga24GenChar.asm vga24Utils.asm \
                vga24Chars.asm vga24Pointer.asm vga24EscTab.asm \
                vga24Palette.asm vga24Dither.asm vidcomPolygon.asm \
                vidcomLine.asm vidcomPutLine.asm vidcomRaster.asm \
                vga24Raster.asm vga24Admin.asm vidcomExclBounds.asm

vga24EC.geo vga24.geo : geos.ldf 