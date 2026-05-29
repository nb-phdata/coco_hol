---
name: toolkit-configure
description: "Configure toolkit.conf with a JDBC connection from the current Cortex Code Snowflake connection. Use when: toolkit needs a connection, user runs a toolkit command without a configured connection, user says 'configure toolkit', 'setup toolkit', or 'toolkit connection'. Triggers: configure toolkit, setup toolkit, toolkit connection, toolkit config."
---

# Configure Toolkit Connection

Configure `toolkit.conf` to use the current Cortex Code Snowflake connection as a JDBC datasource.

## Workflow

### Step 1: Detect Existing Configuration

Check if `toolkit.conf` exists in the project root and whether a Snowflake connection is already configured.

1. Look for `toolkit.conf` in the project root
2. If it exists, read the `ds.datasources.snowflake.connection` block
3. If a valid JDBC URL is already present and not using placeholder values (e.g., `USER`, `ACCOUNT`), inform the user and ask if they want to overwrite it

**If no `toolkit.conf` exists:**
- Create one from the default template (see Step 3)

**If connection is already configured with real values:**

**STOP**: Ask the user if they want to overwrite the existing connection.

### Step 2: Get Current Cortex Code Connection

Retrieve the active Snowflake connection details from Cortex Code:

1. Run `cortex connections list` to see available connections
2. Identify the currently active connection (marked as active or set via `cortex connections set`)
3. Extract: account URL, database, schema, warehouse, role, password, and username

If no active connection exists, inform the user they need to set one up first:
```
No active Snowflake connection found in Cortex Code.
Set one up with: cortex connections set <connection-name>
```

**STOP** if no connection is available.

Ask the user for the current password if unavailable in current connections.

### Step 3: Build and Write Configuration

Construct the JDBC URL and update `toolkit.conf`:

**JDBC URL format:**
```
jdbc:snowflake://<account>.snowflakecomputing.com/?db=<database>&schema=<schema>&warehouse=<warehouse>&role=<role>
```

**Connection block in toolkit.conf:**
```hocon
ds {
  datasources {
    snowflake {
      connection {
        url = "jdbc:snowflake://<account>.snowflakecomputing.com/?db=<database>&schema=<schema>&warehouse=<warehouse>&role=<role>"
        username = "<username>"
        password = "<password>
      }
    }
  }
}
```

**Rules:**
- Preserve all other existing configuration blocks (match, advisor, provision, sql, etc.)
- Only update the `ds.datasources.snowflake.connection` section
- If the account URL contains `.snowflakecomputing.com` already, do not double it

### Step 4: Validate Connection

Test that the configuration works:

1. Run `toolkit ds scan snowflake --dry-run` or a similar lightweight toolkit command to verify connectivity
2. If the command is not available, run a SQL query via `sql_execute` using the same connection to confirm it's reachable

**If validation fails:**
- Show the error to the user
- Suggest common fixes (wrong account URL, missing password env var, network issues)
- Return to Step 3 if the user wants to correct values

**If validation succeeds:**
- Report success and show the configured connection details (redacting password)

## Stopping Points

- After Step 1: If existing config found, confirm overwrite
- After Step 2: If no active connection available
- After Step 4: Final confirmation of success or failure

## Output

Updated `toolkit.conf` with a working JDBC connection derived from the current Cortex Code Snowflake connection.
