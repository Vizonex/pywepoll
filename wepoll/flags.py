# === FLAGS ===

# SEE: https://docs.python.org/3/library/select.html#edge-and-level-trigger-polling-epoll-objects
# NOTE: Some flags might not be supported such as EPOLLET, EPOLLEXCLUSIVE

EPOLLIN = 1 << 0
"""Available for read"""
EPOLLPRI = 1 << 1
"""Urgent data for read"""
EPOLLOUT = 1 << 2
"""Available for write"""
EPOLLERR = 1 << 3
"""Error condition happened on the assoc. fd"""
EPOLLHUP = 1 << 4
"""Hang up happened on the assoc. fd"""
EPOLLRDNORM = 1 << 6
"""Equivalent to EPOLLIN"""
EPOLLRDBAND = 1 << 7
"""Priority data band can be read."""
EPOLLWRNORM = 1 << 8
"""Equivalent to EPOLLOUT"""
EPOLLWRBAND = 1 << 9
"""Priority data may be written."""
EPOLLMSG = 1 << 10  # Never Reported
"""Ignored."""
EPOLLRDHUP = 1 << 13
"""Stream socket peer closed connection or shut down writing half of connection."""
EPOLLONESHOT = 1 << 31
"""Set one-shot behavior. After one event is pulled out, the fd is internally disabled"""
