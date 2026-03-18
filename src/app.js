
const express = require('express');


const app = express();

app.use(express.json());


//add your routes here


app.get('/health', (req, res) => {
    res.status(200).json({ status: 'UP', message: 'Server is healthy' ,time: new Date().toISOString()});
});







module.exports = app;