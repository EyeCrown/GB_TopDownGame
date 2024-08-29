# Notes for developpement
> This document is about guidelines for developpement to avoid forget it

## FPS Check
The FPS value is contained in **wFrameCounter**. Its value is between *0* and *255* since 256 is 60 * 4.
If you want to use it be aware of multiply your calculation by 4.