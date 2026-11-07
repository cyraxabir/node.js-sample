const { describe, it, after } = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");

const app = require("./server");

/**
 * Helper – makes a GET request and returns { statusCode, body }.
 */
function get(path) {
  return new Promise((resolve, reject) => {
    http
      .get(`http://127.0.0.1:${process.env.PORT || 8080}${path}`, (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () =>
          resolve({ statusCode: res.statusCode, body: JSON.parse(data) })
        );
      })
      .on("error", reject);
  });
}

describe("GET /", () => {
  it("should return the expected JSON payload", async () => {
    const { statusCode, body } = await get("/");
    assert.equal(statusCode, 200);
    assert.equal(body.message, "Hello from DevOps Intern Task!");
    assert.equal(body.status, "running");
  });
});

describe("GET /health", () => {
  it("should return healthy status", async () => {
    const { statusCode, body } = await get("/health");
    assert.equal(statusCode, 200);
    assert.equal(body.status, "healthy");
  });
});

after(() => {
  // Close the server so the test process can exit
  process.exit(0);
});
