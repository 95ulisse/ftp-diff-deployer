path = require 'path'
fs = require 'fs'
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
		memory =
			if utils.file.exists @options.memory
				JSON.parse utils.file.read @options.memory
			else
				{}

		# Traverses the source tree and build a tree of the source files
		tree = {}
		utils.file.recurse @options.src, (fullpath) =>
			fullpath = path.normalize '/' + path.relative @options.src, fullpath
			dir = tree[path.dirname fullpath] ||= {}
			dir[path.basename fullpath] = utils.file.hash path.resolve @options.src, fullpath.slice(1)


		# Creates the diff by comparing the memory and the actual tree
		diff =
			new: []
			modified: []
			removed: []
		for dir, files of tree
			if not memory[dir]
				diff.new.push path.join dir, f for f of files
			else
				for f, h of files
					if not memory[dir][f]
						diff.new.push path.join dir, f
					else if memory[dir][f] != h
						diff.modified.push path.join dir, f
						delete memory[dir][f]
					else
						delete memory[dir][f]
		for dir, files of memory # What's left are the removed files
			for f of files
				diff.removed.push path.join dir, f

		# Saves back the tree as the new memory file
		utils.file.write @options.memory, JSON.stringify tree

		# Calls the callback with the computed diff
		done null, diff
		return true