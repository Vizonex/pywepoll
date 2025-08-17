from asyncio.selector_events import BaseSelectorEventLoop
from .selector import EpollSelector

class WepollEventLoop(BaseSelectorEventLoop):
    def __init__(self):
        super().__init__(EpollSelector())


