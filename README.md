# Haproxy in Docker
Alfresco-specific haproxy docker images.

## Overview

This is the repository building Haproxy Docker images. At the moment there are 3 templates available:

* a front proxy
* a load balancer between alfresco and solr
* a load balancer between solr and alfresco

An init script choses the right template based on an environment variable and creates the final haproxy configuration file. Templates are themselves scripts, to allow for further tweaking, for example adding a new kind of backend. 

All images are automatically built by [jenkins-2](https://jenkins-2.xenit.eu) and published to [hub.xenit.eu/public/haproxy-alfresco](https://hub.xenit.eu/public/haproxy-alfresco).

## Environment variables

There are several environment variables available to tweak the behaviour.

| Variable                        | Default                          | Comments                                                                                                 |
|---------------------------------|----------------------------------|----------------------------------------------------------------------------------------------------------|
| HAPROXY_TEMPLATE                | template-front-proxy-alfresco.sh | Type of proxy                                                                                            |
| HAPROXY_HOSTNAME                | localhost                        | Hostname to be sent to a syslog/logstash server.                                                         |
| HAPROXY_SEND_LOGS               | false                            | Whether to send logs to a syslog/logstash server.                                                        |
| HAPROXY_LOGS_SERVER             | 10.88.10.50:514                  | Hetzner syslog/logstash server.                                                                          |
| HAPROXY_STATS_TIMEOUT           | 2m                               | Stats timeout.                                                                                           |
| HAPROXY_COOKIE                  | JSESSIONID                       | Cookie to be used. Valid for front proxy.                                                                |
| HAPROXY_BALANCE                 | hdr(X-Forwarded-For)/leastconn   | Balancing method. Different defaults for front proxy/alfresco-solr-alfresco-lb                           |
| HAPROXY_TIMEOUT_CLIENT          | 30m                              |                                                                                                          |
| HAPROXY_TIMEOUT_CONNECT         | 4s                               |                                                                                                          |
| HAPROXY_TIMEOUT_SERVER          | 30m                              |                                                                                                          |
| HAPROXY_TIMEOUT_CHECK           | 5s                               |                                                                                                          |
| HAPROXY_INCLUDE_FRONTEND_STATS  | true                             | Whether to generate statistics to be used by Prometheus scraping.                                        |
| HAPROXY_FRONTEND_STATS          | stats                            | Frontend name for statistics.                                                                            |
| HAPROXY_FRONTEND_INTERNET       | internet                         | Frontend name for internet. Valid for front proxy.                                                       |
| HAPROXY_FRONTEND_INTERNET_BIND  | *:80                             | Bind for frontend internet. Valid for front proxy.                                                       |
| HAPROXY_FRONTEND_ALFRESCO       | alfresco                         | Frontend name for alfresco. Valid for lb-alfresco-solr.                                                  |
| HAPROXY_FRONTEND_ALFRESCO_BIND  | *:8882                           | Bind for frontend alfresco. Valid for lb-alfresco-solr.                                                  |
| HAPROXY_FRONTEND_SOLR           | solr                             | Frontend name for solr. Valid for lb-solr-alfresco.                                                      |
| HAPROXY_FRONTEND_SOLR_BIND      | *:8880                           | Bind for frontend solr. Valid for lb-solr-alfresco.                                                      |
| HAPROXY_BACKEND_ALFRESCO        | alfresco                         | Backend name for alfresco. Valid for front proxy and lb-solr-alfresco.                                   |
| HAPROXY_BACKEND_ALFRESCO_PORT   | 8080                             | Alfresco backend port. Valid for front proxy.                                                            |
| HAPROXY_BACKEND_ALFRESCO_CHECK  | /alfresco/s/api/server           | Check for alfresco backend. Alternative: /actuators/health. Valid for front proxy and lb-solr-alfresco.  |
| HAPROXY_BACKEND_ALFRESCO_COUNT  | 1                                | Number of alfresco backends. Valid for front proxy and lb-solr-alfresco.                                 |
| HAPROXY_SERVICE_ALFRESCO        | alfresco                         | Alfresco service name (docker DNS). Valid for front proxy and lb-solr-alfresco.                          |
| HAPROXY_INCLUDE_SHARE           | false                            | Whether to include share as a backend. Valid for front proxy.                                            |
| HAPROXY_BACKEND_SHARE           | share                            | Backend name for share. Valid for front proxy.                                                           |
| HAPROXY_BACKEND_SHARE_PORT      | 8080                             | Share backend port. Valid for front proxy.                                                               |
| HAPROXY_BACKEND_SHARE_CHECK     | share                            | Check for share backend. Valid for front proxy.                                                          |
| HAPROXY_BACKEND_SHARE_COUNT     | 1                                | Number of share backends. Valid for front proxy.                                                         |
| HAPROXY_SERVICE_SHARE           | share                            | Share service name (docker DNS). Valid for front proxy.                                                  |
| HAPROXY_INCLUDE_WORKSPACE       | false                            | Whether to include digital workspace as a backend. Valid for front proxy.                                |
| HAPROXY_BACKEND_WORKSPACE       | workspace                        | Backend name for digital workspace. Valid for front proxy.                                               |
| HAPROXY_BACKEND_WORKSPACE_PORT  | 8080                             | Workspace backend port. Valid for front proxy.                                                           |
| HAPROXY_BACKEND_WORKSPACE_CHECK | workspace                        | Check for workspace backend. Valid for front proxy.                                                      |
| HAPROXY_BACKEND_WORKSPACE_COUNT | 1                                | Number of workspace backends. Valid for front proxy.                                                     |
| HAPROXY_SERVICE_WORKSPACE       | digital-workspace                | Workspace service name (docker DNS). Valid for front proxy.                                              |
| HAPROXY_INCLUDE_FINDER          | false                            | Whether to include finder as a backend. Valid for front proxy.                                           |
| HAPROXY_STRIP_FINDER_PREFIX     | true                             | Whether to retain "/finder/" in the url path. Valid for front proxy.                                     |
| HAPROXY_BACKEND_FINDER          | finder                           | Backend name for finder. Valid for front proxy.                                                          |
| HAPROXY_BACKEND_FINDER_CHECK    | /                                | Check for finder backend. Valid for front proxy.                                                         |
| HAPROXY_BACKEND_FINDER_COUNT    | 1                                | Number of finder backends. Valid for front proxy.                                                        |
| HAPROXY_BACKEND_FINDER_PORT     | 80                               | Finder backend port. Valid for front proxy.                                                              |
| HAPROXY_SERVICE_FINDER          | alfred-finder                    | Finder service name (docker DNS). Valid for front proxy.                                                 |
| HAPROXY_INCLUDE_OOI             | false                            | Whether to include ooi service as a backend. Valid for front proxy.                                      |
| HAPROXY_BACKEND_OOI             | ooi-service                      | Backend name for ooi service. Valid for front proxy.                                                     |
| HAPROXY_BACKEND_OOI_PORT        | 9095                             | OOI backend port. Valid for front proxy.                                                                 |
| HAPROXY_BACKEND_OOI_CHECK       | /                                | Check for ooi service backend. Valid for front proxy.                                                    |
| HAPROXY_BACKEND_OOI_COUNT       | 1                                | Number of ooi service backends. Valid for front proxy.                                                   |
| HAPROXY_SERVICE_OOI             | alfresco-ooi-service             | Ooi service name (docker DNS). Valid for front proxy.                                                    |
| HAPROXY_BACKEND_SOLR            | solr                             | Backend name for solr. Valid for lb-alfresco-solr.                                                       |
| HAPROXY_BACKEND_SOLR_CHECK      | /solr4                           | Check for solr backend. Valid for lb-alfresco-solr.                                                      |
| HAPROXY_BACKEND_SOLR_COUNT      | 1                                | Number of solr backends.  Valid for lb-alfresco-solr.                                                    |
| HAPROXY_SERVICE_SOLR            | solr                             | Solr service name (docker DNS).                                                                          |
| HAPROXY_RESOLVE_RETRIES         | 3                                |                                                                                                          |
| HAPROXY_TIMEOUT_RESOLVE         | 1s                               |                                                                                                          |
| HAPROXY_TIMEOUT_RETRY           | 1s                               |                                                                                                          |
| HAPROXY_HOLD_OTHER              | 10s                              |                                                                                                          |
| HAPROXY_HOLD_REFUSED            | 10s                              |                                                                                                          |
| HAPROXY_HOLD_NX                 | 10s                              |                                                                                                          |
| HAPROXY_HOLD_TIMEOUT            | 10s                              |                                                                                                          |
| HAPROXY_HOLD_VALID              | 10s                              |                                                                                                          |
| HAPROXY_HOLD_OBSOLETE           | 10s                              |                                                                                                          |

**Maintained by:**

Roxana Angheluta <roxana.angheluta@xenit.eu>

### How to build

To build a local version of the _haproxy_ image:

```bash
./gradlew buildDockerImage
```