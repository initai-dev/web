# Use the official Elixir image
# We use Alpine for a smaller image size
FROM elixir:1.18-alpine AS build

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    nodejs \
    npm

# Set environment variables
ENV MIX_ENV=prod

# Create app directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./

# Install mix dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy assets and content
COPY assets assets
COPY priv priv

# Copy source code
COPY lib lib
COPY config config

# Build assets
RUN mix assets.deploy

# Compile the project
RUN mix compile

# Build the release
RUN mix release

# --- Runtime Stage ---
FROM alpine:3 AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    libstdc++

# Create app user
RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

# Create app directory
WORKDIR /app

# Copy the release from build stage
COPY --from=build --chown=appuser:appgroup /app/_build/prod/rel/web_phoenix ./

# Copy static assets and content from build stage
COPY --from=build --chown=appuser:appgroup /app/priv/static ./priv/static
COPY --from=build --chown=appuser:appgroup /app/priv/content ./priv/content

# Switch to app user
USER appuser

# Expose the port
EXPOSE 4000

# Set environment variables
ENV MIX_ENV=prod
ENV PHX_SERVER=true
ENV PORT=4000

# Start the Phoenix server
CMD ["./bin/web_phoenix", "start"]