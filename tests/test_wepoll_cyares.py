from wepoll import epoll, EPOLLIN, EPOLLOUT
import pytest

cyares = pytest.importorskip("cyares")
if cyares is not None:
    from cyares import Channel

# based off pycares's testsuite

READ = EPOLLIN
WRITE = EPOLLOUT

class TestCyaresWepoll:
    channel: "Channel"

    def wait(self):
        # The function were really testing is this wait function

        while self.channel.running_queries:
            timeout = self.channel.timeout()
            if timeout == 0.0:
                self.channel.process_no_fds()
                continue
            for fd, event in self.poll.poll(timeout):
                if event & ~EPOLLIN:
                    self.channel.process_write_fd(fd)
                if event & ~EPOLLOUT:
                    self.channel.process_read_fd(fd)

    def socket_state_cb(self, fd: int, r:bool, w: bool):
        flags = 0
        if r:
            flags |= READ
        if w:
            flags |= WRITE
        
        if flags:
            self.poll.register(fd, flags)
        else:
            self.poll.unregister(fd)

    def test_resolve(self):
        self.poll = epoll()
        self.channel = Channel(event_thread=False, servers=["8.8.8.8", "8.8.4.4"], sock_state_cb=self.socket_state_cb)
        fut = self.channel.query("python.org", "A")
        self.wait()
        assert fut.result()
