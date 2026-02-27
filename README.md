# GitLab Runner for Unraid

A GitLab Runner Docker image designed for Unraid, with automatic registration on first start.

Based on `gitlab/gitlab-runner:alpine` — adds auto-registration via environment variables and ships with an Unraid Community Applications template.

## Quick Start

```bash
docker run -d \
  --name gitlab-runner \
  --restart unless-stopped \
  -e CI_SERVER_URL=https://gitlab.com \
  -e RUNNER_TOKEN=glrt-xxxxxxxxxxxx \
  -e RUNNER_EXECUTOR=docker \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /mnt/user/appdata/gitlab-runner:/etc/gitlab-runner \
  mcgo/unraid-gitlab-runner
```

## Installation on Unraid

1. Go to the **Apps** tab in Unraid
2. Search for **GitLab Runner**
3. Click **Install** and fill in the template variables
4. The runner will automatically register itself at your GitLab instance

### Manual Template Install

If the template is not yet available in Community Applications:

1. In Unraid, go to **Docker > Add Container > Template Repositories**
2. Add: `https://github.com/mcgo/unraid-gitlab-runner`
3. The template will appear under **Docker > Add Container**

## Creating a Runner Token

### Modern Tokens (GitLab 16.0+, recommended)

1. Go to your GitLab project/group/instance **Settings > CI/CD > Runners**
2. Click **New project runner** (or group/instance runner)
3. Configure the runner settings (tags, description, etc.) in the UI
4. Copy the token (starts with `glrt-`)

With modern tokens, tags and other settings are configured in GitLab's UI — the `RUNNER_TAG_LIST`, `RUNNER_UNTAGGED`, and `RUNNER_LOCKED` environment variables have no effect.

### Legacy Registration Tokens (deprecated)

If you're using a legacy registration token, you can still pass `RUNNER_TAG_LIST`, `RUNNER_UNTAGGED`, and `RUNNER_LOCKED` as environment variables.

## Environment Variables

### Required

| Variable | Description | Default |
|---|---|---|
| `CI_SERVER_URL` | URL of your GitLab instance | — |
| `RUNNER_TOKEN` | Runner authentication token | — |

### Basic Configuration

| Variable | Description | Default |
|---|---|---|
| `RUNNER_NAME` | Display name in GitLab | `unraid-runner` |
| `RUNNER_EXECUTOR` | `docker` or `shell` | `docker` |
| `DOCKER_IMAGE` | Default image for CI jobs | `alpine:latest` |
| `RUNNER_CONCURRENT` | Max parallel jobs | `1` |

### Advanced

| Variable | Description | Default |
|---|---|---|
| `RUNNER_TAG_LIST` | Comma-separated tags (legacy tokens only) | — |
| `RUNNER_UNTAGGED` | Run untagged jobs (legacy tokens only) | — |
| `RUNNER_LOCKED` | Lock to project (legacy tokens only) | — |
| `DOCKER_PRIVILEGED` | Enable privileged mode for Docker executor | `false` |
| `DOCKER_VOLUMES` | Additional volumes, comma-separated | — |
| `UNREGISTER_ON_STOP` | Unregister runner on container stop | `false` |
| `CA_CERTIFICATES_PATH` | Path to custom CA cert inside container | — |

## Volumes

| Container Path | Recommended Host Path | Description |
|---|---|---|
| `/etc/gitlab-runner` | `/mnt/user/appdata/gitlab-runner` | Runner configuration (persists registration) |
| `/var/run/docker.sock` | `/var/run/docker.sock` | Docker socket (required for Docker executor) |

## Docker Images

This image is available on:

- **GHCR**: `ghcr.io/mcgo/unraid-gitlab-runner`
- **Docker Hub**: `mcgo/unraid-gitlab-runner`

## License

MIT
