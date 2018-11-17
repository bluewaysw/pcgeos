cvtpcx -G -m1 -x0 -y0 -2 -nPCStatusLightOff -w16 -h16 -ogreen.goh PR025-8.pcx
cvtpcx -G -m1 -x0 -y0 -2 -nPCStatusLightOn -w16 -h16 -ored.goh PR026-8.pcx
cvtpcx -G -m1 -x0 -y0 -2 -nPCStatusLightLimited -w16 -h16 -oyellow.goh PR024-8.pcx
cvtpcx -G -m1 -x0 -y0 -2 -nPCToggleOnHeaderIcon -w23 -h92 -ogreen2.goh PR027-8.pcx
rem cvtpcx -G -m1 -x0 -y0 -2 -nPCToggleOffHeaderIcon -w23 -h92 -ored2.goh PR028-8.pcx
rem use PR029 (yellow->green) instead of PR028 (red->green)
cvtpcx -G -m1 -x0 -y0 -2 -nPCToggleOffHeaderIcon -w23 -h92 -ored2.goh PR029-8.pcx
cvtpcx -G -m1 -x0 -y0 -2 -nSecureStatusOff -w16 -h16 -ounlock.goh GI036-8.pcx
cvtpcx -G -m1 -x0 -y0 -2 -nSecureStatusOn -w16 -h16 -olock.goh GI035-8.pcx
cvtpcx -G -m225 -x0 -y0 -2 -nGPCZoom100Icon -w27 -h16 -Stool -stiny -oA111-8.goh A111-8.pcx
cvtpcx -G -m225 -x0 -y0 -2 -nGPCZoomOutIcon -w18 -h16 -Stool -stiny -oA113-8.goh A113-8.pcx
cvtpcx -G -m225 -x0 -y0 -2 -nGPCZoomInIcon -w18 -h16 -Stool -stiny -oA114-8.goh A114-8.pcx

