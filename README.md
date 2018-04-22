Launch APEX with Docker youtube shownotes

Intro
Docker is a radical way to host an Oracle APEX environment on your computer that both 
minimizes the strain you impose on your system’s memory 
and maximizes your potential to version and share your database configuration. 
In this post, I’m going to cover the details of running the latest version of APEX from scratch on your computer, using Docker.
Ingredients
Let’s begin by assembling our ingredients.
APEX
1st ingredient - Download the latest version of APEX and unzip it in the path ~/docker/. 
google ‘download oracle apex’, hit the 1st link and review & accept the oracle license agreement. 
move it the folder structure you’ve prepared and unzip it.
Next ingredient - Download my database configuration script named ‘install_apex514.sh’ (https://www.dropbox.com/s/wdnaf18zfcgss2e/install_apexpdb514.sh?dl=0)  and move it to the directory you just created ~/docker/apex/. Make sure you replace the email on line 37 with your own email.
We need 2 things for Oracle Rest Data Service too
1st off - Git clone the git repo of my colleague Martin D’Souza (see shownotes) in the path ~/docker/ords/
Next up Download the latest version of ORDS. To do this, simply google download oracle ords, hit the 1st link, accept the license agreement. Then, unzip it in the same folder ~/docker/ords/
Final ingredient - make sure that Docker installed on your computer. You can do this by typing ‘docker version’ on the command line. Make sure you can also login.
While we’re at it. Visit store.docker.com, login, search for oracle enterprise edition and agree to the terms and conditions.

Create the oracle container
Now that we have all of these prerequisites assembled, let’s start by kicking off your Oracle db and installing the latest version of APEX. 
Small configuration
2 small pieces of configuration:
 create a an empty folder called ‘oracle’ in the path ~/docker. You are going to mount to this folder to your docker container so that all database configuration gets stored in this folder. This is not a requirement but it gives you some options to share your configuration with your team-mates, as we will discuss.
Create a docker network. I’m going to call it ‘oracle_network’. Super simple - this will permit your containers to easily talk with one another.

Command
docker run -d -it \
--name oracle \
-p 32122:1521 \
-e TZ=America/New_york \
--network=oracle_network \
-v ~/docker/oracle:/ORCL \
-v ~/docker/apex:/tmp/apex \
store/oracle/database-enterprise:12.2.0.1

Now let’s launch our oracle database  - 
You’ve given this container the name ‘oracle’, which means other containers on the ‘oracle_network’ can refer to it by this name
You map the container’s database port 1521 to external port 32122
You set the timezone to your own
You instruct it to listen on the network you’ve created
As I touched on earlier, you then map your local  folder structure docker/oracle to the container’s folder /ORCL. all the database configuration will be stored here. This is a good idea because, after you’ve done all that you want with the database, you can simply zip and share the contents of this folder with your teammates, thereby sparing them from having to repeat your work.
I also mount the local folder docker/apex to the container.
The last line in this ‘docker run’ command refers to the official oracle database image on the docker repository. This will work if you’ve already accepted  their license agreement on store.docker.com

Depending on the processing power of your computer, your oracle container may take a few minutes to start up. In the background, know that a ton of configuration scripts are being run inside your container, building the database and populating your mounted docker/oracle folder with around 6GB worth of configuration files. 

Run apex install script
Once the oracle container has a status of healthy, you can log in and configure it to where you want it to be… be warned - while this step isn’t complicated, it could easily take over 20 minutes.

We start by logging into the container and navigating to the mounted folder that contains the configuration files for the latest version of apex.

After making my configuration file, executable, kick it off and we’ll discuss what’s it doing.

Here are the steps you’re performing:
@apxremov.sql;
→ You start by 1st removing the existing APEX installation in the container database. This is necessary if you want to create a pluggable database (or pdb) that does not have APEX preinstalled.


create pluggable database orclpdb514 admin user pdb_adm identified by Oradoc_db1
file_name_convert=('/u02/app/oracle/oradata/ORCL/pdbseed/','/u02/app/oracle/oradata/ORCL/ORCLPDB514/');
You then proceed to create a new pdb with 514 in the name because we plan to install APEX 5.1.4


alter pluggable database orclpdb514 open read write;
alter pluggable database all save state;
You open the pdb.


Alter session set container = ORCLPDB514;
@apexins.sql SYSAUX SYSAUX TEMP /i/;
You install APEX 5.1.4 in the new pdb - - this step takes a while


@apex_rest_config_core.sql oracle oracle;
alter user apex_public_user identified by oracle account unlock;
Finally, you configure APEX to communicate with ORDS


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
2 final pieces of configuration - You configure your ACL privileges


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
And you create an admin user to log into APEX - I hope you remembered to switch out the placeholder email here.
.
Create the ORDS container
Build the ORDS image
3rd step
While the previous step is cooking, you can start to prepare a 2nd container for our Oracle Rest Data Services. There is currently no Oracle ORDS official Docker image in the repository but with the ingredients you assembled  in your ~/docker/ords folder at the top of this video, you can easily build the requisite image yourself and then, if you like, share it with your teammates by pushing it your docker hub.
To build the requisite ORDS image, navigate to your docker/ords folder and run this docker build command
docker build -t ords:3.0.12 .
Upon successful completion, you’ll find an image with the name ords in your docker images
If you want to spare your teammates from the minor inconvenience of downloading the latest version of ORDS and cloning Martin D’Souza’s git repository as we did at the top of the video, you can push this image to your docker hub with the commands:
docker push <your docker username>/ords:3.0.12
I’d offer to share my own with you but doing so may violate Oracle’s terms and conditions.

Run the ORDS container
For this final step - You’ll want to wait for your apex installation script to complete before going further. In this step, you’ll spin up your ORDS container that will talk to your Oracle database and finally be able to access your APEX web interface.
docker run -t -i \
  --name ords_514 \
  --network=oracle_network \
  -e TZ=America/Edmonton \
  -e DB_HOSTNAME=oracle \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=orclpdb514.localdomain \
  -e APEX_PUBLIC_USER_PASS=oracle \
  -e APEX_LISTENER_PASS=oracle \
  -e APEX_REST_PASS=oracle \
  -e ORDS_PASS=oracle \
  -e SYS_PASS=Oradoc_db1 \
  --volume ~/docker/apex/images:/ords/apex-images \
  -p 32514:8080 \
  ords:3.0.12

Let’s walk through this command
You name the container ords_514 to match the name of the oracle pluggable database and APEX version because that gives the option to simultaneously spin up other ords containers that serve up different APEX installations on different pdbs in your multitenant oracle database. Next time you want to start this container, to state the possibly obvious, you’d simply run docker start ords_514
As before, you place this container on the oracle_network that you created so that it can communicate with the oracle container.
You set the appropriate timezone
Next, we pass in some configuration property values necessary for the ords installation. 
You identify the name of the db_hostname to match the name of your db container
You let ords know that it should communicate with the db on port 1521
You instruct this installation of ords to listen for the pdb that we specially configured with the latest version of APEX
You then pass in the appropriate values for the passwords for the database users APEX_PUBLIC_USER, APEX_LISTENER, APEX_REST, ORDS and SYS
You mount the local apex images folder so that ORDS can serve them up appropriately
You map the container’s port 8080 to port 32514 so you can access it in your browser on port 32514
finally you instruct your container to build on the docker image that you built

After running this command and getting no error messages, we can now switch to a browser to confirm that we’re done.

You can now log into your APEX Internal workspace with the values set by the APEX installation script you ran earlier: username ADMIN, password Oradoc_db1 (see shownotes)

Don’t forget - your work can be leveraged for the benefit your colleagues to spare them some of the heavy lifting your just did.
if you
zip and share the contents of your docker/oracle folder. 
and push your ords image to your docker hub
You can spare your colleagues from having to download ords, clone Martin D’Souza’s git repo and perform any configuration on the oracle container. See show notes for more details.

The docker run command for spin up their oracle container would be the same but it would be faster for them because they’d be mounting it a pre-populated docker/oracle folder. 
The docker command for spinning up the ords container would also be the same, except you would substitute the image reference at the end of the command with a reference the ords image you pushed to your docker hub.

All of these recommendations are of subject to the constraints of your Oracle License agreement. 

