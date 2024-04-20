import pytest

def test_not_analizing_if_was_playing_back_sound():
    """
    Given a sound detector
    When it detects a sound while the sound was being played back
    Then it should not analyze the sound to avoid feedback loops
    """
    raise NotImplementedError()