# ULID for PostgreSQL

ULID is a 128-bit Universally Unique Lexicographically Sortable Identifier. This project provides a PostgreSQL function to generate ULID using PostgreSQL's plv8 and pgcrypto extension.

See [ULID specification](https://github.com/ulid/spec) for more details.

See [ULID JavaScript implementation](https://github.com/ulid/javascript) for the original TypeScript implementation.

## Note

This implementation has removed some features from the original implementation for simplicity, such as:

- Support for custom prng
- Support for feeding seedTime to ulid()

## Prerequisites

- [PostgreSQL](https://www.postgresql.org) (tested on PostgreSQL 15)
- [plv8 extension](https://plv8.github.io)
- [pgcrypto extension](https://www.postgresql.org/docs/current/pgcrypto.html)

## Install

Download [ulid.sql](ulid.sql) and execute it in PostgreSQL.

## Usage

### Alter Column

```sql
ALTER TABLE `table_name` ALTER COLUMN `column_name` TYPE CHAR(26);
```

### Set Default

```sql
ALTER TABLE `table_name` ALTER COLUMN `column_name` SET DEFAULT ulid();
```

### Generate ULID

```sql
select ulid();
```

## License

MIT License
