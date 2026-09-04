const path = require("node:path");

const DEFAULT_PORT = 9080;
const REQUEST_TIMEOUT_MS = 12000;
const DEFAULT_MANIFEST_URL =
  "https://dl.gxu.app/manifests/update.json";
const DEFAULT_ALLOWED_DOWNLOAD_HOSTS = [
  "dl.gxu.app",
  "github.com",
];
const DEFAULT_ALLOWED_RELEASE_HOSTS = ["github.com"];
const DEFAULT_STATS_FILE = path.join(
  __dirname,
  "..",
  "data",
  "download-counts.json",
);

function resolvePort() {
  const parsed = Number.parseInt(process.env.PORT ?? "", 10);
  return Number.isNaN(parsed) ? DEFAULT_PORT : parsed;
}

function parseCsv(value, fallback) {
  const items = String(value ?? "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
  return items.length > 0 ? items : fallback;
}

function parseBoolean(value) {
  return ["1", "true", "yes", "on"].includes(
    String(value ?? "").trim().toLowerCase(),
  );
}

function normalizePem(value) {
  const raw = String(value ?? "").trim();
  return raw ? `${raw.replace(/\\n/g, "\n")}\n` : "";
}

module.exports = {
  port: resolvePort(),
  requestTimeoutMs: REQUEST_TIMEOUT_MS,
  updateManifestUrl: process.env.UPDATE_MANIFEST_URL || DEFAULT_MANIFEST_URL,
  statsFile: process.env.STATS_FILE || DEFAULT_STATS_FILE,
  allowedDownloadHosts: parseCsv(
    process.env.ALLOWED_DOWNLOAD_HOSTS,
    DEFAULT_ALLOWED_DOWNLOAD_HOSTS,
  ),
  allowedReleaseHosts: parseCsv(
    process.env.ALLOWED_RELEASE_HOSTS,
    DEFAULT_ALLOWED_RELEASE_HOSTS,
  ),
  requireManifestSignature: parseBoolean(
    process.env.REQUIRE_MANIFEST_SIGNATURE,
  ),
  manifestSignatureKeyId: process.env.MANIFEST_SIGNATURE_KEY_ID || "",
  manifestPublicKeyPem: normalizePem(process.env.MANIFEST_PUBLIC_KEY_PEM),
};
