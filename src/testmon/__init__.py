"""Quick app for pipeline testing"""

__version__ = "0.1.0"

from datetime import datetime, timedelta

from fastapi import FastAPI
from pydantic import BaseModel  # pylint: disable=E0611
from starlette.requests import Request


class NowOut(BaseModel):  # pylint: disable=R0903
    """Pydantic validator for api json response."""

    status: str
    time: str
    ip: str


app = FastAPI()  # pylint: disable=C0103


def get_tomorrow(today: datetime) -> datetime:
    """Return tomorrow."""
    return today + timedelta(seconds=86400)


@app.get("/now", response_model=NowOut)
async def now(request: Request):
    """Return the current time."""
    _now = datetime.now()
    out = NowOut(status="alive", time=_now.ctime(), ip=request.client.host)
    return out.dict()


@app.get("/tomorrow", response_model=NowOut)
async def tomorrow(request: Request):
    """Return exactly one day from now."""
    _now = datetime.now()
    _tomorrow = get_tomorrow(_now)
    out = NowOut(status="alive", time=_tomorrow.ctime(), ip=request.client.host)
    return out.dict()
