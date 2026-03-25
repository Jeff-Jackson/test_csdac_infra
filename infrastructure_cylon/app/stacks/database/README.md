# Database stack (RDS MariaDB / MySQL)

---

## 📘 Overview
This stack manages RDS instances for both **MariaDB** and **MySQL** across environments.

Supported operations:
- Create and update RDS primary/secondary instances
- Upgrade DB engine versions (e.g., MariaDB 10.11 → 11.4, MySQL 8.0 → 8.4)
- Manage parameter and option groups
- (Optionally) manage IAM role for Enhanced Monitoring

---

## 🧩 Instance maps & sensible defaults
This stack uses **maps** to define DB instances per engine:

- `mysql_instances = { primary = {...}, secondary = {...}, ... }`
- `mariadb_instances = { primary = {...}, secondary = {...}, ... }`

For each map item we accept optional overrides; if a key is omitted we fall back to module-level defaults (from `variables.tf`). The most relevant keys are:

| Key                      | Type    | Default (MySQL)     | Default (MariaDB) | Notes |
|--------------------------|---------|---------------------|-------------------|-------|
| `instance_class`         | string  | `var.mysql_instance_class`   | `var.mariadb_instance_class` | Safe project-wide defaults; override per env when needed. |
| `engine_version`         | string  | –                   | –                 | Use two-step upgrade below. |
| `family`                 | string  | `mysql8.0`/`mysql8.4` | `mariadb10.11/11.4` | Must match engine *family*, not patch. |
| `major_engine_version`   | string  | `8.0`/`8.4`         | `10.11`/`11.4`    | Controls OptionGroup family. |
| `deletion_protection`    | bool    | `false`             | `false`           | Recommend `true` in prod. |
| `monitoring_interval`    | number  | `60`                | `60`              | Enables Enhanced Monitoring when `monitoring_role_arn` is set. |
| `parameter_group_name`   | string  | (unset)             | (unset)           | Only pin when required; avoid timestamped legacy names. |
| `create_db_parameter_group` | bool | `true`             | `true`            | Set `false` during Stage 1 if you must keep old family. |
| `create_db_option_group` | bool    | `true`              | `true`            | Same as above. |

**Example (single primary per engine):**
```hcl
mysql_instances = {
  primary = {
    instance_class       = "db.r6g.large"
    engine_version       = "8.4.6"
    deletion_protection  = true
    monitoring_interval  = 60
  }
}

mariadb_instances = {
  primary = {
    instance_class       = "db.r7g.2xlarge"
    engine_version       = "11.4.8"
    deletion_protection  = true
    monitoring_interval  = 60
  }
}
```

**Example (add a secondary MariaDB later):**
```hcl
mariadb_instances = {
  primary = { instance_class = "db.r6g.2xlarge" }
  secondary = {
    suffix                 = "-secondary"
    instance_class         = "db.r6g.2xlarge"
    manage_master_user_password = true
  }
}
```

---

## ⚙️ Engine Upgrade Workflow (Two-Step)

Upgrading MySQL or MariaDB engine versions (for example, MySQL 8.0 → 8.4) in AWS RDS requires a two-step process to avoid compatibility errors with parameter and option groups.

**Why is this needed?**

AWS does **not** allow attaching a parameter/option group for a new engine family (e.g., `mysql8.4`) to an RDS instance that is still running the previous major engine version (e.g., 8.0). Attempting to do so will result in an error like:

```
InvalidParameterCombination: The DB parameter group 'mysql8.4-...' is not allowed for engine version 8.0.36
```

To safely upgrade and avoid downtime or failed applies, use this two-stage approach:

### 1️⃣ Stage 1 – Engine version only

Upgrade only the `engine_version` to the target patch version, but **keep** the `family` and `major_engine_version` in your parameter and option groups unchanged.

**Example:** Upgrading MySQL 8.0.36 → 8.4.6 while still using `family = "mysql8.0"`.

#### HCL Example (`main.tf`):
```hcl
module "db" {
  source  = "..."
  engine  = "mysql"
  engine_version = "8.4.6"
  # Still using old family
  family  = "mysql8.0"
  major_engine_version = "8.0"
  # ...
}
```

#### `terraform.tfvars`:
```hcl
engine_version = "8.4.6"
family         = "mysql8.0"
major_engine_version = "8.0"
```

Apply this change and wait for the RDS instance to finish upgrading the engine.

### 2️⃣ Stage 2 – Parameter/Option groups

Once the engine is running the new major version, update the `family` and `major_engine_version` to match the new engine (e.g., `mysql8.4`).

**Example:** Switch parameter/option groups to the new family.

#### HCL Example (`main.tf`):
```hcl
module "db" {
  source  = "..."
  engine  = "mysql"
  engine_version = "8.4.6"
  # Now switch to new family
  family  = "mysql8.4"
  major_engine_version = "8.4"
  # ...
}
```

#### `terraform.tfvars`:
```hcl
engine_version = "8.4.6"
family         = "mysql8.4"
major_engine_version = "8.4"
```

Apply again to update the parameter and option groups.

### Quick tfvars templates (per environment)
**Stage 1 – engine-only (keep old families)**
```hcl
mysql_instances = {
  primary = {
    engine_version           = "8.4.6"
    family                   = "mysql8.0"
    major_engine_version     = "8.0"
    deletion_protection      = true
    monitoring_interval      = 60
    # Keep legacy groups / avoid churn in Stage 1
    create_db_parameter_group = false
    create_db_option_group    = false
  }
}

mariadb_instances = {
  primary = {
    engine_version           = "11.4.8"
    family                   = "mariadb10.11"
    major_engine_version     = "10.11"
    deletion_protection      = true
    monitoring_interval      = 60
    create_db_parameter_group = false
    create_db_option_group    = false
  }
}
```

**Stage 2 – switch to new families**
```hcl
mysql_instances = {
  primary = {
    engine_version           = "8.4.6"
    family                   = "mysql8.4"
    major_engine_version     = "8.4"
    deletion_protection      = true
    monitoring_interval      = 60
    create_db_parameter_group = true
    create_db_option_group    = true
  }
}

mariadb_instances = {
  primary = {
    engine_version           = "11.4.8"
    family                   = "mariadb11.4"
    major_engine_version     = "11.4"
    deletion_protection      = true
    monitoring_interval      = 60
    create_db_parameter_group = true
    create_db_option_group    = true
  }
}
```

---

**This two-step approach:**
- Prevents `InvalidParameterCombination` errors from AWS.
- Ensures a safe, zero-downtime upgrade path for production environments.
- Lets you validate the engine upgrade before changing configuration groups.

---

## 🧱 Terraform State Handling

### 1️⃣ `RUN_IMPORT=true`
Use when **resource exists in AWS** but **is missing from Terraform state**.

Example cases:
- Stack was recreated and lost its state file.
- RDS or parameter/option groups were manually imported once and now need to be re-attached.

This stage will run:
```bash
terraform import module.mariadb["primary"].module.db_instance.aws_db_instance.this[0] <db_identifier>
terraform import module.db["primary"].module.db_instance.aws_db_instance.this[0] <db_identifier>
...
```

✅ Safe to run — only imports existing resources.

---

### 2️⃣ `RUN_STATE_MIGRATE=true`
Use when Terraform plan shows:
```
- destroy module.db.module.db_instance...
+ create module.db["primary"].module.db_instance...
```

This happens after refactor (introduction of `for_each` → `"primary"`, `"secondary"` keys).

The migration stage will move existing resources in state:
```bash
terraform state mv \
  module.db.module.db_instance.aws_db_instance.this[0] \
  module.db["primary"].module.db_instance.aws_db_instance.this[0]
```

✅ No real resources touched — only renames addresses inside state.

---

### One‑time flags guidance
- **RUN_STATE_MIGRATE=true** — use once per environment right after refactor (e.g., introducing `for_each` with keys like `"primary"`, `"secondary"`). It rewrites state addresses; real resources are untouched.
- **RUN_IMPORT=true** — only when resources exist in AWS but are missing from state (rare in this project). Safe to run; it just imports.
- After a successful run, set both to `false` in subsequent pipelines.

---

## 🔒 Enhanced Monitoring IAM Role
You can choose one of two models:

| Model | Description |
|--------|-------------|
| **A — External Role** | Role created manually or in another stack. Use `create_monitoring_role=false` and specify `monitoring_role_arn` in tfvars. |
| **B — Managed by TF** | Terraform creates/imports and manages the role. Use `create_monitoring_role=true`. During import, the pipeline auto-detects and imports the role if it exists. |

> ℹ️ In this stack, the **centralized IAM role model (A)** is used.
>
> The shared role `*-rds-monitoring-role` is created and managed in `iam.tf`,
> while both MySQL and MariaDB RDS modules have `create_monitoring_role = false`
> and reference its ARN via `monitoring_role_arn = aws_iam_role.rds_monitoring.arn`.
>
> This avoids duplicate role creation across modules and ensures a single
> consistent Enhanced Monitoring configuration per environment.

**Policy attachment**: the shared role must have `AmazonRDSEnhancedMonitoringRole` attached. In this stack we attach it explicitly:
```hcl
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
```

---

## 🚫 Do/Don’t with Parameter/Option Groups
- ✅ **Do** let Terraform create fresh Parameter/Option Groups when switching families (Stage 2). This avoids timestamped legacy names.
- ✅ **Do** avoid hard-pinning `parameter_group_name`/`option_group_name` unless you have a migration/rollback reason.
- ❌ **Don’t** switch families and engine version in a single step on prod — you will hit `InvalidParameterCombination`.

---

## 🧩 Useful Commands
```bash
# See what’s in the state
terraspace build database
cd .terraspace-cache/<region>/<env>/stacks/database
terraform state list

# Inspect a specific resource
terraform state show module.mariadb["primary"].module.db_instance.aws_db_instance.this[0]
```

---

## 🔎 Verification checklist (post-apply)
Run in the target region:
```bash
aws rds describe-db-instances \
  --region <region> \
  --db-instance-identifier <env>-cylon-mysql \
  --query 'DBInstances[0].{EngineVersion:EngineVersion,Status:DBInstanceStatus,Pending:PendingModifiedValues,PG:DBParameterGroups[0].DBParameterGroupName,OG:OptionGroupMemberships[0].OptionGroupName,Family:DBParameterGroups[0].ParameterApplyStatus,MonitoringInterval:MonitoringInterval,MonitoringRoleArn:MonitoringRoleArn,MultiAZ:MultiAZ,DeletionProtection:DeletionProtection,AllocatedStorage:AllocatedStorage,MaxAllocatedStorage:MaxAllocatedStorage,BackupWnd:PreferredBackupWindow,MaintWnd:PreferredMaintenanceWindow}' --output table

aws rds describe-db-instances \
  --region <region> \
  --db-instance-identifier <env>-cylon-mariadb \
  --query 'DBInstances[0].{EngineVersion:EngineVersion,Status:DBInstanceStatus,Pending:PendingModifiedValues,PG:DBParameterGroups[0].DBParameterGroupName,OG:OptionGroupMemberships[0].OptionGroupName,Family:DBParameterGroups[0].ParameterApplyStatus,MonitoringInterval:MonitoringInterval,MonitoringRoleArn:MonitoringRoleArn,MultiAZ:MultiAZ,DeletionProtection:DeletionProtection,AllocatedStorage:AllocatedStorage,MaxAllocatedStorage:MaxAllocatedStorage,BackupWnd:PreferredBackupWindow,MaintWnd:PreferredMaintenanceWindow}' --output table
```
Expected: engine versions reflect the target (e.g., 8.4.6 / 11.4.8), monitoring is `60` with the shared role ARN, PG/OG names belong to the current family, and status is `available`.

---

## ⏱ Apply timing
We expose `var.rds_apply_immediately` to control maintenance timing. In prod we usually keep it `false` and rely on the maintenance window; for urgent patching it can be set to `true` per environment.

---

## 🔁 Recovery from interrupted apply (timeouts/locks)
If a pipeline fails during an RDS modification (e.g., timeout), Terraform may leave the OptionGroup or ParameterGroup in `in-use` state.

**Steps to recover:**
1. Release Terraform state lock manually (DynamoDB table `terraform_csdac_cylon_locks`) using:
   ```bash
   terraspace force_unlock database <LockID>
   ```
2. Verify in AWS Console that the RDS instance finished upgrading.
3. If Terraform still plans to destroy an OG/PG that is “in use”:
   - Temporarily reassign the instance to the **default** Option/Parameter Group.
   - Re-run `terraform apply` (Terraform will clean up safely).
   - Then re-enable:
     ```hcl
     create_db_option_group    = true
     create_db_parameter_group = true
     ```
     to recreate managed groups.
4. Re-apply and ensure the RDS instance uses new OG/PG names of the correct family.

---

## 🧩 Multi-instance environments
If an environment requires more than one DB instance (e.g., `primary`, `secondary`),  
use the `for_each` maps (`mariadb_instances`, `mysql_instances`).  
Set `RUN_STATE_MIGRATE=true` once after the refactor to migrate existing Terraform state addresses.

---

## 🧰 Post-apply summary in Jenkins
The Jenkins pipeline now automatically prints a compact summary for visibility:
```
==> Compact summary (engine versions & monitoring)
MySQL: engine_version=8.4.6, MonitoringInterval=60, MonitoringRoleArn=..., Status=available
MariaDB: engine_version=11.4.8, MonitoringInterval=60, MonitoringRoleArn=..., Status=available
```
Full JSON outputs are suppressed by default to keep logs concise and readable.
