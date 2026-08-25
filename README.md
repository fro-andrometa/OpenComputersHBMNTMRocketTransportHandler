# How does this work?
Add a transposer, connect it to an extractor and the Rocket Transport Pad, and an inserter (connected to another ejector) that will lead to the rocket transport pad's insertion point.
Then, attach a spatial i/o port, with your desired dimensions on the pylons.
Power & fuel everything, the pylons, the (do not worry if something is unpowered - the main thing you need to worry about is if the computer runs out of power midwarp, as it will be unable to differentiate between an un
Hook up a redstone I/O below the spatial i/o port, connected to the computer, and attach a button (preferably accessible from within the pylons)
Load up the computer program (in main.lua), setup the other destination's computer (with same steps as this one), keep it chunk loaded, and happy warping!

# Help! How do I recover my rocket & get to my destination?
You should use an unlinker to obtain your rocket again (make sure you can link to your destination, if not, then... you won't be able to get there again; ALWAYS KEEP A TRANSPORTER PAD LINKER ON YOU!!

# What else should I know?
There should be only one spatial cell in the overall system. If you did the recovery rocket process, you must take the other spatial cell out of the extractor to prevent an infinite loop of spatial cell swapping & poewr drain.
You should always keep a transporter pad linker with all of your destinations (neatly labelled!) on you, within your backpack, or in an easily accessible AE2 system! (though if you're using a global AE2 system, why are you using this?)

Happy warping!
