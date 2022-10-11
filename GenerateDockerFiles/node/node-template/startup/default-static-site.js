var express = require('express');
var app = express();
var options = {
    index: ['index.html','hostingstart.html']
};
app.use('/', express.static('/opt/startup', options));
var server = app.listen(process.env.PORT);
// Must be longer than local proxy keep-alive timeout
server.keepAliveTimeout = (65 * 1000);
// Must be longer than server.keepAliveTimeout
server.headersTimeout = (66 * 1000);
