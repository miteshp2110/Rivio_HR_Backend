require('dotenv').config();

const http = require('http');
const app = require('./app');

const server = http.createServer(app);
const PORT = process.env.PORT || 3000;

async function startServer() {
    try{
        server.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    }
    catch(error){
        console.error('Error starting server:', error);
        process.exit(1);
    }
}

startServer();