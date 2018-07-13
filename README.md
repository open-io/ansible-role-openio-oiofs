[![Build Status](https://travis-ci.org/open-io/ansible-role-openio-oiofs.svg?branch=master)](https://travis-ci.org/open-io/ansible-role-openio-oiofs)
# Ansible role `openio-oiofs`

An Ansible role for the [OpenIO](http://www.openio.io) filesystem.
This role installs and configures OpenIO oiofs.

If you like/use this role, please consider giving it a star on github or
reviewing it on Ansible Galaxy. Thanks!

## Requirements

This role supports Centos 7 and Ubuntu 16.04 Xenial.

The role **defaults** to use the following services, which should be deployed
before using the oiofs role:

- a local `oioproxy` daemon listening on `localhost:6006`
- a local `ECD` daemon listening on `localhost:6017`
- a local & standalone `redis` daemon listening on `localhost:6379`

You can specify different adresses and/or ports for each of those service
dependencies if the default values do not suit your deployment. For example, if
they are not running on the same host as oiofs itself.

The `ECD` service should only be necessary if you are using an erasure coding
policy. The default values are harmless otherwise.

Instead of the standalone `redis` service, you can use a `redis-sentinel`
cluster for higher availability / resiliency.

See below for configuration details.

## Role Variables

| Variable											| Default					| Comments (type) |
| :---													| :---						| :--- |
| `openio_sds_conf_directory`		| `'/etc/oio/sds.conf.d'`	| OpenIO SDS configuration directory (for namespace config file) |
| `openio_oiofs_conf_directory`	| `'/etc/oio/oiofs.conf.d'`	| OpenIO oiofs configuration directory (for mountpoints config files) |
| `oiofs_mountpoints`						| `[]`						| List of mountpoints to setup (see below for structure) |
| `openio_oiofs_cfg_user`				| `'openio'`						| Owner for config files |
| `openio_oiofs_cfg_group`			| `'openio'`						| Group for config files |

Each mountpoint to setup can specify the following members:

| Member      	| Default 					| Comments (type)  |
| :---          	| :---    					| :---             |
| `path` |  | mandatory, string, containing path where that oiofs instance is to be mounted on |
| `state` |  | mandatory, string that decides if the mountpoint is to be setup (`'present'`) or uninstalled (`'absent'`)|
| `container` | `'test_container'` | SDS container to store oiofs |
| `account` | `'test_account'` | SDS account |
| `namespace` | `'OPENIO'` | SDS namespace |
| `oioproxy_host` | `'127.0.0.1'` | SDS oioproxy hostname or IP address |
| `oioproxy_port` | `6006` | SDS oioproxy port |
| `ecd_host` | `'127.0.0.1'` | SDS ecd hostname or IP address |
| `ecd_port` | `6017` | SDS ecd port |
| `force_mkfs` | `false` | In case the container already had an oiofs inside |
| `cache_action` | `'flush'` |  'flush': use previous cache content / 'erase': forget previous cache content |
| `user` | `root` | User name used to mount the filesystem |
| `group` | `root` | Group name used to mount the filesystem |
| `mode` | `'0755'` | Mode used to mount the filesystem |
| `fuse_options` | `['default_permissions', 'allow_other']` | List of strings: options passed to fuse with a "-o" when mounting the filesystem |
| `fuse_flags` | `[]` | List of strings: flags passed to fuse when mounting the filesystem |
| `attributes_timeout` | `20` | Attributes validity timeout (in seconds) |
| `auto_retry` | `true` | Automatic retry of read/write/flush operations |
| `cache_asynchronous` | `true` | Make the cache async/sync |
| `cache_directory` | `'/mnt/oiofs-cache'` | Local cache directory where to store data before sending to the SDS cluster |
| `cache_size_bytes` | `2048000000` | Cache size in bytes |
| `cache_size_on_flush_bytes` | `1024000000` | On cache full events, the cache will flush data until this size is attained (in bytes) |
| `cache_timeout` | `5` | Seconds between automatic cache flushes |
| `chunk_size` | `1048576` | Chunk size in bytes (only used at mkfs.oiofs time) |
| `chunk_part_size` | `1048576` | Chunk part size in bytes (only useful if `recovery_cache_directory` is given |
| `fuse_max_retries` | `10` | Maximum number of fuse retry attempts |
| `ignore_flush` | `true` | Ignore flushes |
| `inode_by_container` | `65536` | Maximum number of inodes per container (only used at mkfs.oiofs time) |
| `log_level` | `'NOTICE'` | NOTICE < INFO < DEBUG |
| `max_flush_threads` | `10` | Maximum number of flusher threads |
| `max_packed_chunks` | `10` | Maximum number of chunks per upload |
| `max_redis_connections` | `30` | Maximum number of connections to redis cluster |
| `on_die` | `'respawn'` | What to do when the service handling this mountpoint dies (see *Note 3* below for details) |
| `recovery_cache_directory` | `` | Local recovery cache directory, if any is to be used |
| `redis_sentinel_name` | `'{{ oiofs_mountpoint_default_namespace }}-master-1'` | As a redis-sentinel cluster can host multiple instances, use the one with this name (see *Notes 1 & 2* below for details) |
| `redis_sentinel_servers` | `` | List of strings: `['IP1:port1', 'IP2:port2', 'IP3:port3', ]` telling oiofs who are the redis-sentinel cluster members |
| `redis_server | `'127.0.0.1:6379'` | Single standalone redis server (see *Note 1* below for details) |
| `retry_delay` | `500` | Delay before retrying after an error (in milliseconds) |
| `start_at_boot` | `true` | mount the FS at boot time by gridinit |
| `http_server` | `127.0.0.1:6999` | Web service address to query for mountpoint statistics |
| `sds_retry_delay` | `0` | SDS actions retry delay |
| `full_cache_timeout` | `500` | Cache timeout |
| `active_mode` | `` | Default service mode, used for high availability. Set to 'true' to be active by default or 'false' to disable by default |
| `cache_size_for_flush_activation` | `1638400000` | If the cache reach this size oio-fs will start to flush until it reach `cache_size_on_flush_bytes` |
| `chunk_readahead` | `0` | To set the chunk numbers to read ahead |

The full documentation for these options is [here](https://github.com/open-io/oio-fs/blob/master/CONF.md).

*NOTE 1*: `redis_server` and `redis_sentinel_name` are mutually exclusive. You
have to choose between a standalone redis server or a redis-sentinel cluster. In
case nothing is specified, a local standalone redis server is used.

*NOTE 2*: Don't forget to give `redis_sentinel_name` if the default value does not
suit your platform.

*NOTE 3*: The following values are possible:

- `'cry'`: Make gridinit warn if the service fails, but do not attempt to respawn it.
- `'exit'`: Make gridinit itself exit if the service fails, this is probably *not* what you want.
- `'respawn'`: Make gridinit try to restart the service upon failure.

## Dependencies

This role also requires the presence of the following roles in your ansible `roles` directory:

- [ansible-role-openio-repository](https://github.com/open-io/ansible-role-openio-repository)
- [ansible-role-openio-gridinit](https://github.com/open-io/ansible-role-openio-gridinit)

You'll need to create an account for each namespace used for oiofs, for example:

```
openio --oio-ns OPENIO account create test_account
```

And then you can use `test_account` in

```
oiofs_mountpoints:
  - path: "/mnt/oiofs/mnt"
    [...]
    account: test_account
    [...]
```

## Example Playbook

```
---

- name: "Install and configure OpenIO oiofs & SDS repositories"
  hosts: oiofs
  become: true

  tasks:
    - name: "Setup oiofs repository"
      include_role:
        name: ansible-role-openio-repository
      vars:
        openio_repository_products:
          sds:
            release: '17.04'
          oiofs:
            release: '17.04'
            user: 'oiofs'
            password: 'THE_MIRROR_PASSWORD'

    - name: "Apply 'ansible-role-openio-gridinit' role"
      include_role:
          name: ansible-role-openio-gridinit

    - name: "Apply 'ansible-role-openio-oiofs' role"
      include_role:
          name: ansible-role-openio-oiofs
      vars:
        oiofs_mountpoints:
          - path: '/mnt/oiofs/mnt'
            cache_directory: '/mnt/oiofs/cache'
            state: 'present'

...
```

Another, more involved, one:

```
---

- name: "Install and configure OpenIO oiofs & SDS repositories"
  hosts: oiofs
  become: true

  tasks:
    - name: "Setup oiofs repository"
      include_role:
        name: ansible-role-openio-repository
      vars:
        openio_repository_products:
          sds:
            release: '17.04'
          oiofs:
            release: '17.04'
            user: 'oiofs'
            password: 'THE_MIRROR_PASSWORD'

    - name: "Apply 'ansible-role-openio-gridinit' role"
      include_role:
          name: ansible-role-openio-gridinit

    - name: "Apply 'ansible-role-openio-oiofs' role"
      include_role:
          name: ansible-role-openio-oiofs
      vars:
        oiofs_mountpoints:
          - path: '/mnt/oiofs-1/mnt'
            cache_directory: '/mnt/oiofs-1/cache'
            recovery_cache_directory: '/mnt/oiofs-1/recovery'
            state: 'present'
            account: 'test_account'
            container: 'test_container'
            log_level: 'INFO'
            oioproxy_host: '172.17.0.2'
            ecd_host: '172.17.0.2'
            redis_sentinel_servers: ['192.168.0.123:6012', '192.168.0.124:6012', '192.168.0.125:6012']
            redis_sentinel_name: 'OPENIO-master-1'
            fuse_options:
              - 'default_permissions'
              - 'allow_other'

...
```

## Contributing

Issues, feature requests, ideas are appreciated and can be posted in the
[Issues](https://github.com/open-io/ansible-role-openio-oiofs/issues) section.

Pull requests are also very welcome. The best way to submit a PR is by first
creating a fork of this Github project, then creating a topic branch for the
suggested change(s) and pushing that branch to your own fork. Github can then
easily create a PR based on that branch.

## License

Apache License version 2.0

## Contributors

- [Vincent Legoll](https://github.com/vincent-legoll) (maintainer)
