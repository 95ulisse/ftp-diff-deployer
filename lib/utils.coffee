path = require 'path'
fs = require 'fs'
crypto = require 'crypto'
iconv = require 'iconv-lite'
nodeUtil = require 'util'

utils = module.exports

# PRIVATE UTILITIES

# Windows?
win32 = process.platform is 'win32'

# Normalize \\ paths to / paths.
unixifyPath = (filepath) ->
	if win32 then filepath.replace /\\/g, '/' else filepath

# FILE UTILITIES
# All the functions from the `file` module are taken from Grunt's `file` module:
# https://github.com/gruntjs/grunt/blob/master/lib/grunt/file.js

utils.file =

	preserveBOM: false
	defaultEncoding: 'utf8'


	exists: () ->
		filepath = path.join.apply(path, arguments)
		return fs.existsSync(filepath)


	mkdir: (dirpath, mode) ->

		# Set directory mode in a strict-mode-friendly way.
		if mode is null
			mode = parseInt('0777', 8) & (~process.umask())
		
		dirpath.split(/[\/\\]/g).reduce (parts, part) ->
			parts += part + '/'
			subpath = path.resolve(parts)
			if (!utils.file.exists(subpath))
				try
					fs.mkdirSync(subpath, mode);
				catch e
					throw new Error 'Unable to create directory "' + subpath + '" (Error code: ' + e.code + ').', e
			return parts
		, ''


	read: (filepath, options = {}) ->
		try
			contents = fs.readFileSync(String(filepath));
			# If encoding is not explicitly null, convert from encoded buffer to a
			# string. If no encoding was specified, use the default.
			if options.encoding != null
				contents = iconv.decode contents, options.encoding || utils.file.defaultEncoding
				# Strip any BOM that might exist.
				if !utils.file.preserveBOM && contents.charCodeAt(0) == 0xFEFF
					contents = contents.substring(1)

			return contents
		catch e
			throw new Error 'Unable to read "' + filepath + '" file (Error code: ' + e.code + ').', e


	write: (filepath, contents, options = {}) ->
		# Create path, if necessary.
		utils.file.mkdir(path.dirname(filepath));
		try
			# If contents is already a Buffer, don't try to encode it. If no encoding
			# was specified, use the default.
			if (!Buffer.isBuffer(contents))
				contents = iconv.encode contents, options.encoding || utils.file.defaultEncoding
			# Actually write file.
			fs.writeFileSync(filepath, contents)
			return true
		catch e
			throw new Error 'Unable to write "' + filepath + '" file (Error code: ' + e.code + ').', e


	recurse: (rootdir, callback, subdir) ->
		abspath = if subdir then path.join(rootdir, subdir) else rootdir
		for filename in fs.readdirSync(abspath)
			filepath = path.join abspath, filename
			if fs.statSync(filepath).isDirectory()
				utils.file.recurse rootdir, callback, unixifyPath(path.join(subdir || '', filename || ''))
			else
				callback unixifyPath(filepath), rootdir, subdir, filename


	hash: (path) ->
		hash = crypto.createHash 'sha1'
		hash.update utils.file.read(path)
		hash.digest 'hex'


utils.wrapError = (message, data, e) ->
	if not e?
		e = data
		data = null
	err = new Error message
	err.data = data if data
	err.inner = e
	return err

utils.inspect = (obj) ->
	nodeUtil.inspect obj, depth: null, colors: true