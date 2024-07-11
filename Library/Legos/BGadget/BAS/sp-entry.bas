sub duplo_ui_ui_ui()
REM
REM $Id: sp-entry.bas,v 1.1 98/03/12 20:30:40 martin Exp $
REM

DisableEvents()
Dim form1 as control
form1 = MakeComponent("control","top")
form1.name="form1"
form1.proto="form1"
REM form1.width = 250
REM form1.height = 180

Dim initText as label
initText = MakeComponent("label",form1)
initText.caption="Enter initial text here:"
initText.left=10
REM initText.top=10
REM initText.enabled=1
initText.readOnly=0
initText.sizeHControl=3
initText.sizeVControl=3
initText.visible=1

Dim entry1 as entry
entry1 = MakeComponent("entry",form1)
REM entry1.left=10
REM entry1.top=23
entry1.sizeHControl=3
entry1.sizeVControl=3
entry1.visible=1

Dim label1 as label
label1 = MakeComponent("label",form1)
label1.caption="Max Chars:"
REM label1.left=10
REM label1.top=70
label1.enabled=1
label1.readOnly=0
label1.sizeHControl=3
label1.sizeVControl=3
label1.visible=1

Dim number1 as number
number1 = MakeComponent("number",form1)
REM number1.left=80
REM number1.top=62
number1.maximum=250
number1.visible=1

Dim list1 as list
list1 = MakeComponent("list",form1)
list1.name="list1"
list1.proto="list1"
list1.caption=""
REM list1.left=10
REM list1.top=110
list1.look = 0
list1.behavior=1
list1.visible=1
list1.selectedItem=0

form1.visible=1
EnableEvents()
duplo_start()
end sub

sub duplo_start()
    export	form1
	const NUM_FILTERS 5

    dim filterStrings[NUM_FILTERS] as string
    dim filterValues[NUM_FILTERS] as integer

	filterStrings[0]="No filter"
	filterStrings[1]="Custom char filter"
	filterStrings[2]="Numeric filter"
	filterStrings[3]="Alphanumeric filter"
	filterStrings[4]="Alphanumeric + '-'"

	filterValues[0]=0
	filterValues[1]=1
	filterValues[2]=32
	filterValues[3]=36
	filterValues[4]=42

    dim i as integer
	for i = 0 to NUM_FILTERS - 1
		list1.captions[i]=filterStrings[i]
	next i
end sub

Function duplo_top() as component
	duplo_top = form1
    REM $Revision: 1.1 $
End function


sub form1_update(current as entry)
    form1.current = current
    number1.value = current.maxChars
    for i = 0 to NUM_FILTERS -1
	    if filterValues[i] = current.filter then
		    list1.selectedItem = i
	    end if
    next i
    
    entry1.text = current.text
end sub


sub sp_apply()
    form1.current.maxChars = number1.value
    form1.current.filter = filterValues[list1.selectedItem]
    form1.current.text = entry1.text
END sub
