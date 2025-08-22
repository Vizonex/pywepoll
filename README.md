# PyWepoll
[![PyPI version](https://badge.fury.io/py/wepoll.svg)](https://badge.fury.io/py/wepoll)
![PyPI - Downloads](https://img.shields.io/pypi/dm/wepoll)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Python Port of the wepoll C Library meant to help give windows support for epoll objects in python. Code was based on CPython's implementation mixed with the old _epoll.pyx twisted source code. (If I can refind it I'll try to archive it for someone to look through.)

## How this project came to be
Originally this was C Library was going to be utilized in [winloop](https://github.com/Vizonex/winloop) for dealing with `UVPoll` objects but the idea was scrapped when I didn't realize that the License was actually MIT LICENSE Friendly and I was still a bit of a noob at low-level coding. Knowing about this project for a couple of years I wanted to experiemnt with it using [cyares](https://github.com/Vizonex/cyares) to see if it would help with polling sockets if needed to be done manually without socket handles or event-threads to see if it would provide one of the slowest Operating Systems a little performance boost over the standard `select` function that python provides.

Currently as is the library is experimental and I wouldn't call it beta or production ready yet unlike cyares which is in it's beta phase and does a really good job performance-wise. 
The Code is based off the old twisted module 



