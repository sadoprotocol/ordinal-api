"use strict";

require('dotenv').config();

const express = require('express')
const cors = require('cors')
const app = express()
const port = process.env.PORT || 3000;
const formidable = require('formidable');
const ordinal = require('./ordinal');


app.use(cors());
app.use(express.json()) // for parsing application/json
app.use(express.urlencoded({ extended: true })) // for parsing application/x-www-form-urlencoded



// === FILE UPLOAD

app.all('/fileupload', (req, res) => {
  let form = new formidable.IncomingForm();

  form.parse(req, function (err, fields, files) {
    if (err) {
      let error = err.message || err ;

      res.status(500).json({
        success: false,
        message: error
      });
    } else {
      ordinal.upload(files).then(result => {
        res.json({
          success: true,
          message: 'Uploaded',
          rdata: result
        });
      }).catch(err => {
        let error = err.message || err ;

        res.status(500).json({
          success: false,
          message: error
        });
      })
    }
  });
});

// === COMMANDS

app.all('/', (req, res) => {
  if (req.body && Array.isArray(req.body)) {
    ordinal.rpc(req.body).then(data => {
      res.json({
        success: true,
        message: 'Command successful',
        rdata: data
      });
    }).catch(err => {
      let error =err.message || err ;

      res.status(500).json({
        success: false,
        message: error
      });
    });
  } else {
    res.status(500).json({
      success: false,
      message: 'Invalid request. Missing some parameters?'
    });
  }
});






// === END

app.listen(port, () => {
  console.log(`Listening on port ${port}`)
});

