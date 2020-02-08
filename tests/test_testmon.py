from datetime import datetime, timedelta

from starlette.testclient import TestClient

from testmon import app, get_tomorrow

client = TestClient(app)


def test_get_tomorrow():
    today = datetime.now()
    expected_tomorrow = today + timedelta(seconds=86400)
    assert expected_tomorrow == get_tomorrow(today)


def test_now():
    response = client.get("/now")
    assert response.status_code == 200


def test_tomorrow():
    response = client.get("/tomorrow")
    assert response.status_code == 200


def test_bad_path():
    response = client.get("/null")
    assert response.status_code == 404
