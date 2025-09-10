# Redis-Ex

A minimal Redis-like server written in Elixir. It supports basic commands and listens for TCP connections on port 6379.

## Features

- In-memory key-value store
- TCP server compatible with Redis CLI clients, following the [Redis Protocol specification](https://redis-doc-test.readthedocs.io/en/latest/topics/protocol/)
- Supports `PING`, `SET`, `GET`, `EXPIRE` and `PERSIST` commands

## Getting Started

### Prerequisites

- Elixir 1.12+

### Running the Server

Start the application:

```sh
iex -S mix
```

This will start the Redis-like server and listen on port 6379.

### Usage

You can use `redis-cli` to connect:

```bash
$ redis-cli -p 6379
> PING
PONG
> SET foo bar
OK
> GET foo
bar
```

Or you can execute redis commands in iex:

```iex
iex(1)> Redis.execute(["PING"])
:pong
iex(2)> Redis.execute(["SET", "foo", "bar"])
:ok
iex(3)> Redis.execute(["GET", "foo"])
"bar"
```

#### Supported Commands

- `PING` — returns `PONG`
- `SET key value` — stores a string value
- `GET key` — retrieves a value
- `EXPIRE key seconds` — sets a key to expire
- `PERSIST key` — removes the expiration from a key
