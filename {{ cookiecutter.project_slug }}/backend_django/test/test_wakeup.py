import pytest
from django.conf import settings
from backend_django import tasks
import vlc

import time

pytestmark = pytest.mark.django_db


def test_dummy():
    assert 1 == 1


# def test_mqtt_light_on_off():
#     cl = tasks.light_connect()
#     for i in range(3):
#         tasks.light_set(client=cl, state="ON")
#         time.sleep(5)
#         tasks.light_set(client=cl, state="OFF")
#         time.sleep(5)
#     tasks.light_disconnect(client=cl)


# def test_do_wakeup():
#     tasks.do_wakeup(
#         # sound=False,
#         light=True,
#         steps_total=60,
#         steps_1=2,
#         step_duration=2.0,
#         keep_on_duration=5,
#     )


# def test_play_audio():
#     p = vlc.MediaPlayer(tasks.SOUNDFILE2)
#     p.audio_set_volume(tasks.VOL_END)
#     time.sleep(5)
#     p.play()
#     time.sleep(10)
#     p.stop()
