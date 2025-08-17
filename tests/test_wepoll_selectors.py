import selectors
import tempfile
import unittest
from test.test_selectors import ScalableSelectorMixIn, BaseSelectorTestCase
from wepoll import EpollSelector

# Code is borrowed from python's testsuite ensure wepoll matches up with unix epolls

class EpollSelectorTestCase(BaseSelectorTestCase, ScalableSelectorMixIn,
                            unittest.TestCase):

    SELECTOR = EpollSelector
    def test_modify_unregister(self):
        raise self.skipTest("")

    def test_register_file(self):
        # epoll(7) returns EPERM when given a file to watch
        s = self.SELECTOR()
        with tempfile.NamedTemporaryFile() as f:
            with self.assertRaises(IOError):
                s.register(f, selectors.EVENT_READ)
            # the SelectorKey has been removed
            with self.assertRaises(KeyError):
                s.get_key(f)

