${{ content_synopsis }} This image will run mongodb rootless withouth any authentication. Why so simple? Because 99.9% of all containers that need mongodb, are happy with the default settings, no different dbname, different dbuser, whatever needed. It also adds a simple backup scheduler that will backup your database if ```MONGODB_BACKUP_SCHEDULE``` is set, including a retention manager. Since this image has by default no authentication, you must make sure it’s only reachable via an ```internal: true``` network and only attach containers to the same network that need direct access to MongoDB.

**Supported MongoDB versions:** 4.4.30 (EOL, but no AVX required from your CPU)

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small
${{ github:> }}* ... this image can take full backups on its own

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ title_volumes }}
* **${{ json_root }}/var** - Directory of database files
* **${{ json_root }}/backup** - Directory of backups

${{ content_compose }}

${{ content_build }}

${{ content_defaults }}

${{ content_environment }}
| `MONGODB_BACKUP_SCHEDULE` *(optional)* | Set backup schedule for full backups (crontab style) | |
| `MONGODB_BACKUP_RETENTION` *(optional)* | Set backup retention points to keep | 0 (disabled) |

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}