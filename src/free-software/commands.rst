I am a strong believer in the UNIX philosophy of using tools that
does one job and plumbing them together to do more complex tasks.

`sxiv` is the simple X image viewer. Frequently, I have to copy
all pictures from my camera to my hard drive and select photos
that I want to be part of an album.

  $ sxiv -o -t photos/ | xargs mv {} album/
