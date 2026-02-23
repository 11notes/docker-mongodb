![banner](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/banner/README.png)

# MONGODB
![size](https://img.shields.io/badge/image_size-175MB-green?color=%2338ad2d)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![pulls](https://img.shields.io/docker/pulls/11notes/mongodb?color=2b75d6)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)[<img src="https://img.shields.io/github/issues/11notes/docker-mongodb?color=7842f5">](https://github.com/11notes/docker-mongodb/issues)![5px](https://raw.githubusercontent.com/11notes/static/refs/heads/main/img/markdown/transparent5x2px.png)![swiss_made](https://img.shields.io/badge/Swiss_Made-FFFFFF?labelColor=FF0000&logo=data:image/svg%2bxml;base64,PHN2ZyB2ZXJzaW9uPSIxIiB3aWR0aD0iNTEyIiBoZWlnaHQ9IjUxMiIgdmlld0JveD0iMCAwIDMyIDMyIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogIDxyZWN0IHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgZmlsbD0idHJhbnNwYXJlbnQiLz4KICA8cGF0aCBkPSJtMTMgNmg2djdoN3Y2aC03djdoLTZ2LTdoLTd2LTZoN3oiIGZpbGw9IiNmZmYiLz4KPC9zdmc+)

run mongodb rootless

# INTRODUCTION 📢

[MongoDB](https://github.com/mongodb/mongo) (created by [mongodb](https://github.com/mongodb/)) the popular, open-source NoSQL document-oriented database designed for handling large volumes of unstructured or semi-structured data. Unlike traditional relational databases (RDBMS) that use tables, MongoDB stores data in flexible, JSON-like BSON documents (Binary JSON). It is highly scalable, supports rapid development, and is widely used for modern web and mobile applications. 

# SYNOPSIS 📖
**What can I do with this?** This image will run mongodb rootless withouth any authentication. Why so simple? Because 99.9% of all containers that need mongodb, are happy with the default settings, no different dbuser, whatever needed. It also adds a simple backup scheduler that will backup your database if ```MONGODB_BACKUP_SCHEDULE``` is set, including a retention manager. Since this image has by default no authentication, you must make sure it’s only reachable via an ```internal: true``` network and only attach containers to the same network that need direct access to MongoDB. This image is also skipping all informal logs to quiet it down and only show errors.

**Supported MongoDB versions:** 4.4.30 (EOL, but no AVX required from your CPU)

# UNIQUE VALUE PROPOSITION 💶
**Why should I run this image and not the other image(s) that already exist?** Good question! Because ...

> [!IMPORTANT]
>* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
>* ... this image has a health check
>* ... this image runs read-only
>* ... this image is created via a secure and pinned CI/CD process
>* ... this image is very small
>* ... this image can take full backups on its own

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

# COMPARISON 🏁
Below you find a comparison between this image and the most used or original one.

| **image** | **size on disk** | **init default as** | **[distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)** | supported architectures
| ---: | ---: | :---: | :---: | :---: |
| 11notes/mongodb | 175MB | 1000:1000 | ❌ | amd64 |
| mongo | 409MB | 0:0 | ❌ | amd64, arm64v8 |

# VOLUMES 📁
* **/mongodb/var** - Directory of database files
* **/mongodb/backup** - Directory of backups

# COMPOSE ✂️
```yaml
name: "db"

x-lockdown: &lockdown
  # prevents write access to the image itself
  read_only: true
  # prevents any process within the container to gain more privileges
  security_opt:
    - "no-new-privileges=true"

services:
  mongodb:
    image: "11notes/mongodb:4.4.30"
    <<: *lockdown
    environment:
      TZ: "Europe/Zurich"
      # make a full database backup each day at 03:00
      MONGODB_BACKUP_SCHEDULE: "0 3 * * *"
      # only keep the last five backups
      MONGODB_BACKUP_RETENTION: 5
    networks:
      backend:
    volumes:
      - "mongodb.var:/mongodb/var"
      - "mongodb.backup:/mongodb/backup"
    restart: "always"

volumes:
  mongodb.var:
  mongodb.backup:

networks:
  backend:
    internal: true
```
To find out how you can change the default UID/GID of this container image, consult the [RTFM](https://github.com/11notes/RTFM/blob/main/linux/container/image/11notes/how-to.changeUIDGID.md#change-uidgid-the-correct-way).

# BUILD 🚧
```dockerfile
file ./build.dockerfile not found!
```

# DEFAULT SETTINGS 🗃️
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user name |
| `uid` | 1000 | [user identifier](https://en.wikipedia.org/wiki/User_identifier) |
| `gid` | 1000 | [group identifier](https://en.wikipedia.org/wiki/Group_identifier) |
| `home` | /mongodb | home directory of user docker |

# ENVIRONMENT 📝
| Parameter | Value | Default |
| --- | --- | --- |
| `TZ` | [Time Zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) | |
| `DEBUG` | Will activate debug option for container image and app (if available) | |
| `MONGODB_BACKUP_SCHEDULE` *(optional)* | Set backup schedule for full backups (crontab style) | |
| `MONGODB_BACKUP_RETENTION` *(optional)* | Set backup retention points to keep | 0 (disabled) |

# MAIN TAGS 🏷️
These are the main tags for the image. There is also a tag for each commit and its shorthand sha256 value.

* [4.4.30](https://hub.docker.com/r/11notes/mongodb/tags?name=4.4.30)
* [4.4.30-unraid](https://hub.docker.com/r/11notes/mongodb/tags?name=4.4.30-unraid)
* [4.4.30-nobody](https://hub.docker.com/r/11notes/mongodb/tags?name=4.4.30-nobody)

### There is no latest tag, what am I supposed to do about updates?
It is my opinion that the ```:latest``` tag is a bad habbit and should not be used at all. Many developers introduce **breaking changes** in new releases. This would messed up everything for people who use ```:latest```. If you don’t want to change the tag to the latest [semver](https://semver.org/), simply use the short versions of [semver](https://semver.org/). Instead of using ```:4.4.30``` you can use ```:4``` or ```:4.4```. Since on each new version these tags are updated to the latest version of the software, using them is identical to using ```:latest``` but at least fixed to a major or minor version. Which in theory should not introduce breaking changes.

If you still insist on having the bleeding edge release of this app, simply use the ```:rolling``` tag, but be warned! You will get the latest version of the app instantly, regardless of breaking changes or security issues or what so ever. You do this at your own risk!

# REGISTRIES ☁️
```
docker pull 11notes/mongodb:4.4.30
docker pull ghcr.io/11notes/mongodb:4.4.30
docker pull quay.io/11notes/mongodb:4.4.30
```

# UNRAID VERSION 🟠
This image supports unraid by default. Simply add **-unraid** to any tag and the image will run as 99:100 instead of 1000:1000.

# NOBODY VERSION 👻
This image supports nobody by default. Simply add **-nobody** to any tag and the image will run as 65534:65534 instead of 1000:1000.

# SOURCE 💾
* [11notes/mongodb](https://github.com/11notes/docker-mongodb)

# PARENT IMAGE 🏛️
* [${{ json_readme_parent_image }}](${{ json_readme_parent_url }})

# BUILT WITH 🧰
* [mongodb](https://github.com/mongodb/mongo)
* [11notes/util](https://github.com/11notes/docker-util)

# GENERAL TIPS 📌
> [!TIP]
>* Use a reverse proxy like Traefik, Nginx, HAproxy to terminate TLS and to protect your endpoints
>* Use Let’s Encrypt DNS-01 challenge to obtain valid SSL certificates for your services

# CAUTION ⚠️
> [!CAUTION]
>* Do not expose the EOL version to anything except the app that requires it. Use ```internal: true``` docker or container networks **only!**

# ElevenNotes™️
This image is provided to you at your own risk. Always make backups before updating an image to a different version. Check the [releases](https://github.com/11notes/docker-mongodb/releases) for breaking changes. If you have any problems with using this image simply raise an [issue](https://github.com/11notes/docker-mongodb/issues), thanks. If you have a question or inputs please create a new [discussion](https://github.com/11notes/docker-mongodb/discussions) instead of an issue. You can find all my other repositories on [github](https://github.com/11notes?tab=repositories).

*created 23.02.2026, 22:34:07 (CET)*