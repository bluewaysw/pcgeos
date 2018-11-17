#!/bin/sh -
##############################################################################
#
#	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	World Clock
# FILE:		xfig2asmfile.nawk
# AUTHOR:	Larry Warner
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	LEW	10/15/96	Initial Revision
#
# DESCRIPTION:
#
#	Generates World Clock Time Zone data from
#	tzsmall.fig, which is a text file containing polygon descriptions.
#
#	Usage: xfig2asmfile.nawk newPixelWidth newPixelHeight leftMeridian
#
#	$Id: xfig2asmfile.nawk,v 1.2 96/10/21 18:23:43 warner Exp $
#
###############################################################################
#
PATH=/usr/bin:/usr/ucb
export PATH

if [ $# -ne 3 ]; then
	echo "Usage: $0 newPixelWidth newPixelHeight leftMeridian"
	echo " where newPixelWidth and newPixelHeight describe the bitmap"
	echo " you have, and leftMeridian is the meridian at the left edge"
	echo " of your map, in degrees."
	exit
fi

nawk '

BEGIN \
{
# These come in from the command line:
    newPixelWidth = '"$1"'
    newPixelHeight = '"$2"'
    leftMeridian = '"$3"'

# Various useful things:
    polygonIdx = 0

    northLat = 85
    southLat = -60
    radianSouthLat = -1.04720

# Miller-projected values of northLat and southLat:
    millerTop = 2.0474
    millerBottom = -1.1968
    millerHeight = millerTop - millerBottom

    xfigLeft = 75
    xfigRight = 9525
    xfigGreenwich = 4425
    xfigTop = 150
    xfigBottom = 4950
    xfigEquator = 3225
    xfigWidth = xfigRight - xfigLeft
    xfigHeight = xfigBottom - xfigTop

# Vertical fraction (in unprojected degrees) of the map we are using,
# w.r.t. the total possible number of vertical degrees (180)
    verticalFraction =	(northLat - southLat) * 3.14159265358923 / 180.0

    pixelGreenwich = newPixelWidth * (xfigGreenwich - xfigLeft) / xfigWidth

# My xfig data is based on a left-edge of -167.5 degrees:
    pixelXRotator = newPixelWidth * (leftMeridian + 167.5) / 360.0 

    # Hours of each time zone:
    Hr[ 1]= 3; Hr[ 2]= 1; Hr[ 3]= 2; Hr[ 4]= 3; Hr[ 5]= 7; Hr[ 6]= 8;
    Hr[ 7]= 9; Hr[ 8]=10; Hr[ 9]=11; Hr[10]=12; Hr[11]=13; Hr[12]=14;
    Hr[13]=15; Hr[14]=16; Hr[15]=16; Hr[16]=15; Hr[17]=16; Hr[18]=15;
    Hr[19]=17; Hr[20]=17; Hr[21]=17; Hr[22]=18; Hr[23]=16; Hr[24]=17;
    Hr[25]=19; Hr[26]=22; Hr[27]=18; Hr[28]=18; Hr[29]=18; Hr[30]=17;
    Hr[31]=19; Hr[32]=20; Hr[33]=23; Hr[34]=21; Hr[35]=21; Hr[36]=21;
    Hr[37]=22; Hr[38]=24; Hr[39]=23; Hr[40]= 1; Hr[41]= 6; Hr[42]= 4;
    Hr[43]= 5; Hr[44]=21;

    # Minutes of each time zone:
    Mn[ 1]=0; Mn[ 2]=0; Mn[ 3]= 0; Mn[ 4]= 0; Mn[ 5]= 0; Mn[ 6]= 0;
    Mn[ 7]=0; Mn[ 8]=0; Mn[ 9]= 0; Mn[10]= 0; Mn[11]= 0; Mn[12]= 0;
    Mn[13]=0; Mn[14]=0; Mn[15]= 0; Mn[16]=30; Mn[17]=30; Mn[18]= 0;
    Mn[19]=0; Mn[20]=0; Mn[21]=30; Mn[22]= 0; Mn[23]= 0; Mn[24]= 0;
    Mn[25]=0; Mn[26]=0; Mn[27]= 0; Mn[28]= 0; Mn[29]=30; Mn[30]=30;
    Mn[31]=0; Mn[32]=0; Mn[33]= 0; Mn[34]= 0; Mn[35]=30; Mn[36]= 0;
    Mn[37]=0; Mn[38]=0; Mn[39]= 0; Mn[40]= 0; Mn[41]= 0; Mn[42]= 0;
    Mn[43]=0; Mn[44]=0;
}

func rnd(t)
{
	if (t >= 0)
		return int(t + 0.5)
	else
		return int(t - 0.5)
}

func sinh(t)
# We will perform an "Inverse Miller" projection on the y-values 
# so we need to define the sinh function.  The full formula is implemented
# in the ytransform function below.
{
	return ( exp(t) - exp(-t) ) / 2.0
}


func xtransform(x)
# xtransform is fortunately simple; just have to do a little translating and
# scaling
{

	x = (x-xfigGreenwich) * newPixelWidth/xfigWidth + pixelGreenwich

	# Make sure we have no negatives or overruns, and add the
	# pixelXRotator to shift to the desired standard meridian:
	x = rnd(x)
	x = (x - pixelXRotator + newPixelWidth) % newPixelWidth
	
	return x
}

func ytransform(y) {
	# First, linear mapping from [xfigTop, xfigBottom] to the 
	# Miller-projected values for [-60, 85]:
	y = (xfigEquator - y) * millerHeight / xfigHeight
	
	# Next, the inverse Miller projection formula to get radians on 
	# a linear scale:
	y = 1.25 * atan2 (sinh(0.8 * y), 1) 

        # Now we translate and scale again to get to [0, newPixelHeight]:
	y = newPixelHeight - (y - radianSouthLat) * newPixelHeight / verticalFraction + 1
	
	return rnd(y)
}


{
    if ($1 == "2" && $2 == "3" && $3 == "0" && $4 == "1" )  {
        # This is the signature header of a polygon in xfig 3.1 format.
        numpoints = $16
        polygonIdx++
	pointsBlock = ""
        leftmost=99999
        rightmost=-99999

        for (i = 0; i < numpoints; ) {
            getline
            i += NF/2
            thisLineLen = split($0, coords)

	    for (j = 1; j <= thisLineLen; j += 2)  {
		pointsBlock = pointsBlock sprintf \
	             ("DefTimeZonePoint\t%4d, %4d\n",
		     x1 = xtransform(coords[j]),
		          ytransform(coords[j+1]))
		if (x1 < leftmost) {
		    leftmost = x1
		}
		if (x1 > rightmost) {
		    rightmost = x1
		}
	    }
        }

        # Watch out for any polys with very wide ranges - this indicates
	# that the polygon has been wrapped around the full width of the
	# map.  We will create two copies of these polygons, one at the
	# left and one at the right, and GEOS will clip them to the
	# rectangular world map for us.
	wrappedPoly = 0
	tailString=""
	
        if ( (rightmost - leftmost) > newPixelWidth / 2) {
	    tailString = "left"
	    wrappedPoly = 1
        }

        printf"StartTimeZone\t%d_%s, %d, %d, %d, %d\n", 
            polygonIdx, tailString, Hr[polygonIdx], Mn[polygonIdx],
	    leftmost, rightmost
	printf "%s", pointsBlock
	printf"EndTimeZone\t%d_%s\n\n", polygonIdx, tailString
	if (wrappedPoly)  {
	    tailString = "right"
	    printf"StartTimeZone\t%d_%s, %d, %d, %d, %d\n", 
		polygonIdx, tailString, Hr[polygonIdx], Mn[polygonIdx],
		leftmost, rightmost
	    printf "%s", pointsBlock
	    printf"EndTimeZone\t%d_%s\n\n", polygonIdx, tailString
	}
    } 
}'	|\

# One more pass to handle the wrapped polygons.  The polygons
# marked "left" will have their larger x values "unwrapped" to be small,
# and the "right" polygons will have their smaller x values "unwrapped" to
# be large.
nawk '
BEGIN \
{
    newPixelWidth = '"$1"'
}

func moveLeft(n)  {
    if (n ~ /,/) {
	n = substr(n, 1, length(n)-1)
    }
    n += 0
    if (n > newPixelWidth / 2) {
	return (n - newPixelWidth)
    } else {
	return n
    }
}

func moveRight(n)  {
    if (n ~ /,/) {
	n = substr(n, 1, length(n)-1)
    }
    n += 0
    if (n < newPixelWidth / 2) {
	return (n + newPixelWidth)
    } else {
	return n
    }
}

NF == 6 && $2 ~ /left/ \
{
    block = ""
    header = ""
    leftmost=99999
    rightmost=-99999
    header = sprintf("%s\t%s %s %s", $1, $2, $3, $4)
    getline
    while ($1 ~ /DefTimeZonePoint/) {
	block=block sprintf("%s\t%4d, %4d\n",$1,x1=moveLeft($2), $3)
	if (x1 < leftmost) {
	    leftmost = x1
	}
        if (x1 > rightmost) {
            rightmost = x1
	}
	getline
    }
    block = block sprintf("%s\n\n", $0)
    printf("%s %4d, %4d\n", header, leftmost, rightmost)
    print block
}

NF == 6 && $2 ~ /right/ \
{
    block = ""
    header = ""
    leftmost=99999
    rightmost=-99999
    header = sprintf("%s\t%s %s %s", $1, $2, $3, $4)
    getline
    while ($1 ~ /DefTimeZonePoint/) {
	block=block sprintf("%s\t%4d, %4d\n",$1,x1=moveRight($2), $3)
	if (x1 < leftmost) {
	    leftmost = x1
	}
        if (x1 > rightmost) {
            rightmost = x1
	}
        getline
    }
    block = block sprintf("%s\n\n", $0)
    printf("%s %4d, %4d\n", header, leftmost, rightmost)
    print block
}

NF == 6 && $2 !~ /t/ \
{
    print
    getline
    while ($1 ~ /DefTimeZonePoint/) {
	print
	getline
    }
    printf("%s\n\n", $0)
}
'

