SUB duplo_ui_ui_ui()
  ' standard output window
  DIM form1 AS form
  form1 = MakeComponent("form","app")
  CompInit form1
    proto="form1"
    top=60
    left=117
    tile=1
    width=456
    height=282
  End CompInit
  form1.name="form1"

' DIM label1 AS label
' label1 = MakeComponent("label",form1)
' CompInit label1
'   proto="label1"
'   caption="Calculates PI to 240 digits"
' End CompInit
' label1.visible = 1
    
  DIM out AS text
  out = MakeComponent("text",form1)
  CompInit out
    proto="out"
    width=420
    height=200
  End CompInit
  out.name="out"
  out.visible=1
END SUB

SUB module_init()
  ' 			Copyright (C) 1999 NewDeal, Inc.
  ' FILE:    wave.bas
  ' AUTHOR:  Martin Turon
  ' DATE:    October 23, 1999
  const SP_DOCUMENT 5
  const SP_PRIVDATA 9

  sound = MakeComponent("wave","top")
  sound.name = "CONGRATS.WAV"
  sound.path = "SOUNDS"
  sound.root = SP_PRIVDATA
  out.AppendString("\rPlaying wave file: ",sound.name," in PRIVDATA/SOUND.\r\r")
  sound.play()

  sound.path = ""
  sound.root = SP_DOCUMENT
  out.AppendString("\rPlaying wave file: ",sound.name," in DOCUMENT.\r\r")
  sound.play()

END SUB

SUB module_show()
REM code for making this module appear
form1.visible=1
END SUB

SUB module_hide()
REM code for making this module disappear
form1.visible=0
END SUB


