utils = require('./testUtils')
FS = require 'fs-mock'

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
	SimpleDiff = utils.require 'SimpleDiff'
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


	it 'Updates memory file after diff computation', (done) ->
		fs = newFS
			'www/file': ''
		diff = newSimpleDiff fs
		diff.compute () ->
			fs.existsSync(root + 'memory').should.be.ok
			JSON.parse(fs.readFileSync(root + 'memory') + '').should.eql { '/': { 'file': 'da39a3ee5e6b4b0d3255bfef95601890afd80709' } }
			done()


	it 'Recognizes single new file', (done) ->
		fs = newFS
			'www/file': 'contents'
			'memory': JSON.stringify { '/': {} }
		diff = newSimpleDiff fs
		diff.compute (diff) ->
			diff.new.should.eql [ '/file' ]
			diff.modified.should.have.length 0
			diff.removed.should.have.length 0
			done()


	it 'Recognizes single file modify', (done) ->
		fs = newFS
			'www/file': 'contents'
			'memory': JSON.stringify { '/': { 'file': '123fakehash123' } }
		diff = newSimpleDiff fs
		diff.compute (diff) ->
			diff.new.should.have.length 0
			diff.modified.should.eql [ '/file' ]
			diff.removed.should.have.length 0
			done()


	it 'Recognizes single file removal', (done) ->
		fs = newFS
			'www': {}
			'memory': JSON.stringify { '/': { 'file': '123fakehash123' } }
		diff = newSimpleDiff fs
		diff.compute (diff) ->
			diff.new.should.have.length 0
			diff.modified.should.have.length 0
			diff.removed.should.eql [ '/file' ]
			done()


	it 'Recognizes single unchanged', (done) ->
		fs = newFS
			'www/file': ''
			'memory': JSON.stringify { '/': { 'file': 'da39a3ee5e6b4b0d3255bfef95601890afd80709' } } # Actual SHA1 for empty string
		diff = newSimpleDiff fs
		diff.compute (diff) ->
			diff.new.should.have.length 0
			diff.modified.should.have.length 0
			diff.removed.should.have.length 0
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
		diff.compute (diff) ->
			diff.new.should.eql [ '/newFile' ]
			diff.modified.should.eql [ '/modifiedFile' ]
			diff.removed.should.eql [ '/removedFile' ]
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
		debugger
		diff.compute (diff) ->
			diff.new.should.eql [ '/newFile', '/dir/newFile', '/newDir/file1', '/newDir/file2' ]
			diff.modified.should.eql [ '/modifiedFile', '/dir/modifiedFile' ]
			diff.removed.should.eql [ '/removedFile', '/dir/removedFile', '/removedDir/file1', '/removedDir/file2' ]
			done()