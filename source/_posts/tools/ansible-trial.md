---
title: Ansible 试用
date: 2022-03-28 23:09:32
tags:
- "Ansible"
- "Python"
id: ansible-trial
no_word_count: true
no_toc: false
categories: "工具"
---

## Ansible 试用

### 简介

本文会简述 Ansible 的使用方式。

### 配置目标地址 

在项目中会存在 `hosts` 或 `hosts.yaml` 文档，通过此文档可以指定安装服务的位置。

在官方实例中提供了 `hosts.yaml` 的四种样例：

- 不指定组的主机

```yaml
# 样例 1: 对于这样的主机需要将其放在 'all' 或 'ungrouped' 参数下，在样例中定义了 4 个主机，有一个主机还被配置了两个参数
all:
  hosts:
      green.example.com:
          ansible_ssh_host: 191.168.100.32
          anyvariable: value
      blue.example.com:
      192.168.100.1:
      192.168.100.10:
```

- 指定组的主机

```yaml
# 样例 2: 4 个位于 webservers 组中的主机，并且它们全都具有相同的配置项
webservers:
  hosts:
     alpha.example.org:
     beta.example.org:
     192.168.1.100:
     192.168.1.110:
  vars:
    http_port: 8080
```

- 使用子组的方式

```yaml
# 样例 3：可以选定范围的方式指定主机并将子组和变量添加到组中。子组和普通组一样可以定义全部内容，并且子组会从父组继承全部变量，同样父组也会包含子组中的所有主机。
# testing 组是父组，webservers 组是它的子组。而且在 testing 组中已经指定了 www[001:006].example.com 的主机
webservers:
  hosts:
    gamma1.example.org:
    gamma2.example.org:
testing:
  hosts:
    www[001:006].example.com:
  vars:
    testing1: value1
  children:
    webservers:
other:
  children:
    webservers:
      gamma3.example.org
```

> 注：testing 组包含下面所有主机：
> gamma1.example.org 
> gamma2.example.org 
> gamma3.example.org 
> www001.example.com 
> www002.example.com 
> www003.example.com 
> www004.example.com 
> www005.example.com 
> www006.example.com

- 全局参数

```yaml
# 样例 4：全局参数，在 `all` 组中的参数会具有最低级的优先级
all:
  vars:
      commontoall: thisvar
```

### 配置运行文件

在项目中可以编写称为 playbook 的脚本文件

```yaml
- hosts: all
  ###########
  # 关键参数: hosts
  # 是否必填: 是
  # 简介:
  #   指明需要部署的主机或组。
  #
  ## 样例:
  #   hosts: all -- 所有主机
  #   hosts: host1 -- 主机 host1 单独运行
  #   hosts: group1 -- group1 中的所有主机
  #   hosts: group1,group2 -- group1 和 group2 中的所有主机
  #   hosts: group1,host1 -- hosts in group1 AND host
  #
  ## 表达式样例 
  #   hosts: group1,!group3 -- 在 group1 但是不在 group3 中的主机
  #   hosts: group1,&group3 -- 在 group1 和 group3 中的主机
  #   hosts: group1:&group3 -- 同上但是使用 `:` 替代了 `,`
  #   hosts: group1:!group2:&group3 -- 在 group1 和 group3 但不在 group2 的主机
  #
  ## 使用参数的形式传递
  #
  # 可以通过如下的方式传递参数
  #
  #   hosts: '{{mygroups}}' -- 使用 mygroups 参数传递主机
  #
  # 这对于测试 playbook 非常方便，在针对生产、偶尔的维护任务和其他情况运行 playbook 之前，在一个临时环境中运行相同的 playbook，在这些情况下，您只需要针对几个系统而不是整个组运行 playbook。
  # 请注意，不能在清单中设置该变量，因为在使用清单变量之前，我们需要了解主机。所以通常会使用 “额外变量”，如下所示。
  #
  # 如果如上所示设置主机，则可以指定在每次运行时应用 playbook 的主机，如下所示：
  #
  #   ansible-playbook playbook.yml --extra-vars="mygroups=staging"
  #
  # 使用 --extra vars 将变量设置为组、主机名或主机模式的任意组合，就像上一节中的示例一样。
  #

  name: my heavily commented play
  ###########
  # 关键参数: name
  # 默认: play
  # 是否必填: 否
  # 简介: 需要执行命令的简介

  gather_facts: yes
  ###########
  # 关键参数: gather_facts
  # 默认: None
  # 是否必填: 否
  # 简介:
  #   此参数控制着程序是否触发 `fact gathering task` (也被叫做 `gather_facts` 或 `setup` 操作) 来获取远程执行的返回结果。
  #   执行的返回值也通常在选择执行计划和作为参数输入的时候很有用。
  #   例如我们想执行 `ansible_os_distribution` 命令来获取主机的系统类型到底是 RHEL, Ubuntu 或 FreeBSD 等, 以及 CPU, RAM 等硬件信息。

  remote_user: login_user
  ###########
  # 关键参数:  remote_user
  # 默认: 依赖于 `connection` 插件, 对于 ssh 来说就是 '执行当前命令的用户'
  # 是否必填: 否
  # 简介:
  #   登录远程设备的用户，通常也是执行命令的用户

  become: True
  ###########
  # 关键参数: become
  # 默认: False
  # 是否必填: 否
  # 简介:
  #   如果设置为 True 就会提升命令的执行权限，像是在命令行中加入了 `--become` 参数一样。

  become_user: root
  ###########
  # 关键参数: become_user
  # 默认: None
  # 是否必填: 否
  # 简介:
  #   当使用权限升级时，这是您在与远程用户登录后 “become” 的用户。例如，您以 “login_user” 身份登录远程用户，然后您“become” root 用户以执行任务。

  become_method: sudo
  ###########
  # 关键参数: become_method
  # 默认: sudo
  # 是否必填: 否
  # 简介:
  #   当使用特权升级时，这会选择用于特权升级的插件。
  #   使用 `ansible-doc -t become -l` 命令来提示更多内容。

  connection: ssh
  ###########
  # 关键参数: connection
  # 默认: ssh
  # 是否必填: 否
  # 简介:
  #   这将设置 Ansible 将使用哪个 `connection` 插件尝试与目标主机进行通信。
  #   注意此处是由 paramiko (python 版本的 ssh, 在 ssh 命令行不能很好地与目标系统配合使用的情况下非常有用。
  #   除此之外还有 “local”，强制 “local fork” 执行任务，但通常您真正想要的是 “delegate_to:localhost”，其余内容需要参见下面的实例。
  #   使用 `ansible-doc -t connection -l` 命令来提示更多内容。

  vars:
  ###########
  # 关键参数: vars
  # 默认: none
  # 是否必填: 否
  # 简介:
  #   为该任务定义的变量键值对，通常用于模板或任务变量。

    # 在使用时填写 {{color}} 即可引用变量
    color: brown

    # 键值对的数据类型允许传入复杂的结构, 在使用时可以采用  {{web['memcache']}} 这样的方式来获取子项，或 {{web}} 来获取完整的对象
    web:
      memcache: 192.168.1.2
      httpd: apache

    # 列表型参数，使用 {{ mylist[1] }} 可以得到 'b', 索引从 0 开始.
    mylist:
       - a
       - b
       - c

    # 参数可以使用 Jinja 模板引擎进行动态配置, 直至使用的时候才会被读取.
    #
    # 在这个 playbook 中, 此表达式永远会返回 False, 因为 'color' 在上面被赋值为了 'brown'。
    #
    # 当 ansible 转译如下内容时会首先将 'color' 赋值为 'brown' 然后依据 Jinja 表达式对比 'brown' == 'blue'
    is_color_blue: "{{ color == 'blue' }}"
	
	my_version: 1.2.3

  vars_files:
  ##########
  # 关键参数: vars_files
  # 是否必填: 否
  # 简介:
  #   此处可以填写一个 YAML 格式的参数文件列表，这些参数会在 `vars` 之后载入，无论 `vars` 写在哪里。样例如下：
  #
  #   ---
  #   monitored_by: phobos.mars.nasa.gov
  #   fish_sticks: "good with custard"
  #   ... # (文件结束)
  #
  #   注： `---` 应该位于页面最左端
  #
    # 使用绝对路径引入配置文件
    - /srv/ansible/vars/vars_file.yml

    # 使用相对路径引入配置文件
    - vars/vars_file.yml

    # 使用可变配置引入配置文件
    - vars/{{something}}.yml

    # 也可以使用数组来引入配置文件
    - [ 'vars/{{platform}}.yml', vars/default.yml ]

    # 文件会按照顺序进行引入，所以后面的配置文件可以写入更多的内容
    - [ 'vars/{{host}}.yml' ]

    # 但是如果在做主机特定的变量文件，可以考虑在你的库中设置一个组的变量，并把你的主机添加到那个组。

  vars_prompt:
  ##########
  # 关键参数: vars_prompt
  # 是否必填: 否
  # 简介:
  #   Ansible 将在每次运行此 playbook 时提示手动输入的变量列表。用于敏感数据，也可用于不同部署的版本号等。
  #
  #   如果已经提供了这个值，Ansible将不会提示输入，比如在传递时——额外的变量，但不是来自库存。
  #
  #   如果检测到它是非交互式会话，它也不会提示。例如，当从cron调用时。
  #
    - name: passphrase
      prompt: "Please enter the passphrase for the SSL certificate"
      private: yes
      #   在 private 参数为 yes 时输入不会回显到终端

    # 在配置不敏感的内容时应该这样做.
    - name: release_version
      prompt: "Please enter a release tag"
      private: no

    # 配置默认值
    - name: package_version
      prompt: "Please enter a package version"
      default: '1.0'

    # 可以在这个链接找到更多特性 https://docs.ansible.com/ansible/latest/user_guide/playbooks_prompts.html

  roles:
  ##########
  # 关键参数: roles
  # 是否必填: 否
  # 简介: 在此 playbook 中的的权限列表。执行时间在 pre_tasks 和基础信息获取之后, 但在 'tasks' 之前.

  tasks:
  ##########
  # 关键参数: tasks
  # 是否必填: 否
  # 简介: 此 playbook 中的任务列表. 在 roles 之后执行，在 post_tasks 之前执行

    # 一个简单的任务
    # 每个任务都必须有一个操作。'name' 是一个可选项，但是对说明任务的工作项非常有用
    - name: Check that the target can execute Ansible tasks
      action: ping

    ##########
    # Ansible 的 modules 会完成业务工作!, 'action' 并不是必须的, 当然也可以使用 'action itself' 作为 task 的一部分
    - file: path=/tmp/secret mode=0600 owner=root group=root
    #
    # 'action' 的格式如同上面的内容:
    # <modulename>: <module parameters>
    #
    # 可以使用如下的方式进行参数测试:
    #   ansible -m <module> -a "<module parameters>"
    #
    # modules 文档如下:
    # http://ansible.github.com/modules.html

    # 通常情况下，大多数人希望使用“k:v”符号，而不是上面使用的“k=v”（但对临时执行有用）。
    # 虽然这两种格式基本上都是可交换的，`k:v`更明确，类型更友好，并且更容易转义。
    - name: Ensure secret is locked down
      file:
         path: /tmp/secret
         mode: '0600'
         owner: root
         group: root

    # 请注意 'action' 参数的缩进, 并且 'task' 要位于顶层

    ##########
    # 在任务中使用变量
    - name: Paint the server
      command: echo {{color}}

    # 您还可以在任务级别定义变量
    - name: Ensure secret is locked down
      file:
         path: '{{secret_file}}'
         mode: '0600'
         owner: root
         group: root
      vars:
        secret_file: /tmp/secret

	# 在运行任务时进行检查
    - debug:
        msg: "my_version is higher than 1.0.0"
      when: my_version is version('1.0.0', '>')

	# 捕捉任务运行中的异常
	- name: Attempt and graceful roll back demo
      block:
        - name: Print a message
          ansible.builtin.debug:
            msg: 'I execute normally'

        - name: Force a failure
          ansible.builtin.command: /bin/false

        - name: Never print this
          ansible.builtin.debug:
            msg: 'I never execute, due to the above task failing, :-('
      rescue:
        - name: Print when errors
          ansible.builtin.debug:
            msg: 'I caught an error'

        - name: Force a failure in middle of recovery! >:-)
          ansible.builtin.command: /bin/false

        - name: Never print this
          ansible.builtin.debug:
            msg: 'I also never execute :-('
      always:
        - name: Always do this
          ansible.builtin.debug:
            msg: "This always executes"

    ##########
    # 事情发生变化时触发处理程序！
    #
    # 大多数 Ansible 操作都可以在发生变化时检测并报告。
    # 例如，如果文件权限与请求的权限不同，文件内容不同，或者在报告更改时安装（或删除）了包，则任务将假定为“已更改”状态。
    # Ansible 可以选择通知一个或多个处理程序。
    # 处理程序与普通任务类似，主要区别在于它们只在收到通知时运行。
    # 常见的用法是在更新服务的配置文件后重新启动服务。
    # https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html#handlers-running-operations-on-change
    
    # 在拷贝 httpd.conf 文件之后触发重启 Apache
    - name: Update the Apache config
      copy:
        src: httpd.conf
        dest: /etc/httpd/httpd.conf
      notify: Restart Apache

    # 下面是如何指定多个处理程序的样例
    - name: Update our app's configuration
      copy:
        src: myapp.conf
        dest: /etc/myapp/production.conf
      notify:
        - Restart Apache
        - Restart Redis

    ##########
    # 引入来自其他文件的任务
    #
    # Ansible 可以引入另一个文件中的任务列表。该文件必须表示任务列表。
    #
    # 任务列表如下:
    #   ---
    #   - name: create user
    #     user: name={{myuser}} color={{color}}
    #
    #   - name: add user to group
    #     user: name={{myuser}} groups={{hisgroup}} append=true
    #   ... # (文件结束)
    #
    #   'tasks' YAML 文件中的内容是任务列表. 不要用 playbook YAML 代替 'tasks' YAML 文件。

    # 在本例 new_user.yml 里，用户将是 'sklar'，'color' 将是 'red'
    - import_tasks: tasks/new_user.yml
      vars:
        myuser: sklar
        color: red

    # 在本例 new_user.yml 里，用户将是 'mosh'，'color' 将是 'mauve'
    - import_tasks: tasks/new_user.yml
      vars:
        myuser: mosh
        color: mauve


    ##########
    # 使用列表运行任务
    #
    # Ansible 提供了一个基本的循环方式. 如果任务中引入了 'loop' 则会依据给定的内容循环运行。
    - name: Create a file named via variable in /tmp
      file: path=/tmp/{{item}} state=touched
      loop:
        - tangerine
        - lemon

    - name: Loop using a variable
      file: path=/tmp/{{item}} state=touched
      loop: '{{mylist}}'
      vars:
        # 样例在此处定义，但实际使用中可以在任务运行前的任意位置进行定义。
        # 请注意的是 YAML 的缩进，这样的方式也是正确的。
        mylist:
        - tangerine
        - lemon
    ##########
    # 有条件地执行任务
    #
    # 有时，您只想在特定条件下运行某个操作。
    # Ansible 支持使用条件 Jinja 表达式，仅在“True”时执行任务。
    #
    # 如果您试图仅在值更改时运行任务，
    # 请考虑将任务重写为处理程序并使用“notify”（见下文）。
    #
    - name: "shutdown all ubuntu"
      command: /sbin/shutdown -t now
      when: '{{is_ubuntu|bool}}'

    - name: "shutdown the if host is in the government"
      command: /sbin/shutdown -t now
      when: "{{inventory_hostname in groups['government']}}"

      # 另外一种实现方式
    - name: "shutdown the if host is in the government"
      command: /sbin/shutdown -t now
      when: "{{'government' in group_names}}"

    # Ansible 有一些内置变量，您可以在此处检查它们。
    # inventory_hostname 是执行任务的当前主机的名称（源自hosts:关键字）
    # group_names 包含当前主机（inventory_hostname）所属的组列表
    # 组是库存组与属于它们的主机列表的映射

    ##########
    # 使用其他用户运行
    #
    # 每个任务都有可选的关键字来控制用户，以及是否使用权限提升（如sudo或su）切换到该用户。

    - name: login in as postgres and dump all postgres databases
      shell: pg_dumpall -w -f /tmp/backup.psql
      remote_user: postgres
      become: False

    - name: login normally, but sudo to postgres to dump all postgres databases
      shell: pg_dumpall -w -f /tmp/backup.psql
      become: true
      become_user: postgres
      become_method: sudo

    ##########
    # 本地运行!
    #
    # 任务也可以委派给控制主机
    - name: create tempfile
      local_action: shell dd if=/dev/urandom of=/tmp/random.txt count=100

    # 这相当于如下操作
    - name: create tempfile
      shell: dd if=/dev/urandom of=/tmp/random.txt count=100
      delegate_to: localhost
    # “delegate_to”可以使用任何目标主机，但对于上述情况，它与使用“local_action”相同

  handlers:
  ##########
  # 关键参数: handlers
  # 是否必填: 否
  # 简介:
  #   Handlers 是在另一个任务更改某些内容时运行的任务。
  #   有关如何触发它们的示例，请参见上文。
  #   定义 handlers 的格式与任务的格式完全相同。
  #   请注意，如果多个任务在playbook运行中通知同一个处理程序，则该处理程序将只为该主机运行一次。
  #
  #   通过名称或使用 listen 关键字来引用处理程序。
  #   它们将按照 playbook 中宣布的顺序运行。
  # 例如：如果任务要以相反的顺序通知处理程序，如下所示：
  #
  #   - task: ensure file does not exist
  #     file:
  #       name: /tmp/lock.txt
  #       state: absent
  #     notify:
  #     - Restart application
  #     - Restart nginx
  #
  # 因为声明时的顺序 "Restart nginx" handler 会在 "Restart application" 之前运行

    # 使用名称触发的样例
    - name: Restart nginx
      service:
         name: nginx
         state: restarted

    # 使用 listen 或名称触发
    - name: redis restarter
      service:
         name: redis
         state: restarted
      listen:
        - Restart redis

    # 任何模块都可以用于处理程序操作，尽管这可以通过多种方式和多次触发，但每个主机只能执行一次
    - name: restart application that should really be a service
      command: /srv/myapp/restart.sh
      listen:
        - Restart application
        - restart myapp

    # 同样还可以包含来自另一个文件的处理程序。结构与任务文件相同，有关示例，请参见上面的任务部分。
    - import_tasks: handlers/site.yml


# 请注意: 这不是一个 playbook 或任务中所有可能关键字的完整列表，只是一个非常常见的选项示例。

# 下面的内容是文档的结束标记
...
```

### 配置用户的方式

可以使用如下的方式覆写：

- 在运行时使用 `-u` 参数
- 将用户相关信息存储在库中
- 将用户信息存储在配置文件中
- 设置环境变量

### 参考资料

[官方文档](https://docs.ansible.com/ansible/latest/user_guide/intro_getting_started.html)

[官方样例](https://github.com/ansible/ansible/blob/devel/examples)