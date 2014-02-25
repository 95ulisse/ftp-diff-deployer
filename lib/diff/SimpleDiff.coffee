path = require 'path'
fs = require 'fs'
_ = require 'lodash'
utils = require '../utils'

module.exports = class SimpleDiff

	constructor: (@options = {}) ->
		if not options.src
			throw new Error "'src' option is required"
		if not utils.file.exists options.src
			throw new Error "'#{options.src}' do not exists"
		if not options.memory
			throw new Error "'memory' option is required"

	compute: (done) ->

		# Reads memory JSON if available
		@memory =
			if utils.file.exists @options.memory
				JSON.parse utils.file.read @options.memory
			else
				{}
		memory = _.cloneDeep @memory

		# Traverses the source tree and build a tree of the source files
		tree = {}
		utils.file.recurse @options.src, (fullpath) =>
			fullpath = path.normalize '/' + path.relative @options.src, fullpath
			dir = tree[path.dirname fullpath] ||= {}
			dir[path.basename fullpath] = utils.file.hash path.resolve @options.src, fullpath.slice(1)


		# Creates the diff by comparing the memory and the actual tree
		diff =
			new: {}
			modified: {}
			removed: {}
		for dir, files of tree
			if not memory[dir]
				diff.new[path.join dir, f] = h for f, h of files
			else
				for f, h of files
					if not memory[dir][f]
						diff.new[path.join dir, f] = h
					else if memory[dir][f] != h
						diff.modified[path.join dir, f] = h
						delete memory[dir][f]
					else
						delete memory[dir][f]
		for dir, files of memory # What's left are the removed files
			for f, h of files
				diff.removed[path.join dir, f] = h

		# Calls the callback with the computed diff
		done null, diff
		return true

	fileUploaded: (f, hash) ->
		(@memory[path.dirname(f)] ||= {})[path.basename(f)] = hash
		utils.file.write @options.memory, JSON.stringify @memory

	fileRemoved: (f) ->
		dir = path.dirname f
		delete @memory[dir]?[path.basename f]
		delete @memory[dir] if @memory[dir]? and _.keys(@memory[dir]).length == 0
		utils.file.write @options.memory, JSON.stringify @memory