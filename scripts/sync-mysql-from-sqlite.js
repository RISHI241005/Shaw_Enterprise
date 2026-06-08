const { spawnSync } = require("node:child_process");
const path = require("node:path");

const root = path.join(__dirname, "..");
const outputPath = path.join(root, "data", "shaw-enterprise-mysql.sql");
const mysqlHost = process.env.MYSQL_HOST || "localhost";
const mysqlUser = process.env.MYSQL_USER || "root";
const mysqlPassword = process.env.MYSQL_PASSWORD || "";
const mysqlDatabase = process.env.MYSQL_DATABASE || "shaw_enterprise";

if (!mysqlPassword) {
  console.error("MYSQL_PASSWORD is required to sync MySQL.");
  process.exit(1);
}

const exportResult = spawnSync(process.execPath, ["--experimental-sqlite", path.join(__dirname, "export-mysql-database.js")], {
  cwd: root,
  env: process.env,
  encoding: "utf8"
});

if (exportResult.status !== 0) {
  console.error(exportResult.stderr || exportResult.stdout);
  process.exit(exportResult.status || 1);
}

const importResult = spawnSync("mysql", ["-h", mysqlHost, "-u", mysqlUser, `--database=${mysqlDatabase}`], {
  cwd: root,
  input: require("node:fs").readFileSync(outputPath, "utf8"),
  env: { ...process.env, MYSQL_PWD: mysqlPassword },
  encoding: "utf8"
});

if (importResult.status !== 0) {
  console.error(importResult.stderr || importResult.stdout);
  process.exit(importResult.status || 1);
}

console.log(`Synced ${outputPath} into ${mysqlDatabase}.`);
