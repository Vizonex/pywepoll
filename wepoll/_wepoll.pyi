import sys
from socket import socket
from types import TracebackType
from typing import final

if sys.version_info < (3, 11):
    from typing_extensions import Self
else:
    from typing import Self

@final
class epoll:
    def __init__(self, sizehint: int = ...) -> None: ...
    def __enter__(self) -> Self: ...
    def __exit__(
        self,
        exc_type: type[BaseException] | None = None,
        exc_value: BaseException | None = ...,
        exc_tb: TracebackType | None = None,
        /,
    ) -> None: ...
    def close(self) -> None: ...
    closed: bool
    def fileno(self) -> int: ...
    def register(self, fd: int | socket, eventmask: int = ...) -> None: ...
    def modify(self, fd: int | socket, eventmask: int) -> None: ...
    def unregister(self, fd: int | socket) -> None: ...
    def poll(
        self, timeout: float | None = None, maxevents: int = -1
    ) -> list[tuple[int, int]]:
        """
        Wait for events. timeout in seconds (float)
        
        Parameters
        ----------

        :param timeout: timeout in seconds (float or int)
        :param maxevent: maximum number of events to listen for default is -1 which will be a varaious amount.
            Passing -1 to maxevents is discouraged and should be left alone instead if chosen to omit or ignore
        Raises:
            TypeError: if timeout type is not supported
            ValueError: if maxevents is less than -1
        """

    # Maybe in a Future release but we shall see...
    @classmethod
    def fromfd(cls, fd: int, /) -> epoll:
        """creates a epoll (wepoll) from msvcrt using _get_osfhandle(fd) 
        from `io.h` in C to get the file descriptor's handle"""
    
