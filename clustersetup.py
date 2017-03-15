#!/usr/bin/env python3

import argparse
import sys
import os

CORE_SITE_CONTENTS = '''<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
<name>fs.defaultFS</name>
<value>hdfs://{master}:9000/</value>
</property>
<property>
<name>hadoop.tmp.dir</name>
<value>{hadoop_tmp_dir}</value>
</property>
</configuration>
'''

HDFS_SITE_CONTENTS = '''<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
<name>dfs.replication</name>
<value>{hdfs_replication}</value>
</property>
<property>
<name>dfs.permissions</name>
<value>false</value>
</property>
</configuration>
'''

MAPRED_SITE_CONTENTS = '''
<configuration>
<property>
<name>mapreduce.framework.name</name>
<value>yarn</value>
</property>
</configuration>
'''

YARN_SITE_CONTENTS = '''
<configuration>
<property>
<name>yarn.nodemanager.aux-services</name>
<value>mapreduce_shuffle</value>
</property>
<property>
<name>yarn.application.classpath</name>
<value>/opt/hadoop/etc/hadoop, /opt/hadoop/share/hadoop/common/*, /opt/hadoop/share/hadoop/common/lib/*, /opt/hadoop/share/hadoop/hdfs/*, /opt/hadoop/share/hadoop/hdfs/lib/*, /opt/hadoop/share/hadoop/mapreduce/*, /opt/hadoop/share/hadoop/mapreduce/lib/*, /opt/hadoop/share/hadoop/yarn/*, /opt/hadoop/share/hadoop/yarn/lib/*</value>
</property>
<property>
<name>yarn.nodemanager.delete.debug-delay-sec</name>
<value>600</value>
</property>
<property>
<name>yarn.resourcemanager.hostname</name>
<value>{master}</value>
</property>
</configuration>
'''

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--master', default='localhost')
    ap.add_argument('--slave', default=[], action='append', dest='slaves')
    ap.add_argument('--i-am-master', action='store_true')
    ap.add_argument('--hadoop-dir', default='/opt/hadoop')
    ap.add_argument('--hdfs-dir', default='/hdfs')
    ap.add_argument('--format-hdfs', action='store_true', default=False)
    ap.add_argument('--hdfs-replication', default=1, type=int)
    ap.add_argument('--master-aint-a-slave', action='store_true')
    ap.add_argument('--touch-file-if-master', default='/tmp/i_am_master')

    args = ap.parse_args()

    is_master = args.i_am_master or args.master == 'localhost'
    conf_dir = os.path.join(args.hadoop_dir, 'etc', 'hadoop')

    # Generate masters file
    with open(os.path.join(conf_dir, 'masters'), 'wt') as f:
        f.write(args.master)
        f.write('\n')

    # Generate slaves file
    with open(os.path.join(conf_dir, 'slaves'), 'wt') as f:
        if not args.master_aint_a_slave:
            f.write('{}\n'.format(args.master))
        f.write('\n'.join(args.slaves))
        f.write('\n')


    # Generate core-site.xml file
    with open(os.path.join(conf_dir, 'core-site.xml'), 'wt') as f:
        f.write(CORE_SITE_CONTENTS.format(master=args.master, hadoop_tmp_dir=args.hdfs_dir))

    # Generate hdfs-site.xml file
    with open(os.path.join(conf_dir, 'hdfs-site.xml'), 'wt') as f:
        f.write(HDFS_SITE_CONTENTS.format(hdfs_replication=args.hdfs_replication))

    # Generate mapred-site.xml
    with open(os.path.join(conf_dir, 'mapred-site.xml'), 'wt') as f:
        f.write(MAPRED_SITE_CONTENTS)

    # Generate yarn-site.xml
    with open(os.path.join(conf_dir, 'yarn-site.xml'), 'wt') as f:
        f.write(YARN_SITE_CONTENTS.format(master=args.master))


    if is_master:
        with open(args.touch_file_if_master, 'wt') as f:
            print('#!/bin/bash', file=f)
            print('echo I am the master', file=f)
            if args.format_hdfs:
                print('echo Formatting HDFS', file=f)
                print('hdfs namenode -format', file=f)

            print('cp /master.conf /tmp/.docker_generated/supervisord/', file=f)

if __name__ == '__main__':
    sys.exit(main())
