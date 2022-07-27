var express = require('express');
var server = express();
var options = {
    index: ['index.html','hostingstart.html']
};
// Must be longer than local proxy keep-alive timeout
server.keepAliveTimeout = (65 * 1000);
// Must be longer than server.keepAliveTimeout
server.headersTimeout = (66 * 1000);
server.use('/', express.static('/opt/startup', options));
server.listen(process.env.PORT);
