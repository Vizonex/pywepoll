from ._wepoll import epoll

# === FLAGS ===

# SEE: https://docs.python.org/3/library/select.html#edge-and-level-trigger-polling-epoll-objects
# NOTE: Some flags might not be supported such as EPOLLET, EPOLLEXCLUSIVE
EPOLLIN  = 1
"""Available for read"""
EPOLLPRI = 2
"""Urgent data for read"""
EPOLLOUT = 4
"""Available for write"""
EPOLLERR = 8
"""Error condition happened on the assoc. fd"""
EPOLLHUP = 16
"""Hang up happened on the assoc. fd"""
EPOLLRDNORM = 64
"""Equivalent to EPOLLIN"""
EPOLLRDBAND = 128
"""Priority data band can be read."""
EPOLLWRNORM = 256
"""Equivalent to EPOLLOUT"""
EPOLLWRBAND = 512
"""Priority data may be written."""
EPOLLMSG = 1024
"""Ignored."""
EPOLLRDHUP = 8192
"""Stream socket peer closed connection or shut down writing half of connection."""
EPOLLONESHOT = -2147483648
"""Set one-shot behavior. After one event is pulled out, the fd is internally disabled"""

__author__ = "Vizonex"
__version__ = "0.1.0"
__all__ = (
    "__author__",
    "__version__",
    "EPOLLIN",
    "EPOLLPRI",
    "EPOLLOUT",
    "EPOLLERR",
    "EPOLLHUP",
    "EPOLLRDNORM"
    "EPOLLRDBAND",
    "EPOLLWRNORM",
    "EPOLLWRBAND",
    "EPOLLMSG",
    "EPOLLRDHUP",
    "EPOLLONESHOT",
    "epoll"
)
