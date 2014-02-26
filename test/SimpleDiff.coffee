utils = require('./testUtils')
FS = require 'fs-mock'
_ = require 'lodash'

# Root for FS to make sure that the tests can run on both Windows and Linux
win32 = process.platform is 'win32' 
root =
	if win32
		cwd = process.cwd().toLowerCase()
		cwd.match(/^(\w\:)/)[1] + '\\'
	else
		'/'

newFS = (files) ->
	new FS { '/': files }, { windows: win32, root: root.slice(0, -1) }

newSimpleDiff = (fs, options) ->
	Utils = utils.require 'utils'
	if fs
		Utils.__set__ 'fs', fs
	SimpleDiff = utils.require 'diff/SimpleDiff'
	SimpleDiff.__set__ 'utils', Utils
	return new SimpleDiff options || { src: root + 'www', memory: root + 'memory' }

describe 'SimpleDiff test', () ->

	it 'Throws for a non-existent source path', () ->
		(() ->
			newSimpleDiff()
		).should.throw()

		(() ->
			newSimpleDiff src: ''
		).should.throw()

		(() ->
			newSimpleDiff null, { src: '/non/existent/path' }
		).should.throw()


	it 'Throws for missing memory path', () ->
		(() ->
			newSimpleDiff newFS(), { src: root + 'dir' }
		).should.throw()


	it 'Does not update memory file after diff computation', (done) ->
		fs = newFS
			'www/file': ''
		diff = newSimpleDiff fs
		diff.compute () ->
			fs.existsSync(root + 'memory').should.be.false
			done()


	it 'Recognizes single new file', (done) ->
		fs = newFS
			'www/file': 'contents'
			'memory': JSON.stringify { '/': {} }
		diff = newSimpleDiff fs
		diff.compute (e, diff) ->
			throw e if e
			_.keys(diff.new).should.eql [ '/file' ]
			_.keys(diff.modified).should.have.length 0
			_.keys(diff.removed).should.have.length 0
			done()


	it 'Recognizes single file modify', (done) ->
		fs = newFS
			'www/file': 'contents'
			'memory': JSON.stringify { '/': { 'file': '123fakehash123' } }
		diff = newSimpleDiff fs
		diff.compute (e, diff) ->
			throw e if e
			_.keys(diff.new).should.have.length 0
			_.keys(diff.modified).should.eql [ '/file' ]
			_.keys(diff.removed).should.have.length 0
			done()


	it 'Recognizes single file removal', (done) ->
		fs = newFS
			'www': {}
			'memory': JSON.stringify { '/': { 'file': '123fakehash123' } }
		diff = newSimpleDiff fs
		diff.compute (e, diff) ->
			throw e if e
			_.keys(diff.new).should.have.length 0
			_.keys(diff.modified).should.have.length 0
			_.keys(diff.removed).should.eql [ '/file' ]
			done()


	it 'Recognizes single unchanged', (done) ->
		fs = newFS
			'www/file': ''
			'memory': JSON.stringify { '/': { 'file': 'da39a3ee5e6b4b0d3255bfef95601890afd80709' } } # Actual SHA1 for empty string
		diff = newSimpleDiff fs
		diff.compute (e, diff) ->
			throw e if e
			_.keys(diff.new).should.have.length 0
			_.keys(diff.modified).should.have.length 0
			_.keys(diff.removed).should.have.length 0
			done()


	it 'Recognizes diff with a single new, modified, removed and unchanged file', (done) ->
		fs = newFS
			'www': {
				'emptyFile': ''
				'modifiedFile': ''
				'newFile': ''
			}
			'memory': JSON.stringify { '/': {
				'emptyFile': 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
				'removedFile': '123fakehash123'
				'modifiedFile': '123fakehash123'
			} }
		diff = newSimpleDiff fs
		diff.compute (e, diff) ->
			throw e if e
			_.keys(diff.new).should.eql [ '/newFile' ]
			_.keys(diff.modified).should.eql [ '/modifiedFile' ]
			_.keys(diff.removed).should.eql [ '/removedFile' ]
			done()


	it 'Recognizes bigger diff', (done) ->
		fs = newFS
			'www': {
				'emptyFile': ''
				'modifiedFile': ''
				'newFile': ''
				'dir':
					'emptyFile': ''
					'modifiedFile': ''
					'newFile': ''
				'newDir':
					'file1': ''
					'file2': ''
			}
			'memory': JSON.stringify {
				'/':
					'emptyFile': 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
					'removedFile': '123fakehash123'
					'modifiedFile': '123fakehash123'
				'/dir':
					'emptyFile': 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
					'removedFile': '123fakehash123'
					'modifiedFile': '123fakehash123'
				'/removedDir':
					'file1': ''
					'file2': ''
			}
		diff = newSimpleDiff fs
		diff.compute (e, diff) ->
			throw e if e
			_.keys(diff.new).should.eql [ '/newFile', '/dir/newFile', '/newDir/file1', '/newDir/file2' ]
			_.keys(diff.modified).should.eql [ '/modifiedFile', '/dir/modifiedFile' ]
			_.keys(diff.removed).should.eql [ '/removedFile', '/dir/removedFile', '/removedDir/file1', '/removedDir/file2' ]
			done()


	it 'Ignores files if excluded', (done) ->
		fs = newFS
			'www': {
				'emptyFile': ''
				'modifiedFile': ''
				'newFile': ''
			}
			'memory': JSON.stringify { '/': {
				'removedFile': '123fakehash123'
				'modifiedFile': '123fakehash123'
			} }
		diff = newSimpleDiff fs, { src: root + 'www', memory: root + 'memory', exclude: [ '*[Ff]ile' ] }
		diff.compute (e, diff) ->
			throw e if e
			_.keys(diff.new).should.have.length(0);
			_.keys(diff.modified).should.have.length(0);
			_.keys(diff.removed).should.have.length(0);
			done()