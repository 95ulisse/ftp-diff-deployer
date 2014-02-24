rewire = require 'rewire'

exports.require = (path) -> rewire '../lib/' + path