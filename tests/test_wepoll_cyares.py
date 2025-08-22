from cyares import Channel
from cyares.channel import CYARES_SOCKET_BAD
from wepoll import EpollSelector
from wepoll import epoll, EPOLLIN, EPOLLOUT
from socket import AF_INET
READ = EPOLLIN
WRITE = EPOLLOUT

# based off pycares's testsuite

class TestCyaresWepoll:
    channel: Channel
    def wait(self):
        # The function were really testing is this wait function
        poll = epoll()
        while True:
            r, w = self.channel.getsock()
            if not r and not w:
                break
            for rs in r:
                poll.register(rs, EPOLLIN)
            for ws in w:
                poll.register(ws, EPOLLOUT)

            timeout = self.channel.timeout()
            if timeout == 0.0:
                self.channel.process_fd(
                    CYARES_SOCKET_BAD, CYARES_SOCKET_BAD
                )
                continue
            for fd, event in poll.poll(timeout):
                if event & ~EPOLLIN:
                    self.channel.process_write_fd(fd)
                if event & ~EPOLLOUT:
                    self.channel.process_read_fd(fd)

    def test_resolve(self):
        self.channel = Channel(event_thread=False, servers=["8.8.8.8", "8.8.4.4"])
        fut = self.channel.gethostbyname("python.org", AF_INET)
        self.wait()
        self.channel.cancel()
        assert fut.result()


