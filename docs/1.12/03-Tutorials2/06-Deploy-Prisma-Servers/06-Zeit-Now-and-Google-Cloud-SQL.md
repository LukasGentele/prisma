---
alias: joofei3ahd
description: Learn how to deploy Prisma servers to Zeit Now.
---

# Zeit Now and GCP Cloud SQL

In this tutorial, you’re going to learn how to deploy a Prisma server to [Zeit Now](https://zeit.co/now). The server will be backed by a MySQL database hosted in Google Cloud Platform (GCP). If you wish to host your database elsewhere such as AWS RDS just skip directly to [part 2]().

## Overview

Zeit Now

Google Cloud SQL provides fully-managed PostgreSQL & MySQL instances. You may follow the [tutorials and quick guides](https://cloud.google.com/sql/docs/) to configure and setup your SQL instance using either the console or command line.

## Prerequisites

#### GCP Cloud SQL

For the purpose of this tutorial you will need to have signed up for GCP, created a project and enabled the Cloud SQL Admin API (see [quickstart](https://cloud.google.com/sql/docs/mysql/) for more information).

You also should install the [Cloud SDK](https://cloud.google.com/sdk/).

#### Zeit Now

Sign up to [zeit.co](https://zeit.co).

Install the (now-cli)[https://github.com/zeit/now-cli]

## 1. MySQL

### 1.1. Creating A Cloud SQL Instance

We'll be creating a MySQL instance called `prisma` on GCP via the command line. You may also do this via the console.

```console
❯ gcloud sql instances create prisma --tier=db-f1-micro --authorized-networks=0.0.0.0/0 --region=europe-west1

NAME    DATABASE_VERSION  LOCATION        TIER              ADDRESS         STATUS
prisma  MYSQL_5_6         europe-west1-d  db-f1-micro  xx.xx.xx.xx  RUNNABLE
```

* We are deploying to the `europe-west1` region as this is the same location as Zeit in Europe. The default region is `us-central`.
* The network access is opened up so the database can be accessed over the internet.
* Tier is the instance's machine type. `db-f1-micro` is the smallest possible. The default tier is `db-n1-standard-1`.

---

* You can learn the [command line flags](https://cloud.google.com/sdk/gcloud/reference/beta/sql/instances/create)
* The steps for creating Postgres are virtually identical.


### 1.2. Create SQL User

Create a user called `prisma` with a password of `my-secret`.

```console
❯ gcloud beta sql users create prisma --instance=prisma --password=my-secret
```

Your MySQL Instance is now up and running.

Note the IP address of the instance, your username and password.

## 2. Deploying a Prisma server to Zeit Now

Deployment to Now consists of 3 files; a Dockerfile, prisma configuration and Now deployment configuration.

### 2.1 Now Secrets

First we will add secrets to Now to store the sql password from earlier and the Prisma API password.

```console
❯ now secret add sql-password my-secret
❯ now secret add prisma-management-api-secret so-secret
```

*  Learn more about Now secrets: https://zeit.co/docs/getting-started/secrets

### 2.2 Prisma Configuration

Create a file `config.yml`. This contains the Prisma Server configuration.

```file
managementApiSecret: PRISMA_MANAGEMENT_API_SECRET
port: 4466
databases:
    default:
        connector: mysql
        host: SQL_HOST
        port: 3306
        user: prisma
        password: SQL_PASSWORD
        migrations: true
        active: true
```

* SQL_HOST, SQL_PASSWORD and PRISMA_MANAGEMENT_API_SECRET will be replaced with Now build-time environment variables.

### 2.2 Now Deployment Configuration

Create `now.json`. This file contains our build environment variables and references to the secrets.

Change `xx.xx.xx.xx` to the Cloud SQL IP address returned in 1.1.

```file
{
  "name": "prisma-now",
  "type": "docker",
  "build": {
    "env": {
      "SQL_HOST": "xx.xx.xx.xx",
      "SQL_PASSWORD": "@sql-password",
      "PRISMA_MANAGEMENT_API_SECRET": "@prisma-management-api-secret"
    }
  },
}
```

* Learn more about environment variables: https://zeit.co/docs/features/build-env-and-secrets and more about `now.json`: https://zeit.co/docs/features/configuration.
* To take advantage of Zeit's automatic scaling: https://zeit.co/docs/getting-started/scaling

### 2.3 Dockerfile

Create a file called `Dockerfile`. This tells Now how to build and configure the Prisma server.

```file
FROM prismagraphql/prisma:1.13-beta
ARG SQL_HOST
ARG SQL_PASSWORD
ARG PRISMA_MANAGEMENT_API_SECRET
ARG PRISMA_CONFIG_PATH
ENV PRISMA_CONFIG_PATH prisma.yml
COPY config.yml prisma.yml
RUN sed -i s/SQL_HOST/$SQL_HOST/g prisma.yml
RUN sed -i s/SQL_PASSWORD/$SQL_PASSWORD/g prisma.yml
RUN sed -i s/PRISMA_MANAGEMENT_API_SECRET/$PRISMA_MANAGEMENT_API_SECRET/g prisma.yml
EXPOSE 4466
```

* Edit `Dockerfile` with the version of prisma you wish to deploy from [dockerhub](https://hub.docker.com/r/prismagraphql/prisma/tags/)

### 2.4 Deploy

Then you are ready to deploy.

```console
❯ now
```

Now will go through it's deployment process, which will take a few minutes.

* From here you may wish to alias the deployment in Now: https://zeit.co/docs/features/aliases before updating your endpoint in `prisma.yml`.

## Author
Mark Petty – (Intrusted)[https://intrusted.co.uk]