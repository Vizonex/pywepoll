# PyWepoll
A Python Port of the wepoll C Library meant to help give windows support for epoll objects in python.

## How this project came to be
Originally this was C Library was going to be utilized in [winloop](https://github.com/Vizonex/winloop) for dealing with `UVPoll` objects but the idea was scrapped when I didn't realize that the License was actually MIT LICENSE Friendly and I was still a bit of a noob at low-level coding. Knowing about this project for a couple of years I wanted to experiemnt with it using [cyares](https://github.com/Vizonex/cyares) to see if it would help with polling sockets if needed to be done manually without socket handles or event-threads to see if it would provide one of the slowest Operating Systems a little performance boost over the standard `select` function that python provides.

Currently as is the library is experimental and I wouldn't call it beta or production ready yet unlike cyares which is in it's beta phase and does a really good job performance-wise. 


## How to use wepoll when windows is in use
Know that currently there's some features or functions that are unavalible with wepoll however in the future I plan to look into adding them in unless anybody wants to contribute and get it done before I do.

```python
import sys
# NOTE: This example may not work on apple operating systems
if sys.platform == "linux":
    import select 
elif sys.platform == "win32":
    import wepoll as select 
```
