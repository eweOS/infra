addEventListener("fetch", (event) => {
  event.respondWith(
    handleRequest(event.request).catch(
      (err) => errResponse("Internal Error: " + err)
    )
  );
});

// router

async function handleRequest(request) {
  const { pathname } = new URL(request.url);
  if (pathname.startsWith("/github"))
    return handleGithubRequest(request)
  if (pathname.startsWith("/update"))
    return handleUpdateRequest(request)
  return errResponse("Undefined endpoint")
}

// get: info requests

async function handleUpdateRequest(request) {
  
  if (request.method !== 'GET')
    return errResponse("Invalid method")
  const recent = JSON.parse(await EWEOS_LOG.get("last_update"))
  return jsonResponse({
    updated_date: (new Date(recent.timestamp)).getTime()
  })
}

// post: github webhooks

async function handleGithubRequest(request) {
  if (request.method !== 'POST')
    return errResponse("Invalid method")

  const contentType = request.headers.get('content-type') || '';
  if (!contentType.includes('application/json'))
    return errResponse("Blank payload")

  const hooktype = request.headers.get('X-GitHub-Event')
  if (!hooktype)
    return errResponse("No event type")

  const payload = await request.json()
  const signature = request.headers.get('X-Hub-Signature')
  if (!signature)
    return errResponse("No signature")

  const ver = await hmacverify(TOKEN, JSON.stringify(payload), signature.replace("sha1=", ""))
  if (!ver)
    return errResponse("Token verification failed")

  switch(hooktype){
    case "push": {
      return handleGithubPushRequest(payload)
    }
    case "pull_request": {
      const actiontype = payload.action
      switch(actiontype){
        case "opened": {
          return handleGithubPullRequest(payload)
        }
        case "synchronize": {
          return handleGithubPullRequest(payload)
        }
        default: {
          return errResponse("Unexpected behavior")
        }
      }
    }
    default: {
      return errResponse("Unexpected behavior")
    }
  }
}

async function handleGithubPullRequest(payload){
  const pull_request = payload.pull_request
  if (pull_request.title.includes("dontmerge"))
    return errResponse("Tagged #nobuild")
  if (pull_request.labels.includes("dontmerge"))
    return errResponse("Tagged #nobuild")
  let base_branch = pull_request.base.ref
  let pr_branch = pull_request.head.ref
  if (!base_branch || !pr_branch)
    return errResponse("No branch specified")
  if (base_branch.startsWith("_"))
    return errResponse("Ignored special branch: " + base_branch)
  return await github_dispatch(base_branch, "pr", {
    id: pull_request.id,
    sha: pull_request.head.sha
  })
}

async function handleGithubPushRequest(payload){
  const req = {
    method: 'POST',
    headers: {
      'Authorization': 'Token ' + OBS_TOKEN,
    },
  };

  if (payload.head_commit.message?.includes("#nobuild") ?? false)
    return errResponse("Tagged #nobuild")

  let branch = payload.ref
  if (!branch)
    return errResponse("No branch specified")
  if (!branch.startsWith("refs/heads/"))
    return errResponse("Invalid tag: " + branch)
  const pkg_name = branch.replace("refs/heads/","")
  if (pkg_name.startsWith("_"))
    return errResponse("Ignored special branch: " + branch)

  EWEOS_LOG.put("last_update", JSON.stringify(payload.head_commit))

  if (!payload.created) {
      await fetch("https://os-build.ewe.moe/trigger/runservice?project=eweOS:Main&package=" + pkg_name, req);
      return await github_dispatch(pkg_name)
  }
  else {
      return await github_dispatch(pkg_name,"creation")
  }
}

async function github_dispatch(pkg_name, pkg_type="push", pkg_data=null){
  const gh_req = {
    body: JSON.stringify({
      event_type: pkg_type,
      client_payload: {pkg: pkg_name, data: pkg_data}
    }),
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + GH_DISPATCH_TOKEN,
      'User-Agent': 'Cloudflare'
    },
  };
  const response = await fetch("https://api.github.com/repos/eweOS/workflow/dispatches", gh_req);
  return response 
}

// webhook verify functions

async function hmacsign(secret, data) {
  const enc = new TextEncoder();
  const signature = await crypto.subtle.sign(
    "HMAC",
    await importKey(secret),
    enc.encode(data)
  );
  return UInt8ArrayToHex(signature);
}

async function hmacverify(secret, data, signature) {
  const enc = new TextEncoder();
  return await crypto.subtle.verify(
    "HMAC",
    await importKey(secret),
    hexToUInt8Array(signature),
    enc.encode(data)
  );
}

function hexToUInt8Array(string) {
  // convert string to pairs of 2 characters
  const pairs = string.match(/[\dA-F]{2}/gi);

  // convert the octets to integers
  const integers = pairs.map(function (s) {
    return parseInt(s, 16);
  });

  return new Uint8Array(integers);
}

function UInt8ArrayToHex(signature) {
  return Array.prototype.map
    .call(new Uint8Array(signature), (x) => x.toString(16).padStart(2, "0"))
    .join("");
}

async function importKey(secret) {
  const enc = new TextEncoder();
  return crypto.subtle.importKey(
    "raw", // raw format of the key - should be Uint8Array
    enc.encode(secret),
    {
      // algorithm details
      name: "HMAC",
      hash: { name: "SHA-1" },
    },
    false, // export = false
    ["sign", "verify"] // what this key can do
  );
}

// predefined messages

async function errResponse(str) {
  return jsonResponse({
    error: true,
    msg: str
  })
}

async function jsonResponse(json) {
  const jsons = JSON.stringify(json);
  return new Response(jsons, {
    headers: {
      'content-type': 'application/json;charset=UTF-8',
      'Access-Control-Allow-Origin' : 'https://os.ewe.moe'
      }
  });
}
