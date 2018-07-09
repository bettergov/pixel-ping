'use strict';

(function () {
  var config, configPath, emptyHeaders, endParams, endReqOpts, flush, fs, http, js, jsHeaders, jsPath, log, pixel, pixelHeaders, querystring, record, serialize, server, store, url;

  fs = require('fs');

  url = require('url');

  http = require('http');

  querystring = require('querystring');

  store = {};

  record = function record(params) {
    var key, ref;
    if (!(key = (ref = params.query) != null ? ref.key : void 0)) {
      return;
    }
    store[key] || (store[key] = 0);
    return store[key] += 1;
  };

  serialize = function serialize() {
    var data;
    data = {
      json: JSON.stringify(store)
    };
    store = {};
    if (config.secret) {
      data.secret = config.secret;
    }
    return querystring.stringify(data);
  };

  flush = function flush() {
    var data, request;
    log(store);
    if (!config.endpoint) {
      return;
    }
    data = serialize();
    endReqOpts['headers']['Content-Length'] = data.length;
    request = http.request(endReqOpts);
    request.write(data);
    request.end();
    return request.on('response', function (response) {
      return console.info('--- flushed ---');
    });
  };

  log = function log(hash) {
    var hits, key, results;
    results = [];
    for (key in hash) {
      hits = hash[key];
      results.push(console.info(hits + ':\t' + key));
    }
    return results;
  };

  server = http.createServer(function (req, res) {
    var params;
    params = url.parse(req.url, true);
    if (params.pathname === '/pixel.gif') {
      res.writeHead(200, pixelHeaders);
      res.end(pixel);
      record(params);
    } else if (params.pathname === '/pixel.js') {
      res.writeHead(200, jsHeaders);
      res.end(js);
    } else {
      res.writeHead(404, emptyHeaders);
      res.end('');
    }
    return null;
  });

  configPath = process.argv[2] || __dirname + '/../config.json';

  config = JSON.parse(fs.readFileSync(configPath).toString());

  pixel = fs.readFileSync(__dirname + '/pixel.gif');

  jsPath = url.format({
    host: config.host,
    protocol: 'http:'
  });

  js = fs.readFileSync(__dirname + '/pixel.js', 'utf8').replace("<%= root %>", jsPath);

  jsHeaders = {
    'Content-Type': 'text/javascript',
    'Content-Length': Buffer.byteLength(js, 'utf8')
  };

  pixelHeaders = {
    'Cache-Control': 'private, no-cache, proxy-revalidate',
    'Content-Type': 'image/gif',
    'Content-Disposition': 'inline',
    'Content-Length': pixel.length
  };

  emptyHeaders = {
    'Content-Type': 'text/html',
    'Content-Length': '0'
  };

  if (config.endpoint) {
    console.info('Flushing hits to ' + config.endpoint);
    endParams = url.parse(config.endpoint);

    endReqOpts = {
      host: endParams.hostname,
      port: endParams.port || 80,
      method: 'POST',
      path: endParams.pathname,
      headers: {
        'host': endParams.host,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    };
  } else {
    console.warn('No endpoint set. Hits won\'t be flushed, add "endpoint" to ' + configPath + '.');
  }

  process.on('SIGUSR1', function () {
    console.log('Got SIGUSR1. Forcing a flush:');
    return flush();
  });

  process.on('uncaughtException', function (err) {
    return console.error('Uncaught Exception: ' + err);
  });

  server.listen(config.port, config.host);

  setInterval(flush, config.interval * 1000);
}).call(undefined);