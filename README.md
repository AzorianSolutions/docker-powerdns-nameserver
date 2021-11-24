# PowerDNS Authoritative Server packaged by [Azorian Solutions](https://azorian.solutions)

The PowerDNS Authoritative Server is the only solution that enables authoritative DNS service from all major databases, including but not limited to MySQL, PostgreSQL, SQLite3, Microsoft SQL Server, LDAP, plain text files, and many other SQL databases via ODBC.

DNS answers can also be fully scripted using a variety of (scripting) languages such as Lua, Java, Perl, Python, Ruby, C and C++. Such scripting can be used for dynamic redirection, (spam) filtering or real time intervention.

In addition, the PowerDNS Authoritative Server is the leading DNSSEC implementation, hosting the majority of all DNSSEC domains worldwide. The Authoritative Server hosts at least 30% of all domain names in Europe, and around 90% of all DNSSEC domains in Europe.

[PowerDNS Authoritative Server Website](https://www.powerdns.com/auth.html)

[PowerDNS Authoritative Server Documentation](https://doc.powerdns.com/authoritative/)

## Quick reference

- **Maintained by:** [Matt Scott](https://github.com/AzorianSolutions)
- **Github:** [https://github.com/AzorianSolutions/docker-powerdns-nameserver](https://github.com/AzorianSolutions/docker-powerdns-nameserver)
- **Website:** [https://azorian.solutions](https://azorian.solutions)

## TL;DR

    docker run -d -p 12053:53/udp -p 12053:53 -e PDNS_local_address=0.0.0.0 azoriansolutions/powerdns-nameserver

## Azorian Solutions Docker image strategy

The goal of creating this image and others alike is to provide a fairly uniform and turn-key implementation for a chosen set of products and solutions. By compiling the server binaries from source code, a greater chain of security is maintained by eliminating unnecessary trusts. This approach also helps assure support of specific features that may otherwise vary from distribution to distribution. A secondary goal of creating this image and others alike is to provide at least two Linux distribution options for any supported product or solution which is why you will often see tags for both Alpine Linux and Debian Linux.

All documentation will be written with the assumption that you are already reasonably familiar with this ecosystem. This includes container concepts, the Docker ecosystem, and more specifically the product or solution that you are deploying. Simply put, I won't be fluffing the docs with content explaining every detail of what is presented.

## Additional features

When building this image, support for the following features have been compiled into the server binaries.

- OpenSSL ecdsa
- ed25519
- ed448
- Lua (luajit)
- Lua records
- SNMP
- libsodium

## Supported tags

\* denotes an image that is planned but has not yet been released.

### Alpine Linux

- 4.5.2, 4.5.2-alpine, 4.5.2-alpine-3.14, alpine, latest
- 4.5.2-mysql, 4.5.2-alpine-mysql, 4.5.2-alpine-3.14-mysql, alpine-mysql, mysql
- *4.5.2-pgsql, 4.5.2-alpine-pgsql, 4.5.2-alpine-3.14-pgsql, alpine-pgsql
- *4.5.2-sqlite, 4.5.2-alpine-sqlite, 4.5.2-alpine-3.14-sqlite, alpine-sqlite
- *4.5.2-odbc, 4.5.2-alpine-odbc, 4.5.2-alpine-3.14-odbc, alpine-odbc

### Debian Linux

- *4.5.2-debian, 4.5.2-debian-11.1-slim, debian
- 4.5.2-debian-mysql, 4.5.2-debian-11.1-slim-mysql, debian-mysql
- *4.5.2-debian-pgsql, 4.5.2-debian-11.1-slim-pgsql, debian-pgsql
- *4.5.2-debian-sqlite, 4.5.2-debian-11.1-slim-sqlite, debian-sqlite
- *4.5.2-debian-odbc, 4.5.2-debian-11.1-slim-odbc, debian-odbc

## Deploying this image

### Server configuration

Configuration of the PowerDNS authoritative server may be achieved through two approaches. With either approach you choose, you will need to be aware of the various settings available for the server.

[PowerDNS Authoritative Server Settings](https://doc.powerdns.com/authoritative/settings.html)

#### Approach #1

You may pass PowerDNS authoritative server conf file options as environment variables to the container. These environment variables will be automatically inserted into the /etc/pdns/pdns.conf file. Any environment variable that begins with "PDNS_" will be converted into the proper format for insertion into the primary server conf file.

For example, say you pass the environment variable "PDNS_local_address" with the value "0.0.0.0" to the container. This will result in the following line being added to the /etc/pdns/pdns.conf file;

    local-address=0.0.0.0

If you would don't want to pass sensitive information in the environment variables then support has been added for Docker Swarm secrets style support. All you have to do is add "_FILE" to the end of any environment variable beginning with "AS_" or "PDNS_". The content of the file will be automatically loaded into a corresponding environment variable using the same name without the "_FILE" suffix. The original environment variable with the "_FILE" suffix will be deleted. Here is an example of how you would configure the web server password using an environment variable that references a Docker Swarm secret;

    PDNS_webserver_password_FILE=/run/secrets/SECRET-NAME

This would result in the following line being added to the /etc/pdns/pdns.conf file;

    webserver-password=CONTENTS_OF_SECRET_FILE

#### Approach #2

With this approach, you may create traditional PowerDNS authoritative server conf files and map them to a specific location inside of the container. This will cause each mapped configuration file to be loaded each time the container is started. For example, say your Docker / Podman host has a PowerDNS authoritative server conf file stored at /srv/pdns-server.conf and you want to load that in your PowerDNS authoritative server container. You will create a volume mapping that will link the conf file on the host to a specific location in the container. The mapping would look something like this;

    /srv/pdns-server.conf:/etc/pdns/pdns.conf

### Deploy with Docker Run

To run a simple container on Docker with this image, execute the following Docker command;

    docker run -d -p 12053:53/udp -p 12053:53 -e PDNS_local_address=0.0.0.0 azoriansolutions/powerdns-nameserver

If all goes well and the container starts, you should now be able to query this DNS authoritative server using dig;

    dig -p 12053 @IP-OR-HOSTNAME-OF-DOCKER-HOST a docker.com

Since there will be no domains setup by default, you should expect the aforementioned dig test to receive a REFUSED response for any query you send.

### Deploy with Docker Compose

To run this image using Docker Compose, create a YAML file with a name and place of your choosing and add the following contents to it;

    version: "3.3"
    services:
      nameserver:
        image: azoriansolutions/powerdns-nameserver:alpine-mysql
        restart: unless-stopped
        environment:
          - PDNS_local_address=0.0.0.0
        ports:
          - "12053:53/udp"
          - "12053:53"

Then execute the following Docker Compose command;

    docker-compose -u /path/to/yaml/file.yml

## Building this image

If you want to build this image yourself, you can easily do so using the **build-release** command I have included.

The build-release command has the following parameter format;

    build-release IMAGE_TAG_NAME PDNS_VERSION DISTRO_REPO_NAME DISTRO_TAG

So for example, to build the PowerDNS authoritative server version 4.5.0 on Alpine Linux 3.14, you would execute the following shell command:

    build-release 4.5.0-alpine-3.14 4.5.0 alpine 3.14

The build-realease command assumes the following parameter defaults;

- Image Tag Name: latest
- PDNS Version: 4.5.2
- Distro Name: alpine
- Distro Tag: 3.14

This means that running the build-release command with no parameters would be the equivalent of executing the following shell command:

    build-release latest 4.5.2 alpine 3.14

When the image is tagged during compilation, the repository portion of the image tag is derived from the contents of the .as/docker-registry file and the tag from the first parameter provided to the build-release command.

