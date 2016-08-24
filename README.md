# Sponge Minecraft Server for Docker

[Sponge](https://www.spongepowered.org) Minecraft server in a container.

## Running

To run this container, use the following command.

```bash
docker run -d -i -t --name sponge -p 25565:25565 -e SPONGE_VERSION=1.10.2-5.0.0-BETA-101 johnstarich/sponge-vanilla -Xmx1G
```

This command publishes the default minecraft port and sets the desired Sponge version. The last argument `-Xmx2G` is saying that Minecraft can only use 1 gigabyte of memory (RAM), adjust this as you see fit. Feel free to add more arguments, these arguments are appended to the `java` command for the server.

The following command adds a volume mount from the host computer into the container so the Minecraft world can be stored there.

```bash
docker run -d -i -t --name sponge -p 25565:25565 -e SPONGE_VERSION=1.10.2-5.0.0-BETA-101 -v /dir/on/host/for/sponge:/sponge johnstarich/sponge-vanilla -Xmx1G
```

## Connecting to Console

Attaching to the console to run commands is quite useful, especially when setting up for the first time.
In these cases, use the following command to connect to the server console.

**Note: The container must be run as interactive `-i` and allocate a tty `-t` in order for the attach to work.**

```bash
docker attach sponge
```

To disconnect press `ctrl-P` then `ctrl-Q`.
Pressing `ctrl-C` terminates the Minecraft server, so be careful.

## Stopping the server

Stopping the server is not as simple as stopping the container. Stopping the container will immediately terminate the Minecraft server, potentially corrupting or not saving the world properly.

To stop the server correctly, you must attach to the container (described above) and run `stop` in the console.

