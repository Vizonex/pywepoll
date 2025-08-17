import math
from selectors import _PollLikeSelector as PollLikeSelector
from typing import TYPE_CHECKING, Optional

from ._wepoll import epoll
from .flags import EPOLLIN, EPOLLOUT

# Added here if you didn't want to grab from somewhere else
EVENT_READ = 1  # (1 << 0)
EVENT_WRITE = 2  # (1 << 1)

if TYPE_CHECKING:
    from selectors import SelectorKey


class EpollSelector(PollLikeSelector):
    """Wepoll-based selector for windows operating systems"""

    _selector_cls = epoll
    _EVENT_READ = EPOLLIN
    _EVENT_WRITE = EPOLLOUT

    if TYPE_CHECKING:
        _selector: epoll
        _fd_to_key: "dict[int, SelectorKey]"

    def select(self, timeout=None):
        # This is shared between poll() and epoll().
        # epoll() has a different signature and handling of timeout parameter.
        if timeout is None:
            timeout = None
        elif timeout <= 0:
            timeout = 0
        else:
            # NOTE: Our Poll does it by seconds so we get to ignore that
            pass

        ready = []
        try:
            fd_event_list = self._selector.poll(timeout)
        except InterruptedError:
            return ready
        for fd, event in fd_event_list:
            events = 0
            if event & ~self._EVENT_READ:
                events |= EVENT_WRITE
            if event & ~self._EVENT_WRITE:
                events |= EVENT_READ

            key = self._key_from_fd(fd)
            if key:
                ready.append((key, events & key.events))
        return ready
    