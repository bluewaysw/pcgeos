##############################################################################
#
# 	Copyright (c) GeoWorks 1995 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	snap.tcl
# AUTHOR: 	Yo' Mama, 16 May 1995
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	snap			Diss'es yo' mama.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	mom	16 may 95	initial revision
#
# DESCRIPTION:
#
#	$Id: snap.tcl,v 1.1.10.1 97/03/29 11:25:43 canavese Exp $
#
###############################################################################

##############################################################################
#				snap
##############################################################################
#
# SYNOPSIS:	Have your debugger insult your mother.
# PASS:		
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	user possibly pissed
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	mom	16 may 95	initial snap
##############################################################################
[defcmd snap {args} {top.crash}
{Usage:
    snap [<subject>]

Examples:
    "snap"    		Comment on your mother.
    "snap fat"  	Comment on your mother's weight.
    "snap stupid"  	Comment on your mother's IQ.
    "snap old"  	Comment on your mother's age.
    "snap ugly"  	Comment on your mother's beauty.
    "snap nasty"  	Comment on your mother's je ne sais quoi.
    "snap poor"  	Comment on your mother's economic status.

Synopsis:
    Echoes a comment about your mother to the screen.

Notes:
    * Yes, this program personally knows yo' mama.

See also:
    Yo' sister.
}
{
    global fatSnaps
    global stupidSnaps
    global oldSnaps
    global uglySnaps
    global nastySnaps
    global poorSnaps
    global allSnaps

    if {[null $args]} {
	echo [index $allSnaps [expr [expr [history cur]*[history cur]]%[length $allSnaps]]]
    } else {
	[case $args in
	    fat {
		echo [index $fatSnaps [expr [history cur]%[length $fatSnaps]]]
	    }
	    stupid {
		echo [index $stupidSnaps [expr [history cur]%[length $stupidSnaps]]]
	    }
	    old {
		echo [index $oldSnaps [expr [history cur]%[length $oldSnaps]]]
	    }
	    ugly {
		echo [index $uglySnaps [expr [history cur]%[length $uglySnaps]]]
	    }
	    nasty {
		echo [index $nastySnaps [expr [history cur]%[length $nastySnaps]]]
	    }
	    poor {
		echo [index $poorSnaps [expr [history cur]%[length $poorSnaps]]]
	    }
	]
    }

}]

var fatSnaps {{Yo' mama so fat, when her beeper goes off, people thought she was backing up!}
{Yo' mama so fat, she eats Wheat *Thicks*!}
{Yo' mama so fat, people jog around her for exercise!}
{Yo' mama so fat, she went to the movies and sat next to everyone!}
{Yo' mama so fat, she was in the ocean and Spain claimed her for the new world!}
{Yo' mama so fat, she goes to a resturant, looks at the menu and says "okay!"}
{Yo' mama so fat, she got to iron her pants on the driveway!}
{Yo' mama so fat, she put on her lipstick with a paint-roller.}
{Yo' mama so fat, when she bungee jumps, she brings down the bridge too.}
{Yo' mama so fat, when she sits around the house, she SITS AROUND THE HOUSE!}
{Yo' mama so fat, when she steps on a scale, it read "one at a time, please"}
{Yo' mama so fat, she fell in love and broke it.}
{Yo' mama so fat, when she gets on the scale it says to be continued.}
{Yo' mama so fat, when she gets on the scale it says we don't do livestock.}
{Yo' mama so fat, she's got her own area code!}
{Yo' mama so fat, she looks like she's smuggling a Volkswagon!}
{Yo' mama so fat, whenever she goes to the beach the tide comes in!}
{Yo' mama so fat, her legs is like spoiled milk - white & chunky!}
{Yo' mama so fat, I had to take a train to get on her good side!}
{Yo' mama so fat, she wakes up in sections!}
{Yo' mama so fat, when she goes to an amusement park, people try to ride HER!}
{Yo' mama so fat, she rolled over 4 quarters and it made a dollar!}
{Yo' mama so fat, when she lies on the beach no one else gets sun!}
{Yo' mama so fat, when she jumps up in the air she gets stuck!!!}
{Yo' mama so fat, she's got more Chins than a Hong Kong phone book!}
{Yo' mama so fat, that her senior picture had to be aerial view!}
{Yo' mama so fat, she's on both sides of the family!}
{Yo' mama so fat, everytime she walks in high heels, she strikes oil!}
{Yo' mama so fat, she has a wooden leg with a kickstand!}
{Yo' mama so fat, she broke her leg, and gravy poured out!}
{Yo' mama so fat, she got hit by a parked car!}
{Yo' mama so fat, they have to grease the bath tub to get her out!}
{Yo' mama so fat, she has a run in her blue-jeans!}
{Yo' mama so fat, when she back up she beep.}
{Yo' mama so fat, she has to buy two airline tickets.}
{Yo' mama so fat, when she fell over she rocked herself asleep trying to get up.}
{Yo' mama so fat, she influences the tides.}
{Yo' mama so fat, that when I tried to drive around her I ran out of gas.}
{Yo' mama so fat, the animals at the zoo feed her.}
{Yo' mama so fat, when she dances at a concert the whole band skips.}
{Yo' mama so fat, the Aids quilt wouldn't cover her.}
{Yo' mama so fat, she stands in two time zones.}
{Yo' mama so fat, you have to grease the door frame and hold a twinkie on the other side just to get her through.}
{Yo' mama so fat, when she goes to an all you can eat buffet, they have to install speed bumps.}
{Yo' mama so fat, that she can't tie her own shoes.}
{Yo' mama so fat, she sets off car alarms when she runs.}
{Yo' mama so fat, when she wears a Malcolm X T-shirt, helicopters try to land on her back!}
{Yo' mama so fat, the only pictures you have of her are satellite pictures.}
{Yo' mama so fat, she put on some BVD's and by the time they reached her waist they spelled out boulevard.}
{Yo' mama so fat, that when she sits on the beach, Greenpeace shows up and tries to tow her back into the ocean.....}
{Yo' mama so fat, that she would have been in E.T., but when she rode the bike across the moon, she caused an eclipse.}
{Yo' mama so fat, she was Miss Arizona --  class Battleship.}
{Yo' mama so fat, to her "light food" means under 4 Tons.}
{Yo' mama so fat, The Himalayas are practices runs to prepare for her.}
{Yo' mama so fat, she went on a date with high heels on and came back with sandals!!!}
{Yo' mama so fat, she stepped on a talking scale and it told her to get off!!!}
{Yo' mama so fat, and stupid, her waist size is larger than her IQ!!!}
{Yo' mama so fat, she was zoned for commercial development.}}

var stupidSnaps {{Yo' mama so stupid, it took her 2 hours to watch 60 minutes.}
{Yo' mama so stupid, it took her half an hour to make minute rice.}
{Yo' mama so stupid, she threw a brick at the floor and missed.}
{Yo' mama so stupid, when she saw the NC-17 (under 17 not admitted) sign, she went home and got 16 friends.}
{Yo' mama so stupid, that she puts lipstick on her head just to make-up her mind.}
{Yo' mama so stupid, she hears it's chilly outside so she gets a bowl.}
{Yo' mama so stupid, you have to dig for her IQ!}
{Yo' mama so stupid, she got locked in a grocery store and starved!}
{Yo' mama so stupid, that she tried to put M&M's in alphabetical order!}
{Yo' mama so stupid, she could trip over a cordless phone!}
{Yo' mama so stupid, she sold her car for gasoline money!}
{Yo' mama so stupid, she bought a solar-powered flashlight!}
{Yo' mama so stupid, she thinks a quarterback is a refund!}
{Yo' mama so stupid, she took a cup to see Juice.}
{Yo' mama so stupid, she asked you "What is the number for 911"}
{Yo' mama so stupid, she got stabbed in a shoot out.}
{Yo' mama so stupid, she called Dan Quayle for a spell check.}
{Yo' mama so stupid, she stepped on a crack and broke her own back.}
{Yo' mama so stupid, she thought she needed a token to get on Soul Train.}
{Yo' mama so stupid, she took the Pepsi challenge and chose Jif.}
{Yo' mama so stupid, when you stand next to her you hear the ocean!}
{Yo' mama so stupid, she thinks Fleetwood Mac is a new hamburger at McDonalds!}
{Yo' mama so stupid, she sits on the TV, and watches the couch!}
{Yo' mama so stupid, when she went to take the 6 train, she took the 3 twice. }
{Yo' mama so stupid, she jumped out the window and went up.}
{Yo' mama so stupid, she took a umbrella to see Purple Rain.}
{Yo' mama so stupid, she watches "The Three Stooges" and takes notes.}
{Yo' mama so stupid, she couldn't read an audio book.}
{Yo' mama so stupid, it take her a week to get rid of a 24hr virus.}
{Yo' mama so stupid, it take her a day to cook a 3 minute egg.}
{Yo' mama so stupid, she has to ask for help to use hamburger helper.}
{Yo' mama so stupid, she went to Disneyworld and saw a sign that said "Disneyworld Left" so she went home.}
{Yo' mama so stupid, she asked me what kind of jeans I had on and I said "Guess" so she said Levi's.}
{Yo' mama so stupid, she called information to get the number for 411 ...}}

var uglySnaps { {Yo' mama's lips so big, ChapStick had to invent a spray.}
{Yo' mama's hair so nappy, she has to take Tylenol just to comb it.}
{Yo' mama so ugly, when she joined an ugly contest, they said "Sorry, no professionals."}
{Yo' mama so ugly, just after she was born, her mother said "What a treasure and her father said "Yes, let's go bury it."}
{Yo' mama so ugly, they push her face into dough to make gorilla cookies.}
{Yo' mama so ugly, instead of putting the bungee cord around her ankle, they put it around her neck.}
{Yo' mama so ugly, she gets 364 extra days to dress up for Halloween.}
{Yo' mama so ugly, when she walks into a bank, they turn off the surveillence cameras.}
{Yo' mama so ugly, her mom had to tie a steak around her neck to get the dogs to play with her.}
{Yo' mama so ugly, the government moved Halloween to her birthday.}
{Yo' mama so ugly, that if ugly were bricks she'd have her own projects.}
{Yo' mama so ugly, she made an onion cry.}
{Yo' mama so ugly, when they took her to the beautician it took 12 hours for a quote!}
{Yo' mama so ugly, she tried to take a bath the water jumped out!}
{Yo' mama so ugly, she looks out the window and gets arrested!}
{Yo' mama so ugly, even Rice Krispies won't talk to her!}
{Yo' mama so ugly, Ted Danson wouldn't date her!}
{Yo' mama so ugly, for Halloween she trick or treats on the phone!}
{Yo' mama so ugly, she turned Medusa to stone!}
{Yo' mama so ugly, people go as her for Halloween.}
{Yo' mama so ugly, she scares the roaches away.}
{Yo' mama so ugly, I heard that your dad first met her at the pound.}
{Yo' mama so ugly, that your father takes her to work with him so that he doesn't have to kiss her goodbye.}
{Yo' mama so ugly, she is very successful at her job: Being a scarecrow.}
{Yo' mama so ugly, she has to sneak up on a glass of water.}}

var oldSnaps {{Yo' mama so old, I told her to act her own age, and the bitch died!}
{Yo' mama so old, her social security number is 1!}
{Yo' mama so old, that when she was in school there was no history class.}
{Yo' mama so old, her birth certificate says expired on it.}
{Yo' mama so old, she knew Burger King while he was still a prince.}
{Yo' mama so old, her birth certificate is in Roman numerals.}}

var poorSnaps {{Yo' mama so poor she can't afford to pay attention!}
{Yo' mama so poor, when she goes to KFC, she has to lick other people's fingers.}
{Yo' mama so poor, when I ring the doorbell she says,"DING!"}
{Yo' mama so poor, she went to McDonald's and put a milkshake on layaway.}
{Yo' mama so poor, your family ate cereal with a fork to save milk.}
{Yo' mama so poor, her face is on the front of a foodstamp.}
{Yo' mama so poor, she wave around a popsicle stick and calls it air conditioning.}
{Yo' mama so poor, burglars break in her house and leave money.}
{Yo' mama house so small, she has to go outside to eat a large pizza.}}

var nastySnaps {{Yo' mama so nasty she made Speed Stick slow down.}
{Yo' mama so nasty, she made Right Guard turn left.}
{Yo' mama so nasty, the fishery be paying her to leave.}
{Yo' mama so nasty, she has to creep up on bathwater.}
{Yo' mama so nasty, she made Sure confused.}
{Yo' mama so nasty, Ozzie Ozbourne refused to bite her head off.}
{Yo' mama so nasty, she went swimming and now we have the dead sea.}
{Yo' mama so nasty, she look like she got Buchwheat in a headlock.}
{Yo' mama so nasty, Bigfoot is taking her picture!}
{Yo' mama so nasty, she looks like a Chia Pet with an afro!}
{Yo' mama so nasty, she shaves with a weedwhacker.}
{Yo' mama's house so nasty, she has to wipe her feet before she goes outside.}
{Yo' mama teeth are so yellow, I can't believe its not butter.}
{Yo' mama breath so bad, when she yawns her teeth duck.}}

var allSnaps [concat $fatSnaps $stupidSnaps $oldSnaps $uglySnaps $nastySnaps $poorSnaps]
