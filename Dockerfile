# Build stage
FROM dart:3.10.3 AS build
WORKDIR /app

# Copy all projects (for shared dependencies, though none yet, it's safer for monorepos)
COPY . .

# Move into the server directory
WORKDIR /app/pixorama_server

# Install dependencies and compile the server executable
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Final stage
FROM alpine:latest

# Environment variables
ENV runmode=production
ENV serverid=default
ENV logging=normal
ENV role=monolith

# Copy runtime dependencies
COPY --from=build /runtime/ /

# Copy compiled server executable from the server's bin folder
COPY --from=build /app/pixorama_server/bin/server server

# Copy configuration files and resources from the server directory
COPY --from=build /app/pixorama_server/config/ config/
COPY --from=build /app/pixorama_server/web/ web/
COPY --from=build /app/pixorama_server/migrations/ migrations/

# This file is required for Insight log filtering (from the server directory)
COPY --from=build /app/pixorama_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

# Expose ports
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Define the entrypoint command
ENTRYPOINT ./server --mode=$runmode --server-id=$serverid --logging=$logging --role=$role
