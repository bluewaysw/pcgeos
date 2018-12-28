win32/genpcMain.obj \
win32/genpcMain.eobj: geos.def geode.def library.def resource.def object.def \
                lmem.def Internal/interrup.def initfile.def \
                Internal/powerDr.def driver.def Internal/kbdMap.def \
                char.def input.def graphics.def fontID.def font.def \
                color.def hwr.def Objects/uiInputC.def localize.def \
                sllang.def gdi.def genpcConstant.def genpcConfig.def \
                genpcVariable.def genpcMacro.def \
                ../Common/gdiConstant.def ../Common/gdiVariable.def \
                ../Common/gdiPointer.asm ../Common/gdiKeyboard.asm \
                ../Common/gdiPower.asm ../Common/gdiExt.asm \
                ../Common/gdiUtils.asm genpcMouse.asm win.def \
                Internal/grWinInt.def Internal/videoDr.def hugearr.def \
                Internal/im.def Internal/semInt.def Objects/processC.def \
                Objects/metaC.def chunkarr.def geoworks.def timer.def \
                ec.def heap.def assert.def disk.def file.def drive.def \
                genpcKbd.asm genpcPwr.asm

win32/gdiEC.geo win32/gdi.geo : geos.ldf 