# Serverless Data Lake on AWS

An end-to-end serverless data lake on AWS: raw and curated storage in S3, schema discovery and CSV-to-Parquet transformation with AWS Glue, centralized governance with AWS Lake Formation, SQL analytics with Amazon Athena, log-based monitoring with Amazon CloudWatch, and a BI dashboard in Amazon QuickSight.


## Table of contents
- [Architecture](#architecture)
- [Dataset](#dataset)
- [Data flow](#data-flow)
- [Storage layer](#storage-layer)
- [Governance layer](#governance-layer)
- [Processing layer](#processing-layer)
  - [Crawler](#crawler)
  - [ETL job](#etl-job)
- [Query layer](#query-layer)
- [Monitoring layer](#monitoring-layer)
- [BI layer](#bi-layer)


## Architecture
<img width="1141" height="551" alt="AWS Serverless Data Lake drawio" src="https://github.com/user-attachments/assets/6797d913-9d43-487a-9287-5d57c01e6609" />
The platform is organized into six layers:

| Layer | Services | Responsibility |
|---|---|---|
| Storage | Amazon S3 | Raw (CSV) and curated (Parquet) zones |
| Governance | AWS Lake Formation | Registered storage location, permissions on data locations and tables |
| Processing | AWS Glue (crawler, ETL job, Data Catalog) | Schema discovery, metadata, format conversion |
| Query | Amazon Athena | Serverless SQL over the Glue Data Catalog |
| Monitoring | Amazon CloudWatch | Pipeline logs |
| BI | Amazon QuickSight | Dashboarding |

## Dataset

A movies dataset in CSV format (`movies.csv`) with one row per title. Columns include release year, title, directors (`directors_0..2`), rating, genres (`genres_0..1`), rank, running time in seconds, and actors (`actors_0..2`). Some columns are sparse (for example `rating`, `running_time_secs`, and secondary directors), which makes explicit type handling necessary in queries.

## Data flow

1. **Ingest:** `movies.csv` lands in the raw zone of the S3 bucket under `data/movies_csv/`.
2. **Discover:** A Glue crawler scans the `data/` prefix, infers the schema, and registers a partitioned table (`data`) in the `movies-db` database of the Glue Data Catalog.
3. **Transform:** A Glue ETL job reads the table through the Data Catalog and writes the dataset as Parquet to the curated zone, `data/movies_parquet/`.
4. **Re-catalog:** The crawler runs again and registers the new prefixes, producing the `movies_csv` and `movies_parquet` tables alongside `data`.
5. **Query:** Athena resolves table metadata from the Data Catalog and reads the underlying files from S3.
6. **Visualize:** QuickSight issues SQL to Athena and renders the dashboard.
7. **Observe:** Crawler and job logs are written to CloudWatch Logs throughout.

Access at every step is mediated by Lake Formation grants layered on top of IAM.

## Storage layer

A single S3 bucket holds two zones under the `data/` prefix, plus a results location for Athena:

<img width="1518" height="307" alt="022548789168" src="https://github.com/user-attachments/assets/0d83310b-af74-4b99-b45e-4b80757190d8" />

The raw zone is kept in its original format. The curated zone holds the analytics-ready columnar copy.

## Governance layer

AWS Lake Formation sits above IAM and S3 to provide centralized, table-level access control:

- The `data/` prefix is **registered as a data lake location** using a dedicated service role, which lets Lake Formation vend credentials for that path.
- A **data location grant** allows the Glue service role to use the registered path, so the crawler and ETL job can read and write.
- The `movies-db` database is created with its location set to the same prefix.
- **Table-level `SELECT` grants** are given to the analyst role for each table, including the tables created by the second crawler run.

Permissions are applied per table rather than per bucket, so access to new tables is an explicit decision.

<img width="1516" height="518" alt="013" src="https://github.com/user-attachments/assets/8bef3943-27ef-4163-9a61-1eb1a90ce91c" />

## Processing layer

### Crawler

The `movies-table` crawler targets the `data/` root with default settings (all subfolders crawled). It infers column types, creates the table, and registers the `movies_csv` folder as a partition (`partition_0`). Partition indexing is enabled on the table.
<img width="1507" height="282" alt="08 3" src="https://github.com/user-attachments/assets/5da01f05-c436-434b-ba85-7c317dc7235a" />

<img width="1865" height="598" alt="09" src="https://github.com/user-attachments/assets/4b5cf367-0d1f-4d14-b60a-968bf873d95b" />

### ETL job

The `ParquetConversion` job is a Glue Studio visual job with a Data Catalog source (`movies-db.data`) and an S3 target.

<img width="1227" height="446" alt="ParquetConversion Job" src="https://github.com/user-attachments/assets/6ce89e13-405e-4f9b-a47c-f321de625cb7" />


| Setting | Value |
|---|---|
| Source | Glue Data Catalog, `movies-db.data` |
| Target | `s3://<bucket>/data/movies_parquet/` |
| Format | Parquet (Glue optimized writer) |
| Compression | Uncompressed |
| Workers | 10 x G.1X |

The job appends to the target path, so it is run once per load to avoid duplicated files.

## Query layer

Athena queries the tables through the Glue Data Catalog. Rating and runtime columns are cast with `TRY_CAST`, which returns `NULL` instead of failing on blank values.

<img width="1871" height="708" alt="014" src="https://github.com/user-attachments/assets/6f98b2c0-e727-4a87-b3c1-5b06c86f24c9" />

## Monitoring layer

Glue crawler and job logs are collected in CloudWatch Logs (`/aws-glue/crawlers` and `/aws-glue/jobs/error`). CloudWatch Logs Insights is used to inspect activity across both log groups.

<img width="1878" height="558" alt="016" src="https://github.com/user-attachments/assets/5dfd34ea-a138-4477-ab65-13c5f6a4ecd3" />

## BI layer

QuickSight connects to Athena as its data source and presents the curated dataset as an interactive dashboard with filters for release year, genre, director, rating range, and title search, plus KPI cards and charts for releases over time and movies by genre.

<img width="1537" height="677" alt="017" src="https://github.com/user-attachments/assets/34023f4f-3390-489a-b938-32eb77cff4d2" />




