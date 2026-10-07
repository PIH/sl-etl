-- Reads the chiefdom -> lat/long mapping from the CSV committed alongside the jobs.
-- Runs in an in-memory H2 database (datasources/csv-files.yml); column order must match the schema file.
select  gid_3,
        country,
        province,
        district,
        chiefdom,
        province_gadm,
        district_gadm,
        chiefdom_gadm,
        cast(latitude as decimal(9,6))  as latitude,
        cast(longitude as decimal(9,6)) as longitude,
        point_source
from    CSVREAD('${csvFile}', null, 'charset=UTF-8 fieldSeparator=,')
