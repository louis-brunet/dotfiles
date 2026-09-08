import assert from "node:assert/strict";
import test from "node:test";

import { buildRequestOptions } from "./http.ts";

test("buildRequestOptions uses basic auth with the Azure DevOps PAT", () => {
  const options = buildRequestOptions("azure-devops-user", "secret-token");
  const headers = options.headers as Record<string, string>;

  assert.equal(headers.Accept, "application/json");
  assert.equal(headers["Content-Type"], "application/json");
  assert.equal(headers.Authorization, "Basic YXp1cmUtZGV2b3BzLXVzZXI6c2VjcmV0LXRva2Vu");
});
