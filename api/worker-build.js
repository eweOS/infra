addEventListener("fetch", (event) => {
  event.respondWith(
    handleRequest(event.request).catch(
      (err) => errResponse("Internal Error: " + err)
    )
  );
});

addEventListener("scheduled", (event) => {
  event.waitUntil(handleScheduled());
});

async function handleRequest(request) {
  const { pathname } = new URL(request.url);
  if (pathname.startsWith("/list"))
    return handleListRequest(request)
  if (pathname.startsWith("/info"))
    return handleInfoRequest(request)
  if (pathname.startsWith("/build"))
    return handleBuildRequest(request)
  if (pathname.startsWith("/create"))
    return handleInitRequest(request)
  if (pathname.startsWith("/update"))
    return handleUpdateRequest(request)
  return errResponse("Undefined endpoint")
}

async function handleScheduled() {
  let ret = {}
  const pkgs = await db_eweos_build.list()
  for (const pkg of pkgs.keys) {
    ret[pkg.name] = await getPkg(pkg.name)
  }
  await db_eweos_meta.put("pkgstatus", JSON.stringify(ret), {expirationTtl: 7200}) 
  await db_eweos_meta.put("pkgstatus_update", JSON.stringify({update: Date.now()}), {expirationTtl: 7200}) 
}

async function handleListRequest(request) {
  if (request.method !== 'GET')
    return errResponse("Invalid method")
  const auth = request.headers.get('Authorization') || '';
  if(auth != "token " + AUTH_TOKEN){
    const pkgs_cached = await db_eweos_meta.get("pkgstatus")
    if (pkgs_cached)
      return jsonResponse(JSON.parse(pkgs_cached))
  }
  let ret = {}
  const pkgs = await db_eweos_build.list()
  for (const pkg of pkgs.keys) {
    ret[pkg.name] = await getPkg(pkg.name)
  }
  await db_eweos_meta.put("pkgstatus", JSON.stringify(ret), {expirationTtl: 7200}) 
  return jsonResponse(ret)

}

async function handleInfoRequest(request) {
  if (request.method !== 'GET')
    return errResponse("Invalid method")
  const { searchParams } = new URL(request.url)
  let pkgname = searchParams.get('pkg')
  if (!pkgname)
    return errResponse("No pkgname specified")
  const pkgs = await getPkg(pkgname)
  return jsonResponse(pkgs)
}

async function handleUpdateRequest(request) {
  if (request.method !== 'POST')
    return errResponse("Invalid method")
  
  const contentType = request.headers.get('content-type') || '';
  if (!contentType.includes('application/json'))
    return errResponse("Blank payload")

  const auth = request.headers.get('Authorization') || '';
  if(auth != "token " + AUTH_TOKEN)
    return errResponse("Unauthorized")

  const payload = await request.json()
  if (!payload.pkgname)
    return errResponse("No pkgname specified")
  let pkgdata = await getPkg(payload.pkgname)
  if (payload.error){
    pkgdata.update_error = payload.error
    await setPkg(payload.pkgname,pkgdata)
    return jsonResponse(pkgdata)
  }
  if (!payload.version)
    return errResponse("No version specified")
  if (!payload.date)
    return errResponse("No version specified")
  pkgdata.update_version = payload.version
  pkgdata.update_date = payload.date
  if (payload.currversion)
    pkgdata.version = payload.currversion
  pkgdata.update_error = ""
  await setPkg(payload.pkgname,pkgdata)
  return jsonResponse(pkgdata)
}

async function handleBuildRequest(request) {
  if (request.method !== 'POST')
    return errResponse("Invalid method")
  
  const contentType = request.headers.get('content-type') || '';
  if (!contentType.includes('application/json'))
    return errResponse("Blank payload")

  const auth = request.headers.get('Authorization') || '';
  if(auth != "token " + AUTH_TOKEN)
    return errResponse("Unauthorized")

  const payload = await request.json()
  const args = ["version","pkgname","status","time","date","arch"]
  if (!checkPayload(payload, args))
    return errResponse("Arguments not complete")
  let pkgdata = await getPkg(payload.pkgname)
  if(!pkgdata.build) pkgdata.build = {}
  if(!pkgdata.build[payload.arch]) pkgdata.build[payload.arch] = {}
  pkgdata.build[payload.arch].build_version = payload.version
  pkgdata.build[payload.arch].build_date = payload.date
  pkgdata.build[payload.arch].build_time = payload.time
  pkgdata.build[payload.arch].build_status = payload.status
  pkgdata.build[payload.arch].build_log = payload.log
  pkgdata.build[payload.arch].build_stop = payload.stop || ""
  await setPkg(payload.pkgname,pkgdata)
  return jsonResponse(pkgdata)
}

async function handleInitRequest(request) {
  if (request.method !== 'POST')
    return errResponse("Invalid method")
  
  const contentType = request.headers.get('content-type') || '';
  if (!contentType.includes('application/json'))
    return errResponse("Blank payload")

  const payload = await request.json()

  const auth = request.headers.get('Authorization') || '';
  if(auth != "token " + AUTH_TOKEN)
    return errResponse("Unauthorized")

  if (!payload.pkgname)
    return errResponse("No pkgname specified")
  let pkgdata = await getPkg(payload.pkgname)
  if (payload.currversion)
    pkgdata.version = payload.currversion
  await setPkg(payload.pkgname,pkgdata)
  return jsonResponse({msg: "created"})
}

async function errResponse(str) {
  return jsonResponse({
    error: true,
    msg: str
  })
}

function checkPayload(payload, arglist) {
  for (let index = 0; index < arglist.length; index++) {
    const arg = arglist[index];
    if(!payload[arg]) return false
  }
  return true
}

async function setPkg(pkgname, pkgdata) {
  await db_eweos_build.put(pkgname,JSON.stringify(pkgdata))
}

async function getPkg(pkgname) {
  return JSON.parse(await db_eweos_build.get(pkgname) || "{}")
}

async function jsonResponse(json) {
  const jsons = JSON.stringify(json);
  return new Response(jsons, {
    headers: {
      'content-type': 'application/json;charset=UTF-8',
      'Access-Control-Allow-Origin' : '*'
      }
  });
}
