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
        exc_type: type[BaseException] | None = ...,
        exc_value: BaseException | None = ...,
        exc_tb: TracebackType | None = ...,
        /,
    ) -> None: ...
    def close(self) -> None:
        """
        Close the control file descriptor of the :class:`.epoll` object.

        :raises OSError: if close fails.
        """
    closed: bool
    def fileno(self) -> int:
        """
        Close the control file descriptor of the :class:`.epoll` object.

        :raises OSError: if close fails.
        """
        ...
    def register(self, fd: int | socket, eventmask: int = ...) -> None:
        """
        Registers a file descriptor.

        :param fd: a file descriptor to register. This can be either
            a socket type or integer.
        :param eventmask: A List of epoll flags to set to this file
            descriptor.

        :raises TypeError: if obtaining the file descriptor from the
            python object fails or is an invalid type.
        :rasies RuntimeError: if epoll is closed.
        """
        ...
    def modify(self, fd: int | socket, eventmask: int) -> None:
        """
        Modify a registered file descriptor.

        :param fd: a file descriptor to register. This can be either
            a socket type or integer.
        :param eventmask: A List of epoll flags to set for the modified fd.

        :raises TypeError: if obtaining the file descriptor from the
            python object fails or is an invalid type.

        :rasies RuntimeError: if epoll is closed.
        """
        ...

    def unregister(self, fd: int | socket) -> None:
        """
        Remove a registered file descriptor from the :class:`.epoll` object.

        :param fd: a file descriptor to unregister. This can be either
            a socket type or integer.
        :raises OSError: if unregistering the file descriptor fails.
        """
        ...

    def poll(
        self, timeout: float | None = None, maxevents: int = -1
    ) -> list[tuple[int, int]]:
        """
        Wait for events using timeout in seconds.

        :param timeout: timeout in seconds (float or int)

        :param maxevents: maximum number of events to listen for
            default is -1 which will be a varaious amount.
            Passing -1 to maxevents is discouraged and should
            be left alone instead if chosen to omit or ignore

        :raises TypeError: if timeout type is not supported
        :raises ValueError: if maxevents is less than -1
        """
        ...

    # Maybe in a Future release but we shall see...
    @classmethod
    def fromfd(cls, fd: int, /) -> epoll:
        """
        creates a :class:`.epoll` from msvcrt using `_get_osfhandle`
        from `io.h` in C to get the file descriptor's handle.
        This function does not audit in order to increase performance

        :param fd: the file descriptor to create an :class:`.epoll` using.

        :raises OSError: if `_get_osfhandle` fails
        :raises WindowsError: if initialization after obtaining the handle fails.
        """
        ...
