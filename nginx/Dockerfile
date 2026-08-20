# Nginx reverse proxy image.
#
# Built with a `build:` context in docker-compose instead of a plain
# `image: nginx:...` line on purpose: the CD pipeline (.github/workflows/ci.yml)
# does `sed -i -E 's|image: .*|image: <ecr-uri>|' docker-compose.yaml` on deploy,
# which is not scoped to a single service. If nginx had its own `image:` line,
# that sed would overwrite it with the backend's ECR image URI on every deploy
# and silently break the proxy. Using `build:` avoids a second `image:` line.
FROM nginx:alpine

# nginx.conf lives at the repo root (build context is the repo root, see
# docker-compose.yaml) so it stays a single
COPY nginx.conf /etc/nginx/conf.d/default.conf
