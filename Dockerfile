FROM gitlab/gitlab-runner:alpine

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
