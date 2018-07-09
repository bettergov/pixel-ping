# Require core Node.js modules.
fs          = require 'fs'
url         = require 'url'
http        = require 'http'
querystring = require 'querystring'

#### The Pixel Ping server

# The in-memory hit `store` is a simple hash. We map unique identifiers to the
# number of hits they receive here, and flush the `store` every `interval`
# seconds.
store = {}

# Record a single incoming hit from the remote pixel.
record = (params) ->
  return unless key = params.query?.key
  store[key] or= 0
  store[key] +=  1

# Serializes the current `store` to JSON, and creates a fresh one. Add a
# `secret` token to the request object, if configured.
serialize = ->
  data  = json: JSON.stringify(store)
  store = {}
  data.secret = config.secret if config.secret
  querystring.stringify data

# Flushes the `store` to be saved by an external API. The contents of the store
# are sent to the configured `endpoint` URL via HTTP POST. If no `endpoint` is
# configured, this is a no-op.
flush = ->
  log store
  return unless config.endpoint
  data = serialize()
  endReqOpts['headers']['Content-Length'] = data.length
  request = http.request endReqOpts
  request.write data
  request.end()
  request.on 'response', (response) ->
    console.info '--- flushed ---'

# Log the contents of the `store` to stdout.
log = (hash) ->
  for key, hits of hash
    console.info "#{hits}:\t#{key}"

# Create a `Server` object. When a request comes in, ensure that it's looking
# for `pixel.gif` or `pixel.js`. If the request is for the pixel serve it and record the request.
server = http.createServer (req, res) ->
  params = url.parse req.url, true
  if params.pathname is '/pixel.gif'
    res.writeHead 200, pixelHeaders
    res.end pixel
    record params
  else if params.pathname is '/pixel.js'
    res.writeHead 200, jsHeaders
    res.end js
  else
    res.writeHead 404, emptyHeaders
    res.end ''
  null

#### Configuration

# Load the configuration, tracking pixel, js file, and remote endpoint.
configPath = process.argv[2] or (__dirname + '/../config.json')
config     = JSON.parse fs.readFileSync(configPath).toString()
pixel      = fs.readFileSync(__dirname + '/pixel.gif')
jsPath     = url.format({host: config.host, protocol: 'http:'})
js         = fs.readFileSync(__dirname + '/pixel.js', 'utf8').replace("<%= root %>", jsPath)

jsHeaders  = 
  'Content-Type':   'text/javascript'
  'Content-Length': Buffer.byteLength(js, 'utf8')
  
pixelHeaders = 
  'Cache-Control':       'private, no-cache, proxy-revalidate'
  'Content-Type':        'image/gif'
  'Content-Disposition': 'inline'
  'Content-Length':      pixel.length

emptyHeaders = 
  'Content-Type':   'text/html'
  'Content-Length': '0'

if config.endpoint
  console.info "Flushing hits to #{config.endpoint}"
  endParams = url.parse config.endpoint
  # endpoint  = http.createClient endParams.port or 80, endParams.hostname
  endReqOpts =
    host: endParams.hostname
    port: endParams.port or 80
    method: 'POST'
    path: endParams.pathname
    headers:
      'host':         endParams.host
      'Content-Type': 'application/x-www-form-urlencoded'
else
  console.warn "No endpoint set. Hits won't be flushed, add \"endpoint\" to #{configPath}."

# Sending `SIGUSR1` to the Pixel Ping process will force a data flush.
process.on 'SIGUSR1', ->
  console.log 'Got SIGUSR1. Forcing a flush:'
  flush()

# Don't let exceptions kill the server.
process.on 'uncaughtException', (err) ->
  console.error "Uncaught Exception: #{err}"

#### Startup

# Start the server listening for pixel hits, and begin the periodic data flush.
server.listen config.port, config.host
setInterval flush, config.interval * 1000
