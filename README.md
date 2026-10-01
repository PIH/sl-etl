# sl-etl
ETL repository for Partners In Health Sierra Leone

# Docker image

`partnersinhealth/sl-etl` layers this project's `datasources/`, `jobs/` and `application-docker.yml`
(as its `application.yml`) on the [PETL](https://github.com/PIH/petl) base image,
`partnersinhealth/petl`. CI builds and pushes it (`Dockerfile`, build context `target/docker/`,
populated by `mvn package`) on every push and on every release, tagged `latest` and the version.
The `Dockerfile` pins the PETL base image by digest; Renovate (`renovate.json`) opens a PR when a
newer image is published for the tag it follows, merged automatically once its checks pass. To stay
on a PETL version, pin that version's tag instead of `latest`. To build it locally: `./build-runtime-docker-image.sh`, which
layers on a locally built `partnersinhealth/petl:local`.

It runs as [openmrs-contrib-distro-tools](https://github.com/PIH/openmrs-contrib-distro-tools)'
`petl` service (see its `docs/services.md`), e.g. for the kgh-test CI server:

    PETL_IMAGE_NAME=partnersinhealth/sl-etl
    PETL_FULL_REFRESH_JOBS="create-partitions.yml refresh-ci-warehouse.yml"
    PETL_SQLSERVER_DATABASE=openmrs_kgh_test

`application-docker.yml` maps the `kgh` OpenMRS datasource and the `warehouse` SQL Server
datasource onto distro-tools' `PETL_MYSQL_*` and `PETL_SQLSERVER_*` variables. The other sites'
datasources aren't set; set one by its Spring environment-variable name where it's needed (e.g.
`DATASOURCES_OPENMRS_<SITE>_HOST`).
