#!/usr/bin/env bash
#
# check site reachability
#

set -euo pipefail
#set -x



function is_mtr_installed {
    # check is mtr present in system
    which mtr > /dev/null
    echo -n $?
}

function get_os_name {
    echo -n $(uname -s)
}

function generate_mtr_report {
    # mtr report
    # $1: host
    # $2: log file

    local host=${1:?host required}
    local log=${2:?logfile path required}

    [ $(is_mtr_installed) -eq 0 ] && {
        echo -e "\n[.] mtr info" >> $log
        mtr --report -c 5 $host >> $log
    } || {
        echo -e "\n[!] no mtr was found" >> $log
    }
}

function get_route_path {
    # $1: host

    local host=${1:?host required}


    # route get / ip route get
    [ "$(get_os_name)" == "Linux" ] && {
        ip route get $host
    } || {
        route get $host
    }
}

function get_ip_rules {
    [ "$(get_os_name)" == "Linux" ] && {
        ip rule show
    } || {
        echo -n "[!] no ip rule command"
    }
}

function main {
    # $1: host

    local script_start_time=$(date +%Y-%m-%d.%H%M%S)
    local host=${1:-www.gismeteo.ru}
    local log=./report.site_check.${host}.${script_start_time}


    # log header
    echo -e "[$script_start_time] Checking $host" >> $log

    # show client ip address
    echo -e "\n[.] client external ip address" >> $log
    curl -s ifconfig.me >> $log

    # get route path to host
    echo -e "\n[.] route path" >> $log
    get_route_path $host >> $log

    # ping
    echo -e "\n[.] ping info" >> $log
    ping -c 10 $host 2>>$log >> $log

    # traceroute
    echo -e "\n[.] tracepath info" >> $log
    traceroute -m 30 -n -w 1 $host 2>>$log >> $log

    # mtr report
    generate_mtr_report $host $log

    # curl
    echo -e "\n[.] http info" >> $log
    curl https://$host/ \
        -svLAff \
        -o /dev/null \
        -w '\n[.] curl stats:
        \rcontent_type:        %{content_type}
        \rhttp_connect:        %{http_connect}
        \rlocal_ip:            %{local_ip}
        \rlocal_port:          %{local_port}
        \rnum_connects:        %{num_connects}
        \rnum_redirects:       %{num_redirects}
        \rredirect_url:        %{redirect_url}
        \rremote_ip:           %{remote_ip}
        \rremote_port:         %{remote_port}
        \rsize_download:       %{size_download}
        \rsize_header:         %{size_header}
        \rsize_request:        %{size_request}
        \rsize_upload:         %{size_upload}
        \rspeed_download:      %{speed_download} B/s
        \rssl_verify_result:   %{ssl_verify_result}
        \rtime_appconnect:     %{time_appconnect}
        \rtime_connect:        %{time_connect}
        \rtime_namelookup:     %{time_namelookup}
        \rtime_pretransfer:    %{time_pretransfer}
        \rtime_redirect:       %{time_redirect}
        \rtime_starttransfer:  %{time_starttransfer}
        \rtime_total:          %{time_total}
        \rurl_effective:       %{url_effective}
        \rhttp_code:           %{http_code}\n' \
        2>>$log >> $log

        # network statistics
        echo -e "\n[.] network statistics" >> $log
        netstat -s >> $log
}


main $@


