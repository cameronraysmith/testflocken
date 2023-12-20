"""Tests for the testflocken.app module."""


def test_testflocken():
    from testflocken.app import testflocken

    assert testflocken(1, 2) == 3
