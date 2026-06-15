# CoCo Hands-On Lab: Snowflake Snowsight

**Duration:** 90 minutes  
**Level:** Intermediate  
**Prerequisites:**  
* Snowflake account with CoCo enabled
* phData Toolkit Installed 
  * Follow the steps in /lab/setup/toolkit_install.md
  * OR https://toolkit.phdata.io/docs/toolkit-cli#installation:~:text=contact%20us.-,Installation,-The%20Toolkit%20CLI
  * (`toolkit --version` to verify)
* phData Toolkit configured to Snowflake and Northwinds database

---

## Overview

This hands-on lab teaches you to use **CoCo** in Snowflake Snowsight to accelerate your development workflow:

| Part | Environment | What You'll Do | Time |
|------|-------------|----------------|------|
| **1** | Snowsight (Web IDE) | Debug and extend a Python notebook that builds an ML model on sales data | 30 min |
| **2** | Snowsight (Web IDE) | Understand what is in a source system using phData Forge and develop dbt Models using CoCo | 30 min |

---

## Repository Structure

```
.
├── README.md   # Lab guide and instructions
└── .cortex/
    ├── skills/
          ├── toolkit-configure
            └── SKILL.md   # Toolkit configuration skill for CoCo  
└── lab/
    ├── part1_notebook/
    │   └── sales_churn_model.ipynb   # Starter notebook with intentional bugs
    ├── part2_notebook/
    │   └── northwind.pdf   # Business info PDF for Part 2
    │   └── top_queries.sql   # Consolidated Queries SQL script for Part 2
    ├── setup/
        └── ml_setup.sql   # SQL script for Part 1
        └── northwind_setup.sql   # SQL script for Part 2
        └── toolkit_install.md   # Toolkit Installation readme
```

---

## Part 1: Debugging and Extending an ML Model using CoCo in Snowsight (30 min)

### Context

Your team has a Python notebook that loads sales data, engineers features, and trains a model to predict whether a customer will churn. The notebook has several bugs and is missing key sections. You'll use CoCo in Snowsight to fix and extend it.

### Setup (5 min)

1. Log into Snowsight
2. Navigate to **Projects > Workspaces**
3. Prompt CoCo to create a GIT API Integration and import the provided notebook into a new Workspace:
   `https://github.com/nb-phdata/coco_hol/blob/main/lab/part1_notebook/sales_churn_model.ipynb`
5. Prompt CoCo to select the **Python 3 (Anaconda)** kernel and attach a warehouse
6. Prompt CoCo to use the same GIT API Integration to import and execute `ml_setup.sql` to create the required database, schema, and sample data: https://github.com/nb-phdata/coco_hol/blob/main/lab/setup/setup.sql

### Exercise 0: Explain the Notebook (1 min)

**Example prompt:**
> *Can you summarize what this notebook does*

### Exercise 1: Fix Errors and Get Best Practices (10 min)

After connecting to a compute pool, ask CoCo to review and fix the notebook.

**Example prompt:**
> *Can you search through this notebook and fix any errors you encounter. Additionally, please recommend any best practices*

CoCo will identify the intentional bugs in the notebook and suggest fixes, along with best practice recommendations for your ML workflow.

### Exercise 2: Review and Run (5 min)

1. **Review the best practice recommendations** that CoCo provided — accept the ones that make sense for your use case
2. **Run All** cells in the notebook to verify everything executes cleanly

### Exercise 3: Add Experimentation (15 min)

After a successful run, extend the notebook with advanced ML capabilities.

**Example prompt:**
> *Can you add Principal Component Analysis to the notebook. Additionally, I want to add Snowflake experiments across different ML algorithms to assess which model scores best*

This will add PCA for dimensionality reduction and set up experiment tracking to compare multiple models.

### Exercise 4: Iterate and Fix (10 min)

1. **Ask CoCo to fix any remaining issues** — sometimes you'll need to append experiment names with timestamps depending on how many times you've run it
2. **Run All** again to verify the full pipeline executes end-to-end

### What You've Accomplished

By the end of Part 1, you've taken a baseline model notebook, fixed errors, added robust experimentation across multiple ML algorithms, and set it up to deploy the best model to the Snowflake Model Registry each training run.

---

## Part 2: Data Discovery using phData Forge and dbt Model Development using CoCo in Snowsight (30 min)

### Context

The purpose of this Cortex Code (CoCo) demo is to walk through a realistic, AI-augmented data engineering workflow on top of the classic Northwinds dataset. We’ll start by automatically profiling the environment using documentation gathering and a phData Toolkit-driven DDL scan, then use Cortex Code to perform interactive database discovery. This combination is meant to show how you can quickly move from “what’s in this source system?” to a clear understanding of key entities, relationships, and business processes without spending days spelunking information_schema and legacy reports.
From there, the session will focus on turning that understanding into actionable assets: we’ll guide CoCo through designing a dimensional model and generating a dbt project. By the end, attendees should see Cortex Code not as a toy chatbot, but as a practical co-pilot for metadata discovery, modeling, transformation, and lightweight application scaffolding—all within Snowflake.

### Agenda

Documentation Gathering and Toolkit Scan
Northwinds Database Discovery with Cortex Code (COCO)
Creation of Dimensional Model using COCO
Creation of dbt Project using COCO

phData toolkit configured to Snowflake and Northwinds database
Top queries consolidated into one sql file as well as a business information pdf
Upload the business information pdf into a snowflake internal stage in the Northwinds schema


### Open Terminal and Verify phData Toolkit CLI

```bash
toolkit --version
```

### Setup (5 min)

1. Log into Snowsight
2. Navigate to **Projects > Workspaces** and create a new Notebook
3. Prompt CoCo to use the same GIT API Integration to import and execute `northwind_setup.sql` to create the required database, schema, and sample data: `https://github.com/nb-phdata/coco_hol/blob/main/lab/setup/setup.sql`
4. Upload the business PDF `northwind.pdf` into a Snowflake internal stage via CoCo
5. Open your terminal
6. Navigate to your project directory:
   ```bash
   cd COCO_HOL
   ```
7. Install the phData CLI (if you have not done so already):
   ```
   brew install toolkit-cli
   ```
   or
   ```
   brew tap phdata/toolkit
   ```
8. Create a new toolkit instance within the directory:
   ```bash
   toolkit init
   ```
9. Now we will configure the phData Toolkit to Snowflake and the Northwinds database:
   a. Open `toolkit.conf`
   b. Add the following connection:
      ```
      connections {
        snowflake {
          url = "jdbc:snowflake://<org-name>-<account-name>.snowflakecomputing.com"
          properties {
            user = "<your_snowflake_login_name"
            role = "ACCOUNTADMIN" or <your-role>
            warehouse = "COMPUTE_WH" or <your-warehouse>
            private_key_file = ${PRIVATE_KEY_FILE}
            private_key_file_pwd = ${PRIVATE_KEY_FILE_PWD}
          }
        }
      }
      
      ds {
        datasources {
          snowflake {
            connection = ${connections.snowflake}
          }
        }
      }
      ```
   c. Generate a 2048-bit RSA private key in PKCS#8 format and store it in a secure local folder such as ~/.snowflake/keys/rsa_key.p8.
      ```
      openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 des3 -inform PEM -out rsa_key.p8
      mkdir -p ~/.snowflake/keys
      mv rsa_key.p8 ~/.snowflake/keys/
      chmod 600 ~/.snowflake/keys/rsa_key.p8
      ```
   d. Generate the matching public key from that private key and save it as rsa_key.pub in the same folder.
      ```
      openssl rsa -in ~/.snowflake/keys/rsa_key.p8 -pubout -out ~/.snowflake/keys/rsa_key.pub
      chmod 644 ~/.snowflake/keys/rsa_key.pub
      ```
   e. Assign the public key to the Snowflake user with ALTER USER ... SET RSA_PUBLIC_KEY='...', using only the body of the public key and excluding the BEGIN/END PUBLIC KEY lines.
      ```
      PUBK=$(grep -v "PUBLIC KEY" ~/.snowflake/keys/rsa_key.pub | tr -d '\n')
      echo "$PUBK"
      ```
   f. Now, enter into the Snowsight webpage and prompt CoCo:
      ```
      ALTER USER <YOUR_SNOWFLAKE_USER> SET RSA_PUBLIC_KEY='paste_one_line_value_here';
      ```
   g. Verify the key pair by comparing the Snowflake user fingerprint from DESC USER <user> to the fingerprint generated locally from rsa_key.pub:
      ```
      DESC USER YOUR_SNOWFLAKE_USER;
      ```
   h. In the terminal, ensure the same value is returned, using:
      ```
      openssl rsa -pubin -in ~/.snowflake/keys/rsa_key.pub -outform DER | openssl dgst -sha256 -binary | openssl enc -base64
      ```
   i. Best practice is to use environment variables rather than hard-coding the secrets in `toolkit.conf`.
      ```
      export PRIVATE_KEY_FILE="$HOME/.snowflake/keys/rsa_key.p8"
      export PRIVATE_KEY_FILE_PWD="your-passphrase"
      export CONNECTION_ROLE="ACCOUNTADMIN"
      ```
      Your `toolkit.conf` should now look like:
      ```
      connections {
        snowflake {
          url = "jdbc:snowflake://<orgname>-<accountname>.snowflakecomputing.com"
          properties {
            user = "<your_snowflake_login_name>"
            role = ${CONNECTION_ROLE}
            warehouse = "COMPUTE_WH" or <your-warehouse>
            private_key_file = ${PRIVATE_KEY_FILE}
            private_key_file_pwd = ${PRIVATE_KEY_FILE_PWD}
          }
        }
      }
      
      ds {
        datasources {
          snowflake {
            connection = ${connections.snowflake}
          }
        }
      }
     ```
10. Validate the setup by running a Toolkit command such as `toolkit ds scan snowflake`.
11. Next, Output the scan to JSON: 
    ```
    toolkit ds show snowflake:scan:latest --format JSON -o
    ```
    
#### Step 1: Feed Information into Cortex Code

**Upload top_queries.sql, your Snowflake scan, and the business documentation into CoCo with the prompt:**
> *Use the top_queries.sql, northwind.pdf, and snowflake_scan files to answer my following questions. Act like this is an actual business and not the sample database.* 

#### Step 2: Ask Database Discovery Questions with Cortex Code

**Top Questions to Ask:**
> *What business process does this data represent?*
> *What numeric measures exist that represent performance or activity?*
> *What is the lowest level of detail captured by the primary transaction tables?*
> *Which entities appear across multiple business processes and would likely become conformed and shared dimensions?*
> *Which date should be considered the primary reference point for a "daily" or "monthly" report?*
> *Which attributes might change over time but still need historical tracking?* 

#### Step 3: Data Model Design with Cortex Code

**Example prompt:**
> *Based on the information we gathered and questions you answered, build a Kimball data model, and leave the tables empty until I validate it.* 

**Output:** Database created, with empty dim and fact tables.

#### Step 4: dbt Model Creation with Cortex Code

**Create a network rule for dbt, if not already there:**
```
CREATE OR REPLACE NETWORK RULE my_dbt_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  -- Minimal URL allowlist that is required for dbt deps
  VALUE_LIST = (
    'hub.getdbt.com',
    'codeload.github.com'
    );

-- Create EXTERNAL ACCESS INTEGRATION for dbt access to external dbt package locations

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION my_dbt_ext_access
  ALLOWED_NETWORK_RULES = (my_dbt_network_rule)
  ENABLED = TRUE;
```

**Example prompt:**
> *Create the tables in a separate schema, called northwinds_dw, and create a dbt project to populate the those tables.*

**Output:** A dbt project with sources, stages, tables, transformations, and DAG.

Note: Check for data in the tables.

---

## Wrap-Up

### What You Built

| Component | Location | Purpose |
|-----------|----------|---------|
| Fixed & extended notebook | Snowsight | Debugged, added PCA, experimentation, and model registry deployment |
| Dimensional model + dbt project | Snowsight | Profiled Northwind with Toolkit scan, designed a Kimball model, and generated a dbt project with CoCo |

### Key Takeaways

1. **CoCo in Snowsight** accelerates notebook development by helping you debug, generate, and explain code inline
2. **phData Toolkit + CoCo** accelerates data engineering by combining automated DDL scanning and metadata discovery with AI-guided dimensional modeling and dbt project generation — compressing days of source system analysis into a single session.

### Next Steps

- Explore phData Forge: `https://www.phdata.io/phdata-forge/`
- Build custom skills to encode team expertise (see `$skill-development`)
- Define project rules with `AGENTS.md` for session-persistent conventions
- Try background agents: `Run a background agent to refactor all test files`
- Connect external tools via MCP: `cortex mcp add github -- npx @modelcontextprotocol/server-github`

---

## Quick Reference

| Action | Syntax |
|--------|--------|
| Include file | `@path/to/file` |
| Reference table | `#DB.SCHEMA.TABLE` |
| Invoke skill | `$skill-name` |
| Run shell command | `!git status` |
| Execute SQL | `/sql SELECT 1` |
| Switch mode | `Shift+Tab` |
| Plan mode | `Ctrl+P` |
| Help | `?` |
