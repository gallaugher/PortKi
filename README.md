# PortKi
PortKi - (currently a Work in Progress) an iOS app for creating Kiosk-style navigation screens for the Adafruit PyPortal.

Here's a video of the PyPortal and app, in-action, briefly demonstrating features and use.
https://youtu.be/XVfCQ6XWwH4

Because it's a work-in-progress, it's not really ready for end-users who aren't comfortable diving in to code. To use this version you'll need to download the code, install cocoapods as shown in the pod file, set up an S3 and Adafruit.io account, etc. I do hope to continue to work on this & I really hope others offer suggestions / improvements / advice so I can learn, too!

To get this to work you'll need a:
- PyPortal: http://adafruit.com/pyportal
- AWS S3 accout and a publicly-readable directory named "portki-files" that is writeable by your "Portki" app [free]
- An adafruit.io account [free]

It's all still pretty raw, but it works in an alpha-beta sort of way.
The iOS code is especially gruesome - I kept changing data structures and APIs, and I haven't had a chance to refactor or clean things up. I eventually went with saving data locally, uploading JSON to Adafruit.io, and uploading JPEGs to Amazon S3. I also need to do a bunch of other things: Allow for screen deletions & moving, Allow for resizeable text boxes, and allow more than one line in a text box. 

Python code also needs some improvement & I could use some advice on several topics, including:
- creating the "portki-files" local directory if it doesn't exist at runtime. 
- detecting if the PyPortal is about to run out of space in the cache, then default to an SD Card (if installed), or provide some sort of graceful error/warning to the user. 
- being able to send a note from adafruit.io to the PyPortal so that it triggers a re-load of json & screen images.
That said, it's working pretty good for late-alpha, early-beta, and I'm ready to put this outside my office door.

I'm still pretty new to many of the concepts I've experimented here. Feedback welcome.

For more projects, see:
- https://youtube.com/GallaugherYouTube
- https://gallaugher.com

Learning iOS? Check out:
- https://gallaugher.com/swift
