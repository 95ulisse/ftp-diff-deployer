require('coffee-script/register');

module.exports = {
	DiffDeployer: require('./lib/DiffDeployer'),
	diff: {
		SimpleDiff: require('./lib/diff/SimpleDiff')
	},
	reporters: {
		NullReporter: require('./lib/reporters/NullReporter'),
		SimpleReporter: require('./lib/reporters/SimpleReporter')
	}
};