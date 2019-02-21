const path = require('path');
var basePath = __dirname;

module.exports = {
  context: path.join(basePath, 'src'),

  //entry: path.join(__dirname, './app.ts'),
  entry : {
    app : './app.ts'
  },
  output: {
    filename: 'app.js',
    path: __dirname
  },
    devServer: {
        port: 8080,
        noInfo: true,
        proxy: {
            '/api': {
                target: 'http://localhost:3000',
                pathRewrite: {'^/api' : ''}
            }
        }
    },

  module: {
    rules: [
      {
        test: /\.tsx?$/,
        loader: 'ts-loader',
        exclude: /node_modules/,
      },
    ]
  },
  resolve: {
    extensions: [".tsx", ".ts", ".js"]
  },
};