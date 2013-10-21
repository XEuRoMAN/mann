#!/bin/bash

apt-get -qq update
apt-get -qq install wget

#
# NetBeans
#
while [ "$answer_nb" != "y" -a "$answer_nb" != "n" ]
    do
        echo "=========="
        printf "Do you want to install NetBeans 7.2.1?\n[y/n]\n"
        read answer_nb

        if [ "$answer_nb" = "y" ]
            then
                echo "Downloding NetBeans 7.2.1. It takes a few minutes..."
                wget -Nq http://download.netbeans.org/netbeans/7.2.1/final/bundles/netbeans-7.2.1-ml-php-linux.sh

                echo "Installing Java 7 JRE"
                apt-get -qq install openjdk-7-jre

                echo "Installing NetBeans 7.2.1"
                su root ./netbeans-7.2.1-ml-php-linux.sh
                #rm ./netbeans-7.2.1-ml-php-linux.sh
        elif [ "$answer_nb" = "n" ]
            then
                echo "NetBeans won't be installed"
        fi
    done


#
# node.js
#
while [ "`echo "$answer_njs" | awk '{ print $1 }'`" != "1" -a "$answer_njs" != "2" ]
    do
        echo "=========="
        echo "What do you want to do with node.js?"

        node_location=`whereis node | awk '{ print $2 }'`
        if [ "$node_location" == "" ]
            then
                echo "1 - Install"
            else
                echo "1 - Update to stable version"
                echo "1 x.x.x - Update to selected x.x.x version"
            fi
        echo "2 - Skip"

        read answer_njs
    done


if [ "$answer_njs" == "1" -a "$node_location" == "" ]
    then
        echo "Downloding node.js. It takes a few minutes..."
        wget -Nq http://nodejs.org/dist/node-latest.tar.gz

        echo "Updating external tools..."
        apt-get -qq install python g++ make

        echo "Extracting node.js..."
        tar -xzf node-latest.tar.gz && cd node-v*

        echo "Installing node.js..."
        ./configure
        make
        make install
        echo "node.js installed."
elif [ "`echo "$answer_njs" | awk '{ print $1 }'`" == "1" -a "$node_location" != "" ]
    then
        apt-get -qq install curl
        npm cache clean -f
        npm install -g n

        version_njs=`echo "$answer_njs" | awk '{ print $2 }'`
        if [ "$version_njs" == "" ]
            then
                n stable
            else
                n $version_njs
            fi
        echo "node.js updated."
    else
        echo "node.js skipped."
    fi


#
# MongoDB
#
while [ "`echo "$answer_md" | awk '{ print $1 }'`" != "1" -a "$answer_md" != "2" ]
    do
        echo "=========="
        echo "What do you want to do with MongoDB?"

        mongo_location=`whereis mongo | awk '{ print $2 }'`
        if [ "$mongo_location" == "" ]
            then
                echo "1 - Install"
            else
                echo "1 - Update to stable version"
                echo "1 x.x.x - Update to selected x.x.x version"
            fi
        echo "2 - Skip"

        read answer_md
    done


if [ "$answer_md" == "1" -a "$mongo_location" == "" ]
    then
        echo "Setting up MongoDB repository..."
        apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
        echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
        apt-get -qq update

        echo "Installing MongoDB..."
        apt-get -qq install mongodb-10gen
        echo "MongoDB installed."
elif [ "`echo "$answer_md" | awk '{ print $1 }'`" == "1" -a "$mongo_location" != "" ]
    then
        echo "Setting up MongoDB repository..."
        apt-key -qq adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
        echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | tee /etc/apt/sources.list.d/mongodb.list
        apt-get -qq update

        version_md=`echo "$answer_md" | awk '{ print $2 }'`
        if [ "$version_md" == "" ]
            then
                apt-get -qq install mongodb-10gen
            else
                apt-get -qq install mongodb-10gen=$version_md
            fi
        echo "MongoDB updated."
    else
        echo "MongoDB skipped."
    fi

#
# pretty MongoDB
#
while [ "$answer_prt" != "y" -a "$answer_prt" != "n" ]
    do
        echo "=========="
        printf "Make MongoDB pretty() for default?\n[y/n]\n"
        read answer_prt

        if [ "$answer_prt" = "y" ]
            then
                touch $HOME/.mongorc.js
                exist_prt=`cat $HOME/.mongorc.js | grep "DBQuery.prototype._prettyShell = true"`
                if [ "$exist_prt" == "" ]
                    then
                        echo "DBQuery.prototype._prettyShell = true" >> $HOME/.mongorc.js
                        echo "prettyShell set to true."
                    else
                        echo "prettyShell already set to true."
                    fi
            fi
    done

#
# MongoDB replicas
#
mongo_location=`whereis mongo | awk '{ print $2 }'`

if [ "$mongo_location" != "" ]
    then
        is_ubuntu=`uname -a | grep ubuntu`

        while [ "$answer_mdrep" != "y" -a "$answer_mdrep" != "n" ]
            do
                echo "=========="
                printf "Do you want to install MongoDB replicas?\n[y/n]\n"
                read answer_mdrep

                if [ "$answer_mdrep" = "y" ]
                    then
                        replicas_count=0
                        while [ $replicas_count -lt 2 ]
                            do
                                echo "How many replicas to create? [2-n]"
                                read replicas_count
                            done

                        for (( i=1; i<=$replicas_count; i++ ))
                            do
                                if [ $i -eq 1 ]
                                    then
                                        end=""

                                        if [ "$is_ubuntu" == "" ]
                                            then
                                                mongo_main=`ps aux | grep -m 1 mongodb.conf | awk '{ print $2 }'`
                                                if [ "$mongo_main" != "" ]
                                                    then
                                                        kill $mongo_main
                                                    fi
                                            fi
                                    else
                                        end="$i"
                                        cp /etc/mongodb.conf /etc/mongodb$end.conf
                                        if [ "$is_ubuntu" == "" ]
                                            then
                                                cp /etc/init.d/mongodb /etc/init.d/mongodb$end
                                            fi
                                        mkdir -p /var/log/mongodb$end
                                        chmod 0777 /var/log/mongodb$end
                                        mkdir -p /var/lib/mongodb$end
                                        chmod 0777 /var/lib/mongodb$end
                                    fi

                                new_content=`cat /etc/mongodb$end.conf`

                                path_var=`echo "$new_content" | grep "dbpath=/var/lib/mongodb"`
                                if [ "$path_var" == "" ]
                                    then
                                        echo "dbpath=/var/lib/mongodb$end" >> /etc/mongodb$end.conf
                                    else
                                        new_content=`echo "$new_content" | sed "s;$path_var;dbpath=/var/lib/mongodb$end;g"`
                                    fi

                                log_var=`echo "$new_content" | grep "logpath=/var/log/mongodb"`
                                if [ "$log_var" == "" ]
                                    then
                                        echo "logpath=/var/log/mongodb$end/mongodb.log" >> /etc/mongodb$end.conf
                                    else
                                        new_content=`echo "$new_content" | sed "s;$log_var;logpath=/var/log/mongodb$end/mongodb.log;g"`
                                    fi

                                port_var=`echo "$new_content" | grep "port ="`
                                port=`expr 27017 + $i - 1`
                                if [ "$port_var" == "" ]
                                    then
                                        echo "port = $port" >> /etc/mongodb$end.conf
                                    else
                                        new_content=`echo "$new_content" | sed "s/$port_var/port = $port/g"`
                                    fi

                                rs_var=`echo "$new_content" | grep "replSet ="`
                                if [ "$rs_var" == "" ]
                                    then
                                        echo "replSet = rs0" >> /etc/mongodb$end.conf
                                    else
                                        new_content=`echo "$new_content" | sed "s/$rs_var/replSet = rs0/g"`
                                    fi

                                echo "$new_content" > /etc/mongodb$end.conf

                                if [ "$is_ubuntu" != "" ]
                                    then
                                        touch /etc/init/mongodb$end.conf
                                        printf "description "MongoDB"\n\npre-start script\n    mkdir -p /var/lib/mongodb$end/\n    mkdir -p /var/log/mongodb$end/\nend script\n\nstart on runlevel [2345]\nstop on runlevel [06]\n\nscript\n    exec /usr/bin/mongod --config /etc/mongodb$end.conf\nend script" > /etc/init/mongodb$end.conf
                                    else
                                        new_content_init=`cat /etc/init.d/mongodb$end`

                                        name_var=`echo "$new_content_init" | grep "NAME=mongodb"`
                                        new_content_init=`echo "$new_content_init" | sed "s/$name_var/NAME=mongodb$end/g"`

                                        conf_var=`echo "$new_content_init" | grep "CONF="`
                                        new_content_init=`echo "$new_content_init" | sed "s;$conf_var;CONF=/etc/mongodb$end.conf;g"`

                                        echo "$new_content_init" > /etc/init.d/mongodb$end
                                    fi

                                
                                service mongodb$end restart
                                sleep 10
                            done

                        host_name=`hostname`
                        mongo --port 27017 --eval "printjson(rs.initiate())"
                        sleep 30
                        for (( i=1; i<$replicas_count; i++ ))
                            do
                                port=`expr 27017 + $i`
                                arr_nr=`expr $i - 1`
                                mongo --port 27017 --eval "printjson(rs.add('$host_name:$port'))"
                                sleep 5
                            done

                        priority=101;
                        for (( i=0; i<$replicas_count; i++ ))
                            do
                                priority=`expr $priority - 1`

                                mongo --port 27017 --eval "conf = rs.conf(); conf.members[$i].priority = $priority; printjson(rs.reconfig(conf))"
                                sleep 5
                                if [ $i -eq 1 ]
                                    then
                                        mongo --port 27017 --eval "conf = rs.conf(); conf.members[$i].tags = {type: 'realtime'}; rs.reconfig(conf);"
                                        sleep 5
                                elif [ $i -ne 0 ]
                                    then
                                        mongo --port 27017 --eval "conf = rs.conf(); conf.members[$i].tags = {type: 'periodic'}; rs.reconfig(conf);"
                                        sleep 5
                                    fi
                            done

                        mongo --port 27017 --eval "printjson(rs.conf())"

                        echo "MongoDB replicas set."
                elif [ "$answer_mdrep" = "n" ]
                    then
                        echo "MongoDB replicas won't be installed"
                fi
            done
    fi


#
# Apache
#
while [ "$answer_ap" != "y" -a "$answer_ap" != "n" ]
    do
        echo "=========="
        printf "Do you want to install Apache2?\n[y/n]\n"
        read answer_ap

        if [ "$answer_ap" = "y" ]
            then
                echo "Installing Apache2..."
                apt-get -qq install apache2
                echo "Apache2 installed."

                echo "Let's configure some..."

                while [ "$url" == "" ]
                    do
                        echo "What url do you want to use for nodejs project (i.e. best.web, mysite.js, etc):"
                        read url
                    done

                while [ "$dir" == "" ]
                    do
                        echo "Where is project index.js file (full path i.e. /home/$USER/www/my-project/):"
                        read dir
                    done
                
                while [ "$node_port" == "" ]
                    do
                        echo "Which port nodejs will listen (default: 8000):"
                        read node_port
                    done


                echo "Writing settings..."
                etc_hosts=`cat /etc/hosts | grep -m 1 localhost`
                echo "`cat /etc/hosts | sed "s/$etc_hosts/$etc_hosts $url/g"`" > /etc/hosts

                a2enmod proxy
                a2enmod proxy_http

                mkdir -p /etc/apache2/conf.d/
                touch /etc/apache2/conf.d/custom

                printf "\n<VirtualHost *:80>\n    DocumentRoot $dir\n    ServerName $url\n\n    ProxyPass / http://$url:$node_port/\n    ProxyPassReverse / http://$url:$node_port/\n</VirtualHost>\n" >> /etc/apache2/conf.d/custom


                confd=`cat /etc/apache2/apache2.conf | grep "IncludeOptional conf.d/*"`
                if [ "$confd" == "" ]
                    then
                        printf "\nIncludeOptional conf.d/*" >> /etc/apache2/apache2.conf
                    fi

                httpd=`cat /etc/apache2/apache2.conf | grep "Include httpd.conf"`
                touch /etc/apache2/httpd.conf
                if [ "$httpd" == "" ]
                    then
                        printf "\nInclude httpd.conf" >> /etc/apache2/apache2.conf
                        echo "ServerName localhost" >> /etc/apache2/httpd.conf
                    fi

                server_name=`cat /etc/apache2/httpd.conf | grep ServerName`
                if [ "$server_name" == "" ]
                    then
                        echo "ServerName localhost" >> /etc/apache2/httpd.conf
                    fi

                service apache2 restart
            fi
    done


echo "DONE! Press ENTER to exit..."
read exit_confirm

