    #!/bin/bash
    ##############################################################################
    #    Open LiteSpeed is an open source HTTP server.                           #
    #    Copyright (C) 2013 - 2019 LiteSpeed Technologies, Inc.                  #
    #                                                                            #
    #    This program is free software: you can redistribute it and/or modify    #
    #    it under the terms of the GNU General Public License as published by    #
    #    the Free Software Foundation, either version 3 of the License, or       #
    #    (at your option) any later version.                                     #
    #                                                                            #
    #    This program is distributed in the hope that it will be useful,         #
    #    but WITHOUT ANY WARRANTY; without even the implied warranty of          #
    #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            #
    #    GNU General Public License for more details.                            #
    #                                                                            #
    #    You should have received a copy of the GNU General Public License       #
    #    along with this program. If not, see http://www.gnu.org/licenses/.      #
    ##############################################################################

    ###    Author: Xpressos CDC
    ###    https://github.com/xpressos/OLSSCRIPTS-olsdomain
    ###    Modified by irfani.dev (2025) - Added interactive menu, SSL enablement, and other improvements.
    ###    https://github.com/mirfani340/ols-domain-management

    FORCEYES=0
    ALLERRORS=0

    #Site settings
    INSTALLSITE=0
    SITEPATH=
    DOMAIN=*
    EMAIL=

    #OS Info
    OSNAMEVER=UNKNOWN
    OSNAME=
    OSVER=
    OSTYPE=`uname -m`

    #Webserver settings
    SERVER_ROOT=/usr/local/lsws
    PUBLIC_HTML=/usr/local/lsws/www/
    VIRTHOST=$(ps -ef | awk '{for (I=1;I<=NF;I++) if ($I == "virtualhost") {printf echo "," $(I+1)};}' /usr/local/lsws/conf/httpd_config.conf)

    fn_display_license() {
        echo
        echoY '*************************************************************************'
        echoY '* Open LiteSpeed One-Click Domain Installation                          *'
        echoY '* Originally Copyright (C) 2019 Xpressos CDC                            *'
        echoY '* Modifications Copyright (C) 2025 irfani.dev                           *'
        echoY '* License: GNU GPL v3 or later (see LICENSE file for details)           *'
        echoY '* This program comes with ABSOLUTELY NO WARRANTY.                       *'
        echoY '*************************************************************************'
    }

    fn_install_info() {
    echo
    echoY "Installing your New Domain with the following parameters:"
    echoY "Enable SSL:       " "Yes"
    echoY "Site Domain:      " "$DOMAIN"
    echoY "Site Path:        " "$SITEPATH"
    echo "========================================================================="
    echo
    }

    fn_check_os() {
        OSNAMEVER=
        OSNAME=
        OSVER=
    
        
        if [ -f /etc/redhat-release ] ; then
            cat /etc/redhat-release | grep " 6." >/dev/null
            if [ $? = 0 ] ; then
                OSNAMEVER=CENTOS6
                OSNAME=centos
                OSVER=6
            else
                cat /etc/redhat-release | grep " 7." >/dev/null
                if [ $? = 0 ] ; then
                    OSNAMEVER=CENTOS7
                    OSNAME=centos
                    OSVER=7
                else
                    # Try to parse for 8/9 or AlmaLinux/Rocky from redhat-release (some clones keep file)
                    grep -iE 'AlmaLinux release 9' /etc/redhat-release >/dev/null 2>&1 && {
                        OSNAMEVER=ALMA9
                        OSNAME=almalinux
                        OSVER=9
                    }
                    if [ -z "$OSNAMEVER" ]; then
                        grep -iE 'AlmaLinux release 8' /etc/redhat-release >/dev/null 2>&1 && {
                            OSNAMEVER=ALMA8
                            OSNAME=almalinux
                            OSVER=8
                        }
                    fi
                    if [ -z "$OSNAMEVER" ]; then
                        grep -iE 'Rocky Linux release 9' /etc/redhat-release >/dev/null 2>&1 && {
                            OSNAMEVER=ROCKY9
                            OSNAME=rocky
                            OSVER=9
                        }
                    fi
                    if [ -z "$OSNAMEVER" ]; then
                        grep -iE 'Rocky Linux release 8' /etc/redhat-release >/dev/null 2>&1 && {
                            OSNAMEVER=ROCKY8
                            OSNAME=rocky
                            OSVER=8
                        }
                    fi
                fi
            fi
        elif [ -f /etc/lsb-release ] ; then
            cat /etc/lsb-release | grep "DISTRIB_RELEASE=14." >/dev/null
            if [ $? = 0 ] ; then
                OSNAMEVER=UBUNTU14
                OSNAME=ubuntu
                OSVER=trusty
                
            else
                cat /etc/lsb-release | grep "DISTRIB_RELEASE=16." >/dev/null
                if [ $? = 0 ] ; then
                    OSNAMEVER=UBUNTU16
                    OSNAME=ubuntu
                    OSVER=xenial
                    
                    
                else
                    cat /etc/lsb-release | grep "DISTRIB_RELEASE=18." >/dev/null
                    if [ $? = 0 ] ; then
                        OSNAMEVER=UBUNTU18
                        OSNAME=ubuntu
                        OSVER=bionic
                        
                    fi
                fi
            fi
        elif [ -f /etc/debian_version ] ; then
            cat /etc/debian_version | grep "^7." >/dev/null
            if [ $? = 0 ] ; then
                OSNAMEVER=DEBIAN7
                OSNAME=debian
                OSVER=wheezy
                
            else
                cat /etc/debian_version | grep "^8." >/dev/null
                if [ $? = 0 ] ; then
                    OSNAMEVER=DEBIAN8
                    OSNAME=debian
                    OSVER=jessie
                    
                else
                    cat /etc/debian_version | grep "^9." >/dev/null
                    if [ $? = 0 ] ; then
                        OSNAMEVER=DEBIAN9
                        OSNAME=debian
                        OSVER=stretch
                        
                    fi
                fi
            fi
        fi

        # Generic /etc/os-release fallback for newer clones (AlmaLinux 9+ etc.)
        if [ -z "$OSNAMEVER" ] && [ -f /etc/os-release ]; then
            . /etc/os-release
            case "$ID" in
                almalinux)
                    case "$VERSION_ID" in
                        9*) OSNAMEVER=ALMA9; OSNAME=almalinux; OSVER=9 ;;
                        8*) OSNAMEVER=ALMA8; OSNAME=almalinux; OSVER=8 ;;
                    esac ;;
                rocky)
                    case "$VERSION_ID" in
                        9*) OSNAMEVER=ROCKY9; OSNAME=rocky; OSVER=9 ;;
                        8*) OSNAMEVER=ROCKY8; OSNAME=rocky; OSVER=8 ;;
                    esac ;;
                centos)
                    case "$VERSION_ID" in
                        8*) OSNAMEVER=CENTOS8; OSNAME=centos; OSVER=8 ;;
                        9*) OSNAMEVER=CENTOS9; OSNAME=centos; OSVER=9 ;;
                    esac ;;
            esac
        fi

        if [ "x$OSNAMEVER" = "x" ] ; then
            echoR "Sorry, currently this script supports CentOS(6,7), Ubuntu(14,16,18), Debian(7-9), and RHEL clones (AlmaLinux/Rocky 8/9)."
            echoR "You can download the source code and build from it."
            echoR "The url of the source code is https://github.com/xpressos/OLSscripts-olsdomain."
            echo 
            exit 1
        else
            if [ "x$OSNAME" = "xcentos" ] ; then
            echo
                echoG "Current platform is "  "$OSNAME $OSVER."
            else
                export DEBIAN_FRONTEND=noninteractive
                echoG "Current platform is "  "$OSNAMEVER $OSNAME $OSVER."
            fi
        fi
    }


    fn_install_site() {
        if [ ! -e "$SITEPATH" ] ; then
            echo
                echoY "Installing your Site ..."
            echo
                mkdir -p $SITEPATH
            wget -P $SITEPATH https://github.com/xpressos/OLSscripts-olsdomain/raw/master/sitefiles.tar.gz
            cd $SITEPATH
            tar -xzf sitefiles.tar.gz
            rm sitefiles.tar.gz
            mv $SITEPATH/logs $PUBLIC_HTML/$DOMAIN
            chown -R nobody:nobody $PUBLIC_HTML/$DOMAIN
            echoY "[OK] Site Installed."
        
        else
            echo
        echoR "WARNING: $SITEPATH already exists."
        echoR "$DOMAIN must already be installed!"
        fi
    }

    function echoY
    {
        FLAG=$1
        shift
        echo -e "\033[38;5;148m$FLAG\033[39m$@"
    }

    function echoG
    {
        FLAG=$1
        shift
        echo -e "\033[38;5;71m$FLAG\033[39m$@"
    }

    function echoR
    {
        FLAG=$1
        shift
        echo -e "\033[38;5;203m$FLAG\033[39m$@"
    }

    # Attempt a graceful restart (reload) of OpenLiteSpeed; fallback to restart
    fn_graceful_restart() {
        if [ -x "$SERVER_ROOT/bin/lswsctrl" ]; then
            echoY "Applying configuration (graceful restart)..." ""
            $SERVER_ROOT/bin/lswsctrl reload 2>/dev/null || $SERVER_ROOT/bin/lswsctrl restart
        else
            echoR "lswsctrl not found at $SERVER_ROOT/bin/lswsctrl"
        fi
    }

    # Enable SSL for a vhost by adding a vhssl block & listener mapping if missing
    fn_enable_ssl_vhost() {
        local D="$1"
        [ -z "$D" ] && echoR "fn_enable_ssl_vhost: domain missing" && return 1
        local VHCONF="$SERVER_ROOT/conf/vhosts/$D/vhconf.conf"
        local HTTPD_CONF="$SERVER_ROOT/conf/httpd_config.conf"
        local CERT_DIR="/etc/letsencrypt/live/$D"
        local FULLCHAIN="$CERT_DIR/fullchain.pem"
        local PRIVKEY="$CERT_DIR/privkey.pem"

        if [ ! -f "$FULLCHAIN" ] || [ ! -f "$PRIVKEY" ]; then
            echoR "Certificate files not found for $D at $CERT_DIR"; return 1
        fi

        if [ ! -f "$VHCONF" ]; then
            echoR "vHost config $VHCONF not found"; return 1
        fi

        # Add vhssl block if absent
        if ! grep -qi '^vhssl' "$VHCONF"; then
            cat >> "$VHCONF" <<SSLEND
    vhssl  {
    keyFile                 $PRIVKEY
    certFile                $FULLCHAIN
    certChain               1
    enableECDHE             1
    renegProtection         1
    sslProtocol             30
    enableSpdy              15
    sessionCache            1
    sessionCacheSize        20000
    sessionCacheTimeout     300
    }
    SSLEND
            echoY "Added vhssl block to $VHCONF" ""
        else
            echoY "vhssl block already present in $VHCONF (skipping)" ""
        fi

        # Ensure there's a listener for 443 mapping this domain
        if [ -f "$HTTPD_CONF" ]; then
            if ! grep -q "listener SSL" "$HTTPD_CONF"; then
                cat >> "$HTTPD_CONF" <<LEND

    listener SSL {
    address                 *:443
    secure                  1
    map                     $D $D
    }
    LEND
                echoY "Created SSL listener and mapped $D" ""
            else
                # Add map line to existing SSL listener if missing
                grep -q "map[[:space:]]\+$D[[:space:]]\+$D" "$HTTPD_CONF" || {
                    # Insert map inside first SSL listener block prior to its closing brace
                    awk -v dom="$D" '
                        BEGIN{ssl=0}
                        /^listener[[:space:]]+SSL[[:space:]]*{/ {ssl=1}
                        ssl && /^}/ {print "  map                     " dom " " dom; ssl=0}
                        {print}
                    ' "$HTTPD_CONF" > "$HTTPD_CONF.tmp" && mv "$HTTPD_CONF.tmp" "$HTTPD_CONF"
                    echoY "Added map for $D to existing SSL listener" ""
                }
            fi
        else
            echoR "$HTTPD_CONF not found; cannot ensure SSL listener"
        fi

        fn_graceful_restart
    }

    fn_install_ssl() {
        echo
        echoY "Installing SSL (webroot) ..." ""
        echo
        if ! command -v certbot >/dev/null 2>&1; then
            echoY "certbot not found - attempting to install..." ""
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian) apt-get update -y && apt-get install -y certbot ;; 
                    centos|almalinux|rocky) yum install -y epel-release && yum install -y certbot ;; 
                    *) echoR "Unsupported package manager for auto-install. Please install certbot manually."; return 1 ;;
                esac
            fi
        fi
        if [ -z "$SITEPATH" ]; then
            # Fallback default webroot guess
            SITEPATH="/usr/local/lsws/www/$DOMAIN"
        fi
        certbot certonly --webroot -w "$SITEPATH" -d "$DOMAIN" -m "$EMAIL" --agree-tos -n -v || {
            echoR "Certbot failed."; return 1; }
        echoY "SSL certificate obtained for $DOMAIN" ""
    }

    fn_restart_ols() {
        echo
        echo "Domain Installed"
        echoY "Restarting OpenLiteSpeed Webserver ..."
        $SERVER_ROOT/bin/lswsctrl restart
        echo
    }

    fn_test_domain() {
        echo
            echoY "Testing ..."
        fn_test_site
    }

    fn_test_webpage() {
        local URL=$1
            local KEYWORD=$2
            local PAGENAME=$3

            rm -rf tmp.tmp
            wget --no-check-certificate -O tmp.tmp  $URL >/dev/null 2>&1
            grep "$KEYWORD" tmp.tmp  >/dev/null 2>&1
        
            if [ $? != 0 ] ; then
            echoR "Error: $PAGENAME Failed."
        else
            echo "[OK] $PAGENAME Passed."
        echo
        echoG "Congratulations!"
            echo "Your site is live at https://$DOMAIN"
        fi
        rm tmp.tmp
    }

    fn_test_site() {
        fn_test_webpage http://$DOMAIN/ "Congratulation" "Site load test"  
    }

    fn_config_httpd() {
        if [ -e "$SERVER_ROOT/conf/httpd_config.conf" ] ; then
            cat $SERVER_ROOT/conf/httpd_config.conf | grep "virtualhost $DOMAIN" >/dev/null
            if [ $? != 0 ] ; then
            sed -i "/listener\b/a \ \ map                     $DOMAIN $DOMAIN" -i.bkp /usr/local/lsws/conf/httpd_config.conf
                VHOSTCONF=$SERVER_ROOT/conf/vhosts/$DOMAIN/vhconf.conf

                cat >> $SERVER_ROOT/conf/httpd_config.conf <<END 

    virtualhost $DOMAIN {
    vhRoot                  $SITEPATH
    configFile              $VHOSTCONF
    allowSymbolLink         1
    enableScript            1
    restrained              0
    setUIDMode              2
    }

    END
        
                mkdir -p $SERVER_ROOT/conf/vhosts/$DOMAIN/
                            cat > $VHOSTCONF <<END 
    docRoot                   \$VH_ROOT/
    vhDomain                  $DOMAIN
    enableGzip                1
    errorlog  {
    useServer               1
    }
    accesslog $SERVER_ROOT/logs/$DOMAIN/access.log {
    useServer               0
    logHeaders              3
    rollingSize             100M
    keepDays                30
    compressArchive         1
        logFormat               %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"
    }
    index  {
    useServer               0
    indexFiles              index.html, index.php
    autoIndex               0
    autoIndexURI            /_autoindex/default.php
    }
    errorpage 404 {
    url                     /404.html
    }
    expires  {
    enableExpires           1
    }
    accessControl  {
    allow                   *
    }
    rewrite  {
    enable                  0
    logLevel                0
    }

    END
                chown -R lsadm:lsadm $SERVER_ROOT/conf/
            fi
            
            
        else
            echoR "$SERVER_ROOT/conf/httpd_config.conf is missing."
            ALLERRORS=1
        fi
    }


    fn_usage() {
        echoY "USAGE:                             " "$0 [options] [options] ..."
        echoY "OPTIONS                            "
        echoG " --domain(-d) DOMAIN               " "To install your site with your chosen domain(option required)."
        echoG " --sitepath(-p) SITEPATH           " "To specify a location for the new site installation(option required)."
        echoG " --email(-e) EMAIL              " "To specify an email for SSL installation(option required)."
        echoG " --quiet                           " "Set to quiet mode, won't prompt to input anything."
        echoG " --help(-h)                        " "To display usage."
        echo
        echoY "EXAMPLE                           "
        echoG "./olsdomain -d mysite.com -e myemail@myprovider.com -p /home/myuser/www"  ""
        echo  "                                   To install your site \"mysite.com\" in the \"/home/myuser/www\" server folder and use your email \"myemail@myprovider.com\" for SSL certificate."
        echo
    }

    while [ "$1" != "" ] ; do
        case $1 in 
            -e| --email )              
                                        shift
                                        EMAIL=$1
                                        ;;
            
            -d| --domain )         
                                        shift
                                        DOMAIN=$1
                                        ;;
                                        
                                        
        -p| --sitepath )           
                                        shift
                                        SITEPATH=$1			
                                        ;;

                                        
                --quiet )              FORCEYES=1
                                        ;;
                                    
            
            -h| --help )                fn_usage
                                        exit 0
                                        ;;

            * )                         fn_usage
                                        exit 0
                                        ;;
        esac
        shift
    done

    # ===================== Interactive Dashboard Additions =====================

    menu_add_domain() {
        echo
        echoY "Add New Domain" ""
        read -rp "Enter domain (e.g. example.com): " DOMAIN
        if [ -z "$DOMAIN" ]; then
            echoR "Domain cannot be empty."; return 1
        fi
        DEFAULT_SITEPATH="/usr/local/lsws/www/$DOMAIN"
        read -rp "Site root path [$DEFAULT_SITEPATH]: " SITEPATH_INPUT
        SITEPATH=${SITEPATH_INPUT:-$DEFAULT_SITEPATH}

        # Derive standard paths
        VH_CONF_DIR="/usr/local/lsws/conf/vhosts/$DOMAIN"
        LOG_DIR="/usr/local/lsws/logs/$DOMAIN"
        HTML_DIR="$SITEPATH" # keep compatibility with existing script using SITEPATH as vhRoot/docRoot

        echo
        echoY "Summary:" ""
        echo " Domain: $DOMAIN"
        echo " vHost Conf Dir: $VH_CONF_DIR"
        echo " Log Dir: $LOG_DIR"
        echo " Site Root (docRoot): $HTML_DIR"
        echo
        read -rp "Proceed with creation? (y/N): " CONFIRM
        if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
            echoR "Canceled."; return 1
        fi

        SITEPATH=$HTML_DIR
        # Create directories
        mkdir -p "$HTML_DIR" "$LOG_DIR" "$VH_CONF_DIR"
        chown -R nobody:nobody "$HTML_DIR" 2>/dev/null || true
        chown -R lsadm:lsadm /usr/local/lsws/conf/vhosts 2>/dev/null || true

        # Provide minimal index if missing
        if [ ! -f "$HTML_DIR/index.html" ]; then
            cat > "$HTML_DIR/index.html" <<EOM
    <!doctype html><title>$DOMAIN</title><h1>It works! ($DOMAIN)</h1>
    EOM
        fi

        # Configure httpd (reuses existing function expecting DOMAIN & SITEPATH)
        fn_config_httpd
        echoY "Domain added. You may now choose 'Install SSL On Domain' for certificates." ""
        fn_graceful_restart
    }

    menu_remove_domain() {
        echo
        echoY "Remove Domain" ""
        read -rp "Enter domain to remove: " REMOVE_DOMAIN
        if [ -z "$REMOVE_DOMAIN" ]; then
            echoR "Domain cannot be empty."; return 1
        fi

        VH_CONF_DIR="/usr/local/lsws/conf/vhosts/$REMOVE_DOMAIN"
        HTTPD_CONF="/usr/local/lsws/conf/httpd_config.conf"
        LOG_DIR="/usr/local/lsws/logs/$REMOVE_DOMAIN"
        WWW_DIR="/usr/local/lsws/www/$REMOVE_DOMAIN"

        echo "This will remove vhost mapping and optionally directories:"
        echo "  $VH_CONF_DIR"
        echo "  $LOG_DIR"
        echo "  $WWW_DIR"
        read -rp "Also delete site & log directories? (y/N): " DELDIRS
        read -rp "Confirm removal of domain $REMOVE_DOMAIN? (type domain to confirm): " CONF
        if [ "$CONF" != "$REMOVE_DOMAIN" ]; then
            echoR "Confirmation mismatch. Canceled."; return 1
        fi

        # Remove mapping line(s)
        if [ -f "$HTTPD_CONF" ]; then
            cp "$HTTPD_CONF" "$HTTPD_CONF.bak.$(date +%s)"
            sed -i "/map[[:space:]]\+$REMOVE_DOMAIN[[:space:]]\+$REMOVE_DOMAIN/d" "$HTTPD_CONF"
            awk -v dom="$REMOVE_DOMAIN" '
                BEGIN{skip=0}
                tolower($0) ~ "^virtualhost[[:space:]]+" dom "[[:space:]]*{" {skip=1; next}
                skip && /^}/ {skip=0; next}
                !skip {print}
            ' "$HTTPD_CONF" > "$HTTPD_CONF.tmp" && mv "$HTTPD_CONF.tmp" "$HTTPD_CONF"
        fi

        if [ -d "$VH_CONF_DIR" ]; then
            rm -rf "$VH_CONF_DIR"
        fi
        if [[ $DELDIRS =~ ^[Yy]$ ]]; then
            rm -rf "$LOG_DIR" "$WWW_DIR"
        fi
        echoY "Removed domain $REMOVE_DOMAIN. Restarting OLS..." ""
        $SERVER_ROOT/bin/lswsctrl restart
    }

    menu_install_ssl() {
        echo
        echoY "Install SSL On Domain" ""
        read -rp "Enter domain: " SSL_DOMAIN
        if [ -z "$SSL_DOMAIN" ]; then
            echoR "Domain cannot be empty."; return 1
        fi
        read -rp "Enter email for certbot (required): " SSL_EMAIL
        if [ -z "$SSL_EMAIL" ]; then
            echoR "Email cannot be empty."; return 1
        fi
        DEFAULT_WEBROOT="/usr/local/lsws/www/$SSL_DOMAIN"
        read -rp "Webroot path [$DEFAULT_WEBROOT]: " SSL_WEBROOT_INPUT
        SITEPATH=${SSL_WEBROOT_INPUT:-$DEFAULT_WEBROOT}
        DOMAIN=$SSL_DOMAIN
        EMAIL=$SSL_EMAIL
        fn_install_ssl
        echoY "SSL installation completed for $SSL_DOMAIN" ""
        read -rp "Enable SSL in vHost now? (y/N): " ENABLESSL
        if [[ $ENABLESSL =~ ^[Yy]$ ]]; then
            fn_enable_ssl_vhost "$SSL_DOMAIN"
        else
            echoY "You can enable later by running: (inside script) fn_enable_ssl_vhost $SSL_DOMAIN" ""
        fi
    }

    show_menu() {
        while true; do
            echo
            echoY "================ OpenLiteSpeed CLI Management ================" ""
            echo "1) Add new domain"
            echo "2) Remove domain"
            echo "3) Install SSL On Domain"
            echo "4) Exit"
            if ! read -rp "Select an option [1-4]: " opt; then
                echoR "No input (non-interactive or EOF). Exiting menu."; break
            fi
            # If running non-interactively (no TTY) and opt is empty, exit cleanly
            if [ -z "$opt" ] && [ ! -t 0 ]; then
                echoR "No choice provided in non-interactive mode. Exiting."; break
            fi
            case $opt in
                1) menu_add_domain ;;
                2) menu_remove_domain ;;
                3) menu_install_ssl ;;
                4) echo "Bye."; break ;;
                *) echoR "Invalid choice" ;;
            esac
        done
    }

    # If no arguments were provided, run interactive menu.
    if [ $# -eq 0 ]; then
        # If stdin is not a TTY (piped / curl) avoid dropping into interactive loop
        if [ ! -t 0 ]; then
            echo "Interactive menu disabled: no TTY detected."
            echo "Download first: curl -fsSL <url>/olsdomain.sh -o olsdomain.sh && chmod +x olsdomain.sh && ./olsdomain.sh"
            echo "Or run non-interactive: curl -fsSL <url>/olsdomain.sh | bash -s -- -d domain.com -e you@example.com -p /usr/local/lsws/www/domain.com"
            exit 1
        fi
        fn_display_license
        fn_check_os
        show_menu
        exit 0
    fi

    fn_display_license
    fn_check_os
    fn_install_info
    fn_install_site
    fn_config_httpd
    fn_install_ssl
    fn_enable_ssl_vhost "$DOMAIN" 2>/dev/null || true
    fn_test_domain

    echo
    echo
