# Saya: Anti-Spy Software for Guilds.

![logo][logo]

## Purpose

Saya helps identify suspects from enemy guilds that are trying to infultrate the user's guild.
This must be done without installing any software on visitor, without causing harm, and
without breaking laws.

## Workflow

Saya finds suspects by recording vistors to an enemy guild's website and coralating the IP address of 
those visitors with the known IP addresses of the user's guild.  The user can 
gather the member IP addresses from the forum database.

![workflowdiagram][workflowdiagram]

## The Saya Probe

Probing another website can be done by placing a simple image on the enemy guild's website.
When the vistor's web browser loads the image, Saya will record the vistor information.  This
is identical to how web analyitics tools work.  However, Saya does not deliver the images directly,
instead redirecting the web browser to the real image.

![probediagram][probediagram]

## Known Issues
- Images that are Saya probes will break if Saya is turned off.
- Some Internet bandwidth will be consumed, although minimal becuase Saya does not deliver the images directly and it leverage browser caching to prevent unmeanigful repeated visits.

[logo]: https://github.com/sunsetbrew/saya/blob/master/public_html/saya/assets/welcome.png "Logo"
[probediagram]: https://github.com/sunsetbrew/saya/blob/master/doc/Saya-Probe.png "Probe Diagram"
[workflowdiagram]: https://github.com/sunsetbrew/saya/blob/master/doc/Saya-Workflow.png "Workflow Diagram"
