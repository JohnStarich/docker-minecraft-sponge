# Sponge Minecraft Server for Docker

[Sponge](https://www.spongepowered.org) Minecraft server in a container.

Built-in features include:

* runs a Sponge server in a Docker container
* issues a `stop` command when the container is stopped
* supports multiple console connections using `docker exec`
* automatically downloads newest or desired Sponge version specified by environment variable
* automatic restarts in the event of a server crash or regular `/stop` command

## Running

To run this container, use the following command.

```bash
docker run -d --name sponge -p 25565:25565 -p 25565:25565/udp johnstarich/sponge-vanilla
```

This command starts a Sponge server and allows connections on port 25565 (the default Minecraft port). If you are running the container on the same IP address as your Minecraft game client, then use the server address `localhost` to connect and play.

Here's a larger example of usage:

```bash
# [] = optional
# $SERVER_VERSION can be `1.10.2-5.0.0-BETA-101`,
#   `latest`, `latest-stable`, `latest-bleeding`
#   where latest and latest stable get the current
#   stable build of Sponge and bleeding gets the
#   current beta build of sponge.

docker run --detach \
    [--name $CONTAINER_NAME] \
    --publish $SERVER_PORT:25565 \
    --publish $SERVER_PORT:25565/udp \
    [--env SPONGE_VERSION=$SERVER_VERSION] \
    johnstarich/sponge-vanilla [$JAVA_ARG1 [$JAVA_ARG2 ...]]
```

This command publishes the default Minecraft port and sets the desired Sponge version. The last java arguments could be something like `-Xmx1G`, which instructs Minecraft to only use 1 gigabyte of memory (RAM). Feel free to add more arguments since these arguments are appended to the `java` command for the server.

The following command adds a volume mount from the host computer into the container so the Minecraft world can be stored there. It also specifies a specific BETA build to use instead of the latest stable release.

```bash
docker run -d --name sponge -p 25565:25565 -p 25565:25565/udp -e SPONGE_VERSION=1.10.2-5.0.0-BETA-101 -v /dir/on/host/for/sponge:/sponge johnstarich/sponge-vanilla -Xmx1G
```

## Connecting to Console

Attaching to the console to run commands is quite useful, especially when setting up for the first time.
In these cases, use the following command to connect to the server console.

```bash
docker exec -it sponge spongesh
```

To disconnect, press `ctrl-C`.

Individual commands can also be run from `spongesh`. For example, `docker exec sponge spongesh say hello world`.

## Stopping the server

Stopping the server can be done by just stopping the container with `docker stop sponge`.

However, if the shutdown process takes longer than 10 seconds (the default Docker wait time), then Docker will kill the server without giving it time to shut down properly. This can be solved by extending the shut down time with `docker stop --time=60 sponge` where 60 is the number of seconds before a kill is issued.

The *__best way__* to shutdown the server safely, without risk of corruption, is by running `docker exec sponge spongesh shutdown`. This command will tell the server to shutdown and the server will shut down when it is ready.
