# ftp-diff-deployer

> Incrementally push differences to FTP server.

`ftp-diff-deployer` is a tiny library written in [CoffeeScript](http://coffeescript.org/) that uploads only the files you've changed to your FTP server. Before uploading your files, it compares the actual files with the snapshot of the last upload: this means that the first time it's run, it will upload everything, but the subsequent times it will upload only what you've changed.

It's perfect to be run as a [Grunt](http://gruntjs.com/) task (if that's your case, it's worth checking out [grunt-ftp-diff-deployer](https://github.com/95ulisse/grunt-ftp-diff-deployer)) or as a *post-receive* hook in a git repo. These are just some examples, but you can use it any way you want!

## Installation

`ftp-diff-deployer` is available on **npm**, so you just need to issue from the root of your project:

```shell
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
	src: 'www',
	dest: '/',
	memory: 'ftp-diff-deployer-memory-file.json'
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

First of all, we istantiate a `DiffDeployer`, passing an object containing the needed information.

`host` is the name of the FTP server to connect to. The credentials for the server are stored in the `auth` object. If you need to use anonymous authentication, pass an empty username/password pair, like so:

```js
{
	host: 'ftp.anonymous.example.com',
	auth: { username: '', password: '' }
}
```

The `src` parameter is the path to the *local* folder containing the files to upload. The `dest` parameter, instead, is the path to the *remote* folder (on the server) where the files will be uploaded. Following the example, this means that the contents of the `www` folder will be uploaded to the root of the FTP server.

The `memory` parameter is the path to where the memory file containing the snapshot of your files will be created. This file is very important because it contains the state of your files at the moment of your last upload, that will be used to compute the difference.

After the `DiffDeployer` object is created, call the `deploy` method, passing a callback that will be called when the upload has finished. If an error occurred, the callback will be called with the error object, otherwise, `err` will be null, like the normal node-style callbacks.

There are are the basics that should help you get started. If you want to know more, feel free to go on!

## Full option list

```js
{
	host: 'ftp.example.com',
	port: 21,
	auth: {
		username: '',
		password: ''
	},
	src: 'www',
	dest: '/',
	exclude: [],
	memory: 'memory.json',
	diff: 'simple',
	reporter: 'simple',
	retry: 3
}
```

The foundamental options have been covered in the previous paragraph. Here we deal with the other advanced options that `ftp-diff-deploy` supports.

* **`port`**: Port of the server to connect to. Defaults to `21`.
* **`exclude`**: Array of files to exclude from the diff. This option may be useful to exclude some annoying files like the *Thumbs.db* that Windows creates. Each item in the array is a pattern that is matched using the [minimatch](https://github.com/isaacs/minimatch) library.

```js
exclude: [
	'[Tt]humbs.db', //Exclude that annoying Thumbs.db file
	'specialFolder/**/*.js' //Exclude all the javascript files inside the 'specialFolder' directory
]
```

* **`diff`**: Diff method to use. At the moment, the only supported method is `simple` (which is also the default).
* **`reporter`**: Reporter to use. The possible reporters are:
	* `simple` (Default): Just a log of what's happening.
	* `null`: Suppresses any output.
* **`retry`**: Number of attempts to try before declaring failure (defaults to `3`).

## Tests

Tu run the tests, issue from the root of the project:

```shell
grunt test
```

The tests are written with [mocha](http://visionmedia.github.io/mocha/) and [should.js](https://github.com/visionmedia/should.js).

## Special notes

`ftp-diff-deployer` is based on [jsftp](https://github.com/sergi/jsftp), which handles all the core FTP comunication. A big *thank you* to the guys behind the project!

## License

`ftp-diff-deployer` is released under the [MIT license](http://opensource.org/licenses/MIT).