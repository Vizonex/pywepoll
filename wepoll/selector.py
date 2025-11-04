import sys
from selectors import _PollLikeSelector as PollLikeSelector
from typing import TYPE_CHECKING

from ._wepoll import epoll
from .flags import EPOLLIN, EPOLLOUT

# Added here if you didn't want to grab from somewhere else
EVENT_READ = 1  # (1 << 0)
EVENT_WRITE = 2  # (1 << 1)

if TYPE_CHECKING:
    from selectors import SelectorKey

# 3.13 compatabaility flags
_NOT_EPOLLIN = ~EPOLLIN
_NOT_EPOLLOUT = ~EPOLLOUT


class EpollSelector(PollLikeSelector):
    """Wepoll-based selector for windows operating systems"""

    _selector_cls = epoll
    _EVENT_READ = EPOLLIN
    _EVENT_WRITE = EPOLLOUT

    if TYPE_CHECKING:
        _selector: epoll
        if sys.version_info < (3, 13):
            _fd_to_key: "dict[int, SelectorKey]"

    if sys.version_info < (3, 13):

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
    else:

        def select(self, timeout=None):
            if timeout is None:
                timeout = -1
            elif timeout <= 0:
                timeout = 0
            else:
                pass

            # epoll_wait() expects `maxevents` to be greater than zero;
            # we want to make sure that `select()` can be called when no
            # FD is registered.
            max_ev = len(self._fd_to_key) or 1

            ready = []
            try:
                fd_event_list = self._selector.poll(timeout, max_ev)
            except InterruptedError:
                return ready

            fd_to_key = self._fd_to_key
            for fd, event in fd_event_list:
                key = fd_to_key.get(fd)
                if key:
                    events = (event & _NOT_EPOLLIN and EVENT_WRITE) | (
                        event & _NOT_EPOLLOUT and EVENT_READ
                    )
                    ready.append((key, events & key.events))
            return ready
