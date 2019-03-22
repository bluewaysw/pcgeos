## Troubleshooting Communications

The SDK install scripts work well for those programmers who know which 
COM ports and IRQ levels their machines will use when communicating. 
However, when something goes wrong with this process, it can be very 
difficult to determine the correct combination of port and interrupt numbers. 
This chapter contains a systematic way to determine the correct 
configuration to use.

Most developers should not need to read this chapter. You should only read 
this chapter if you have been referred here from another part of this book.

**The Cables**

Your machines should be connected by a null-modem serial line. Lap-link 
cable works admirably for this purpose. 

At some point as you try to set up communications between your machines, 
you may think that things should be working, but they aren't. Under these 
circumstances, a judicious jiggle to the cable's connections may prove helpful.

**The Settings**

Communications between machines are controlled by some settings on both 
machines. To get communication working, you will be working with these 
settings.

+ The COM port setting tells the pccom tool which serial port the serial 
communication cable is plugged into. This value can range from one to 
four. 

+ The communication speed determines how quickly your machines will 
try to communicate. We suggest a speed of 19200 baud; if one of your 
machines (presumably your target machine) is slow, you may have to use 
9600 baud instead.

+ Each COM port has an IRQ level associated with it. If you try to send a 
signal to a COM port using the wrong IRQ level, your machine tends to 
generate some bad interrupts and freeze. Thus, if you do not know the 
IRQ level associated with a COM port, but discover it through 
trial-and-error, you may want to note it down in case you ever need to use 
another COM port. 

**Setting and Overriding the PTTY variable**

For the communication software to work correctly, both your target and host 
machines must have a correctly set PTTY variable. Type set on both 
machines to find out what the present value is for PTTY. The set command 
should return output that includes a line that looks something like the 
following (the numbers may be different):

~~~
PTTY=1,19200,4
~~~

or

~~~
PTTY=1,19200
~~~

If you are reading this chapter, then at least one of these values on at least 
one of your machines has probably been set incorrectly. 

+ The first number of this variable signals which COM port this machine will 
use to communicate. This value may be different between machines. Your 
connection may be between your host's port 1 and your target's port 2. 
This number must be an integer between one and four.

+ The second number specifies the communication speed, measured in 
baud. This value must be the same on both machines. 

+ The third number, if any, specifies the IRQ level to use when 
communicating. If there is no third number, then it is assumed that you 
are using the IRQ level normally associated with the given COM port. (I.e. 
if the first number of your PTTY variable is 1 or 3, the communication 
software will assume you want to use IRQ level 4. If the first number of 
your PTTY variable is 2 or 4, IRQ level 3 is assumed.)

To change your PTTY variable, issue the command

~~~
set ptty=1,19200,4
~~~

or

~~~
set ptty=1,19200
~~~

Note that there are no spaces in this command other than that between "set" 
and "ptty". If you include a space before the equals sign, you are actually 
setting the value of a new variable, "PTTY  " (PTTY with a space after it). If 
you place a space after the equals sign, the communication software won't be 
able to interpret the value. Nor should there be spaces after the commas.

When you have figured out the correct values to use when communicating, 
you will want to make sure there is a line in your AUTOEXEC.BAT file that 
sets the variable correctly.

When invoking the pccom tool, you can override the values set by the PTTY 
variable by passing the /c, /b, and /I flags. For instance, typing

~~~
pccom /c:2 /b:9600 /I:3
~~~

will invoke the pccom tool using COM port 2, IRQ level 3, and a 9600 baud 
communication rate, no matter what values have been set in the PTTY 
variable.

**Step 1: Make Your Best Guess**

When you troubleshoot your communication set-up, the most difficult 
problem to solve is the case where you don't know which COM port either 
machine is using. If you are in this situation now, some research might be in 
order. The documentation of one or more of your machines should contain a 
clue as to which COM port number is associated with a particular serial 
socket. If you have another device which you know uses a serial port, then 
you can be sure that the cable is not hooked up to that port. Thus, if you know 
that your target machine has a mouse plugged into serial port two, you know 
that you will not be communicating with a COM port number of two. 

If you narrow down the COM port choices now, you will save yourself a lot of 
time in the steps to follow.

**Step 2: Invoke pccom on Both Machines**

At the DOS prompt, type "pccom" on both machines. If you are passing flags 
to the pccom tool at either machine, now is the time to pass them. As you 
continue with troubleshooting, you will probably have to exit the pccom tool 
on one or both machines several times to change COM port and IRQ level 
settings. Always remember to start up the pccom tool again, as no 
communication will take place if it is only running on one machine.

**Step 3+: Type "abc" On The Host Machine**

Depending on what happens when you do this, you can narrow in on your 
communication problem.

"abc" appears on the Target (i.e. the other) machine-Success!
You have found the correct communication settings. Edit your 
AUTOEXEC.BAT files so that your PTTY variables will be set 
correctly when you next restart your machines. If you have 
been experimenting with communications settings, you may 
wish to change your PTTY variables immediately, or just restart 
your machines after changing the AUTOEXEC.BAT files.

"???" appears on the Host (i.e. the same) machine-Incorrect cables.
You do not have a null-modem connection in the serial line 
between your machines. The null-modem acts like a telephone 
line, making the host's "mouth" talk to the target's "ear," and 
that the target's "mouth" talks to the host's "ear." Without the 
null-modem connection, your machines will act as if they are 
talking on the phone, but one of them is holding their receiver 
upside down-listening at the mouthpiece and talking into the 
earpiece. Your host's voice is being echoed back into its own 
"ears," getting corrupted in the process. Use a null-modem 
connection.

The good news is that your signal is in fact reaching the cable, 
and thus your host machine is using the correct COM port and 
IRQ level settings.

"a" on Target, Host frozen-Everything's correct except IRQ level.
The host successfully transmitted the "a" to the target. The 
target machine listened at the right port and sent back a signal 
that it was ready for the next character. The host received this 
signal, but could not handle it and froze. Try a different IRQ 
level for your host (by using a different number for the third 
part of your host's PTTY variable or by using the /I: flag when 
next invoking the pccom tool on the host machine).
Before continuing with tests, "unfreeze" your host by restarting 
it. (You probably had to do this to change the IRQ level anyhow.)

No text appears, Host is frozen-Host IRQ level is wrong.
The IRQ level you have chosen to use with your host's COM port 
is not correct for that COM port. Note that there is no guarantee 
that you have chosen the correct COM port number either. Try 
using a different IRQ level, and when you find the correct one 
for that COM port, you might want to note it down.
Before continuing with tests, "unfreeze" your host by restarting 
it. (You probably had to do this to change the IRQ level anyhow.)

No text appears, Host not frozen, Target Frozen-Target IRQ wrong.
You've almost achieved the right settings; your host machine is 
sending the signal correctly, and your target machine is 
listening at the right port. However, your target machine is 
getting confused when the signal comes in. Change the IRQ 
level setting on your target machine, either by changing the 
PTTY variable, or by passing an /I: flag to the pccom tool.
Before continuing with tests, "unfreeze" your target by 
restarting it. (You probably had to do this to change the IRQ 
level anyhow.)

No text appears, Neither machine frozen-Wrong COM port.
The host machine successfully sent the signal to the COM port 
you selected. However, the signal never got to the target 
machine. Either the host's COM port setting was wrong, so that 
the signal was sent to the wrong port and never reached the 
cable; or the target's COM port was wrong, so that it was 
listening at the wrong port. It is possible that in fact both 
machines have the wrong COM port settings.

Try using different COM port settings on one or both machines. 
(Do this by changing the first part of your PTTY variable or by 
passing a /c: flag to the pccom tool.) Of course, if you are rather 
sure about which COM port one of the machines is using, you 
should try changing the other one's settings first.
Remember that the COM port value may be 1, 2, 3, or 4. If you 
know that some device is already using a port, than you need 
not test that port (assuming you haven't somehow managed to 
plug a serial cable and some other device into the same serial 
port socket).

If you're unsure about your target machine settings, you might 
try reversing these tests, typing "abc" on the target machine to 
see what happens. The pccom communication is 
bi-directional, so you may use the above tests just as well, 
substituting the word "host" for "target," and vice versa.

[Documents and Displays](Documents_and_Displays.md) <-- &nbsp;&nbsp; [table of contents](../Tutorial.md) 
