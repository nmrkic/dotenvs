# __PROJECT_TITLE__ QA

Local QA deployment of __PROJECT_TITLE__: runs the published Docker images of
every service, so any issue branch can be tested without the source code.

## Needed software

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- `make`

## First setup

1. Copy the environment file:

   ```
   cp .env.example .env
   ```

   Everything needed to start is already filled in. Variables that are left
   empty are real secrets (marked `SECRET` in the file); the features that
   need them stay off until you get the values from the developers and put
   them in `.env`. Never commit `.env`.

2. Log in to the Docker registry with your credentials:

   ```
   docker login __REGISTRY_HOST__
   ```

3. Put the starting database dump (ask the developers or QA for it) into the
   `init_db` folder and run:

   ```
   make reset_db
   ```

   Without a dump the database starts empty.

## Commands

### Run an issue

```
make start issue=ABC-123
```

Pulls the images tagged with that issue and starts them. `issue` is the Jira
ticket name; branches and images are named after the parent issue. Without
`issue` the `APP_VERSION` from `.env` is used.

Frontend images can use another tag:

```
make start issue=ABC-123 front_issue=ABC-456
```

Start only some containers (quote several):

```
make start issue=ABC-123 app=user
make start issue=ABC-123 app="user notify"
```

Containers: __SERVICE_LIST__

### Restart, stop, logs

```
make restart            # or: make restart app=user
make stop               # or: make stop app="user notify"
make logs               # or: make logs app=user
```

Stopping is not needed when moving to another issue; run `make start` with
the new issue.

### Database

```
make reset_db               # drop everything and load the dump from init_db
make backup_db name=mydump  # dump the database into sql/<date>-mydump.sql
make db_shell               # database shell
```

### Scheduled jobs

Jobs do not run on a schedule locally. Run one by hand:

```
make run_scheduler method=<method> service=<service>
```

### Cleaning up

```
make clean       # stop and remove the containers
make clean_all   # also remove volumes (the database is lost)
```

## Addresses

__ADDRESS_LIST__
