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
  ' FILE:    pi.bas
  ' AUTHOR:  z!>c2bas 1999/10/20 (c)turon.com

  out.AppendString("\rCalculating PI to 240 digits:\r\r")
  ' known bugs: digit 33 and other prefix zeros are trimmed by Str()!

  DIM a AS long
  a = 10000
  DIM b AS long
  b = 0
  DIM c AS long
  c = 840 ' was 8400
  DIM d AS long
  d = 0
  DIM e AS long
  e = 0
  DIM f[841] AS long ' was 8401
  DIM g AS long
  g = 0

  DO WHILE b < c
    f[b] = a / 5
    b    = b + 1
  LOOP

  d = 0
  g = c * 2
  DO WHILE g > 0
    b = c
    DO WHILE b > 1
      d    = d + f[b] * a
      g    = g - 1
      f[b] = d MOD g
      d    = d / g
      g    = g - 1
      d    = d * b
      b    = b - 1
    LOOP    
    out.AppendString(FullStr(e + d / a))  ' display next 4 digits
    c = c - 14
    e = d MOD a
    d = 0 
    g = c * 2    
  LOOP

END SUB

FUNCTION FullStr(l as long) AS string
	' Returns a full length decimal string
	' including any prefix zeros corresponding
	' to the given long.
	' 1999/10/20 (c)turon
	FullStr = Str(l)
	IF Len(FullStr) < 4
		FullStr = "0"+FullStr
	END IF	
END FUNCTION

SUB module_show()
REM code for making this module appear
form1.visible=1
END SUB

SUB module_hide()
REM code for making this module disappear
form1.visible=0
END SUB


