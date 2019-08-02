# PortKi
PortKi - (currently a Work in Progress) an iOS app for creating Kiosk-style navigation screens for the Adafruit PyPortal

To get this to work you'll need a:
- PyPortal: http://adafruit.com/pyportal
- AWS S3 accout and a publicly-readable directory named "portki-files" that is writeable by your "Portki" app [free]
- An adafruit.io account [free]

It's all still pretty raw, but it works in an alpha-beta sort of way.
The iOS code is especially gruesome - I kept changing data structures and APIs, and I haven't had a chance to refactor or clean things up. I eventually went with saving data locally, uploading JSON to Adafruit.io, and uploading JPEGs to Amazon S3. I also need to do a bunch of other things: Allow for screen deletions & moving, Allow for resizeable text boxes, and allow more than one line in a text box. That said, it's working pretty good for late-alpha, early-beta, and I'm ready to put this outside my office door.

I'm still pretty new to many of the concepts I've experimented here. Feedback welcome.

For more projects, see:
- https://youtube.com/GallaugherYouTube
- https://gallaugher.com

Learning iOS? Check out:
- https://gallaugher.com/swift
