FROM python:3.7

COPY poetry.lock pyproject.toml /app/
WORKDIR /app

RUN apt-get update && apt-get install gcc

RUN pip install poetry

# Project initialization:
RUN poetry config virtualenvs.create false \
  && poetry install --no-dev --no-interaction --no-ansi

COPY ./src /app

ENV PYTHONPATH /app
ENV REDIS_URL 127.0.0.1:6379

EXPOSE 80

CMD ["uvicorn", "testmon:app", "--host", "0.0.0.0", "--port", "80"]
