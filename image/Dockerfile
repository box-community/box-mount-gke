FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        acl \
        ca-certificates \
        util-linux \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --no-cache-dir "boxsdk[jwt]>=10,<11" \
    && python -c "import box_sdk_gen; print('Box SDK ready')"

RUN groupadd --gid 1000 boxmount-share \
    && useradd --uid 1001 --create-home --shell /usr/sbin/nologin boxmount \
    && useradd --uid 1000 --create-home --gid boxmount-share --shell /bin/bash agent \
    && usermod --append --groups boxmount-share boxmount \
    && mkdir -p /mnt/box /workspace /app /run/secrets \
    && chown boxmount:boxmount-share /mnt/box \
    && chmod 2770 /mnt/box \
    && chown agent:boxmount-share /workspace

COPY box-mount /usr/local/bin/box-mount
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY agent.py /app/agent.py

RUN chmod 0755 /usr/local/bin/box-mount \
    && chmod 0755 /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
