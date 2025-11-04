from asyncio.selector_events import BaseSelectorEventLoop

from .selector import EpollSelector


class WepollEventLoop(BaseSelectorEventLoop):
    """
    Selector event loop for wepoll.

    See `events.EventLoop <https://docs.python.org/3/library/asyncio-eventloop.html#asyncio.EventLoop>`__ for API specification.
    """

    def __init__(self):
        super().__init__(EpollSelector())
