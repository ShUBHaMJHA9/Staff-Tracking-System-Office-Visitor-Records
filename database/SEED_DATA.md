# Database Seed Data

The following mock records are automatically inserted into the database during the `InitialCreate` migration to provide a functional starting point for the Admin Portal.

## Users (Employees & Staff)
| ID | Name | Role | Department | Email |
|----|------|------|------------|-------|
| `...0001` | Ravi Shankar Swami | Admin | Web & IT | admin@iod.com |
| `...0002` | Shubham Kumar | Staff | Web & IT | shubham@iod.com |
| `...0003` | Anita Sharma | Staff | Human Resources | anita.hr@iod.com |
| `...0004` | Satish Singh | SecurityGuard | Security Operations | guard@iod.com |
| `...0005` | Arun Bajaj | Staff | Corporate Affairs | exec@iod.com |
| `...0006` | Priya Menon | Staff | Finance & Accounting | analyst@iod.com |
| `...0007` | Karthik Raman | Staff | Web & IT | itadmin@iod.com |
| `...0008` | Sneha Rao | Staff | Corporate Affairs | secretary@iod.com |
| `...0009` | Vikram Singh | SecurityGuard | Security Operations | security@iod.com |

**Passwords:**
- `admin@iod.com` -> `admin123`
- `guard@iod.com`, `security@iod.com` -> `guard123`
- All other staff -> `staff123`

## Field Duties (Active)
- **Shubham Kumar**: Hardware installation & website training for Directors (Destination: Nehru Place Client Center)
- **Anita Sharma**: Quarterly HR compliance audit (Destination: Connaught Place Head Office)

## Encrypted Coordinates (Sample)
The raw SQLite database stores coordinates exactly like this due to the AES Encryption layer:
- `Latitude` = `JwEwxge7272vq23qjQKn3eg1L5hDfNhzq2fr++B8/QQ=`
- `Longitude` = `DFlpLbuhPWut1rh0HJ6Es1IBr/rJROzyG/ZiWAZffW4=`

## Watchlist Targets
- **Suresh Mehta** (suresh@blacklisted.com) - Reason: Disruptive behavior during General Meeting
