require('coffee-script/register');

var DiffDeployer = require('./lib/DiffDeployer');

DiffDeployer.SimpleDiff = require('./lib/diff/SimpleDiff');
DiffDeployer.NullReporter = require('./lib/reporters/NullReporter');
DiffDeployer.SimpleReporter = require('./lib/reporters/SimpleReporter');

module.exports = DiffDeployer;