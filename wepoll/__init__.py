from ._wepoll import epoll
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
from .loop import WepollEventLoop
from .selector import EpollSelector

__author__ = "Vizonex"
__version__ = "0.1.5"
__all__ = (
    "EPOLLERR",
    "EPOLLHUP",
    "EPOLLIN",
    "EPOLLMSG",
    "EPOLLONESHOT",
    "EPOLLOUT",
    "EPOLLPRI",
    "EPOLLRDHUP",
    "EPOLLWRBAND",
    "EPOLLWRNORM",
    "EpollSelector",
    "WepollEventLoop",
    "__author__",
    "__version__",
    "epoll",
)

