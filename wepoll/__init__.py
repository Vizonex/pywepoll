from ._wepoll import epoll
from .loop import WepollEventLoop
from .selector import EpollSelector
from .flags import EPOLLERR as EPOLLERR
from .flags import EPOLLHUP as EPOLLHUP
from .flags import EPOLLIN as EPOLLIN
from .flags import EPOLLMSG as EPOLLMSG
from .flags import EPOLLONESHOT as EPOLLONESHOT
from .flags import EPOLLOUT as EPOLLOUT
from .flags import EPOLLPRI as EPOLLPRI
from .flags import EPOLLRDBAND as EPOLLRDBAND
from .flags import EPOLLRDHUP as EPOLLRDHUP
from .flags import EPOLLRDNORM as EPOLLRDNORM
from .flags import EPOLLWRBAND as EPOLLWRBAND
from .flags import EPOLLWRNORM as EPOLLWRNORM


__author__ = "Vizonex"
__version__ = "0.1.1"
__all__ = (
    "__author__",
    "__version__",
    "EPOLLIN",
    "EPOLLPRI",
    "EPOLLOUT",
    "EPOLLERR",
    "EPOLLHUP",
    "EPOLLWRNORM",
    "EPOLLWRBAND",
    "EPOLLMSG",
    "EPOLLRDHUP",
    "EPOLLONESHOT",
    "epoll",
    "EpollSelector",
    "WepollEventLoop",
)

