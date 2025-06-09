# 8 GenValue
**GenValueClass** allows the user to retrieve or set a numerical value for use 
in your application. The GenValue object offers a display for the current 
value and the means to either increase or decrease this value. The GenValue 
object also manages the range that this value may fall between and the 
action to send out when a value has been selected. 

Before reading this chapter, you should be familiar with **GenClass** and with 
message passing. (See "GenClass," Chapter 2.)

## 8.1 GenValue Features

Depending upon the specific UI, the GenValue object can look like one of 
many things. It may be a spin gadget, a slider, a dial, or some other gadget. 
A GenValue typically allows the user to set a value within a specified range 
through keyboard or mouse input. For example, many GenValue objects in 
OSF/Motif are comprised of a text field showing the current value, an 
incrementor and a decrementor, and possibly a moniker. (Scroll bars are also 
GenValues, though they have very different appearance.)

In OSF/Motif, the user can enter the value by keyboard input into the text 
field or by clicking the mouse on the incrementor or decrementor.

The GenValue provides the following capabilities:

+ A user interface object to enter values into your application.

+ Application defined minimum and maximum values.

+ The increment value to increase or decrease values by.

+ Ability for the value to be represented in a variety of forms, including 
integer, decimal, or a unit of distance.

+ An action to apply any value to.

The user may change a value in a GenValue in one of two ways. It can be 
entered with the keyboard by typing directly into the display area, or it can 
be entered graphically by using the arrows, dials, or sliders that the specific 
UI provides. To enter a value by typing directly into the text field, first the 
user clicks on the area, bringing up a cursor. Then a value may be typed into 
the GenValue. To enter a value graphically, the user clicks on either the 
incrementor or decrementor, thus changing the value of the GenValue.

Once the value is changed, the value may become set immediately (if the 
object is operating in *immediate* mode), and the GenValue will perform its 
action (if any) every time the value is changed. As an alternative, the 
GenValue may be operating in *delayed* mode, and the value will not be set 
until a MSG_GEN_APPLY is received through an "Apply" or "OK" button. The 
mode (delayed or immediate) of the GenValue is controlled by the parent. 
Usually a GenValue will operate in immediate mode unless it is placed as a 
child of a GIT_PROPERTIES GenInteraction.

GenValue only allows the user to set a value within a specific range; this 
range consists of a minimum and maximum value that the GenValue may 
display. These values are set by the application and cannot be directly 
modified by the user, but they can be changed by your application. If the user 
enters a value above the maximum, the GenValue simply takes on its 
maximum possible value. If the user enters a value below the minimum, the 
GenValue takes on its least possible value.

![image info](Figures/Fig8-1.png)

**Figure 8-1** *A GenValue*  
*This image is of a GenValue in OSF/Motif. It is in the point display mode and 
is used to customize the font sizes in GeoWrite.*


In addition to the limits upon the range of values entered by the user, the 
GenValue also has a defined increment value. The increment value is the 
specific amount to increment or decrement the GenValue's value when using 
graphical input. The user cannot directly modify this value, but it can be 
changed by your application.

The GenValue object always displays a numerical value within its text field. 
The units of that numerical value may be set by your application. By default, 
any value within a GenValue is an integer, but that value could also be a 
decimal value, or even a unit of distance such as centimeters, points, or 
inches. The GenValue automatically provides whatever notation is required 
by the display units (decimal points, the words "pt" and "cm," or any other 
distance notation in the text field). (See Figure 8-1.)

## 8.2 GenValue Instance Data

The GenValue contains instance fields that affect the current value, the 
display units of that value, and the action to take when any value operation 
has been completed. These instance fields are listed in Code Display 8-1. 
Remember, in addition to these instance data variables, there are also the 
instance fields inherited from the GenValue's superclass, **GenClass**.

----------
**Code Display 8-1 GenValue Instance Data**

	/* The instance data fields for GenValue are shown below. Those that are records
	 * of flags have their default flags shown with other possible flags listed below.
	 * Other fields are shown with their default values. */

		@instance WWFixedAsDWord		GVLI_value = MakeWWFixed(0.0);
		@instance WWFixedAsDWord		GVLI_minimum = MakwWWFixed(0.0);
		@instance WWFixedAsDWord		GVLI_maximum = MakeWWFixed(32766);
		@instance WWFixedAsDword		GVLI_increment = MakeWWFixed(1.0);
		@instance GenValueStateFlags	GVLI_stateFlags = 0;

	/* GenValueStateFlags */
		typedef ByteFlags GenValueStateFlags;
		#define GVSF_INDETERMINATE		0x80
		#define GVSF_MODIFIED			0x40
		#define GVSF_OUT_OF_DATE		0x20

		@instance GenValueDisplayFormat		GVLI_displayFormat = GVDF_INTEGER;

	/* GenValueDisplayFormat */
		typedef ByteEnum GenValueDisplayFormat;
		#define GVDF_INTEGER 0
		#define GVDF_DECIMAL 1
		#define GVDF_POINTS 2
		#define GVDF_INCHES 3
		#define GVDF_CENTIMETERS 4
		#define GVDF_MILLIMETERS 5
		#define GVDF_PICAS 6
		#define GVDF_EUR_POINTS 7
		#define GVDF_CICEROS 8
		#define GVDF_POINTS_OR_MILLIMETERS 9
		#define GVDF_POINTS_OR_CENTIMETERS 10

		@instance optr				GVLI_destination;
		@instance Message			GVLI_applyMsg = 0;

----------
*GVLI_value* is the current numerical value of the GenValue. By default, it is 
an integer constant defined by the application. Depending on the 
*GVLI_displayFormat*, it can be interpreted as an integer, a decimal, or 
distance unit.

*GVLI_maximum* is the maximum possible value that the GenValue may 
display. This value may be positive or negative. The default value is 32766.

*GVLI_minimum* is the minimum possible value that the GenValue may 
display. This value may be positive or negative. The default value is zero.

*GVLI_increment* is the value to increment (or decrement) the GenValue when 
its value is changed by UI controls rather than direct text input. The default 
value is one.

*GVLI_stateFlags* specifies the **GenValueStateFlags** for the GenValue to 
operate under. These flags affect whether the data within the GenValue is 
indeterminate (not necessarily true) or modified (changed since the last 
MSG_GEN_APPLY).

*GVLI_displayFormat* specifies the units of measurement 
(**GenValueDisplayFormat**) that the numerical value represents. By 
default, this is an integer, but it could also be a decimal or a unit of 
measurement (such as inches, points, or centimeters).

*GVLI_applyMsg* is the message to send out upon GenValue changes (i.e. 
whenever it receives MSG_GEN_APPLY). There is no default message.

*GVLI_destination* is the object or process to send the message upon GenValue 
changes. This can be an optr to an object or a valid **TravelOption**. See 
"System Classes," Chapter 1. There is no default destination object.

----------
**Code Display 8-2 GenValue Optional Attribute Fields**

	@vardata Message	ATTR_GEN_VALUE_STATUS_MSG;
	@vardata word		TTR_GEN_VALUE_DECIMAL_PLACES;
	@vardata WWFixed	ATTR_GEN_VALUE_METRIC_INCREMENT;
	@vardata optr		ATTR_GEN_VALUE_RUNS_ITEM_GROUP;
		@reloc ATTR_GEN_VALUE_RUNS_ITEM_GROUP, 0 optr;
	@vardata void		ATTR_GEN_VALUE_SET_MODIFIED_ON_REDUNDANT_SELECTION;

----------
ATTR_GEN_VALUE_STATUS_MSG sets a status message for a GenValue. A 
status message allows your object to communicate with other objects when 
changes occur without sending out its apply message (*GVLI_applyMsg*).

ATTR_GEN_VALUE_DECIMAL_PLACES specifies the number of decimal 
places to display to the right of the decimal point if the *GVLI_displayFormat* 
allows fractional quantities.

ATTR_GEN_VALUE_METRIC_INCREMENT allows you to specify a particular 
metric increment to use besides the default if the *GVLI_displayFormat* is 
GVDF_POINTS_OR_MILLIMETERS or GVDF_INCHES_OR_CENTIMETERS.

ATTR_GEN_VALUE_RUNS_ITEM_GROUP links a GenValue to a 
GenItemGroup.

ATTR_GEN_VALUE_SET_MODIFIED_ON_REDUNDANT_SELECTION specifies 
that the GenValue should be marked modified whether or not a change in the 
value has occurred. This will result in that value being applied whenever it 
receives a MSG_GEN_APPLY. (The default behavior for when no change in 
state occurs, no message will be sent out.)

----------
**Code Display 8-3 GenValue Hints**

	@vardata void 		HINT_VALUE_INCREMENTABLE;
	@vardata void 		HINT_VALUE_NOT_INCREMENTABLE;

	@vardata void		HINT_VALUE_NAVIGATE_TO_NEXT_FIELD_ON_RETURN_PRESS;
	@vardata Message	HINT_VALUE_CUSTOM_RETURN_PRESS;

	@vardata WWFixedAsDWord 	HINT_VALUE_DISPLAYS_RANGE;
	@vardata GenValueIntervals	HINT_VALUE_DISPLAY_INTERVALS;
	@vardata void		HINT_VALUE_CONSTRAIN_TO_INTERVALS;

	typedef struct {
		word	GVI_numMajorIntervals;
		word	GVI_numMinorIntervals;
	} GenValueIntervals;

	@vardata void		HINT_VALUE_SHOW_MIN_AND_MAX;
	@vardata void		HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION;
	@vardata void		HINT_VALUE_DELAYED_DRAG_NOTIFICATION;
	@vardata void		HINT_VALUE_ORIENT_HORIZONTALLY;
	@vardata void		HINT_VALUE_ORIENT_VERTICALLY;

	@vardata void		HINT_VALUE_ANALOG_DISPLAY;
	@vardata void		HINT_VALUE_DIGITAL_DISPLAY;
	@vardata void		HINT_VALUE_NO_DIGITAL_DISPLAY;
	@vardata void		HINT_VALUE_NO_ANALOG_DISPLAY;
	@vardata void		HINT_VALUE_NOT_DIGITALLY_EDITABLE;
	@vardata void		HINT_VALUE_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS;

----------
HINT_VALUE_INCREMENTABLE and HINT_VALUE_NOT_INCREMENTABLE 
specify whether increment (and decrement) gadgets are appropriate for this 
GenValue. By default, GenValues are incrementable. 

HINT_VALUE_CUSTOM_RETURN_PRESS stores a Message to send out if the 
user hits return within the textual portion of a GenValue. Normally, this 
action triggers the interaction default (sending the apply message).

HINT_VALUE_DISPLAYS_RANGE indicates that this GenValue displays a 
range of values between its minimum and maximum. In most cases, this 
suggests that the GenValue use sliders or some other UI gadget that is able 
to show the width of a range. It is up to the specific UI to support range 
values. If this hint is present, *GVLI_value* refers to the starting point of the 
range of values, whose width is stored in the **WWFixedAsDWord** value 
here. The maximum *GVLI_value* in this case would be *GVLI_maximum* minus 
the range. If this hint is not present, the range "length" is presumed to be 
zero, even in gadgets that specify a range length by default.

HINT_VALUE_DISPLAY_INTERVALS indicates that intervals should be 
displayed along an object's range. This hint is used most often in analog (e.g. 
slider) type displays. If possible, hash marks will appear along the 
GenValue's display at the intervals specified by **GenValueIntervals**. This 
structure stores entries for both major intervals and minor intervals. In 
general, minor intervals will have smaller tick marks than major intervals.

	typedef struct {
		word GVI_numMajorIntervals;
		word GVI_numMinorIntervals;
	} GenValueIntervals;

If either *GVI_numMajorIntervals* or *GVI_numMinorIntervals* is zero, only one 
set of marks will appear.

HINT_VALUE_CONSTRAIN_TO_INTERVALS suggests that the value within 
*GVLI_value* constrain itself to the *GVI_numMinorIntervals* interval within 
HINT_VALUE_DISPLAY_INTERVALS.

HINT_VALUE_SHOW_MIN_AND_MAX instructs the GenValue to display its 
minimum and maximum values, if possible.

HINT_VALUE_IMMEDIATE_DRAG_NOTIFICATION instructs the GenValue to 
send out its status and/or apply messages constantly during a drag operation 
(each time the value changes). It is up to the specific UI to support this 
behavior.

HINT_VALUE_DELAYED_DRAG_NOTIFICATION instructs the GenValue to 
delay sending out status and/or apply message until the user releases the 
mouse after the drag operation. It is up to the specific UI to support this 
behavior.

HINT_VALUE_ORIENT_HORIZONTALLY instructs the specific UI to arrange 
an analog GenValue, if available, in the horizontal dimension.

HINT_VALUE_ORIENT_VERTICALLY instructs the specific UI to arrange an 
analog GenValue, if available, in the vertical dimension.

HINT_VALUE_ANALOG_DISPLAY indicates that the GenValue should be 
displayed in an analog fashion, if applicable. 
HINT_VALUE_DIGITAL_DISPLAY indicates that the GenValue should be 
displayed in a digital fashion (i.e. numerically). Similarly, 
HINT_VALUE_NO_DIGITAL_DISPLAY and 
HINT_VALUE_NO_ANALOG_DISPLAY indicate that a digital or analog display 
is not appropriate. 

HINT_VALUE_NOT_DIGITALLY_EDITABLE instructs the UI to disallow 
editing of the text within a numerical GenValue. This hint is only applicable 
if some other UI means of changing the value is available. To remove a 
numeric display of values entirely, use HINT_VALUE_NO_DIGITAL_DISPLAY.

HINT_VALUE_DO_NOT_MAKE_LARGER_ON_PEN_SYSTEMS instructs the 
specific UI to avoid expanding a GenValue object to accept pen input, if 
possible. By default, text areas of GenValues grow larger under pen systems 
to allow ink strokes. This hint usually indicates that non-ink means of 
entering values is available.

## 8.3 GenValue Basics

The GenValue instance fields can be set to specific values in your Goc file, and 
they can also be modified by your application at run-time. This section 
describes how to set and modify these fields in your Goc file. 

### 8.3.1 The Value

	GVLI_value, MSG_GEN_VALUE_SET_VALUE, 
	MSG_GEN_VALUE_SET_INTEGER_VALUE, MSG_GEN_VALUE_GET_VALUE

The GVLI_value instance field stores the current numerical value of the 
GenValue. You may set an initial value for the GenValue to appear with by 
setting this instance field in your Goc file. This value is a fixed point number; 
use **MakeWWFixed** to create this fixed point number in your instance data.

Any user changes on the value within the text field will not affect *GVLI_value* 
until MSG_GEN_APPLY applies that value. If the GenValue operates in 
delayed mode, it will be marked modified in its *GVLI_stateFlags* whenever a 
user change occurs; those changes will be applied when the GenValue 
receives a MSG_GEN_APPLY. In most cases, however, a GenValue operates in 
immediate mode, which will result in an immediate change in *GVLI_value*.

----------
**Code Display 8-4 Setting an Initial Value**

	/* This GenValue will appear with the initial integer value of two. MakeWWFixed
	 * creates a fixed point value. */

	@object GenValueClass MyValue = {
		GI_visMoniker = "My Value";
		GVLI_value = MakeWWFixed(2.0);
	}

----------
**GenValueClass** provides several messages to change the value without user 
control. MSG_GEN_VALUE_SET_VALUE sets this numeric value to a passed 
fixed point value; this fixed point value may be any integer or decimal value. 
MSG_GEN_VALUE_SET_INTEGER_VALUE is a simpler message which sets 
GVLI_value to an integer value passed. Neither of these messages mark the 
GenValue modified; you can do this with 
MSG_GEN_VALUE_SET_MODIFIED_STATE.

----------
#### MSG_GEN_VALUE_SET_VALUE

	void	MSG_GEN_VALUE_SET_VALUE(
			WWFixedAsDWord		value,
			Boolean				indeterminate);

This message sets the *GVLI_value* field of the GenValue to the passed value. 
This message clears a GenValue's modified state in its *GVLI_stateFlags*. To 
mark the GenValue modified send MSG_GEN_VALUE_SET_MODIFIED_STATE 
after sending this message.

**Source:** Unrestricted. This message is also used internally when responding to 
user actions.

**Destination:** Any GenValue object.

**Parameters:**  
*value* - The fixed point value to set *GVLI_value* to. If you 
only need an integral value, consider using 
MSG_GEN_VALUE_SET_INTEGER_VALUE instead.

*indeterminate* - TRUE to mark the GenValue indeterminate, FALSE 
to mark it non indeterminate.

**Return:** Nothing.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_INTEGER_VALUE

	void	MSG_GEN_VALUE_SET_INTEGER_VALUE(
			word		value,
			Boolean		indeterminate);

This message sets the *GVLI_value* to the passed integer (word-sized) value. 
*GVLI_value* will then contain this value in its high (integral) word and zero 
in its low (fractional) word. The modified state of the GenValue will be 
cleared.

**Source:** Unrestricted. This message is also used internally when responding to 
user actions.

**Destination:** Any GenValue object.

**Parameters:**  
*value* - The signed integer value to set *GVLI_value* to.

*indeterminate* - TRUE to mark the GenValue indeterminate, FALSE 
to mark it non indeterminate.

**Return:** Nothing.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_GET_VALUE

	WWFixedAsDword MSG_GEN_VALUE_GET_VALUE();

This message returns the value stored in the GenValue's *GVLI_value* 
instance field. This returned value will be a fixed point number.

**Source:**	Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** The fixed point numerical value of the *GVLI_value* instance field.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_GET_INTEGER_VALUE

	@alias (MSG_GEN_VALUE_GET_VALUE) 
				word MSG_GEN_VALUE_GET_INTEGER_VALUE();

This message returns the integral portion of the GenValue's value.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** The integral value of the *GVLI_value* instance field.

**Interception:** Generally not intercepted.

### 8.3.2 The Minimum and Maximum

	GVLI_minimum, GVLI_maximum, MSG_GEN_VALUE_GET_MAXIMUM, 
	MSG_GEN_VALUE_SET_MAXIMUM, MSG_GEN_VALUE_GET_MINIMUM, 
	MSG_GEN_VALUE_SET_MINIMUM

The maximum (*GVLI_maximum*) and minimum (*GVLI_minimum*) values of a 
GenValue constrain the value of *GVLI_value*. The maximum is the greatest 
value that the GenValue's *GVLI_value* can have and can be any fixed point 
number from -32767 up to 32767. The minimum is the least value that the 
GenValue's *GVLI_value* can have (including negative numbers) and can be 
any fixed point number from 32767 down to -32767. The maximum value 
must always be greater than or equal to the minimum value; otherwise, an 
error will occur.

The maximum and minimum values of the GenValue also can be examined 
and modified by the application. This is helpful if you need to use the same 
GenValue for two functions with different ranges of values. You can use the 
GenValue for one function, change the bounds, and use it for another 
function.

MSG_GEN_VALUE_GET_MINIMUM and MSG_GEN_VALUE_GET_MAXIMUM 
return the values of *GVLI_minimum* and *GVLI_maximum* respectively. This 
value is in fixed point format.

MSG_GEN_VALUE_SET_MINIMUM and MSG_GEN_VALUE_SET_MAXIMUM 
set the values of *GVLI_minimum* and *GVLI_maximum* respectively. If this 
new minimum or maximum places the current *GVLI_value* outside the valid 
value range, the value will be adjusted to fall within the current range.

----------
#### MSG_GEN_VALUE_GET_MAXIMUM

	WWFixedAsDWord MSG_GEN_VALUE_GET_MAXIMUM()

This message returns the fixed point value within the *GVLI_maximum* 
instance field of the GenValue.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** The fixed point maximum value in *GVLI_maximum*.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_MAXIMUM

	void	MSG_GEN_VALUE_SET_MAXIMUM(
			WWFixedAsDWord 		value);

This message sets the *GVLI_maximum* field of the GenValue to the passed 
fixed point value. If you set a new maximum that places the current value (in 
*GVLI_value*) above that maximum, *GVLI_value* will be adjusted to this 
maximum.

**Source:** Unrestricted. This message is also used internally when the GenValue 
is being built.

**Destination:** Any GenValue object.

**Parameters:**  
*value* - fixed point value to set *GVLI_maximum* to.

**Return:** Nothing.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_GET_MINIMUM

	WWFixedAsDWord MSG_GEN_VALUE_GET_MINIMUM()

This message returns the fixed point value within the *GVLI_minimum* 
instance field of the GenValue.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** The fixed point minimum value in *GVLI_minimum*.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_MINIMUM

	void	MSG_GEN_VALUE_SET_MINIMUM(
			WWFixedAsDword		value);

This message sets the *GVLI_minimum* instance field of the GenValue to the 
passed fixed point value. If you set a new minimum that places the current 
value (in *GVLI_value*) below that minimum, *GVLI_value* will be adjusted to 
this minimum.

**Source:** Unrestricted. This message is also used internally when the GenValue 
is being built. 

**Destination:** Any GenValue object.

***Parameters:**  
value* - fixed point value to set GVLI_minimum to.

**Return:** Nothing.

**Interception:** Generally not intercepted.

### 8.3.3 The Increment

	GVLI_increment, MSG_GEN_VALUE_GET_INCREMENT, 
	MSG_GEN_VALUE_SET_INCREMENT, HINT_VALUE_INCREMENTABLE, 
	HINT_VALUE_NOT_INCREMENTABLE

The *GVLI_increment* instance field stores the fixed point increment value for 
a GenValue. The increment value is the amount by which the current value 
(in *GVLI_value*) may increase or decrease when that value is changed by UI 
controls. The increment value can be any positive fixed point value between 
one and 65535.

If *GVLI_increment* is greater than the possible range of the GenValue (the 
distance between minimum and maximum), then incrementing or 
decrementing the GenValue will toggle *GVLI_value* between its maximum 
and minimum.

----------
**Code Display 8-5 Setting Minimum, Maximum, Increment Values**

	@object GenValueClass MyValue = {
		GI_visMoniker = "My Value";
		GVLI_value = MakeWWFixed(1.0);
		GVLI_minimum = MakeWWFixed(-100.0);
		GVLI_maximum= MakeWWFixed(100.0);
		GVLI_increment = MakeWWFixed(5.0);
	}

----------
You may change the fixed point value of this increment with 
MSG_GEN_VALUE_SET_INCREMENT. You may also return the current 
increment stored within *GVLI_increment* with 
MSG_GEN_VALUE_GET_INCREMENT. You may wish to change a GenValue's 
increment when one GenValue is being used for multiple roles and must change its 
increment value.

By default, all GenValues are incrementable. If you do not wish to have your 
GenValue provide UI controls for incrementing (or decrementing) its value, 
add HINT_VALUE_NOT_INCREMENTABLE in its instance data. 
HINT_VALUE_INCREMENTABLE provides the default behavior. (You may still 
increment or decrement the value manually with 
MSG_GEN_VALUE_INCREMENT or MSG_GEN_VALUE_DECREMENT.)

----------
#### MSG_GEN_VALUE_SET_INCREMENT

	void	MSG_GEN_VALUE_SET_INCREMENT (
			WWFixedAsDWord 		value);

This message sets the *GVLI_increment* field to the passed value.

**Source:** Unrestricted. This message is also used internally when the GenValue 
is being built.

**Destination:** Any GenValue object.

**Parameters:**  
*value* - fixed point value to set *GVLI_increment* to.

**Return:** Nothing.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_GET_INCREMENT

	WWFixedAsDWord MSG_GEN_VALUE_GET_INCREMENT();

This message returns the value of the *GVLI_increment* field of the GenValue.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** The fixed point value of *GVLI_increment*.

**Interception:** Generally not intercepted.

### 8.3.4 GenValue States

	GVLI_stateFlags, MSG_GEN_VALUE_SET_INDETERMINATE_STATE, 
	MSG_GEN_VALUE_IS_INDETERMINATE, 
	MSG_GEN_VALUE_SET_MODIFIED_STATE, 
	MSG_GEN_VALUE_IS_MODIFIED, 
	ATTR_GEN_SET_MODIFIED_ON_REDUNDANT_SELECTION

*GVLI_stateFlags* stores the current state of the GenValue. There are two 
**GenValueStateFlags**:

+ GVSF_INDETERMINATE
This flag specifies that the value within the GenValue is indeterminate 
(may or may not be true). In most cases, you will not need to set this flag. 

+ GVSF_MODIFIED
This flag specifies that the value within the GenValue has changed since 
it last received a MSG_GEN_APPLY. The handler for MSG_GEN_APPLY 
checks whether this flag is set before sending out the GenValue's 
*GVLI_applyMsg*.

+ GVSF_OUT_OF_DATE
This flag specifies that the value within the GenValue is out of date with 
what the user has typed in. This is distinct from the GVSF_MODIFIED 
state; while the user is typing an a value ("123" for example) the typed 
value may be temporarily out of range, or incomplete. In this case, the 
value would be marked GVSF_OUT_OF_DATE and GVSF_MODIFIED. 
Notice that if the value were incremented or decremented, it would be 
marked GVSF_MODIFIED, but not GVSF_OUT_OF_DATE because the 
value is legal and presumable valid for operations. This flag is most 
useful when telling status messages whether a value should be used.

GenValues are normally marked as not modified anytime their state is set 
with an external message, marked modified whenever the user interacts 
with them, and marked not modified after receiving MSG_GEN_APPLY. 
MSG_GEN_VALUE_SET_MODIFIED_STATE allows you to control the modified 
state of a GenValue outside of these events.

You may set a GenValue's indeterminate or modified state with 
MSG_GEN_VALUE_SET_INDETERMINATE_STATE or 
MSG_GEN_VALUE_SET_MODIFIED_STATE, respectively.

To check whether a GenValue is indeterminate or modified, use 
MSG_GEN_VALUE_IS_INDETERMINATE or MSG_GEN_VALUE_IS_MODIFIED.

You may also mark a GenValue GVSF_OUT_OF_DATE by sending it 
MSG_GEN_VALUE_SET_OUT_OF_DATE.

----------
#### MSG_GEN_VALUE_SET_INDETERMINATE_STATE

	void	MSG_GEN_VALUE_SET_INDETERMINATE_STATE(
			Boolean		indeterminateState);

This message sets the indeterminate state for a GenValue. Pass TRUE to 
mark the GenValue indeterminate, FALSE to mark it not indeterminate. The 
GenValue will not be marked modified after this message.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*indeterminateState* - TRUE to set the GVSF_INDETERMINATE flag in the 
GenValue's *GVLI_stateFlags*,
FALSE to clear the GVSF_INDETERMINATE flag.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_IS_INDETERMINATE

	Boolean	MSG_GEN_VALUE_IS_INDETERMINATE();

This message checks whether a GenValue is indeterminate. 

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Return:** TRUE if GenValue is indeterminate, FALSE if it is not.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_MODIFIED_STATE

	void	MSG_GEN_VALUE_SET_MODIFIED_STATE(
			Boolean		modifiedState);

This message sets the modified state for a GenValue. Pass TRUE to mark the 
GenValue modified, FALSE to mark it not modified.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*modifiedState* 
TRUE to set the GVSF_MODIFIED flag in the 
GenValue's *GVLI_stateFlags*,
FALSE to clear the GVSF_MODIFIED flag.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_IS_MODIFIED

	Boolean	MSG_GEN_VALUE_IS_MODIFIED();

This message checks whether a GenValue has been modified since the last 
MSG_GEN_APPLY. 

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Return:** TRUE if GenValue is modified, FALSE if it is not.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_OUT_OF_DATE

	void	MSG_GEN_VALUE_SET_OUT_OF_DATE();

This message sets a GenValue's GVSF_OUT_OF_DATE flag.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Interception:** Generally not intercepted.

### 8.3.5 Display Formats

	GVLI_displayFormat, MSG_GEN_VALUE_SET_DISPLAY_FORMAT, 
	MSG_GEN_VALUE_GET_DISPLAY_FORMAT, 
	ATTR_GEN_VALUE_METRIC_EQUIVALENT, 
	ATTR_GEN_VALUE_DECIMAL_PLACES

In addition to displaying an integer numerical value, a GenValue may also 
display numerical values of several other formats. These formats may be any 
one of the **GenValueDisplayFormat** enumerations provided in 
**GenValueClass**. The allowed enumerations of type 
**GenValueDisplayFormat** are:

	GVDF_INTEGER
	GVDF_DECIMAL
	GVDF_POINTS
	GVDF_INCHES
	GVDF_CENTIMETERS
	GVDF_MILLIMETERS
	GVDF_PICAS
	GVDF_EUR_POINTS
	GVDF_CICEROS
	GVDF_POINTS_OR_MILLIMETERS
	GVDF_INCHES_OR_CENTIMETERS

*GVLI_displayFormat* controls how the values of the GenValue will be 
represented. For example, if the display format is in centimeters, the display 
will include the text "cm" after the numerical value; if the display includes a 
fractional part, a decimal point will be present. These display formats will 
also convert the values (which are stored as points) into the proper distance 
units for the textual display.

By default, the value's fractional portion will be displayed using 3 places to 
the right of the decimal point. You may alter this number of places with 
ATTR_GEN_VALUE_DECIMAL_PLACES. You may only choose a number of 
decimal places between zero to four (inclusive), because of the limited text 
space offered within a GenValue.

Your GenApplication object contains instance data which specifies whether 
the application is being run under US or metric units. This setting may affect 
the display of your units depending on the particular 
**GenValueDisplayFormat**. 

GVDF_INTEGER displays the value as an integer (the high word of the fixed 
point value) and ignores any fractional part. 

GVDF_DECIMAL displays the value as a decimal value. 

GVDF_POINTS displays the value in points (1/72 of an inch) regardless of 
whether metric or US units are specified for the application. 

GVDF_INCHES displays the value in inches regardless of whether metric or 
US units are specified for the application. 

GVDF_CENTIMETERS displays the value in centimeters regardless of 
whether metric or US units are specified for the application.

GVDF_MILLIMETERS displays the value in millimeters regardless of whether 
metric or US units are specified for the application.

GVDF_PICAS displays the value as a distance in picas. One pica is equal to 12 
US Points, or 1/6 of an inch.

GVDF_EUR_POINTS displays the value as a distance in European Points. One 
european point is about equal to 1.0656 US Points.

GVDF_CICEROS displays the value as a distance in Ciceros. One Cicero is 
equal to 12 European Points.

GVDF_POINTS_OR_MILLIMETERS and GVDF_INCHES_OR_CENTIMETERS 
are special cases. These display formats display the value in 
points (or inches) if US units are specified for the application; 
the value will be represented in millimeters (or centimeters) if 
metric units are instead specified.

Importantly, *all* distance units (inches, picas, centimeters, etc.) store their 
values as Points (1/72 inch). The system automatically converts these values 
(in Points) into the proper units of the GenValue's *GVLI_displayFormat* when 
it displays the numerical value within the textual display.

----------
**Code Display 8-6 Setting a Distance Display Format**

	@object GenValueClass MyValue = {
		GI_visMoniker = "My Value";
		GVLI_displayFormat = GVDF_INCHES;

	/* For an initial value of 1 inch, the equivalent value in Points is 72. */
		GVLI_value = MakeWWFixed(72.0);

	/* For an initial value of 1/2 inch, the equivalent value in Points is 36. */
		GVLI_increment = MakeWWFixed(36.0);
	}

----------
 For example, if your display format is GVDF_INCHES and you wish to set an 
initial value of 1 inch and an increment of 1/2 an inch, you should set these 
values to 72 (points which equals 1 inch) and 36 (points which equals one-half 
inch) respectively. This is necessary because the system expects these values 
to be in Points for other system operations. A conversion table is provided in 
Table 8-1 for setting up these initial values.

**Table 8-1** Conversions to US Points

	Distance Unit		Multiplier  
	Inches				72  
	Centimeters			28.3465  
	Millimeters			2.8346  
	Picas				12  
	European Points		1.0656  
	Ciceros				12.7872

Any increments for GVDF_POINTS_OR_MILLIMETERS or 
GVDF_INCHES_OR_CENTIMETERS are assumed to be in US units. If the 
application instead operates in metric, the increment will be automatically 
converted to a metric equivalent by the system; this metric equivalent will 
usually be rounded to a convenient numerical value. You may specify an 
ATTR_GEN_VALUE_METRIC_EQUIVALENT to override the default increment 
that the system calculates, however.

For example, assume GVDF_INCHES_OR_CENTIMETERS is selected and the 
value and increment are 72 (points which equals 1 inch). If the application is 
in US units, the display will specify inches and the value and increment will 
be 72 (1 inch); if the application is instead in metric, the display will specify 
centimeters and the increment will be 70.866 (2.5 cm). If instead, you choose 
an ATTR_GEN_VALUE_METRIC_INCREMENT of 52.692 (2 cm), that will be 
the increment used if the application is metric.

----------
Code Display 8-7 ATTR_GEN_VALUE_METRIC_INCREMENT

	/* If the application is US, the initial value will be 1 inch and the increment 
	 * will be 1 inch. If the application is metric, the initial value will be 2.54 cm
	 * (1 inch or 72 points) but the increment will be 2.0 cm (56.692 points). If
	 * ATTR_GEN_VALUE_METRIC_INCREMENT were not included, the system would have chosen
	 * an increment of 2.5 cm (70.866 points) which is the closest "nice" value to the
	 * original increment of 72 points (1 inch). */

	@object GenValueClass MyValue = {
		GI_visMoniker = "My Value";
		GVLI_displayFormat = GVDF_INCHES_OR_CENTIMETERS;
		GVLI_value = MakeWWFixed(72.0);
		GVLI_increment = MakeWWFixed(72.0);
		ATTR_GEN_VALUE_METRIC_INCREMENT = MakeWWFixed(56.692);
	}

----------
To set a new display format, send MSG_GEN_VALUE_SET_DISPLAY_FORMAT. 
To retrieve the current display format, send the GenValue 
MSG_GEN_VALUE_GET_DISPLAY_FORMAT. Note that changing the display 
format will not change the numerical value of that display. For example, if 
the display format changes from decimal to integer, the GenValue will round 
the number down and display only the integer portion of the value.
#### MSG_GEN_VALUE_GET_DISPLAY_FORMAT

	GenValueDisplayFormat MSG_GEN_VALUE_GET_DISPLAY_FORMAT();

This message returns the *GVLI_displayFormat* field of the GenValue.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** **GenValueDisplayFormat** of the GenValue.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_DISPLAY_FORMAT

	void	MSG_GEN_VALUE_SET_DISPLAY_FORMAT(
			GenValueDisplayFormat			format);

This message sets the *GVLI_displayFormat* of the GenValue to the given 
format. The current value in *GVLI_value* is unaffected, but the display will be 
updated to reflect the new display format.

**Source:** Unrestricted. This message is also used internally when the GenValue 
is being built. 

**Destination:** Any GenValue object.

**Parameters:**  
*format* - **GenValueDisplayFormat** to set the GenValue to.

**Return:** Nothing.

**Interception:** Generally not intercepted.

### 8.3.6 Sending an Action

	GVLI_applyMsg, GVLI_destination, 
	HINT_VALUE_NAVIGATE_TO_NEXT_FIELD_ON_RETURN_PRESS, 
	HINT_VALUE_CUSTOM_RETURN_PRESS, 
	MSG_GEN_VALUE_GET_APPLY_MSG, MSG_GEN_VALUE_SET_APPLY_MSG, 
	MSG_GEN_VALUE_GET_DESTINATION, 
	MSG_GEN_VALUE_SET_DESTINATION

*GVLI_applyMsg* sets the message for the GenValue to send out whenever it 
has been modified and needs to apply its changes. Whenever a GenValue 
receives MSG_GEN_APPLY, it will check whether its GVSF_MODIFIED flag has 
been set; if it has, it will send out its apply message. If a GenValue is 
operating in immediate mode, these actions will happen immediately, 
resulting in an immediate action.

*GVLI_destination* specifies the destination object (or process) to send the 
*GVLI_applyMsg* to. (This may also be a **TravelOption**, such as 
TO_APP_TARGET.)

----------

**Code Display 8-8 Sending an Apply Message**

	@object GenValueClass MyValue = {
		GI_visMoniker = "My Value";
		GVLI_value = MakeWWFixed(1.0);
		GVLI_applyMsg = MSG_MY_VALUE_DOUBLE_VALUE;
		GVLI_destination = process;
	}

	/* Retrieve the current value. This value will be a fixed point dword. */

	@method MyValueProcessClass, MSG_MY_VALUE_DOUBLE_VALUE {
		WWFixedAsDWord	curValue;

		curValue = @call MyValue::MSG_GEN_VALUE_GET_VALUE();
		curValue = curValue*2;
		@call MyValue::MSG_GEN_VALUE_SET_VALUE(curValue, 0);
	}

----------



A GenValue's changes are typically applied when the user hits the Return 
key and the GenValue has the focus. You can change this behavior, though, 
with the following hints: HINT_VALUE_CUSTOM_RETURN_PRESS allows a 
textually-oriented GenValue to send the specified message to the destination 
object when the Return key is pressed. 
HINT_VALUE_NAVIGATE_TO_NEXT_FIELD_ON_RETURN_PRESS instructs 
the GenValue to navigate (via the UI) to the next textually-activated object 
(as the tab key works in many situations).

To change a GenValue's apply message or destination, send it 
MSG_GEN_VALUE_SET_APPLY_MSG or 
MSG_GEN_VALUE_SET_DESTINATION, respectively. Use 
MSG_GEN_VALUE_GET_APPLY_MSG or 
MSG_GEN_VALUE_GET_DESTINATION to return the current apply message 
or destination.

The apply message should be defined on the prototype 
GEN_VALUE_APPLY_MSG, whose values are shown below.

----------
#### GEN_VALUE_APPLY_MSG

	void	GEN_VALUE_APPLY_MSG(
			WWFixedAsDWord		value,
			word		stateFlags);

This prototype defines the message sent out when the GenValue is "applied." 
The output of the GenValue should handle a message with these parameters.

**Source:** GenValue, when "applied."

**Destination:** The GenValue's output (*GVLI_destination*) object.

**Parameters:**  
*value* - The current value of the GenValue.

*stateFlags* - The **GenValueStateFlags** stored in 
*GVLI_stateFlags*.

**Return:** Nothing.

**Interception:** The destination object should handle the apply message with this 
format.

----------
#### MSG_GEN_VALUE_GET_APPLY_MSG

	Message	MSG_GEN_VALUE_GET_APPLY_MSG();

This message returns the GenValue's *GVLI_applyMsg*. 

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** The apply message of the GenValue.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_APPLY_MSG

	void	MSG_GEN_VALUE_SET_APPLY_MSG(
			Message		message);

This message sets the apply message (in *GVLI_applyMsg*) for a GenValue.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** message	The apply message to set for the GenValue.

**Return:** Nothing.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_GET_DESTINATION

	optr	MSG_GEN_VALUE_GET_DESTINATION();

This message returns the current destination object (or process) that the 
GenValue sends its apply messages to.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** The destination optr (*GVLI_destination*) of the GenValue.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_DESTINATION

	void	MSG_GEN_VALUE_SET_DESTINATION(
			optr	dest);

This message sets the *GVLI_destination* field of the range to the passed optr. 
The object can be a pointer to a specific object in the system (i.e. the 
GenProcess object) or can be a pointer to a generic location in the system (i.e. 
a **TravelOption**). 

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*dest* - The optr of the new destination object.

**Return:** Nothing.

**Interception:** Generally not intercepted.

## 8.4 Supplemental Usage

Besides altering instance data, there are several other messages and 
mechanisms for your use in **GenValueClass**. 

### 8.4.1 Adjusting the Value Indirectly

	MSG_GEN_VALUE_INCREMENT, MSG_GEN_VALUE_DECREMENT, 
	MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM, 
	MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM

To increase the value of *GVLI_value* by the increment in *GVLI_increment*, 
send the GenValue MSG_GEN_VALUE_INCREMENT. To decrease the value of 
GVLI_value by the increment in *GVLI_increment*, send the GenValue 
MSG_GEN_VALUE_DECREMENT. These messages are equivalent to clicking 
on the UI controls provided to increment or decrement the GenValue (usually 
up and down arrows). Both of these messages clear the indeterminate state 
of the object and *do not change* its modified state. 

To set the value of *GVLI_value* to the minimum in *GVLI_minimum*, send the 
GenValue MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM. To set the value of 
*GVLI_value* to the maximum in *GVLI_maximum*, send the GenValue 
MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM.Both of these messages clear 
the indeterminate state of the GenValue and do not change its modified state. 

Note that HINT_VALUE_NOT_INCREMENTABLE has no effect on these 
messages; that hint only removes any user controls for incrementing or 
decrementing a value.

----------
#### MSG_GEN_VALUE_INCREMENT

	void	MSG_GEN_VALUE_INCREMENT();

This message increases the value of *GVLI_value* within the GenValue by the 
increment in *GVLI_increment*. This message will clear the indeterminate flag 
of the GenValue but will not affect its modified flag.

**Source:** Unrestricted. This message is also used internally when responding to 
user actions.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** Nothing. *GVLI_value* will be incremented (or set to the maximum if 
increasing the value would push it over the maximum).

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_DECREMENT

	void	MSG_GEN_VALUE_DECREMENT();

This message decreases the value of *GVLI_value* within the GenValue by the 
increment in *GVLI_increment*. This message will clear the indeterminate flag 
of the GenValue but will not affect its modified flag.

**Source:** Unrestricted. This message is also used internally when responding to 
user actions.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** Nothing. *GVLI_value* will be decremented (or set to the minimum if 
decreasing the value would push it below the minimum).

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM

	void	MSG_GEN_VALUE_SET_VALUE_TO_MINIMUM();

This message sets the value of *GVLI_value* to the minimum value in 
*GVLI_minimum*. This message will clear the indeterminate flag of the 
GenValue but will not affect its modified flag.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** Nothing. *GVLI_value* will be set to *GVLI_minimum*.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM

	void	MSG_GEN_VALUE_SET_VALUE_TO_MAXIMUM();

This message sets the value of *GVLI_value* to the maximum value in 
*GVLI_maximum*. This message will clear the indeterminate flag of the 
GenValue but will not affect its modified flag.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** Nothing. *GVLI_value* will be set to *GVLI_maximum*.

**Interception:** Generally not intercepted.

###8.4.2 Status Messages

	ATTR_GEN_VALUE_STATUS_MSG, MSG_GEN_VALUE_SEND_STATUS_MSG

If your GenValue is operating in delayed mode, there usually occur times 
when your GenValue's state may not reflect the most recent changes. In most 
cases this is fine, but in some cases you may wish other UI objects to be 
notified of a change in your GenValue's state *without* sending out an apply 
message. This can be done with a status message. 

A status message allows your GenValue to send out a message whenever the 
user interacts with the GenValue, regardless of whether that change will be 
immediately applied. This is most useful for cases in which two UI objects are 
representing information that depends on each other. The status message 
allows one UI object to inform its friend that its state has changed, and that 
the friend should change its state to reflect the new information.

To give a GenValue a status message, include 
ATTR_GEN_VALUE_STATUS_MSG in the object's declaration. Use the 
prototype GEN_VALUE_STATUS_MSG to define your status message. This 
prototype ensures that the status message passes the correct parameters 
(the current value and state flags of the GenValue).

Any user changes that do not result in the sending of the object's apply 
message will result in the sending of the object's status message. For an 
object in immediate mode, this ATTR will have no effect. You may also 
manually send an object's status message by sending the GenValue 
MSG_GEN_VALUE_SEND_STATUS_MSG.

----------
#### GEN_VALUE_STATUS_MSG

	void	GEN_VALUE_STATUS_MSG(
			WWFixedAsDWord		value,
			word				stateFlags);

This prototype should be used to define the status message of the GenValue.

**Source:** The GenValue, when its status message is sent.

**Destination:** The GenValue's destination object (*GVLI_destination*).

**Parameters:**  
*value* - The current user value of the GenValue.

*stateFlags* * The current value of GVLI_stateFlags.

**Return:** Nothing.

**Interception:** Must be handled by the output object if the status message is to have 
any effect.

----------
#### MSG_GEN_VALUE_SEND_STATUS_MSG

	void	MSG_GEN_VALUE_SEND_STATUS_MSG(
			Boolean		modifiedState);

This message sends the status message stored in the object's 
ATTR_GEN_VALUE_STATUS_MSG instance field. You should pass this 
message the modified State you wish to send. This modified state may or not 
reflect the GVSF_MODIFIED flag in the GenValue's *GVLI_stateFlags*.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*modifiedState*	TRUE if this message should pass the modified bit 
(GVSF_MODIFIED) set, FALSE if it should pass 
GVSF_MODIFIED cleared.

**Return:** Nothing.

**Interception:** Generally not intercepted.

### 8.4.3 Retrieving Text

	MSG_GEN_VALUE_GET_VALUE_TEXT, 
	MSG_GEN_VALUE_SET_VALUE_FROM_TEXT, 
	MSG_GEN_VALUE_GET_MAX_TEXT_LEN, 
	MSG_GEN_VALUE_SET_MAX_TEXT_LEN, MSG_GEN_VALUE_SELECT_TEXT

The GenValue's numeric values are displayed within a special text field. In 
addition to retrieving the numeric value of the GenValue, you may also 
retrieve the textual representation of that number with 
MSG_GEN_VALUE_GET_VALUE_TEXT. Similarly, you can set the value of the 
GenValue from a textual representation with 
MSG_GEN_VALUE_SET_VALUE_FROM_TEXT.

You must pass these messages a **GenValueType** which specifies the 
instance data field you are wishing to set or get. The **GenValueType** types 
are:

	typedef enum /* word */ {
		GVT_VALUE,			/* GVLI_value */
		GVT_MINIMUM,		/* GVLI_minimum */
		GVT_MAXIMUM,		/* GVLI_maximum */
		GVT_INCREMENT,		/* GVLI_increment */
		GVT_LONG,			/* Longest value we can
							 * create. */
		GVT_RANGE_LENGTH,	/* End of the displayed
							 * range, if applicable. */
		GVT_RANGE_END,		/* Last value in the range,
							 * if applicable. */
		GVT_VALUE_AS_RATIO_OF_AVAILABLE_RANGE
							/* The current value, 
							 * relative to minimum. */
	} GenValueType;

Some special subclasses of the GenValue will want to calculate how many 
characters it will allow the user to type into its text field. By default, the 
number of characters is determined by the maximum and minimum values, 
but subclasses can handle MSG_GEN_VALUE_GET_MAX_TEXT_LEN to set it 
specifically. This message is sent by the range to itself when deciding how big 
the text field should be. The maximum text length allowed is thirty 
characters long.

If you wish to select a GenValue's text, send the GenValue 
MSG_GEN_VALUE_SELECT_TEXT. The specific UI has final say on whether it 
allows a GenValue to exhibit selectable text.

----------
#### MSG_GEN_VALUE_GET_VALUE_TEXT

	void	MSG_GEN_VALUE_GET_VALUE_TEXT(
			char				*buffer,
			GenValueType		valueType);

This message retrieves a fixed point value (either *GVLI_value*, 
*GVLI_minimum*, *GVLI_maximum*, or *GVLI_increment*) from the GenValue 
and stores its textual representation (in a null-terminated text string) in the 
passed buffer. This message is not affected by the indeterminate state of the 
GenValue.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*buffer* - The pointer to the buffer to store the 
null-terminated text string. This buffer must be at 
least GEN_VALUE_MAX_TEXT_LEN bytes long.

*valueType* - The *GenValueType*, specifying the instance data 
to retrieve and convert into text.

**Return:** Nothing. The *buffer* will be filled in with text.

**Interception:** Can be intercepted by a subclass of GenValue to allow custom text 
formats to be displayed on the screen. In this case you would also 
subclass MSG_GEN_VALUE_SET_VALUE_FROM_TEXT.

----------
#### MSG_GEN_VALUE_SET_VALUE_FROM_TEXT

	void	MSG_GEN_VALUE_SET_VALUE_FROM_TEXT(
			char				*text,
			GenValueType		valueType);

This message sets a fixed point value (either *GVLI_value*, *GVLI_minimum*, 
*GVLI_maximum*, or *GVLI_increment*) of the GenValue from a textual 
representation (in a null-terminated text string) in the passed buffer. This 
message clears the indeterminate state of the GenValue but does not change 
its modified state.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*text* * The pointer to a null-terminated text string to set 
the GenValue's text to.
*
valueType* - The **GenValueType**, specifying the instance data 
to convert into a fixed point value from the passed 
text.

**Return:** Nothing. The instance field will be updated.

**Interception:** Can be intercepted by a subclass of GenValue to allow custom text 
formats to be displayed on the screen. In this case, you would also 
subclass MSG_GEN_VALUE_GET_VALUE_TEXT.

----------
#### MSG_GEN_VALUE_GET_TEXT_LEN

	byte	MSG_GEN_VALUE_GET_TEXT_LEN();

This message may be used by subclasses to determine the number of 
characters the user is allowed to type into the GenValue's text field.

**Source:** The GenValue object, when calculating its size.

**Destination:** Sent to self.

**Parameters:** None.

**Return:** The number of characters of text the user will be allowed to type into 
the GenValue's text field.

**Interception:** Subclasses may intercept this message to return a specific number of 
characters; there is no need to call the superclass.

----------
#### MSG_GEN_VALUE_GET_MAX_TEXT_LEN

	byte	MSG_GEN_VALUE_GET_MAX_TEXT_LEN();

This message retrieves the maximum number of characters allowed to be 
typed into a textual GenValue. By default, this number is calculated from the 
minimums and maximums specified. Subclasses of GenValue may wish to 
intercept this message to allow different text lengths (such as values 
represented with floating point or enumerated type instance data).

**Source:** The GenValue object sends this to itself when it needs to figure out its 
maximum text length.

**Destination:** Itself.

**Return:** Maximum number of allowable characters

**Interception:** May be intercepted to allow different text lengths.

----------
#### MSG_GEN_VALUE_SELECT_TEXT

	void	MSG_GEN_VALUE_SELECT_TEXT();

This message selects a GenValue's text, if allowed by the specific UI.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Interception:** Generally not intercepted.

### 8.4.4 Using Value Ratios

	MSG_GEN_VALUE_GET_VALUE_RATIO, 
	MSG_GEN_VALUE_SET_VALUE_FROM_RATIO

Instead of setting or getting a specific value, you may want in some cases to 
set or get a value as a ratio; this ratio is determined as the percentage of the 
difference between the minimum and maximum. For example, if the 
minimum of a GenValue is 10 and the maximum is 100, the 50% ratio would 
be 55 (halfway between 10 and 100).

To retrieve the value of a GenValue as a ratio, send it 
MSG_GEN_VALUE_GET_VALUE_RATIO. This message will return the ratio as 
a dword value. You must also pass this message the **GenValueType** telling 
it which instance data you wish to retrieve.

To set a value within a GenValue as a ratio, send it 
MSG_GEN_VALUE_SET_VALUE_RATIO, passing it the ratio and the 
GenValueType (instance data field) to set. The correct value will be 
computed and set within your GenValue's instance data.

----------
#### MSG_GEN_VALUE_GET_VALUE_RATIO

	WWFixedAsDword MSG_GEN_VALUE_GET_VALUE_RATIO(
		GenValueType		valueType);

This message gets the value of a GenValue (*GVLI_value*) as a ratio of its 
distance between the minimum value and the maximum value. It returns 
this ratio as a dword (0000.0000h meaning 0%, ffff.ffffh meaning 100%).

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*valueType* - **GenValueType** of the instance data field to get the 
value ratio for.

**Return:** The ratio as a dword.

**Interception:** You may intercept subclasses of GenValueClass to allow custom text 
formats to be displayed on the screen. Someone subclassing this 
message for this reason would also want to subclass 
MSG_GEN_VALUE_SET_VALUE_FROM_TEXT to correctly parse text to 
yield a new value.

----------
#### MSG_GEN_VALUE_SET_VALUE_RATIO

	void	MSG_GEN_VALUE_SET_VALUE_RATIO(
			WWFixed				ratio,
			GenValueType		valueType);

This message sets the value (*GVLI_value*) of a GenValue as a ratio of the 
distance between its minimum and the maximum values. This ratio should 
be in the form of a dword (0000.0000h meaning 0%, ffff.ffffh meaning 100%).

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*ratio* - The dword ratio value.

*valueType* - The GenValueType of the instance data to set as 
a ratio.

**Return:** Nothing.

**Interception:** Generally not intercepted.

### 8.4.5 Text Filters for the GenValue

	MSG_GEN_VALUE_GET_TEXT_FILTER

One of the GenValue's components is a text field to enter values into. When 
this visual component is being built, the GenValue will send 
MSG_GEN_VALUE_GET_TEXT_FILTER to itself to set up a text filter. A text 
filter allows a textual object to accept or reject certain characters on a 
number of bases. The default **VisTextFilter** provides numeric-only filtering 
with no spaces and no tabs on GVDF_INTEGER or GVDF_DECIMAL display 
formats; no tabs on distance unit display formats.

You may set up your own filter by intercepting this message and returning a 
**VisTextFilter** of your own choosing.

----------
#### MSG_GEN_VALUE_GET_TEXT_FILTER

	VisTextFilter MSG_GEN_VALUE_GET_TEXT_FILTER();

This message retrieves the text filtering in use on a GenValue object. By 
default, GenValues use numeric-only filtering with no spaces and no tabs for 
numbers and a filtering of no tabs for distance units.

**Source:** Unrestricted. This message is normally sent by a GenValue to itself 
when building its textual component.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** **VisTextFilter** in use by the textual portion of the GenValue.

**Interception:** Usually, you will want to intercept this message if you subclass 
**GenValueClass** and provide your own custom filtering.

### 8.4.6 Using Ranges in GenValues

	HINT_VALUE_DISPLAYS_RANGE, 
	MSG_GEN_VALUE_SET_RANGE_LENGTH, 
	MSG_GEN_VALUE_GET_RANGE_LENGTH, 
	MSG_GEN_VALUE_ADD_RANGE_LENGTH, 
	MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH

Special GenValue objects may actually display ranges rather than individual 
values within a range-for example, the GEOS scrollbars in OSF/Motif 
display the percentage of the document visible in the view.

For your GenValue to display a range, use HINT_VALUE_DISPLAYS_RANGE. 
If this hint is not present, the GenValue is assumed to have a range size of 
zero. This hint takes an argument of **WWFixedAsDWord** to indicate the size 
of the range.

To get the range length, use MSG_GEN_VALUE_GET_RANGE_LENGTH. To set 
the range, use MSG_GEN_VALUE_SET_RANGE_LENGTH. Two other 
messages, MSG_GEN_VALUE_ADD_RANGE_LENGTH and 
MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH, add or subtract the value of 
the GenValue by the range length.

----------
#### MSG_GEN_VALUE_GET_RANGE_LENGTH

	WWFixedAsDWord MSG_GEN_VALUE_GET_RANGE_LENGTH();

This message returns the value stored in HINT_VALUE_DISPLAYS_RANGE.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:** None.

**Return:** The value stored in HINT_VALUE_DISPLAYS_RANGE. If this hint is not 
set, the return value will be zero.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SET_RANGE_LENGTH

	void	MSG_GEN_VALUE_SET_RANGE_LENGTH(
			WWFixedAsDWord value);

This message has the effect of adding or changing the hint 
HINT_VALUE_DISPLAYS_RANGE for the GenValue. Setting a value of zero 
will cause the GenValue to act as if it did not have this hint.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Parameters:**  
*value* - The new range length.

**Return:** Nothing.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_ADD_RANGE_LENGTH

	void	MSG_GEN_VALUE_ADD_RANGE_LENGTH();

This message adds the range length to the current value of the GenValue 
object. It has the effect of incrementing the *GVLI_value* field by the range 
length.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Interception:** Generally not intercepted.

----------
#### MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH

	void	MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH();

This message subtracts the range length from the current value of the 
GenValue object. It has the effect of decrementing the *GVLI_value* field by the 
range length.

**Source:** Unrestricted.

**Destination:** Any GenValue object.

**Interception:** Generally not intercepted.

[GenInteraction](ogenint.md) <-- [Table of Contents](../objects.md) &nbsp;&nbsp; --> [GenView](ogenvew.md)