import pytest

from src.hello import add


@pytest.mark.parametrize(
    ("left", "right", "expected"),
    [
        (2, 3, 5),
        (0, 0, 0),
        (-2, 2, 0),
        (-4, -3, -7),
    ],
)
def test_add_returns_sum(left, right, expected):
    assert add(left, right) == expected
