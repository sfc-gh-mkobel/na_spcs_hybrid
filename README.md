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

This table is going to be the one that is shared with our application.  The most important attributes for us in this dataset are TICKER, DATE and LAST_EXCH
Feel free to explore the dataset before moving on.  The query we use to select the data for sharing is crude but illustrates what we want.


## What you will learn
In this quikstart you will learn how to use the Snowflake Native Apps framework along with Snowpark Containers services to build and deploy an application.  You will also learn how the Snowflake CLI can help automate the build and deployment of your application

## What you will build
A Snowflake Native App with Snowpark Container Services

## Setup
In a Snowflake Native App there are two parties.  The builder of the application, often called the Provider in our literature, and the user of the application, often called the consumer in our literature.  In this particular Quickstart you will play both roles as you only have one account.  In a real-world scenario you would share your application via the Snowflake Marketplace.


### Provider Setup

#### Create Provider Objects

#### Clone Repository
You will need to clone the following [repository]().  You can also choose to download the repository as a zip file and unzip it onto your laptop.

For the Provider, we need:

* An IMAGE REPOSITORY to hold the image for the service image

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
CREATE IMAGE REPOSITORY IF NOT EXISTS spcs_app.napp.img_repo;
SHOW IMAGE REPOSITORIES IN SCHEMA spcs_app.napp;
```

To enable the setup, we will use some templated files. There is a script to generate the files from the templated files. You will need the following as inputs:

* The full name of the image repository. You can get this by running 
   `SHOW IMAGE REPOSITORIES IN SCHEMA spcs_app.napp;`, and getting the `repository_url`.

Once you have the repository url then you can run the following from a terminal.  You will be prompted to enter the url.

```bash
bash ./configure.sh
```

This created a `Makefile` with the necessary repository filled in. Feel free to look at the Makefile, but you can also just run:

```bash
make all
```

This will create the 2 container images and push them to the IMAGE REPOSITORY.

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
## Create Application Package Using SnowCLI

To create an application package and create a version for it, execute the following make command:

```bash
make snow_create
```

Occasionally, you might want to validate a setup script before deploying an application to avoid potential impacts that could occur if validation fails during the deployment process. The snow app validate command validates a setup script without needing to run or deploy an application. It uploads source files to a separate scratch stage that drops automatically after the command completes to avoid disturbing files in the application’s source stage.

```bash
make snow_validate
```

If you want to explore these command further then first look in the makefile you created earlier and then head over to the [documentation](https://docs.snowflake.com/en/developer-guide/snowflake-cli/command-reference/native-apps-commands/overview)

We have now created an application package, created all the objects needed by the application and also deployed all the needed artefacts to the stage we created earlier and linked them to our package. 

### Testing on the Provider/Consumer Side

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
--this will be out ticker table
CREATE HYBRID TABLE HT_TEST(UserID INTEGER NOT NULL, TICKER VARCHAR NOT NULL, CONSTRAINT pk_UserID_TickerID PRIMARY KEY (UserID, TICKER));
--insert a sample row we know will exist as a ticker
INSERT INTO HT_TEST VALUES(1,'AMZN');
SELECT * FROM HT_TEST;
```

The 'consumer' is now setup in terms of data.  Now let's install the application we have just deployed.  We will configure it later.

```sql
--TEST ON THE PROVIDER SIDE
USE ROLE ACCOUNTADMIN;
GRANT INSTALL, DEVELOP ON APPLICATION PACKAGE na_spcs_pkg TO ROLE nac;
GRANT CREATE APPLICATION ON ACCOUNT TO ROLE nac;

USE ROLE nac;
USE WAREHOUSE wh_nac;

-- Create the APPLICATION
DROP APPLICATION IF EXISTS na_spcs_app CASCADE;
CREATE APPLICATION na_spcs_app FROM APPLICATION PACKAGE na_spcs_pkg USING VERSION v1;
```

## Configure the Application

In Snowsight head over to Data Products / Apps in the left hand sidebar.
The application you have just installed should be the only one there.  If it isn't the only application then locate the NA_SPCS_PYTHON_APP applcation you have just created

* Click on the application
* Click the "Grant" button to grant the necessary privileges
* Click the "Review" button to open the dialog to create the
  necessary `EXTERNAL ACCESS INTEGRATION`. Review the dialog and
  click "Connect".

At this point, you should now see an "Activate" button in the top right. Click it to activate the app.
Behind the scenes Snowflake is setting up your services as well as the compute pools needed by the application so this may yake a few minutes.

Once it has successfully activated, the "Activate" button will be replaced
with a "Launch app" button. Before you Click the "Launch app" button to open the
containerized web app in a new tab.

* Align the TICKER table on your consumer to the "Privileges to objects" reuest.

Now click the "Launch app" button

At this point, you can also grant access to the ingress endpoint by granting
the APPLICATION ROLE `app_user` to a normal user role. Users with that role can
then visit the URL.

If you need to get the URL via SQL, you can call a stored procedure 
in the Native App, `app_public.app_url()`.

```sql
-- ????????????????????????????????????????
GRANT APPLICATION ROLE na_spcs_python_app.app_user TO ROLE <insert role here>;
-- Get the URL for the app
CALL na_spcs_python_app.app_public.app_url();
```
##### Monitoring App Run


```sql
SELECT
  TIMESTAMP as time,
  RESOURCE_ATTRIBUTES['snow.executable.name'] as executable,
  RECORD['severity_text'] as severity,
  VALUE as message
FROM
  "EVENT_DB"."DATA"."EVENT_TABLE"
WHERE RESOURCE_ATTRIBUTES['snow.application.name'] = 'NA_SPCS_APP' order by time desc;


call NA_SPCS_APP.app_public.app_url();
call NA_SPCS_APP.support.get_service_status('APP_PUBLIC.BACKEND');
call NA_SPCS_APP.support.get_service_status('APP_PUBLIC.FRONTEND');
call NA_SPCS_APP.support.get_service_logs('APP_PUBLIC.FRONTEND',0,'eap-frontend',1000);
call NA_SPCS_APP.support.get_service_logs('APP_PUBLIC.FRONTEND',0,'eap-router',1000);
```


##### Cleanup
To clean up the Native App test install, you can just `DROP` it:

```sql
DROP APPLICATION na_spcs_python_app CASCADE;
```

The `CASCADE` will also drop the `WAREHOUSE` and `COMPUTE POOL` that the
Application created, along with the `EXTERNAL ACCESS INTEGRATION` that 
the Application prompted the Consumer to create.

You can also clean up the Native App by uninstalling it from the "Apps" tab.

#### Debugging
There are some debugging Stored Procedures to allow the Consumer to see the status
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
INSERT INTO na_spcs_pkg.shared_data.feature_flags 
  SELECT parse_json('{"debug": ["GET_SERVICE_STATUS", "GET_SERVICE_LOGS"]}') AS flags, 
         'ABC12345' AS acct;
```

To enable on the Provider account for use while developing on the Provider side, you could run

```
INSERT INTO na_spcs_pkg.shared_data.feature_flags 
  SELECT parse_json('{"debug": ["GET_SERVICE_STATUS", "GET_SERVICE_LOGS"]}') AS flags,
         current_account() AS acct;
```
