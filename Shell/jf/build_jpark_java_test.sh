#!/bin/bash
source /root/.bash_profile
export MAVEN_OPTS='-Xms1024m -Xmx1024m'
if [ -d /data/jpark/java-code/code-$1 ]; then
    cd /data/jpark/java-code/code-$1
    mvn -DskipTests=true -Dmaven.compile.fork=true -T 1C install -Pdev -f jf-jpark-parent/pom.xml
fi
