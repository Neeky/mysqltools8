## mysqltools8-权威指南
   **作者:** 蒋乐兴

   **微信:** jianglegege

   **官方网站:** <a href="https://www.sqlpy.com" target="_blank" > www.sqlpy.com </a>
  
  ---

## 目录
- [作者序](#作者序)
- [mysqltools的世界观](#mysqltools的世界观)
- [mysqltool介绍](#mysqltool介绍)
- [安装与配置mysqltools](#安装与配置mysqltools)
- [配置管理结点](#配置管理结点)
- [安装MySQL单机](#安装MySQL单机)
  - [mysqltools都做了什么](#mysqltools都做了什么)
  - [进一步定制mysqltools的行为](#进一步定制mysqltools的行为)
- [单机多实例](#单机多实例)
--- 


## 作者序
   自第一个版本的 mysqltools 开源以来，收到了不少用户的反馈；mysqltools8 在此基础上总结了前一个版本的经验与教训，同时也顺应时代的发展增加了许多新的特性，比如支持 **docker** 这个让 mysqltools8 真正做到了拿来就用，面向 **插件实现** 一方面让 mysqltools8 的体积从之前的 1.2G 下降到了 30+MB ，另一方面功能上也实现了 **热插拔** 不管是升级还是扩展新的功能都更加简单。

   ---

## mysqltools的世界观
   **mysqltools** 希望 DBA 能喝着咖啡就把锁事情给做了，并且希望所交付的“输出”健壮到直接不用再管，DBA 节省下来的精力可以去做一些更有价值的事。总的来说我解决好两件事 **质量、效率**

   ### 质量
   **KFC vs 学校后街的蛋炒饭**

   KFC 根据既定的流程生产每一个汉堡，假设这个流程下公众对汉堡给出的评分是80分，那么不管哪个 KFC 的店它生产出来的汉堡都稳定在80分；一段时间后 KFC 发现这个流程中可以改进的项，把汉堡的质量提升到81分，那么它就能做到所有的店里的汉堡都能打81分。

   学校后街的蛋炒饭，好不好吃这个事难说；因为好多事都影响到它，有可能老板今天心情不好，也有可能是今天客人太多他比较急，这些都会影响到炒饭的质量。有一次我要买两盒，由于去的比较晚，老板只有一个鸡蛋了，你没有猜错！ 他就只放了一个。

   表面上看 KFC 流程化生产的好处在于它的东西质量有保障，最要命的是 KFC 只做加法，它可以不断提升自己，学校后街的蛋炒饭上周做的好吃，我们没办法确认我下次去吃还是不是那个味。

   **加法人生**
   
   ---

   ### 效率
   **多流水线 vs 手工串行**
   
   现在用 MySQL 的很多时候动不动就来个**分库分表**，先抛开其合理性不谈，就工作量上来说相比单机是要增加了不少。 mysqltools并不希望看到这种工作量线性的增加到 DBA 身上来，为此 mysqltools 一开始就是冲着并行去的。

   **加量不加工作量**

   ---


## mysqltool介绍
   **mysqltools 要解决的问题** 
   
   1、各类 MySQL 环境的建设(单机，主从，MGR，MHA，读写分离)
   
   2、实例生命周期中的备份，监控，事态感知与修复方案下发

   3、生命周期结束时的清理与资源回收

   ---

   **mysqltools 提出的方案**

   1、把多年经验总结的最佳实践编写成 playbook 一来可以减少重复劳动(同时保证质量) 二来可以在此基础上做加法

   2、强调监控的重要性，把常规问题的解决方案固化为修复脚本，遇到问题是监控系统自动执行，没出大事不要来烦 DBA

   3、最终目标是只要用电环境就是正常的

   ---

   **mysqltools 用到的一些技术**

   1、ansible 用来做批量管理

   2、zabbix 用来做监控和修复方案下发

   3、mysql extrabckup meb mysqltools-python 等等 ...

   ---

## 安装与配置mysqltools
   **安装**
   
   目前mysqltools支持在centos-7.x和以上版本的系统上安装、我们把安装上 mysqltool8 的主机称为管理结点

   ```bash
   # 切换到 root 用户
   sudo su 
   # 下载 mysqltools8 安装包并解压
   wget https://github.com/Neeky/mysqltools8/archive/master.zip

   unzip master.zip
   # 进入到 mysqltools8 的目录并执行自动安装脚本

   mv mysqltools8-master /usr/local/mysqltools8
   cd /usr/local/mysqltools8

   bash dependences/install_mysqltools8.sh

   source /etc/profile
   # 检查是否自动安装上 python-3.7.x
   python3 --version
   Python 3.7.3
   # 检查是否自动安装上 ansible-2.7.10
   ansible --version                                                    
   ansible 2.7.10
   ```
   ---

   **配置(ansible 相关)**

   **1、** 生成的公钥与私钥
   ```bash
   ssh-keygen 
   # 连续回车
   ```
   **2、** 配置到目标主机的互信
   ```bash
   ssh-copy-id root@172.16.192.100
   ```
   **3、** 增加 ansible 的配置文件
   ```
   mkdir /etc/ansible
   touch /etc/ansible/hosts
   echo 'sqlstudio ansible_host=172.16.192.100 ansible_user=root' > /etc/ansible/hosts
   ```
   >完成上面的这些步骤就能在管理机上控制 72.16.192.100 了。

   **4、** 验证一下 ansible 是否配置成功
   ```
   ansible -m ping sqlstudio                                                    
   sqlstudio | SUCCESS => {
       "changed": false,
       "ping": "pong"
   }
   ```

   ---

   **配置(mysqltools)**

   新版本的 mysltools 配置非常简单，全局配置就三个
   ```yaml
   max_memory_size_mb: "{{ 1024 * 512 }}" # 512G内存
   mysql_port: 3306
   mysql_binary_pkg: "mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz"
   #mysql_binary_pkg: "mysql-8.0.16-linux-glibc2.12-x86_64.tar.xz"
   ```
   **1、** mysql_port 指定 MySQL 要监听的地址

   **2、** mysql_binary_pkg 要使用的 MySQL 二进制包

   **3、** max_memory_size_mb 这个值的主要目的用来支持单机多实例的，这里是文档的入门阶段不会讲这个值

   mysqltools 是插件式的，设计成插件式是为了减小 mysqltools 的体积，mysqltools 中的每一个功能都要有一个“插件”来支持，
   拿安装 MySQL 这个事来说支持它的插件就是“MySQL 的二进制安装包” 总的来说所有的插件保存在 sps/插件名/具体的插件版本
   
   事实上现阶段这些配置你可以都不用改，这也是为了 mysqltools 可以拿来就用。你可以进入下一节 [安装MySQL单机](#安装MySQL单机) 体验一下 mysqltools的功能

   ---

## 安装MySQL单机
   **要安装 MySQL 就要有对应的插件支持，而 MySQL 的支持插件就是 MySQL 的二进制安装包**

   **1、** 下载 config.yaml 中指定的 mysql 版本到 mysqltools/sps/mysql/ 目录
   ```
   mkdir -p /usr/local/mysqltools/sps/mysql 
   cd /usr/local/mysqltools/sps/mysql 

   wget https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz
   ```
   **2、** 进入到 mysql 的安装目录
   ```bash
   cd /usr/local/mysqltools8/ansible/mysql/
   ```
   **3、** 修改 hosts 的值为目标机器(之前配置 ansible 时候设置的 sqlstudio,如果你指定了其它的名字改成对应的就好)
   ```
   ---                                                                                                
     - hosts: sqlstudio                                                                               
       remote_user: root                                                                              
       become_user: root                                                                              
       become: yes                                                                                    
       vars_files: 
   ```
   **4、** 自动化单机安装
   ```bash
   ansible-playbook install_single.yaml 

   PLAY [sqlstudio] **********************************************************************************
   
   TASK [Gathering Facts] ****************************************************************************
   ok: [sqlstudio]
   
   TASK [create mysql group] *************************************************************************
   changed: [sqlstudio]
   
   TASK [create user "mysql3306"] ********************************************************************
   changed: [sqlstudio]
   
   TASK [install libaio] *****************************************************************************
   changed: [sqlstudio]
   
   TASK [install numactl] ****************************************************************************
   changed: [sqlstudio]
   
   TASK [install perl-Data-Dumper] *******************************************************************
   changed: [sqlstudio]
   
   TASK [/etc/my-3306.cnf for mysql-8.0.x] ***********************************************************
   skipping: [sqlstudio]
   
   TASK [/etc/my-3306.cnf for mysql-5.7.x] ***********************************************************
   changed: [sqlstudio]
   
   TASK [transfer mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz to target host(s).] *********************
   changed: [sqlstudio]
   
   TASK [generate untar script /tmp/untar_mysql_pkg.sh] **********************************************
   changed: [sqlstudio]
   
   TASK [untar mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz] *******************************************
   changed: [sqlstudio]
   
   TASK [rm /tmp/untar_mysql_pkg.sh] *****************************************************************
   changed: [sqlstudio]
   
   TASK [create libmysqlclient_r.so] *****************************************************************
   changed: [sqlstudio]
   
   TASK [update file privileges] *********************************************************************
   changed: [sqlstudio]
   
   TASK [config ldconfig] ****************************************************************************
   changed: [sqlstudio]
   
   TASK [load so] ************************************************************************************
   changed: [sqlstudio]
   
   TASK [conifg header file] *************************************************************************
   changed: [sqlstudio]
   
   TASK [rm /tmp/mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz] *****************************************
   changed: [sqlstudio]
   
   TASK [transfer users.sql to target host(s).] ******************************************************
   changed: [sqlstudio]
   
   TASK [transfer init_mysql_data_dir.sh to target host(s).] *****************************************
   changed: [sqlstudio]
   
   TASK [init data dir] ******************************************************************************
   changed: [sqlstudio]
   
   TASK [/etc/profile] *******************************************************************************
   changed: [sqlstudio]
   
   TASK [~/.bash_profile] ****************************************************************************
   changed: [sqlstudio]
   
   TASK [~/.bashrc] **********************************************************************************
   changed: [sqlstudio]
   
   TASK [config mysqld-3306.service] *****************************************************************
   changed: [sqlstudio]
   
   TASK [conifg mysqld-3306 auto start] **************************************************************
   changed: [sqlstudio]
   
   TASK [start mysqld-3306] **************************************************************************
   changed: [sqlstudio]
   
   TASK [create backup dir] **************************************************************************
   changed: [sqlstudio]
   
   TASK [create backup script dir] *******************************************************************
   changed: [sqlstudio]
   
   TASK [transfer backup script to target host (mysqldump)] ******************************************
   changed: [sqlstudio]
   
   TASK [config backup job (mysqldump)] **************************************************************
   changed: [sqlstudio]
   
   PLAY RECAP ****************************************************************************************
   sqlstudio                  : ok=30   changed=29   unreachable=0    failed=0
   ```
   >可以看到就算是一个简单的 MySQL 实例的安装 mysqltools 也执行了大大小小的30个步骤，也许随着之后能力和见识的提升步骤
   可能还会更多。

   **5、** 验证一下 MySQL 是否真的安装完成了
   ```bash
   # ssh 到被控主机
   ssh 172.16.192.100
   # 连接一下用于测试 MySQL 服务是否正常
   mysql -uroot -pmtls0352 -h127.0.0.1 -P3306
   mysql: [Warning] Using a password on the command line interface can be insecure.
   Welcome to the MySQL monitor.  Commands end with ; or \g.
   Your MySQL connection id is 3
   Server version: 5.7.26-log MySQL Community Server (GPL)
   
   Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.
   
   Oracle is a registered trademark of Oracle Corporation and/or its
   affiliates. Other names may be trademarks of their respective
   owners.
   
   Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
   
   mysql>
   ```
   ---

   ### mysqltools都做了什么
   **1、** 为每一个实例都在操作系统层面创建不同的用户
   ```bash
   # 如果端口是 3306 那么用户名就是 mysql3306
   ps -ef | grep mysql                                                            
   mysql33+  24081      1  0 16:24 ?        00:00:01 /usr/local/mysql-5.7.26-linux-glibc2.12-x86_64/bin/mysqld --defaults-file=/etc/my-3306.cnf                                                         
   root      24402  24381  0 16:50 pts/1    00:00:00 grep --color=auto mysql

   cat /etc/passwd | grep mysql33
   mysql3306:x:3306:3306::/home/mysql3306:/bin/bash
   ```
   **2、** 根据主机的配置(cpu,mem,disk) 自动生成对应的配置文件
   ```ini
   [mysql]
   auto-rehash
   socket                              =/tmp/mysql-3306.sock             #   /tmp/mysql.sock
   
   
   [mysqld]
   ####: for global
   user                                =mysql3306                          #       mysql
   basedir                             =/usr/local/mysql-5.7.26-linux-glibc2.12-x86_64              #/usr/local/mysql/
   datadir                             =/database/mysql/data/3306     #    /usr/local/mysql/data
   server_id                           =1312                           #   0
   port                                =3306                           #   3306
   character_set_server                =utf8                           #   latin1
   log_bin_trust_function_creators     =ON                             #   0
   max_prepared_stmt_count             =1048576                        #   
   log_timestamps                      =system                         #   utc
   socket                              =/tmp/mysql-3306.sock                #      /tmp/mysql.sock
   read_only                           =OFF                            #   off
   skip_name_resolve                   =1                              #   0
   auto_increment_increment            =1                              #   1
   auto_increment_offset               =1                              #   1
   lower_case_table_names              =1                              #   0
   secure_file_priv                    =                               #   null
   open_files_limit                    =102000                         #   1024
   thread_cache_size                   =16                             #   9
   max_connections                     =151                            # 151
   
   
   ####: for table cache
   table_open_cache                    =4000                           #   2000
   table_definition_cache              =2000                           #   1400
   table_open_cache_instances          =16                             #   16
   
   ####: for binlog
   binlog_format                       =ROW                            #   row
   log_bin                             =mysql-bin                      #   off
   binlog_rows_query_log_events        =ON                             #   off
   log_slave_updates                   =ON                             #   off
   expire_logs_days                    =7                              #   0
   binlog_cache_size                   =64k                            #   65536(64k)
   binlog_checksum                     =none                           #   CRC32
   sync_binlog                         =1                              #   1
   slave-preserve-commit-order         =ON                             #    
   
   ####: for error-log
   log_error                           =err.log                        #   /usr/local/mysql/data/localhost.localdomain.err
   
   ####: for general-log
   general_log                         =OFF                            #   off
   general_log_file                    =general.log                    #   hostname.log
   
   ####: for slow query log
   slow_query_log                      =ON                             #    off
   slow_query_log_file                 =slow.log                       #    hostname.log
   log_queries_not_using_indexes       =OFF                            #    off
   long_query_time                     =2.0                            #    10.000000
   
   ####: for gtid
   gtid_executed_compression_period    =1000                           #   1000
   gtid_mode                           =ON                             #   off
   enforce_gtid_consistency            =ON                             #   off
   
   
   ####: for replication
   skip_slave_start                    =0                              #   
   master_info_repository              =table                          #   file
   relay_log_info_repository           =table                          #   file
   slave_parallel_type                 =logical_clock                  #    database | LOGICAL_CLOCK
   slave_parallel_workers              =4                              #    0
   rpl_semi_sync_master_enabled        =1                              #    0
   rpl_semi_sync_slave_enabled         =1                              #    0
   rpl_semi_sync_master_timeout        =1000                           #    1000(1 second)
   plugin_load_add                     =semisync_master.so             #
   plugin_load_add                     =semisync_slave.so              #
   binlog_group_commit_sync_delay      =200                            #    0      200(0.02% seconde) 
   binlog_group_commit_sync_no_delay_count = 10                        #    0
   binlog_transaction_dependency_tracking  = WRITESET                  #    COMMIT_ORDER | WRITESET       
   transaction_write_set_extraction        = XXHASH64
   
   
   ####: for innodb
   default_storage_engine                          =innodb                     #   innodb
   default_tmp_storage_engine                      =innodb                     #   innodb
   innodb_data_file_path                           =ibdata1:256M:autoextend    #   ibdata1:12M:autoextend
   innodb_temp_data_file_path                      =ibtmp1:64M:autoextend      #   ibtmp1:12M:autoextend
   innodb_buffer_pool_filename                     =ib_buffer_pool             #   ib_buffer_pool
   innodb_log_group_home_dir                       =./                         #   ./
   innodb_log_files_in_group                       =8                          #   2
   innodb_log_file_size                            =128M                       #   50331648(48M)
   innodb_file_per_table                           =ON                         #   on
   innodb_online_alter_log_max_size                =128M                       #   134217728(128M)
   innodb_open_files                               =64000                      #   2000
   innodb_page_size                                =16k                        #   16384(16k)
   innodb_thread_concurrency                       =0                          #   0
   innodb_read_io_threads                          =4                          #   4
   innodb_write_io_threads                         =4                          #   4
   innodb_purge_threads                            =4                          #   4(garbage collection)
   innodb_page_cleaners                            =4                          #   4(flush lru list)
   innodb_print_all_deadlocks                      =ON                         #   off
   innodb_deadlock_detect                          =ON                         #   on
   innodb_lock_wait_timeout                        =50                         #   50
   innodb_spin_wait_delay                          =6                          #   6
   innodb_autoinc_lock_mode                        =2                          #   1
   innodb_flush_sync                               =OFF                        #   on
   innodb_io_capacity                              =4000                       #   200
   innodb_io_capacity_max                          =20000                      #   2000
   #--------Persistent Optimizer Statistics
   innodb_stats_auto_recalc                        =ON                         #   on
   innodb_stats_persistent                         =ON                         #   on
   innodb_stats_persistent_sample_pages            =20                         #   20
   innodb_adaptive_hash_index                      =ON                         #   on
   innodb_change_buffering                         =all                        #   all
   innodb_change_buffer_max_size                   =25                         #   25
   innodb_flush_neighbors                          =0                          #   1
   innodb_flush_method                             =O_DIRECT                   #   
   innodb_doublewrite                              =ON                         #   on
   innodb_log_buffer_size                          =64M                       #    16777216(16M)
   innodb_flush_log_at_timeout                     =1                          #   1
   innodb_flush_log_at_trx_commit                  =1                          #   1
   innodb_buffer_pool_size                         =896M                            # 134217728(128M)
   innodb_buffer_pool_instances                    =1                                # 1
   autocommit                                      =ON                          #  1
   #--------innodb scan resistant
   innodb_old_blocks_pct                           =37                         #    37
   innodb_old_blocks_time                          =1000                       #    1000
   #--------innodb read ahead
   innodb_read_ahead_threshold                     =56                         #    56 (0..64)
   innodb_random_read_ahead                        =off                        #    OFF
   #--------innodb buffer pool state
   innodb_buffer_pool_dump_pct                     =50                         #    25 
   innodb_buffer_pool_dump_at_shutdown             =ON                         #    ON
   innodb_buffer_pool_load_at_startup              =ON                         #    ON
   
   
   ####  for performance_schema
   performance_schema                                                      =on    #    on
   performance_schema_consumer_global_instrumentation                      =on    #    on
   performance_schema_consumer_thread_instrumentation                      =on    #    on
   performance_schema_consumer_events_stages_current                       =on    #    off
   performance_schema_consumer_events_stages_history                       =on    #    off
   performance_schema_consumer_events_stages_history_long                  =off   #    off
   performance_schema_consumer_statements_digest                           =on    #    on
   performance_schema_consumer_events_statements_current                   =on    #    on
   performance_schema_consumer_events_statements_history                   =on    #    on
   performance_schema_consumer_events_statements_history_long              =off   #    off
   performance_schema_consumer_events_waits_current                        =on    #    off
   performance_schema_consumer_events_waits_history                        =on    #    off
   performance_schema_consumer_events_waits_history_long                   =off   #    off
   performance-schema-instrument                                           ='memory/%=COUNTED'
   
   
   # -- ~ _ ~    ~ _ ~     ~ _ ~ -- 
   # base on mysql-5.7.24 
   # generated by https://www.sqlpy.com 2019年5月22日 15:39
   # wechat: jianglegege
   # email: 1721900707@qq.com
   # -- ~ _ ~ --
   ```
   **3、** 自动导出相应的动态库和PATH环境变量头文件
   ```bash
   cat /etc/ld.so.conf.d/mysql-5.7.26-linux-glibc2.12-x86_64.conf 
   /usr/local/mysql-5.7.26-linux-glibc2.12-x86_64/lib/

   cat /etc/profile | grep mysql                                       
   export PATH=/usr/local/mysql-5.7.26-linux-glibc2.12-x86_64/bin/:$PATH 
   ```
   **4、** systemd 服务管理
   ```
   cat /usr/lib/systemd/system/mysqld-3306.service                              
   [Unit]
   Description=MySQL Server
   Documentation=man:mysqld(8)
   Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
   After=network.target
   After=syslog.target
   
   [Install]
   WantedBy=multi-user.target
   
   [Service]
   User=mysql3306
   Group=mysql
   ExecStart=/usr/local/mysql-5.7.26-linux-glibc2.12-x86_64/bin/mysqld --defaults-file=/etc/my-3306.cnf
   LimitNOFILE = 102400
   Environment=MYSQLD_PARENT_PID=1
   #Restart=on-failure
   #RestartPreventExitStatus=1
   ```
   **5、** 创建自动备份任务
   ```
   su mysql3306
   [mysql3306@sqlstudio tmp]$ crontab -l                                                              
   #Ansible: mysql-3306-auto-backup
   0 2 * * * /usr/local/.mtlsscripts/3306-mysqldump-backup.sh
   ```
   ---

   ### 进一步定制mysqltools的行为
   其它更加精细的行为是由 mysqltools8/ansible/mysql/vars/mysql.yaml 这个配置文件来控制的
   ```yaml
   #mysql configure
   mysql_user: "mysql{{mysql_port}}"
   mysql_group: mysql
   mysql_uid: "{{mysql_port}}"
   mysql_gid: 3306
   mysql_backup_tool: "mysqldump"
   mysql_backup_crontab_day: "*"
   mysql_backup_crontab_hour: "2"
   mysql_backup_crontab_minute: "0"
   mysql_base_dir: "/usr/local/{{ mysql_binary_pkg | replace('.tar.gz','') | replace('.tar.xz','') }}"
   mysql_data_dir: "/database/mysql/data/{{mysql_port}}"
   mysql_version: "{{ mysql_binary_pkg | replace('.tar.gz','') | replace('.tar.xz','') }}"
   mysql_backup_dir: "/backup/mysql/{{mysql_port}}"
   mysql_backup_script_dir: "/usr/local/.mtlsscripts"
   mysql_root_pwd: 'mtls0352'
   mysql_monitor_user: 'monitor'
   mysql_monitor_pwd: 'monitor0352'
   mysql_dumper_user: 'dumper'
   mysql_dumper_pwd: 'dumper0352'
   mysql_extra_user: 'extrabackuper'
   mysql_extra_pwd: 'extra0352'
   mysql_binlog_format: "row"
   mysql_xport: "{{ mysql_port * 10 }}"
   mysql_mgrport: "{{ mysql_port * 10 + 1 }}"
   mysql_admin_port: "{{ mysql_port * 10 + 2 }}"
   ```
   >可以看到其它的参数基本上是由全局的 mysql_port mysql_binary_pkg 这两个参数来决定的，通常来说你可以自定义一下用户的密码和备份时间(其实也没有必要改)

   ---

## 单机多实例
   **通过前面 [安装MySQL单机](#安装MySQL单机) 下面看一下单机多实例在 mysqltools 做起来有多简单,实事上只要改一下全局配置中的 port 就行了**

   **1、** 改全局配置文件 mysqltools8/config.yaml 中 mysql_port 的值(在这里我改成了 3308)
   ```yaml
   max_memory_size_mb: "{{ 1024 * 512 }}" # 512G内存
   mysql_port: 3308
   mysql_binary_pkg: "mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz"
   #mysql_binary_pkg: "mysql-8.0.16-linux-glibc2.12-x86_64.tar.xz"
   ```

   **2、** 指定实例的最大可分配内存 max_memory_size_mb 这个参数如果比主机的内存要大，那么最终以主机的内存为准；如果比主机内存要小那么以 max_memory_size_mb 为准。我在这里把新实例的内存设置为 1G 也就是改成 1024 * 1
   ```yaml
   max_memory_size_mb: "{{ 1024 * 1 }}" # 1G内存
   mysql_port: 3308
   mysql_binary_pkg: "mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz"
   #mysql_binary_pkg: "mysql-8.0.16-linux-glibc2.12-x86_64.tar.xz"
   ```
   
   **3、** 执行安装
   ```bash
   ansible-playbook install_single.yaml                                       
   
   PLAY [sqlstudio] **********************************************************************************
   
   TASK [Gathering Facts] ****************************************************************************
   ok: [sqlstudio]
   
   TASK [create mysql group] *************************************************************************
   ok: [sqlstudio]
   
   TASK [create user "mysql3308"] ********************************************************************
   changed: [sqlstudio]
   
   TASK [install libaio] *****************************************************************************
   ok: [sqlstudio]
   
   TASK [install numactl] ****************************************************************************
   ok: [sqlstudio]
   
   TASK [install perl-Data-Dumper] *******************************************************************
   ok: [sqlstudio]
   
   TASK [/etc/my-3308.cnf for mysql-8.0.x] ***********************************************************
   skipping: [sqlstudio]
   
   TASK [/etc/my-3308.cnf for mysql-5.7.x] ***********************************************************
   changed: [sqlstudio]
   
   TASK [transfer mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz to target host(s).] *********************
   changed: [sqlstudio]
   
   TASK [generate untar script /tmp/untar_mysql_pkg.sh] **********************************************
   changed: [sqlstudio]
   
   TASK [untar mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz] *******************************************
   changed: [sqlstudio]
   
   TASK [rm /tmp/untar_mysql_pkg.sh] *****************************************************************
   changed: [sqlstudio]
   
   TASK [create libmysqlclient_r.so] *****************************************************************
   ok: [sqlstudio]
   
   TASK [update file privileges] *********************************************************************
   changed: [sqlstudio]
   
   TASK [config ldconfig] ****************************************************************************
   ok: [sqlstudio]
   
   TASK [load so] ************************************************************************************
   changed: [sqlstudio]
   
   TASK [conifg header file] *************************************************************************
   ok: [sqlstudio]
   
   TASK [rm /tmp/mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz] *****************************************
   changed: [sqlstudio]
   
   TASK [transfer users.sql to target host(s).] ******************************************************
   ok: [sqlstudio]
   
   TASK [transfer init_mysql_data_dir.sh to target host(s).] *****************************************
   changed: [sqlstudio]
   
   TASK [init data dir] ******************************************************************************
   changed: [sqlstudio]
   
   TASK [/etc/profile] *******************************************************************************
   ok: [sqlstudio]
   
   TASK [~/.bash_profile] ****************************************************************************
   changed: [sqlstudio]
   
   TASK [~/.bashrc] **********************************************************************************
   changed: [sqlstudio]
   
   TASK [config mysqld-3308.service] *****************************************************************
   changed: [sqlstudio]
   
   TASK [conifg mysqld-3308 auto start] **************************************************************
   changed: [sqlstudio]
   
   TASK [start mysqld-3308] **************************************************************************
   changed: [sqlstudio]
   
   TASK [create backup dir] **************************************************************************
   changed: [sqlstudio]
   
   TASK [create backup script dir] *******************************************************************
   changed: [sqlstudio]
   
   TASK [transfer backup script to target host (mysqldump)] ******************************************
   changed: [sqlstudio]
   
   TASK [config backup job (mysqldump)] **************************************************************
   changed: [sqlstudio]
   
   PLAY RECAP ****************************************************************************************
   sqlstudio                  : ok=30   changed=20   unreachable=0    failed=0
   ```
   **4、** 实例是否启动
   ```bash
   ps -ef | grep mysql                                                            
   mysql33+  24081      1  0 16:24 ?        00:00:01 /usr/local/mysql-5.7.26-linux-glibc2.12-x86_64/bin/mysqld --defaults-file=/etc/my-3306.cnf 
   mysql33+  32415      1  0 16:25 ?        00:00:00 /usr/local/mysql-5.7.26-linux-glibc2.12-x86_64/bin/mysqld --defaults-file=/etc/my-3308.cnf

   mysql -uroot -pmtls0352 -h127.0.0.1 -P3308                                 
   mysql: [Warning] Using a password on the command line interface can be insecure.
   Welcome to the MySQL monitor.  Commands end with ; or \g.
   Your MySQL connection id is 2
   Server version: 5.7.26-log MySQL Community Server (GPL)
   
   Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.
   
   Oracle is a registered trademark of Oracle Corporation and/or its
   affiliates. Other names may be trademarks of their respective
   owners.
   
   Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
   
   mysql> select @@innodb_buffer_pool_size /1024/1024;                                                
   +--------------------------------------+
   | @@innodb_buffer_pool_size /1024/1024 |
   +--------------------------------------+
   |                         256.00000000 |
   +--------------------------------------+
   1 row in set (0.00 sec)
   ```
   >可以看到当你指定主机的最大可分配内存为 1G 时 mysqltools 给 innodb_buffer_pool_size 分配了 256M。