# Example Native App with Snowpark Container Services
This is a simple Snowflake Native App that uses Snowpark Container Services to deploy a frontend application. The application will share the Factset [Tick History](https://app.snowflake.com/marketplace/listing/GZT0ZGCQ51UL/factset-tick-history?search=factset) dataset available from the Snowflake Marketplace. The users of the application will then share with the application the tickers in which they are interested via a Snowflake Hybrid table and the application will show a graph of the historical performance of that ticker. This example uses a Vue-based JavaScript frontend, a Flask-based Python middle tier, and nginx as a router.


## Prerequisite

Snowflake trial account.

## What you will need
### Snowflake CLI
You should have Snowflake CLI installed on your local machine.
https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation

#### Authorisation
Once the Snowflake CLI is installed you will need to provide connection information for your Snowflake account through a config.toml file.  Instructions can be found [here](https://docs.snowflake.com/en/developer-guide/snowflake-cli/connecting/configure-cli) and [here](https://docs.snowflake.com/en/developer-guide/snowflake-cli/connecting/configure-connections)

The Snowflake CLI helps to automate lots of features within Snowflake.  Today we are using it for Native Apps but it can also be used for Streamlit, Notebooks, Git etc.

### Docker
This Quickstart uses Docker to deploy the container images you build locally to your Snowflake account.  Docker can be installed from [here](https://www.docker.com/products/docker-desktop/)

### Factset Dataset
The application will be sharing this dataset with the users of the application.  Although it is never exposed directly, the application uses it when drawing historical graphs for ticker symbols.
* Go to Snowsight
* Data Products / Marketplace in the left hand column
* Locate the Dataset [Tick History (Free)](https://app.snowflake.com/marketplace/listing/GZT0ZGCQ51UL/factset-tick-history?search=factset)
* Click on it
* Click Get and follow the instructions

Before installing the dataset have a read of the descriptions of the dataset content on the site.  Because this is a free dataset the count of symbols and the date range of the data is curtailed

When installing the dataset leave all of the defaults the same. This means the data will be installed in a database name Tick_History.  
Going into a worksheet inside Snowsight and looking at the available data you will see
* Database = Tick_History
* Schema = Public
* Table = TH_SF_MKTPLACE

The datset has over 31 billion rows.

This table is going to be the one that is shared with our application.  The most important attributes for us in this dataset are TICKER, DATE and 
Feel free to explore the dataset before moving on.  The query we use to select the data for sharing is crude but illustrates what we want. 
  

## What you will learn
In this quikstart you will learn how to use the Snowflake Native Apps framework along with Snowpark Containers services to build and deploy an application.  You will also learn how the Snowflake CLI can help automate the build and deployment of your application

## What you will build
A Snowflake Native App with Snowpark Container Services

## Setup
In a Snowflake Native App there are two parties.  The builder of the application, often called the Provider in our literature, and the user of the application, often called the consumer in our literature.  In this particular Quickstart you will play both roles as you only have one account.  In a real-world scenario you would share your application via the Snowflake Marketplace.

/--- This will be done using snow app run (Meny)
### Provider Setup

#### Create Provider Objects
[!NOTE] KEEP
#### Clone Repository
You will need to clone the following [repository]().  You can also choose to download the repository as a zip file and unzip it onto your laptop.

For the Provider, we need to set up only a few things:
* A STAGE to hold the files for the Native App
* An IMAGE REPOSITORY to hold the image for the service image
* An APPLICATION PACKAGE that defines the Native App

```sql
USE ROLE ACCOUNTADMIN;
CREATE ROLE IF NOT EXISTS naspcs_role;
GRANT ROLE naspcs_role TO ROLE accountadmin;

GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE naspcs_role;
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE naspcs_role;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE naspcs_role;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE naspcs_role;
GRANT CREATE APPLICATION PACKAGE ON ACCOUNT TO ROLE naspcs_role;
GRANT CREATE APPLICATION ON ACCOUNT TO ROLE naspcs_role;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE naspcs_role;

GRANT CREATE DATA EXCHANGE LISTING ON ACCOUNT TO ROLE naspcs_role;

CREATE WAREHOUSE IF NOT EXISTS wh_nap WITH WAREHOUSE_SIZE='XSMALL';
GRANT ALL ON WAREHOUSE wh_nap TO ROLE naspcs_role;

USE ROLE naspcs_role;
CREATE DATABASE IF NOT EXISTS spcs_app;
CREATE SCHEMA IF NOT EXISTS spcs_app.napp;
CREATE STAGE IF NOT EXISTS spcs_app.napp.app_stage;
CREATE IMAGE REPOSITORY IF NOT EXISTS spcs_app.napp.img_repo;
SHOW IMAGE REPOSITORIES IN SCHEMA spcs_app.napp;
```
/--- This will be done using snow app run (Meny) -----/

#### Create Provider Objects

The application now needs to be built.  The first this we need is the creation of the container images and the deployment of them to your Snowflake account is all done 
* The full name of the image repository. You can get this by running 
   `SHOW IMAGE REPOSITORIES IN SCHEMA spcs_app.napp;`, and getting the `repository_url`.

Once you have the repository url then you can run the following from a terminal.  You will be prompted to enter the url now.

```bash
bash ./configure.sh
```

This created a `Makefile` with the necessary repository filled in. Feel free to look at the Makefile, but you can also just run:

```bash
make all
```
This will create the 2 container images and push it to the IMAGE REPOSITORY.

[!NOTE] KEEP
Your images have been built locally and deployed to your Snowflake account.  If you want to check that they are there you can head back over to Snowsight and execute (fill in your values)
[!NOTE] KEEP
```sql
SHOW IMAGE REPOSITORIES IN ACCOUNT;
```
[!NOTE] KEEP
You can then grab the database name, the schema name and the repository name and then execute
[!NOTE] KEEP
```sql
SHOW IMAGES IN IMAGE REPOSITORY  <db>.<schema>.<repo>;
```

#### Create Application Package

Next, you need to upload the files in the `na_spcs_python` directory into the stage 
`SPCS_APP.NAPP.APP_STAGE` in the folder `na_spcs_python`.

To create the VERSION for the APPLICATION PACKAGE, run the following commands

```sql
USE ROLE naspcs_role;
USE WAREHOUSE wh_nap;
DROP APPLICATION PACKAGE IF EXISTS na_spcs_python_pkg;
CREATE APPLICATION PACKAGE na_spcs_python_pkg;
CREATE SCHEMA na_spcs_python_pkg.shared_data;
CREATE TABLE na_spcs_python_pkg.shared_data.feature_flags(flags VARIANT, acct VARCHAR);
CREATE SECURE VIEW na_spcs_python_pkg.shared_data.feature_flags_vw AS SELECT * FROM na_spcs_python_pkg.shared_data.feature_flags WHERE acct = current_account();
GRANT USAGE ON SCHEMA na_spcs_python_pkg.shared_data TO SHARE IN APPLICATION PACKAGE na_spcs_python_pkg;
GRANT SELECT ON VIEW na_spcs_python_pkg.shared_data.feature_flags_vw TO SHARE IN APPLICATION PACKAGE na_spcs_python_pkg;
INSERT INTO na_spcs_python_pkg.shared_data.feature_flags SELECT parse_json('{"debug": ["GET_SERVICE_STATUS", "GET_SERVICE_LOGS", "LIST_LOGS", "TAIL_LOG"]}') AS flags, current_account() AS acct;
GRANT USAGE ON SCHEMA na_spcs_python_pkg.shared_data TO SHARE IN APPLICATION PACKAGE na_spcs_python_pkg;

USE ROLE naspcs_role;
-- for the first version of a VERSION
ALTER APPLICATION PACKAGE na_spcs_python_pkg ADD VERSION v2 USING @spcs_app.napp.app_stage/na_spcs_python;
```

If you need to iterate, you can create a new PATCH for the version by running this
instead:

```sql
USE ROLE naspcs_role;
-- for subsequent updates to version
ALTER APPLICATION PACKAGE na_spcs_python_pkg ADD PATCH FOR VERSION v2 USING @spcs_app.napp.app_stage/na_spcs_python;
```

### Testing on the Provider/Consumer Side

#### Setup for Testing on the Provider Side
We can test our Native App on the Provider by mimicking what it would look like on the Consumer side (a benefit/feature of the Snowflake Native App Framework).  This is really helpful when debugging your application and when you only have one account with which to work.

To do this, run below SQL commands . This will 

* create a role 
* virtual warehouse for install
* database
* schema
* A Hybrid Table which will store your portfolio (includes sample INSERT too)
* Permissions necessary to configure the Native App (Granted to the `NAC` role)

```sql
USE ROLE ACCOUNTADMIN;
-- (Mock) Consumer role
CREATE ROLE IF NOT EXISTS nac;
GRANT ROLE nac TO ROLE ACCOUNTADMIN;
CREATE WAREHOUSE IF NOT EXISTS wh_nac WITH WAREHOUSE_SIZE='XSMALL';
GRANT USAGE ON WAREHOUSE wh_nac TO ROLE nac WITH GRANT OPTION;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE nac;
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE nac WITH GRANT OPTION;
GRANT CREATE COMPUTE POOL ON ACCOUNT TO ROLE nac;

USE ROLE nac;
CREATE DATABASE IF NOT EXISTS nac_test;
CREATE SCHEMA IF NOT EXISTS nac_test.data;
USE SCHEMA nac_test.data;
CREATE HYBRID TABLE <insert name here>(UserID INTEGER NOT NULL, TickerID INTEGER NOT NULL, CONSTRAINT pk_UserID_TickerID PRIMARY KEY (UserID, TickerID));
```



#### Testing on the Provider Side
First, let's install the Native App.

```sql
-- For Provider-side Testing
USE ROLE naspcs_role;
GRANT INSTALL, DEVELOP ON APPLICATION PACKAGE na_spcs_python_pkg TO ROLE nac;
USE ROLE ACCOUNTADMIN;
GRANT CREATE APPLICATION ON ACCOUNT TO ROLE nac;

USE ROLE naspcs_role;


-- FOLLOW THE consumer_setup.sql TO SET UP THE TEST ON THE PROVIDER
USE ROLE nac;
USE WAREHOUSE wh_nac;

-- Create the APPLICATION
DROP APPLICATION IF EXISTS na_spcs_python_app CASCADE;

--this should be done by snow app run
CREATE APPLICATION na_spcs_python_app FROM APPLICATION PACKAGE na_spcs_python_pkg USING VERSION v1;
```

In Snowsight head over to Data Products / Apps in the left hand sidebar.
The application you have just installed should be the only one there.  If it isn't then locate the NA_SPCS_PYTHON_APP applcation you have just created

* Click the "Grant" button to grant the necessary privileges
* Click the "Review" button to open the dialog to create the
  necessary `EXTERNAL ACCESS INTEGRATION`. Review the dialog and
  click "Connect".

At this point, you should now see an "Activate" button in the top right. Click it to activate the app.
Behind the scenes Snowflake is setting up your services as well as the compute pools needed by the application so this may yake a few minutes.

Once it has successfully activated, the "Activate" button will be replaced
with a "Launch app" button. Click the "Launch app" button to open the
containerized web app in a new tab.

At this point, you can also grant access to the ingress endpoint by granting
the APPLICATION ROLE `app_user` to a normal user role. Users with that role can
then visit the URL.

If you need to get the URL via SQL, you can call a stored procedure 
in the Native App, `app_public.app_url()`.

```sql
-- ????????????????????????????????????????
GRANT APPLICATION ROLE na_spcs_python_app.app_user TO ROLE sandbox;
-- Get the URL for the app
CALL na_spcs_python_app.app_public.app_url();
```

##### Cleanup
To clean up the Native App test install, you can just `DROP` it:

```
DROP APPLICATION na_spcs_python_app CASCADE;
```
The `CASCADE` will also drop the `WAREHOUSE` and `COMPUTE POOL` that the
Application created, along with the `EXTERNAL ACCESS INTEGRATION` that 
the Application prompted the Consumer to create.

### Publishing/Sharing your Native App
You Native App is now ready on the Provider Side. You can make the Native App available
for installation in other Snowflake Accounts by setting a default PATCH and Sharing the App
in the Snowsight UI.

Navigate to the "Apps" tab and select "Packages" at the top. Now click on your App Package 
(`NA_SPCS_PYTHON_PKG`). From here you can click on "Set release default" and choose the latest patch
(the largest number) for version `v2`. 

Next, click "Share app package". This will take you to the Provider Studio. Give the listing
a title, choose "Only Specified Consumers", and click "Next". For "What's in the listing?", 
select the App Package (`NA_SPCS_PYTHON_PKG`). Add a brief description. Lastly, add the Consumer account
identifier to the "Add consumer accounts". Then click "Publish".

### Using the Native App on the Consumer Side

#### Setup for Testing on the Consumer Side
We're ready to import our Native App in the Consumer account.

To do the setup, run the commands in `consumer_setup.sql`. This will create the role and
virtual warehouse for the Native App. The ROLE you will use for this is `NAC`.

#### Using the Native App on the Consumer
To get the Native app, navigate to the "Apps" sidebar. You should see the app at the top under
"Recently Shared with You". Click the "Get" button. Select a Warehouse to use for installation.
Under "Application name", choose the name `NA_SPCS_PYTHON_APP` (You _can_ choose a 
different name, but the scripts use `NA_SPCS_PYTHON_APP`). Click "Get".

Next we need to configure the Native App. We can do this via Snowsight by
visiting the Apps tab and clicking on our Native App `NA_SPCS_PYTHON_APP`.
* Click the "Grant" button to grant the necessary privileges
* Click the "Review" button to open the dialog to create the
  necessary `EXTERNAL ACCESS INTEGRATION`. Review the dialog and
  click "Connect".

At this point, you should now see an "Activate" button in the top right.
Click it to activate the app.

Once it has successfully activated, the "Activate" button will be replaced
with a "Launch app" button. Click the "Launch app" button to open the
containerized web app in a new tab.

At this point, you can also grant access to the ingress endpoint by granting
the APPLICATION ROLE `app_user` to a normal user role. Users with that role can
then visit the URL.

If you need to get the URL via SQL, you can call a stored procedure 
in the Native App, `app_public.app_url()`.

##### Cleanup
To clean up the Native App, you can just uninstall it from the "Apps" tab.

#### Debugging
I added some debugging Stored Procedures to allow the Consumer to see the status
and logs for the containers and services. These procedures are granted to the `app_admin`
role and are in the `app_public` schema:
* `GET_SERVICE_STATUS()` which takes the same arguments and returns the same information as `SYSTEM$GET_SERVICE_STATUS()`
* `GET_SERVICE_LOGS()` which takes the same arguments and returns the same information as `SYSTEM$GET_SERVICE_LOGS()`

The permissions to debug are managed on the Provider in the 
`NA_SPCS_PYTHON_PKG.SHARED_DATA.FEATURE_FLAGS` table. 
It has a very simple schema:
* `acct` - the Snowflake account to enable. This should be set to the value of `SELECT current_account()` in that account.
* `flags` - a VARIANT object. For debugging, the object should have a field named `debug` which is an 
  array of strings. These strings enable the corresponding stored procedure:
  * `GET_SERVICE_STATUS`
  * `GET_SERVICE_LOGS`

An example of how to enable logging for a particular account (for example, account 
`ABC12345`) to give them all the debugging permissions would be

```
INSERT INTO na_spcs_python_pkg.shared_data.feature_flags 
  SELECT parse_json('{"debug": ["GET_SERVICE_STATUS", "GET_SERVICE_LOGS"]}') AS flags, 
         'ABC12345' AS acct;
```

To enable on the Provider account for use while developing on the Provider side, you could run

```
INSERT INTO na_spcs_python_pkg.shared_data.feature_flags 
  SELECT parse_json('{"debug": ["GET_SERVICE_STATUS", "GET_SERVICE_LOGS"]}') AS flags,
         current_account() AS acct;
```
