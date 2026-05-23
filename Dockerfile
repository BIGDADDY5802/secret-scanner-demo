# Intentionally using older image to demonstrate Trivy vulnerability detection
FROM python:3.8-slim

WORKDIR /app

COPY test-data/ .

RUN echo "Demo application for secret scanner pipeline"

CMD ["echo", "Running demo app"]
