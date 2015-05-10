module.exports = {
  js: {
    files: [{
      expand: true,
      cwd: '<%= config.dir.src %>/js',
      src:['**/*.js'],
      dest: '<%= config.dir.tmp %>/js'
    }]
  },
  jsProd: {
    files: [{
      expand: true,
      cwd: '<%= config.dir.src %>/js/',
      src:['**/*.js'],
      dest: '<%= config.dir.dist %>/js/'
    }]
  },
  img: {
    files: [{
      expand: true,
      cwd: '<%= config.dir.src %>/img',
      src:['**/*'],
      dest: '<%= config.dir.tmp %>/img'
    }]
  },
  imgProd: {
    files: [{
      expand: true,
      cwd: '<%= config.dir.src %>/img',
      src:['**/*'],
      dest: '<%= config.dir.dist %>/img'
    }]
  },
  font: {
    files: [{
      expand: true,
      cwd: '<%= config.dir.src %>/font',
      src:['**/*'],
      dest: '<%= config.dir.tmp %>/font'
    }]
  },
  fontProd: {
    files: [{
      expand: true,
      cwd: '<%= config.dir.src %>/font',
      src:['**/*'],
      dest: '<%= config.dir.dist %>/font'
    }]
  }
};
