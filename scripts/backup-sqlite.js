const fs = require("node:fs");
const path = require("node:path");
const { DatabaseSync } = require("node:sqlite");

const root = path.join(__dirname, "..");
const dataDir = process.env.DATA_DIR ? path.resolve(process.env.DATA_DIR) : path.join(root, "data");
const sqlitePath = process.env.SQLITE_PATH || path.join(dataDir, "shaw-enterprise.db");
const backupDir = process.env.BACKUP_DIR ? path.resolve(process.env.BACKUP_DIR) : path.join(dataDir, "backups");
const stamp = new Date().toISOString().replace(/[:.]/g, "-");
const backupPath = path.join(backupDir, `shaw-enterprise-${stamp}.db`);

fs.mkdirSync(backupDir, { recursive: true });
const db = new DatabaseSync(sqlitePath);
db.exec(`VACUUM INTO '${backupPath.replace(/'/g, "''")}'`);
db.close();

console.log(backupPath);
