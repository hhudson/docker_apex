# Launch APEX with Docker

<!-- TOC -->

- [Launch APEX with Docker](#launch-apex-with-docker)
    - [Intro](#intro)
        - [References](#references)
    - [Ingredients](#ingredients)
            - [APEX](#apex)
            - [ORDS](#ords)
            - [Docker](#docker)
    - [Create the oracle container](#create-the-oracle-container)
            - [2 small pieces of configuration](#2-small-pieces-of-configuration)
        - [Container command](#container-command)
        - [Run database configuration script (install APEX)](#run-database-configuration-script-install-apex)
    - [Create the ORDS container](#create-the-ords-container)
        - [Build the ORDS image](#build-the-ords-image)
        - [Run the ORDS container](#run-the-ords-container)
    - [Share and version your work](#share-and-version-your-work)
        - [Suggestion](#suggestion)
        - [Disclaimer](#disclaimer)
    - [Next steps](#next-steps)

<!-- /TOC -->

## Intro

Docker is a radical way to host an Oracle APEX environment on your computer that:
1. minimizes the strain you impose on your system’s memory
1. maximizes your potential to version and share your database configuration.

This post was made to support of a [youtube video](https://www.youtube.com/watch?v=WlkCN516OUI) I made. In this post, I’m going to cover the details of running the latest version of APEX from scratch on your computer, using Docker.

### References

All of my code has been assembled from the following sources:
* [Docker-oracle-setup](https://github.com/martindsouza/docker-oracle-setup) & [Docker-ords](https://github.com/martindsouza/docker-ords) by [Martin Giffy D'Souza](https://twitter.com/martindsouza)
* [APEX and ORDS up and running in....2 steps!](http://joelkallman.blogspot.ca/2017/05/apex-and-ords-up-and-running-in2-steps.html) by [Joel Kallman](https://twitter.com/joelkallman)

## Ingredients

#### APEX
* Download [the latest version of APEX](http://www.oracle.com/technetwork/developer-tools/apex/downloads/index.html) and unzip it in the path ~/docker/.
```console
hayden@mac:~/docker$ mkdir apex
hayden@mac:~/docker$ cd apex/
hayden@mac:~/docker/apex$ mv ~/Downloads/apex_18.1.zip .
hayden@mac:~/docker/apex$ unzip apex_18.1.zip
[...]
ayden@mac:~/docker/apex$ mv apex 18.1.0
```
* Download my database configuration script: [install_apex181.sh](https://github.com/hhudson/docker_apex/blob/master/install_apexpdb181.sh) and move it to the directory you just created ~/docker/apex/. Make sure you replace the email on line 37 with your own email.
```console
hayden@mac:~/docker/apex/18.1.0$ mv ~/Downloads/install_apex181.sh .
```

#### ORDS
We need 2 things for Oracle Rest Data Service too
* Git clone Martin D'Souza's [git repo](https://github.com/martindsouza/docker-ords) in the path ~/docker/ords/
```console
hayden@mac:~/docker/ords$ git clone https://github.com/martindsouza/docker-ords.git .
```
* Download [the latest version of ORDS](http://www.oracle.com/technetwork/developer-tools/rest-data-services/downloads/index.html). Unzip it in the same folder ~/docker/ords/.
```console
hayden@mac:~/docker/ords$ mv ~/Downloads/ords.17.4.1.353.06.48.zip .
hayden@mac:~/docker/ords$ unzip ords.17.4.1.353.06.48.zip
```


#### Docker
* Make sure that Docker installed on your computer.
```console
hayden@mac:~/docker$ docker version
Client:
 Version:	18.03.0-ce
 ...
```
* Visit store.docker.com to accept the Oracle terms and conditions for using their database image:
    1. login
    1. search for 'oracle enterprise edition'
    1. agree to the terms and conditions.

## Create the oracle container
Now that we have all of these prerequisites assembled, let’s start by kicking off your Oracle database and installing the latest version of APEX.

#### 2 small pieces of configuration

 1. Create a an empty folder called ‘oracle’ in the path ~/docker. You are going to mount to this folder to your docker container so that all database configuration gets stored in this folder. This is not a requirement but it gives you some options to share your configuration with your team-mates, as we will discuss:
 ```console
hayden@mac:~/docker$ mkdir oracle
 ```
 2. Create a docker network. I’m going to call it ‘oracle_network’. This will permit your containers to easily talk with one another.
 ```console
hayden@mac:~$ docker network create oracle_network
 ```


### Container command
```console
hayden@mac:~$ docker run -d -it \
--name oracle \
-p 32122:1521 \
-e TZ=America/New_york \
--network=oracle_network \
-v ~/docker/oracle:/ORCL \
<<<<<<< HEAD
-v ~/docker/apex/5.1.4:/tmp/apex \
=======
-v ~/docker/apex/18.1.0:/tmp/apex \
>>>>>>> apex_18.1
store/oracle/database-enterprise:12.2.0.1
```

Let's walk through this command  -

1. You’ve given this container the name ‘oracle’, which means other containers on the ‘oracle_network’ can refer to it by this name
You map the container’s database port 1521 to external port 32122.
1. You set the timezone to your own.
1. You instruct it to listen on the network you’ve created, 'oracle_network'.
1. As I touched on earlier, you then map your local  folder structure ~/docker/oracle to the container’s folder /ORCL. all the database configuration will be stored here. This is a good idea because, after you’ve done all that you want with the database, you can simply zip and share the contents of this folder with your teammates, thereby sparing them from having to repeat your work.
1. You also mount the local folder ~/docker/apex to the container.
1. The last line in this ‘docker run’ command refers to the official oracle database image on the docker repository. This will work if you’ve already accepted  their license agreement on store.docker.com

Depending on the processing power of your computer, your oracle container may take over 5 minutes to start up. In the background, know that a ton of configuration scripts are being run inside your container, building the database and populating your mounted ~/docker/oracle folder with around 6GB worth of configuration files.

You can check the status of your container with the command:
```console
hayden@mac:~$ docker ps
CONTAINER ID        IMAGE                                       COMMAND                  CREATED             STATUS                        PORTS                               NAMES
221b75906a65        store/oracle/database-enterprise:12.2.0.1   "/bin/sh -c '/bin/ba…"   12 days ago         Up About a minute (healthy)   5500/tcp, 0.0.0.0:32122->1521/tcp   oracle

```

### Run database configuration script (install APEX)
Once the oracle container has a status of 'healthy', you can log in and configure it to where you want it to be. Fair warning: while this step isn’t complicated, it could easily take over 20 minutes.

The configuration is easy to kick-off:
1. Log into the container
1. Navigate to the mounted folder that contains the configuration files for the latest version of APEX
1. Make my configuration script executable (we moved it to this folder earlier)
1. Run the script
```console
hayden@mac:~$ docker exec -it oracle bash
[oracle@221b75906a65 /]$ cd /tmp/apex/
[oracle@221b75906a65 apex]$ chmod +x install_apexpdb181.sh
[oracle@221b75906a65 apex]$ ./install_apexpdb181.sh
```


Let's walk through the commands in this script:
```sql
@apxremov.sql;
```
You start by 1st removing the existing APEX installation in the container database. This is necessary if you want to create a pluggable database (or pdb) that does not have APEX preinstalled.


```sql
create pluggable database orclpdb181 admin user pdb_adm identified by Oradoc_db1
file_name_convert=('/u02/app/oracle/oradata/ORCL/pdbseed/','/u02/app/oracle/oradata/ORCL/ORCLPDB181/');
```
You then proceed to create a new pdb with 181 in the name because we plan to install APEX 18.1.

```sql
alter pluggable database orclpdb181 open read write;
alter pluggable database all save state;
```
You open the pdb.

```sql
Alter session set container = ORCLPDB181;
@apexins.sql SYSAUX SYSAUX TEMP /i/;
```
You install APEX 18.1 in the new pdb - - this step takes a while

```sql
@apex_rest_config_core.sql oracle oracle;
alter session set container = CDB\$ROOT;
alter user apex_public_user identified by oracle account unlock;
```
Finally, you configure APEX to communicate with ORDS

```sql
Alter session set container = ORCLPDB181;
declare
    l_acl_path varchar2(4000);
    l_apex_schema varchar2(100);
begin
    for c1 in (select schema
                 from sys.dba_registry
                where comp_id = 'APEX') loop
        l_apex_schema := c1.schema;
    end loop;
    sys.dbms_network_acl_admin.append_host_ace(
        host => '*',
        ace => xs\$ace_type(privilege_list => xs\$name_list('connect'),
        principal_name => l_apex_schema,
        principal_type => xs_acl.ptype_db));
    commit;
end;
/
```
2 final pieces of configuration - You configure your ACL privileges

```sql
begin
    apex_util.set_security_group_id( 10 );
    apex_util.create_user(
        p_user_name => 'ADMIN',
        p_email_address => 'you@youremail.com',
        p_web_password => 'Oradoc_db1',
        p_developer_privs => 'ADMIN',
        p_change_password_on_first_use => 'N');
    apex_util.set_security_group_id( null );
    commit;
end;
/
```
And you create an admin user to log into APEX - I hope you remembered to switch out the placeholder email here.


## Create the ORDS container
### Build the ORDS image

While the previous step is cooking, you can start to prepare a 2nd container for our Oracle Rest Data Services. There is currently no Oracle ORDS official Docker image in the repository but with the ingredients you assembled  in your ~/docker/ords folder at the top of this tutorial, you can easily build the requisite image yourself and then, if you like, share it with your teammates by pushing it your docker hub.
To build the requisite ORDS image, navigate to your docker/ords folder and run this docker build command
```console
hayden@mac:~/docker/ords$ docker build -t ords:3.0.12 .
```
Upon successful completion, you’ll find an image with the name ords in your docker images.

If you want to spare your teammates from the minor inconvenience of downloading the latest version of ORDS and cloning Martin D’Souza’s git repository as we did at the top of the video, you can push this image to your docker hub with the commands:
```console
haydenhudson@Haydens-MacBook-Air:~$ docker images | grep ords
ords                               3.0.12              06b3950c1d58        12 days ago         193MB

hayden@mac:~/docker push haydenhhudson/ords:3.0.12
```
I’d offer to share my own with you but doing so may violate Oracle’s terms and conditions.

### Run the ORDS container
For this final step - You’ll want to wait for your apex installation script to complete before going further. In this step, you’ll spin up your ORDS container that will talk to your Oracle database and finally be able to access your APEX web interface.
```console
hayden@mac:~$ docker run -t -i \
  --name ords_181 \
  --network=oracle_network \
  -e TZ=America/Edmonton \
  -e DB_HOSTNAME=oracle \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=orclpdb181.localdomain \
  -e APEX_PUBLIC_USER_PASS=oracle \
  -e APEX_LISTENER_PASS=oracle \
  -e APEX_REST_PASS=oracle \
  -e ORDS_PASS=oracle \
  -e SYS_PASS=Oradoc_db1 \
<<<<<<< HEAD
  --volume ~/docker/apex/5.1.4/images:/ords/apex-images \
  -p 32514:8080 \
=======
  --volume ~/docker/apex/18.1.0/images:/ords/apex-images \
  -p 32181:8080 \
>>>>>>> apex_18.1
  ords:3.0.12
```

Let’s walk through this command
1. You name the container ords_181 to match the name of the oracle pluggable database and APEX version because that gives the option to simultaneously spin up other ords containers that serve up different APEX installations on different pdbs in your multitenant oracle database. Next time you want to start this container, to state the possibly obvious, you’d simply run docker start ords_181
1. As before, you place this container on the oracle_network that you created so that it can communicate with the oracle container.
You set the appropriate timezone
1. Next, we pass in some configuration property values necessary for the ords installation.
1. You identify the name of the db_hostname to match the name of your db container
1. You let ords know that it should communicate with the db on port 1521
1. You instruct this installation of ords to listen for the pdb that we specially configured with the latest version of APEX
You then pass in the appropriate values for the passwords for the database users APEX_PUBLIC_USER, APEX_LISTENER, APEX_REST, ORDS and SYS
1. You mount the local apex images folder so that ORDS can serve them up appropriately
1.You map the container’s port 8080 to port 32181 so you can access it in your browser on port 32181
1. Finally you instruct your container to build on the docker image that you built

After running this command and getting no error messages, we can now switch to a browser to confirm that we’re done: [http://localhost:32181/ords](http://localhost:32181/ords)

You can now log into your APEX Internal workspace with the values set by the APEX installation script you ran earlier: username ADMIN, password Oradoc_db1.


## Share and version your work
Don’t forget - your work can be leveraged for the benefit your colleagues to spare them some of the heavy lifting your just did.
if you
1. share the contents of your ~/docker/oracle folder
2. push your ords image to your docker hub

For your colleagues this would mean:
* No downloading ORDS
* No cloning Martin D’Souza’s git repo
* No performing any configuration on the oracle container, including installing APEX.

### Suggestion

* Use a private github repo and pay for additional space. With [Git LFS](https://git-lfs.github.com/) and $5/month you can buy 50gb worth of space and preserve a library of database snapshots that you and your team mates can clone into your ~/docker/oracle folder.
    * With this setup the docker command for spinning up the Oracle container for the 1st time would be the same but, the execution would be faster because the docker container would not need to build the database.


### Disclaimer

All of these recommendations are of subject to the constraints of your Oracle License agreement.

## Next steps

I have collected some thoughts on how to use your freshly minted Oracle APEX Dev environment and collaborate with your colleages in the following [blog post](https://2122.IO/apex/f?p=BLOG:SDLC).
