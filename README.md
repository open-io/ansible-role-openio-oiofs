[![Build Status](https://travis-ci.org/open-io/ansible-role-openio-oiofs.svg?branch=master)](https://travis-ci.org/open-io/ansible-role-openio-oiofs)
# Ansible role `openio-oiofs`

An Ansible role for the [OpenIO](http://www.openio.io) filesystem.
This role installs and configures OpenIO oiofs.

If you like/use this role, please consider giving it a star on github or reviewing it on Ansible Galaxy. Thanks!

## Requirements

This role supports Centos 7 and Ubuntu 16.04 Xenial.

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
| `force_mkfs` | `false` | In case the container already had an oiofs inside |
| `cache_action` | `'flush'` |  'flush': use previous cache content / 'erase': forget previous cache content |
| `user` | `root` |  |
| `group` | `root` |  |
| `mode` | `'0755'` |  |
| `fuse_options` | `['default_permissions', 'allow_other']` | List of strings: options passed to fuse with a "-o" when mounting the filesystem |
| `fuse_flags` | `[]` | List of strings: flags passed to fuse when mounting the filesystem |
| `attributes_timeout` | `20` |  |
| `auto_retry` | `true` |  |
| `cache_asynchronous` | `true` |  |
| `cache_directory` | `'/mnt/oiofs-cache'` | Local cache directory where to store data before sending to the SDS cluster |
| `cache_size_bytes` | `2048000000` | Cache size in bytes |
| `cache_size_on_flush_bytes` | `1024000000` |  |
| `cache_timeout` | `5` | Seconds between automatic cache flushes |
| `chunk_size` | `1048576` | Chunk size in bytes |
| `fuse_max_retry` | `10` | Maximum number of fuse retry attempts |
| `ignore_flush` | `true` | Ignore flushes |
| `inode_by_container` | `65536` | Maximum number of inodes per container |
| `log_level` | `'NOTICE'` | NOTICE < INFO < DEBUG |
| `max_flush_thread` | `10` | Maximum number of flusher threads |
| `max_packed_chunks` | `10` |  |
| `max_redis_connections` | `30` | Maximum number of connections to redis cluster |
| `recovery_cache_directory` | `'/mnt/oiofs-recover'` | Local recovery cache directory |
| `redis_sentinel_name` | `'{{ oiofs_mountpoint_default_namespace }}-master-1'` | As a redis-sentinel cluster can host multiple instances, use the one with this name |
| `redis_sentinel_cluster` | `[]` | List of strings: `['IP1:port1', 'IP2:port2', 'IP3:port3', ]` telling oiofs who are the redis-sentinel cluster members |
| `retry_delay` | `500` |  |
| `start_at_boot` | `true` | mount the FS at boot time by gridinit |
| `stats_server` | `None` | Web service address to query for mountpoint statistics |
| `upload_retry_delay` | `0` | Upload retry delay |

## Dependencies

This role also requires the presence of the following roles in your ansible `roles` directory:
- [ansible-role-openio-repository](https://github.com/open-io/ansible-role-openio-repository)
- [ansible-role-openio-gridinit](https://github.com/open-io/ansible-role-openio-gridinit)

For oiofs repository setup you'll need to add some variables for the role, like in the following playbook snippet:

```
  tasks:
    - name: "Setup oiofs repository"
      include_role:
          name: ansible-role-openio-repository
      vars:
          openio_sds_release: 'unstable'
          openio_sds_repo_product: 'oiofs'
          openio_sds_repo_user: 'oiofs'
          openio_sds_repo_pass: 'THE_MIRROR_PASSWORD'
```

You'll need to create an account for each namespace used for oiofs, for example:

```
openio --oio-ns OPENIO account create test_account
```

And then you can use `test_account` in

```
oiofs_mountpoints:
  - path: "THE_TARGET_PATH"
    [...]
    account: test_account
    [...]
```

This may also be included in your playbook. See example below.

## Example Playbook

This example assumes an ansible inventory with specific host groups (`openio_conscience`, `openio_oiofs`, `openio_redis_cluster`, `openio_directory_m0`).

```
---

- name: Configure OpenIO SDS package repository
  hosts: all

  roles:
    - { role: ansible-role-openio-repository }

- name: Create the account for OpenIO oiofs
  hosts: all
  vars:
    openio_namespace: OPENIO

  tasks:
    - name: 'Check account pre-existence'
      shell: "openio --oio-ns {{ openio_namespace }} account show test_account"
      when: inventory_hostname == groups["openio_conscience"][0]
      register: account_status
      ignore_errors: yes
  
    - name: 'Create account for oiofs'
      shell: "openio --oio-ns {{ openio_namespace }} account create test_account"
      when:
        - account_status.rc != 0
        - inventory_hostname == groups["openio_conscience"][0]

- name: Install and configure OpenIO oiofs repository
  hosts: openio_oiofs

  tasks:
    - name: "Apply 'ansible-role-openio-repository' role"
      include_role:
          name: ansible-role-openio-repository
      vars:
          # Get latest build for now, from unstable repo
          openio_sds_release: 'unstable'
          openio_sds_repo_product: 'oiofs'
          openio_sds_repo_user: 'oiofs'
          openio_sds_repo_pass: 'THE_MIRROR_PASSWORD'

- name: Install and configure OpenIO oiofs
  hosts: all
  vars:
    openio_iface: 'eth0'
    # Use the redis-sentinel cluster from OpenIO SDS (because it will be sufficient)
    redis_sentinel_cluster: '[ {% for ip in groups["openio_redis_cluster"] | map("extract", hostvars, ["ansible_" + openio_iface, "ipv4", "address"]) %} "{{ ip }}:6012", {% endfor %} ]'
    # Use the oioproxy from the m0 host (any oioproxy from the SDS cluster would do)
    oioproxy_hosts: "{{ groups['openio_directory_m0'] | map('extract', hostvars, ['ansible_' + openio_iface, 'ipv4', 'address']) | list }}"

  tasks:
    - name: "Apply 'ansible-role-openio-oiofs' role on a node from the SDS cluster"
      include_role:
          name: ansible-role-openio-oiofs
      vars:
        oiofs_mountpoints:
          - path: "/mnt/oiofs-2/mnt"
            state: 'present'
            account: 'test_account'
            cache_directory: /mnt/oiofs-2/cache
            container: test_container_2
            force_mkfs: false
            log_level: "INFO" # NOTICE < INFO < DEBUG
            oioproxy_host: "{{ oioproxy_hosts[0] }}"
            redis_sentinel_cluster: "{{ redis_sentinel_cluster }}"

      when: inventory_hostname == "oio_3"

    - name: "Apply 'ansible-role-openio-oiofs' role on a standalone oiofs node"
      include_role:
          name: ansible-role-openio-oiofs
      vars:
        oiofs_mountpoints:
          - path: "/mnt/oiofs-1/mnt"
            state: 'present'
            account: 'test_account'
            cache_directory: /mnt/oiofs-1/cache
            container: test_container_1
            force_mkfs: true
            log_level: "INFO" # NOTICE < INFO < DEBUG
            oioproxy_host: "{{ oioproxy_hosts[0] }}"
            redis_sentinel_cluster: "{{ redis_sentinel_cluster }}"

            fuse_options:
              - default_permissions
              - allow_other

          - path: "/mnt/oiofs-3/mnt"
            state: 'absent'

      when: inventory_hostname == "oio_4"

...
```

## Contributing

Issues, feature requests, ideas are appreciated and can be posted in the [Issues](https://github.com/open-io/ansible-role-openio-oiofs/issues) section.

Pull requests are also very welcome. The best way to submit a PR is by first creating a fork of this Github project, then creating a topic branch for the suggested change and pushing that branch to your own fork. Github can then easily create a PR based on that branch.

## License

Apache License version 2.0

## Contributors

- [Vincent Legoll](https://github.com/vincent-legoll) (maintainer)
