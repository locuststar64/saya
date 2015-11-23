# Saya: Anti-Spy for Guilds.

![logo][logo]


>
## WARNING: Pre-Alpha

*Saya is a work in progress. It is not recommended that anyone use it.*

## Features

Saya helps identify suspects from enemy guilds that are trying to infultrate the user's guild.

- Web GUI for Analyizing Suspects  
- Web GUI for Generating Probes  
- Backend software for collecting, manageing data, 

For information on how it works, see the [white paper]( https://github.com/sunsetbrew/saya/blob/master/doc/Saya-WhitePaper.md);

## Requirements

- Perl with DBD::SQLite installed.
- Perl with HTTP:Tiny installed.
- Perl with Text:CSV installed.
- Perl with CGI installed.
- Perl with JSON installed.

### If using Discourse
- If using updateDiscourseUsers.pl, must have Perl with DBD::Pg as well.
```
sudo yum install perl-DBD-Pg
```

## Installation

- Put Saya somewhere not exposed by the web server.

- Get the submodules
```
 git submodule init
 git submodule update
```

- Update the configuration. 
```
 cp saya.conf.example  saya.conf
 vi saya.conf
```

- Setup the database and fix database permissions.  Put the database in a seperate directory somewhere.  The directory and the database muse be writeable by you and the web server.  The location of the database was specified in the sayaDSN value of saya.conf.
```
 ./createDatabase.pl
 chmod 777 /path-to-database
 chmod 666 /path-to-database/data.db
```

- Setup web server to pass the the configuration file to the CGI programs.
Use a different virtual host for improved security.
```
    <VirtualHost yoursite.com:80>
       ...
       SetEnv SAYA_CONFIG /path-to-saya/saya.conf
       ...
    </VirtualHost>
```

- Setup the probe script in the web server document root. Consider naming it something else.
```
  cp log.pl to /path-to-document-root/log.pl
```

- Setup automation
Automation includes updating the suspects table and also updating the list of known users.
You may have to populate the saya_users table for your own forum in your own way.  All Saya needs to know the last IP address of each user so it can corralate the data.

It is best to populate the saya_users table periodically to keep up with changing user IP addresses.
Add the following **crontab** for Discourse forum Users:
```
    0 1,13 * * * SAYA_CONFIG=/path-to-saya/saya.conf /path-to-saya/updateDiscourseUsers.pl >/dev/null 2>&1
    0 * * * * SAYA_CONFIG=/path-to-saya/saya.conf /path-to-saya/maintenance/updateSuspects.pl >/dev/null 2>&1
    0 2 * * * SAYA_CONFIG=/path-to-saya/saya.conf /path-to-saya/maintenance/purgeOldData.pl >/dev/null 2>&1
```

[logo]: https://github.com/sunsetbrew/saya/blob/master/public_html/saya/assets/welcome.png "Logo"
[banner]: https://github.com/sunsetbrew/saya/blob/master/public_html/saya/assets/banner.png "Banner"
