# ftp-diff-deployer

> Incrementally push differences to FTP server.

`ftp-diff-deployer` is a tiny library written in [CoffeeScript](http://coffeescript.org/) that uploads only the files you've changed to your FTP server. Before uploading your files, it compares the actual files with the snapshot of the last upload: this means that the first time it's run, it will upload everything, but the subsequent times it will upload only what you've changed.

It's perfect to be run as a [Grunt](http://gruntjs.com/) task (if that's your case, it's worth checking out [grunt-ftp-diff-deployer](https://github.com/95ulisse/grunt-ftp-diff-deployer)) or as a *post-receive* hook in a git repo. These are just some examples, but you can use it any way you want!

## Installation

`ftp-diff-deployer` is available on **npm**, so you just need to issue from the root of your project:

```
npm install ftp-diff-deployer
```

Remember not to forget the `--save` option if you want to store the dependency on `ftp-diff-deployer` in your `package.json`!

## Sample usage

```js
var DiffDeployer = require('ftp-diff-deployer');

var deployer = new DiffDeployer({
	host: 'ftp.example.com',
	auth: {
		username: 'foo',
		password: 'bar'
	},
	diff: new DiffDeployer.SimpleDiff({
		src: 'www',
		memory: 'ftp-diff-deployer-memory-file.json'
	}),
	src: 'www',
	dest: '/'
});

deployer.deploy(function (err) {
	if (err) {
		console.error('Something went wrong!');
		console.error(err);
	} else {
		console.log('Everything went fine!');
	}
});
```

First of all, we istantiate a `DiffDeployer`, passing an object containing the needed information (`host`, `auth`, `diff`, `src` and `dest`).

`host` is the name of the FTP server to connect to. The credentials for the server are stored in the `auth` object. If you need to use anonymous authentication, pass an empty username/password pair, like so:

```
{
	host: 'ftp.anonymous.example.com',
	auth: { username: '', password: '' }
}
```

The `diff` parameter contains an object that will be used to compute the difference from the previous upload. In this example we use the predefined `SimpleDiff`, which uses hashes to compute the difference. The `memory` parameter is the path to where the memory file containing the snapshot of your files will be created.

The `src` parameter is the path to the *local* folder containing the files to upload. The `dest` parameter, instead, is the path to the *remote* folder (on the server) where the files will be uploaded.

After the `DiffDeployer` object is created, call the `deploy` method, passing a callback that will be called when the upload has finished. If an error occurred, the callback will be called with the error object, otherwise, `err` will be null, like the normal node-style callbacks.

There are are the basics that should help you get started. If you want to know more, feel free to go on!