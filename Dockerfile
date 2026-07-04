FROM tes3mp/server:0.8.1

# Copy active scripts, collections, configs, and our custom entrypoint into the image
COPY scripts_active/ /server/scripts_active/
COPY scripts_collections/ /server/scripts_collections/
COPY config/ /server/config/
COPY docker-entrypoint.sh /server/docker-entrypoint.sh

# Ensure the entrypoint script is executable
RUN chmod +x /server/docker-entrypoint.sh

# Use our custom entrypoint to execute setup routines before launching the server
ENTRYPOINT ["/bin/bash", "/server/docker-entrypoint.sh"]
