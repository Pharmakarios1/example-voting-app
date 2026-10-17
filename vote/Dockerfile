
# Base stage
FROM python:3.11-slim AS base

# Install curl for the container healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

# Upgrade Python packaging tools to receive security fixes
RUN python -m pip install --no-cache-dir --upgrade \
    pip setuptools wheel

# Install application dependencies
COPY requirements.txt ./requirements.txt
RUN python -m pip install --no-cache-dir -r requirements.txt

# Development stage
FROM base AS dev
RUN python -m pip install --no-cache-dir watchdog
ENV FLASK_ENV=development
CMD ["python", "app.py"]

# Production stage
FROM base AS final

COPY . .

EXPOSE 80

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", \
     "--log-file", "-", "--access-logfile", "-", \
     "--workers", "4", "--keep-alive", "0"]
