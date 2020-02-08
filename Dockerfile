FROM python:3.7-alpine

# Move dependencies manifests for app
COPY poetry.lock pyproject.toml /app/
WORKDIR /app

# Download dependencies for installation of cryptography package
RUN apk update && apk add gcc make musl musl-dev libffi-dev openssl-dev

# Install project dependencies
RUN pip3 install poetry && \
  poetry config virtualenvs.create false && \
  poetry install --no-dev --no-interaction --no-ansi

# Don't want the baddies having these
RUN apk del gcc make musl musl-dev libffi-dev openssl-dev

COPY ./src /app

# Don't run as root
RUN addgroup -S -g 1499 testmon && \
    adduser -u 1499 -DHG testmon testmon && \
    chown -R testmon:testmon /app
USER testmon

ENV PYTHONPATH /app

EXPOSE 8080

CMD ["uvicorn", "testmon:app", "--host", "0.0.0.0", "--port", "8080"]
