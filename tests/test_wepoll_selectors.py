import selectors
import tempfile
import unittest
from test.test_selectors import ScalableSelectorMixIn, BaseSelectorTestCase
from wepoll import EpollSelector

# Code is borrowed from python's testsuite to ensure wepoll matches up with unix epolls


class EpollSelectorTestCase(
    BaseSelectorTestCase, ScalableSelectorMixIn, unittest.TestCase
):
    SELECTOR = EpollSelector

    def test_modify_unregister(self):
        if self.SELECTOR.__name__ == "EpollSelector":
            patch = unittest.mock.patch("wepoll.EpollSelector._selector_cls")
        else:
            raise self.skipTest("")

        with patch as m:
            m.return_value.modify = unittest.mock.Mock(side_effect=ZeroDivisionError)
            s = self.SELECTOR()
            self.addCleanup(s.close)
            rd, wr = self.make_socketpair()
            s.register(rd, selectors.EVENT_READ)
            self.assertEqual(len(s._map), 1)
            with self.assertRaises(ZeroDivisionError):
                s.modify(rd, selectors.EVENT_WRITE)
            self.assertEqual(len(s._map), 0)

    def test_register_file(self):
        # epoll(7) returns EPERM when given a file to watch
        s = self.SELECTOR()
        with tempfile.NamedTemporaryFile() as f:
            with self.assertRaises(IOError):
                s.register(f, selectors.EVENT_READ)
            # the SelectorKey has been removed
            with self.assertRaises(KeyError):
                s.get_key(f)
    
    def test_empty_select(self):
        # Issue #23009: Make sure EpollSelector.select() works when no FD is
        # registered.
        s = self.SELECTOR()
        self.addCleanup(s.close)
        self.assertEqual(s.select(timeout=0), [])
