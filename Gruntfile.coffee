module.exports = (grunt) ->
  grunt.initConfig
    bower:
      install:
        options:
          targetDir: 'public/lib'
          layout: 'byComponent'
          install: true
          verbose: false
          cleanTargetDir: true
          cleanBowerDir: false

  [
    'grunt-bower-task'
  ].forEach grunt.loadNpmTasks
